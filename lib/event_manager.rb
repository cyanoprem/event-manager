# rubocop:disable all

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/,'')
  if phone_number.length < 10
    'Wrong Number'
  elsif phone_number.length == 11
    if phone_number[0] == 1
      phone_number[1..10]
    else
      'Wrong Number'
    end
  elsif phone_number.length > 11
    'Wrong Number'
  else 
    phone_number
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
$hour_array = []
$day_array =[]

contents.each do |row|
  id =row[0]

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  reg_date = row[:regdate]

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  date = DateTime.strptime(reg_date, "%m/%d/%Y %k:%M")

  $hour_array.push(date.hour)

  $day_array.push(Date.new(2008, date.mon, date.mday).wday)

end

hour_hash ={}
day_hash = {}

hour_hash = $hour_array.reduce(Hash.new(0)) do |result, vote|
  result[vote] += 1
  result
end

day_hash = $day_array.reduce(Hash.new(0)) do |result, vote|
  result[vote] += 1
  result
end

p hour_hash # What hours of the day most people registered 
p day_hash # What days of the week did most people register 


