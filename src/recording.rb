class Recording
  def self.is_active(recording, time)
    timestamp = time.strftime("%Y%m%d%H%M")
    rec_start = recording[:start_date] + recording[:start_time]
    rec_end = recording[:end_date] + recording[:end_time]
    rec_start <= timestamp && timestamp < rec_end
  end
end