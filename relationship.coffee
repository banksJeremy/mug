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
      
    @value

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
        refP.set value
  
  refs[0]

# f = ma
force = new Ref, mass = new Ref, acceleration = new Ref
equality(force, product(mass, acceleration))

force.set 6
mass.set 2
log "Acceleration = #{acceleration.value}"

# p(happy)p(dog|happy) = p(dog)p(happy|dog)
pH = new Ref, pDgH = new Ref, pD = new Ref, pHgD = new Ref
equality(product(pH, pDgH), product(pD, pHgD))

pH.set .6
pD.set .9
pHgD.set .5
log "P(dog|happy)=#{pDgH.value}"

# now add notHappy and notDog
pnH = new Ref, pnD = new Ref
sum(pH, pnH).set(1).sum(pD, pnD)



