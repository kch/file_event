class FSEvent::FileEvent::DirectoryState
  attr_reader :path

  # * _path_: the path to a directory.
  # * _glob_: the glob pattern used to list the files in _path_.
  #
  # _glob_ is optional and defaults to "*".
  #
  # Don't use recursive globs (e.g.: "**/*"), FileEvent will create one
  # DirectoryState instance for each subfolder in a watched path, as need
  # arises.
  def initialize(path, glob = nil)
    @path       = File.expand_path(path)
    @glob       = glob || "*"
    @file_stats = {}
  end

  # Update the :hot status for the watched files in #path.
  #
  # A path is marked hot if:
  # * its _mtime_ is newer than it was during last #refresh!, or
  # * its _mtime_ is not older than 60 seconds and we don't have a previous
  #   _mtime_ entry for it.
  #
  # You can get a list of currently hot paths by calling #hot_paths.
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

  # Return the paths that have been marked :hot during last #refresh!.
  def hot_paths
    @file_stats.select { |k, hv| hv[:hot] }.map { |k, v| k }
  end

  # You should call touch on paths that you modify after a #refresh!.
  #
  # When your code updates a file that a path points to, this path may be sent
  # back to the fsevents stream, at which point it may change it again, and
  # now you risk entering a (potentially infinite) loop.
  #
  # #touch only needs to be called if you have modified the file at _path_.
  # It is, however, harmless to call it otherwise.
  def touch(path, time = Time.now)
    @file_stats[path][:mtime] = time
  end
end
