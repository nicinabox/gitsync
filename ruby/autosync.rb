#!/usr/bin/ruby
require "rubygems"
require 'trollop'

def sync
  dir = ARGV[0] || abort("No path specified!")
  
  # Setup options
  opts = Trollop::options do
    opt :debug, "Show debug output", :default => false
    opt :frequency, "Frequency to run", :default => 10
    opt :exclude, "Exclude files from size check", :default => "synclog"
  end
  
  puts "Git sync started..." if opts[:debug]
  
  x = "--exclude=#{opts[:exclude]}"
  
  while true
    curr = `du -s #{dir} | awk '{print $1}'`
    prev = curr
  
    while curr == prev
      puts "No change, waiting #{opts[:frequency]} seconds" if opts[:debug]
    
      sleep opts[:frequency].to_i
      curr = `du -s #{dir} #{x} | awk '{print $1}'`
    end
  
    sleep 1
    orig = `du -s #{dir} #{x} | awk '{print $1}'`
    while curr != orig
      orig = `du -s #{dir} #{x} | awk '{print $1}'`
      puts "Might be writing: orig: #{orig}, curr: #{curr}" if opts[:debug]
      sleep 3
      curr = `du -s #{dir} #{x} | awk '{print $1}'`
    end
  
    msg = `cd #{dir} && git status --porcelain`
    `cd #{dir} && git add -A` 
    `cd #{dir} && git commit -qam "#{msg}"`
  
    puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} Committed" if opts[:debug]
  end
  
end

sync