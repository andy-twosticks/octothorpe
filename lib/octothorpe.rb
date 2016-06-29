# Coding: UTF-8

require 'forwardable'


##
# A very simple hash-like class that borrows a little from OpenStruct, etc.
#
# * Treats string and symbol keys as equal
# * Access member objects with ot.>>.keyname
# * Guard conditions allow you to control what returns if key is not present
# * Pretty much read-only, for better or worse
#
# Meant to facilitate message-passing between classes.
#
# Simple example:
#     ot = Octothorpe.new(one: 1, "two" => 2, "weird key" => 3)
#     ot.>>.one            # -> 1
#     ot.>>.two            # -> 2
#     ot.get("weird key")  # -> 3
#
# With guard conditions:
#     ot = Octotghorpe.new(one: 1, "two" => 2)
#     ot.guard(Array, :three)
#     ot.freeze       # optional step - makes OT truly read-only
#     ot.>>.three     # -> [] 
#     ot.>>.three[9]  # valid (of course; returns nil)
#
# Octothorpe additionally responds to the following methods exactly as a Hash would:
#
#    empty?, has_key?, has_value?, include?
#    each,   each_key, each_value, keys,    values
#    select, map,      reject,     inject
#    merge,  <,        >
#
class Octothorpe
  extend Forwardable

  def_delegators :@inner_hash, :empty?, :has_key?, :has_value?, :include?
  def_delegators :@inner_hash, :each, :each_key, :each_value, :keys, :values
  def_delegators :@inner_hash, :select, :map, :reject, :inject

  # Gem version number
  VERSION = '0.3.0'


  # Generic Octothorpe error class
  class OctoError < StandardError; end

  # Raised when Octothorpe needs a hash but didn't get one
  class BadHash < OctoError; end

  # Raised when caller tries to modify a frozen Octothorpe
  class Frozen < OctoError; end


  ## 
  # Inner class for storage. This is to minimise namespace collision with key names. Not exposed to
  # Octothorpe's caller.
  #
  class Storage
    attr_reader :octothorpe_store

    def initialize(hash)
      @octothorpe_store = hash
    end

    def method_missing(method, *attrs)
      super if (block_given? || !attrs.empty?)
      @octothorpe_store[method.to_sym]
    end

  end
  ##


  ##
  # :call-seq:
  #   ot = Octothrpe.new(hash)
  #
  # Initialise an Octothorpe object by passing it a hash.
  #
  # You can create an empty OT by calling Octothorpe.new, but there's probably little utility in
  # that, given that it is read-only.
  #
  # If you pass anything other than nil or something OT can treat as a Hash, you will cause an
  # Octothorpe::BadHash exception.
  #
  def initialize(hash=nil)
    @store = Storage.new( symbol_hash(hash || {}) )
    @inner_hash = @store.octothorpe_store
  end


  ##
  # :call-seq:
  #   ot.>>.keyname
  #
  # You can use >> to access member objects in somewhat the same way as an OpenStruct.
  #
  #   ot = Octotghorpe.new(one: 1, "two" => 2)
  #   ot.>>.one  # -> 1
  #
  # This will not work for members that have keys with spaces in, or keys which have the same name
  # as methods on Object. Use _get_ for those.
  #
  def >>; @store; end


  ##
  # :call-seq:
  #   ot.get(key)
  #   ot.send(key)
  #   ot[key]
  #
  # You can use get to access member object values instead of the >> syntax.
  #
  # Unlike >>, this works for keys with spaces, or keys that have the same name as methods on
  # Object.
  #
  def get(key); @store.octothorpe_store[key.to_sym]; end

  alias send get
  alias [] get


  ##
  # Returns a hash of the object.
  #
  def to_h; @store.octothorpe_store; end


  ##
  # :call-seq:
  #   ot.guard( class, key [, key, ...] )
  #   ot.guard( key, [,key, ...] ) {|k| ... }
  #
  # Guarantees the initial state of a memnber. Each key that is not already present will be set to
  # <class>.new. Has no effect if key is already present. Class must be some class Thing that can
  # respond to a vanilla Thing.new.
  #
  # Alternatively, for the block form, the key is passed to the block, and the value of the key
  # becomes the return value of the block ... but again, ONLY if the key is not already set.
  #
  # Note that this is the only time that you can modify an Octothorpe object once it is created. If
  # you call _freeze_ on an it, it will become genuinely read-only, and any call to guard from then
  # on will raise Octothorpe::Frozen.
  #
  def guard(*args)
    raise Frozen if self.frozen?

    klass = args.shift unless block_given?
    keys  = args.map(&:to_sym)

    if block_given?
      keys.each{|k| @store.octothorpe_store[k] ||= yield k }
    else
      keys.each{|k| @store.octothorpe_store[k] ||= klass.new }
    end

    self
  end


  ##
  # :call-seq:
  #   ot.merge(other)                              -> new_ot
  #   ot.merge(other){|key, oldval, newval| block} -> new_ot
  #
  # Exactly as _Hash.merge_, but returns a new Octothorpe object.
  #
  # You may pass a hash or an octothorpe. Raises Octothorpe::BadHash if it is anything else.
  #
  def merge(other)
    thisHash  = @store.octothorpe_store
    otherHash = symbol_hash(other)

    merged = 
      if block_given?
        thisHash.merge(otherHash) {|key,old,new| yield key, old, new }
      else
        thisHash.merge(otherHash)
      end

    Octothorpe.new(merged)
  end


  # 
  # Resolve some of the standard comparisons (with an OT or a hash)
  #
  
  def ==(other); compare_as_hash(other, :==); end
  def <(other);  compare_as_hash(other, :<);  end
  def >(other);  compare_as_hash(other, :>);  end
  def >=(other); compare_as_hash(other, :>=); end
  def <=(other); compare_as_hash(other, :<=); end


  ##
  # Inspect exposes a view of the inner hash
  #
  def inspect
    "#<Octothorpe#{@store.octothorpe_store.inspect}>"
  end


  private


  ##
  # Try to return thing as a hash with symbols for keys
  #
  def symbol_hash(thing)
    if thing.kind_of?(Octothorpe)
      thing.to_h
    else
      thing.each_with_object({}) {|(k,v),m| m[k.to_sym] = v }
    end
  rescue
    raise BadHash
  end


  ##
  # Given an 'other' - Hash or OT - render both self and other down to a hash then run the given
  # comparason on them and return the result
  #
  def compare_as_hash(other, method)
    thisHash  = @store.octothorpe_store.to_h
    otherHash = symbol_hash(other)
    thisHash.send(method, otherHash)
  end

end

