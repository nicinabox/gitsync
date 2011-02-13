#!/usr/bin/ruby
require "rubygems"
require 'trollop'

def sync
  #dir = ARGV[0] || abort("No path specified!")
  
  # Setup options
  opts = Trollop::options do
    opt :debug, "Show debug output", :default => false
    opt :interactive, "Interactive", :default => false
  end
  
  puts "Git sync started..." if opts[:debug]
  
  # Current working size
  orig_size = `du -s #{dir} | awk '{print $1}'`
  
  # Current status
  go = "cd #{dir} &&"
  status = %x(#{go} git status --porcelain).split("\n")
  untracked = %x(#{go} git ls-files -o -X .gitignore).split("\n")
  
  # Write protection
  sleep 1
  curr_size = `du -s #{dir} | awk '{print $1}'`
  while curr_size != orig_size
    orig = `du -s #{dir} | awk '{print $1}'`
    puts "Might be writing: orig: #{orig_size}, curr: #{curr_size}" if opts[:debug]
    sleep 3
    curr_size = `du -s #{dir} | awk '{print $1}'`
  end
  
  # Git
  unless status.empty?
    # Add all files
    puts %x(#{go} pwd)
    if opts[:interactive]
      print "\nAdd these files to staging?\n#{status.join("\n")}?\n[yn] "
      response = $stdin.gets.chomp
      exit if response == "n"
    end
    %x(cd #{dir} && git add -A)
     
    # Check to see what's been staged
    staged = %x(#{go} git ls-files).split("\n")
    porcelain = %x(#{go} git status --porcelain).split("\n")
    
    # Commit!
    if opts[:interactive]
      print "\nCommit #{s = staged.join(", ")}? [yn] "
      response == $stdin.gets.chomp
      exit if response == "n"
    end
    %x(cd #{dir} && git commit -qm "#{porcelain.join("\n")}")
    puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{staged.join(", ")}" if opts[:debug]
  else
    puts "Nothing to commit." if opts[:debug]
  end
  
end

sync