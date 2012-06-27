infoq-rss
=========

This is a simple Sinatra app that puts mp3 enclosures into infoq's personalized RSS feed, so that it can work with any standard podcatcher (I use BeyondPod on Android).  

I've been annoyed with InfoQ's RSS feed for a long time, since it's my only source of awesome mp3 content that doesn't have enclosures in their feed.  This required a Rube Goldberg amalgam of Dropbox favorites and a BeyondPod folder feed.  InfoQ requires you to login to download MP3s, so this code might violate some terms of service or something, but there's no agreement during the registration process.  InfoQ is welcome to contact me to discuss.

To get the mp3 of every presentation, add http://infoq-rss.herokuapp.com/rss to your podcatcher.  Unfortunately, the InfoQ RSS feed only contains the most recent 16 items, which includes presentations, articles and interviews.  This feed will only show presentations, so you'll likely get less than 16.

If you want to filter out certain topics, create your own free InfoQ account, and "Personalize Your Main Interests" by clicking on your first name in the top right of infoq.com.  Additionally, on the Preferences page, you can add topics or tags to your "Excluded" list (I exclude Java and .Net).  Then pass the token from your InfoQ personalized RSS feed to this script, and you'll only get the items you're interested in: http://infoq-rss.herokuapp.com/rss?token=xxxx .  As an added bonus, the 16 items you get will go further back in time.


