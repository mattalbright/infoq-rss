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
					item.enclosure.url = "http://#{env['HTTP_HOST']}/mp3/#{preso_path}?token=#{token}"
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
		'DrROHqmA6qPdIMgWBTVyXnko3xVw5YBZ' => {
			'username' => 'mattalbright@gmail.com',
			'password' => 'mattalbrightpass',
		}
	}[token]
	
	return unless form_data
	
	curl = Curl::Easy.new("https://www.infoq.com/login.action")
	params = form_data.keys.map { |k| Curl::PostField.content(k, form_data[k]) }
	
	user_cookie = ""
	
	curl.on_header do |header|
		header.match('RegisteredUserCookie=[^;]+') { |m| user_cookie = m[0] }
		header.length
	end
	curl.http_post(*params)
	
	user_cookie
end

def get_mp3_url(preso_path, user_cookie)
	mp3_href = nil
	curl = Curl::Easy.new("http://www.infoq.com/presentations/#{preso_path}")
	curl.headers['Cookie'] = user_cookie
	curl.on_body do |body|
		body.match('class="link-mp3" +href="(/mp3download[^"]+)"') { |m| mp3_href = m[1] }
		body.length
	end
	curl.http_get
	return unless mp3_href
	
	curl.url = "http://www.infoq.com#{mp3_href}"
	mp3_abs_url = nil
	curl.on_header do |header|
		header.match('Location: ([[:graph:]]+)') { |m| mp3_abs_url = m[1] }
		header.length
	end
	curl.http_get

	mp3_abs_url
end

get '/mp3/:preso_path' do |preso_path|
	user_cookie = login(params[:token])
	mp3_url = get_mp3_url(preso_path, user_cookie)
	redirect mp3_url
end

end
