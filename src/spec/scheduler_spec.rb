require 'rspec'

describe 'Scheduler class' do

  it 'should validate initialization parameters' do
    sched1 = Scheduler.new()
  end

  # if you don't get too far into the class internals, this becomes just an interface test
  it 'should be able to start scheduling recordings' do

  end

  # if you don't get too far into the class internals, this becomes just an interface test
  it 'should be able to stop scheduling recordings' do

  end

  # how to test the "event" loop?

  it 'should be able to tell a recorder to start recording' do

  end

  it 'should be able to tell a recorder to stop recording' do

  end

  it 'should schedule conflicting programs correctly according to the provided algorithm' do

    true.should == false
  end

  it 'return which show is scheduled to be recorded based on the input date/time' do

    true.should == false
  end

end