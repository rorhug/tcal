# Que.wake_interval = 2.seconds
Que.mode = :off
Que.worker_count = (ENV['QUE_WORKERS'] || 4)
Que.logger = Logger.new("#{Rails.root}/log/worker_#{Rails.env}.log")
