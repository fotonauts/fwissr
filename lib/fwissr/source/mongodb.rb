require 'uri'

class Fwissr::Source::Mongodb < Fwissr::Source

  class << self

    def from_settings(settings)
      if settings['mongodb'].nil? || (settings['mongodb'] == '') || settings['collection'].nil? || (settings['collection'] == '')
        raise "Erroneous mongodb settings: #{settings.inspect}"
      end

      uri = URI.parse(settings['mongodb'])
      db_name = uri.path[1..-1]

      if db_name.nil? || (db_name == '')
        raise "Erroneous mongodb settings: #{settings.inspect}"
      end

      options = settings.dup
      options.delete('mongodb')
      options.delete('collection')

      self.new(connection_for_uri(settings['mongodb']), db_name, settings['collection'], options)
    end

    def connections
      @connections ||= { }
    end

    def connection_for_uri(uri)
      self.connections[uri] ||= ::Mongo::MongoClient.from_uri(uri)
    end

  end # class << self


  TOP_LEVEL_COLLECTIONS = [ 'fwissr', 'config' ].freeze

  attr_reader :conn, :db_name, :collection_name, :options

  #
  # API
  #

  def initialize(conn, db_name, collection_name, options = { })
    @conn            = conn
    @db_name         = db_name
    @collection_name = collection_name
    @options         = options
  end

  def fetch_conf
    result = { }
    result_part = result

    unless TOP_LEVEL_COLLECTIONS.include?(@collection_name) || @options['top_level']
      # merge conf at the correct place in registry
      #
      # eg: m_app                 => /my_app
      #     my_app.database       => /my_app/database
      #     my_app.database.slave => /my_app/database/slave
      key_ary = @collection_name.split('.')
      key_ary.each do |key_part|
        result_part = (result_part[key_part] ||= { })
      end
    end

    # build conf hash from collection's documents
    conf = { }
    self.collection.find().each do |doc|
      key = doc['_id']
      value = if doc['value'].nil?
        doc.delete('_id')
        doc
      else
        doc['value']
      end

      conf[key] = value
    end

    Fwissr.merge_conf!(result_part, conf)

    result
  end


  #
  # Private
  #

  def collection
    @collection ||= @conn.db(@db_name).collection(@collection_name)
  end

end # class Fwissr::Source::Mongodb
