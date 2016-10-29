require 'google/apis/calendar_v3'

log_path = Rails.logger.instance_variable_get("@logdev").dev.path
Google::Apis.logger = ActiveSupport::Logger.new(log_path)
Google::Apis.logger.level = Logger::INFO

class GoogleCalendarSync
  CALENDAR_SUMMARY = "Tcal#{ " - " + Rails.env unless Rails.env.production? }"
  TIMEZONE_STRING = "Europe/Dublin"
  MAX_SYNCS_PER_HOUR = 5
  # SYNC_BLOCKED_MESSAGES = {
  #   ongoing: "There is already a sync in progress!",
  #   lots_recently: "You "
  # }

  def initialize(user)
    @user = user
    user.ensure_valid_access_token!
  end

  def cal_service
    return @cal_service if @cal_service
    @cal_service = Google::Apis::CalendarV3::CalendarService.new
    @cal_service.authorization = AccessToken.new(@user.oauth_access_token)
    @cal_service
  end

  def print_some_upcoming_events(cal_id=nil)
    response = cal_service.list_events(
      cal_id || calendar_id,
      max_results: 10,
      single_events: true,
      order_by: 'startTime',
      time_min: Time.now.iso8601
    )

    puts "Upcoming events:"
    puts "No upcoming events found" if response.items.empty?
    response.items.each do |event|
      start = event.start.date || event.start.date_time
      puts "- #{event.summary} (#{start})"
    end
  end

  def create_event(event)
    result = cal_service.insert_event(calendar_id, event)
  end

  def calendar_id
    return @calendar_id if @calendar_id

    # find it in the users list of calendars
    calendar = cal_service.list_calendar_lists.items.find { |cal| cal.summary == CALENDAR_SUMMARY }
    return (@calendar_id = calendar.id) if calendar

    # create it
    calendar = Google::Apis::CalendarV3::Calendar.new(
      summary: CALENDAR_SUMMARY,
      time_zone: TIMEZONE_STRING
    )
    calendar = cal_service.insert_calendar(calendar)
    return @calendar_id = calendar.id
  end

  def fetch_all_gcal_events
    gcal_events = []
    next_page = nil
    5.times do
      response = cal_service.list_events(
        calendar_id,
        max_results: 250,
        single_events: true,
        order_by: 'startTime',
        time_min: Time.now.beginning_of_week.iso8601
        # time_max needs to be set to end of semester
      )
      gcal_events += response.items
      next_page = response.next_page_token
      break if !next_page || response.items.length < 1
    end
    gcal_events
  end

  def fetch_upcoming_events_for_feed
    events = cal_service.list_events(
      calendar_id,
      max_results: 9,
      single_events: true,
      order_by: 'startTime',
      time_min: (Time.now - 55.minutes).iso8601,
      time_max: 3.weeks.from_now.iso8601
    ).items

    events_by_date = events.each_with_object({}) do |event, dates|
      date = event.start.date_time.to_date
      dates[date] ||= []
      dates[date].push(event)
    end
    events_by_date.delete(events_by_date.keys.last)
    events_by_date
  end

  def sync_events!(source_event_list)
    # all events already on gcal
    all_gcal_events = fetch_all_gcal_events

    # remove tcal events...
    events_to_create = source_event_list.reject do |source_event|
      event_exists = false

      source_event_start = source_event.start[:date_time]

      all_gcal_events.delete_if do |gcal_event| # ...and gcal events
        gcal_event_start = gcal_event.start.date_time.try(:iso8601)
        event_matched = gcal_event_start &&
                        gcal_event_start == source_event_start &&
                        gcal_event.description == source_event.description &&
                        gcal_event.try(:sequence).to_i == 0
        event_exists = true if event_matched # ... if they match each other
        event_matched
      end

      event_exists
    end

    ids_to_delete = all_gcal_events.uniq(&:id).map(&:id)
    delete_remote_event_ids(ids_to_delete) if ids_to_delete.any?

    create_events(events_to_create) if events_to_create.any?

    {
      events_created: events_to_create.size,
      events_deleted: ids_to_delete.size
    }
  end

  def create_events(events)
    callback = lambda { |event, err| raise err if err }
    events.in_groups_of(50, false) do |events|
      cal_service.batch do |cal_batch|
        events.each do |event|
          cal_batch.insert_event(calendar_id, event, &callback)
        end
      end
    end
  end

  def delete_remote_event_ids(ids)
    callback = lambda { |event, err| raise err if err }
    ids.in_groups_of(50, false) do |ids|
      cal_service.batch do |cal_batch|
        ids.each do |id|
          cal_batch.delete_event(calendar_id, id, &callback)
        end
      end
    end
  end
end

class AccessToken
  attr_reader :token
  def initialize(token)
    @token = token
  end

  def apply!(headers)
    headers['Authorization'] = "Bearer #{@token}"
  end
end
