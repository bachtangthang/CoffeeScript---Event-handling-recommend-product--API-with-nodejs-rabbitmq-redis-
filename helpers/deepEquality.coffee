
isObject = (object) ->
  object != null and typeof object == 'object'

exports.deepEqual = (object1, object2) ->
  keys1 = Object.keys(object1)
  keys2 = Object.keys(object2)
  if keys1.length != keys2.length
    return false
  for key of keys1
    val1 = object1[key]
    val2 = object2[key]
    areObjects = isObject(val1) and isObject(val2)
    if areObjects and !deepEqual(val1, val2) or !areObjects and val1 != val2
      return false
  true