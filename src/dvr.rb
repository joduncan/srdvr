#!/bin/env ruby
require_relative './scheduler'

scheduler = Scheduler.new(File.dirname(__FILE__)+File::SEPARATOR+'dvr.csv', 1)
scheduler.start
while(1)
  sleep 5
end
