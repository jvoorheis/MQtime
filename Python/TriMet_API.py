import urllib
from xml.etree import ElementTree as ET

api_key = "22C4454D868CE515575838DCC"
address1, address2 = "835 SW 2nd Ave, Portland, OR", "630 NE 23rd Ave, Portland, OR"
y1, x1 = 45.529302, -122.659348
y2, x2 = 45.529843, -122.681235
date = "6-9-2014"
time1 = "7:00 AM"

            
def PDXTransitTimeAddress(address1, address2, date, time, api_key):
    URL1 = "http://developer.trimet.org/ws/V1/trips/tripplanner?fromPlace="+address1
    URL1 = URL1 + "&toPlace="+address2+"&Date="+date+"&Time="+time+"&appID="+api_key
    PDXresponse = urllib.urlopen(URL1)
    root = ET.parse(PDXresponse).getroot()
    items = root.find("{http://maps.trimet.org/maps/model/xml}itineraries")
    trips = [{"distance": i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}distance").text,
    "totalTime": i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}duration").text,
    "transfers":i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}numberOfTransfers").text,
    "walkTime":i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}walkingTime").text,
    "transitTime":i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}transitTime").text} for i in items]
    return trips
    
def PDXTransitTimeCoords(x1, y1,x2, y2, date, time, api_key):
    URL1 = "http://developer.trimet.org/ws/V1/trips/tripplanner?fromCoord="+str(x1)+","+str(y1)
    URL1 = URL1 + "&toCoord="+str(x2)+","+str(y2)+"&Date="+date+"&Time="+time+"&appID="+api_key
    #print(URL1)
    PDXresponse = urllib.urlopen(URL1)
    root = ET.parse(PDXresponse).getroot()
    items = root.find("{http://maps.trimet.org/maps/model/xml}itineraries")
    trips = [{"distance": i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}distance").text,
    "totalTime": i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}duration").text,
    "transfers":i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}numberOfTransfers").text,
    "walkTime":i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}walkingTime").text,
    "transitTime":i.find("{http://maps.trimet.org/maps/model/xml}time-distance").find("{http://maps.trimet.org/maps/model/xml}transitTime").text} for i in items]
    return trips
    
print PDXTransitTimeAddress(address1, address2, date, time1, api_key)
print PDXTransitTimeCoords(x1, y1, x2, y2, date, time1, api_key)