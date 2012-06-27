#!/usr/bin/env ruby
#
require 'minitest/spec'
require 'minitest/autorun'

class FastStruct < BasicObject

  alias_method :fast_struct_original_method_missing, :method_missing

  def initialize(&block)
    instance_eval &block

    def self.method_missing(method, *args)
      fast_struct_original_method_missing(method, *args)
    end
  end

  def method_missing(method, *args)
    instance_eval %Q{
      def self.#{method}
        #{args.first.inspect}
      end
    }
  end

end

describe FastStruct do

  it "assigns a string to an attribute reader" do
    object = FastStruct.new { name "Value" }
    object.name.must_equal "Value"
  end

  it "assigns an integer to an attribute reader" do
    object = FastStruct.new { meaning 42 }
    object.meaning.must_equal 42
  end

  it "assigns a float to an attribute reader" do
    object = FastStruct.new { floater 1.1 }
    object.floater.must_equal 1.1
  end

  it "assigns a symbol to an attribute reader" do
    object = FastStruct.new { symbolism :colon }
    object.symbolism.must_equal :colon
  end

  it "assigns an array to an attribute reader" do
    object = FastStruct.new { collection [1, :two, 'three'] }
    object.collection.must_equal [1, :two, 'three']
  end

  it "assigns a shallow hash to an attribute reader" do
    object = FastStruct.new { dictionary meaning: 42, subject:  "Life" }
    object.dictionary.must_equal meaning: 42, subject: "Life"
  end

  it "assigns a nested hash to an attribute reader" do
    object = FastStruct.new { nested adam: { begat: [ :cane, :abel ] } }
    object.nested.must_equal adam: { begat: [ :cane, :abel ] }
  end

  it "raises NoMethodError for calls to unknown readers" do
    object = FastStruct.new { known :property }
    -> { object.unknown_property }.must_raise NoMethodError
  end

end

