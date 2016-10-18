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

    def initialize(user)
      @user = user
      @agent = Mechanize.new do |agent|
        agent.user_agent_alias = "Mac Safari"
        agent.follow_meta_refresh = true
      end
    end

    def test_login_success!
      log_line("test_login_success!")
      submit_login
      @user.my_tcd_login_success
    end

    # private

    def submit_login
      log_line("submit_login start")

      login_page = @agent.get("https://my.tcd.ie")
      form = login_page.form_with(name: "f")
      form.field_with!(name: "MUA_CODE.DUMMY.MENSYS.1").value = @user.my_tcd_username
      form.field_with!(name: "PASSWORD.DUMMY.MENSYS.1").value = @user.my_tcd_password
      signed_in_page = form.click_button

      success = signed_in_page.link_with(text: "here").present?
      unless success
        if signed_in_page.at_css("td.pagetitle").try(:text).try(:include?, "Password Change")
          raise MyTcdError, "MyTcd wants you to change your password. Login and do so before returning here"
        elsif signed_in_page.at_css("span.sitsmessagetitle").try(:text).try(:include?, "Username and Password invalid")
          raise MyTcdError, "MyTcd says it doesn't recognise that username and password"
        else
          raise MyTcdError, "Error logging into MyTcd..."
        end
      end

      signed_in_page
    ensure
      save_login_success!(success)
      log_line("submit_login done success=#{@user.my_tcd_login_success}")
    end

    def fetch_events
      page = get_term_event_list_page;
      rows = page.css("table#ttb_timetableTable tbody tr");

      last_date = nil
      rows.map do |row|
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
        "Module Name" => module_name,
        "Activity"    => activity
      }.reduce("") do |desciption, (attr_name, val)|
        val.present? ? desciption + "#{attr_name}: #{val}\n" : desciption
      end

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
      timetable_page = get_standard_timetable_page
      form = timetable_page.form_with(action: "SIW_XTTB_1")

      t = Time.now.freeze
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

    def get_standard_timetable_page
      submit_login
        .link_with(text: "here").click
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
      @user.update_attributes!(
        my_tcd_last_attempt_at: Time.now,
        my_tcd_login_success: did_log_in
      )
    end

    def try_parse_time(time_string)
      begin
        Time.parse(time_string)
      rescue ArgumentError, TypeError
        nil
      end
    end

    def fix_casing(str, surname: false)
      fixed = str.gsub(/\b([a-zA-Z]+)\b/) { $1.downcase.capitalize }
      surname ? fixed : fixed.gsub(/(?<=Mac|Mc)([a-z])/) { $1.capitalize }
    end
  end

  class MyTcdError < StandardError
    def initialize(msg="Error communicating with my.tcd.ie")
      super(msg)
    end
  end
end
