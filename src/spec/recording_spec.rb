require 'rspec'
require_relative '../recording'

describe 'is_active API' do

  it 'should should return true if a time is within the recordings timeframe ' do
    rec1 = { :start_date => "20140912",
             :start_time => "1700",
             :end_date => "20140912",
             :end_time => "1900"
           }
    rec2 = { :start_date => "20140912",
             :start_time => "1700",
             :end_date => "20140913",
             :end_time => "1900"
           }

    expect(Recording.is_active(rec1, Time.new(2014,9,12,17,00))).to equal(true)
    expect(Recording.is_active(rec2, Time.new(2014,9,13,18,00))).to equal(true)
    expect(Recording.is_active(rec2, Time.new(2014,9,13,8,00))).to equal(true)
  end

  it 'should should return false if a time is not within the recordings timeframe ' do
    rec1 = { :start_date => "20140912",
             :start_time => "1700",
             :end_date => "20140912",
             :end_time => "1900"
           }
    rec2 = { :start_date => "20140912",
             :start_time => "1700",
             :end_date => "20140913",
             :end_time => "1900"
           }
    expect(Recording.is_active(rec1, Time.new(2014,9,12,19,00))).to equal(false)
    expect(Recording.is_active(rec1, Time.new(2014,9,13,18,00))).to equal(false)
    expect(Recording.is_active(rec2, Time.new(2014,9,13,22,00))).to equal(false)
  end
end