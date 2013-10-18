require 'rubygems'
require 'mongo'

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require 'fwissr'


#
# File
#

# temporary fwissr conf dir path
def tmp_conf_dir
  "/tmp/fwissr.spec"
end

# get temporary conf file path
def tmp_conf_file(filename)
  "#{tmp_conf_dir}/#{filename}"
end

# create a temporary conf file
def create_tmp_conf_file(filename, conf)
  # full path
  conf_file_path = File.join(tmp_conf_dir, filename)

  # delete file if it already exists
  File.unlink(conf_file_path) if File.file?(conf_file_path)

  # create directory if it does not exists yet
  FileUtils.mkdir_p(tmp_conf_dir)

  # save conf file
  if File.extname(filename) == ".json"
    # json
    File.open(conf_file_path, 'w') { |file| file.write(Yajl::Encoder.encode(conf)) }
  elsif File.extname(filename) == ".yml"
    # yaml
    File.open(conf_file_path, 'w') { |file| YAML.dump(conf, file) }
  else
    raise "Unsupported conf file type: #{filename}"
  end
end

# delete all temporary conf files
def delete_tmp_conf_files
  raise "Hey, don't delete all legal conf files !" if File.expand_path(tmp_conf_dir) == File.expand_path(Fwissr::DEFAULT_MAIN_CONF_PATH)

  FileUtils.rm(Dir[tmp_conf_dir + "/*.{json,yml}"])
end

# change fwissr conf directories
def set_tmp_conf(conf_dir = tmp_conf_dir, user_conf_dir = "")
  Fwissr.conf_dir      = conf_dir
  Fwissr.user_conf_dir = user_conf_dir
end


#
# Mongodb
#

def tmp_mongo_hostname
  "localhost"
end

def tmp_mongo_port
  27017
end

# temporary mongodb database
def tmp_mongo_db
  "fwissr_spec"
end

# get temporary conf collection full URI
def tmp_mongo_db_uri
  "mongodb://#{tmp_mongo_hostname}:#{tmp_mongo_port}/#{tmp_mongo_db}"
end

# create a temporary conf collection
def create_tmp_mongo_col(name, conf)
  client = ::Mongo::MongoClient.from_uri(tmp_mongo_db_uri)
  col = client.db(tmp_mongo_db).create_collection(name)
  conf.each do |key, val|
    col.insert({'_id' => key, 'value' => val})
  end
end

# delete temporary mongodb database
def delete_tmp_mongo_db
  client = ::Mongo::MongoClient.from_uri(tmp_mongo_db_uri)
  client.drop_database(tmp_mongo_db)
end
