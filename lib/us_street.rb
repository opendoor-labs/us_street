require "us_street/version"
require 'yaml'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/try'
require 'active_support/inflector/inflections'
require 'active_support/core_ext/integer/inflections'

class UsStreet
  COMPONENTS = [:unit, :street_number, :dir_prefix, :street_name, :street_suffix, :dir_suffix, :road_number].freeze

  f = File.expand_path('data/street_suffix_mapping.yml', __dir__)
  ROAD_SUFFIXES = YAML.load(File.read(f))

  DIRECTIONAL_MAPPINGS = {
    "n" => "n",
    "e" => "e",
    "s" => "s",
    "w" => "w",
    "north" => "n",
    "east" => "e",
    "south" => "s",
    "west" => "w",
    "nth" => "n",
    "sth" => "s",
    "ne" => "ne",
    "nw" => "nw",
    "se" => "se",
    "sw" => "sw",
    "northeast" => "ne",
    "northwest" => "nw",
    "southeast" => "se",
    "southwest" => "sw",
  }

  def self.components; COMPONENTS; end

  def self.clean(str)
    str.to_s.gsub(/([\.,:;]|\(.*?\))/, '').gsub(/.#[a-zA-Z0-9]+$/, '').gsub(/\s+/, ' ').strip.downcase.presence
  end

  def self.clean_hash(hash)
    hash.each_with_object({}.with_indifferent_access) { |(k,v),hsh| hsh[k] = clean(v) }
  end

  # Define methods for each of the components
  components.each do |f|
    define_method(f) { @components[f] }
  end

  attr_reader :components

  # @param {String} street_number - The street number
  # @param {String} street_name - The name of the street including all the 'ixes
  # @param {Hash} components - The components of the street
  def initialize(components = {})
    @components = components
  end

  def street
    @street ||= UsStreet.trim(dir_prefix, street_name, street_suffix, dir_suffix, road_number)
  end

  def full_street
    @full_street ||= UsStreet.trim(street_number, street)
  end

  def display
    @display ||= unit.present? ? UsStreet.trim(full_street, "##{unit}") : full_street
  end

  def attributes
    @attributes ||= @components.merge(street: street, full_street: full_street, display: display)
  end

  def self.parse(full_street, overrides = {})
    original_full_street = full_street.to_s
    full_street = clean(full_street.to_s).to_s # the cleaner removes unit numbers :(
    overrides = clean_hash(overrides)

    parts = full_street.split(' ')
    sidx, eidx = 0, parts.length - 1
    unit_number = dir_suffix = dir_prefix = street_suffix = street_number = road_number = nil

    # We could have a unit number last. Format '#[a-zA-Z0-9]+' but it's removed by the cleaners so match the original
    if match = original_full_street.match(/#([a-zA-Z0-9]+)$/)
      unit_number = match[1]
    end

    # we may be on a numbered road. Like a country road.
    if parts[eidx] =~ /^\d+$/
      road_number = parts[eidx]
      eidx -= 1
    end

    # strip suffixes starting at the end and working backwards
    # Check for a postdirectional (directional suffix)
    eidx -= 1 if eidx - sidx > 0 and dir_suffix    = direction_mapping(parts[eidx])

    # Check for a street suffix. If there's already a street suffix override,
    # don't strip from string unless it's the same suffix.
    # Otherwise "Forest Trail Rd" gets stripped to "Forest Trl"
    if eidx - sidx > 0 and street_suffix_maybe = road_mapping(parts[eidx])
      if overrides[:street_suffix].blank? or street_suffix_maybe == road_mapping(overrides[:street_suffix])
        street_suffix = street_suffix_maybe
        eidx -= 1
      end
    end

    # remove components from the beginning

    # is there a street number at beginning
    if eidx - sidx > 0 and parts[sidx] =~ /^\d+$/
      street_number = parts[sidx]
      sidx += 1
    end

    # is there a predirectional?
    sidx += 1 if eidx - sidx > 0 and dir_prefix    = direction_mapping(parts[sidx])

    # fix weirdo street names and make them consistent
    parts[sidx] = "St" if parts[sidx] =~ /^((st\.?)|(saint))$/i  # catch "Saint John Street"
    parts[sidx] = "Dr" if parts[sidx] =~ /^((dr\.?)|(doctor))$/i  # catch "Dr. Oz Road"

    # Time to build up the output, prefer what was passed in
    # Note: We needed to decompose the street because the street may have had the components put into it
    # by some unsavoury operators :'(
    overrides_unit = overrides[:unit].to_s.try(:match, /([a-zA-Z0-9]+)/).try(:captures).try(:first)
    out = {
      unit: (overrides_unit || unit_number).try(:upcase),
      dir_prefix: direction_mapping(overrides[:dir_prefix]).presence || dir_prefix,
      street_name: overrides[:street_name].presence || parts[sidx..eidx].join(' '),
      street_suffix: road_mapping(overrides[:street_suffix]).presence || street_suffix,
      dir_suffix: direction_mapping(overrides[:dir_suffix]).presence || dir_suffix,
      street_number: overrides[:street_number].presence || street_number,
      road_number: overrides[:road_number].presence || road_number
    }

    # we may have country or co for a country road.
    out[:street_name] = 'co' if out[:street_name] == 'country'

    # perform one last mapping to be sure that we've got the correct 'ixes.
    out[:dir_prefix] = out[:dir_prefix].try(:upcase)
    out[:dir_suffix] = out[:dir_suffix].try(:upcase)
    out[:street_suffix] = road_mapping(out[:street_suffix]).try(:titleize)
    out[:street_name] = out[:street_name].try(:titleize)

    out[:street_name] = out[:street_name].to_i.ordinalize if out[:street_name].present? && out[:street_name] =~ /^\d+$/

    new out
  end

  def self.from_attrs(street_number, dir_prefix, street_name, street_suffix, dir_suffix)
    return parse(
      street_name,
      street_number: street_number,
      dir_prefix: dir_prefix,
      street_suffix: street_suffix,
      dir_suffix: dir_suffix
    )
  end

  def self.direction_mapping(direction)
    DIRECTIONAL_MAPPINGS[direction.to_s.downcase] && DIRECTIONAL_MAPPINGS[direction.to_s.downcase].upcase
  end

  def self.road_mapping(suffix)
    ROAD_SUFFIXES[suffix.to_s.downcase] && ROAD_SUFFIXES[suffix.to_s.downcase].upcase
  end

  def self.trim(*address_components)
    address_components.compact.join(' ').gsub(/\s+/, ' ').strip
  end

  def ==(other)
    other.respond_to?(:full_street) && self.full_street == other.full_street
  end
end
