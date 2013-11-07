*Version 0.3.1 of MQtime (updated 10/30/13)
*Uses the Mapquest OpenStreetMaps API, with the commercial mapquest service as backup
*This nods towards TRAVELTIME, written by Adam Ozimek and Daniel Miles in syntax, and very loosely in structure. 
*This uses the INSHEETJSON library to parse the API requests.
*Any mistakes are my own.
*Written by John Voorheis, University of Oregon
*Email jlv@uoregon.edu with any comments or concerns


program MQtime
	version 11
	syntax [in], [start_x(string) start_y(string) end_x(string) end_y(string) start_add(string) end_add(string)api_key(string) km mode(string)]
	qui {
		cap which insheetjson
		if _rc == 111 noisily dis as text "Insheetjson.ado not found, please ssc install insheetjson"
		if _rc == 111 assert 1==2
		cap which libjson.mlib
		if _rc == 111 noisily dis as text "Libjson.mlib not found, please ssc install libjson"
		if _rc == 111 assert 1==2
		cap gen travel_time = .
		cap gen distance = .
		cap gen fuelUsed = .
		cap gen service = "OSM"
		if "`api_key'"==""{
			local osm_url1 = "http://open.mapquestapi.com/directions/v1/route?key=Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz&from="
			local mq_url1 = "http://www.mapquestapi.com/directions/v1/route?key=Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz&from="
		}
		else if "`api_key'"~=""{
			local osm_url1 = "http://open.mapquestapi.com/directions/v1/route?key=" + "`api_key'" + "&from="
			local mq_url1 = "http://www.mapquestapi.com/directions/v1/route?key=" + "`api_key'" + "&from="
		}
		if ("`mode'"==""){
			if ("`km'"==""){
				local options = "&outFormat='json'&narrativeType=none"
			}
			else{
				local options = "&outFormat='json'&narrativeType=none&unit=k"
			}
		}
		else if ("`mode'"=="walking"){
			if ("`km'"==""){
				local options = "&outFormat='json'&narrativeType=none&routeType=pedestrian"
			}
			else{
				local options = "&outFormat='json'&narrativeType=none&unit=k&routeType=pedestrian"
			}
		}
		else if ("`mode'"=="bicycle"){
			if ("`km'"==""){
				local options = "&outFormat='json'&narrativeType=none&routeType=bicycle"
			}
			else{
				local options = "&outFormat='json'&narrativeType=none&unit=k&routeType=bicycle"
			}
		}
		else if ("`mode'"=="transit"){
			if ("`km'"==""){
				local options = "&outFormat='json'&narrativeType=none&routeType=multimodal"
			}
			else{
				local options = "&outFormat='json'&narrativeType=none&unit=k&routeType=multimodal"
			}
		} 
		if "`in'" == ""{
		local cnt = _N
		
		forval i = 1/`cnt'{
			if "`start_x'"!="" & "`start_add'"==""{
				local sx = `start_x'[`i']
				local sy = `start_y'[`i']
				local start_coords = string(`sy')+","+string(`sx')
			}
			else if "`start_x'"=="" & "`start_add'"!=""{
				local temp1 = `start_add'[`i']
				local start_coords = subinstr("`temp1'", " ", "%20", .)
			}
			else{
				noisily display "You must specify either x,y coordinates or an string address for both origin and destination"
				assert 1==2
			}
			if "`end_x'"!="" & "`end_add'"==""{
				local ex = `end_x'[`i'] 
				local ey = `end_y'[`i']
				local end_coords = string(`ey')+","+string(`ex')
			}
			else if "`end_x'"=="" & "`end_add'"!=""{
				local temp1 = `end_add'[`i']
				local end_coords = subinstr("`temp1'", " ", "%20", .)
			}
			else{
				noisily display "You must specify either x,y coordinates or an string address for both origin and destination"
				assert 1==2
			}
			
			local api_request = "`osm_url1'" + "`start_coords'" + "&to=" + "`end_coords'"+"`options'"
			local mp_api_request = "`mq_url1'" + "`start_coords'" + "&to=" + "`end_coords'"+"`options'"
		
			cap gen str240 temp_time = ""
			cap gen str240 temp_distance = ""
			cap gen str240 errorcode = ""
			cap gen str240 temp_fuel = ""
			*noisily di "`api_request'"
			insheetjson temp_time temp_distance errorcode temp_fuel using "`api_request'", columns("route:formattedTime" "route:distance" "info:statuscode" "route:fuelUsed") flatten replace
			
			*noisily di errorcode[1]
			if errorcode[1] == "601" | errorcode[1] == "602" | errorcode[1] == "603" | errorcode[1] == "610" {
				insheetjson temp_time temp_distance errorcode temp_fuel using "`mp_api_request'", columns("route:formattedTime" "route:distance" "info:statuscode" "route:fuelUsed") flatten replace
				if errorcode[1] == "400" {
					replace travel_time = . in `i'
					replace distance = . in `i'
					replace service = "Route Failed" in `i'
					noisily: di "Processed " `i'
				}
				else{
				replace service = "Mapquest" in `i'
				local time1 = temp_time in 1
				split temp_time, p(":") generate(blah)
				local time1 = (1/60)*real(blah3) + real(blah2) + 60*real(blah1) in 1
				replace travel_time = `time1' in `i'
				replace distance = real(temp_distance[1]) in `i'
				replace fuelUsed = real(temp_fuel[1]) in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt'		
				}	
			}
			else if errorcode[1] == "400" {
				replace travel_time = . in `i'
				replace distance = . in `i'
				replace service = "Route Failed" in `i'
				noisily: di "Processed " `i' " of " `cnt'
			}
			else if errorcode[1] == "500"{
				sleep 500
				insheetjson temp_time temp_distance errorcode temp_fuel using "`api_request'", columns("route:formattedTime" "route:distance" "info:statuscode" "route:fuelUsed") flatten replace
				local time1 = temp_time in 1
				split temp_time, p(":") generate(blah)
				local time1 = (1/60)*real(blah3) + real(blah2) + 60*real(blah1) in 1
				replace travel_time = `time1' in `i'
				replace distance = real(temp_distance[1]) in `i'
				replace fuelUsed = real(temp_fuel[1]) in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt'
			}
			else {
				local time1 = temp_time in 1
				split temp_time, p(":") generate(blah)
				local time1 = (1/60)*real(blah3) + real(blah2) + 60*real(blah1) in 1
				replace travel_time = `time1' in `i'
				replace distance = real(temp_distance[1]) in `i'
				replace fuelUsed = real(temp_fuel[1]) in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt'
			}
		}
		}
		else{
		tokenize `in'
		*This is a hacky and terrible way of doing things, I'll clean up later.
		cap gen placeholder = ""
		replace placeholder = "`2'" in 1
		split placeholder, p("/")
		local cnt = placeholder2[1]
		drop placeholder placeholder1 placeholder2
		*
		forval i = `2'{ 
			if "`start_x'"!="" & "`start_add'"==""{
				local sx = `start_x'[`i']
				local sy = `start_y'[`i']
				local start_coords = string(`sy')+","+string(`sx')
			}
			else if "`start_x'"=="" & "`start_add'"!=""{
				local temp1 = `start_add'[`i']
				local start_coords = subinstr("`temp1'", " ", "%20", .)
			}
			else{
				noisily display "You must specify either x,y coordinates or an string address for both origin and destination"
				assert 1==2
			}
			if "`end_x'"!="" & "`end_add'"==""{
				local ex = `end_x'[`i'] 
				local ey = `end_y'[`i']
				local end_coords = string(`ey')+","+string(`ex')
			}
			else if "`end_x'"=="" & "`end_add'"!=""{
				local temp1 = `end_add'[`i']
				local end_coords = subinstr("`temp1'", " ", "%20", .)
			}
			else{
				noisily display "You must specify either x,y coordinates or an string address for both origin and destination"
				assert 1==2
			}
			
			local api_request = "`osm_url1'" + "`start_coords'" + "&to=" + "`end_coords'"+ "`options'"
			*noisily di "`api_request'"
			local mp_api_request = "`mq_url1'" + "`start_coords'" + "&to=" + "`end_coords'"+"`options'"
			cap gen str240 temp_time = ""
			cap gen str240 temp_distance = ""
			cap gen str240 errorcode = ""
			cap gen str240 temp_fuel = ""

			insheetjson temp_time temp_distance errorcode temp_fuel using "`api_request'", columns("route:formattedTime" "route:distance" "info:statuscode" "route:fuelUsed") flatten replace
			*noisily di errorcode[1]
			if errorcode[1] == "601" | errorcode[1] == "602" | errorcode[1] == "603" | errorcode[1] == "610" {
				insheetjson temp_time temp_distance errorcode temp_fuel using "`mp_api_request'", columns("route:formattedTime" "route:distance" "info:statuscode" "route:fuelUsed") flatten replace
				if errorcode[1] !="0" {
					replace travel_time = . in `i'
					replace distance = . in `i'
					replace service = "Route Failed" in `i'
					noisily: di "Processed " `i' " of " `cnt'
				}
				else{
				replace service = "Mapquest" in `i'
				local time1 = temp_time in 1
				split temp_time, p(":") generate(blah)
				local time1 = (1/60)*real(blah3) + real(blah2) + 60*real(blah1) in 1
				replace travel_time = `time1' in `i'
				replace distance = real(temp_distance[1]) in `i'
				replace fuelUsed = real(temp_fuel[1]) in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt'		
				}			
			}
			else if errorcode[1] == "400" {
				replace travel_time = . in `i'
				replace distance = . in `i'
				replace service = "No Cars Go" in `i'
				noisily: di "Processed " `i' " of " `cnt'
			}
			else if errorcode[1] == "500"{
				sleep 500
				insheetjson temp_time temp_distance errorcode temp_fuel temp_fuel using "`api_request'", columns("route:formattedTime" "route:distance" "info:statuscode" "route:fuelUsed") flatten replace
				local time1 = temp_time in 1
				split temp_time, p(":") generate(blah)
				local time1 = (1/60)*real(blah3) + real(blah2) + 60*real(blah1) in 1
				replace travel_time = `time1' in `i'
				replace distance = real(temp_distance[1]) in `i'
				replace fuelUsed = real(temp_fuel[1]) in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt'
			}
			else {
				local time1 = temp_time in 1
				split temp_time, p(":") generate(blah)
				local time1 = (1/60)*real(blah3) + real(blah2) + 60*real(blah1) in 1
				replace travel_time = `time1' in `i'
				replace distance = real(temp_distance[1]) in `i'
				replace fuelUsed = real(temp_fuel[1]) in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt'
			}
			}
		}
		
	}
end
