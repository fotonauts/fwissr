require 'rubygems'

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require 'fwissr'


def setup_global_conf
  # create additional file sources
  create_tmp_conf_file('mouarf.lol.json', {
    'meu' => 'ringue',
    'pa' => { 'pri' => 'ka'},
  })

  create_tmp_conf_file('trop.mdr.json', {
    'gein' => 'gembre',
    'pa' => { 'ta' => 'teu'},
  })

  # create additional mongodb sources
  create_tmp_mongo_col('roque.fort', {
    'bar' => 'baz',
  })

  create_tmp_mongo_col('cam.en.bert', {
    'pim' => { 'pam' => [ 'pom', 'pum' ] },
  })

  # create main conf file
  fwissr_conf = {
    'fwissr_sources' => [
      { 'filepath' => tmp_conf_file('mouarf.lol.json') },
      { 'filepath' => tmp_conf_file('trop.mdr.json'), 'top_level' => true },
      { 'mongodb'  => tmp_mongo_db_uri, 'collection' => 'roque.fort', 'top_level' => true },
      { 'mongodb'  => tmp_mongo_db_uri, 'collection' => 'cam.en.bert' },
    ],
    'fwissr_refresh_period' => 5,
    'foo' => 'bar',
  }
  create_tmp_conf_file('fwissr.json', fwissr_conf)
end


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
  conn = Fwissr::Source::Mongodb.connection_for_uri(tmp_mongo_db_uri)
  conn.create_collection(name)
  conf.each do |key, val|
    conn.insert(name, {'_id' => key, 'value' => val})
  end
end

# delete temporary mongodb database
def delete_tmp_mongo_db
  conn = Fwissr::Source::Mongodb.connection_for_uri(tmp_mongo_db_uri)
  conn.drop_database(tmp_mongo_db)
end
