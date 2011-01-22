(function() {
  var ArrayIterator, BufferedIterator, Deque, DequeIterator, DequeNode, FunctionIterator, Iterator, IteratorSequence, Mapper, MapperWraper, Promise, Sequence, SequenceIterator, any, anyFunction, apply, biter, call, copy, deque, isFunction, iter, make, mapper, meta, mug, seq;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  mug = typeof exports != "undefined" && exports !== null ? exports : {};
  if (typeof window != "undefined" && window !== null) {
    window.mug = mug;
  }
  mug.meta = meta = {
    name: "Mug",
    version: [0, 0, 0],
    oneLineDescription: "A collection of things I like to have in CoffeeScript.",
    address: "https://gist.github.com/9ba8fffbe53d1ed642ce",
    author: "Jeremy Banks <jeremy@jeremybanks.com>",
    license: "Copyright 2011 Jeremy Banks. Released under the MIT license."
  };
  mug.make = make = function(constructor, arguments) {
    var constructed, object, pseudoConstructor;
    if (constructor === Object) {
      object = {};
    } else {
      pseudoConstructor = (function() {});
      pseudoConstructor.prototype = constructor.prototype;
      object = new pseudoConstructor;
      object.constructor = constructor;
    }
    if (arguments === void 0) {
      arguments = [];
    }
    if (arguments != null) {
      constructed = constructor.apply(object(arguments));
      if ((constructed != null) && constructed instanceof Object) {
        object = constructed;
      }
    }
    return object;
  };
  mug.copy = copy = function(object) {
    var key, result;
    if (object instanceof Object && !(object instanceof Function)) {
      result = make(object.constructor, null);
      for (key in object) {
        if (object.hasOwnProperty(key)) {
          result[key] = copy(object[key]);
        }
      }
      return result;
    } else if (object instanceof String) {
      return String(object);
    } else {
      return object;
    }
  };
  mug.call = call = function() {
    var args, f, thisValue;
    f = arguments[0], thisValue = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    return f.apply(thisValue, args);
  };
  mug.apply = apply = function(f, thisValue, args) {
    return f.apply(thisValue, args);
  };
  mug.Promise = Promise = (function() {
    function Promise(value) {
      var _ref;
      this.state = "unfulfilled";
      this.id = ("" + (Math.random())).replace("0.", "" + ((_ref = this.constructor) != null ? _ref.name : void 0) + "#");
      this.handlers = {
        fulfilment: [],
        failure: [],
        progress: []
      };
      if (value != null) {
        this.fulfill(value);
      }
      null;
    }
    Promise.prototype.fulfill = function(value) {
      var f, _i, _len, _ref;
      this.value = value;
      if (this.state !== "unfulfilled") {
        throw new Error("Cannot fulfill a " + this.state + " Promise.");
      }
      this.state = "fulfilled";
      _ref = this.handlers.fulfilment;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        f.call(this, this.value);
      }
      return delete this.handlers;
    };
    Promise.prototype.fail = function() {
      var f, _i, _len, _ref;
      if (this.state !== "unfulfilled") {
        throw new Error("Cannot fail a " + this.state + " Promise.");
      }
      this.state = "failed";
      _ref = this.handlers.fail;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        f.call(this);
      }
      return delete this.handlers;
    };
    Promise.prototype.progress = function(event) {
      var f, _i, _len, _ref;
      if (this.state !== "unfulfilled") {
        throw new Error("Cannot progress a " + this.state + " Promise.");
      }
      _ref = this.handlers.progress;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        f.call(this, event);
      }
      return null;
    };
    Promise.prototype.also = function(other) {
      var p;
      p = new Promise;
      return this.then(other.then((function() {
        return p.fulfill();
      }), (function() {
        return p.fail();
      })), (function() {
        return p.fail();
      }));
    };
    Promise.prototype.then = function(fulfilmentHandler, failureHandler, progressHandler) {
      if (this.state === "unfulfilled") {
        return this.on(fulfilmentHandler, failureHandler, progressHandler);
      } else {
        if ((fulfilmentHandler != null) && this.state === "fulfilled") {
          fulfilmentHandler.call(this, this.value);
        }
        if ((failureHandler != null) && this.state === "failed") {
          failureHandler.call(this, this.value);
        }
        return null;
      }
    };
    Promise.prototype.on = function(fulfilmentHandler, failureHandler, progressHandler) {
      if (this.state !== "unfulfilled") {
        return;
      }
      if (fulfilmentHandler != null) {
        this.handlers.fulfilment.push(fulfilmentHandler);
      }
      if (failureHandler != null) {
        this.handlers.failure.push(failureHandler);
      }
      if (progressHandler != null) {
        return this.handlers.progress.push(progressHandler);
      }
    };
    Promise.prototype.get = function(propertyName) {
      var p;
      p = new Promise;
      return this.then((function(value) {
        return p.fulfill(value[propertyName]);
      }), (function() {
        return p.fail();
      }), (function(event) {
        return p.progress(event);
      }));
    };
    Promise.prototype.call = function() {
      var args, methodName;
      methodName = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return this.then((function(value) {
        return p.fulfill(value[propertyName].apply(value, args));
      }), (function() {
        return p.fail();
      }), (function(event) {
        return p.progress(event);
      }));
    };
    return Promise;
  })();
  isFunction = function() {
    var f, fs, _i, _len;
    fs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    for (_i = 0, _len = fs.length; _i < _len; _i++) {
      f = fs[_i];
      if (!(f instanceof Function)) {
        return false;
      }
    }
    return true;
  };
  anyFunction = function() {
    var f, fs, _i, _len;
    fs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    for (_i = 0, _len = fs.length; _i < _len; _i++) {
      f = fs[_i];
      if (f instanceof Function) {
        return true;
      }
    }
    return false;
  };
  mug.mapper = mapper = function(mappable) {
    var e;
    if (isFunction(mappable.mapper)) {
      return mappable.mapper();
    } else if (isFunction(mappable.map, mappable.each, mappable.toArray)) {
      return mappable;
    } else if (anyFunction(mappable.map, mappable.each)) {
      return new MapperWraper(mappable);
    } else if (iter.canUseSimply(mappable)) {
      return iter(mappable);
    } else if (seq.canUseSimply(mappable)) {
      return seq(mappable);
    } else {
      e = new Error("()" + mappable + ") is not Mappable.");
      e.object = mappable;
      throw e;
    }
  };
  mapper.canUseSimply = function(o) {
    return anyFunction(o.map, o.each, o.mapper);
  };
  mug.iter = iter = function(iterable) {
    var e;
    if (isFunction(iterable.iterator)) {
      return iterable.iterator();
    } else if (isFunction(iterable.next, iterable.rest)) {
      return iterable;
    } else if (iterable.length) {
      return new ArrayIterator(iterable);
    } else if (isFunction(iterable)) {
      return new FunctionIterator(iterable);
    } else if (seq.canUseSimply(iterable)) {
      return new SequenceIterator(seq(iterable));
    } else if (mapper.canUseSimply(iterable)) {
      return iter(mapper(iterable).toArray());
    } else {
      e = new Error("(" + iterable + ") is not Iterable");
      e.object = iterable;
      throw e;
    }
  };
  iter.canUseSimply = function(o) {
    return isFunction(o.next, o.hasNext) || (o.length != null) || anyFunction(o, o.iterator);
  };
  seq = function(seqable) {
    var e;
    if (isFunction(sequable.sequence)) {
      return seqable.sequence();
    } else if (isFunction(seqable.first, seqable.rest)) {
      return seqable;
    } else if (iter.canUseSimply(seqable)) {
      return new IteratorSequence(iter(seqable));
    } else if (mapper.canUseSimply(seqable)) {
      return new ArraySequence(mapper(iterable).toArray());
    } else {
      e = new Error("(" + seqable + ") is not Seqable");
      e.object = seqable;
      throw e;
    }
  };
  seq.canUseSimply = function(o) {
    return isFunction(o.first, o.rest) || anyFunction(o.sequence);
  };
  mug.biter = biter = function(iterable) {
    return new BufferedIterator(iter(iterable));
  };
  mug.deque = deque = function(iterable) {
    return new Deque(iterable);
  };
  mug.Mapper = Mapper = (function() {
    function Mapper() {}
    Mapper.prototype.each = function(f) {
      var index;
      if (this.map === Mapper.prototype.map) {
        throw new Error("Mapper requires .each() or .map().");
      }
      index = 0;
      this.map(function() {
        f.call(this, index, this);
        index += 1;
        return void 0;
      });
      return void 0;
    };
    Mapper.prototype.map = function(f) {
      var result;
      if (this.each === Mapper.prototype.each) {
        throw new Error("Mapper requires .each() or .map().");
      }
      result = [];
      this.each(function() {
        return result.push(f.call(this, this));
      });
      return result;
    };
    Mapper.prototype.toArray = function() {
      return this.map(function(x) {
        return x;
      });
    };
    return Mapper;
  })();
  mug.MapperWraper = MapperWraper = (function() {
    __extends(MapperWraper, Mapper);
    function MapperWraper(object) {
      if (__indexOf.call(object, "map") >= 0) {
        this.map = function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return object.map.apply(object, args);
        };
      }
      if (__indexOf.call(object, "each") >= 0) {
        this.each = function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return object.each.apply(object, args);
        };
      }
      if (!((this.each != null) || (this.map != null))) {
        throw new Error("Mapper requires .each() or .map().");
      }
    }
    return MapperWraper;
  })();
  mug.Iterator = Iterator = (function() {
    function Iterator() {
      Iterator.__super__.constructor.apply(this, arguments);
    }
    __extends(Iterator, Mapper);
    Iterator.prototype.each = function(f) {
      var index, next;
      index = 0;
      while (this.hasNext()) {
        next = this.next();
        f.call(next, index, next);
        index += 1;
      }
      return void 0;
    };
    return Iterator;
  })();
  mug.FunctionIterator = FunctionIterator = (function() {
    __extends(FunctionIterator, Iterator);
    function FunctionIterator(f, previous) {
      this.f = f;
      this.previous = previous;
    }
    FunctionIterator.prototype.hasNext = function() {
      if (this.buffer === void 0) {
        this.buffer = this.f.call(this.previous, this.previous);
      }
      return this.buffer !== void 0;
    };
    FunctionIterator.prototype.next = function() {
      var buffered, value;
      if (this.buffer !== void 0) {
        buffered = this.buffer;
        delete this.buffer;
        this.previous = buffered;
        return buffered;
      } else {
        value = this.f.call(this.previousValue, this.previousValue);
        this.previous = value;
        return value;
      }
    };
    return FunctionIterator;
  })();
  mug.ArrayIterator = ArrayIterator = (function() {
    __extends(ArrayIterator, Iterator);
    function ArrayIterator(array) {
      this.array = array;
      this.index = 0;
    }
    ArrayIterator.prototype.hasNext = function() {
      return this.index < this.array.length;
    };
    ArrayIterator.prototype.next = function() {
      var value;
      value = this.array[this.index];
      this.index += 1;
      return value;
    };
    return ArrayIterator;
  })();
  mug.SequenceIterator = SequenceIterator = (function() {
    __extends(SequenceIterator, Iterator);
    function SequenceIterator(current) {
      this.current = current;
    }
    SequenceIterator.prototype.hasNext = function() {
      return this.current.first() !== void 0;
    };
    SequenceIterator.prototype.next = function() {
      var first;
      first = this.current.first();
      this.current = this.current.rest();
      return first;
    };
    return SequenceIterator;
  })();
  mug.Sequence = Sequence = (function() {
    function Sequence() {
      Sequence.__super__.constructor.apply(this, arguments);
    }
    __extends(Sequence, Mapper);
    Sequence.prototype.each = function(f) {
      var current, first, index;
      current = this;
      index = 0;
      while ((first = current.first()) !== void 0) {
        f.call(first, index, first);
        current = current.rest();
        index += 1;
      }
      return void 0;
    };
    return Sequence;
  })();
  mug.IteratorSequence = IteratorSequence = (function() {
    __extends(IteratorSequence, Sequence);
    function IteratorSequence(iterator) {
      this.iterator = iterator;
    }
    IteratorSequence.prototype.first = function() {
      var first;
      if (this.iterator.hasNext()) {
        first = this.iterator.next();
        return this.first = function() {
          return first;
        };
      }
    };
    IteratorSequence.prototype.rest = function() {
      var rest;
      if (this.first() !== void 0) {
        rest = new IteratorSequence(this.iterator);
        return this.rest = function() {
          return rest;
        };
      } else {
        return this;
      }
    };
    return IteratorSequence;
  })();
  mug.DequeNode = DequeNode = (function() {
    function DequeNode(value) {
      this.value = value;
      this.next = null;
      this.prev = null;
    }
    return DequeNode;
  })();
  mug.Deque = Deque = (function() {
    function Deque(iterable) {
      this.head = null;
      this.tail = null;
      this.length = 0;
      if (iterable != null) {
        this.extend(iterable);
      }
    }
    Deque.prototype.push = function(value) {
      var node;
      node = new DequeNode(value);
      node.prev = this.tail;
      if (this.tail) {
        this.tail.next = node;
      }
      this.tail = node;
      this.length += 1;
      if (!(this.head != null)) {
        return this.head = this.tail;
      }
    };
    Deque.prototype.extend = function(iterable) {
      var d;
      d = this;
      return iter(iterable).each(function() {
        return d.push(this);
      });
    };
    Deque.prototype.extendEnd = function(iterable) {
      var d;
      d = this;
      return iter(iterable).each(function() {
        return d.unshift(this);
      });
    };
    Deque.prototype.unshift = function(value) {
      var node;
      node = new DequeNode(value);
      node.next = this.head;
      if (this.head) {
        this.head.prev = node;
      }
      this.head = node;
      this.length += 1;
      if (!(this.tail != null)) {
        return this.tail = this.head;
      }
    };
    Deque.prototype.pop = function() {
      var value;
      if (!this.length) {
        throw new Error("Cannot .pop() off of empty Deque.");
      }
      value = this.tail.value;
      this.tail = this.tail.prev;
      this.length -= 1;
      if (this.tail != null) {
        return this.head = this.tail;
      } else {
        return this.tail.next = null;
      }
    };
    Deque.prototype.shift = function(value) {
      if (!this.length) {
        throw new Error("Cannot .shift() off of empty Deque.");
      }
      value = this.head.value;
      this.head = this.head.next;
      this.length -= 1;
      if (this.head != null) {
        return this.head.prev = null;
      } else {
        return this.tail = null;
      }
    };
    Deque.prototype.first = function() {
      return this.head.value;
    };
    Deque.prototype.last = function() {
      return this.tail.vaue;
    };
    Deque.prototype.iterator = function() {
      return new DequeIterator(this);
    };
    return Deque;
  })();
  mug.DequeIterator = DequeIterator = (function() {
    __extends(DequeIterator, Iterator);
    function DequeIterator(deque) {
      this.deque = deque;
      this.previousNode = null;
      this.node = null;
    }
    DequeIterator.prototype.hasNext = function() {
      if (this.node != null) {
        return true;
      } else {
        if (this.previousNode) {
          this.node = this.previousNode.next;
        } else {
          this.node = this.deque.head;
        }
        return this.node != null;
      }
    };
    DequeIterator.prototype.next = function() {
      var value;
      if (!(this.node != null)) {
        this.node = this.deque.head;
      }
      value = this.value;
      this.head = this.head[this.attr];
      this.attr = "next";
      return value;
    };
    return DequeIterator;
  })();
  mug.BufferedIterator = BufferedIterator = (function() {
    __extends(BufferedIterator, Iterator);
    function BufferedIterator(iterator) {
      this.iterator = iterator;
      this.buffer = deque();
    }
    BufferedIterator.prototype.hasNext = function() {
      return this.buffer.length || this.iterator.hasNext();
    };
    BufferedIterator.prototype.next = function() {
      if (this.buffer.length) {
        return this.buffer.shift();
      } else {
        return this.iterator.next();
      }
    };
    BufferedIterator.prototype.first = function() {
      if (!this.buffer.length) {
        this.buffer.unshift(this.iterator.next());
      }
      return this.buffer.first();
    };
    BufferedIterator.prototype.push = function(value) {
      return this.buffer.unshift(value);
    };
    return BufferedIterator;
  })();
  mug.any = any = function(iterable) {
    var i;
    i = iter(iterable);
    if (i.next()) {
      return true;
    }
    return false;
  };
  mug.all = function(iterable) {
    var i;
    i = iter(iterable);
    if (!i.next()) {
      return false;
    }
    return true;
  };
}).call(this);
