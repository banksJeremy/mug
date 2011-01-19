#!/usr/bin/env coffee@1.0.0
mug = exports ? {}
if window? then window.mug = mug

# todo: why is map not lazy?! assert that it must return an iterable and
# stop just using array map, jesus
# also I don't think this works the same as jQuery's map.

mug.meta = meta =
  name: "Mug"
  version: [0, 0, 0]
  oneLineDescription: "A collection of things I like to have in CoffeeScript."
  address: "https://gist.github.com/9ba8fffbe53d1ed642ce"
  author: "Jeremy Banks <jeremy@jeremybanks.com>"
  license: "Copyright 2011 Jeremy Banks. Released under the MIT license."

mug.make = make = (constructor, arguments) ->
  # Creates a new instance of an object with a given constructor/type.
  # The constructor is called unless arguments is specified as null.
  # 
  # ECMA-265 5e: http://goo.gl/0LyEU
  
  if constructor is Object
    object = {}
    # keep constructor property non-enumerable when it's the default
  else
    pseudoConstructor = (->)
    pseudoConstructor.prototype = constructor.prototype
    object = new pseudoConstructor
    object.constructor = constructor
  
  if arguments is undefined
    arguments = []
  
  if arguments?
    constructed = constructor.apply object arguments
    
    if constructed? and constructed instanceof Object
      object = constructed
  
  object

mug.copy = copy = (object) ->
  # Returns a deep copy of Objects that are not Functions and of Strings.
  # Objects/parts that we do not copy are referenced.
  
  if object instanceof Object and object not instanceof Function
    result = make object.constructor, null
    
    for key of object
      if object.hasOwnProperty key
        result[key] = copy object[key]
    
    result
  else if object instanceof String
    String object
  else
    object

mug.call = call = (f, thisValue, args...) ->
  f.apply thisValue, args

mug.apply = apply = (f, thisValue, args) ->
  f.apply thisValue, args

mug.Promise = class Promise
  # an interactive promise along-the-lines of the CommmonJS proposal
  
  constructor: (value) ->
    @state = "unfulfilled"
    @id = "#{@constructor?.name}#{Math.random()}"
    @fulfillHandlers = []
    @failHandlers = []
    @handlers = { fulfill: [], fail: [], progress: [] }
    
    if value?
      @fulfill value
    
    null
  
  fulfill: (@value) ->
    if @state isnt "unfulfilled"
      throw new Error "Cannot fulfill a #{@state} Promise."
    
    @state = "fulfilled"
    
    for f in @handlers.fulfill
      f.call this, @value
    
    delete @handlers
  
  fail: ->
    if @state isnt "unfulfilled"
      throw new Error "Cannot fail a #{@state} Promise."
    
    @state = "failed"
    
    for f in @handlers.fail
      f.call this
    
    delete @handlers
  
  progress: (event) ->
    if @state isnt "unfulfilled"
      throw new Error "Cannot progress a #{@state} Promise."
    
    for f in @handlers.progress
      f.call this, event
    
    null
  
  also: (other) ->
    # create a new promise based on the outcome of this and another promise
    p = new Promise
    @then (other.then (-> p.fulfill()), (-> p.fail())), (-> p.fail())
  
  then: (fulfilledHander, failHandler, progressHandler) ->
    if fulfilledHander?
      if @state is "fulfilled"
        fulfilledHander.call this, @value
      else if @state is "unfulfilled"
        @handlers.fulfill.push fulfilledHander
    
    if failHandler?
      if @state is "failed"
        failHandler.call this, @value
      else if @state is "unfulfilled"
        @handlers.fail.push failHandler
    
    if progressHandler?
      if @state is "unfulfilled"
        @handlers.progress.push progressHandler
    
    null
  
  get: (propertyName) ->
    "a promise on a property of the promised value"
  
  call: (method, args...) ->
    "a promise on a method call on the pormised value"


