class TcdStaffScrape
  PEOPLE_FINDER_URL = "http://people.tcd.ie/"

  attr_reader :agent

  def initialize
    @agent = Mechanize.new do |agent|
      agent.user_agent_alias = "Mac Safari"
      agent.follow_meta_refresh = true
    end
  end

  def log_line(msg)
    time = Time.now.utc
    Rails.logger.info(
      "tcd_staff_scrape_log #{msg}"
    )
  end


  def do_it!
    log_line("TcdStaffScrape start")

    home = agent.get(PEOPLE_FINDER_URL)
    form = home.form_with(id: "ctl01")
    form.field_with(name: "__EVENTTARGET").value = "ctl00$MainContent$UserControlSearchForPerson$ButtonDeptSearch"
    form.field_with(name: "__EVENTARGUMENT").value = ""
    select_field = form.field_with(name: "ctl00$MainContent$UserControlSearchForPerson$DropDownListDepartments")

    select_field.options.each_with_index do |option, i|
      next if i == 0 #first option is a placeholder

      department_name = option.text
      log_line("#{i} => #{department_name} #{option.value}")
      option.click

      begin
        staff_from_page = get_people_from_page(form.submit, department_name)
        staff_stored_by_email = StaffMember.where(department: department_name).reduce({}) do |hsh, member|
          hsh[member.email] = member
          hsh
        end
        staff_to_be_stored = []

        staff_from_page.each do |page_member|
          next if page_member[:email].nil?

          if staff_stored_by_email[page_member[:email]]
            staff_stored_by_email.delete(page_member[:email])
          else
            staff_to_be_stored.push(page_member)
          end
        end

        staff_whove_disappeared = staff_stored_by_email.values
        StaffMember.where(id: staff_whove_disappeared.map(&:id)).update_all(disappeared_at: Time.now)

        log_line("Bulk inserting #{staff_to_be_stored.length}")
        Rails.logger.silence do
          StaffMember.import(staff_to_be_stored)
        end

      rescue Mechanize::ResponseCodeError, Net::HTTP::Persistent::Error => e
        log_line("Error getting that one... #{e.message}")
      end
    end
  end

  def get_people_from_page(page, department_name)
    people = []

    page.css("#DEPTSEARCHRESULT").each do |department_section|
      sub_department_name = department_section.at_css(".panel-title").try(:text)
      department_section.css(".bs-callout").each do |row|
        person_attrs = {
          department: department_name,
          sub_department: sub_department_name,
          name: row.at_css("[id*=LabelName]").try(:text),
          email: row.at_css("[id*=EmailLink]").try(:text),
          phone: row.at_css("[id*=PhoneLink]").try(:text),
          job_title: row.css(".col-sm-6")[2].try(:text),
          location: row.css(".col-sm-6")[4].try(:text),
          row_html: row.to_s#,
          # other_col: row.css(".col-sm-6")[5].try(:text)
        }
        person_attrs.each do |key, value|
          if value.is_a?(String)
            value.strip!
            value.gsub!(/\u00a0/, ' ') # swap non-breaking spaces for normal spaces
            person_attrs[key] = nil if value == ""
          end
        end
        people.push(person_attrs)
      end
    end

    people
  end

end
