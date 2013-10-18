require File.join(File.dirname(__FILE__), 'spec_helper')

describe Fwissr::Registry do

  it "instanciates with a source" do
    # create conf file
    test_conf = {
      'foo' => 'bar',
      'cam' => { 'en' => 'bert'},
    }
    create_tmp_conf_file('test.json', test_conf)

    # test
    registry = Fwissr::Registry.new()
    registry.add_source(Fwissr::Source::File.new(tmp_conf_file('test.json')))

    registry['/test/foo'].should == 'bar'
    registry['/test/cam/en'].should == 'bert'
    registry['/test/cam'].should == { 'en' => 'bert' }
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

end
