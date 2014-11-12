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
      expect(us_street.full_street).to eq("123 Main Southy St")
    end

    it 'handles unit numbers' do
      us_street = UsStreet.parse('123 123rd st #15')
      expect(us_street.unit).to eq('15')
      expect(us_street.full_street).to eq('123 123rd St')
      expect(us_street.display).to eq('123 123rd St #15')
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
  end
end
