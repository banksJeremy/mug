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
} = mug = window?.mug? || require?("./mug")

console.log "D", iter(mug.deque([1])).toArray()

parseArgs = (args, default_n) ->
  args = biter args
  
  if args.first() instanceof Number or args.first() instanceof String
    n = args.next()
  else
    n = default_n
  
  if args.first() instanceof Object and args.first() not instanceof Array
    object = args.next()
  else
    object = {}
  
  factor = 1
  sign = 1
  
  console.log "--", args.constructor
  
  args.each ->
    signed_factor = sign * factor
    object[signed_factor] = (object[signed_factor] ? []).concat this
    
    if sign is 1
      sign = -1
    else
      factor += 1
      sign = +1
  
  vars = []
  for coefficient, values of object
    for value in values
      vars.push [ coefficient, value ]
  
  return [n, vars]

snapInt = (f) ->
  # rounds to the nearest integer if the difference is less than 1e-9
  
  if Math.abs(f % 1) < 1e-9
    f - (f % 1)
  else
    f

relateOperations = (main, magnitude) ->
  class Constant
    constructor: ->
      [@constant, @coVars] = parseArgs arguments, main.identity
      console.log @coVars
  
    relate: ->
      return if not @coVars.length
    
      changed = false
    
      if @coVars.length is 1
        [coefficient, variable] = @coVars.pop()
        variable magnitude.opposite @constant, coefficient
      
        changed = true
      else
        newVars = for coVar in @coVars
          [coefficient, variable] = coVar
          if variable()?
            @constant = main.perform @constant, magnitude.perform variable(), coefficient
        
            changed = true
        
            null
          else
            variable
      
        if changed
          @coVars = newVars.filter (v) -> v?
      
        changed
    
      if changed
        @relate() # continue relating until no more changes
      
        true
      else
        false

addition = 
  perform: (a, b) -> a + b
  opposite: (c, a) -> c - a
  identity: 0

multiplication =
  perform: (a, b) -> a * b
  opposite: (c, a) -> c / a
  identity: 1

exponentiation =
  perform: (a, b) -> Math.pow a, b
  opposite: (c, a) -> Math.log a, c
  identity: 0

ConstantSum = relateOperations addition, multiplication
ConstantProduct = relateOperations multiplication, exponentiation
console.log "Defined terms"

relate = (relationships) ->
  keepGoing = true
  anyProgress = false
  
  while keepGoing
    keepGoing = false
  
    for relationship in relationships
      if relationship.relate()
        keepGoing = true
        anyProgress = true
  
  anyProgress

console.log "making refs"

pHappy = ref()
pHappygDog = ref .75
pDog = ref .40
pDoggHappy = ref .50

console.log "made refs"

console.log pHappy(), pHappygDog()

console.log "that's pHappy, pHappygDog"

(new ConstantProduct [pHappy, pHappygDog], [pDog, pDoggHappy]).relate()

console.log pHappy()
console.log "that's pHappy again"
