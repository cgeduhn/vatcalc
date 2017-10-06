require "spec_helper"

RSpec.describe Vatcalc do
  it "has a version number" do
    expect(Vatcalc::VERSION).not_to be nil
  end

  describe "converts" do 
    let (:u){Vatcalc::Util}
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


  describe "base_object with amount of 100" do 
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

  describe "base_object with amount of 45.45" do 
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


end
