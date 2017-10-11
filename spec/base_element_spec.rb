require "spec_helper"

RSpec.describe Vatcalc::BaseElement do

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



end