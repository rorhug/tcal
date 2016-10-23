require 'google/apis/calendar_v3'

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
  end

  def cal_service
    return @cal_service if @cal_service
    @cal_service = Google::Apis::CalendarV3::CalendarService.new
    @cal_service.authorization = AccessToken.new(@user.oauth_access_token)
    @cal_service
  end

  def print_some_upcoming_events
    response = cal_service.list_events('primary', max_results: 10, single_events: true, order_by: 'startTime', time_min: Time.now.iso8601)

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

  def fetch_gcal_events
    gcal_events = []
    next_page = nil
    begin
      response = cal_service.list_events(
        calendar_id,
        max_results: 200,
        single_events: true,
        order_by: 'startTime',
        time_min: Time.now.beginning_of_week.iso8601
        # time_max needs to be set to end of semester
      )
      gcal_events += response.items
      next_page = response.next_page_token
    end while next_page
    gcal_events
  end

  def sync_events!(source_event_list)
    # all events already on gcal
    all_gcal_events = fetch_gcal_events

    # remove tcal events...
    events_to_create = source_event_list.reject do |source_event|
      event_exists = false

      all_gcal_events.delete_if do |gcal_event| # ...and gcal events
        event_matched = gcal_event.start.date_time.iso8601 == source_event.start[:date_time] &&
          gcal_event.description == source_event.description
        event_exists = true if event_matched # ... if they match each other
        event_matched
      end

      event_exists
    end

    ids_to_delete = all_gcal_events.map(&:id)
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
