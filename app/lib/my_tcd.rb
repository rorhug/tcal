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

  class MyTcdError < StandardError
    def initialize(msg="Error logging into MyTCD...")
      super(msg)
    end
  end

  class NoTimetableLinkError < MyTcdError
    def skip_sentry
      false
    end
  end

  class PasswordError < MyTcdError
    def skip_sentry
      true
    end
  end

  class PasswordChangeError < PasswordError
    def initialize(msg="MyTCD wants you to change your password. Go forth and do so before returning here.")
      super(msg)
    end
  end

  class PasswordInvalidError < PasswordError
    def initialize(msg="MyTCD says it doesn't recognise that username/password.")
      super(msg)
    end
  end
end
