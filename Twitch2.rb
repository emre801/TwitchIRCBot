require 'cinch'
#require 'mysql'
load 'Cred.rb'
load 'pokegemTest.rb' ##Comment this out in Windows
load 'runCommands.rb'
$gChanel = ""
$loadMySQL = false
$writeMySQL = false
restart = false

def retrieve_mysql_info(tableName, user = false)
  tableName.slice! ".txt"
  begin
      con = Mysql.new 'localhost', 'user12', '34klq*', 'darcelbot'
      sql = "SELECT * FROM " + tableName
      channel = $gChanel
      sql << " where user = '#{channel}'" if user
      rs = con.query sql
      #puts "We have #{rs.num_rows} row(s)"
      hash = Hash.new
      rs.each_hash do |row|
         puts  row['col1'] + " " + row['col2']
         hash[row['col1']] = row['col2']
      end  
      return hash
      
  rescue Mysql::Error => e
      puts e.errno
      puts e.error
      
  ensure
      con.close if con
  end
end



def insert_new_value_into_table(tableName, col1, col2)
  tableName.slice! ".txt"
  begin
      con = Mysql.new 'localhost', 'user12', '34klq*', 'darcelbot'
      con.query("INSERT INTO #{tableName}(col1,col2) VALUES('#{col1}','#{col2}')")
      
  rescue Mysql::Error => e
      puts e.errno
      puts e.error
      
  ensure
      con.close if con
  end


end



def build_commands(fileName, user = false)
  return retrieve_mysql_info(fileName, user) if $loadMySQL
  #Read the commands from the files
  file = open(fileName, 'r')
  hash = Hash.new
  file.each { |line| 
    line = line.strip
    commands = line.split(':---:')
    hash[commands[0]] =  commands[1]
  }
  return hash
end


$timeCommands = build_commands("time.txt")


class TimedPlugin
  include Cinch::Plugin
  $timeCommands.each { |command, seconds| 
    timer seconds.to_i, method: command.to_sym
    define_method(command) do 
      string = command
      string = string.to_s.gsub('<','&lt;').gsub('>','&gt;')
      channel = $gChanel
      bot.irc.send ":#{bot.config.user}!#{bot.config.user}@#{bot.config.user}.tmi.twitch.tv PRIVMSG #{channel} :#{string}"
    end
  }



end


cred = Cred.new()
pokemonInfo = PokemonInfo.new
readCommand = ReadCommand.new


class Cinch::Message
  def twitch(string)
    string = string.to_s.gsub('<','&lt;').gsub('>','&gt;')
    bot.irc.send ":#{bot.config.user}!#{bot.config.user}@#{bot.config.user}.tmi.twitch.tv PRIVMSG #{channel} :#{string}"
  end
end

def build_commands_array(fileName)
  #Read the commands from the file
  file = open(fileName, 'r')
  array = Array.new
  file.each { |line| 
    line = line.strip
    array <<  line
  }
  return array
end

def write_file(hash, filepath)
  logfile = File.new(filepath, "w")
  hash.each { |k, v| logfile.write(k + ':---:' + v + "\n")  }
  logfile.close
end

def write_file_array(array, filepath)
  logfile = File.new(filepath, "w")
  array.each { |person| logfile.write(person + "\n")  }
  logfile.close
end





queue = Array.new
#read from file queue and stored friendCodes

puts "Enter channel to join"
channel = "emre801"
if(ARGV.length==0)
  channel = gets.chomp#"emre801"
else
  channel = ARGV[0]
end
$gChanel = channel
hash = build_commands("botCommands.txt",true)
$tCommands = build_commands("time.txt")
fc_hash = build_commands("fc.txt")
ign_hash = build_commands("ign.txt")
puns = build_commands_array("pun.txt")
queue = build_commands_array("queue.txt")
botname = cred.return_bot_name #this is where you'll enter your bot's name
raffle = Hash.new
raffle_lock = false;


#write queue to file
  
bot = Cinch::Bot.new do
  configure do |c|
    c.server   = "irc.twitch.tv"
    c.port     = "6667"
    c.nick     = botname #change nickname to your bots' name
    c.password = cred.return_twitch_password
    c.channels = ["#"+channel]
    c.user     = botname #change user to your bot's name
    c.plugins.plugins = [TimedPlugin]
  end
  on :message, "!listC" do |m|
    commandList = "The available commands are "
    hash.each { |command, response|  commandList = commandList + " " + command  }
    m.twitch commandList
  end
  on :message, "!pun" do |m|
    m.twitch puns[rand(puns.length)]
  end
  ##----------
  #

  on :message, /^!(.+)/ do |m, responce|
    readCommand.read_input(m,queue,responce,channel,fc_hash,ign_hash, hash)
  end

  ## FC and IGN management
  
  on :message, "!remove" do |m|
    readCommand.remove(m,queue)
    write_file_array(queue, "queue.txt")
  end

  on :message, "!fc" do |m, responce|
    readCommand.fc(m,queue, responce, fc_hash)
  end
  
  
  on :message, /^!fc_update (.+)/ do |m, responce|
    responce = responce.delete('^0-9')
    if(!fc_hash.has_key?(m.user.nick))
      m.twitch m.user.nick + ", you do not have a friendCode in the database, currently adding it"
    end
    if responce.length != 12
      m.twitch m.user.nick + ", You have entered an incorrect friend Code"
      return;
    end
    m.twitch m.user.nick + ", Thank you. I have added your Friend Code to my Collection " + responce[0..3] + "-" + responce[4..7] + "-" + responce[8..12]
    fc_hash[m.user.nick] = responce
    write_file(fc_hash, "fc.txt") if !$writeMySQL
    insert_new_value_into_table("fc", m.user.nick, responce) if $writeMySQL
  end
  ##----------
  


  ##----------
  ## Make bot quit
  on :message, "!quit" do |m|
    if( m.user.name.eql?(channel) || m.user.name.eql?("emre801"))
      bot.quit
    end
  end

  on :message, "!wt" do |m|
    if( m.user.name.eql?(channel))
      m.twitch "Wonder trade time"
      (1..5).to_a.each do |time|
        sleep(1)
        m.twitch (6 - time).to_s
      end
      sleep(1)
      m.twitch "GO!"
    end
  end

  on :message, "!userList" do |m|
    if( m.user.name.eql?(channel))
      Channel("#"+channel).users.each do |user, modes|
        m.twitch modes
      end
    end
  end
  on :message, "!bwaha" do |m|
    return if( !m.user.name.eql?(channel))
    #fc_hash.each{|k,v| insert_new_value_into_table("fc", k, v)}
    #ign_hash.each{|k,v| insert_new_value_into_table("ign", k, v)}
    hash.each{|k,v| insert_new_value_into_table("botcommands", k, v)}
  end

  on :message, /^!addC (.+)/ do |m, responce|
    #responce.strip?
    if( m.user.name.eql?(channel))
      bound = responce.index(' ')
      head = responce.slice(0,bound)
      tail = responce.slice(bound + 1, responce.length)
      m.twitch head + "----" + tail
      
      hash[head] = tail
      write_file(hash, "botCommands.txt")
      m.twitch "New Command added"
      m.twitch "blarg"
      bot.quit
      restart = true
    end
  end

  
  ##Pokemon LookUp, you have to comment this out in windows
  on :message, /^!pk (.+)/ do |m, responce|
    pokemonInfo.print_pokemon(responce, m)
  end
  ##---------
end

bot.start
#this might be the point where I choose to reboot or not
puts "Hello I have ended WOOT WOOT"
Kernel.exec("ruby Twitch.rb " + channel) if restart