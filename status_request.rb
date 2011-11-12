require "open-uri"
require "pony"

# Select files & Initialize parameters
server_file = 'server_list.txt'
log_file = 'server_logs.log'
urls = Hash.new
up_status = "Connection Established"
down_status = "Down"


def send_mail
  Pony.mail(:to => 'pkemanes@gmail.com', :subject => 'DOWN!', :body => 'Mayday! Mayday!', :via => :smtp, :via_options => {
    :address              => 'smtp.gmail.com',
    :port                 => '587',
    :enable_starttls_auto => true,
    :user_name            => 'pkemanes',
    :password             => 'password',
    :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
    :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
  })
end


# Save logs to file
def log_error(status, url)
  logs = File.open('server_logs.log', "a")
    logs.puts("-----------------------------------------------")
    logs.puts("Status: #{status} | #{Time.now}")
    logs.puts("#{url}")
    logs.puts("-----------------------------------------------")
    logs.puts("")
  logs.close
end


# Read file into array
# Check formating of server list
File.readlines(server_file).each do |str|
  str = str.strip()

  # RegExp: Any number of characters followed by a comma,
  # any number of white space then one or more digits
  if str =~ /.*[,]\s*\d+/
    a = str.split(%r{,\s*})
    urls[a[0]] = a[1].to_s.to_i

  # RegExp: Any characters followed by whitespace
  # and one or more digits
  elsif str =~ /.*\s\d+/
    a = str.split
    urls[a[0]] = a[1].to_s.to_i

  # RegExp: Any character followed by a comma
  # and any whitespace
  elsif str =~ /,\s*/
    a = str.split(%r{,\s*})
    urls[a[0]] = 0

  # RegExp: If anything other than whitespace
  elsif str =~ /\S+/
    urls[str] = 0
  end
end


# Check for connection errors
urls.each do |url, errors|
  begin
    file = open(url)
    the_status = file.status[0]

    if the_status == "200"
      # Log Established reconnection & reset token
      log_error(up_status, url) if errors > 2
      urls[url] = 0
    else
      urls[url] += 1
    end

  rescue => e
    urls[url] += 1
  end

  # Log after 3 tries (15mins) of downtime & Send email
  if urls[url] == 3
    log_error(down_status, url)
    send_mail
    p "Sending email..."
  end

  # Send email every 24hours
  if urls[url] > 0 && urls[url]%268 == 0
    p urls[url]
    send_mail
    p "Sending email..."
  end
end


# Clean up and rewrite server list
doc = File.open(server_file, "w")
  urls.each do |url, errors|
    doc.puts("#{url}, #{errors}")
  end
doc.close

