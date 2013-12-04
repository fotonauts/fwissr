# @abstract Subclass and override {#fetch_conf} to implement a configuration source.
class Fwissr::Source

  autoload :File,    'fwissr/source/file'
  autoload :Mongodb, 'fwissr/source/mongodb'

  class << self
    # Instanciate source from settings
    #
    # @param settings [Hash] Source settings
    # @return [Fwissr::Source::File, Fwissr::Source::Mongodb] Source instance
    def from_settings(settings)
      raise "Unexpected source settings class: #{settings.inspect}" unless settings.is_a?(Hash)

      if settings['filepath']
        Fwissr::Source::File.from_settings(settings)
      elsif settings['mongodb']
        Fwissr::Source::Mongodb.from_settings(settings)
      else
        raise "Unexpected source settings kind: #{settings.inspect}"
      end
    end
  end # class << self


  #
  # API
  #

  # [Hash] Source options
  attr_reader :options

  # Init
  def initialize(options = { })
    @options = options

    @conf = nil
  end

  # Reset source
  def reset!
    @conf = nil
  end

  # Source can be refreshed ?
  #
  # @return [true,false] Is it a refreshable source ?
  def can_refresh?
    @options && (@options['refresh'] == true)
  end

  # Get source conf
  #
  # @return [Hash] The source's configuration
  def get_conf
    if (@conf && !self.can_refresh?)
      # return already fetched conf if refresh is not allowed
      @conf
    else
      # fetch conf
      @conf = self.fetch_conf
    end
  end

  # Fetch conf from source
  #
  # @abstract MUST be implemented by child class
  #
  # @return [Hash] The source's configuration
  def fetch_conf
    raise "not implemented"
  end

end # class Fwissr::Source
