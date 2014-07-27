class EarliestRecordingContinues
  def compare(a, b)
    # basic input type error checking.
    return 1 if a.class != Hash
    return -1 if b.class != Hash

    # more basic input type error checking. ideally none of this should ever happen,
    # but it doesn't hurt to sanitize inputs a little bit.
    return 1 if ! a.key?(:start)
    return -1 if ! b.key?(:start)

    # check times if they're on the same day, otherwise assume the earliest date wins.
    # this covers recordings that might start at 11pm one day and go to 1am the next day.
    return a[:start_time] <=> b[:start_time] if(a[:start_date] == b[:start_date])
    return a[:start_date] <=> b[:start_date]
  end
end