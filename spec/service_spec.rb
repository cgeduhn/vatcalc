require "spec_helper"

RSpec.describe Vatcalc::ServiceElement do 
  let (:s) {Vatcalc::ServiceElement}
  let (:b) {Vatcalc::Base.new}


  describe "with a simple base with VAT percentage of 19" do 
    let(:elem) {Vatcalc::BaseElement.new(10.00,percentage: 19)}
    let (:b) {Vatcalc::Base.new.insert(elem)}


    let (:s) {Vatcalc::ServiceElement.new(5.00,base: b)}

    it "has correctly net" do
      expect(s.net.to_f).to eq(4.2)
    end

    it "has correctly vat" do
      expect(s.vat.to_f).to eq(0.8)
    end

    it "has a correctly vat splitting" do
      expect(s.vat_splitted).to eq({Vatcalc::VATPercentage.new(19) => Money.euro(80)})
    end

  end

  describe "with a base with VAT percentage of 19 and 7" do 
    let(:elem1) {Vatcalc::BaseElement.new(10.00, percentage: 19, net: true)}
    let(:elem2) {Vatcalc::BaseElement.new(10.00, percentage:  7, net: true)}

    let (:b) {a = Vatcalc::Base.new.insert(elem1); a.insert(elem2)}

    let (:s) {Vatcalc::ServiceElement.new(5.00,base: b)}

    it "has correctly net" do
      expect(s.net).to eq(Money.euro(2.1*100 + 2.34*100))
    end

    it "has correctly vat" do
      expect(s.vat.to_f).to eq(0.56)
    end

    it "has correctly vat splitting" do
      expect(s.vat_splitted).to eq({
        Vatcalc::VATPercentage.new(19) => Money.euro(40),
        Vatcalc::VATPercentage.new(7) =>  Money.euro(16)
      })
    end

  end


  describe "with a base with VAT percentage of 19 and 7" do 
    let(:elem1) {Vatcalc::BaseElement.new(9.99, percentage: 19)}
    let(:elem2) {Vatcalc::BaseElement.new(9.99, percentage:  7)}
    let(:elem3) {Vatcalc::BaseElement.new(9.99, percentage:  0)}

    let (:b) {a = Vatcalc::Base.new.insert(elem1); a.insert(elem2); a.insert(elem3);}

    #9.99 / 1.19 = 8.39 # => 0.302669 5526695527 # =>   0.302667
    #9.99 / 1.07 = 9.34 # => 0.336940 83694083693 # =>  0.336941
    #9.99 / 1.00 = 9.99 # => 0.360389 6103896104 # =>   0.360390

    # => 27.72 net
    # => 02.25 vat
    # => 29.97 gross 


    #Coupon 10%
    let (:s) {Vatcalc::ServiceElement.new(-3.00,base: b)}

    let (:m) { Money.euro(-3*100).allocate([0.30267,0.336941,0.360389]) }

    let (:expected_net) {  m[0]/Vatcalc::VATPercentage.new(19) + m[1]/Vatcalc::VATPercentage.new(7) + m[2] }

    it "has correctly net" do
      expect(b.allocate(Money.euro(-3*100)).values).to eq(m)
      expect(s.net).to eq(expected_net)
    end

    # it "has correctly vat" do
    #   expect(s.vat.to_f).to eq(0.56)
    # end

    # it "has correctly vat splitting" do
    #   expect(s.vat_splitted).to eq({
    #     Vatcalc::VATPercentage.new(19) => Money.euro(40),
    #     Vatcalc::VATPercentage.new(7) =>  Money.euro(16)
    #   })
    # end

  end



end
