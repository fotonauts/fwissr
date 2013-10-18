class Fwissr::Source::File < Fwissr::Source

  class << self

    def from_path(path, options = { })
      if path.nil? || (path == '')
        raise "Unexpected file source path: #{path.inspect}"
      end

      self.new(path, options)
    end

    def from_settings(settings)
      options = settings.dup
      options.delete('filepath')

      self.from_path(settings['filepath'], options)
    end

  end # class << self


  TOP_LEVEL_CONF_FILES = [ 'fwissr', 'config' ].freeze

  attr_reader :path, :options

  #
  # API
  #

  def initialize(path, options = { })
    raise "File not found: #{path}" if !::File.exists?(path)

    @path    = path
    @options = options
  end

  def fetch_conf
    result = { }

    conf_files = if ::File.directory?(@path)
      Dir[@path + "/*.{json,yml}"].sort
    else
      [ @path ]
    end

    conf_files.each do |conf_file_path|
      next unless ::File.file?(conf_file_path)

      self.merge_conf_file!(result, conf_file_path)
    end

    result
  end


  #
  # PRIVATE
  #

  def merge_conf_file!(result, conf_file_path)
    # parse conf file
    conf = Fwissr.parse_conf_file(conf_file_path)
    if conf
      conf_file_name = ::File.basename(conf_file_path, ::File.extname(conf_file_path))

      result_part = result

      unless TOP_LEVEL_CONF_FILES.include?(conf_file_name) || @options['top_level']
        # merge conf at the correct place in registry
        #
        # eg: my_app.json               => /my_app
        #     my_app.database.yml       => /my_app/database
        #     my_app.database.slave.yml => /my_app/database/slave
        key_ary = conf_file_name.split('.')
        key_ary.each do |key_part|
          result_part = (result_part[key_part] ||= { })
        end
      end

      Fwissr.merge_conf!(result_part, conf)
    else
      raise "Failed to parse conf file: #{conf_file_path}"
    end
  end

end # class Fwissr::Source::File
