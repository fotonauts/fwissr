require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Fwissr::Source::Mongodb do

  before(:each) do
    # delete all temporary collections
    delete_tmp_mongo_db
  end

  it "instanciates from a URI" do
    # create collection
    create_tmp_mongo_col('test', { })

    # test
    source = Fwissr::Source.from_settings({ 'mongodb' => tmp_mongo_db_uri, 'collection' => 'test' })

    # check
    source.class.should == Fwissr::Source::Mongodb
    source.db_name.should == tmp_mongo_db
    source.collection_name.should == 'test'
  end

  it "fetches conf" do
    # create collection
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_mongo_col('test', test_conf)

    # test
    source = Fwissr::Source.from_settings({ 'mongodb' => tmp_mongo_db_uri, 'collection' => 'test' })
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == { 'test' => test_conf }
  end

  it "maps collection name to key parts" do
    # create collection
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_mongo_col('cam.en.bert', test_conf)

    # test
    source = Fwissr::Source.from_settings({ 'mongodb' => tmp_mongo_db_uri, 'collection' => 'cam.en.bert' })
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == { 'cam' => { 'en' => { 'bert' => test_conf } } }
  end

  it "does not map collection name to key parts for top level collections" do
    top_level_conf_col_name = Fwissr::Source::Mongodb::TOP_LEVEL_COLLECTIONS.first

    # create collection
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert' },
    }
    create_tmp_mongo_col(top_level_conf_col_name, test_conf)

    # test
    source = Fwissr::Source.from_settings({ 'mongodb' => tmp_mongo_db_uri, 'collection' => top_level_conf_col_name})
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == test_conf
  end

  it "does not map file name to key parts for custom top level collections" do
    # create collection
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert' },
    }
    create_tmp_mongo_col('cam.en.bert', test_conf)

    # test
    source = Fwissr::Source.from_settings({ 'mongodb' => tmp_mongo_db_uri, 'collection' => 'cam.en.bert', 'top_level' => true })
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == test_conf
  end

  it "does refresh conf if allowed to" do
    # create collection
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_mongo_col('test', test_conf)

    source = Fwissr::Source.from_settings({ 'mongodb' => tmp_mongo_db_uri, 'collection' => 'test', 'refresh' => true })
    conf_fetched = source.get_conf
    conf_fetched.should == { 'test' => test_conf }

    # update conf
    delete_tmp_mongo_db

    test_conf_modified = {
      'foo' => 'meuh',
    }
    create_tmp_mongo_col('test', test_conf_modified)

    # test
    conf_fetched = source.get_conf
    conf_fetched.should == { 'test' => test_conf_modified }
  end

  it "does NOT refresh conf if not allowed" do
    # create collection
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_mongo_col('test', test_conf)

    source = Fwissr::Source.from_settings({ 'mongodb' => tmp_mongo_db_uri, 'collection' => 'test' })
    conf_fetched = source.get_conf
    conf_fetched.should == { 'test' => test_conf }

    # update conf
    delete_tmp_mongo_db

    test_conf_modified = {
      'foo' => 'meuh',
    }
    create_tmp_mongo_col('test', test_conf_modified)

    # test
    conf_fetched = source.get_conf
    conf_fetched.should == { 'test' => test_conf }
  end

  it "resets itself" do
    # create collection
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_mongo_col('test', test_conf)

    source = Fwissr::Source.from_settings({ 'mongodb' => tmp_mongo_db_uri, 'collection' => 'test' })
    conf_fetched = source.get_conf
    conf_fetched.should == { 'test' => test_conf }

    # update conf
    delete_tmp_mongo_db

    test_conf_modified = {
      'foo' => 'meuh',
    }
    create_tmp_mongo_col('test', test_conf_modified)

    # test
    source.get_conf.should == { 'test' => test_conf }
    source.reset!
    source.get_conf.should == { 'test' => test_conf_modified }
  end

end
