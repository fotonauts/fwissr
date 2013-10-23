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
    # setup
    setup_global_conf

    # check
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

  it "does not care if leading slash is missing" do
    # setup
    setup_global_conf

    Fwissr['foo'].should == 'bar'
    Fwissr['cam'].should == { 'en' => { 'bert' => { 'pim' => { 'pam' => [ 'pom', 'pum' ] } } } }
    Fwissr['cam/en/bert/pim/pam'].should == [ 'pom', 'pum' ]
  end

  it "handles fwissr_refresh_period options" do
    Fwissr.global_registry.refresh_period.should == 5
  end

end
