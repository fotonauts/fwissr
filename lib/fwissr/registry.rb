require 'thread'

module Fwissr

  class Registry

    # refresh period in seconds
    DEFAULT_REFRESH_PERIOD = 30

    #
    # API
    #

    attr_reader :refresh_period

    def initialize(options = { })
      @refresh_period = options['refresh_period'] || DEFAULT_REFRESH_PERIOD

      @registry = { }
      @sources  = [ ]

      # mutex for @registry and @sources
      @semaphore = Mutex.new

      @refresh_thread = nil
    end

    def add_source(source)
      @semaphore.synchronize do
        @sources << source

        Fwissr.merge_conf!(@registry, source.get_conf)
      end

      self.ensure_refresh_thread
    end

    def reload!
      self.reset!
      self.load!
    end

    def get(key)
      # split key
      key_ary = key.split('/')

      # remove first empty part
      key_ary.shift if (key_ary.first == '')

      cur_hash = self.registry.dup
      key_ary.each do |key_part|
        cur_hash = cur_hash[key_part]
        return nil if cur_hash.nil?
      end

      cur_hash.freeze

      cur_hash
    end

    alias :[] :get

    def keys
      result = [ ]
      _keys(result, [ ], self.registry.dup)
      result.sort
    end

    def dump
      self.registry.dup
    end


    #
    # PRIVATE
    #

    def refresh_thread
      @refresh_thread
    end

    def have_refreshable_source?
      @semaphore.synchronize do
        !@sources.find { |source| source.can_refresh? }.nil?
      end
    end

    def ensure_refresh_thread
      # check refresh thread state
      if ((@refresh_period > 0) && self.have_refreshable_source?) && (!@refresh_thread || !@refresh_thread.alive?)
        # (re)start refresh thread
        @refresh_thread = Thread.new do
          while(true) do
            sleep(@refresh_period)
            self.load!
          end
        end
      end
    end

    def reset!
      @semaphore.synchronize do
        @registry = { }

        @sources.each do |source|
          source.reset!
        end
      end
    end

    def load!
      @semaphore.synchronize do
        @registry = { }

        @sources.each do |source|
          source_conf = source.get_conf
          Fwissr.merge_conf!(@registry, source_conf)
        end
      end
    end

    def registry
      self.ensure_refresh_thread

      @registry
    end

    # helper for #keys
    def _keys(result, key_ary, hash)
      hash.each do |key, value|
        key_ary << key
        result << "/#{key_ary.join('/')}"
        _keys(result, key_ary, value) if value.is_a?(Hash)
        key_ary.pop
      end
    end

  end # module Registry

end # module Fwissr
