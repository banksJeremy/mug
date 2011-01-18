#!/usr/bin/env coffee@1.0.0
{
  copy: copy
  Promise: Promise
} = mug = window?.mug? || require?("./mug")

mug.relationships = relationships = exports ? {}
relationships.meta = copy mug.meta
relationships.meta.name = "Mug.Relationships"
relationships.meta.oneLineDescription =
  "Operations with relationships between numbers. GIGO."

snapInt = (f) ->
  # Snap a float to the nearest integer if it's within 1e-12.
  
  if Math.abs(f % 1) < 1e-12
    f - f % 1
  else
    f

class Ref extends Promise
  offerValue: (value) ->
    if value? and @state is "unfulfilled"
      if value instanceof Function
        value = value()
      
      @fulfill @value = value
      
    @value

Ref.of = (value) ->
  if value instanceof Ref
    value
  else
    new Ref value

# commutitive operations that we can feed into commutitiveOperation
addition =
  perform: (a, b) -> c = a + b
  undo: (c, b) -> a = c - b
  identity: 0

multiplication =
  perform: (a, b) -> c = a * b
  undo: (c, b) -> a = c / b
  identity: 1

commutitiveOperation = (operation) ->
  (refs...) ->
    # Provides a Ref to the value of a commutitive operation applied over
    # the arguments in refs.
    refs = refs.map(Ref.of)
    
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
        
        unknownOne.offerValue remainingValue
      else if outstandingVars is 0 and not result.value?
        runningValue = operation.identity
        
        for ref in refs
          runningValue = operation.perform runningValue, ref.value
        
        result.offerValue runningValue
      
      null
    
    result.then update
    
    for ref in refs
      ref.then (value) ->
        outstandingVars -= 1
        update()
    
    result

sum = commutitiveOperation addition
product = commutitiveOperation multiplication

pow = (base, power) ->
  base = Ref.of base
  power = Ref.of power
  
  result = new Ref
  
  base.then -> power.then ->
    result.offerValue Math.pow base.value, power.value
  
  result.then -> base.then ->
    power.offerValue snapInt(Math.log(result.value) / Math.log(base.value))
  
  result.then -> power.then ->
    base.offerValue snapInt(Math.pow result.value, 1 / power.value)
  
  result

equality = (refs...) ->
  # Establishes equality between Refs.
  refs = refs.map(Ref.of)
  
  for ref in refs
    ref.then (value) ->
      for refP in refs
        refP.offerValue value
  
  refs[0]

complement = (ref) ->
  # Refers to the 1-complement of a Ref object (cached)
  ref = Ref.of ref
  
  if not ref._complement?
    ref._complement = new Ref
    ref._complement._complement = ref
    
    sum(ref, ref._complement).offerValue 1
    
  ref._complement

reciprocal = (ref) ->
  # Returns the reciprocal of a Ref object (cached)
  ref = Ref.of ref
  
  if not ref._reciprocal?
    ref._reciprocal = new Ref
    ref._reciprocal._reciprocal = ref
    
    product(ref, ref._reciprocal).offerValue 1
  
  ref._reciprocal

neg = -> (ref) ->
  ref = Ref.of ref
  
  if not ref._neg?
    ref._neg = new Ref
    ref._neg._neg = ref
    
    sum(ref, ref._neg).offerValue 0
  
  ref._neg

# f = ma
force = new Ref; mass = new Ref; acceleration = new Ref
equality(force, product(mass, acceleration))

force.offerValue 6
mass.offerValue 2
console.log "acceleration = #{acceleration.value}"

# e = .5mv^2
energy = new Ref; velocity = new Ref
(equality energy, (product .5, mass, (pow velocity, 2)))

energy.offerValue 16
console.log "velocity = #{velocity.value}"

