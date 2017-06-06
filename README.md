# get-oe1podcast
Downloads an OE1 podcast and creates a podcast feed on your own webspace

With this advanded function it's possible to automate download of radio streams from ORF OE1 (7 days in the past) and create a podcast feed from the downloads with some
    information gathered from the streaming system. To host the content you'll need (of course) a webserver facing to the internet.
    
    -podcast      is a search value 
    -safePath     is the path to which the streams are beeing downloaded
    -xmlPath      is the path where the xml files are stored. This is the location of feedUrlHome
    -feedUrlHome  is the web address that points to the xmlPath (from the web)
    -search       searches for streams and displays it with releavant information on the screen.

#OE1 Audio API Analysis:

1. https://audioapi.orf.at/oe1/api/json/current/broadcasts returns a list of broadcasts

2. search for e.g help -> build an URL with programKey/broadcastDay
        Tag6 -> broadcasts -> 15 -> title "help - das Konsomentenmagazin"

3. https://audioapi.orf.at/oe1/api/json/current/broadcast/474761/20170513
        Streams -> 0 -> loopStreamId: "2017-05-20_1139_tl_51_7DaysSat16_365481.mp3"

4. download http://loopstream01.apa.at/?channel=oe1&shoutcast=0&id=2017-05-20_1139_tl_51_7DaysSat16_365481.mp3 
