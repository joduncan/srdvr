class Recording
  def self.is_active(recording, time)
    # this is a really bad hack to work around how/why I'm getting empty hashes in one of my
    # lists somewhere.
    return false if recording.nil? || recording.class != Hash || recording.keys.length == 0
    timestamp = time.strftime("%Y%m%d%H%M")
    rec_start = recording[:start_date] + recording[:start_time]
    rec_end = recording[:end_date] + recording[:end_time]
    rec_start <= timestamp && timestamp < rec_end
  end
end