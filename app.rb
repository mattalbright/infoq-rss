require 'rss'
require 'open-uri'
require 'uri'

class InfoQApp < Sinatra::Base

USER_AGENT = "Mozilla/5.0 (https://github.com/mattalbright/infoq-rss) Chrome/33.0.1750.149"

get '/rss' do
	# Default is everything... create your own infoq account and exclude stuff if you want in Preferences.
	token = params[:token] || 'FyBAnM6KAPnHXKa0T2oa0NCGJ6hRjrAU' 
	rss_out = RSS::Maker.make('2.0') do |feed_out|
		url = "http://www.infoq.com/rss/rss.action?token=#{token}"
		open(url) do |rss_in|
			feed_in = RSS::Parser.parse(rss_in)
			feed_out.channel.title = feed_in.channel.title
			feed_out.channel.link = feed_in.channel.link
			feed_out.channel.description = feed_in.channel.description

			feed_in.items.each do |item_in|
				next unless item_in.title.start_with?("Presentation")
				preso_path = false
				item_in.link.match('/presentations/(.+)$') { |m| preso_path = m[1] }
				next unless preso_path
				
				feed_out.items.new_item do |item_out|
					item_out.link = item_in.link
					item_out.title = item_in.title
					item_out.description = item_in.description
					item_out.pubDate = item_in.pubDate
					item_out.enclosure.url = "http://#{env['HTTP_HOST']}/mp3/#{preso_path}"
					item_out.enclosure.type = 'audio/mpeg'
					
					# From http://www.rssboard.org/rss-profile#element-channel-item-enclosure :
					# "When an enclosure's size cannot be determined, a publisher SHOULD use a length of 0."
					item_out.enclosure.length = 0
				end
			end
		end
	end

	content_type :rss
	rss_out.to_s
end

def get_user_cookie
	user_cookie = ""
	
	curl = Curl::Easy.new("https://www.infoq.com/login.action")
	curl.ssl_verify_peer = false
	curl.useragent = USER_AGENT
	curl.on_header do |header|
		header.match('RegisteredUserCookie=[^;]+') { |m| user_cookie = m[0] }
		header.length
	end
	curl.http_post(URI.encode_www_form(
		'username' => 'mattalbright+infoq@gmail.com', 'password' => 'infoqpass'))
	
	user_cookie
end

def get_mp3_url(preso_path, user_cookie)
	filename = nil
	curl = Curl::Easy.new("http://www.infoq.com/presentations/#{preso_path}")
	curl.useragent = USER_AGENT
	curl.headers['Cookie'] = user_cookie
	curl.on_body do |body|
		body.match('value="(presentations/[^"]+\.mp3)"') { |m| filename = m[1] }
		body.length
	end
	curl.http_get
	return unless filename
	
	curl.url = "http://www.infoq.com/mp3download.action"
	mp3_abs_url = nil
	curl.on_header do |header|
		header.match('Location: ([[:graph:]]+)') { |m| mp3_abs_url = m[1] }
		header.length
	end
	curl.http_post(URI.encode_www_form('filename' => filename))

	mp3_abs_url
end

get '/mp3/:preso_path' do |preso_path|
	redirect get_mp3_url(preso_path, get_user_cookie)
end

end
