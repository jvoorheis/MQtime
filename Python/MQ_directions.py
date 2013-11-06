# -*- coding: utf-8 -*-
"""
Created on Wed Sep 25 12:12:24 2013

@author: john

Cleanup: This collects just the mapquest driving query functions in a single 
script.

"""

import urllib, json, time

def timeToHours(time_str):
    """
    This takes a string in HH:MM:SS format, and returns the time in minutes
    """
    time_split = time_str.split(":")
    return int(time_split[0])*60.0 + int(time_split[1]) + int(time_split[2])/60.0

def mapquest_distance(address1, address2, api_key):
    URL2 = "http://www.mapquestapi.com/directions/v1/route?key="+api_key+"&from="+address1+"&to="+address2+"&callback=renderNarrative&outFormat='json'"
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
        return jsonResponse

def hybrid_distance_full(address1, address2, api_key):
    """
    This function queries the Mapquest API for driving directions between two 
    addresses (assumed to be cleaned before input.) The function first attempts 
    to use the OpenStreetmaps API, which has much more permissive TOU, and then, 
    if OSM cannot calculate a route, it queries the Licensed Mapquest service.
    Either query yields a JSON object, from which we can extract the driving 
    distance. The function also returns the service from which the driving
    distance is obtained - which is important for proper attribution, 
    and for extremely large jobs, since the licensed data has a daily query 
    limit of 5000. For now, the extraction of the relevant bits of the JSON 
    object are done outside of the function call.

    """
    
    URL2 = "http://open.mapquestapi.com/directions/v1/route?key="+api_key+"&from="+address1+"&to="+address2+"&callback=renderNarrative&outFormat='json'"
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
                return [{"route":{"distance":"Timeout Error", "formattedTime":"Timeout Error"}}, "OSM"]
    elif 'Unable to calculate route.'  in jsonResponse['info']['messages']:
        alt_try = mapquest_distance(address1, address2, api_key)
        return [alt_try, "Mapquest"]
    else:
        return [jsonResponse, "OSM"]

