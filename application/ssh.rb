require 'highline/import'

class MCollective::Application::Ssh < MCollective::Application
  description "SSH helper based on mcollective filters"
  usage "mco ssh [filters and options] -- [ssh options]"

  def post_option_parser(configuration)
    configuration[:ssh] = ARGV.join(" ") if ARGV.length >= 1
  end

  # Shows a list of options and lets the user choose one
  def pick(choices)
    return choices[0][1] if choices.size == 1
    keys = choices.keys

    choose do |menu|
      keys.each do |choice|
          menu.choice choice
      end

      menu.choice "Exit" do exit! end
    end
  end

  def main
    rpcutil = rpcclient("rpcutil", :options => options)
    rpcutil.progress = false

    addresses = {}
    rpcutil.get_fact(:fact => 'ipaddress') do |resp|
      begin
        value = resp[:body][:data][:value]
        addresses[resp[:senderid]] = value if value
      rescue Exception => e
        STDERR.puts "Could not parse facts for #{resp[:senderid]}: #{e.class}: #{e}"
      end
    end

    ip = if addresses.size == 1
      addresses.values.first
    elsif addresses.empty?
      # Mcollective will print it's own message about not
      # matching any hosts (without a newline)
      puts
      exit!
    else
      hostname = pick(addresses)
      addresses[hostname]
    end

    begin
      puts("Running: ssh #{ip} #{configuration[:ssh]}")
      exec("ssh #{ip} #{configuration[:ssh]}")
    rescue Exception => e
      puts("Failed to run ssh: #{e}")
      puts e.backtrace
      exit!
    end
  end
end


