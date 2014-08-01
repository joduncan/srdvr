require_relative '../recording'

# I'm pretty sure that if we had channel A, 8-9, channel B 8:30-9:30, channel A 9-10,
# this will record channel A from 8-9, B from 9-9:30, and A 9:30-10.
# That's less than ideal, so I probably need another algorithm called
# "EarliestRecordingContinuesAndSubsequentRecordingsOnSameChannelGetPrecedence"
# to do that, I might need to select "currently active" recordings using end-time inclusion rather
# than my first consideration for end-time exclusion.. or have a second parameter which includes
# the currently active recordings. adding the 2nd parameter might be hairy though.
# such an algorithm would need to sort channels, not recordings.
# each channel would need to have a list of recordings scheduled for that channel around this time frame,
# and be able to determine that two programs were stopping/starting on one channel, vs a different channel
# whose scheduled recording would be mid-way at that given point in time.
class NaiveFifo
  # this is somewhat backwards, as we are validating data at the latest/inner-most level.
  # FIXME: move this into config file parsing/initialization.
  def validate_inputs(a,b)
    # basic input type error checking.
    raise ArgumentError.new("found #{a.class}, expected Hash with 2 keys.") if a.class != Hash || a.length != 2
    raise ArgumentError.new("found #{b.class}, expected Hash with 2 keys.") if b.class != Hash || b.length != 2

    # more basic input type error checking. ideally none of this should ever happen,
    # but it doesn't hurt to sanitize inputs a little bit.
    raise ArgumentError.new("malformed hash: #{a}") unless a.key?(:recordings) && a.key?(:channel)
    raise ArgumentError.new("malformed hash: #{b}") unless b.key?(:recordings) && b.key?(:channel)

    [a,b].each do |item|
      [:start_date,:start_time,:end_date,:end_time].each do |field|
        if ! item[:recordings].all? { |rec| rec.key?(field) }
          raise ArgumentError.new("ch. #{item[:channel]}: bad data #{item}")
        end
      end
    end
  end

  # must iterate through all valid recordings on each channel to find out which channel should be recorded.
  # check times if they're on the same day, otherwise assume the earliest date wins.
  # this covers recordings that might start at 11pm one day and go to 1am the next day.
  # this ignores channel stickiness. If channel A records 8-9, 9-10, and channel B records 8:30-9:30,
  # recordings will likely go A:8-9,B:9:01-9:30,A:9:31-10
  def compare_timestamps(time, a_list,b_list)
    # channel A has no active recordings at this time. B is either equal to, or less than A.
    return 1 unless a_list.length > 0
    # channel B ahs no active recordings at this time. A is either equal to, or less than B.
    return -1 unless b_list.length > 0
    # both channels have recordings. time to work some magic.
    a_list.map { |rec_a|
      b_list.map { |rec_b|
        if(rec_a[:start_date] == rec_b[:start_date])
          rec_a[:start_time] <=> rec_b[:start_time]
        else
          rec_a[:start_date] <=> rec_b[:start_date]
        end
      }.min
    }.min
  end

  def compare(time, a, b)
    validate_inputs(a,b)

    compare_timestamps(time,
                       a[:recordings].select { |rec| Recording.is_active(rec, time) },
                       b[:recordings].select { |rec| Recording.is_active(rec, time) })
  end
end