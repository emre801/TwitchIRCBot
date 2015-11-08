class Cred
  def return_cred()
    client = Twitter::REST::Client.new do |config|
    config.consumer_key        = "fnLBUDDLfOyzyQDx3ZMDgQS82"
    config.consumer_secret     = "TbEWq9NYx41eY39Qvgre71eylnJ0JK7g4SJO9i5RcORWSTtIW7"
    config.access_token        = "235382126-kxh6viE1CHQJpcbHhH0gRcG8kMpvRzcxL2rVUh94"
    config.access_token_secret = "bQsYMmBWVP50XoeDqKwoanDIXjLXN1U6SlO5rK2UzQzi2"
    end 
    return client
  end
  def return_twitch_password()
    return "oauth:r4ykhpl985qi85oydfkt3z2xk95cj8"
  end
  def return_bot_name()
    return "darcelBot"
  end
end
