require File.join(File.dirname(__FILE__), 'spec_helper')

describe Fwissr::Registry do

  before(:each) do
    # delete all temporary conf files
    delete_tmp_conf_files

    # delete all temporary collections
    delete_tmp_mongo_db
  end

  it "instanciates with a source" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    # test
    registry = Fwissr::Registry.new('refresh_period' => 20)
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json')))

    registry.refresh_period.should == 20

    registry['/test/foo'].should == 'bar'
    registry['/test/cam/en'].should == 'bert'
    registry['/test/cam'].should == { 'en' => 'bert' }


    registry['/meuh'].should be_nil
    registry['/test/meuh'].should be_nil
    registry['/test/cam/meuh'].should be_nil
  end

  it "have a default refresh period" do
    registry = Fwissr::Registry.new
    registry.refresh_period.should == Fwissr::Registry::DEFAULT_REFRESH_PERIOD
  end

  it "instanciates with several sources" do
    # create conf files
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    test_conf = {
      'foo' => 'baz',
      'cam' => { 'et' => 'rat'},
      'jean' => 'bon',
    }
    create_tmp_conf_file('test2.json', test_conf)

    # test
    registry = Fwissr::Registry.new()
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json'), 'top_level' => true))

    # check
    registry['/foo'].should == 'bar'
    registry['/cam'].should == { 'en' => 'bert' }
    registry['/cam/en'].should == 'bert'

    # test
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test2.json'), 'top_level' => true))

    # check
    registry['/foo'].should == 'baz'
    registry['/cam'].should == { 'en' => 'bert', 'et' => 'rat' }
    registry['/cam/en'].should == 'bert'
    registry['/cam/et'].should == 'rat'
    registry['/jean'].should == 'bon'
  end

  it "lists keys" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'jean' => [ 'bon', 'rage' ],
      'cam' => { 'en' => { 'bert' => 'coulant' } },
    }
    create_tmp_conf_file('test.json', test_conf)

    registry = Fwissr::Registry.new()
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json')))

    # test
    registry.keys.should == [
      '/test',
      '/test/cam',
      '/test/cam/en',
      '/test/cam/en/bert',
      '/test/foo',
      '/test/jean',
    ]
  end

  it "dumps itself" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'jean' => [ 'bon', 'rage' ],
      'cam' => { 'en' => { 'bert' => 'coulant' } },
    }
    create_tmp_conf_file('test.json', test_conf)

    registry = Fwissr::Registry.new()
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json')))

    # test
    registry.dump.should == { 'test' => test_conf }
  end

  it "does NOT start a refresh thread if none of its sources is refreshable" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    registry = Fwissr::Registry.new('refresh_period' => 20)
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json')))

    # check
    registry.refresh_thread.should be_nil
  end

  it "starts a refresh thread if one of its sources is refreshable" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    registry = Fwissr::Registry.new('refresh_period' => 20)
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json'), 'refresh' => true))

    # check
    registry.refresh_thread.should_not be_nil
    registry.refresh_thread.alive?.should be_true
  end

  it "does not refresh from sources before 'refresh_period' option" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    registry = Fwissr::Registry.new('refresh_period' => 3)
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json'), 'refresh' => true))
    registry.dump.should == { 'test' => test_conf }

    # modify conf file
    delete_tmp_conf_files

    test_conf_modified = {
      'pouet' => 'meuh',
    }
    create_tmp_conf_file('test.json', test_conf_modified)

    sleep(1)

    # not refreshed yet
    registry.dump.should == { 'test' => test_conf }
  end

  it "refreshes from sources after 'refresh_period' option" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    registry = Fwissr::Registry.new('refresh_period' => 2)
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json'), 'refresh' => true))
    registry.dump.should == { 'test' => test_conf }

    # modify conf file
    delete_tmp_conf_files

    test_conf_modified = {
      'pouet' => 'meuh',
    }
    create_tmp_conf_file('test.json', test_conf_modified)

    sleep(3)

    # refresh done
    registry.dump.should == { 'test' => test_conf_modified }

    # modify conf file
    delete_tmp_conf_files

    test_conf_modified_2 = {
      'pouet' => 'tagada',
    }
    create_tmp_conf_file('test.json', test_conf_modified_2)

    sleep(3)

    # refresh done
    registry.dump.should == { 'test' => test_conf_modified_2 }
  end

  it "reloads" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'jean' => [ 'bon', 'rage' ],
      'cam' => { 'en' => { 'bert' => 'coulant' } },
    }
    create_tmp_conf_file('test.json', test_conf)

    registry = Fwissr::Registry.new()
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json')))
    registry.dump.should == { 'test' => test_conf }

    # modify conf file
    delete_tmp_conf_files

    test_conf_modified = {
      'pouet' => 'meuh',
    }
    create_tmp_conf_file('test.json', test_conf_modified)

    # test
    registry.dump.should == { 'test' => test_conf }
    registry.reload!
    registry.dump.should == { 'test' => test_conf_modified }
  end

end
