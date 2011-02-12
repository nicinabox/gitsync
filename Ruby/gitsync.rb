#!/usr/bin/ruby
def sync
  dir = ARGV[0]
  time = ARGV[1]
  debug = ARGV[2] || false
  
  puts "Git sync started..." if debug
  
  while true
    curr = `du -s #{dir} | awk '{print $1}'`
    prev = curr
  
    while curr == prev
      puts "No change, waiting #{time} seconds" if debug
    
      sleep time.to_i
      curr = `du -s #{dir} | awk '{print $1}'`
    end
  
    sleep 1
    orig = `du -s #{dir} | awk '{print $1}'`
    while curr != orig
      orig = `du -s $dir | awk '{print $1}'`
      puts "Might be writing: orig: #{orig}, curr: #{curr}" if debug
      sleep 3
      curr = `du -s #{dir} | awk '{print $1}'`
    end
  
    msg = `cd #{dir} && git status --porcelain`
    `cd #{dir} && git add -A` 
    `cd #{dir} && git commit -qam "#{msg}"`
  
    puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} Committed" if debug
  end
  
end

sync