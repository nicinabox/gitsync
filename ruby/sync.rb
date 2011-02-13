#!/usr/bin/ruby
require 'optparse'

def sync
  dir = ARGV[0] || abort("No path specified!")
  options = {}
  OptionParser.new do |o|
    o.banner = "Usage: gitsync.rb [-di] /path/to/repo/"
    o.on('-d', 'Show debugging output') { |b| options[:debug] = b }
    o.on('-i', 'Interactive') { |b| options[:interactive] = b }
    o.on('-h', 'Halps!') { puts o; exit }
    o.parse!
  end
  
  #p :debug => $debug, :interactive => $interactive
  puts "Git sync started..." if options[:debug]
  
  
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
    orig = `du -s $dir | awk '{print $1}'`
    puts "Might be writing: orig: #{orig_size}, curr: #{curr_size}" if options[:debug]
    sleep 3
    curr_size = `du -s #{dir} | awk '{print $1}'`
  end
  
  # Git
  unless status.empty?
    # Add all files
    puts %x(#{go} pwd)
    if options[:interactive]
      print "\nAdd these files to staging?\n#{status.join("\n")}?\n[yn] "
      response = $stdin.gets.chomp
      exit if response == "n"
    end
    %x(cd #{dir} && git add -A)
     
    # Check to see what's been staged
    staged = %x(#{go} git ls-files).split("\n")
    porcelain = %x(#{go} git status --porcelain).split("\n")
    
    # Commit!
    if options[:interactive]
      print "\nCommit #{s = staged.join(", ")}? [yn] "
      response == $stdin.gets.chomp
      exit if response == "n"
    end
    %x(cd #{dir} && git commit -qm "#{porcelain.join("\n")}")
    puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{staged.join(", ")}" if options[:debug]
  else
    puts "Nothing to commit." if options[:debug]
  end
  
end

sync