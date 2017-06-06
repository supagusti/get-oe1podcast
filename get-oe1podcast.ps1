 <#
 .Synopsis
    Downloads an OE1 podcast and creates a podcast feed
 .DESCRIPTION
    With this advanded function it's possible to automate download of radio streams from ORF OE1 (7 days in the past) and create a podcast feed from the downloads with some
    information gathered from the streaming system. To host the content you'll need (of course) a webserver facing to the internet.
    
    -podcast      is a search value 
    -safePath     is the path to which the streams are beeing downloaded
    -xmlPath      is the path where the xml files are stored. This is the location of feedUrlHome
    -feedUrlHome  is the web address that points to the xmlPath (from the web)
    -search       searches for streams and displays it with releavant information on the screen.
 .EXAMPLE
    get-oe1podcast -podcast help -safePath c:\inetpub\www\podcasts\help -xmlPath c:\inetpub\www\podcasts\help -feedUrlHome http://mysite.com/podcasts/help
 .EXAMPLE
    get-oe1podcast -podcast help -search
 #>

 function get-oe1podcast
 {
     [CmdletBinding()]
     [Alias()]
     [OutputType([int])]
     Param
     (
         # Podcast Download
         [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
         $podcast,
         # Podcast Download Save Path
         [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=1)]
         $safePath,
         # Podcast Download XML Path (meist gleich)
         [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=2)]
         $xmlPath,
         # Podcast Download DryRun (eq with whatif)
         [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=3)]
         [switch]$dryRun,
         # Podcast Download FeedUrlHome
         [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=4)]
         $feedUrlHome,
         # Search
         [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=1)]
         $search


     )

     #[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


## ------------------------------------------------------------------------------------------------------------------------------
##
##  START OF Search Part
##
##
## ------------------------------------------------------------------------------------------------------------------------------

if ($search)
{
        ##for each bla,bla,bla: $j[0].broadcasts | select scheduledStartISO,title, subtitle   | ft
     $j = Invoke-WebRequest -Uri https://audioapi.orf.at/oe1/api/json/current/broadcasts -Method Get -ContentType 'application/json; charset=utf-8'| ConvertFrom-Json
     $helpuri=""

     foreach ($broadcast in $j)
     {

         foreach ($title in $broadcast.broadcasts)
            {
                if ($title.title -like "*"+$search+"*")
                {
                     $helpuri =  $title.href
                     #break
                     #---START UTF8 Conversion ---
                     $tmpFile = New-TemporaryFile
                     Invoke-WebRequest -Uri $helpuri -Method Get -ContentType 'application/json; charset=utf-8' -OutFile $tmpFile.FullName
                     $content = Get-Content ($tmpFile.FullName) -Encoding utf8 -raw 
                     $podcast = $content | ConvertFrom-Json
                     #---END UTF8 Conversion ------

                     if ($podcast.streams[0].loopStreamId -eq $null)
                        {
                            $downloadUrl = "No stream available"
                            
                        }
                     Else
                        {
                            $downloadUrl = "http://loopstream01.apa.at/?channel=oe1&shoutcast=0&id=" +  $podcast.streams[0].loopStreamId
                            
                        }

                     
                     ##Get info
                     $description=""
                     foreach ($item in $podcast.items)
                        {
                            $description=$description + ($item.description -replace '<[^>]+>',"`n") + "`n"
                        }

                     Write-Output("Title: " + $podcast.title)
                     Write-Output("Begin Time: " + $podcast.startISO)
                     Write-Output("Subtitle:" + ($podcast.subtitle -replace '<[^>]+>',"`n"))
                     Write-Output("Description:" + $description)
                     Write-output("downloadUrl: "+$downloadUrl)   
                     Write-output("---------------------------------------------------------"+"`n")   
                     Remove-Item ($tmpFile)
                }

            }
     }


     break

}

## ------------------------------------------------------------------------------------------------------------------------------
##
##  START OF Podcast Part
##
##
## ------------------------------------------------------------------------------------------------------------------------------

