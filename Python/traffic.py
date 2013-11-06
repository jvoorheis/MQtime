# -*- coding: utf-8 -*-
"""
Created on Wed Nov  6 11:31:10 2013

@author: john

Modified Functions to generate driving time based on realtime traffic, and get 
transit travel time. Provides functions for both the Mapquest and Google Maps API.
"""
import urllib, json, time

def mapquest_distance(address1, address2, api_key, traffic=False, timeofday="08:00", day=2, mode="fastest"):
    URL2 = "http://www.mapquestapi.com/directions/v1/route?key="+api_key+"&from="+address1+"&to="+address2+"&callback=renderNarrative&outFormat='json'&routeType="+mode
    if traffic==True:
        URL2 = URL2+"&useTraffic=true&timeType=2&dateType="+str(day)+"&localTime="+str(timeofday)
    mapquestResponse = urllib.urlopen(URL2)
    jsonResponse = json.loads(mapquestResponse.read())
    if jsonResponse['info']['statuscode']==500:
    #Basically, if the OSM API craps out on us, we do the equivalent of 
    #wait 5 sec. and then reload. If 10 successive requests fail, return 
    #an error.
        bad_requests = 0        
        while True:
            bad_requests+=1
            time.sleep(5)
            mapquestResponse = urllib.urlopen(URL2)
            jsonResponse = json.loads(mapquestResponse.read())
            if jsonResponse['info']['statuscode']!=500:
                break
            elif bad_requests >=10:
                return {"route":{"distance":"Timeout Error", "formattedTime":"Timeout Error"}}
    else:            
        return 
        

def getDistance(address1, address2, mode="driving"):
    """
    Based on current time/date at runtime. Need to add option to take string 
    time as input, convert to Unix Epoch time, and then add this to API request URL
    """
    URL2 = "http://maps.googleapis.com/maps/api/directions/json?origin="+address1+"&destination="+address2+"&sensor=false"+"&mode="+mode+"&departure_time="+str(int(time.time()))
    googleResponse = urllib.urlopen(URL2)
    jsonResponse = json.loads(googleResponse.read())
    return jsonResponse


add3 = "4575 W 11th Ave, Eugene, OR 97402"
add4 = "910 Willamette St, Eugene, OR 97401"

try3_gm = getDistance(add3, add4, mode="transit")
try4_gm = getDistance(add3, add4)
print try3_gm['routes'][0][u'legs'][0][u'duration']['value']
print try4_gm['routes'][0][u'legs'][0][u'duration']['value']


