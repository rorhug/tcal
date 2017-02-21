require 'google/apis/calendar_v3'

module MyTcd
  # WEEKS_TO_SYNC = 50
  LOGIN_PAGE_URL = "https://my.tcd.ie/urd/sits.urd/run/siw_lgn"
  ACTIVITY_COLOR_ID_MAPPING = {
    "Laboratory" => 6,
    "Tutorial" => 5,

    # use default calendar color for these
    "Lecture" => nil,
    "Core" => nil
  }

  class TimetableScraper
    HTML_EVENT_ATTRIBUTES = {
      "Date" => [],
      "Module" => [],
      "Size" => [],
      "Group" => [],
      "Activity" => [],
      "Room" => [],
      "Lecturer" => []
    }.freeze

    attr_reader :agent, :user, :for_auto_sync

    def initialize(user, silence_my_tcd_fail_email: true)
      @user = user
      @silence_my_tcd_fail_email = silence_my_tcd_fail_email
      @agent = Mechanize.new do |agent|
        agent.user_agent_alias = "Mac Safari"
        agent.follow_meta_refresh = true
        agent.open_timeout=120
        agent.read_timeout=120
      end
    end

    def test_login_success!
      log_line("test_login_success!")
      get_my_tcd_home(for_login_test: true)
      @user.my_tcd_login_success
    end

    def notify_user_of_my_tcd_fail!(password_change: false)
      return if @silence_my_tcd_fail_email
      @user.que_mail(
        UserMyTcdFailMailer,
        requires_password_change: password_change,
      )
    end

    def get_my_tcd_home(for_login_test: false)
      send_to_sentry = false
      log_line("get_my_tcd_home")
      login_page = @agent.get(LOGIN_PAGE_URL)

      (1..6).reduce(login_page) do |page, _| # try and get to the home page in 4 or less links

        # Home Success :)
        if page.link_with(text: "My Timetable").present?
          save_login_success!(for_login_test: for_login_test)
          return page

        #Password change
        elsif page.at('h2:contains("Password Change")')
          notify_user_of_my_tcd_fail!(password_change: true)
          raise PasswordError, "MyTCD wants you to change your password. Go forth and do so before returning here."

        # Invalid user/pass combo
        elsif page.at('strong:contains("Username and Password invalid")')
          notify_user_of_my_tcd_fail!
          raise PasswordError, "MyTCD says it doesn't recognise that username/password."

        # Invalid user/pass combo
        elsif page.at('strong:contains("Username Invalid")')
          # notify_user_of_my_tcd_fail! Probably shouldn't notify people who haven't even filled in username on my accidental sync
          raise PasswordError, "MyTCD won't accept that username."

        # Multiple Course Selection
        elsif multiple_course_form = page.form_with(action: "SIW_MCS")
          multiple_course_form.field_with(name: "SCJ_LIST.DUMMY.MENSYS.1").options.last.click
          next multiple_course_form.click_button

        # Main Login Page (has to be below invalid login as that's really just this page with a message!)
        elsif login_form = page.form_with(action: "SIW_LGN")
          login_form.field_with!(name: "MUA_CODE.DUMMY.MENSYS.1").value = @user.my_tcd_username
          login_form.field_with!(name: "PASSWORD.DUMMY.MENSYS.1").value = @user.my_tcd_password
          next login_form.click_button

        # JS Login Redirect, click here thingy
        elsif page.title == "User Redirect" && (here_link = page.link_with(text: "click here to access the portal"))
          next here_link.click

        # Automatic Logout as was logged in on another session
        elsif page.at('strong:contains("Automatic Logout")')
          # There's a 'here' link on this page which goes to login page anyway... (random/u565.html)
          next @agent.get(LOGIN_PAGE_URL)

        # Unknown flow :/
        else
          send_to_sentry = true
          raise MyTcdError, "Error logging into MyTCD (unknown flow)"
        end
      end

      # it could repeat 4 times without raising...
      send_to_sentry = true
      raise MyTcdError, "Error logging into MyTCD (4)"

    rescue MyTcd::MyTcdError, SocketError => e
      if e.is_a?(SocketError)
        send_to_sentry = true
        e = MyTcdError.new("MyTCD seems to be down... please try again later")
      end
      save_login_success!(error: e, for_login_test: for_login_test)

      exception_extra = if @agent.current_page
        {
          agent_page_url: @agent.current_page.uri.try(:to_s),
          agent_page_html: @agent.current_page.body
        }
      end

      Raven.capture_exception(
        e,
        level: "warning",
        user: @user.for_raven,
        extra: exception_extra
      ) if send_to_sentry # Only care if it's an unknown error

      raise e # raise it again up to the controller or job runner
    end

    def fetch_events(event_list_page: get_term_event_list_page) # returns { events: [GoogleCalEvent, ...], status: (:success, :no_records) }
      log_line("fetch_events")

      # page = get_term_event_list_page

      if event_list_page.at_css("td").inner_html == "No records to show"
        return { events: [], status: :no_records }
      end

      log_line("begin_term_events_parsing")
      rows = event_list_page.css("#ttb_timetableTable tbody tr");

      last_date = nil
      gcal_events = rows.map do |row|
        date_header = row.at_css(".sitsrowhead")
        if date_header
          date_string = date_header.try(:inner_html).gsub("<br/>", " ")
          last_date = try_parse_time(date_string) if date_string.present?
        end
        next unless last_date

        event_cell = row.at_css("td")
        next unless event_cell

        event_attributes = table_cell_to_event_attributes(event_cell)
        parse_to_gcal_event(event_attributes, last_date)
      end
      log_line("finish_term_events_parsing")
      { events: gcal_events, status: :success }
    end

    def format_location_string(mytcd_location)
      # remove room brackets e.g. "LB01(Lloyd Institute (INS Building))"
      mytcd_location.gsub(/[ \n]*[\(\)]/, ", ").gsub(/[\n \,]+\z/, "")
    end

    def parse_to_gcal_event(attrs, base_date)
      start_time, end_time = attrs["Time"].first.split("-").map do |time_str|
        try_parse_time(time_str.strip)
      end.compact.map do |time|
        base_date.dup.change(hour: time.hour, minute: time.min)
      end

      locations = attrs["Room"].compact.map { |s| format_location_string(s.to_s) }
      activity = attrs["Activity"].first.to_s.downcase.titlecase

      lecturers = attrs["Lecturer"].compact.map do |lecturer|
        # MacMcFix
        simple_titleize(lecturer).gsub(/(?<=Mac|Mc|O')([a-z])/) { $1.capitalize }
      end

      # Telecoms Iii => III
      module_name = simple_titleize(attrs["Module"][0].to_s).gsub(/\bIi{1,6}\b/, &:upcase)
      module_code = attrs["Module"][1]

      locations_title, locations_description = if locations.size == 1
        ["Location", locations.first]
      elsif locations.size > 1
        ["Multiple Locations", "\n - " + locations.join("\n - ")]
      end

      event_description = {
        "Lecturer".pluralize(lecturers.size)            => lecturers.join(", "),
        "Group"                                         => attrs["Group"].first,
        "Like our page"                                 => "https://fb.me/TcalDotMe",
        locations_title                                 => locations_description,
        "Class Size"                                    => attrs["Size"].first,
        "Module Code"                                   => module_code,
        "Module Name"                                   => module_name,
        "Activity"                                      => activity,
        "Timetable kept in sync using"                  => "https://tcal.me"
      }.reduce("") do |desciption, (attr_name, val)|
        if val.present?
          desciption + "#{attr_name}: #{val}\n"
        else
          desciption
        end
      end

      event = Google::Apis::CalendarV3::Event.new({
        summary: [module_name, activity, module_code].select(&:present?).join(" | "),
        location: locations.first,
        description: event_description,
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: start_time.to_datetime,
          time_zone: GoogleCalendarSync::TIMEZONE_STRING
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: end_time.to_datetime,
          time_zone: GoogleCalendarSync::TIMEZONE_STRING
        ),
        reminders: {
          use_default: false
        },
        color_id: ACTIVITY_COLOR_ID_MAPPING[activity]
      })

      event
    end

    def table_cell_to_event_attributes(td)
      # https://gist.github.com/RoryDH/319603b31fba656a836706411fb98352

      td.at_css("strong").try(:remove) # this tag is redundant, gets in the way

      mousover_attr = td.attribute("onmouseover") # onmouseover contains extra attrs
      tooltip_function_text = mousover_attr.try(:value).try(:match, /\Atooltip\(\'(.+)\'\)\z/).try(:[], 1)

      HTML_EVENT_ATTRIBUTES.dup.merge(
        "#{tooltip_function_text}<br>#{td.inner_html}".gsub(/[\n\r]/, "").split(/<br>|<br\/>/).map do |l|
          # Some attribute values (room and module) have links wrapping. Might be useful later...
          Nokogiri::HTML(l).text.strip
        end.each_with_object({}) do |string_pair, event|
          pair = string_pair.split(":", 2).map(&:strip)
          if pair[0].present? && pair[1].present?
            event[pair[0]] ||= []
            event[pair[0]].push(pair[1])
          end
        end
      )
    end

    def get_term_event_list_page
      timetable_page = get_default_timetable_page
      log_line("get_term_event_list_page")
      form = timetable_page.form_with(action: "SIW_XTTB_1")

      t = Time.zone.now.freeze
      # zone is set to dublin in the application.rb
      # lets hope that daylight saving switches on my.tcd.ie server
      # at the same time on this

      is_michaelmas = (1..8).exclude?(t.month)
      academic_year = is_michaelmas ? t.year : t.year - 1

      update_timetable_form = {
        "P01" => "", #from_date.strftime("%d/%b/%Y"),
        "P02" => "", #to_date.strftime("%d/%b/%Y"),
        "P03" => "#{academic_year}/#{(academic_year + 1).to_s[2..3]}",
        # ===== SHITE =====
        "P04" => "16",
        "P05" => "37",
        # ===== ===== =====
        "P06" => "T",
        "P07" => "TOP",
        "P08" => form.field_with(name: "INSTANCE_NUMBER.DUMMY.MENSYS.1").value,
        "nkey" => form.field_with(name: "NKEY.DUMMY.MENSYS.1").value,
        "runMode" => form.field_with(name: "RUN_MODE.DUMMY.MENSYS.1").value
      }

      @agent.post(
        "https://my.tcd.ie/urd/sits.urd/run/SIW_XTTB_1.update_timetable",
        update_timetable_form
      )
    end

    def get_default_timetable_page
      get_my_tcd_home
        .link_with(text: "My Timetable").click
        .link_with(text: " View My Own Student Timetable ").click
    end

    def log_line(msg)
      time = Time.now.utc
      Rails.logger.info(
        "scrape_log #{time} #{time.strftime("%L")}ms #{msg} user.id=#{@user.id}"
      )
    end

    def save_login_success!(error: nil, for_login_test: false)

      # If we're syncing and we get a non-password error don't
      # mark them as login fail. This avoids them being excluded
      # from sync for a reason unlrelated to wrong password.
      return if !for_login_test && error && !(error.instance_of?(PasswordError))

      did_log_in = !error
      log_line("save_login_success! did_log_in=#{did_log_in}")

      @user.my_tcd_login_success = did_log_in

      if for_login_test
        @user.my_tcd_last_attempt_at = Time.now
      end

      @user.save!
    end

    def try_parse_time(time_string)
      begin
        # see comment on other Time.zone call in this class
        Time.zone.parse(time_string)
      rescue ArgumentError, TypeError
        nil
      end
    end

    def simple_titleize(str)
      str.downcase.gsub(/\b(?<!['â`])[a-z]/) { |match| match.capitalize }
    end
  end

  class MyTcdError < StandardError
    def initialize(msg="Error logging into MyTCD...")
      super(msg)
    end
  end

  class PasswordError < MyTcdError
  end
end
