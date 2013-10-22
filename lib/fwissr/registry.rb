require 'thread'

module Fwissr

  class Registry

    # refresh period in seconds
    DEFAULT_REFRESH_PERIOD = 15

    #
    # API
    #

    attr_reader :refresh_period

    def initialize(options = { })
      @refresh_period = options['refresh_period'] || DEFAULT_REFRESH_PERIOD

      @sources   = [ ]
      @registry  = nil
      @last_load = nil

      @semaphore      = Mutex.new
      @is_refreshing  = false
      @refresh_thread = nil
    end

    def add_source(source)
      @sources << source
    end

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

      cur_hash.freeze

      cur_hash
    end

    alias :[] :get

    def keys
      result = [ ]
      _keys(result, [ ], registry)
      result.sort
    end

    def dump
      self.registry
    end


    #
    # PRIVATE
    #

    def is_fresh?
      @registry && @last_load && ((Time.now - @last_load) < @refresh_period)
    end

    def is_refreshing?
      (@is_refreshing == true)
    end

    def must_refresh?
      @refresh_period && (@refresh_period > 0) && !self.is_fresh? && !self.is_refreshing?
    end

    def refresh_thread
      @refresh_thread
    end

    def do_refresh
      @semaphore.synchronize do
        if self.must_refresh?
          if @registry.nil?
            # load synchronously for the first time
            self.load_registry
          else
            # refresh asynchronously
            @is_refreshing = true
            @refresh_thread = Thread.new do
              begin
                self.load_registry
              ensure
                @is_refreshing = false
              end
            end
          end
        end
      end
    end

    def registry
      if self.must_refresh?
        self.do_refresh
      end

      @registry
    end

    def load_registry
      result = { }

      @sources.each do |source|
        source_conf = source.get_conf
        result = Fwissr.merge_conf!(result, source_conf)
      end

      @registry  = result
      @last_load = Time.now
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
