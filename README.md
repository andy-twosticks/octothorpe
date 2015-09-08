# Octothorpe

A very simple hash-like class that borrows a little from OpenStruct, etc.

* Treats string and symbol keys as equal
* Access member objects with ot.>>.keyname
* Guard conditions allow you to control what returns if key is not present
* Pretty much read-only, for better or worse

Meant to facilitate message-passing between classes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'octothorpe'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install octothorpe

## Usage

Simple example:

    ot = Octotghorpe.new(one: 1, "two" => 2, "weird key" => 3)
    ot.>>.one            # -> 1
    ot.>>.two            # -> 2
    ot.get("weird key")  # -> 3

With guard conditions:

    ot = Octotghorpe.new(one: 1, "two" => 2)
    ot.guard(Array, :three)
    ot.freeze       # optional step - makes OT truly read-only
    ot.>>.three     # -> [] 
    ot.>>.three[9]  # valid (of course; returns nil)

Octothorpe responds to a good subset of the methods that hash does
(although, not the write methods).

## FAQ

### Octo-what?

An antiquated term for the pound, or, _hash_ key on a phone keyboard. It's a
sort of a joke, you see. Or, very nearly.

### This is a very small library. Was it really worth it?

Maybe not. Feel free to be your own judge.

### What possible use is it?

If you are fed up with errors caused because Gem A gives you a hash with string
keys and Gem B expects symbol keys; or you are tired of putting:

    hash && (hash[:key] || {})[4]

...then this might just possibly be of use. 

Alternatively you might try an OpenStruct, Rails' HashWithIndifferentAccess,
the Hashie gem or the AndAnd gem.

### Why Read-Only?

Functional programming. 

I find it very hard to fully realise the ideals of functional programming in
Ruby; but as I get closer to those ideals, my code becomes clearer to read and
my tests become much, much simpler.

