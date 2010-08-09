#!/usr//bin/env ruby
# encoding: UTF-8
$:.unshift File.join(File.dirname(__FILE__), '../lib')
require 'shellwords'
require 'file_event'

class SetEncodingXattrFileEvent < FSEvent::FileEvent
  PATH_TO_FILE_TOOL                 = "/usr/bin/file"
  PATH_TO_XATTR_TOOL                = "/usr/bin/xattr"
  TEXT_ENCODING_ATTR_NAME           = "com.apple.TextEncoding"
  TEXT_ENCODING_ATTR_VALUE_FOR_UTF8 = "UTF-8;134217984"
  filter { |path| `#{PATH_TO_FILE_TOOL} -b --mime-encoding #{path.shellescape}` =~ /utf-8|ascii/i }

  def on_file_change(path)
    system "#{PATH_TO_XATTR_TOOL} -w #{TEXT_ENCODING_ATTR_NAME} '#{TEXT_ENCODING_ATTR_VALUE_FOR_UTF8}' #{path.shellescape}"
    touch   path
  end
end


SetEncodingXattrFileEvent.watch("#{ENV['HOME']}/Desktop", :extension => "txt", :latency => 1.0)

trap(:INT) { puts; exit }
CFRunLoop.instance.thread.join
