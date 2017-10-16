require "spec_helper"


class TestArticle

  include Vatcalc::ActsAsBillElement

  attr_reader :price, :vat_percentage, :net, :currency
  def initialize(price: ,vat_percentage: Vatcalc.vat_percentage, net: false, currency: "EUR")
    @price = price
    @vat_percentage = vat_percentage
    @net = net
    @currency = (currency || "EUR")
  end

  acts_as_bill_element(amount: :price, vat_percentage: :vat_percentage, currency: :currency, prefix: :bill, net: :net)
end


class TestFee
  include Vatcalc::ActsAsBillElement

  attr_reader :price,:net,:currency
  def initialize(price: ,net: false, currency: "EUR")
    @price = price
    @net = net
    @currency = (currency || "EUR")
  end

  acts_as_bill_element(amount: :price, service: true, currency: :currency, prefix: :bill, net: :net)
end


RSpec.describe Vatcalc::Bill do

  let(:tolerance) { Vatcalc::Bill::Tolerance }
  let(:round_precision) { Vatcalc::Bill::RoundPrecision }



  describe "containing only base elements" do

    let (:b) {
      Vatcalc::Bill.new(elements: [
        TestArticle.new(price: 100.00,vat_percentage: 7),
        TestArticle.new(price: 100),
        TestArticle.new(price: 100.00,vat_percentage: "19")
      ])
    }

    it "inserted items correctly" do
      expect(b.gross.to_f).to eq(201.00)
      expect(b.net.to_f).to eq(178.33)
      expect(b.vat.to_f).to eq((201.00 - 178.33).round(2))
      expect(b.percentages.length).to eq(2)
    end

    it "has correct items" do 
      expect(b.elements.length).to eq(3)
      expect(b.base_elements.length).to eq(3)
      expect(b.service_elements.length).to eq(0)
    end

    it "has correct rates" do
      expect(b.rates.length).to eq(2)
      expect(b.rates.values.sort).to eq([0.4759,0.5241])
      d = (b.rates.values.sum.round(round_precision))
      expect(1.00 - d).to be <= tolerance
    end
  end

  describe "containing 2 elements with no vat percentage" do
    let (:b) {
      Vatcalc::Bill.new(elements: [
        TestArticle.new(price: 50.45, vat_percentage: 0),
        TestArticle.new(price: 45.45, vat_percentage: 0),
      ])
    }
    it "calculates correctly the sum" do 
      expect(b.gross.to_f).to eq(95.90)
      expect(b.net.to_f).to eq(95.90)
      expect(b.vat.to_f).to eq(0)
      expect(b.rates.values).to eq([1.00])
      expect(b.rates.keys.collect(&:to_f)).to eq([1.00])
    end
  end

  describe "containing 2 elements with vat percentage of 7" do
    let(:obj1) { TestArticle.new(price: 47.47,vat_percentage: 7) }
    let(:obj2) { TestArticle.new(price: 45.45,vat_percentage: 7) }

    let(:b) { Vatcalc::Bill.new(elements: [[obj1,1],[obj2,1]]) }

    it "calculates correctly the sum" do 
      expect(b.gross.to_f).to eq(92.92)
      expect(b.net.to_f).to eq(86.84)
      expect(b.vat.to_f).to eq(6.08)
    end
  end

  describe "calculating random rates" do

    it "has correctly rates" do
      r = Proc.new{|it| rand(100000).to_f * (rand*100)}
      100.times do |i|
        obj1 = [TestArticle.new(price: r.call,vat_percentage: 0.00),2]
        obj2 = [TestArticle.new(price: r.call,vat_percentage: 7.00),2]
        obj3 = [TestArticle.new(price: r.call,vat_percentage: 19.00),2]
        b = Vatcalc::Bill.new(elements: [obj1,obj2,obj3])
        d = (b.rates.values.sum.to_d(Vatcalc::Bill::RoundPrecision))
        expect(1.00 - d).to be <= (Vatcalc::Bill::Tolerance)
      end
    end
  end


  describe "containing base elements and service_elements" do

    let(:elem1) {TestArticle.new(price: 10.00, vat_percentage: 19, net: true)}
    let(:elem2) {TestArticle.new(price: 10.00, vat_percentage:  "7%", net: true)}

    let (:s) { TestFee.new(price: 5.00) }
    let(:b) { Vatcalc::Bill.new(elements: [elem1,elem2,s]) }

    let(:s_net) { Money.new((2.5/1.19)*100,Vatcalc.currency) + Money.new(100*(2.5/1.07),Vatcalc.currency) }


    it "has correctly gross" do
      expect(b.service_elements.length).to eq(1)
      expect(b.gross.to_f).to eq(27.60)
    end

    it "has correctly net" do
      expect(b.net).to eq(s_net + (2 * Money.new(10 * 100,Vatcalc.currency)))
    end

    it "has correctly vat" do
      expect(b.vat.to_f).to eq( (Money.new(56,Vatcalc.currency) + Money.new(1.9 * 100,Vatcalc.currency) + Money.new(0.70 * 100,Vatcalc.currency)).to_f )
    end

    it "has correctly vat splitting" do

      expect(b.vat_splitted).to eq({
        Vatcalc::VATPercentage.new(19) => elem1.bill_vat + Money.new(40,Vatcalc.currency),
        Vatcalc::VATPercentage.new(7) =>  elem2.bill_vat + Money.new(16,Vatcalc.currency),
      })


      expect(s.bill_vat_splitted).to eq({
        Vatcalc::VATPercentage.new(19) => Money.new(40,Vatcalc.currency),
        Vatcalc::VATPercentage.new(7) =>  Money.new(16,Vatcalc.currency)
      })
    end


  end


  describe "with a base with VAT percentage of 19 and 7 and a coupon " do 
    let(:elem1) {TestArticle.new(price: 9.99, vat_percentage: 19)}
    let(:elem2) {TestArticle.new(price: 9.99, vat_percentage:  7)}
    let(:elem3) {TestArticle.new(price: 9.99, vat_percentage:  0)}

    let (:s) {TestFee.new(price: -3.00)}

    let (:b) { Vatcalc::Bill.new(elements: [elem1,elem2,elem3,[s,2]]) }

    #9.99 / 1.19 = 8.39 # => 0.3026 6 95526695527 # =>   0.3027
    #9.99 / 1.07 = 9.34 # => 0.3369 4 083694083693 # =>  0.3369
    #9.99 / 1.00 = 9.99 # => 0.3603 8 96103896104 # =>   0.3604

    # => 27.72 net
    # => 02.25 vat
    # => 29.97 gross 


    #Coupon 10%

    let (:m) { Money.new(-3*100,Vatcalc.currency).allocate([0.3027,0.3369,0.3604]) }

    let (:expected_net) {  m[0]/Vatcalc::VATPercentage.new(19) + m[1]/Vatcalc::VATPercentage.new(7) + m[2] }

    it "has correctly net" do
      expect(b.gross.to_f).to eq(23.97)
      expect(b.net.to_f).to eq((2*expected_net + Money.new(27.72*100,Vatcalc.currency)).to_f)

      

      #{"19%"=>"30.27%", "7%"=>"33.69%", "0%"=>"36.04%"}
      expect(s.bill_net).to eq(expected_net)
    end

    it "has correctly net" do
      bill = Vatcalc::Bill.new

      bill.insert s 

      bill.insert([elem1,elem2,elem3])
      

      expect(s.bill_net).to eq(expected_net)

      expect(bill.gross.to_f).to eq(26.97)
      expect(bill.net.to_f).to eq((expected_net + Money.new(27.72*100,Vatcalc.currency)).to_f)
      
      
    end
  end


  describe "with a simple base with VAT percentage of 19" do 
    let(:elem) {TestArticle.new(price: 10.00,vat_percentage: 19)}

    let (:s) {TestFee.new(price: 5.00)}

    let (:b) {Vatcalc::Bill.new(elements: [elem,s])}


    it "has correctly net" do
      b.rates
      expect(s.bill_net.to_f).to eq(4.2)
    end

    it "has correctly vat" do
      b.rates
      expect(s.bill_vat.to_f).to eq(0.8)
    end

    it "has a correctly vat splitting" do
      b.rates
      expect(s.bill_vat_splitted).to eq({Vatcalc::VATPercentage.new(19) => Money.new(80,Vatcalc.currency)})
    end

  end



  describe "with a simple base with VAT percentage of 19 and USD" do 
    let (:elements) {
      [
        TestArticle.new(price: 10.00,vat_percentage: 19,currency: "USD"),
        TestFee.new(price: 5.00,currency: "USD")
      ]  
    }
    let (:b) {Vatcalc::Bill.new(elements: elements)}

    let (:s) {b.service_elements.last.first}

    it "has correctly currency" do
      expect(b.currency).to eq("USD")
    end

    it "has correctly net" do
      b.rates
      expect(s.net.to_f).to eq(4.2)
    end

    it "has correctly vat" do
      b.rates
      expect(s.vat.to_f).to eq(0.8)
    end

    it "has a correctly vat splitting" do
      b.rates
      expect(s.vat_splitted).to eq({Vatcalc::VATPercentage.new(19) => Money.usd(80)})
    end

  end


end










