require 'octothorpe'

describe Octothorpe do


  before do
    @hash  = {one: 'a', 'two' => 2, dup: 3, "weird key" => 4}
    @hash2 = @hash.each_with_object({}) {|(k,v),m| m[k.to_sym] = v }
    @ot    = Octothorpe.new(@hash)
  end


  describe "#new" do

    it "takes a hash" do
      expect{ Octothorpe.new(one: 2, three: 4) }.not_to raise_exception
    end

    it "accepts no arguments" do
      expect{ Octothorpe.new }.not_to raise_exception
    end

    it "raises Octothorpe::BadHash if passed non-hash, non-nil" do
      expect{ Octothorpe.new("hello") }.to raise_exception Octothorpe::BadHash
      expect{ Octothorpe.new(:boo)    }.to raise_exception Octothorpe::BadHash
      expect{ Octothorpe.new(14)      }.to raise_exception Octothorpe::BadHash
    end

  end


  describe "#>>" do

    it "returns the value with the given key" do
      expect(@ot.>>.one).to eq @hash2[:one]
      expect(@ot.>>.two).to eq @hash2[:two]
    end

    it "returns nil when given a non-key value" do
      expect(@ot.>>.three).to be_nil
    end

    it "throws an exception if passed a parameter or block" do
      expect{ @ot.>>.three(1)          }.to raise_exception
      expect{ @ot.>>.three{|x| puts x} }.to raise_exception
    end

  end


  describe "#get" do

    it "returns the value with the given key" do
      expect( @ot.get(:one) ).to eq @hash2[:one]
      expect( @ot.get(:two) ).to eq @hash2[:two]
    end

    it "returns nil when given a non-key value" do
      expect( @ot.get(:three) ).to be_nil
    end

    it "will return odd keys" do
      expect( @ot.get(:dup)        ).to eq @hash2[:dup]
      expect( @ot.get('weird key') ).to eq @hash2[:'weird key']
    end

  end


  describe "#[]" do

    it "acts just like get" do
      expect( @ot[:one] ).to eq @hash2[:one]
      expect( @ot[:two] ).to eq @hash2[:two]
    end

  end


  describe "#to_h" do

    it "dumps the OT as a hash" do
      expect( @ot.to_h ).to eq @hash2
    end

  end


  describe "#guard" do

    it "sets the given fields with a default value for the class" do
      @ot.guard(Array, :alpha)
      @ot.guard(Hash,  :beta)

      expect( @ot.>>.alpha ).to eq([])
      expect( @ot.>>.beta  ).to eq({})
    end

    it "returns self" do
      expect( @ot.guard(Array, :foo) ).to eq @ot
    end

    it "only sets the field if it does not already exist" do
      @ot.guard(Array, :one)
      expect( @ot.>>.one ).to eq @hash2[:one]
    end

    it "accepts a list of keys" do
      @ot.guard(Array, :fred, :daphne, "velma")
      otHash = @ot.to_h
      expect( otHash[:fred]   ).to eq([])
      expect( otHash[:daphne] ).to eq([])
      expect( otHash[:velma]  ).to eq([])
    end

    it "raises Octothorpe::Frozen if the OT is frozen" do
      @ot.freeze
      expect{ @ot.guard(Hash, :foo) }.to raise_exception Octothorpe::Frozen
    end

  end


  describe "#merge" do
    before do
      @other = {fred: 1, "velma" => 2}
    end

    it "accepts a hash" do
      expect{ @ot.merge(@other) }.not_to raise_exception
    end

    it "accepts another OT" do
      ot2 = Octothorpe.new(@other)
      expect{ @ot.merge(ot2) }.not_to raise_exception
    end

    it "raises Octothorpe::BadHash if the parameter cannot be turned into a hash" do
      expect{ @ot.merge(12)  }.to raise_exception Octothorpe::BadHash
      expect{ @ot.merge(nil) }.to raise_exception Octothorpe::BadHash
    end

    it "returns a new OT that combines the self OT with another" do
      ot2    = @ot.merge(@other)
      other2 = @other.each_with_object({}) {|(k,v),m| m[k.to_sym] = v }

      expect( ot2      ).to be_a( Octothorpe )
      expect( ot2.to_h ).to eq( @hash2.merge(other2) )
    end

    it "honours the Hash.merge block format" do
      h1  = {one: 1, two: 2}
      h2  = {one: 3, two: 4}

      ot  = Octothorpe.new(h1)
      ans = ot.merge(h2){|k,o,n| o.to_s + '.' + n.to_s }

      expect( ans.to_h ).to eq( {one: '1.3', two: '2.4'} )
    end

  end


  describe "(miscelaneous other stuff)" do
    # I "imagine" that the actual class uses Forwardable, but the test code
    # shouldn't know or care about that.  In any case, just testing with
    # responds_to always feels like cheating.

    it "behaves like a Hash for a bunch of query methods" do
      expect( @ot.empty? ).not_to eq true
      expect( Octothorpe.new().empty? ).to eq true

      expect( @ot.has_key?(:two) ).to eq true
      expect( @ot.has_key?(:four) ).not_to eq true

      expect( @ot.has_value?(3) ).to eq true
      expect( @ot.has_value?(14) ).not_to eq true

      expect( @ot.include?(:two) ).to eq true
      expect( @ot.include?(:foo) ).not_to eq true
    end

    it "behaves like a hash for a bunch of methods that return an array" do
      expect( @ot.keys   ).to eq(@hash2.keys)
      expect( @ot.values ).to eq(@hash2.values)

      expect( @ot.map{|k,v| k} ).to eq( @hash2.map{|k,v| k} )

      ans = @hash2.select{|k,_| k == :two }
      expect( @ot.select{|k,v| k == :two } ).to eq( {two: 2} )

      ans = @hash2.reject{|k,_| k == :two }
      expect(  @ot.reject{|k,_| k == :two } ).to eq( ans )
    end

    it "behaves like a hash for a bunch of iterators" do

      expect( @ot.inject(0){|m,(k,v)| m += v.to_i } ).to eq 9

      expect{ @ot.each{|k,v| } }.not_to raise_exception
      ans = []; @ot.each{|k,_| ans << k}
      expect( ans ).to eq( @hash2.keys )

      ans = []; @ot.each_key{|k| ans << k}
      expect(ans).to eq( @hash2.keys )

      ans = []; @ot.each_value{|v| ans << v} 
      expect(ans).to eq( @hash2.values )
    end

  end


end

