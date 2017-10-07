require "spec_helper"


RSpec.describe Vatcalc::Util do
  let (:h) {Vatcalc::Util::PercentageHash.new}
  let (:u){Vatcalc::Util}

  describe "converts" do 
    it "correctly to percentage" do 
      expect(u.convert_to_percentage_value(1.19)).to eq(1.19)
      expect(u.convert_to_percentage_value(0.19)).to eq(1.19)
      expect(u.convert_to_percentage_value(19)).to eq(1.19)

      expect(u.convert_to_percentage_value(7)).to eq(1.07)
      expect(u.convert_to_percentage_value(1.07)).to eq(1.07)
      expect(u.convert_to_percentage_value(0.07)).to eq(1.07)

      expect(u.convert_to_percentage_value(1)).to eq(1.01)
      
      expect(u.convert_to_percentage_value(0)).to eq(1.00)
      expect(u.convert_to_percentage_value(0.00)).to eq(1.00)
    end

    it "correctly to money" do 
      expect(u.convert_to_money(1.19)).to eq(Money.euro(119))
      expect(u.convert_to_money(100)).to eq(Money.euro(100))
      expect(u.convert_to_money(100.00)).to eq(Money.euro(100*100))

      m = Money.euro(1)
      expect(u.convert_to_money(m)).to eq(m)
    end

    it "calculates correctly net" do
      expect(Vatcalc.net_of(11.00).to_f).to eq(9.24)
    end

    it "calculates correctly net" do 
      expect(Vatcalc.vat_of(11.00).to_f).to eq(1.76)
    end
  end

  describe "::PercentageHash" do
    it "has access" do
      h[7] = 1
      expect(h.has_key? 7).to be(true)
      expect(h.has_key? 1.07).to be(true)
      expect(h.has_key? 0.07).to be(true)
    end
  end
end

RSpec.describe Vatcalc::BaseObject do
  it "has a version number" do
    expect(Vatcalc::VERSION).not_to be nil
  end



  describe "with amount of 100" do 
    Vatcalc.vat_percentage = 1.19
    it "has correct values with standard vat percentage" do
      obj = Vatcalc::BaseObject.new(value: 100.00)
      expect(obj.net.to_f).to eq(84.03) 
      expect(obj.vat.to_f).to eq(15.97) 
    end

    it "has correct values with 7 percent" do 
      obj = Vatcalc::BaseObject.new(amount: 100.00,percentage: 7)
      expect(obj.net.to_f).to eq(93.46) 
      expect(obj.vat.to_f).to eq(6.54) 
    end

    it "has correct values with 0 percent" do 
      obj = Vatcalc::BaseObject.new(gross: 100.00,percentage: 0)
      expect(obj.net.to_f).to eq(100.00) 
      expect(obj.vat.to_f).to eq(0.00) 
    end
  end

  describe "with amount of 45.45" do 
    Vatcalc.vat_percentage = 1.19
    it "has correct values with standard vat percentage" do
      obj = Vatcalc::BaseObject.new(value: 45.45)
      expect(obj.net.to_f).to eq(38.19) 
      expect(obj.vat.to_f).to eq(7.26) 
    end

    it "has correct values with 7 percent" do 
      obj = Vatcalc::BaseObject.new(amount: 45.45,percentage: 7)
      expect(obj.net.to_f).to eq(42.48) 
      expect(obj.vat.to_f).to eq(2.97) 
    end

    it "has correct values with 0 percent" do 
      obj = Vatcalc::BaseObject.new(gross: 45.45,percentage: 0)
      expect(obj.net.to_f).to eq(45.45) 
      expect(obj.vat.to_f).to eq(0.00) 
    end
  end

  describe "add two base objects" do 

    it "calculates correctly the sum" do 
      obj1 = Vatcalc::BaseObject.new(gross: 50.45,percentage: 0)
      obj2 = Vatcalc::BaseObject.new(gross: 45.45,percentage: 0)

      result = Vatcalc::Base.new << obj1 << obj2


      expect(result.gross.to_f).to eq(95.90)
      expect(result.net.to_f).to eq(95.90)
      expect(result.vat.to_f).to eq(0)


      obj1 = Vatcalc::BaseObject.new(gross: 47.47,percentage: 7)
      obj2 = Vatcalc::BaseObject.new(gross: 45.45,percentage: 7)

      result = Vatcalc::Base.new << obj1 << obj2

      expect(result.gross.to_f).to eq(92.92)
      expect(result.net.to_f).to eq(86.84)
      expect(result.vat.to_f).to eq(6.08)

    end

  end


end


RSpec.describe Vatcalc::Base do
  let (:b) {Vatcalc::Base.new}
  it "inserts anything correctly" do
    b << ([100.00, 7])
    expect(b.collection.length).to eq(1)

    b << ([100])
    expect(b.collection.length).to eq(2)

    expect(b.gross.to_f).to eq(101.00)

    b << {percentage: 19.00,value: 100.00}

    expect(b.gross.to_f).to eq(201.00)
    expect(b.net.to_f).to eq(178.33)
    expect(b.vat.to_f).to eq((201.00 - 178.33).round(2))
    expect(b.percentages.length).to eq(2)
  end


  it "has correctly rates if net is 0" do
    b << [0,0.00]
    expect(b.collection.first.percentage).to eq(1.00)
    expect(b.percentages).to eq([1.00])
    expect(b.rates).to eq({1.00 => 1.00})
  end

  it "has correctly rates" do
    r = Proc.new{|it| rand * (rand*100)}
    1000.times do |i|
      b = Vatcalc::Base.new
      b << [r.call,0.00]
      b << [r.call,19]
      b << [r.call,7]
      vs = b.rates.values.collect{|s| (s*100).round(2)}
      rounded_sum = vs.inject(0){|s,i| s+=i}.round(4)
      #p "---#{b.human_rates}"
      p "#{b.rates}"
      expect(rounded_sum).to eq(100)
    end


  end
end



