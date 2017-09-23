QUE_EXCLUDE_LOG_EVENTS = [:job_unavailable]

if $IS_QUE
  Que.wake_interval = 1.seconds
  Que.mode = :off
  Que.worker_count = 4
  # Que.logger = Logger.new("#{Rails.root}/log/worker_#{Rails.env}.log")
  Que.log_formatter = proc do |data|
    if QUE_EXCLUDE_LOG_EVENTS.exclude?(data[:event])
      JSON.dump(data)
    end
  end
end
