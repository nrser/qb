
shared_context :temp_gem do
  def temp_gem_name
    'test_gem'
  end
  
  def temp_gem_root
    TEMP_GEMS_DIR / temp_gem_name
  end
  
  def temp_gem_reset!
    FileUtils.rm_rf( temp_gem_root ) if temp_gem_root.exist?
    FileUtils.cp_r TEST_GEM_ROOT_PATH, temp_gem_root
  end
  
end # shared_context :temp_test_gem


shared_examples :temp_gem_should_be_setup do
  
  describe "temp gem" do
    
  end # "temp gem"
  
end # shared_examples :temp_gem_should_be_setup


