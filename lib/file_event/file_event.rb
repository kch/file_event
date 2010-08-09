class FSEvent::FileEvent < FSEvent
  def self.filters #:nodoc:
    @filters ||= []
  end

  # call-seq:
  #   filter { |path| block }
  #
  # Adds a condition that each path must pass before it's passed to #on_file_change
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

  # call-seq:
  #   on_file_change(path)
  #   on_file_change(*paths)
  #
  # Override this in your subclass to handle file change notifications.
  #
  # Two forms are accepted:
  #
  # * with a single _path_ argument, in which case the method will be called
  #   repeatedly, once for each file path that changed;
  #
  # * with a splat *_paths_ argument, in which case the method will be only
  #   called once, with all paths passed as arguments.
  def on_file_change(*paths)
    raise NotImplementedError, "Subclasses of FSEvent::FileEvent must implement on_file_change(*paths) or on_file_change(path)"
  end

  # You should call touch on paths that you modify during #on_file_change.
  #
  # See FSEvent::FileEvent::DirectoryState#touch for more.
  def touch(file_path)
    file_path = File.expand_path(file_path)
    directory_state_for_path(File.dirname(file_path)).touch(file_path)
  end

  def start #:nodoc:
    super
    @run_loop.thread.abort_on_exception = true
  end


  private

  def on_change(paths) #:nodoc:
    file_paths = changed_file_paths_from_changed_directory_paths(paths)
    case method(:on_file_change).arity
    when -1 then on_file_change(*file_paths)
    when  1 then file_paths.each { |path| on_file_change path }
    else raise ArgumentError, "on_file_change takes either one path argument or one splat *paths argument."
    end
  end

  def changed_file_paths_from_changed_directory_paths(dir_paths) #:nodoc:
    dir_paths.uniq\
      .map    { |dir_path | hot_files_for_directory_path(dir_path) }.flatten\
      .select { |file_path| self.class.filters.all? { |f| f[file_path] } }
  end

  def hot_files_for_directory_path(dir_path) #:nodoc:
    directory_state_for_path(dir_path).refresh!.hot_paths
  end

  def directory_state_for_path(dir_path) #:nodoc:
    dir_path = File.expand_path(dir_path)
    @directory_states[dir_path] ||= FSEvent::FileEvent::DirectoryState.new(dir_path, @watched_paths_glob)
  end

end

require File.join(File.dirname(__FILE__), 'directory_state')
