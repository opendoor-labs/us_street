require 'spec_helper'

describe UsStreet do
  describe ".from_attrs" do
    it "builds a normalized street address" do
      us_street = UsStreet.from_attrs(11421, "W", "LAURELWOOD", "Lane", nil)
      expect(us_street.full_street).to eq("11421 W Laurelwood Ln")
    end

    it "removes unknown directions" do
      us_street = UsStreet.from_attrs(11421, "WFS", "LAURELWOOD", "Lane", nil)
      expect(us_street.full_street).to eq("11421 Laurelwood Ln")
    end

    it "simplifies known directions" do
      us_street = UsStreet.from_attrs(11421, "NorthWesT", "LAURELWOOD", "Lane", "SE")
      expect(us_street.full_street).to eq("11421 NW Laurelwood Ln SE")
    end

    it "checks for Saint & Doctor such-n'-such streets" do
      us_street = UsStreet.from_attrs(11421, nil, "ST. JOHN", "Road", nil)
      expect(us_street.full_street).to eq("11421 St John Rd")
      us_street = UsStreet.from_attrs(11421, nil, "saInT John", "Road", nil)
      expect(us_street.full_street).to eq("11421 St John Rd")

      us_street = UsStreet.from_attrs(11421, nil, "DR JOHN", "Road", nil)
      expect(us_street.full_street).to eq("11421 Dr John Rd")
      us_street = UsStreet.from_attrs(11421, nil, "Doctor John", "Road", nil)
      expect(us_street.full_street).to eq("11421 Dr John Rd")
    end

    it "removes stuff in parens" do
      us_street = UsStreet.from_attrs(11421, "WFS", "LAURELWOOD (NOT HERE)", "Lane", nil)
      expect(us_street.full_street).to eq("11421 Laurelwood Ln")
    end

    it "strips off unrequired characters" do
      us_street = UsStreet.from_attrs(123, nil, "N. main, -southy", nil, nil)
      expect(us_street.full_street).to eq("123 N Main Southy")
    end

    it "strips off spaces" do
      us_street = UsStreet.from_attrs("  123", nil, "N. main, -southy  ", nil, nil)
      expect(us_street.full_street).to eq("123 N Main Southy")
    end

    context 'with weird data' do
      it 'checks for double entry of directional prefix' do
        us_street = UsStreet.from_attrs("  123", 'North', "N 12th St", nil, nil)
        expect(us_street.full_street).to eq('123 N 12th St')
      end

      it 'checks for double entry of street suffix' do
        us_street = UsStreet.from_attrs("  123", nil, "N 12th St", 'Street', nil)
        expect(us_street.full_street).to eq('123 N 12th St')
      end

      it 'checks for double entry of directional suffix' do
        us_street = UsStreet.from_attrs("  123", nil, "12th Street West", 'st', 'W')
        expect(us_street.full_street).to eq('123 12th St W')
      end

      it 'handles all the suffixen and prefixen' do
        us_street = UsStreet.from_attrs("  123", 'S', "South 12th St East", 'Street', 'E')
        expect(us_street.full_street).to eq('123 S 12th St E')
      end

      it 'reads the directional prefix from the street when not passed in' do
        us_street = UsStreet.from_attrs("  123", nil, 'southwest 12th St', nil, nil)
        expect(us_street.full_street).to eq('123 SW 12th St')
      end

      it 'reads the street suffix from the street when not passed in' do
        us_street = UsStreet.from_attrs("  123", nil, "12th Street", nil, nil)
        expect(us_street.full_street).to eq('123 12th St')
      end

      it 'reads the directional suffix from the street when not passed in' do
        us_street = UsStreet.from_attrs("  123", nil, "12th North", 'Street', nil)
        expect(us_street.full_street).to eq('123 12th St N')
      end

      it 'prefers what is passed in' do
        us_street = UsStreet.from_attrs("  123", 'S', "North 12th St WEST", 'Street', 'E')
        expect(us_street.full_street).to eq('123 S 12th St E')
      end

      # yes this is a real address: 2644 E North Ln, Phoenix, AZ 85028
      it "doesn't strip North if it's the full street name" do
        us_street = UsStreet.from_attrs("2644", "E", "North", "Ln", nil)
        expect(us_street.full_street).to eq("2644 E North Ln")
      end
    end
  end

  describe '.parse' do
    it "builds a normalized street address" do
      us_street = UsStreet.parse("11421 W LAURELWOOD Lane")
      expect(us_street.full_street).to eq("11421 W Laurelwood Ln")
    end

    it "removes unknown directions" do
      us_street = UsStreet.parse("11421   LAURELWOOD Lane", dir_prefix: 'WFS')
      expect(us_street.full_street).to eq("11421 Laurelwood Ln")
    end

    it "simplifies known directions" do
      us_street = UsStreet.parse("11421 NorthWesT LAURELWOOD Lane SE")
      expect(us_street.full_street).to eq("11421 NW Laurelwood Ln SE")
    end

    it "checks for Saint & Doctor such-n'-such streets" do
      us_street = UsStreet.parse("11421 ST. JOHN Road")
      expect(us_street.full_street).to eq("11421 St John Rd")
      us_street = UsStreet.parse("11421 saInT John Road")
      expect(us_street.full_street).to eq("11421 St John Rd")

      us_street = UsStreet.parse("11421 DR JOHN Road")
      expect(us_street.full_street).to eq("11421 Dr John Rd")
      us_street = UsStreet.parse("11421 Doctor John Road")
      expect(us_street.full_street).to eq("11421 Dr John Rd")
    end

    it "removes stuff in parens" do
      us_street = UsStreet.parse("11421 LAURELWOOD (NOT HERE) Lane")
      expect(us_street.full_street).to eq("11421 Laurelwood Ln")
    end

    it "strips off unrequired characters" do
      us_street = UsStreet.parse("123 N. main, -southy")
      expect(us_street.full_street).to eq("123 N Main Southy")
    end

    it "doesn't strip directions in street name" do
      us_street = UsStreet.parse("2644 E North Ln")
      expect(us_street.full_street).to eq("2644 E North Ln")
    end

    it "strips off spaces" do
      us_street = UsStreet.parse("  123 N    main   southy  ")
      expect(us_street.full_street).to eq("123 N Main Southy")
    end

    it 'prefers an explicit dir_prefix' do
      us_street = UsStreet.parse("123 S main southy", dir_prefix: "n")
      expect(us_street.dir_prefix).to eq('N')
      expect(us_street.full_street).to eq("123 N Main Southy")
    end

    it 'prefers an explicit dir_suffix' do
      us_street = UsStreet.parse("123 main southy W", dir_suffix: "n")
      expect(us_street.dir_suffix).to eq('N')
      expect(us_street.full_street).to eq("123 Main Southy N")
    end

    it 'prefers an explicit street_suffix' do
      us_street = UsStreet.parse("123 main southy road", street_suffix: "st")
      expect(us_street.street_suffix).to eq('St')
      # we can't strip Road here, it may be part of the street name in fact.
      expect(us_street.full_street).to eq("123 Main Southy Road St")
    end

    it 'handles unit numbers' do
      us_street = UsStreet.parse('123 123rd st #15')
      expect(us_street.unit).to eq('15')
      expect(us_street.full_street).to eq('123 123rd St')
      expect(us_street.display).to eq('123 123rd St #15')
    end

    it 'handles alpha unit numbers' do
      us_street = UsStreet.parse('123 123rd st #C')
      expect(us_street.unit).to eq('C')
      expect(us_street.full_street).to eq('123 123rd St')
      expect(us_street.display).to eq('123 123rd St #C')
    end

    it 'handles alpha unit numbers' do
      us_street = UsStreet.parse('123 123rd st', unit: 'C')
      expect(us_street.unit).to eq('C')
      expect(us_street.full_street).to eq('123 123rd St')
      expect(us_street.display).to eq('123 123rd St #C')
    end

    it 'handles 123rd st without ordinals or street number' do
      us_street = UsStreet.parse('123 st')
      expect(us_street.street_number).to eq(nil)
      expect(us_street.street_name).to eq('123rd')
      expect(us_street.full_street).to eq('123rd St')
    end

    it 'handles non ordinalized street names' do
      us_street = UsStreet.parse('13 1 st #14')
      expect(us_street.street_number).to eq('13')
      expect(us_street.unit).to eq('14')
      expect(us_street.street_name).to eq('1st')
      expect(us_street.full_street).to eq('13 1st St')
      expect(us_street.display).to eq('13 1st St #14')
    end

    it 'handles overrides with string keys' do
      us_street = UsStreet.parse('123 Fake st', "unit" => 12)
      expect(us_street.unit).to eq('12')
    end

    it 'handles units containing #' do
      us_street = UsStreet.parse('123 Fake st', "unit" => "#12")
      expect(us_street.unit).to eq('12')
    end

    it 'handles country roads' do
      street1 = UsStreet.parse('1455 Indian Rte 9500')
      street2 = UsStreet.parse('1455 Country Road 2085')

      expect(street1.full_street).to eq('1455 Indian Rte 9500')
      expect(street1.street_number).to eq('1455')
      expect(street1.street_name).to eq('Indian')
      expect(street1.road_number).to eq('9500')
      expect(street1.street_suffix).to eq('Rte')
      expect(street1.unit).to be_nil

      expect(street2.full_street).to eq('1455 Co Rd 2085')
      expect(street2.street_number).to eq('1455')
      expect(street2.street_name).to eq('Co')
      expect(street2.road_number).to eq('2085')
      expect(street2.street_suffix).to eq('Rd')
      expect(street2.unit).to be_nil
    end

    it 'handles country roads with units' do
      street = UsStreet.parse('1455 Country Road 2085 #12')
      expect(street.full_street).to eq('1455 Co Rd 2085')
      expect(street.street_number).to eq('1455')
      expect(street.street_name).to eq('Co')
      expect(street.road_number).to eq('2085')
      expect(street.street_suffix).to eq('Rd')
      expect(street.unit).to eq('12')
    end

    it 'doesnt strip street when overrides are present' do
      street = UsStreet.parse("PALM BEACH", {:street_number=>"20127", :dir_prefix=>"E", :street_suffix=>"Drive"})
      expect(street.full_street).to eq('20127 E Palm Beach Dr')
      expect(street.street_number).to eq('20127')
      expect(street.street_name).to eq('Palm Beach')
      expect(street.street_suffix).to eq('Dr')
    end
  end
end
