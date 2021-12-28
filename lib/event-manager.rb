require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonenumber(phone)
   phone_s = phone.scan(/\d/).join.to_s
  if phone_s.length == 10
    return phone_s
  elsif phone_s.length == 11 && phone_s[0] == "1"
    return phone_s[1..10]
  else
    return "Phone# Error"
  end
end


def time_targeting(reg_date)
  my_date = Time.strptime(reg_date, "%m/%d/%y %k:%M")
  my_date.hour
end

def day_targeting(reg_date)
  my_date = Date.strptime(reg_date, "%m/%d/%y %k:%M")
  my_date.strftime("%A")
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

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
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
time_array = Array.new
day_array = Array.new
week_days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

contents.each do |row|
  id = row[0]
  p name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  p phonenumber = clean_phonenumber(row[:homephone])
  time = time_targeting(row[:regdate])
  time_array.push(time)
  day = day_targeting(row[:regdate])
  day_array.push(day)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

i = 1
for i in 1..24 do
  p "Num replies hour #{i}: #{time_array.count(i)}"
end

week_days.each do |day|
  p "Num replies on #{day}: #{day_array.count(day)}"
end





