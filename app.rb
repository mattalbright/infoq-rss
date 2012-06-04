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
					item.enclosure.url = "/mp3/#{preso_path}"
					item.enclosure.length = 65_000_000
					item.enclosure.type = 'audio/mpeg'
				end
			end
		end
	end

	content_type :rss
	rss_out.to_s
end

get '/mp3/:preso_path' do |preso_path|
	preso_path
end

end
