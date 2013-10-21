class Fwissr::Source

  autoload :File,    'fwissr/source/file'
  autoload :Mongodb, 'fwissr/source/mongodb'

  class << self
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

  attr_reader :options

  def initialize(options = { })
    @options = options

    @conf = nil
  end

  # source can be refreshed ?
  def can_refresh?
    @options && (@options['refresh'] == true)
  end

  # get conf
  def get_conf
    if (@conf && !self.can_refresh?)
      # return already fetched conf if refresh is not allowed
      @conf
    else
      # fetch conf
      @conf = self.fetch_conf
    end
  end

  # fetch conf from source
  def fetch_conf
    # MUST be implemented by child class
    raise "not implemented"
  end

end # class Fwissr::Source
