module QB
  # represents the data in a role's meta/qb.yml
  class Meta < Entity
    field :var_prefix, type: Types.maybe(String)
    
    field :default_dir, type: Types.one_of(
      nil,
      false,
      'git_root',
      'cwd',
      Types.hash(exactly: {exe: String})
    )
    
    field :save_options, type: Types.maybe(Types.bool), default: true
    
    field :vars, type: Types.array(values: Var)
  end # Meta
end # QB