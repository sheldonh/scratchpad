#!/usr/bin/env ruby
#
# An exercise in applying Robert C Martin's "Clean Code"
# (ISBN-10: 0-13-235088-2), using a Hash differ as the subject.

module ObjectDiff

  class Hash

    def initialize(old, new)
      @old = old
      @new = new
      @differences = nil
    end

    def different?
      not differences.empty?
    end

    def to_s
      differences.collect { |o| "#{o}\n" }.join
    end

    def differences
      calculate_differences_if_first_time
      @differences
    end

    private

    def calculate_differences_if_first_time
      if @differences.nil?
        @differences = []
        calculate_differences
      end
    end

    def calculate_differences
      keys_from_both_hashes.each do |key|
        @key = key
        handle_differences_for_key
      end
    end

    def handle_differences_for_key
      handle_removal_for_key or handle_addition_for_key or handle_change_for_key
    end

    def handle_removal_for_key
      if key_removed?
        add_removal_for_key
      end
    end

    def handle_addition_for_key
      if key_added?
        add_addition_for_key
      end
    end

    def handle_change_for_key
      if key_value_changed?
        add_change_for_key
      end
    end

    def key_removed?
      @old.include?(@key) and not @new.include?(@key)
    end

    def key_added?
      @new.include?(@key) and not @old.include?(@key)
    end

    def key_value_changed?
      old_value != new_value
    end

    def add_removal_for_key
      @differences << Removal.new(@key, old_value)
    end

    def add_addition_for_key
      @differences << Addition.new(@key, new_value)
    end

    def add_change_for_key
      @differences << Removal.new(@key, old_value)
      @differences << Addition.new(@key, new_value)
    end

    def keys_from_both_hashes
      @old.keys.concat( @new.keys ).uniq
    end

    def old_value
      @old[@key]
    end

    def new_value
      @new[@key]
    end

  end

  class Difference

    attr_accessor :key, :value

    def initialize(key, value)
      @key, @value = key, value
    end

    def to_s
      raise NotImplementedError
    end

    def ==(other)
      self.class == other.class and key == other.key and value == other.value
    end

  end

  class Removal < Difference

    def to_s
      "- #{@key.inspect}: #{@value.inspect}"
    end

  end

  class Addition < Difference

    def to_s
      "+ #{@key.inspect}: #{@value.inspect}"
    end

  end

end

require 'minitest/spec'
require 'minitest/autorun'

describe ObjectDiff::Hash do

  describe "#different?" do

    it "is false for identical hashes" do
      hash_diff = ObjectDiff::Hash.new( { no: :change }, { no: :change } )
      hash_diff.different?.must_equal false
    end

    it "is true for different hashes" do
      hash_diff = ObjectDiff::Hash.new( { change: :from }, { change: :to } )
      hash_diff.different?.must_equal true
    end

  end

  describe "#differences" do

    it "is empty for identical hashes" do
      hash_diff = ObjectDiff::Hash.new( { no: :change }, { no: :change } )
      hash_diff.differences.must_be_empty
    end

    it "includes a removal when the old hash has a key missing from the new hash" do
      hash_diff = ObjectDiff::Hash.new( { removed: :value }, {} )
      hash_diff.differences.must_include ObjectDiff::Removal.new(:removed, :value)
    end

    it "includes an addition when the new hash has a key missing from the old hash" do
      hash_diff = ObjectDiff::Hash.new( {}, { added: :value } )
      hash_diff.differences.must_include ObjectDiff::Addition.new(:added, :value)
    end

    it "includes a removal and an addition when the value in the old hash is changed in the new hash" do
      hash_diff = ObjectDiff::Hash.new( { change: :from }, { change: :to } )
      hash_diff.differences.must_include ObjectDiff::Removal.new(:change, :from)
      hash_diff.differences.must_include ObjectDiff::Addition.new(:change, :to)
    end

    it "caches the first comparison to avoid recomparison on subsequent access" do
      old, new = { no: :change }, { no: :change }
      hash_diff = ObjectDiff::Hash.new( old, new )

      first_time_differences = hash_diff.differences
      new[:change] = true
      hash_diff.differences.must_equal first_time_differences
    end

  end

  describe "#to_s" do

    it "produces an empty string for identical hashes" do
      hash_diff = ObjectDiff::Hash.new( { no: :change }, { no: :change } )
      hash_diff.to_s.must_equal ''
    end

    it "produces unified diff output for different hashes" do
      hash_diff = ObjectDiff::Hash.new( { change: :from }, { change: :to } )
      hash_diff.to_s.must_equal "- :change: :from\n+ :change: :to\n"
    end

  end

end 
