QUE_EXCLUE_LOG_EVENTS = [:job_unavailable]

if $IS_QUE
  # Que.wake_interval = 2.seconds
  Que.mode = :off
  Que.worker_count = (ENV['QUE_WORKERS'] || 4)
  # Que.logger = Logger.new("#{Rails.root}/log/worker_#{Rails.env}.log")
  Que.log_formatter = proc do |data|
    if QUE_EXCLUE_LOG_EVENTS.exclude?(data[:event])
      JSON.dump(data)
    end
  end
end
