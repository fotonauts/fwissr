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

#
# Global Registry
# ===============
#
# Fwissr loads all conf files in main directories: +/etc/fwissr/+ and +~/.fwissr/+
#
# Two conf files are treated differently: +/etc/fwissr/fwissr.json+ and +~/.fwissr/fwissr.json+
#
# These two main conf files are 'top_level' ones and so their settings are added to global registry root. They can
# too contain a +fwissr_sources+ setting that is then used to setup additional sources.
#
# Global registry is accessed with Fwissr#[] method
#
# @example +/etc/fwissr/fwissr.json+ file:
#
#  {
#    'fwissr_sources': [
#      { 'filepath': '/mnt/my_app/conf/' },
#      { 'filepath': '/etc/my_app.json' },
#      { 'mongodb': 'mongodb://db1.example.net/my_app', 'collection': 'config', 'refresh': true },
#    ],
#    'fwissr_refresh_period': 30
# }
#
module Fwissr

  # default path where main conf file is located
  DEFAULT_MAIN_CONF_PATH = "/etc/fwissr"

  # default directory (relative to current user's home) where user's main conf file is located
  DEFAULT_MAIN_USER_CONF_DIR = ".fwissr"

  # main conf file
  MAIN_CONF_FILE = "fwissr.json"

  class << self
    attr_writer :main_conf_path, :main_user_conf_path

    # Main config files directory
    # @api private
    def main_conf_path
      @main_conf_path ||= DEFAULT_MAIN_CONF_PATH
    end

    # User's specific config files directory
    # @api private
    def main_user_conf_path
      @main_user_conf_path ||= File.join(Fwissr.find_home, DEFAULT_MAIN_USER_CONF_DIR)
    end

    # Finds the user's home directory
    #
    # @note Borrowed from rubygems
    # @api private
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
    # @api private
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

    # Load global registry
    # @api private
    def global_registry
      @global_registry ||= begin
        result = Fwissr::Registry.new('refresh_period' => self.main_conf['fwissr_refresh_period'])

        # check main conf files
        if File.exists?(self.main_conf_path) || File.exists?(self.main_user_conf_path)
          # setup main conf files sources
          if File.exists?(self.main_conf_path)
            result.add_source(Fwissr::Source.from_settings({ 'filepath' => self.main_conf_path }))
          end

          if File.exists?(self.main_user_conf_path)
            result.add_source(Fwissr::Source.from_settings({ 'filepath' => self.main_user_conf_path }))
          end

          # setup additional sources
          if !self.main_conf['fwissr_sources'].nil?
            self.main_conf['fwissr_sources'].each do |source_setting|
              result.add_source(Fwissr::Source.from_settings(source_setting))
            end
          end
        end

        result
      end
    end

    # Main config
    # @api private
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

    # Main config file
    # @api private
    def main_conf_file
      @main_conf_file ||= File.join(self.main_conf_path, MAIN_CONF_FILE)
    end

    # Main user's config file
    # @api private
    def main_user_conf_file
      @main_user_conf_file ||= File.join(self.main_user_conf_path, MAIN_CONF_FILE)
    end

    # Global registry accessor
    #
    # @param key [String] setting key
    # @return [Object] setting value
    def [](key)
      self.global_registry[key]
    end

    alias :get :[]

    # Dumps global registry keys
    #
    # @return [Array] Keys list
    def keys
      self.global_registry.keys
    end

    # @return [Hash] The entire registry
    def dump
      self.global_registry.dump
    end


    #
    # Utils
    #

    # Parse a configuration file
    #
    # @param conf_file_path [String] Configuration file path
    # @return [Hash] Parse configuration
    # @api private
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

    # @note Borrowed from rails
    # @api private
    def merge_conf(to_hash, other_hash)
      self.merge_conf!(to_hash.dup, other_hash)
    end

    # @note Borrowed from rails
    # @api private
    def merge_conf!(to_hash, other_hash)
      other_hash.each_pair do |k,v|
        tv = to_hash[k]
        to_hash[k] = (tv.is_a?(Hash) && v.is_a?(Hash)) ? self.merge_conf(tv, v) : v
      end
      to_hash
    end

    # Simple deep freezer
    # @api private
    def deep_freeze(obj)
      if obj.is_a?(Hash)
        obj.each do |k, v|
          self.deep_freeze(v)
        end
      elsif obj.is_a?(Array)
        obj.each do |v|
          self.deep_freeze(v)
        end
      end

      obj.freeze
    end
  end # class << self

end # module Fwissr
