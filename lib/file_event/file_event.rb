class FSEvent::FileEvent < FSEvent
  def self.filters
    @filters ||= []
  end

  def self.filter(&block)
    filters << block
  end

  def initialize(paths, options = {})
    super(paths)
    self.latency          = options[:latency] if options[:latency]
    extensions            = options.values_at(:extension, :extensions).flatten.compact
    options[:glob]      ||= "*.{#{extensions.join(",")}}" unless extensions.empty?
    @watched_paths_glob   = options[:glob]
    @directory_states     = {}
  end

  def on_change(paths)
    file_paths = changed_file_paths_from_changed_dir_paths(paths)
    case method(:on_file_change).arity
    when -1 then on_file_change(*file_paths)
    when  1 then file_paths.each { |path| on_file_change path }
    else raise ArgumentError, "on_file_change takes either one path argument or one splat *paths argument."
    end
  end

  def touch(path)
    directory_state_for_path(File.dirname(path)).touch(path)
  end

  def start
    super
    @run_loop.thread.abort_on_exception = true
  end


  private

  def on_file_change(*paths)
    raise NotImplementedError, "Subclasses of FSEventFoo must implement on_file_change(*paths) or on_file_change(path)"
  end

  def changed_file_paths_from_changed_dir_paths(dir_paths)
    dir_paths.uniq\
      .map    { |path| hot_files_for_path(path) }.flatten\
      .select { |path| self.class.filters.all? { |f| f[path] } }
  end

  def directory_state_for_path(path)
    path = File.expand_path(path)
    @directory_states[path] ||= FSEvent::FileEvent::DirectoryState.new(path, @watched_paths_glob)
  end

  def hot_files_for_path(path)
    directory_state_for_path(path).refresh!.hot_paths
  end

end

require File.join(File.dirname(__FILE__), 'directory_state')
