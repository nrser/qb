
describe_class QB::Role do
  
  describe_method :default_role_name do
    
    include_context "reset role path"
    
    describe_group "path in a role search dir gets relative name" do
      it_behaves_like :a_function,
        mapping: {
          [ ( TEST_ROLES_DIR / 'blah' / 'la' / 'la' ).to_s ] => 'blah/la/la',
          [ ( TEST_ROLES_DIR / 'not_nested' ).to_s ] => 'not_nested',
        }
    end # Group "path in a role search dir" Description
    
    
    describe_group "outside a role search dir uses basename" do
      it_behaves_like :a_function,
        mapping: {
          [ '/tmp/blah/la/la' ] => 'la',
          [ ( QB::ROOT / 'tmp' / 'blah' / 'la' / 'la' ).to_s ] => 'la',
        }
    end # Group "path in a role search dir" Description
    
  end # Method default_role_name Description
  
end # Class QB::Role Description
