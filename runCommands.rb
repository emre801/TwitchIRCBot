
class ReadCommand
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


	def read_input(m, queue,responce, channel, fc_hash, ign_hash, hash)
	  sResponce = responce.split("!")
	  sResponce.each { |item| execute_input(m,queue,item,channel,fc_hash,ign_hash,hash)}
      
	end

	def execute_input(m,queue,responce,channel,fc_hash,ign_hash, hash)
 	   responce.strip!
       lowerCase = responce.downcase
       m.twitch responce
       if(hash.has_key?("!"+responce))
       	m.twitch hash["!"+responce]
       end
       if lowerCase["add"]
       	add(m,queue)
       elsif lowerCase["next"]
       	nextT(m,queue,channel,fc_hash,ign_hash)
	   elsif lowerCase["ign"]
		ign(m,queue,responce[3..-1],ign_hash)
	   elsif lowerCase["line"]
	   	line(m,queue)
	   elsif lowerCase["fc "]
	   	fc_responce(m, queue, responce, fc_hash)  		
       end

	end


	def add(m, queue)
		if (queue.include?(m.user.nick))
	      m.twitch "You are already in line for a battle, #{m.user.nick}"
	      return
	    end
	    m.twitch "#{m.user.nick}, has been added to the battleQueue"
	    queue.push m.user.nick
	    write_file_array(queue, "queue.txt")
	end

	def nextT(m, queue, channel, fc_hash,ign_hash)
	 	if queue.length == 0 
	      m.twitch "No one is in queue"
	      return
	    end
	    if m.user.nick.eql?(channel)
	      battle = queue.shift 
	      person = battle
	      battle ="Next person for battle is #{battle}"
	      if(fc_hash.has_key?(person))
	        battle = battle + ", fc: " +  fc_hash[person][0..3] + "-" + fc_hash[person][4..7] + "-" + fc_hash[person][8..12]
	      else 
	        battle = battle + ", please enter your friend code, inorder to save code use !fc command"
	      end
	      if(ign_hash.has_key?(person))
	        battle = battle + ", IGN: " + ign_hash[person]
	      else
	        battle = battle + ", please enter your IGN inorder for it to be saved"
	      end
	      m.twitch battle
	      write_file_array(queue, "queue.txt")
	    end
	end

	def ign(m, queue, responce,ign_hash)
		ign_hash[m.user.nick] = responce
		m.twitch "your IGN has been saved, thank you"
		write_file(ign_hash, "ign.txt") if !$writeMySQL
	end

    def fc_responce(m, queue, responce, fc_hash)
		responce.strip!
	    originalMessage = responce
	    responce = responce.delete('^0-9')
	    if responce.length != 12
	      originalMessage.downcase! 
	      originalMessage.gsub!(/[^0-9A-Za-z]/, '') 
	      if(fc_hash.has_key?(originalMessage))
	          originalMessageR = fc_hash[originalMessage]
	          m.twitch originalMessage + " : " + originalMessageR[0..3] + "-" + originalMessageR[4..7] + "-" + originalMessageR[8..12]
	      else
	        m.twitch m.user.nick + ", You have entered an incorrect friend Code"
	      end
	      return;
	    end
	    m.twitch m.user.nick + ", Thank you. I have added your Friend Code to my Collection " + responce[0..3] + "-" + responce[4..7] + "-" + responce[8..12]
	    fc_hash[m.user.nick] = responce
	end

	def fc(m, queue, responce, fc_hash)
	    if(fc_hash.has_key?(m.user.nick))
	      responce = fc_hash[m.user.nick]
	      m.twitch m.user.nick + " : " + responce[0..3] + "-" + responce[4..7] + "-" + responce[8..12]
	    else 
	      m.twitch m.user.nick + " , please enter you friend code using \"!fc 1234-1234-1234\""
	    end
	    write_file(fc_hash, "fc.txt")
	end
	def line(m, queue)
	    if(queue.length ==0)
	      m.twitch "No one is in line"
	      return
	    end
	    line = "";
	    queue.each { |item| line = line + " " + item  }
    	m.twitch line
	end
	def remove(m, queue)
	    if queue.include?(m.user.nick)
	      queue.delete(m.user.nick)
	      m.twitch "You have been removed"
	    else
	      m.twitch m.user.nick + ", you are not in line"
	    end
	end

	def fc_update(m, queue)

	end

end


