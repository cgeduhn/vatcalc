require "spec_helper"

RSpec.describe Vatcalc::VATPercentage do
  let (:perc){Vatcalc::VATPercentage}
  it "will initialized correctly" do 
    #expect(Vatcalc.percentage.to_f).to eq(1.19)
    #expect(u.convert_to_percentage_value(1.19)).to eq(1.19)
    expect(perc.new(0.19).to_f).to eq(1.19)
    expect(perc.new(19).to_f).to eq(1.19)
    expect(perc.new(19.00).to_f).to eq(1.19)

    expect(perc.new(7).to_f).to eq(1.07)
    #expect(perc.new(1.07)).to eq(1.07)
    expect(perc.new(0.07).to_f).to eq(1.07)

    expect(perc.new(1).to_f).to eq(1.01)
    
    expect(perc.new(0).to_f).to eq(1.00)
    expect(perc.new(0.00).to_f).to eq(1.00)

    expect(Vatcalc.percentage.to_f).to eq(1.19)


    h = Hash.new
    h[perc.new(19)] = 1
    
    expect(h.has_key? perc.new(19)   ).to eq(true)
    expect(h.has_key? perc.new(0.19) ).to eq(true)
  end

  it "has same hashes" do 
    p1 = perc.new(0.19)
    p2 = perc.new(19)
    p3 = perc.new(7)
    p4 = perc.new(0.07)

    expect(p1).to eq(p2)
    expect(p3).to eq(p4)
    expect(p1).not_to eq(p4)

    h = {p1 => 1}
    expect(h.has_key?(p1)).to eq(true)
    expect(h.has_key?(p2)).to eq(true)
  end

  it "compares correctly" do
    s = perc.new(7)
    s1 = perc.new(7)
    b = perc.new(19)

    expect(s).not_to eq(b)
    expect(s).to eq(s1)
    expect(b).not_to eq(s1)

    expect(s).to eq(1.07)
    expect(s1).to eq(1.07)
    expect(b).to eq(1.19)

    expect(s).to eq(1.07)
    expect(s1).to eq(1.07)
    expect(b).to eq(1.19)
  end
end