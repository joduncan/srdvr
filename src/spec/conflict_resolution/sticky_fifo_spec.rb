require 'rspec'
require_relative '../../conflict_resolution/sticky_fifo'

describe 'Sticky Fifo comparator' do

  it 'should should sort channels based on which program starts first, with preference to channels that are already recording' do

    rec1 = {
        :start_date =>"20140615",
        :end_date =>"20140615",
        :start_time => "615",
        :end_time => "700"
    }
    rec2 = {
        :start_date =>"20140615",
        :end_date =>"20140615",
        :start_time => "630",
        :end_time => "730"
    }
    rec3 = {
        :start_date =>"20140615",
        :end_date =>"20140615",
        :start_time => "700",
        :end_time => "730"
    }
    # don't ask me who would record a 9.5 hr tv show, I'm sure there are folks/shows out there like this.
    rec4 = {
        :start_date =>"20140614",
        :end_date =>"20140615",
        :start_time => "1130",
        :end_time => "900"
    }
    rec5 = {
        :start_date =>"20140615",
        :end_date =>"20140615",
        :start_time => "615",
        :end_time => "645"
    }

    ch1 = { :channel => 130, :recordings => [rec1,rec3] }
    ch2 = { :channel => 131, :recordings => [rec2] }
    ch3 = { :channel => 129, :recordings => [rec4] }

    algo = StickyFifo.new

    # sort them based on this class's sort method
    time = Time.new(2014,06,15,06,30)
    expect([ch2, ch1].sort { |a,b| algo.compare(time, a, b) }).to match_array([ch1,ch2])

    time = Time.new(2014,06,15,07,00)
    expect([ch2, ch1].sort { |a,b| algo.compare(time, a, b) }).to match_array([ch1, ch2])

    time = Time.new(2014,06,15,07,10)
    expect([ch2, ch1].sort { |a,b| algo.compare(time, a, b) }).to match_array([ch1, ch2])

    time = Time.new(2014,06,15,06,20)
    expect([ch2, ch3, ch1].sort { |a,b| algo.compare(time, a, b) }).to match_array([ch3,ch1,ch2])

    # input validation test cases. exact time for the comparison doesn't matter.
    expect{[1,2,"four"].sort { |a,b| algo.compare(time, a, b) } }.to raise_error(ArgumentError)

    expect{ [ {:a=>"whatever"}, {} ].sort { |a,b| algo.compare(time, a, b) } }.to raise_error(ArgumentError)
  end
end