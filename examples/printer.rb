#!/usr//bin/env ruby
# encoding: UTF-8
$:.unshift File.join(File.dirname(__FILE__), '../lib')
require 'file_event'

watcher = FSEvent::FileEvent.watch("/Users/kch/Desktop") { |path| puts "File change detected: #{path}" }

puts "Watching #{watcher.directories.join(', ')}…"

trap(:INT) { puts; exit }      # ^C will exit gracefully
CFRunLoop.instance.thread.join # Wait for CFRunLoop