if ($podcast)
{


     if ($safePath -eq $null) {$safePath="."}
     if ($xmlPath -eq $null) {$xmlPath="."}
     $j = Invoke-WebRequest -Uri https://audioapi.orf.at/oe1/api/json/current/broadcasts -Method Get -ContentType 'application/json; charset=utf-8'| ConvertFrom-Json
     $helpuri=""

     foreach ($broadcast in $j)
     {

         foreach ($title in $broadcast.broadcasts)
            {
                if ($title.title -like "*"+$podcast+"*")
                {
                    $helpuri =  $title.href
                    break
                }

            }
     }

     ##Write-Output $helpuri
     #$podcast = Invoke-WebRequest -Uri $helpuri -Method Get -ContentType 'application/json; charset=utf-8' | ConvertFrom-Json

     #---START UTF8 Conversion ---
     $tmpFile = New-TemporaryFile
     Invoke-WebRequest -Uri $helpuri -Method Get -ContentType 'application/json; charset=utf-8' -OutFile $tmpFile.FullName
     $content = Get-Content ($tmpFile.FullName) -Encoding utf8 -raw 
     $podcast = $content | ConvertFrom-Json

     #---END UTF8 Conversion ------

     if ($podcast.streams[0].loopStreamId -eq $null)
        {
            write-output ("No stream available")
            break
        }
     $downloadUrl = "http://loopstream01.apa.at/?channel=oe1&shoutcast=0&id=" +  $podcast.streams[0].loopStreamId
     Write-Verbose("downloadUrl="+$downloadUrl)

     ##Speichern des Files
     $safeFilePath=$safePath+"/"+$podcast.streams[0].loopStreamId
     if (test-path $safeFilePath)
     {
        Write-Output("File already downloaded")
     }
     else
     {

        if ($dryRun)
        {
            Write-Output("File would be saved to " +$safeFilePath +"")
        }
        else
        {
            Write-Output("Saving to " +$safeFilePath )
            Invoke-WebRequest $downloadUrl -OutFile $safeFilePath
        }
     }

     ##Get info
     $description=""

     foreach ($item in $podcast.items)
        {
            $description=$description + ($item.description -replace '<[^>]+>','') + "`n"
        }

     Write-Verbose("Title=" + $podcast.title)
     #$podcastTitle = $podcast.title + " vom "+ $podcast.broadcastDay
     $podcastBroadcastDayHelper=[datetime]$podcast.startISO
     [string]$podcastBroadcastDay=($podcastBroadcastDayHelper.Day.ToString() + "."+$podcastBroadcastDayHelper.Month.ToString() + "." + $podcastBroadcastDayHelper.Year.ToString())
     $podcastTitle = $podcast.title + " ("+ $podcastBroadcastDay + ")"

     Write-Verbose("Subtitle=" + $podcast.subtitle)
     Write-Verbose("Description=" + $description)
     #NEW
     #$descriptionTmp = $description
     #$description=ConvertFrom-UTF8 ($descriptionTmp)
     #Write-Verbose("Description (converted)=" + $description)
     ## make XML Description of the podcast

     $xmlFileName=$podcast.streams[0].loopStreamId.Split(".")
     $xmlFullPath=$xmlPath + "/" + $xmlFileName[0] + ".xml"
     Write-Verbose ("xmlFullPath=" + $xmlFullPath)
     if (test-path $xmlFullPath)
     {
        Write-Output("File already created")
     }
     else
     {
         [xml]$xmlContent=@"
<?xml version="1.0" encoding="utf-8"?>
        <PodcastGenerator>
            <episode>
                <titlePG><![CDATA[extrablatt]]></titlePG>
                <shortdescPG><![CDATA[blabla]]></shortdescPG>
                <longdescPG><![CDATA[blabla]]></longdescPG>
                <imgPG></imgPG>
                <categoriesPG>
                <category1PG></category1PG>
                <category2PG></category2PG>
                <category3PG></category3PG>
                </categoriesPG>
                <keywordsPG><![CDATA[]]></keywordsPG>
                <explicitPG>no</explicitPG>
                <authorPG>
                    <namePG></namePG>
                    <emailPG></emailPG>
                </authorPG>
                <fileInfoPG>
                    <size>27.22</size>
                    <duration>19:49</duration>
                    <bitrate>192</bitrate>
                    <frequency>44100</frequency>
                </fileInfoPG>
            </episode>
        </PodcastGenerator>
"@
         $xmlContent.PodcastGenerator.episode.titlePG."#cdata-section"= $podcastTitle
         $xmlContent.PodcastGenerator.episode.shortdescPG."#cdata-section"= $podcast.subtitle
         $xmlContent.PodcastGenerator.episode.longdescPG."#cdata-section"=$description
         $podcastLen=(Get-Item $safeFilePath).Length / 1MB
         $podcastLenRounded=[math]::Round($podcastLen,2)
         $podcastLenLanguage = New-Object System.Globalization.CultureInfo("en-US")

         $xmlContent.PodcastGenerator.episode.fileInfoPG.size=$podcastLenRounded.ToString($podcastLenLanguage)

         $podcastTimeLen=New-TimeSpan -Start $podcast.startISO -End $podcast.endISO
         $xmlContent.PodcastGenerator.episode.fileInfoPG.duration=$podcastTimeLen.Minutes.ToString()+":"+$podcastTimeLen.Seconds.ToString()
         $xmlContent.Save($xmlFullPath)
     }

     #Create a new Podcast feed
     $feedPath=$xmlPath + "/" + "feed.xml"
     Write-Verbose("creating new feed.xml and safe it to "+$feedPath+"...")
     $feedSkeletonDescription=($podcast.pressRelease -replace '<[^>]+>','')
     $feedSkeletonTitle=($podcast.title -replace '<[^>]+>','')
     $feedSkeletonSubtitle=($podcast.description -replace '<[^>]+>','')
     [xml]$feedSkeleton=@"
<?xml version="1.0" encoding="utf-8"?>
        <!-- generator="Podcast Generator 2.6" -->
        <rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xml:lang="de" version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
                <title>OE1 - Help</title>
                <link>$feedUrlHome/</link>
                <atom:link href="$feedUrlHome/feed.xml" rel="self" type="application/rss+xml" />
                <description>$feedSkeletonDescription</description>
                <generator>get-oe1Podcast.ps1 Generator 1.0 </generator>
                <lastBuildDate>Tue, 24 May 2017 16:56:19 +0200</lastBuildDate>
                <language>de</language>
                <copyright>(c) ORF</copyright>
                <itunes:image href="http://test.mitschke.at/podcasthome/images/itunes_image.png" />
                <image>
                <url>http://test.mitschke.at/podcasthome/images/itunes_image.png</url>
                <title>$feedSkeletonTitle</title>
                <link>$feedUrlHome/</link>
                </image>
                <itunes:summary>$feedSkeletonDescription</itunes:summary>
                <itunes:subtitle>$feedSkeletonSubtitle</itunes:subtitle>
                <itunes:author>ORF</itunes:author>
                <itunes:owner>
                <itunes:name>ORF</itunes:name>
                <itunes:email>nospam@orf.at</itunes:email>
                </itunes:owner>
                <itunes:explicit>no</itunes:explicit>

                <itunes:category text="Arts"></itunes:category>



        </channel>
 </rss>
"@
     $feedSkeleton.Save($feedPath)

     ##Load this newly created feed
     [xml]$feedContent = Get-Content ($feedPath)

     $episodeXMLFiles=Get-ChildItem ($xmlPath+"/*.xml") -Exclude feed.xml | Sort-Object -Descending -property LastWriteTime
     foreach($episodeXMLFile in $episodeXMLFiles)
     {
         #Clear-Variable $xmlContent
         [xml]$xmlContent=Get-Content ($episodeXMLFile.FullName)

         ##Einfügen des neuen Podcasts in den Feed

         $feedContentItem=$feedContent.rss.channel.AppendChild($feedContent.CreateElement("item"))
         ##Title
         $feedContentItemTitle=$feedContentItem.AppendChild($feedContent.CreateElement("title"))
         $feedContentItemTitle.AppendChild($feedContent.CreateTextNode($xmlContent.PodcastGenerator.episode.titlePG."#cdata-section"));
         ##itunes:subtitle
         $feedContentItemSubtitle=$feedContentItem.AppendChild($feedContent.CreateElement("itunes","subtitle"))
         $feedContentItemSubtitle.AppendChild($feedContent.CreateTextNode($xmlContent.PodcastGenerator.episode.shortdescPG."#cdata-section"));
         ##itunes:summary
         $feedContentItemItunesSummary=$feedContentItem.AppendChild($feedContent.CreateElement("itunes","summary"))
         $feedContentItemItunesSummary.AppendChild($feedContent.CreateCDataSection(($xmlContent.PodcastGenerator.episode.longdescPG."#cdata-section")));
         ##description
         $feedContentItemDescription=$feedContentItem.AppendChild($feedContent.CreateElement("description"))
         $feedContentItemDescription.AppendChild($feedContent.CreateCDataSection($xmlContent.PodcastGenerator.episode.longdescPG."#cdata-section"));
         ##link
         $feedContentItemLink=$feedContentItem.AppendChild($feedContent.CreateElement("link"))
         $feedContentItemLink.AppendChild($feedContent.CreateTextNode(($feedUrlHome+"/"+$episodeXMLFile.BaseName+".mp3")));
         ##enclosure url
         $feedContentItemEnclosureUrl=$feedContentItem.AppendChild($feedContent.CreateElement("enclosure"))
         $feedContentItemEnclosureUrl.SetAttribute(“url”,($feedUrlHome+"/"+$episodeXMLFile.BaseName+".mp3"));
         $feedContentItemEnclosureUrl.SetAttribute(“length”,(([float]$xmlContent.PodcastGenerator.episode.fileInfoPG.size)*1MB));
         $feedContentItemEnclosureUrl.SetAttribute(“type”,”audio/mpeg”);
         ##guid
         $feedContentItemTitle=$feedContentItem.AppendChild($feedContent.CreateElement("guid"))
         $feedContentItemTitle.AppendChild($feedContent.CreateTextNode(($feedUrlHome+"/"+$episodeXMLFile.BaseName+".mp3")));
         ##itunes:duration
         $feedContentItemItunesDuration=$feedContentItem.AppendChild($feedContent.CreateElement("itunes","duration"))
         $feedContentItemItunesDuration.AppendChild($feedContent.CreateTextNode($xmlContent.PodcastGenerator.episode.fileInfoPG.duration));
         ##author
         $feedContentItemAuthor=$feedContentItem.AppendChild($feedContent.CreateElement("author"))
         $feedContentItemAuthor.AppendChild($feedContent.CreateTextNode("ORF"));
         ##itunes:author
         $feedContentItemItunesAuthor=$feedContentItem.AppendChild($feedContent.CreateElement("itunes","author"))
         $feedContentItemItunesAuthor.AppendChild($feedContent.CreateTextNode("ORF"));
         ##itunes:explicit
         $feedContentItemItunesExplicit=$feedContentItem.AppendChild($feedContent.CreateElement("itunes","explicit"))
         $feedContentItemItunesExplicit.AppendChild($feedContent.CreateTextNode("no"));
         ##pubdate
         $feedContentItemPubDate=$feedContentItem.AppendChild($feedContent.CreateElement("pubdate"))
         $feedContentItemPubDate.AppendChild($feedContent.CreateTextNode($episodeXMLFile.CreationTime.DateTime));
     }

     $feedContent.Save($feedPath)
     Remove-Item ($tmpFile)

}


}



