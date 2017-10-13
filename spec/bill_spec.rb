require "spec_helper"

RSpec.describe Vatcalc::Bill do

  let(:tolerance) { Vatcalc::Bill::Tolerance }
  let(:round_precision) { Vatcalc::Bill::RoundPrecision }



  describe "containing only base elements" do

    let (:b) {
      Vatcalc::Bill.new(base: [
        {amount: 100.00,vat_percentage: 7},
        100,
        {percentage: 19.00,value: 100.00}
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
      Vatcalc::Bill.new(base: [
        {amount: 50.45,vat_percentage: 0},
        {percentage: 0,value: 45.45}
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
    let(:obj1) { Vatcalc::BaseElement.new(47.47,percentage: 7) }
    let(:obj2) { Vatcalc::BaseElement.new(45.45,percentage: 7) }

    let(:b) { Vatcalc::Bill.new(base: [[obj1,1],[obj2,1]]) }

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
        b = Vatcalc::Bill.new(base: [
          {value: r.call,vat_percentage: 0.00, quantity: 2},
          {value: r.call,vat_percentage: 7, quantity: 2},
          {value: r.call,vat_percentage: 19,   quantity: 2}
        ])
        d = (b.rates.values.sum.to_d(Vatcalc::Bill::RoundPrecision))
        expect(1.00 - d).to be <= (Vatcalc::Bill::Tolerance)
      end
    end
  end


  describe "containing base elements and service_elements" do

    let(:elem1) {Vatcalc::BaseElement.new(10.00, percentage: 19, net: true)}
    let(:elem2) {Vatcalc::BaseElement.new(10.00, percentage:  "7%", net: true)}

    let (:s) { Vatcalc::ServiceElement.new(5.00) }
    let(:b) { Vatcalc::Bill.new(base: [elem1,elem2], services: [s]) }

    let(:s_net) { Money.euro((2.5/1.19)*100) + Money.euro(100*(2.5/1.07)) }


    it "has correctly gross" do
      expect(b.service_elements.length).to eq(1)
      expect(b.gross.to_f).to eq(27.60)
    end

    it "has correctly net" do
      expect(b.net).to eq(s_net + (2 * Money.euro(10 * 100)))
    end

    it "has correctly vat" do
      expect(b.vat.to_f).to eq( (Money.euro(56) + Money.euro(1.9 * 100) + Money.euro(0.70 * 100)).to_f )
    end

    it "has correctly vat splitting" do

      expect(b.vat_splitted).to eq({
        Vatcalc::VATPercentage.new(19) => elem1.vat + Money.euro(40),
        Vatcalc::VATPercentage.new(7) =>  elem2.vat + Money.euro(16),
      })


      expect(s.vat_splitted).to eq({
        Vatcalc::VATPercentage.new(19) => Money.euro(40),
        Vatcalc::VATPercentage.new(7) =>  Money.euro(16)
      })
    end


  end


  describe "with a base with VAT percentage of 19 and 7 and a coupon " do 
    let(:elem1) {Vatcalc::BaseElement.new(9.99, percentage: 19)}
    let(:elem2) {Vatcalc::BaseElement.new(9.99, percentage:  7)}
    let(:elem3) {Vatcalc::BaseElement.new(9.99, percentage:  0)}

    let (:s) {Vatcalc::ServiceElement.new(-3.00)}

    let (:b) { Vatcalc::Bill.new(base: [elem1,elem2,elem3], services: s) }

    #9.99 / 1.19 = 8.39 # => 0.3026 6 95526695527 # =>   0.3027
    #9.99 / 1.07 = 9.34 # => 0.3369 4 083694083693 # =>  0.3369
    #9.99 / 1.00 = 9.99 # => 0.3603 8 96103896104 # =>   0.3604

    # => 27.72 net
    # => 02.25 vat
    # => 29.97 gross 


    #Coupon 10%

    let (:m) { Money.euro(-3*100).allocate([0.3027,0.3369,0.3604]) }

    let (:expected_net) {  m[0]/Vatcalc::VATPercentage.new(19) + m[1]/Vatcalc::VATPercentage.new(7) + m[2] }

    it "has correctly net" do
      expect(b.gross.to_f).to eq(26.97)
      expect(b.net.to_f).to eq((expected_net + Money.euro(27.72*100)).to_f)

      

      #{"19%"=>"30.27%", "7%"=>"33.69%", "0%"=>"36.04%"}
      expect(s.net).to eq(expected_net)
    end

    it "has correctly net" do
      bill = Vatcalc::Bill.new

      service = Vatcalc::ServiceElement.new(-3.00)

      bill.insert_service_element(service)



      bill.insert_base_element([elem1,elem2,elem3])
      

      expect(service.net).to eq(expected_net)

      expect(bill.gross.to_f).to eq(26.97)
      expect(bill.net.to_f).to eq((expected_net + Money.euro(27.72*100)).to_f)
      
      
    end
  end


  describe "with a simple base with VAT percentage of 19" do 
    let(:elem) {Vatcalc::BaseElement.new(10.00,percentage: 19)}

    let (:s) {Vatcalc::ServiceElement.new(5.00)}

    let (:b) {Vatcalc::Bill.new(base: elem,services: s)}


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
      expect(s.vat_splitted).to eq({Vatcalc::VATPercentage.new(19) => Money.euro(80)})
    end

  end



  describe "with a simple base with VAT percentage of 19 and USD" do 
    let (:b) {Vatcalc::Bill.new(currency: "USD", base: {amount: 10.00, percentage: 19}, services: {amount: 5.00}, )}

    let (:s) {b.service_elements.last.last}

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



  # let (:s) {Vatcalc::ServiceElement}
  # let (:b) {Vatcalc::Base.new}


  # describe "with a simple base with VAT percentage of 19" do 
  #   let(:elem) {Vatcalc::BaseElement.new(10.00,percentage: 19)}
  #   let (:b) {Vatcalc::Base.new.insert(elem)}


  #   let (:s) {Vatcalc::ServiceElement.new(5.00,b.rates)}

  #   it "has correctly net" do
  #     expect(s.net.to_f).to eq(4.2)
  #   end

  #   it "has correctly vat" do
  #     expect(s.vat.to_f).to eq(0.8)
  #   end

  #   it "has a correctly vat splitting" do
  #     expect(s.vat_splitted).to eq({Vatcalc::VATPercentage.new(19) => Money.euro(80)})
  #   end

  # end









