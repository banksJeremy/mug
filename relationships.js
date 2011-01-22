(function() {
  var BayesianEvent, PhysicalObject, Promise, Ref, addition, commutitiveOperation, complement, copy, equality, mug, multiplication, neg, pow, product, reciprocal, relationships, snapInt, sum, _ref;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __slice = Array.prototype.slice;
  _ref = mug = ((typeof window != "undefined" && window !== null ? window.mug : void 0) != null) || (typeof require === "function" ? require("./mug") : void 0), copy = _ref.copy, Promise = _ref.Promise;
  mug.relationships = relationships = typeof exports != "undefined" && exports !== null ? exports : {};
  relationships.meta = copy(mug.meta);
  relationships.meta.name = "Mug.Relationships";
  relationships.meta.oneLineDescription = "Operations with relationships between numbers. GIGO.";
  snapInt = function(f) {
    if (Math.abs(f % 1) < 1e-12) {
      return f - f % 1;
    } else {
      return f;
    }
  };
  relationships.Ref = Ref = (function() {
    function Ref() {
      Ref.__super__.constructor.apply(this, arguments);
    }
    __extends(Ref, Promise);
    Ref.prototype.is = function(value) {
      if ((value != null) && this.state === "unfulfilled") {
        if (value instanceof Function) {
          value = value();
        }
        this.fulfill(this.value = value);
      }
      return this.value;
    };
    return Ref;
  })();
  Ref.of = function(value) {
    if (value instanceof Ref) {
      return value;
    } else {
      return new Ref(value);
    }
  };
  Ref.many = function(n) {
    var _, _results;
    if (n == null) {
      n = 12;
    }
    _results = [];
    for (_ = 0; (0 <= n ? _ < n : _ > n); (0 <= n ? _ += 1 : _ -= 1)) {
      _results.push(new this);
    }
    return _results;
  };
  addition = {
    perform: function(a, b) {
      var c;
      return c = a + b;
    },
    undo: function(c, b) {
      var a;
      return a = c - b;
    },
    identity: 0
  };
  multiplication = {
    perform: function(a, b) {
      var c;
      return c = a * b;
    },
    undo: function(c, b) {
      var a;
      return a = c / b;
    },
    identity: 1
  };
  commutitiveOperation = function(operation) {
    return function() {
      var outstandingVars, ref, refs, result, update, _i, _len;
      refs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      refs = refs.map(Ref.of);
      result = new Ref;
      outstandingVars = refs.length;
      update = function() {
        var ref, remainingValue, runningValue, unknownOne, _i, _j, _len, _len2;
        if (outstandingVars === 1 && (result.value != null)) {
          remainingValue = result.value;
          for (_i = 0, _len = refs.length; _i < _len; _i++) {
            ref = refs[_i];
            if (ref.value != null) {
              remainingValue = operation.undo(remainingValue, ref.value);
            } else {
              unknownOne = ref;
            }
          }
          unknownOne.is(remainingValue);
        } else if (outstandingVars === 0 && !(result.value != null)) {
          runningValue = operation.identity;
          for (_j = 0, _len2 = refs.length; _j < _len2; _j++) {
            ref = refs[_j];
            runningValue = operation.perform(runningValue, ref.value);
          }
          result.is(runningValue);
        }
        return null;
      };
      result.then(update);
      for (_i = 0, _len = refs.length; _i < _len; _i++) {
        ref = refs[_i];
        ref.then(function(value) {
          outstandingVars -= 1;
          return update();
        });
      }
      return result;
    };
  };
  relationships.sum = sum = commutitiveOperation(addition);
  relationships.product = product = commutitiveOperation(multiplication);
  relationships.pow = pow = function(base, power) {
    var result;
    base = Ref.of(base);
    power = Ref.of(power);
    result = new Ref;
    base.then(function() {
      return power.then(function() {
        return result.is(Math.pow(base.value, power.value));
      });
    });
    result.then(function() {
      return base.then(function() {
        return power.is(snapInt(Math.log(result.value) / Math.log(base.value)));
      });
    });
    result.then(function() {
      return power.then(function() {
        return base.is(snapInt(Math.pow(result.value, 1 / power.value)));
      });
    });
    return result;
  };
  relationships.equality = equality = function() {
    var ref, refs, _i, _len;
    refs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    refs = refs.map(Ref.of);
    for (_i = 0, _len = refs.length; _i < _len; _i++) {
      ref = refs[_i];
      ref.then(function(value) {
        var refP, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = refs.length; _i < _len; _i++) {
          refP = refs[_i];
          _results.push(refP.is(value));
        }
        return _results;
      });
    }
    return refs[0];
  };
  relationships.complement = complement = function(ref) {
    ref = Ref.of(ref);
    if (!(ref._complement != null)) {
      ref._complement = new Ref;
      ref._complement._complement = ref;
      sum(ref, ref._complement).is(1);
    }
    return ref._complement;
  };
  relationships.reciprocal = reciprocal = function(ref) {
    ref = Ref.of(ref);
    if (!(ref._reciprocal != null)) {
      ref._reciprocal = new Ref;
      ref._reciprocal._reciprocal = ref;
      product(ref, ref._reciprocal).is(1);
    }
    return ref._reciprocal;
  };
  relationships.neg = neg = function() {
    return function(ref) {
      ref = Ref.of(ref);
      if (!(ref._neg != null)) {
        ref._neg = new Ref;
        ref._neg._neg = ref;
        sum(ref, ref._neg).is(0);
      }
      return ref._neg;
    };
  };
  /*===========================================================================
  I haven't put a ton of thought into how I'm going to organize this module yet.
  ===========================================================================*/
  relationships.PhysicalObject = PhysicalObject = (function() {
    function PhysicalObject(knowns) {
      var name, value, _ref;
      _ref = Ref.many(), this.force = _ref[0], this.mass = _ref[1], this.acceleration = _ref[2], this.kineticEnergy = _ref[3], this.speed = _ref[4], this.density = _ref[5], this.volume = _ref[6], this.displacement = _ref[7];
      if (knowns != null) {
        for (name in knowns) {
          value = knowns[name];
          if (!(name in this)) {
            this[name] = new Ref(value);
          } else {
            this[name].is(value);
          }
        }
      }
      equality(this.force, product(this.mass, this.acceleration));
      equality(this.kineticEnergy, product(.5, this.mass, pow(this.speed, 2)));
      equality(this.density, product(this.mass, reciprocal(this.volume)));
    }
    return PhysicalObject;
  })();
  relationships.BayesianEvent = BayesianEvent = (function() {
    __extends(BayesianEvent, Ref);
    function BayesianEvent() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      BayesianEvent.__super__.constructor.apply(this, args);
      this._given = {};
      this;
    }
    BayesianEvent.prototype.given = function(that) {
      var thatGivenNotThis, thatGivenThis, thisGivenNotThat, thisGivenThat;
      if (!(that.id in this._given)) {
        thisGivenThat = this._given[that.id] = new Ref;
        thisGivenNotThat = this._given[complement(that).id] = new Ref;
        thatGivenThis = that._given[this.id] = new Ref;
        thatGivenNotThis = that._given[complement(this).id] = new Ref;
        equality(product(thisGivenThat, that), product(thatGivenThis, this));
        equality(that, sum(product(thisGivenThat, that), product(thisGivenNotThat, complement(that))));
        equality(this, sum(product(thatGivenThis, this), product(thatGivenNotThis, complement(this))));
      }
      return this._given[that.id];
    };
    return BayesianEvent;
  })();
}).call(this);
