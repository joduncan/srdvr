require_relative 'conflict_resolution/sticky_fifo'
require_relative 'recorder'
require_relative 'recording'
require 'csv'

class Scheduler
  def initialize(config, num_tuners = 1, comparator_class=StickyFifo)
    @comparator = comparator_class.new
    # NOTE: this obviously assumes that each tuner can only record 1 channel at a time.
    # depending on the hardware/library/etc underlying stuff, this may be an invalid assumption.
    @max_concurrent_channels = num_tuners

    @recordings = []

    @recorders_in_use = {}
    @recorders = Array.new(@max_concurrent_channels) { Recorder.new }

    if(config.class == Array)
      @config_file = nil
      @recordings = config
    elsif (config.class == String)
      @config_file = config
      @config_file_last_mtime = File.mtime(@config_file)
      @recordings = parse_config
    else
      raise ArgumentError.new("invalid config")
    end

    Thread.main[:scheduler_running] = false
    @scheduler_thread = Thread.new { sched_loop }
    # don't kill the whole program if the sched-loop worker thread dies.
    # TODO: add detection and error recovery if worker thread dies.
    # we would leave this enabled for debugging purposes when trying to figure out when/why/how the
    # worker thread might die. that'll never happen, b/c my code (and Ruby) is basically perfect. ;-)
    @scheduler_thread.abort_on_exception = false
  end

  # TODO: add detection and error recovery in appropriate places if worker thread dies.
  def start
    Thread.main[:scheduler_running] = true
  end

  # TODO: add detection and error recovery in appropriate places if worker thread dies.
  def stop
    Thread.main[:scheduler_running] = false
  end

  # this could be better, by seeing what time we're executing at the first time through the loop,
  # and only sleeping enough to get into the next minute. otherwise recordings could be as many as 59
  # seconds behind the start of the minute.
  def sched_loop
    loop do
      # 0. check if scheduler should be active.
      if(Thread.main[:scheduler_running])
        # 1. check if config has changed.
        update_config if config_needs_refresh
        # 2. update active recording list/actions
        update_recording_channels
      end
      # lather, rinse, repeat.
      sleep 60
    end
  end

  def config_needs_refresh
    return true if(@config_file && File.mtime(@config_file) > @config_file_last_mtime)
    return false
  end

  def update_config
    @config_file_last_mtime = File.mtime(@config_file)
    @recordings = parse_config
  end

  def update_recording_channels(time = Time.now)
    raise ArgumentError.new("invalid time") unless time.class == Time
    # 1. find all recordings that should be running at the specified time.
    # 2. sort the running recordings based on the provided conflict resolution algorithm
    # 3. take the top most recording(s)
    current_channels = cull(time)

    # 4. stop any active recordings that have fallen out of the "should be currently recording" list
    ( @recorders_in_use.keys - current_channels).each { |channel| stop_recording(channel) }

    # 5. start any new recordings that have just been added to the "should be currently recording" list
    (current_channels - @recorders_in_use.keys).each { |channel| start_recording(channel) }
  end

  def cull(time)
    raise ArgumentError.new("invalid time") unless time.class == Time
    sorted_recording_collections = @recordings.sort { |a,b| @comparator.compare(time, a, b) }
    possible_recordings = sorted_recording_collections.select do |collection|
      collection[:recordings].any? { |rec| Recording.is_active(rec, time) }
    end
    possible_recordings.map { |recording_collection| recording_collection[:channel] }.take(@max_concurrent_channels)
  end
  alias_method :lookup, :cull

  def start_recording(channel)
    next_idle_recorder = @recorders.select { |recorder| ! @recorders_in_use.value?(recorder) }.first
    if(next_idle_recorder)
      puts "ch. #{channel}: Starting recording at "+Time.now.to_s
      @recorders_in_use[channel] = next_idle_recorder
      next_idle_recorder.start(channel)
    end
  end

  def stop_recording(channel)
    puts "ch. #{channel}: Stopping recording at "+Time.now.to_s
    # tiny bit of error checking, just so it doesn't blow up if someone calls this in the wrong order. shame on them.
    @recorders_in_use[channel].stop() if @recorders_in_use.key?(channel)
    @recorders_in_use.delete(channel)
  end

  def parse_config
    recordings = {}
    # do CSV stuff.
    # FIXME: should add some error checking to validate this input.
    CSV.foreach(@config_file, :headers => true) do |row|
      channel = row['channel'].to_i
      start_date = row['timestamp'][0,8]
      start_time = row['timestamp'][8,4]
      duration = row['duration']
      start = Time.new(start_date[0,4],start_date[4,2], start_date[6,2], start_time[0,2], start_time[2,2])
      end_date, end_time = (start+duration.to_i*60).strftime("%Y%m%d,%H%M").split(',')
      recordings[channel] = [] unless recordings.key?(channel)
      recordings[channel].push( {
                                  :start_date => start_date,
                                  :start_time => start_time,
                                  :end_date => end_date,
                                  :end_time => end_time
                                } )
    end
    # turn hashtable into array of hashtables.
    recordings.keys.map { |channel| { :channel => channel, :recordings => recordings[channel] } }
  end

  # typically this is only needed for testing purposes, so that we don't create
  # a lot of untracked threads.
  def destroy_worker
    @scheduler_thread.exit if @scheduler_thread
  end
end