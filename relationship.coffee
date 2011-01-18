#!/usr/bin/env coffee@1.0.0
{
  iter: iter
  seq: seq
  biter: biter
  mapper: mapper
  copy: copy
  any: any
  all: all
  Promise: Promise
} = mug = window?.mug? || require?("./mug")

mug.relationships = relationships = exports ? {}

# GIGO, there's no checking for logical validity of input

snapInt = (f) ->
  # Snap a float to the nearest integer if it's within 1e-12.
  
  if Math.abs(f % 1) < 1e-12
    f - f % 1
  else
    f

class Ref extends Promise
  # A Ref is a reference that can be set only once.
  # It provides a Promise on the value once set as .
  # If you attempt to .set(value) when it has already been set,
  # nothing will happen and the existing value will be returned.
  
  maybeSet: (value) ->
    if value? and @state is "unfulfilled"
      if value instanceof Function
        value = value()
      
      @fulfill @value = value
      
    @value

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
        
        unknownOne.maybeSet remainingValue
      else if outstandingVars is 0 and not result.value?
        runningValue = operation.identity
        
        for ref in refs
          runningValue = operation.perform runningValue, ref.value
        
        result.maybeSet runningValue
      
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
  result = new Ref
  
  base.then -> power.then ->
    result.maybeSet Math.pow base.value, power.value
  
  result.then -> base.then ->
    power.maybeSet snapInt(Math.log(result.value) / Math.log(base.value))
  
  result.then -> power.then ->
    base.maybeSet snapInt(Math.pow result.value, 1 / power.value)
  
  result

equality = (refs...) ->
  # Establishes equality between Refs.
  
  for ref in refs
    ref.then (value) ->
      for refP in refs
        refP.maybeSet value
  
  refs[0]

complement = (ref) ->
  # Refers to the 1-complement of a Ref object (cached)
  
  if not ref._complement?
    ref._complement = new Ref
    ref._complement._complement = ref
    
    sum(ref, ref._complement).maybeSet 1
    
  ref._complement

reciprocal = (ref) ->
  # Returns the reciprocal of a Ref object (cached)
  
  if not ref._reciprocal?
    ref._reciprocal = new Ref
    ref._reciprocal._reciprocal = ref
    
    product(ref, ref._reciprocal).maybeSet 1
  
  ref._reciprocal

neg = -> (ref) ->
  if not ref._neg?
    ref._neg = new Ref
    ref._neg._neg = ref
    
    sum(ref, ref._neg).maybeSet 0
  
  ref._neg


###
todo:
more acceptable argument parsing.
if you get a Number then wrap it.
maybe don't make refs wrap promises, but make them promises.
###

# f = ma
force = new Ref; mass = new Ref; acceleration = new Ref
equality(force, product(mass, acceleration))

force.maybeSet 6
mass.maybeSet 2
console.log "acceleration = #{acceleration.value}"

# e = .5mv^2
energy = new Ref; velocity = new Ref
equality(energy, product(new Ref(.5), mass, pow(velocity, new Ref(2))))

energy.maybeSet 16
console.log "velocity = #{velocity.value}"

