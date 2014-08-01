require 'rspec'
require_relative '../scheduler'
require_relative '../conflict_resolution/naive_fifo'

describe 'Scheduler class' do

  it 'should validate initialization parameters' do
    expect{ Scheduler.new([],1,NaiveFifo) }.not_to raise_error
    # TODO: add real error checking in scheduler class so that this either doesn't error,
    # or throws an argument error instead of a name error.
    test_scheduler = ""

    expect{ test_scheduler = Scheduler.new([]) }.not_to raise_error
    expect( Thread.main[:scheduler_running] ).to equal(false)
    test_scheduler.destroy_worker

    expect{ test_scheduler = Scheduler.new([],6) }.not_to raise_error
    expect( Thread.main[:scheduler_running] ).to equal(false)
    test_scheduler.destroy_worker

    expect{ test_scheduler = Scheduler.new([],2,"NaiveFifo") }.to raise_error(NameError)
    expect{ test_scheduler = Scheduler.new(4) }.to raise_error(ArgumentError)
    expect( Thread.main[:scheduler_running] ).to equal(false)
  end

  # if you don't get too far into the class internals, this becomes just an interface test
  it 'should be able to start and stop scheduling recordings' do
    test_sched = Scheduler.new([],4)
    test_sched.start
    expect(Thread.main[:scheduler_running]).to equal(true)
    test_sched.stop
    expect(Thread.main[:scheduler_running]).to equal(false)
    test_sched.destroy_worker
  end

  # these should be split up. I don't want to mock up half the class (twice) to test this, though.
  it 'should be able to tell a recorder to start and stop recording a channel' do
    test_sched = Scheduler.new([], 2)
    expect { test_sched.start_recording(5) }.to output(/ch. 5: Starting recording at/).to_stdout
    expect { test_sched.stop_recording(5) }.to output(/ch. 5: Stopping recording at/).to_stdout
  end

  it 'should return which show is scheduled to be recorded based on the input date/time' do
    test1 = Scheduler.new(File.dirname(__FILE__)+File::SEPARATOR+"sample_cfg_1.csv", 2)
    time = Time.new(2014,7,30,17,50)
    expect(test1.lookup(time)).to match_array([10])
    time = Time.new(2014,7,30,18,50)
    expect(test1.lookup(time)).to match_array([5])
    time = Time.new(2014,7,30,20,00)
    expect(test1.lookup(time)).to match_array([5, 12])

    test1 = Scheduler.new(File.dirname(__FILE__)+File::SEPARATOR+"sample_cfg_2.csv", 1, NaiveFifo)
    time = Time.new(2014,7,31,06,29)
    expect(test1.lookup(time)).to match_array([20])
    time = Time.new(2014,7,31,06,30)
    expect(test1.lookup(time)).to match_array([25])
    time = Time.new(2014,7,31,06,31)
    expect(test1.lookup(time)).to match_array([25])
  end

  it 'should detect if the config file has been updated' do
    test_sched = Scheduler.new(File.dirname(__FILE__)+File::SEPARATOR+"sample_cfg_1.csv", 1)
    sleep 1
    FileUtils.touch(File.dirname(__FILE__)+File::SEPARATOR+"sample_cfg_1.csv")
    expect(test_sched.config_needs_refresh).to equal(true)
  end

  it 'should not detect config file changes when not using a config file' do
    test_sched = Scheduler.new([], 1)
    expect(test_sched.config_needs_refresh).to equal(false)
  end

  it 'should accept an array for the source of the list of recordings, for the sake of testing(or future expanded APIs)' do
    recordings = [
        {:channel =>7,
         :recordings => [
             {
                 :start_date=>"20140729",
                 :start_time=>"1030",
                 :end_date=>"20140729",
                 :end_time=>"1130"
             },
             {
                 :start_date=>"20140805",
                 :start_time=>"2230",
                 :end_date=>"20140806",
                 :end_time=>"0000"
             }
         ]
        },
        {:channel =>42,
         :recordings => [
             {
                 :start_date=>"20140731",
                 :start_time=>"1800",
                 :end_date=>"20140731",
                 :end_time=>"1900"
             },
             {
                 :start_date=>"20140802",
                 :start_time=>"2000",
                 :end_date=>"20140802",
                 :end_time=>"2030"
             }
         ]
        }
    ]
    expect { test_sched = Scheduler.new(recordings, 1) }.not_to raise_error
  end
end