require 'yaml'

puts YAML.dump {
  'save_options' => false,
  'vars' => [
    {
      'name' => 'name',
      'description' => "name of gitignore",
      'require' => true,
      'type' => {
        'one_of' => 
      }
    }
  ]
}

