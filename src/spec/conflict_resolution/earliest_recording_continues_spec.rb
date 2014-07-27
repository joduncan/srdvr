require 'rspec'
require_relative '../../conflict_resolution/earliest_recording_continues'

describe 'Earliest recording continues algorithm' do

  it 'should sort conflicting recordings based on their start times' do
    # make 2-3 conflicting recordings.
    rec1 = {
        :start_date =>20140615,
        :end_date =>20140615,
        :start_time => 615,
        :end_time => 700
    }
    rec2 = {
        :start_date =>20140615,
        :end_date =>20140615,
        :start_time => 630,
        :end_time => 700
    }
    rec3 = {
        :start_date =>20140615,
        :end_date =>20140615,
        :start_time => 645,
        :end_time => 730
    }
    # don't ask me who would record a 9.5 hr tv show, I'm sure there are folks/shows out there like this.
    rec4 = {
        :start_date =>20140614,
        :end_date =>20140615,
        :start_time => 1130,
        :end_time => 900
    }

    algo = EarliestRecordingContinues.new

    # sort them based on this class's sort method
    expect([rec2, rec1].sort( &algo.method(:compare) )).to match_array([rec1,rec2])

    expect([rec2,rec3,rec1].sort( &algo.method(:compare) )).to match_array([rec1,rec2,rec3])

    expect([rec2,rec1,rec3,rec4].sort( &algo.method(:compare) )).to match_array([rec4,rec1,rec2,rec3])

    # input validation test cases
    expect{[1,2,"four"].sort( &algo.method(:compare) )}.to raise_error(ArgumentError)

    expect{ [ {:a=>"whatever"}, {} ].sort( &algo.method(:compare) )}.to raise_error(ArgumentError)
  end
end