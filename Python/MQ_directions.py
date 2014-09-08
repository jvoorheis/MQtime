# -*- coding: utf-8 -*-
"""
Created on Wed Sep 25 12:12:24 2013

@author: john

Cleanup: This collects just the mapquest driving query functions in a single 
script.

"""

import urllib, json, time, csv

datafile=""

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

api_key = "Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz"

filelength = len(addresses_merged)
hybrid_distance_try = [0 for i in range(filelength)]
driving_time = ["" for i in range(filelength)]
services = ["" for i in range(filelength)]
nonzeroind = 0
mapquest_requests = sum([1 if service=="Mapquest" else 0 for service in services]) 




with open(datafile, 'r') as csvfile:
    f = csv.reader(csvfile, delimiter=",")
    addresses = [row for row in f]
dist_ind = len(addresses[0])
driv_ind = len(addresses[0])+1
serv_ind = len(addresses[0])+1
addresses[0].append("Distance")
addresses[0].append("DrivingTime")
addresses[0].append("DirectionsService")
    
for i in range(filelength):
    gd_full = hybrid_distance_full(str(addresses[i][0]), str(addresses[i][1]), api_key)
    addresses[nonzeroind+i][dist_ind] = gd_full[0]['route']['distance']
    addresses[nonzeroind+i][driv_ind] = gd_full[1]
    addresses[nonzeroind+i][serv_ind] = timeToHours(gd_full[0]['route']['formattedTime'])
    if gd_full[1] == "Mapquest":
        mapquest_requests +=1
    if (nonzeroind+i)%20==0:
        print [nonzeroind+i, gd_full[0]['route']['distance'], 
               gd_full[0]['route']['formattedTime'], mapquest_requests, timeToHours(gd_full[0]['route']['formattedTime'])]
    #Dump the lists of distances and services once every hundred iterations
    if (nonzeroind+i)%100 == 0:
        f3 = open("driving_dump.json", "wb")
        json.dump(addresses, f3)
        f3.close()
        
with open("distances_full.csv", 'wb') as csvfile:
    spamwriter = csv.writer(csvfile, delimiter=',')
    for i in range(len(addresses)):
        spamwriter.writerow(addresses[i])