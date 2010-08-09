#!/usr//bin/env ruby
# encoding: UTF-8
$:.unshift File.join(File.dirname(__FILE__), '../lib')
require 'shellwords'
require 'file_event'

class RevealExtensionFileEvent < FSEvent::FileEvent
  PATH_TO_DEVELOPER          = "/Developer/usr/bin"
  PATH_TO_GET_FILE_INFO_TOOL = "#{PATH_TO_DEVELOPER}/GetFileInfo"
  PATH_TO_SET_FILE_TOOL      = "#{PATH_TO_DEVELOPER}/SetFile"
  filter { |path| `#{PATH_TO_GET_FILE_INFO_TOOL} -ae #{path.shellescape}`.chomp.to_i == 1 }

  def on_file_change(path)
    system "#{PATH_TO_SET_FILE_TOOL} -a e #{path.shellescape}"
    touch   path
  end
end


RevealExtensionFileEvent.watch("#{ENV['HOME']}/Desktop", :extensions => %w[ rb txt xml html png ], :latency => 1.0)

trap(:INT) { puts; exit }
CFRunLoop.instance.thread.join
