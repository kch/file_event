#!/usr//bin/env ruby
# encoding: UTF-8
$:.unshift File.join(File.dirname(__FILE__), '../lib')
require 'unicode_utils'
require 'fileutils'
require 'file_event'

class DowncaseExtensionFileEvent < FSEvent::FileEvent
  filter { |path| path =~ /\.([^.]?[A-Z][^.]?)+$/ }

  def on_file_change(path)
    temp_name = path + rand.to_s
    FileUtils.mv(path, temp_name)
    FileUtils.mv(temp_name, path.sub(/\.[^.]+$/) { |m| UnicodeUtils.downcase(m) })
  end
end


DowncaseExtensionFileEvent.watch("#{ENV['HOME']}/Desktop", :latency => 1.0)

trap(:INT) { puts; exit }
CFRunLoop.instance.thread.join
