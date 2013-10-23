require File.join(File.dirname(__FILE__), 'spec_helper')

describe Fwissr::Registry do

  before(:each) do
    # delete all temporary conf files
    delete_tmp_conf_files

    # delete all temporary collections
    delete_tmp_mongo_db
  end

  after(:each) do
    Delorean.back_to_the_present
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
    }
    create_tmp_conf_file('test2.json', test_conf)

    # test
    registry = Fwissr::Registry.new()
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json'), 'top_level' => true))
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test2.json'), 'top_level' => true))

    registry['/foo'].should == 'baz'
    registry['/cam'].should == { 'en' => 'bert', 'et' => 'rat' }
    registry['/cam/en'].should == 'bert'
    registry['/cam/et'].should == 'rat'
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

  it "does not refresh from sources before 'refresh_period' option" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    registry = Fwissr::Registry.new('refresh_period' => 5)
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json'), 'refresh' => true))
    registry.dump.should == { 'test' => test_conf }

    # modify conf file
    delete_tmp_conf_files

    test_conf_modified = {
      'pouet' => 'meuh',
    }
    create_tmp_conf_file('test.json', test_conf_modified)

    Delorean.jump(3)

    # not refreshed yet
    registry.dump.should == { 'test' => test_conf }

    registry.refresh_thread.should be_nil
    registry.is_refreshing?.should be_false
  end

  it "refreshes from sources after 'refresh_period' option" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    registry = Fwissr::Registry.new('refresh_period' => 5)
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json'), 'refresh' => true))
    registry.dump.should == { 'test' => test_conf }

    # modify conf file
    delete_tmp_conf_files

    test_conf_modified = {
      'pouet' => 'meuh',
    }
    create_tmp_conf_file('test.json', test_conf_modified)

    Delorean.jump(6)

    # triggering refresh
    registry.dump

    # wait for refresh to end
    registry.refresh_thread.should_not be_nil
    registry.refresh_thread.join
    registry.is_refreshing?.should be_false

    # refresh done
    registry.dump.should == { 'test' => test_conf_modified }
  end

  it "resets itself" do
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
    registry.reset!
    registry.dump.should == { 'test' => test_conf_modified }
  end

  it "resets itself when a new source is added" do
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

    # test that registry did not changed
    registry.dump.should == { 'test' => test_conf }

    # add new source
    test2_conf = {
      'foo' => 'bar',
      'jean' => [ 'bon', 'rage' ],
      'cam' => { 'en' => { 'bert' => 'coulant' } },
    }
    create_tmp_conf_file('test2.json', test2_conf)

    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test2.json')))

    # check
    registry.dump.should == { 'test' => test_conf_modified, 'test2' => test2_conf }
  end

end
