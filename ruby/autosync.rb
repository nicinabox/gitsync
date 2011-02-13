#!/usr/bin/ruby
require "rubygems"
require 'trollop'

def sync
  # Setup options
  opts = Trollop::options do
    opt :dir, "Directory to watch", :type => String, :required => true 
    opt :verbose, "Show verbose output", :default => false
    opt :frequency, "Frequency to run", :default => 10
  end
    
  puts "Git sync started..." if opts[:verbose]
  
  dir = opts[:dir]
  
  while true
    curr = %x(du -s #{dir} | awk '{print $1}').chomp
    prev = curr
  
    while curr == prev
      #puts "No change, waiting #{opts[:frequency]} seconds" if opts[:verbose]
      sleep opts[:frequency].to_i
      curr = %x(du -s #{dir} | awk '{print $1}').chomp
    end
  
    sleep 1
    orig = %x(du -s #{dir} | awk '{print $1}').chomp
    while curr != orig
      orig = %x(du -s #{dir} | awk '{print $1}').chomp
      puts "File being written. Waiting..." if opts[:verbose]
      sleep 4
      curr = %x(du -s #{dir} | awk '{print $1}').chomp
    end
  
    puts "Adding files..." if opts[:verbose]
    msg = `cd #{dir} && git status --porcelain`
    %x(cd #{dir} && git add -A)
    %x(cd #{dir} && git commit -qm "#{msg}")
  
    puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} Committed" if opts[:verbose]
    puts "Watching for change..." if opts[:verbose]
  end
  
end

sync