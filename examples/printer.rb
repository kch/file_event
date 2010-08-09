#!/usr//bin/env ruby
# encoding: UTF-8
$:.unshift File.join(File.dirname(__FILE__), '../lib')
require 'file_event'

class PrinterFileEvent < FSEvent::FileEvent
  def on_file_change(path)
    puts "File change detected: #{path}"
  end
end

watcher = PrinterFileEvent.watch("/Users/kch/Desktop", :latency => 0.1)

puts "Watching #{watcher.directories.join(', ')}…"

trap(:INT) { puts; exit }
CFRunLoop.instance.thread.join
