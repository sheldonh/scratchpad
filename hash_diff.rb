#!/usr/bin/env ruby
#
# An exercise in applying Robert C Martin's "Clean Code"
# (ISBN-10: 0-13-235088-2), using a Hash differ as the subject.

class HashDiff

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

  def initialize(old, new)
    @old = old
    @new = new
    @differences = nil
  end

  def different?
    not differences.empty?
  end

  def to_s
    differences.join("\n")
  end

  def differences
    @differences ||= first_time_comparison
  end

  private

  def first_time_comparison
    @differences = []
    compare
    @differences
  end

  def compare
    diffable_keys.each do |key|
      @key = key
      add_differences_for_key
    end
  end

  def diffable_keys
    @old.keys.concat( @new.keys ).uniq
  end

  def add_differences_for_key
    handle_removal or handle_addition or handle_change
  end

  def handle_removal
    if removed?
      add_removal
    end
  end

  def handle_addition
    if added?
      add_addition
    end
  end

  def handle_change
    if changed?
      add_change
    end
  end

  def removed?
    @old.include?(@key) and not @new.include?(@key)
  end

  def added?
    @new.include?(@key) and not @old.include?(@key)
  end

  def changed?
    old_value != new_value
  end

  def add_removal
    @differences << Removal.new(@key, old_value)
  end

  def add_addition
    @differences << Addition.new(@key, new_value)
  end

  def add_change
    @differences << Removal.new(@key, old_value)
    @differences << Addition.new(@key, new_value)
  end

  def old_value
    @old[@key]
  end

  def new_value
    @new[@key]
  end

end

require 'minitest/spec'
require 'minitest/autorun'

describe HashDiff do

  describe "#different?" do

    it "is false for identical hashes" do
      hash_diff = HashDiff.new( { no: :change }, { no: :change } )
      hash_diff.different?.must_equal false
    end

    it "is true for different hashes" do
      hash_diff = HashDiff.new( { change: :from }, { change: :to } )
      hash_diff.different?.must_equal true
    end

  end

  describe "#differences" do

    it "is empty for identical hashes" do
      hash_diff = HashDiff.new( { no: :change }, { no: :change } )
      hash_diff.differences.must_be_empty
    end

    it "includes a removal when the old hash has a key missing from the new hash" do
      hash_diff = HashDiff.new( { removed: :value }, {} )
      hash_diff.differences.must_include HashDiff::Removal.new(:removed, :value)
    end

    it "includes an addition when the new hash has a key missing from the old hash" do
      hash_diff = HashDiff.new( {}, { added: :value } )
      hash_diff.differences.must_include HashDiff::Addition.new(:added, :value)
    end

    it "includes a removal and an addition when the value in the old hash is changed in the new hash" do
      hash_diff = HashDiff.new( { change: :from }, { change: :to } )
      hash_diff.differences.must_include HashDiff::Removal.new(:change, :from)
      hash_diff.differences.must_include HashDiff::Addition.new(:change, :to)
    end

    it "caches the first comparison to avoid recomparison on subsequent access" do
      old, new = { no: :change }, { no: :change }
      hash_diff = HashDiff.new( old, new )

      first_time_differences = hash_diff.differences
      new[:change] = true
      hash_diff.differences.must_equal first_time_differences
    end

  end

end
