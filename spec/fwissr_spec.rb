require File.join(File.dirname(__FILE__), 'spec_helper')

describe Fwissr do

  before(:all) do
    Fwissr.main_conf_path = tmp_conf_dir
  end

  before(:each) do
    # delete all temporary conf files
    delete_tmp_conf_files

    # delete all temporary collections
    delete_tmp_mongo_db
  end

  it "manages a global registry" do
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
      'foo' => 'bar',
    }
    create_tmp_conf_file('fwissr.json', fwissr_conf)

    Fwissr['/foo'].should == 'bar'
    Fwissr['/bar'].should == 'baz'
    Fwissr['/cam'].should == { 'en' => { 'bert' => { 'pim' => { 'pam' => [ 'pom', 'pum' ] } } } }
    Fwissr['/cam/en'].should == { 'bert' => { 'pim' => { 'pam' => [ 'pom', 'pum' ] } } }
    Fwissr['/cam/en/bert'].should == { 'pim' => { 'pam' => [ 'pom', 'pum' ] } }
    Fwissr['/cam/en/bert/pim'].should == { 'pam' => [ 'pom', 'pum' ] }
    Fwissr['/cam/en/bert/pim/pam'].should == [ 'pom', 'pum' ]
    Fwissr['/gein'].should == 'gembre'
    Fwissr['/mouarf'].should == { 'lol' => { 'meu' => 'ringue', 'pa' => { 'pri' => 'ka'} } }
    Fwissr['/mouarf/lol'].should == { 'meu' => 'ringue', 'pa' => { 'pri' => 'ka'} }
    Fwissr['/mouarf/lol/meu'].should == 'ringue'
    Fwissr['/mouarf/lol/pa'].should == { 'pri' => 'ka'}
    Fwissr['/mouarf/lol/pa/pri'].should == 'ka'
    Fwissr['/pa'].should == { 'ta' => 'teu'}
    Fwissr['/pa/ta'].should == 'teu'
  end

end
