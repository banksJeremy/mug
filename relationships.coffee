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
  is: (value) ->
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

Ref.many = (n = 12) -> new this for _ in [0...n]

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
        
        unknownOne.is remainingValue
      else if outstandingVars is 0 and not result.value?
        runningValue = operation.identity
        
        for ref in refs
          runningValue = operation.perform runningValue, ref.value
        
        result.is runningValue
      
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
    result.is Math.pow base.value, power.value
  
  result.then -> base.then ->
    power.is snapInt(Math.log(result.value) / Math.log(base.value))
  
  result.then -> power.then ->
    base.is snapInt(Math.pow result.value, 1 / power.value)
  
  result

equality = (refs...) ->
  # Establishes equality between Refs.
  refs = refs.map(Ref.of)
  
  for ref in refs
    ref.then (value) ->
      for refP in refs
        refP.is value
  
  refs[0]

complement = (ref) ->
  # Refers to the 1-complement of a Ref object (cached)
  ref = Ref.of ref
  
  if not ref._complement?
    ref._complement = new Ref
    ref._complement._complement = ref
    
    sum(ref, ref._complement).is 1
    
  ref._complement

reciprocal = (ref) ->
  # Returns the reciprocal of a Ref object (cached)
  ref = Ref.of ref
  
  if not ref._reciprocal?
    ref._reciprocal = new Ref
    ref._reciprocal._reciprocal = ref
    
    product(ref, ref._reciprocal).is 1
  
  ref._reciprocal

neg = -> (ref) ->
  ref = Ref.of ref
  
  if not ref._neg?
    ref._neg = new Ref
    ref._neg._neg = ref
    
    sum(ref, ref._neg).is 0
  
  ref._neg

###===========================================================================
I haven't put a ton of thought into how I'm going to organize this module yet.
===========================================================================###

class PhysicalObject
  # A collection of Refs with simple physical relationships established.
  
  constructor: (knowns) ->
    [@force, @mass, @acceleration, @kineticEnergy,
     @speed, @density, @volume] =
    Ref.many()
    
    # set initially known values
    if knowns? then for name, value of knowns
      this[name].is value
    
    # force = mass * accelertion
    (equality @force,
              (product @mass, @acceleration))
    
    # kineticEnergy = .5 * mass * speed^2
    (equality @kineticEnergy,
              (product .5,
                       @mass,
                       (pow @speed, 2)))
    
    # density = mass/volume
    (equality @density,
              product @mass, reciprocal(@volume))

o = new PhysicalObject
  density: 0.1
  volume: 0.5
  force: 2

p = new PhysicalObject
  speed: 10

(equality o.mass, p.mass)

console.log "m_o =", o.mass.value
console.log "A_o =", o.acceleration.value
console.log "e_kp =", p.kineticEnergy.value

class BayesianEvent extends Ref
  # A Ref that allows you to reference its conditional probability with
  # respect to another BayesianEvent.
  
  constructor: (args...) ->
    super args...
    @_given = {}
    
    this
  
  given: (that) ->
    if that.id not of @_given
      thisGivenThat = this._given[that.id] = new Ref
      thisGivenNotThat = this._given[complement(that).id] = new Ref
      
      thatGivenThis = that._given[this.id] = new Ref
      thatGivenNotThis = that._given[complement(this).id] = new Ref
      
      # P(this | that) * P(that) = P(that | this) * P(this)
      (equality (product thisGivenThat, that),
                (product thatGivenThis, this))
      
      # P(that) = P(this | that) * P(that) + P(this | ~that) * P(~that)
      # (and vice versa)
      (equality that,
                (sum (product thisGivenThat, that),
                     (product thisGivenNotThat, complement(that))))
      (equality this,
                (sum (product thatGivenThis, this),
                     (product thatGivenNotThis, complement(this))))
    
    @_given[that.id]

gotADog = new BayesianEvent
areHappy = new BayesianEvent

areHappy.given(gotADog).is 0.8
areHappy.given(complement gotADog).is 0.5
areHappy.is 0.7
gotADog.given(areHappy).is 0.6

console.log "P(got a dog) = #{gotADog.value}"
console.log "P(have a dog | unhappy) = #{(gotADog.given(complement areHappy)).value}"
console.log "P(have a dog | happy) = #{(gotADog.given(areHappy)).value}"