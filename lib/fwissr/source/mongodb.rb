require 'uri'

begin
  require 'moped'
rescue LoadError
  begin
    require 'mongo'
  rescue LoadError
    raise "[fwissr] Can't find any suitable mongodb driver: please install 'mongo' or 'moped' gem"
  end
end

# Mongodb based source
class Fwissr::Source::Mongodb < Fwissr::Source

  # A mongodb connection
  # @api private
  class Connection

    # [String] Database name
    attr_reader :db_name

    # Init
    def initialize(uri)
      raise "URI is missing: #{uri}" if (uri.nil? || uri == '')

      @uri = uri
      @collections = { }

      @kind = if defined?(::Moped)
        # moped driver
        :moped
      elsif defined?(::Mongo::MongoClient)
        # mongo ruby driver < 2.0.0
        :mongo
      elsif defined?(::Mongo::Client)
        raise "Sorry, mongo gem >= 2.0 is not supported yet"
      else
        raise "Can't find any suitable mongodb driver: please install 'mongo' or 'moped' gem"
      end

      # parse URI
      parsed_uri = URI.parse(@uri)
      @db_name = parsed_uri.path[1..-1]

      if @db_name.nil? || (@db_name == '')
        raise "Missing database in mongodb settings: #{settings['mongodb'].inspect}"
      end
    end

    # Database connection
    def conn
      @conn ||= begin
        case @kind
        when :moped
          ::Moped::Session.connect(@uri)
        when :mongo
          ::Mongo::MongoClient.from_uri(@uri)
        end
      end
    end

    # Database collection
    #
    # @param col_name [String] Collection name
    # @return [Object] Collection handler
    def collection(col_name)
      @collections[col_name] ||= begin
        case @kind
        when :moped
          self.conn[col_name]
        when :mongo
          self.conn.db(@db_name).collection(col_name)
        end
      end
    end

    # Returns an Enumerator for all documents from given collection
    #
    # @param col_name [String] Collection name
    # @return [Enumerator] Collection enumerator
    def fetch(col_name)
      case @kind
      when :moped, :mongo
        self.collection(col_name).find()
      end
    end

    # Insert document in collection
    #
    # @param col_name [String] Collection name
    # @param doc [Hash] Document to insert
    def insert(col_name, doc)
      case @kind
      when :moped, :mongo
        self.collection(col_name).insert(doc)
      end
    end

    # Create a collection
    #
    # @param col_name [String] Collection name
    def create_collection(col_name)
      case @kind
      when :moped
        # NOOP
      when :mongo
        self.conn.db(@db_name).create_collection(col_name)
      end
    end

    # Drop database
    #
    # @param db_name [String] Database name
    def drop_database(db_name)
      case @kind
      when :moped
        self.conn.drop
      when :mongo
        self.conn.drop_database(db_name)
      end
    end
  end # class Connection

  class << self

    # Instanciate source
    #
    # @param settings [Hash] Mongodb settings
    # @return [Fwissr::Source::Mongodb] Instance
    def from_settings(settings)
      if settings['mongodb'].nil? || (settings['mongodb'] == '') || settings['collection'].nil? || (settings['collection'] == '')
        raise "Erroneous mongodb settings: #{settings.inspect}"
      end

      conn = self.connection_for_uri(settings['mongodb'])

      options = settings.dup
      options.delete('mongodb')
      options.delete('collection')

      self.new(conn, settings['collection'], options)
    end

    # Get a memoized connection
    #
    # @api private
    #
    # @param uri [String] Connection URI
    # @return [Fwissr::Source::Mongodb::Connection] Connection handler
    def connection_for_uri(uri)
      @connections ||= { }
      @connections[uri] ||= Fwissr::Source::Mongodb::Connection.new(uri)
    end

  end # class << self

  # [Array] Collection names corresponding to 'top level' configurations
  TOP_LEVEL_COLLECTIONS = [ 'fwissr' ].freeze

  attr_reader :conn, :collection_name

  #
  # API
  #

  # Subclass {Fwissr::Source#initialize}
  def initialize(conn, collection_name, options = { })
    super(options)

    @conn            = conn
    @collection_name = collection_name
  end

  # Implements {Fwissr::Source#fetch_conf}
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

    # Build conf hash from collection's documents
    conf = { }
    self.conn.fetch(@collection_name).each do |doc|
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

end # class Fwissr::Source::Mongodb
