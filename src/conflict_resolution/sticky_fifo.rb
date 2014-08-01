require_relative '../recording'
require_relative './naive_fifo'

# This class is only slightly more intelligent than the NaiveFifo. In this algorithm two back-to-back recordings on
# one channel will be recorded, but if a recording wasn't recorded due to that priority bump, it will supercede
# later recordings that could end after the back-to-back recordings.
# In other words:
# Ch. 5: A 6:30-7:00 --> fully recorded
# Ch. 6: B 7:00-8:30 --> truncated, recorded from 7:30-8:30
# Ch. 5: C 7:00-7:30 --> fully recorded
# Ch. 7: D 7:30-8:30 --> not recorded at all

# so a better algorithm would be to also see if a recording would have recorded when it was supposed to start
# if so, keep recording it, otherwise downgrade it's priority. this could be done by calculating the percentage
# that would be recorded(culling/calculating the recording priorities at each show's start time) and weighting
# shows with 100% recording potential.

class StickyFifo < NaiveFifo

  def datetime_min(rec_a, rec_b)
    [rec_b[:start_time], rec_b[:start_date]] if (rec_b[:start_date] < rec_a[:start_date])
    [rec_b[:start_time], rec_b[:start_date]] if (rec_b[:start_time] < rec_a[:start_time])
    [rec_a[:start_time], rec_a[:start_date]]
  end

  def stickify_recordings(recording_group)
    recording_group[:recordings].map do |rec|
      new_rec = Hash.new
      recording_group[:recordings].each do |other_rec|
        new_rec[:end_time], new_rec[:end_date] = rec[:end_time],rec[:end_date]
        new_rec[:start_time], new_rec[:start_date] = datetime_min(rec, other_rec)
        # we could also extend the end time, but that's not really necessary in this algorithm, since
        # this is a first-recorded-is-sticky comparison, not a "last-recorded-should-be-sticky" comparison.
      end
      new_rec
    end
  end

  def compare(time, a, b)
    validate_inputs(a,b)

    sticky_a = { :channel => a[:channel], :recordings => stickify_recordings(a) }
    sticky_b = { :channel => b[:channel], :recordings => stickify_recordings(b) }
    # must iterate through all valid recordings on each channel to find out which channel should be recorded.
    # check times if they're on the same day, otherwise assume the earliest date wins.
    # this covers recordings that might start at 11pm one day and go to 1am the next day.
    # this should honor channel stickiness. So if channel A records 8-9, 9-10, and channel B records 8:30-9:30,
    # recording should go A:8-10
    # of course this depends on the stickify_recordings method working correctly.
    compare_timestamps(time,
                       sticky_a[:recordings].select { |rec| Recording.is_active(rec, time) },
                       sticky_b[:recordings].select { |rec| Recording.is_active(rec, time) })

  end
end