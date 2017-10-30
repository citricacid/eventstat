
require_relative '../models/models'
require_relative '../settings'
ActiveRecord::Base.establish_connection(Settings::DBWEB)


describe Subcategory do
  context "associations" do
    subcat = Subcategory.find(12)
    it "simple name check" do
      expect(subcat.name).to eql("Lesesirkler")
    end
    it "with maintypes" do
      expect(subcat.maintype_associated?(8)).to be(false)
      expect(subcat.maintype_associated?(7)).to be(true)
    end
  end

  context "links" do
      subcat = Subcategory.find(44)
      dubcat = Subcategory.find(47)
      it "aggregated sub" do
        expect(subcat.aggregated_subcategory.id).to be(47)
        expect(dubcat.aggregated_subcategory).to be(nil)
      end

  end
end
