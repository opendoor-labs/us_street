require 'csv'
require 'json'
require 'us_street'
require 'optparse'

input_path = nil
output_path = nil

parser = OptionParser.new do |opts|
  opts.banner = 'Usage: csv_parser.rb [options]'
  opts.on("-i", "--input PATH", "Input CSV file [columns=full_street,overrides]") do |v|
    input_path = v
  end
  opts.on("-o", "--output PATH", "Output CSV file") do |v|
    output_path = v
  end
end
parser.parse!
if !input_path or !output_path
  puts parser.help
  exit(1)
end

CSV.open(output_path, "wb") do |out|
  out << UsStreet.components

  CSV.foreach(input_path, headers: :first_row) do |row|
    full_street = row['full_street']
    overrides = row.header?('overrides') ? JSON.parse(row['overrides']) : {}

    parse = UsStreet.parse(full_street, overrides)
    out << UsStreet.components.map { |c| parse.components[c] }
  end
end
