require 'rss'
require 'open-uri'

class InfoQApp < Sinatra::Base

get '/rss' do
	token = params[:token] || 'DrROHqmA6qPdIMgWBTVyXnko3xVw5YBZ'
	rss_out = RSS::Maker.make('2.0') do |maker|
		url = "http://www.infoq.com/rss/rss.action?token=#{token}"
		open(url) do |rss_in|
			feed = RSS::Parser.parse(rss_in)
			maker.channel.title = feed.channel.title
			maker.channel.link = feed.channel.link
			maker.channel.description = feed.channel.description

			feed.items.each do |i|
				next unless i.title.start_with?("Presentation")
				preso_path = false
				i.link.match('/presentations/(.+)$') { |m| preso_path = m[1] }
				next unless preso_path
				
				maker.items.new_item do |item|
					item.link = i.link
					item.title = i.title
					item.description = i.description
					item.enclosure.url = "/mp3/#{preso_path}?token=#{token}"
					item.enclosure.length = 65_000_000
					item.enclosure.type = 'audio/mpeg'
				end
			end
		end
	end

	content_type :rss
	rss_out.to_s
end

def login(token)
	form_data = {
		'DrROHqmA6qPdIMgWBTVyXnko3xVw5YBZ' => [
			Curl::PostField.content('username', 'mattalbright'),
			Curl::PostField.content('password', 'mattalbrightpass'),
		]
	}[token]
	
	return unless form_data
	
	curl = Curl::Easy.new("https://www.infoq.com/login.action")
	curl.enable_cookies
	curl.http_post(*form_data)
	curl.perform
	
	puts curl.headers.inspect
	
	curl.response_code
#	res.get_fields('set-cookie').inspect
	# user_cookie = res.get_fields('set-cookie').find {
	# 	|c| c.start_with?('RegisteredUserCookie')
	# }.match('RegisteredUserCookie=([^;]+);')[1]
	# 
	# user_cookie
end

get '/mp3/:preso_path' do |preso_path|
	preso_path
	login(params[:token])
end

end