# This module provides sequential data structures and iteration constructs
# based on bits from Python, Clojure and conventional JavaScript. This is
# provided by five functions: `mapper`, `iter`, `seq`, `deque`
# and `biter`. It also includes several classes instantiated by these
# functions.
# 
# Most of the functionality is built around three interfaces: Mapper and its
# children Iterator and Sequence. `mapper` returns a Mapper, `iter` and
# Iterator and `seq` a sequence.
# 
# ## Abstract Interfaces
# 
# ### Mapper
# 
# - `.each(f)` calls `f` for each value in the mapper. The first argument is the
#   value's index, the second is the value, which will also be the value of
#   `this`.
# - `.map(f)` calls `f` for each value in the mapper and returns an array of
#   the return values. The value is used as `this` and the only argument.
# - `.toArray()` returns an ordinary array of all of the values.
# - The result of calling one of these methods more than once is undefined. Unless
#   you know otherwise you should assume that a Mapper is single-use only.
# - Note that jQuery objects conform to this interface.
# 
# ### Iterator
# - `.hasNext()` indicates if there are any more values available.
# - `.next()` returns the next available value. The result is undefined if
#   `.hasNext()` is false.
# 
# ### Sequence
# - `.first()` returns the first value in a sequence. If the sequence is empty,
#   `undefined` is returned.
# - `.rest()` returns a sequence of all values in the sequence except the first.
#   If the Sequence is empty, it is itself returned.
# - Sequence objects are persistent: their value should never change and they are
#   reusable.
# 
# ### Argument to `mapper`/`iter`/`seq`/`deque`/`biter`
# 
# Any one of the follow criteria must be met:
# 
# - Be a Mapper, Iterator or Sequence.
# - Have a `.length` attribute and corresponding indexed values.
# - Have a `.mapper()`, `.iterator()` or `.sequence()` method returning an object
#   of the coresponding type.
# - Be a function, returning the next value each time called. If no more values
#   are available then `undefined` should be returned.
# 
# ## Concrete Types
# 
# ### Deque
# 
# Double-ended queue with constant-time insertion/access/removal from either end.
# Created using the `deque` function. If an argument is provided then its values
# are pushed on.
# 
# - `.push(value)`/`.unshift(value)` pushes a value onto the back/front of the
#   Deque.
# - `.pop()`/`.shift()` returns and removes the value at the back/front of the
#   Deque.
# - `.length` returns the number of values in the Deque.
# - `.back()`/`.front()` returns the value at back/front of the Deque without
#   removing it.
# - `.iterator()` returns an iterator pointed at the front of the Deque.
# 
# ### Buffered Iterator
# 
# Created with the `biter` function. It puts a `Deque` buffer on the front of an
# an iterator so that values need not be removed to be used.
# 
# - `.buffer` is the Deque being used as the buffer. When the next value is
#   needed, if the buffer contains any values they will be `.popFront()`ed before
#   more are drawn from the iterator.
# - `.first()` returns the next value from the iterator without removing it.
# - `.push(value)` pushes a value on the front of the buffer.
# 
# ## Laziness
# 
# Our objects behave nice and lazily. One possibly counterintutuive behaviour is
# that if you create one of them on an array or a Deque you can continue pushing
# values onto the end as long as you haven't accessed the end of the
# Iterator/Sequence yet.
# 
#     d = [1, 2] or deque([1, 2])
#     i = iter(d)
#     i.next() # 1
#     i.next() # 2
#     d.push(3)
#     i.next() # 3
#     i.next() # undefined
#     d.push(4)
#     i.next() # undefined

# These two functions are used internally only.

isFunction = (fs...) ->
    for f in fs
        if f not instanceof Function
            return false
    
    true

anyFunction = (fs...) ->
    for f in fs
        if f instanceof Function
            return true
    
    false

mug.mapper = mapper = (mappable) ->
    if isFunction mappable.mapper
        mappable.mapper()
    else if isFunction mappable.map, mappable.each, mappable.toArray
        mappable
    else if anyFunction mappable.map, mappable.each
        new MapperWraper mappable
    else if iter.canUseSimply mappable
        iter mappable
    else if seq.canUseSimply mappable
        seq mappable
    else
        e = new Error "()#{mappable}) is not Mappable."
        e.object = mappable
        throw e

mapper.canUseSimply = (o) ->
    anyFunction o.map, o.each, o.mapper
    
mug.iter = iter = (iterable) ->
    if isFunction iterable.iterator
        iterable.iterator()
    else if isFunction iterable.next, iterable.rest
        iterable
    else if iterable.length
        new ArrayIterator iterable
    else if isFunction iterable
        new FunctionIterator iterable
    else if seq.canUseSimply iterable
        new SequenceIterator seq iterable
    else if mapper.canUseSimply iterable
        iter mapper(iterable).toArray()
    else
        e = new Error "(#{iterable}) is not Iterable"
        e.object = iterable
        throw e

iter.canUseSimply = (o) ->
    isFunction(o.next, o.hasNext) or
    o.length? or anyFunction o, o.iterator

seq = (seqable) ->
    if isFunction sequable.sequence
        seqable.sequence()
    else if isFunction seqable.first, seqable.rest
        seqable
    else if iter.canUseSimply seqable
        new IteratorSequence iter seqable
    else if mapper.canUseSimply seqable
        new ArraySequence mapper(iterable).toArray()
    else
        e = new Error "(#{seqable}) is not Seqable"
        e.object = seqable
        throw e

seq.canUseSimply = (o) ->
    isFunction(o.first, o.rest) or
    anyFunction o.sequence

mug.biter = biter = (iterable) ->
    new BufferedIterator iter iterable

mug.deque = deque = (iterable) ->
    new Deque iterable

mug.Mapper = class Mapper
    each: (f) ->
        if @map is Mapper::map
            throw new Error "Mapper requires .each() or .map()."
        
        index = 0
        
        @map ->
            f.call this, index, this
            index += 1
            
            undefined
        
        undefined
    
    map: (f) ->
        if @each is Mapper::each
            throw new Error "Mapper requires .each() or .map()."
        
        result = []
        @each -> result.push f.call this, this
        
        result
    
    toArray: ->
        @map (x) -> x

