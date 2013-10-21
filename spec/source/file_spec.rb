require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Fwissr::Source::File do

  before(:each) do
    # delete all temporary conf files
    delete_tmp_conf_files
  end

  it "instanciates from a URI" do
    # create conf file
    create_tmp_conf_file('test.json', { })

    # test
    source = Fwissr::Source::File.from_path(tmp_conf_file('test.json'))

    # check
    source.class.should == Fwissr::Source::File
    source.path.should == "#{tmp_conf_file('test.json')}"
  end

  it "raises an exception if file does not exists" do
    lambda { Fwissr::Source::File.from_path(tmp_conf_file('pouet.json')) }.should raise_error
  end

  it "fetches JSON conf" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    # test
    source = Fwissr::Source::File.from_path(tmp_conf_file('test.json'))
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == { 'test' => test_conf }
  end

  it "fetches YAML conf" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.yml', test_conf)

    # test
    source = Fwissr::Source::File.from_path(tmp_conf_file('test.yml'))
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == { 'test' => test_conf }
  end

  it "fetches all conf files from a directory" do
    # create conf files
    test1_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test1.json', test1_conf)

    test2_conf = {
      'jean' => 'bon',
      'terieur' => [ 'alain', 'alex' ],
    }
    create_tmp_conf_file('test2.yml', test2_conf)

    # test
    source = Fwissr::Source::File.from_path(tmp_conf_dir)
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == { 'test1' => test1_conf, 'test2' => test2_conf }
  end

  it "maps file name to key parts" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.with.parts.json', test_conf)

    # test
    source = Fwissr::Source::File.from_path(tmp_conf_file('test.with.parts.json'))
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == { 'test' => { 'with' => { 'parts' => test_conf } } }
  end

  it "does not map file name to key parts for default top level conf files" do
    top_level_conf_file_name = "#{Fwissr::Source::File::TOP_LEVEL_CONF_FILES.first}.json"

    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file(top_level_conf_file_name, test_conf)

    # test
    source = Fwissr::Source::File.from_path(tmp_conf_file(top_level_conf_file_name))
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == test_conf
  end

  it "does not map file name to key parts for custom top level conf files" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file("test.json", test_conf)

    # test
    source = Fwissr::Source::File.from_path(tmp_conf_file("test.json"), 'top_level' => true)
    conf_fetched = source.fetch_conf

    # check
    conf_fetched.should == test_conf
  end

  it "should refresh conf is allowed to" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file("test.json", test_conf)

    source = Fwissr::Source::File.from_path(tmp_conf_file("test.json"), 'refresh' => true)
    conf_fetched = source.get_conf
    conf_fetched.should == { 'test' => test_conf }

    # change file
    delete_tmp_conf_files

    test_conf_modified = {
      'foo' => 'pouet',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file("test.json", test_conf_modified)

    # test
    conf_fetched = source.get_conf
    conf_fetched.should == { 'test' => test_conf_modified }
  end

  it "should NOT refresh conf if not allowed" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file("test.json", test_conf)

    source = Fwissr::Source::File.from_path(tmp_conf_file("test.json"))
    conf_fetched = source.get_conf
    conf_fetched.should == { 'test' => test_conf }

    # change file
    delete_tmp_conf_files

    test_conf_modified = {
      'foo' => 'pouet',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file("test.json", test_conf_modified)

    # test
    conf_fetched = source.get_conf
    conf_fetched.should == { 'test' => test_conf }
  end

end
