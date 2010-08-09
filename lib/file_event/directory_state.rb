class FSEvent::FileEvent::DirectoryState
  attr_reader :path

  def initialize(path, glob = nil)
    @path       = File.expand_path(path)
    @glob       = glob || "*"
    @file_stats = {}
  end

  def refresh!
    now = Time.now
    candidate_paths = Dir[File.join(path, @glob)].select { |path| File.file? path }
    (@file_stats.keys - candidate_paths).each { |k| @file_stats.delete(k) }
    candidate_paths.each do |path|
      h_stat            = @file_stats[path] ||= {}
      mtime             = File.mtime(path)
      h_stat[:hot]      = h_stat[:mtime]  ?  mtime > h_stat[:mtime]  :  now - mtime < 60.0 # ∆t in seconds
      h_stat[:mtime]    = mtime
      @file_stats[path] = h_stat
    end
    self
  end

  def touch(path, time = Time.now)
    @file_stats[path][:mtime] = time
  end

  def hot_paths
    @file_stats.select { |k, hv| hv[:hot] }.map { |k, v| k }
  end
end
