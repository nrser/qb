{
  // present
  $present: 'key',
  
  // set
  $set: {key: value},
  // aliases
  $is: ...,
  
  // unset
  $unset: 'key',
  // aliases
  $absent: ...,
  $missing: ...,
  
  // contains (array)
  // 
  $contains: [v1, v2, v3],
  $contains: [{$value: v1, $before: v2, $after: v3}],
  
  $contains:
  $contain: ..., 
  $includes: ...,
  $include: ...,
  
  // missing (array)
  a: {$missing: [v1, v2, v3]},
  // => 
  a: {
    $type: 'array',
    $missing: [v1, v2, v3],
  }
  
  $type: 'array',
  
  // contains (hash)
  topKey: {$set: {nestedKey: value},
  
  $init: value,
}

// init key k to value v
{
  k: {$init: v},
  // => 
  $type: 'dict',
  k: {
    $defaultValue: v,
  }
}