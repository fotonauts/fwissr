require 'thread'

module Fwissr

  class Registry

    # refresh period in seconds
    DEFAULT_REFRESH_PERIOD = 30

    #
    # API
    #

    # [Integer] Refresh period
    attr_reader :refresh_period

    # Init
    def initialize(options = { })
      @refresh_period = options['refresh_period'] || DEFAULT_REFRESH_PERIOD

      @registry = { }
      @sources  = [ ]

      # mutex for @registry and @sources
      @semaphore = Mutex.new

      @refresh_thread = nil
    end

    # Add a source to registry
    #
    # @param source [Fwissr::Source] Concrete source instance
    def add_source(source)
      @semaphore.synchronize do
        @sources << source
      end

      if @registry.frozen?
        # already frozen, must reload everything
        self.reload!
      else
        @semaphore.synchronize do
          Fwissr.merge_conf!(@registry, source.get_conf)
        end
      end

      self.ensure_refresh_thread
    end

    # Reload the registry
    def reload!
      self.reset!
      self.load!
    end

    # Get a registry key value
    #
    # @param key [String] Key
    # @return [Object] Value
    def get(key)
      # split key
      key_ary = key.split('/')

      # remove first empty part
      key_ary.shift if (key_ary.first == '')

      cur_hash = self.registry
      key_ary.each do |key_part|
        cur_hash = cur_hash[key_part]
        return nil if cur_hash.nil?
      end

      cur_hash
    end

    alias :[] :get

    # Get all keys in registry
    #
    # @return [Array] Keys list
    def keys
      result = [ ]
      _keys(result, [ ], self.registry)
      result.sort
    end

    # Dump the registry
    #
    # @return [Hash] The entire registry
    def dump
      self.registry
    end


    #
    # PRIVATE
    #

    # @api private
    def refresh_thread
      @refresh_thread
    end

    # @api private
    #
    # @return [true,false] Is there at least one refreshable source ?
    def have_refreshable_source?
      @semaphore.synchronize do
        !@sources.find { |source| source.can_refresh? }.nil?
      end
    end

    # @api private
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

    # @api private
    def ensure_frozen
      if !@registry.frozen?
        @semaphore.synchronize do
          Fwissr.deep_freeze(@registry)
        end
      end
    end

    # @api private
    def reset!
      @semaphore.synchronize do
        @registry = { }

        @sources.each do |source|
          source.reset!
        end
      end
    end

    # @api private
    def load!
      @semaphore.synchronize do
        @registry = { }

        @sources.each do |source|
          source_conf = source.get_conf
          Fwissr.merge_conf!(@registry, source_conf)
        end
      end
    end

    # @api private
    def registry
      self.ensure_refresh_thread
      self.ensure_frozen

      @registry
    end

    # Helper for #keys
    #
    # @api private
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
