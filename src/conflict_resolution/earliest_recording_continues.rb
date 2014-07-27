class EarliestRecordingContinues
  def compare(a, b)
    # basic input type error checking.
    raise ArgumentError.new("found #{a.class}, expected Hash.") if a.class != Hash
    raise ArgumentError.new("found #{b.class}, expected Hash.") if b.class != Hash

    # more basic input type error checking. ideally none of this should ever happen,
    # but it doesn't hurt to sanitize inputs a little bit.
    raise ArgumentError.new("malformed hash") if ! a.key?(:start_time) || ! b.key?(:start_time)
    raise ArgumentError.new("malformed hash") if ! a.key?(:start_date) || ! b.key?(:start_date)

    # check times if they're on the same day, otherwise assume the earliest date wins.
    # this covers recordings that might start at 11pm one day and go to 1am the next day.
    return a[:start_time] <=> b[:start_time] if(a[:start_date] == b[:start_date])
    return a[:start_date] <=> b[:start_date]
  end
end