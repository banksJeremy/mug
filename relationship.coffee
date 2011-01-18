#!/usr/bin/env coffee@1.0.0
{
  iter: iter
  seq: seq
  biter: biter
  mapper: mapper
  copy: copy
  ref: ref
  any: any
  all: all
  isArray: isArray
  Promise
} = mug = window?.mug? || require?("./mug")
{
  log: log
  warn: warn
  error: error
} = console
inspect = require?("util")?.inspect ? (x) -> x

snapInt = (f) ->
  # if a float is nearer than 1e-12 to an integer, round it
  if Math.abs(f % 1) < 1e-12
    f - f % 1
  else
    f
class Ref
  constructor: (value) ->
    @onceSet = new Promise
    @set value
    
    null
  
  set: (value) ->
    # returns false if value already set
    if value? and @onceSet.state is "unfulfilled"
      if value instanceof Function
        value = value()
      
      @onceSet.fulfill @value = value
      
      true
    else
      false

reciprocal = (ref) ->
  result = new Ref
  ref.onceSet.then (value) -> result.set 1 / value
  result.onceSet.then (value) -> ref.set 1 / value
  
  result

addition =
  perform: (a, b) -> c = a + b
  undo: (c, b) -> a = c - b
  identity: 0

multiplication =
  perform: (a, b) -> c = a * b
  undo: (c, b) -> a = c / b
  identity: 1

exponentiation =
  perform: (a, b) -> c = Math.pow a, b
  undo: (c, b) -> a = snapInt Math.pow c, (1 / b)
  identity: 1

commutitiveOperation = (operation) ->
  (refs...) ->
    result = new Ref
    outstandingVars = refs.length
    
    update = ->
      if outstandingVars is 1 and result.value?
        remainingValue = result.value
        
        for ref in refs
          if ref.value?
            remainingValue = operation.undo remainingValue, ref.value
          else
            unknownOne = ref
        
        unknownOne.set remainingValue
      else if outstandingVars is 0 and not result.value?
        runningValue = operation.identity
        
        for ref in refs
          runningValue = operation.perform runningValue, ref.value
        
        result.set runningValue
      
      null
    
    result.onceSet.then update
    
    for ref in refs
      ref.onceSet.then (value) ->
        outstandingVars -= 1
        update()
    
    result

sum = commutitiveOperation addition
product = commutitiveOperation multiplication

equality = (refs...) ->
  for ref in refs
    ref.onceSet.then (value) ->
      for refP in refs
        ref.set value
  
  refs[0]

[force, mass, acceleration] = [new Ref, new Ref, new Ref]

force.onceSet.then (x) -> log "FORCE IS SET", x
mass.onceSet.then (x) -> log "MASS IS SET", x
acceleration.onceSet.then (x) -> log "ACCEL IS SET", x

equality(force, product(mass, acceleration)) # f = ma

log "Setting force=6, mass=2."
force.set 6
mass.set 2
log "Checking force=#{force.value}, mass=#{mass.value}."
log "Now acceleration=#{acceleration.value}."


