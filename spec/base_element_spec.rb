require "spec_helper"

RSpec.describe Vatcalc::BaseElement do
  it "has a version number" do
    expect(Vatcalc::VERSION).not_to be nil
  end



  describe "with amount of 100" do 
    
    it "has correct values with standard vat percentage" do
      obj = Vatcalc::BaseElement.new(100.00)
      expect(obj.net.to_f).to eq(84.03) 
      expect(obj.vat.to_f).to eq(15.97) 

      obj = Vatcalc::BaseElement.new(100.00,net: true)
      expect(obj.net.to_f).to eq(100.00) 
      expect(obj.vat.to_f).to eq(19.00) 
    end

    it "has correct values with 7 percent" do 
      obj = Vatcalc::BaseElement.new(100.00,percentage: 7)
      expect(obj.net.to_f).to eq(93.46) 
      expect(obj.vat.to_f).to eq(6.54) 

      obj = Vatcalc::BaseElement.new(100.00,net: true,percentage: 7)
      expect(obj.net.to_f).to eq(100.00) 
      expect(obj.vat.to_f).to eq(7.00) 
    end

    it "has correct values with 0 percent" do 
      obj = Vatcalc::BaseElement.new(100.00,percentage: 0)
      expect(obj.net.to_f).to eq(100.00) 
      expect(obj.vat.to_f).to eq(0.00) 


      obj = Vatcalc::BaseElement.new(100.00,net: true,percentage: 0)
      expect(obj.net.to_f).to eq(100.00) 
      expect(obj.vat.to_f).to eq(0.00) 
    end
  end

  describe "with amount of 45.45" do 
    
    it "has correct values with standard vat percentage" do
      obj = Vatcalc::BaseElement.new(45.45)
      expect(obj.net.to_f).to eq(38.19) 
      expect(obj.vat.to_f).to eq(7.26) 
    end

    it "has correct values with 7 percent" do 
      obj = Vatcalc::BaseElement.new(45.45,percentage: 7)
      expect(obj.net.to_f).to eq(42.48) 
      expect(obj.vat.to_f).to eq(2.97) 
    end

    it "has correct values with 0 percent" do 
      obj = Vatcalc::BaseElement.new(45.45,percentage: 0)
      expect(obj.net.to_f).to eq(45.45) 
      expect(obj.vat.to_f).to eq(0.00) 
    end
  end

  describe "add two base objects" do 

    it "calculates correctly the sum" do 
      obj1 = Vatcalc::BaseElement.new(50.45,percentage: 0)
      obj2 = Vatcalc::BaseElement.new(45.45,percentage: 0)

      result = Vatcalc::Base.new << obj1 << obj2


      expect(result.gross.to_f).to eq(95.90)
      expect(result.net.to_f).to eq(95.90)
      expect(result.vat.to_f).to eq(0)


      obj1 = Vatcalc::BaseElement.new(47.47,percentage: 7)
      obj2 = Vatcalc::BaseElement.new(45.45,percentage: 7)

      result = Vatcalc::Base.new << obj1 << obj2

      expect(result.gross.to_f).to eq(92.92)
      expect(result.net.to_f).to eq(86.84)
      expect(result.vat.to_f).to eq(6.08)
    end

  end


end