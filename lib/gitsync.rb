#!/usr/bin/env ruby

module Gitsync
  # Server app
  def self.autosync
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

  # Client app
  def self.sync
    # Setup options
    opts = Trollop::options do
      opt :dir, "Directory to watch", :type => String, :required => true 
      opt :debug, "Show debug output", :default => false
      opt :interactive, "Interactive", :default => false
      opt :pull, "git pull", :default => false
    end

    puts "Git sync started..." if opts[:debug]

    dir = opts[:dir]

    # Current status
    go = "cd #{dir} &&"
    status = %x(#{go} git status --porcelain).split("\n")
    untracked = %x(#{go} git ls-files -o -X .gitignore).split("\n")

    if opts[:pull] 
      output = %x(#{go} git pull)
      puts output
      exit
    end


    # Current working size
    orig_size = %x(du -s #{dir} | awk '{print $1}').chomp

    # Write protection
    sleep 1
    curr_size = %x(du -s #{dir} | awk '{print $1}').chomp
    while curr_size != orig_size
      orig = %x(du -s #{dir} | awk '{print $1}').chomp
      puts "Might be writing: orig: #{orig_size}, curr: #{curr_size}" if opts[:debug]
      sleep 3
      curr_size = %x(du -s #{dir} | awk '{print $1}').chomp
    end

    # Git
    unless status.empty?
      # Add all files
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
end