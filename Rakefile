require 'rbconfig'

task :default => :setup

desc "Clone the fsevent submodule and run make on it"
task :setup do
  system "git submodule init"
  system "git submodule update"
  Dir.chdir "vendor/fsevent/ext"
  ruby = File.join(*Config::CONFIG.values_at('bindir', 'ruby_install_name'))
  system "#{ruby} extconf.rb"
  system "make"
end
