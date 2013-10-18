require 'rubygems'
require 'optparse'

require 'yaml'

FWISSR_USE_YAJL = true

if FWISSR_USE_YAJL
  require 'yajl'
else
  require 'json'
end


require 'fwissr/version'
require 'fwissr/source'
require 'fwissr/registry'

module Fwissr

  # default path where main conf file is located
  DEFAULT_MAIN_CONF_PATH = "/etc/fwissr"

  # default directory (relative to current user's home) where user's main conf file is located
  DEFAULT_MAIN_USER_CONF_DIR = ".fwissr"

  # main conf file
  MAIN_CONF_FILE = "fwissr.json"

  class << self
    attr_writer :main_conf_path, :main_user_conf_path

    # Get config files directory
    def main_conf_path
      @main_conf_path ||= DEFAULT_MAIN_CONF_PATH
    end

    # Get user's specific config files directory
    def main_user_conf_path
      @main_user_conf_path ||= File.join(Fwissr.find_home, DEFAULT_MAIN_USER_CONF_DIR)
    end

    # finds the user's home directory
    #
    # Borrowed from rubygems
    def find_home
      ['HOME', 'USERPROFILE'].each do |homekey|
        return ENV[homekey] if ENV[homekey]
      end

      if ENV['HOMEDRIVE'] && ENV['HOMEPATH'] then
        return "#{ENV['HOMEDRIVE']}:#{ENV['HOMEPATH']}"
      end

      begin
        File.expand_path("~")
      rescue
        if File::ALT_SEPARATOR then
            "C:/"
        else
            "/"
        end
      end
    end

    # Parse command line arguments
    def parse_args!(argv)
      args = {
        :inspect  => false,
        :json     => false,
        :dump     => false,
        :pretty   => false,
      }

      # define parser
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: fwissr [-ijph] <key>\nWith key:\n\t#{Fwissr.keys.sort.join("\n\t")}\n\n"

        opts.define_head "The configuration registry."

        opts.on("-i", "--inspect", "Returns 'inspected' result") do
          args[:inspect] = true
        end

        opts.on("-j", "--json", "Returns result in json") do
          args[:json] = true
        end

        opts.on("--dump", "Dump all keys and values") do
          args[:dump] = true
        end

        opts.on("-p", "--pretty", "Pretty output") do
          args[:pretty] = true
        end

        opts.on("-?", "-h", "--help", "Show this help message") do
          puts opts
          exit
        end

        opts.on_tail("--version", "Show version") do
          puts Fwissr::VERSION
          exit
        end

      end

      # parse what we have on the command line
      opt_parser.parse!(argv)

      # get key
      if argv.empty? && !args[:dump]
        puts "Please specify the key, e.g. 'fwissr /fqdn'"
        puts opt_parser
        exit
      end

      args[:key] = argv.first unless argv.empty?

      args
    end


    #
    # Global Registry
    #
    #
    # NOTE: Parses main conf files (/etc/fwissr/fwissr.json and ~/.fwissr/fwissr.json) then uses 'fwissr_sources' setting to setup additional sources
    #
    # Example of /etc/fwissr/fwissr.json file:
    #
    #  {
    #    'fwissr_sources': [
    #      { 'filepath': '/mnt/my_app/conf/' },
    #      { 'filepath': '/etc/my_app.json' },
    #      { 'mongodb': 'mongodb://db1.example.net/my_app', 'collection': 'config' },
    #    ]
    # }
    #

    # access global registry with Fwissr['/foo/bar']
    def global_registry
      @global_registry ||= begin
        result = Fwissr::Registry.new()

        # check main conf files
        if !File.exists?(self.main_conf_file) && !File.exists?(self.main_user_conf_file)
          raise "No fwissr conf file found: #{self.main_conf_file} | #{self.main_user_conf_file}"
        end

        # setup main conf files sources
        if File.exists?(self.main_conf_file)
          result.add_source(Fwissr::Source.from_settings({ 'filepath' => self.main_conf_file }))
        end

        if File.exists?(self.main_user_conf_file)
          result.add_source(Fwissr::Source.from_settings({ 'filepath' => self.main_user_conf_file }))
        end

        # setup additional sources
        if !self.main_conf['fwissr_sources'].nil?
          self.main_conf['fwissr_sources'].each do |source_setting|
            result.add_source(Fwissr::Source.from_settings(source_setting))
          end
        end

        result
      end
    end

    # fetch main fwissr conf
    def main_conf
      @main_conf ||= begin
        result = { }

        if File.exists?(self.main_conf_file)
          result = self.merge_conf!(result, self.parse_conf_file(self.main_conf_file))
        end

        if File.exists?(self.main_user_conf_file)
          result = self.merge_conf!(result, self.parse_conf_file(self.main_user_conf_file))
        end

        result
      end
    end

    def main_conf_file
      @main_conf_file ||= File.join(self.main_conf_path, MAIN_CONF_FILE)
    end

    def main_user_conf_file
      @main_user_conf_file ||= File.join(self.main_user_conf_path, MAIN_CONF_FILE)
    end

    # delegate to global registry
    [ :[], :get ].each do |meth_name|
      class_eval <<-EOS, __FILE__, __LINE__
        def #{meth_name}(key)
          self.global_registry[key]
        end
      EOS
    end

    [ :keys, :dump ].each do |meth_name|
      class_eval <<-EOS, __FILE__, __LINE__
        def #{meth_name}
          self.global_registry.__send__('#{meth_name}')
        end
      EOS
    end


    #
    # Utils
    #

    def parse_conf_file(conf_file_path)
      conf_file_ext = File.extname(conf_file_path)

      case conf_file_ext
      when ".json"
        # json file
        if FWISSR_USE_YAJL
          Yajl::Parser.parse(File.read(conf_file_path), :check_utf8 => false)
        else
          JSON.parse(File.read(conf_file_path))
        end
      when ".yaml", ".yml"
        # yaml file
        YAML.load_file(conf_file_path)
      else
        raise "Unsupported conf file kind: #{conf_file_path}"
      end
    end

    # borrowed from rails
    def merge_conf(to_hash, other_hash)
      self.merge_conf!(to_hash.dup, other_hash)
    end

    # borrowed from rails
    def merge_conf!(to_hash, other_hash)
      other_hash.each_pair do |k,v|
        tv = to_hash[k]
        to_hash[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? self.merge_conf(tv, v) : v
      end
      to_hash
    end

  end # class << self

end # module Fwissr
