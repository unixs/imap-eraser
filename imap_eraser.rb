#! /usr/bin/env ruby

require 'yaml'
require 'net/imap'
require 'mail'

IMAP_FETCH_LIMIT = 500
LOG_ADDRESS_FIELDS = [:from, :to]
MAIN_LOOP_TIMEOUT = 3
CONFIG_FILENAME = 'imap_eraser.yml'

def read_config
  return YAML.load File.read CONFIG_FILENAME
end

def connect(account)
  begin
    imap = Net::IMAP.new account['host']
    imap.starttls
    imap.login account['user'], account['pass']
    return imap
  rescue Exception => ex
    puts "\tERROR:#{Time.now}| Account [#{account['user']}[at]#{account['host']}] Exception: #{ex.message.force_encoding('utf-8')}"
  end
end

def disconnect(imap)
  begin
    imap.logout
    imap.disconnect
  rescue
  end
end

def before_date(date, before)
  return date - (60 * 60 * 24 * before)
end

def today
  now = Time.now
  return Time.new now.year, now.month, now.day
end

def encode_path(box, dots_delimiter)
  box = Net::IMAP.encode_utf7 box
  if dots_delimiter
    box = box.split('/').join '.'
  end
end

def process(account)
  account_uid = "#{account['user']}[at]#{account['host']}"
  puts "Account start: #{Time.now}| #{account_uid}"
  puts "\tSimulate mode" if account['simulate']
  imap = connect account
  released_memory = 0

  if (imap)
    account['dirs'].each do |dir|
      unless dir['period']
        puts "\tWARNING:#{Time.now}| Mailbox [#{dir['dir']}] has empty period. Ignore mailbox"
        next
      end
      before = Net::IMAP.format_date(before_date(today(), dir['period']))
      puts "#===>#{before} #{dir['dir']}"

      mailbox = encode_path(dir['dir'], account['dots_delimiter'])

      begin
        # Select mailbox
        imap.select mailbox

        # Set conditions
        conditions = ['BEFORE', before, 'NOT', 'FLAGGED']
        if account['only_seen']
          conditions.push 'SEEN'
        end
        # Get messages ids array
        messages = imap.search conditions 

        
        while (!(mids = messages.slice!(0, IMAP_FETCH_LIMIT)).empty?) do

          # Delete messages
          unless account['simulate']
            imap.store mids, '+FLAGS', [:Deleted]
          end

          # Fetch some messages by IMAP
          messages_data = imap.fetch(mids, "ALL")

          # Each some messages
          messages_data.each do |msg|
            # Internaldate
            internaldate = msg[:attr]['INTERNALDATE']

            # Address fields
            address_fields = []
            LOG_ADDRESS_FIELDS.each do |f|
              raw_field = msg[:attr]['ENVELOPE'][f].first
              field = "#{raw_field[:mailbox]}[at]#{raw_field[:host]}"
              if (raw_field[:name])
                fname = Mail::Encodings.unquote_and_convert_to raw_field[:name], 'utf-8'
                field = "#{fname} <#{field}>"
              end
              address_fields << "#{f.capitalize}:#{field}"
            end

            # Subject
            subject = Mail::Encodings.unquote_and_convert_to msg[:attr]['ENVELOPE'][:subject], 'utf-8'

            # RFC822 Size
            rfc822_size = msg[:attr]['RFC822.SIZE']
            released_memory += rfc822_size

            puts "\t|#{internaldate} Size:#{rfc822_size} #{address_fields.join(' ')} Subject:#{subject}"
          end

        end # /while

        unless account['mark_delete_only']
          imap.close
        end
      rescue Exception => ex
        puts "\tERROR:#{Time.now}| Mailbox [#{dir['dir']}] Exception: #{ex.message.force_encoding('utf-8')}"
        #raise ex
      end
    end

    disconnect imap
  end
  puts "Account finish: #{Time.now}| #{account_uid} Memory released: #{released_memory}"
  puts "\n"
end

conf = read_config

account_threads = ThreadGroup.new

conf['accounts'].each do |account|
  account_threads.add Thread.new { process account }
end

# Main Loop
begin
  alive = false

  account_threads.list.each do |t|
    if (t.alive?)
      alive = true
      break
    end
  end

  sleep MAIN_LOOP_TIMEOUT

end while (alive)

# GAME OVER
