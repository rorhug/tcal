require 'google/apis/calendar_v3'

module MyTcd
  class TimetableScraper
    HTML_EVENT_ATTRIBUTES = {
      "Date" => "",
      "Module" => "",
      "Size" => "",
      "Group" => "",
      "Activity" => "",
      "Room" => "",
      "Lecturer" => ""
    }.freeze

    attr_reader :agent, :user

    def initialize(user)
      @user = user
      @agent = Mechanize.new do |agent|
        agent.user_agent_alias = "Mac Safari"
        agent.follow_meta_refresh = true
      end
    end

    def test_login_success!
      log_line("test_login_success!")
      get_my_tcd_home
      @user.my_tcd_login_success
    end

    def get_my_tcd_home
      send_to_sentry = false
      log_line("get_my_tcd_home")
      login_page = @agent.get("https://my.tcd.ie/urd/sits.urd/run/siw_lgn")

      (1..4).reduce(login_page) do |page, _| # try and get to the home page in 4 or less links

        # Home Success :)
        if page.link_with(text: "My Timetable").present?
          save_login_success!(true)
          return page

        #Password change
        elsif page.at_css("td.pagetitle").try(:text).try(:include?, "Password Change")
          raise MyTcdError, "MyTCD wants you to change your password. Go forth and do so before returning here."

        # Invalid user/pass combo
        elsif page.at_css("span.sitsmessagetitle").try(:text).try(:include?, "Username and Password invalid")
          raise MyTcdError, "MyTCD says it doesn't recognise that username/password."

        # Multiple Course Selection
        elsif multiple_course_form = page.form_with(action: "SIW_MCS")
          multiple_course_form.field_with(name: "SCJ_LIST.DUMMY.MENSYS.1").options.last.click
          next multiple_course_form.click_button

        # Main Login Page (has to below password fail, it on after password fail!)
        elsif login_form = page.form_with(action: "SIW_LGN")
          login_form.field_with!(name: "MUA_CODE.DUMMY.MENSYS.1").value = @user.my_tcd_username
          login_form.field_with!(name: "PASSWORD.DUMMY.MENSYS.1").value = @user.my_tcd_password
          next login_form.click_button

        # JS Login Redirect, click here thingy
        elsif page.title == "Log-in successful" && (here_link = page.link_with(text: "here"))
          next here_link.click

        # Unknown flow :/
        else
          send_to_sentry = true
          raise MyTcdError, "Error logging into MyTCD (unknown flow)"
        end
      end

      # it could repeat 4 times without raising...
      send_to_sentry = true
      raise MyTcdError, "Error logging into MyTCD (4)"

    rescue MyTcd::MyTcdError => e
      save_login_success!(false)

      Raven.capture_exception(
        e,
        level: "warning",
        user: @user.for_raven,
        extra: {
          agent_page_url: @agent.current_page.uri.try(:to_s),
          agent_page_html: @agent.current_page.body
        }
      ) if send_to_sentry # Only care if it's an unknown error

      raise e # raise it again up to the controller or job runner
    end

    def fetch_events
      log_line("fetch_events")
      page = get_term_event_list_page

      log_line("begin_term_events_parsing")
      rows = page.css("table#ttb_timetableTable tbody tr");

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
      gcal_events
    end

    def parse_to_gcal_event(attrs, base_date)
      start_time, end_time = attrs["Time"].first.split("-").map do |time_str|
        try_parse_time(time_str.strip)
      end.compact.map do |time|
        base_date.dup.change(hour: time.hour, minute: time.min)
      end

      # remove room brackets e.g. "LB01(Lloyd Institute (INS Building))"
      event_location = attrs["Room"].first.to_s.gsub(/[ \n]*[\(\)]/, ", ").gsub(/[\n \,]+\z/, "")
      lecturer = fix_casing(attrs["Lecturer"].first.to_s, surname: true)
      activity = attrs["Activity"].first.to_s
      module_code = attrs["Module"][1]
      module_name = fix_casing(attrs["Module"][0].to_s)

      event_summary = [module_name, activity, module_code].select(&:present?).join(" | ")
      event_description = {
        "Lecturer"    => lecturer,
        "Module Code" => module_code,
        "Class Size"  => attrs["Size"].first,
        "Group"       => attrs["Group"].first,
        "Location"    => event_location,
        # "Module Name" => module_name, # so you can see fb link on ios cal
        "Activity"    => activity
      }.reduce("") do |desciption, (attr_name, val)|
        val.present? ? desciption + "#{attr_name}: #{val}\n" : desciption
      end + %Q{
Like our page https://www.facebook.com/TcalDotMe
Timetable kept in sync using https://www.tcal.me
}

      event = Google::Apis::CalendarV3::Event.new({
        summary: event_summary,
        location: event_location,
        description: event_description,
        start: {
          date_time: start_time.iso8601,
          time_zone: GoogleCalendarSync::TIMEZONE_STRING
        },
        end: {
          date_time: end_time.iso8601,
          time_zone: GoogleCalendarSync::TIMEZONE_STRING
        },
        reminders: {
          use_default: false
        }
      })
      event.color_id = "2" unless activity.downcase.include?("lecture")

      event
    end

    def table_cell_to_event_attributes(td)
      # https://gist.github.com/RoryDH/319603b31fba656a836706411fb98352

      td.at_css("strong").remove # this tag is redundant, gets in the way

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
            event[pair[0]].push(pair[1].strip)
          end
        end
      )
    end

    def get_term_event_list_page
      timetable_page = get_default_timetable_page
      log_line("get_term_event_list_page")
      form = timetable_page.form_with(action: "SIW_XTTB_1")

      # zone is set to dublin in the application.rb
      # lets hope that daylight saving switches on my.tcd.ie server
      # at the same time on this
      t = Time.zone.now.freeze

      is_michaelmas = (1..8).exclude?(t.month)
      academic_year = is_michaelmas ? t.year : t.year - 1

      # only get events from start of current week
      from_date = t.beginning_of_week.strftime("%d/%b/%Y")
      to_date = is_michaelmas ? "31/Dec/#{t.year}" : "31/Aug/#{t.year}"

      update_timetable_form = {
        "P01" => from_date,
        "P02" => to_date,
        "P03" => "#{academic_year}/#{(academic_year + 1).to_s[2..3]}",
        "P04" => "",
        "P05" => "",
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
        .link_with(text: "View My Own Student Timetable").click
    end

    def log_line(msg)
      time = Time.now.utc
      Rails.logger.info(
        "scrape_log #{time} #{time.strftime("%L")}ms #{msg} user.id=#{@user.id}"
      )
    end

    def save_login_success!(did_log_in)
      log_line("save_login_success! did_log_in=true")
      @user.update_attributes!(
        my_tcd_last_attempt_at: Time.now,
        my_tcd_login_success: did_log_in
      )
    end

    def try_parse_time(time_string)
      begin
        # see comment on other Time.zone call in this class
        Time.zone.parse(time_string)
      rescue ArgumentError, TypeError
        nil
      end
    end

    def fix_casing(str, surname: false)
      fixed = str.gsub(/\b([a-zA-Z]+)\b/) { $1.downcase.capitalize } # capitalize words
      # MacMcFix  :  Telecoms Iii => III
      surname ? fixed.gsub(/(?<=Mac|Mc)([a-z])/) { $1.capitalize } : fixed.gsub(/\bIi{1,6}\b/, &:upcase)
    end
  end

  class MyTcdError < StandardError
    def initialize(msg="Error logging into MyTCD...")
      super(msg)
    end
  end
end
