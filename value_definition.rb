=begin
These #value methods are not for producing a defensive copy of data. They're
for saying that the Hash or Array they were called on *is* a value object.
They say

* it was instantiated to represent an immutable value, and
* it is composed entirely of objects that don't need to change ever again.

So this is being a douchebag:

    def transform data
      SideEffectyThing.process data.value
    end

Congratulations, you've introduced a side effect.

This is not being a douchebag:

    config = {
      basedir: '/usr'
      prefix: '/usr/local',
      confdir: '/etc',
    }.value
    SideEffectyThing.configure config
    OtherSideEffectyThing.configure config

The #value methods freeze everything they can get their hands on inside the
data structure. If those things are enumerable, they'll get their contents
frozen as well. And so on.

So I say again: this is *not* for producing safe copies of data. This is for
saying that a literal hash or array is a value object, and then trying hard
to make it so.

To be safe: only call #value on data structures that you created yourself,
composed entirely of objects that you created yourself.
=end
module ValueDefinition

  module Hash

    def value
      v = inject({}) do |m, (k, v)|
        m[k] = ValueDefinition::Util::to_value(v).freeze
        m
      end
      ValueDefinition::Object.new v.freeze
    end

    def self.included(other)
      other.send :include, ValueDefinition
    end

  end

  module Array

    def value
      map! { |v| ValueDefinition::Util::to_value(v).freeze }
      freeze
    end

    def self.included(other)
      other.send :include, ValueDefinition
    end

  end

  module Util

    def self.to_value(o)
      if o.is_a?(ValueDefinition)
        o.value
      elsif o.is_a?(Enumerable)
        o.map { |e| e.is_a?(ValueDefinition) ? e.value : e }
      else
        o
      end
    end

  end

  class Object

    # Relies on the caller to pass in adequately defensive properties.
    def initialize(properties)
      (@properties = properties).each do |accessor, value|
        instance_variable_set :"@#{accessor}", value
        self.class.send :attr_reader, accessor
      end
      freeze
    end

    def to_hash
      @properties
    end

    def to_s
      to_hash.to_s
    end

    def eql?(other)
      other.respond_to?(:to_hash) and to_hash == other.to_hash
    end

    def ==(other)
      other.class == self.class and eql?(other)
    end

    def hash
      @properties.hash
    end

  end

end

if defined?(RSpec) and respond_to?(:describe)

  Hash.send :include, ValueDefinition::Hash
  Array.send :include, ValueDefinition::Array

  describe 'ValueDefinition::Hash#value' do

    it "returns a deeply immutable value object" do
      v = {identity: {names: [{first: 'Sheldon', last: 'Hearn'}, {first: 'Universal', last: 'Overlord'}]}}.value
      expect(v.identity.names[0].first).to eql 'Sheldon'
      expect { v.identity = :anonymous }.to raise_error NoMethodError
      expect { v.identity.names[0].first.upcase! }.to raise_error /frozen/
      expect { v.identity.names[0].first = 'Bruce' }.to raise_error NoMethodError
      expect { v.identity.names.pop }.to raise_error /frozen/
    end

  end

  describe 'ValueDefinition::Array#value' do

    it "returns a deeply immutable value object collection" do
      v = ['one', 'two', ['three', 'four']].value
      expect(v[2][0]).to eql 'three'
      expect(v.flatten).to eql ['one', 'two', 'three', 'four']
      expect(v.map {|e| e}).to eql ['one', 'two', ['three', 'four']]
      expect { v.pop }.to raise_error /frozen/
      expect { v[2][0] = :mutate }.to raise_error /frozen/
      expect { v[2][0].upcase! }.to raise_error /frozen/
    end

  end

  describe 'ValueDefinition::Object' do

    it "implements equality" do
      a = ValueDefinition::Object.new foo: 'bar'
      b = ValueDefinition::Object.new foo: 'bar'
      c = ValueDefinition::Object.new foo: 'different'
      expect(a).to_not eql Object.new
      expect(a).to eql b
      expect(a).to eql foo: 'bar'
      expect(a).to_not eql c
    end

    it "implements a hashcode" do
      a = ValueDefinition::Object.new foo: 'bar'
      b = ValueDefinition::Object.new foo: 'bar'
      c = ValueDefinition::Object.new foo: 'different'
      expect(a.hash).to eql b.hash
      expect(a.hash).to eql({foo: 'bar'}.hash)
      expect(a.hash).to_not eql c.hash
    end

    it "implements shallow copy" do
      a = ValueDefinition::Object.new foo: Object.new
      b = a.clone
      c = a.dup
      expect(a).to eql b
      expect(b).to eql c
      expect(a.foo.object_id).to eql c.foo.object_id
    end

  end

end
