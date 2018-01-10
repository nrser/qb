
describe_qb_role 'qb/role/qb' do
  include_context :clear_temp_roles
  
  it "gets the name right in nested roles" do
    name = 'nested/tester'
    dest = TEMP_ROLES_DIR / name
    
    Cmds.new(
      './bin/qb qb/role/qb <%= dest %>',
      chdir: QB::ROOT,
      kwds: { dest: dest }
    ).stream!
    
    meta_path = dest / 'meta' / 'qb.yml'
    
    expect( meta_path.file? ).to be true
    
    expect( meta_path.read.lines[2] ).
      to match /\`#{ Regexp.escape name }\` role/
    
  end
  
end
