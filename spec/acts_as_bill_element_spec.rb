require "spec_helper"



class ArticleTestClass1

  include Vatcalc::ActsAsBillElement

  attr_reader :price, :vat_percentage
  def initialize(price: ,vat_percentage: Vatcalc.vat_percentage)
    @price = price
    @vat_percentage = vat_percentage
  end

  acts_as_bill_element(amount: :price, vat_percentage: :vat_percentage, currency: "EUR", prefix: :bill)

end


class ArticleTestClass2

  include Vatcalc::ActsAsBillElement

  attr_reader :price, :vat_percentage
  def initialize(price: ,vat_percentage: Vatcalc.vat_percentage)
    @price = price
    @vat_percentage = vat_percentage
  end

  acts_as_bill_element(amount: :price,net: true, vat_percentage: :vat_percentage, currency: "EUR", prefix: :bill)

end


class CouponTestClass
  include Vatcalc::ActsAsBillElement

  attr_reader :price, :vat_percentage
  def initialize(price: )
    @price = price
  end

  acts_as_bill_element(amount: ->(obj){ -obj.price }, service: true, net: true, currency: "EUR", prefix: :bill)
end

RSpec.describe Vatcalc::ActsAsBillElement do

  describe "an Article with acts_as_bill_element and a price of 10 Euro" do
    let (:a) { ArticleTestClass1.new(price: 10.00,vat_percentage: "19%") }

    it "acts as base element" do 
      expect(Vatcalc.acts_as_bill_element?.call(a)).to eq(true)
    end

    it "has a bill element" do
      expect(a.as_vatcalc_bill_element.class).to eq(Vatcalc::BaseElement)
    end

    it "calculates gross vat net correctly" do
      expect(a.bill_gross.to_f).to eq(10.00)
      expect(a.bill_net.to_f).to eq(8.40)
      expect(a.bill_vat.to_f).to eq(1.60)
    end

    it "has a vat_percentage object" do
      expect(a.bill_vat_percentage).to eq(Vatcalc::VATPercentage.new(19))
    end
  end


  describe "an Article with acts_as_bill_element and a net price of 10 Euro" do
    let (:a) { ArticleTestClass2.new(price: 10.00,vat_percentage: "19%") }

    it "acts as bill element" do 
      expect(Vatcalc.acts_as_bill_element?.call(a)).to eq(true)
    end

    it "has a base element" do
      expect(a.as_vatcalc_bill_element.class).to eq(Vatcalc::BaseElement)
    end

    it "calculates gross vat net correctly" do
      expect(a.bill_gross.to_f).to eq(11.90)
      expect(a.bill_net.to_f).to eq(10.00)
      expect(a.bill_vat.to_f).to eq(1.90)
    end

    it "has a vat_percentage object" do
      expect(a.bill_vat_percentage).to eq(Vatcalc::VATPercentage.new(19))
    end
  end


  describe "an Coupon with acts_as_bill_element and a net price of 10 Euro" do
    let (:a) do 
      c = CouponTestClass.new(price: 10.00) 
      c.as_vatcalc_bill_element.change_rates({"19%" => 0.5, "7%" => 0.5})
      c
    end

    it "acts as bill element" do 
      expect(Vatcalc.acts_as_bill_element?.call(a)).to eq(true)
    end

    it "has a service element" do
      expect(a.as_vatcalc_bill_element.class).to eq(Vatcalc::ServiceElement)
    end

    it "calculates gross vat net correctly" do
      expect(a.bill_gross.to_f).to eq(-11.3)
      expect(a.bill_net.to_f).to eq(-10.00)
      expect(a.bill_vat.to_f).to eq(-1.30)
    end

  end





end