mug.MapperWraper = class MapperWraper extends Mapper
    constructor: (object) ->
        if "map" in object
            @map = (args...) -> object.map args...
        if "each" in object
            @each = (args...) -> object.each args...
        if not (@each? or @map?)
            throw new Error "Mapper requires .each() or .map()."

mug.Iterator = class Iterator extends Mapper
    each: (f) ->
        index = 0
        
        while @hasNext()
            next = @next()
            f.call next, index, next
            index += 1
        
        undefined

mug.FunctionIterator = class FunctionIterator extends Iterator
    constructor: (@f, @previous) ->
    
    hasNext: ->
        if @buffer is undefined
            @buffer = @f.call @previous, @previous
        
        @buffer isnt undefined
    
    next: ->
        if @buffer isnt undefined
            buffered = @buffer
            delete @buffer
            @previous = buffered
            
            buffered
        else
            value = @f.call @previousValue, @previousValue
            @previous = value
            
            value

mug.ArrayIterator = class ArrayIterator extends Iterator
    constructor: (@array) ->
        @index = 0
    
    hasNext: ->
        @index < @array.length
    
    next: ->
        value = @array[@index]
        @index += 1
        
        value

mug.SequenceIterator = class SequenceIterator extends Iterator
    constructor: (@current) ->
    
    hasNext: ->
        @current.first() isnt undefined
    
    next: ->
        first = @current.first()
        @current = @current.rest()
        
        first

mug.Sequence = class Sequence extends Mapper
    each: (f) ->
        current = this
        index = 0
        
        while (first = current.first()) isnt undefined
            f.call first, index, first
            current = current.rest()
            index += 1
        
        undefined

mug.IteratorSequence = class IteratorSequence extends Sequence
    constructor: (@iterator) ->
    
    first: ->
        if @iterator.hasNext()
            first = @iterator.next()
            @first = -> first
    
    rest: ->
        if @first() isnt undefined
            rest = new IteratorSequence @iterator
            @rest = -> rest
        else
            this

mug.DequeNode = class DequeNode
    constructor: (@value) ->
        @next = null
        @prev = null

mug.Deque = class Deque
    constructor: (iterable) ->
        @head = null
        @tail = null
        @length = 0
        
        if iterable?
          @extend iterable
    
    push: (value) ->
        node = new DequeNode value
        node.prev = @tail
        @tail.next = node if @tail
        @tail = node
        @length += 1
        
        if not @head?
            @head = @tail
    
    extend: (iterable) ->
      d = this
      iter(iterable).each ->
        d.push this
    
    extendEnd: (iterable) ->
      d = this
      iter(iterable).each ->
        d.unshift this
    
    unshift: (value) ->
        node = new DequeNode value
        node.next = @head
        @head.prev = node if @head
        @head = node
        @length += 1
        
        if not @tail?
            @tail = @head
    
    pop: ->
        if not @length
            throw new Error "Cannot .pop() off of empty Deque."
        
        value = @tail.value
        @tail = @tail.prev
        @length -= 1
        
        if @tail?
            @head = @tail
        else
            @tail.next = null
        
    
    shift: (value) ->
        if not @length
            throw new Error "Cannot .shift() off of empty Deque."
        
        value = @head.value
        @head = @head.next
        @length -= 1
        
        if @head?
            @head.prev = null
        else
            @tail = null
    
    first: ->
        @head.value
    
    last: ->
        @tail.vaue
    
    iterator: ->
        new DequeIterator this

mug.DequeIterator = class DequeIterator extends Iterator
    # Iterates through value of a deque. You can peek at .first().
    # Should generalize this to some sort of graph iterator.
    # Initialized with a deque. Holds on to the next node after it
    # sees it for .first() or .hasNext().
    
    constructor: (@deque) ->
        @previousNode = null
        @node = null
    
    hasNext: ->
        if @node?
          true
        else
          if @previousNode
            @node = @previousNode.next
          else
            @node = @deque.head
          
          @node?
    
    next: ->
        if not @node?
          @node = @deque.head
        
        value = @.value
        @head = @head[@attr]
        @attr = "next"
        
        value

mug.BufferedIterator = class BufferedIterator extends Iterator
    constructor: (@iterator) ->
        @buffer = deque()
    
    hasNext: ->
        @buffer.length or @iterator.hasNext()
    
    next: ->
        if @buffer.length
            @buffer.shift()
        else
            @iterator.next()
    
    first: ->
        if not @buffer.length
            @buffer.unshift @iterator.next()
        
        @buffer.first()
    
    push: (value) ->
        @buffer.unshift value

mug.any = ref = (iterable) ->
  i = iter(iterable)
  
  if i.next()
    return true
  
  false

mug.all = (iterable) ->
  i = iter(iterable)
  
  if not i.next()
    return false
  
  true
