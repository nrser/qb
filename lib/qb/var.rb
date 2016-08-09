module QB
  # represents an entry in the 'vars' list in a role's meta/qb.yl
  class Var < Entity    
    # has to be String, so can't be nil
    field :name, type: String
    
    # has to be 'boolean' of 'string', so can't be nil
    field :type, type: Types.one_of('boolean', 'string'), default: 'boolean'
    
    # wrapped in Types::Maybe, so nil is allowed
    field :description, type: Types.maybe(String)
    
    # has to be true or false, so can't be nil
    field :required, type: Types.bool, default: false
    
    # wrapped in Types::Maybe, so can be nil
    field :short, type: Types.maybe(Types.string(min: 1, max: 1))
  end
end
