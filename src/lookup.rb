#!/bin/env ruby

require_relative './scheduler'

scheduler = Scheduler.new(File.dirname(__FILE__)+File::SEPARATOR+'dvr.csv', 1)
ARGV.each do |timestamp|
  year = timestamp[0,4]
  month = timestamp[4,2]
  day = timestamp[6,2]
  hours = timestamp[8,2]
  minutes = timestamp[10,2]
  time = Time.new(year, month, day, hours, minutes)
  puts scheduler.lookup(time)
end