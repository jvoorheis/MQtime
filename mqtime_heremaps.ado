*Version 0.5 of mqtime (updated 12/29/14)
*Uses the Mapquest OpenStreetMaps API, with the HERE Maps API as backup
*This nods towards TRAVELTIME, written by Adam Ozimek and Daniel Miles in syntax, and very loosely in structure. 
*This uses the INSHEETJSON library to parse the API requests.
*Any mistakes are my own.
*Written by John Voorheis, University of Oregon
*Email jlv@uoregon.edu with any comments or concerns


program mqtime
	version 11
	syntax [in] [if], [start_x(string) start_y(string) end_x(string) end_y(string) start_add(string) end_add(string) here_id(string) here_code(string) km mode(string) time(string)]
	*di "`if'"
	qui {
		cap which insheetjson
		if _rc == 111 noisily dis as text "Insheetjson.ado not found, please ssc install insheetjson"
		if _rc == 111 assert 1==2
		cap which libjson.mlib
		if _rc == 111 noisily dis as text "Libjson.mlib not found, please ssc install libjson"
		if _rc == 111 assert 1==2
		if ("`start_x'" !="" & "`start_add'"!="") | ("`start_y'"!="" & "`start_add'"!="") {
			noisily display "Cannot combine options start_add() and start_x() or start_y()" 
			noisily error 198
		}
			if ("`here_id'" != "" & "`here_code'"=="") {
	noisily dis as text "To Use your personal HERE API credentials, must specify both here_id() and here_code()"
noisily error 198
	}
	if ("`here_id'" == "" & "`here_code'"!=""){
	 noisily dis as text "To Use your personal HERE API credentials, must specify both here_id() and here_code()"
noisily error 198
	}
		if ("`start_x'" =="" & "`start_add'"=="") | ("`start_y'"=="" & "`start_add'"==""){
		noisily di "You must specify either x,y coordinates or an string address for the origin"
		noisily error 198
		}
		if ("`end_x'" =="" & "`end_add'"=="") | ("`end_y'"=="" & "`end_add'"==""){
		noisily di "You must specify either x,y coordinates or an string address for the origin"
		noisily error 198
		}
		cap gen travel_time = .
		cap gen distance = .
		cap gen fuelUsed = .
		cap gen service = "OSM"
		local mapquestcount = 0
		local osm_url1 = "http://open.mapquestapi.com/directions/v1/route?key=Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz&from="
		
		if "`here_id'" == "" & "`here_code'"==""{
			local mq_url1 = "http://route.api.here.com/routing/7.2/calculateroute.json?app_id=Ts7OEhI9RqLTIGB8LNUt&app_code=47FfXAKAm3-Kio9AqSVwvg"
		}
		else{
			local mq_url1 = "http://route.api.here.com/routing/7.2/calculateroute.json?app_id=" + "`here_id'" + "&app_code=" + "`here_code'"
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
				local options = "&outFormat='json'&narrativeType=none&routeType=multimodal&timeType=1"
			}
			else{
				local options = "&outFormat='json'&narrativeType=none&unit=k&routeType=multimodal&timeType=1"
			}
		}
		cap drop marker
		cap gen marker = 0
		if "`if'" ~= ""{
			replace marker = 1 `if'
		}
		else{
			replace marker = 1
		}
		if "`in'" == "" {
		local cnt = _N
		
		forval i = 1/`cnt'{
			if marker[`i'] == 1{
			if "`start_x'"!="" & "`start_add'"==""{
				local sx = `start_x'[`i']
				local sy = `start_y'[`i']
				local start_coords = string(`sy')+","+string(`sx')
			}
			else if "`start_x'"=="" & "`start_add'"!=""{
				local temp1 = `start_add'[`i']
				local start_coords = subinstr("`temp1'", " ", "%20", .)
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
			*local mp_api_request = "`mq_url1'" + "`start_coords'" + "&to=" + "`end_coords'"+"`options'"
		
			cap gen str240 temp_time = ""
			cap gen str240 temp_distance = ""
			cap gen str240 errorcode = ""
			cap gen str240 temp_fuel = ""
			cap insheetjson temp_time temp_distance errorcode temp_fuel using "`api_request'", columns("route:formattedTime" "route:distance" "info:statuscode" "route:fuelUsed") flatten replace
			if _rc!=0 | temp_time==""{
			if "`start_add'"~=""{
				mqgeocode in `i'/`i', address("`start_add'") outaddress(temp_add_start)
				local start_coords = temp_add_start[`i']
				if geocode_service[`i'] == "HERE Maps"{
					local mapquestcount = `mapquestcount' + 1
				}
				cap drop temp_add_start geocode_service
			}
			if "`end_add'"~=""{
				mqgeocode in `i'/`i', address("`end_add'") outaddress(temp_add_end)
				local end_coords = temp_add_end[`i']
				if geocode_service[`i'] == "HERE Maps"{
					local mapquestcount = `mapquestcount' + 1
				}
				cap drop temp_add_end geocode_service
			}
			local mp_api_request = "`mq_url1'" + "&waypoint0=geo!" + "`start_coords'" + "&waypoint1=geo!" + "`end_coords'"+"&mode=fastest;car;&representation=overview"
			insheetjson temp_time temp_distance using "`mp_api_request'", columns("response:route:1:summary:travelTime" "response:route:1:summary:distance") flatten replace
				replace service = "HERE Maps" in `i'
				local mapquestcount = `mapquestcount' + 1
				*local time1 = temp_time in 1
				replace travel_time = (1/60)*real(temp_time[1]) in `i'
				if "`km'" == ""{
				replace distance = real(temp_distance[1])/1609.3 in `i'
				}
				else{
				replace distance = real(temp_distance[1])/1000 in `i'
				}
				replace fuelUsed = .  in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt' " using the HERE Maps API. (`mapquestcount' total requests this run)"		
			}

			else{
			if errorcode[1] == "601" | errorcode[1] == "602" | errorcode[1] == "603" | errorcode[1] == "610" {
				if "`start_add'"~=""{
					mqgeocode in `i'/`i', address("`start_add'") outaddress(temp_add_start)
					local start_coords = temp_add_start[`i']
					if geocode_service[`i'] == "HERE Maps"{
						local mapquestcount = `mapquestcount' + 1
					}
					cap drop temp_add_start geocode_service
				}
				if "`end_add'"~=""{
					mqgeocode in `i'/`i', address("`end_add'") outaddress(temp_add_end)
					local end_coords = temp_add_end[`i']
					if geocode_service[`i'] == "HERE Maps"{
						local mapquestcount = `mapquestcount' + 1
					}
					cap drop temp_add_end geocode_service
				}
				local mp_api_request = "`mq_url1'" + "&waypoint0=geo!" + "`start_coords'" + "&waypoint1=geo!" + "`end_coords'"+"&mode=fastest;car;&representation=overview"
				cap insheetjson temp_time temp_distance using "`mp_api_request'", columns("response:route:1:summary:travelTime" "response:route:1:summary:distance") flatten replace
				local mapquestcount = `mapquestcount' + 1
				if _rc !="0" {
					replace travel_time = . in `i'
					replace distance = . in `i'
					replace service = "Route Failed" in `i' 
					noisily: di "Processed " `i' " of " `cnt' " - Route Failed using the HERE Maps API. (`mapquestcount' total requests this run)"
				}
				else{
				replace service = "HERE Maps" in `i'

				*local time1 = temp_time in 1
				replace travel_time = (1/60)*real(temp_time[1]) in `i'
				if "`km'" == ""{
				replace distance = real(temp_distance[1])/1609.3 in `i'
				}
				else{
				replace distance = real(temp_distance[1])/1000 in `i'
				}
				replace fuelUsed = .  in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt' " using the HERE Maps API. (`mapquestcount' total requests this run)"	
				}			
			}
			else if errorcode[1] == "400" {
				replace travel_time = . in `i'
				replace distance = . in `i'
				replace service = "Route Failed" in `i'
				noisily: di "Processed " `i' " of " `cnt' " (Route Impossible)"
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
				noisily: di "Processed " `i' " of " `cnt' " using the OpenStreetMaps API."	
			}

			else {
				local time1 = temp_time in 1
				split temp_time, p(":") generate(blah)
				local time1 = (1/60)*real(blah3) + real(blah2) + 60*real(blah1) in 1
				replace travel_time = `time1' in `i'
				replace distance = real(temp_distance[1]) in `i'
				replace fuelUsed = real(temp_fuel[1]) in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt' " using the OpenStreetMaps API."	
			}
		}
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
			if marker[`i'] == 1{ 
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
			*local mp_api_request = "`mq_url1'" + "`start_coords'" + "&to=" + "`end_coords'"+"`options'"
			cap gen str240 temp_time = ""
			cap gen str240 temp_distance = ""
			cap gen str240 errorcode = ""
			cap gen str240 temp_fuel = ""
			cap insheetjson temp_time temp_distance errorcode temp_fuel using "`api_request'", columns("route:formattedTime" "route:distance" "info:statuscode" "route:fuelUsed") flatten replace
			*noisily di errorcode[1]
			if _rc!=0 | temp_time==""{
			*di "`mp_api_request'"
			if "`start_add'"~=""{
				mqgeocode in `i'/`i', address("`start_add'") outaddress(temp_add_start)
				local start_coords = temp_add_start[`i']
				if geocode_service[`i'] == "HERE Maps"{
					local mapquestcount = `mapquestcount' + 1
				}
				cap drop temp_add_start geocode_service
			}
			if "`end_add'"~=""{
				mqgeocode in `i'/`i', address("`end_add'") outaddress(temp_add_end)
				local end_coords = temp_add_end[`i']
				if geocode_service[`i'] == "HERE Maps"{
					local mapquestcount = `mapquestcount' + 1
				}
				cap drop temp_add_end geocode_service
			}
			local mp_api_request = "`mq_url1'" + "&waypoint0=geo!" + "`start_coords'" + "&waypoint1=geo!" + "`end_coords'"+"&mode=fastest;car;&representation=overview"
			insheetjson temp_time temp_distance using "`mp_api_request'", columns("response:route:1:summary:travelTime" "response:route:1:summary:distance") flatten replace
				replace service = "HERE Maps" in `i'
				local mapquestcount = `mapquestcount' + 1
				*local time1 = temp_time in 1
				replace travel_time = (1/60)*real(temp_time[1]) in `i'
				if "`km'" == ""{
				replace distance = real(temp_distance[1])/1609.3 in `i'
				}
				else{
				replace distance = real(temp_distance[1])/1000 in `i'
				}
				replace fuelUsed = .  in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt' " using the HERE Maps API. (`mapquestcount' total requests this run)"		
			}

			else{
			if errorcode[1] == "601" | errorcode[1] == "602" | errorcode[1] == "603" | errorcode[1] == "610" {
				if "`start_add'"~=""{
					mqgeocode in `i'/`i', address("`start_add'") outaddress(temp_add_start)
					local start_coords = temp_add_start[`i']
					if geocode_service[`i'] == "HERE Maps"{
						local mapquestcount = `mapquestcount' + 1
					}
					cap drop temp_add_start geocode_service
				}
				if "`end_add'"~=""{
					mqgeocode in `i'/`i', address("`end_add'") outaddress(temp_add_end)
					local end_coords = temp_add_end[`i']
					if geocode_service[`i'] == "HERE Maps"{
						local mapquestcount = `mapquestcount' + 1
					}
					cap drop temp_add_end geocode_service
				}
				local mp_api_request = "`mq_url1'" + "&waypoint0=geo!" + "`start_coords'" + "&waypoint1=geo!" + "`end_coords'"+"&mode=fastest;car;&representation=overview"
				cap insheetjson temp_time temp_distance using "`mp_api_request'", columns("response:route:1:summary:travelTime" "response:route:1:summary:distance") flatten replace
				local mapquestcount = `mapquestcount' + 1
				if _rc !="0" {
					replace travel_time = . in `i'
					replace distance = . in `i'
					replace service = "Route Failed" in `i' 
					noisily: di "Processed " `i' " of " `cnt' " - Route Failed using the HERE Maps API. (`mapquestcount' total requests this run)"
				}
				else{
				replace service = "HERE Maps" in `i'

				*local time1 = temp_time in 1
				replace travel_time = (1/60)*real(temp_time[1]) in `i'
				if "`km'" == ""{
				replace distance = real(temp_distance[1])/1609.3 in `i'
				}
				else{
				replace distance = real(temp_distance[1])/1000 in `i'
				}
				replace fuelUsed = .  in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt' " using the HERE Maps API. (`mapquestcount' total requests this run)"	
				}			
			}
			else if errorcode[1] == "400" {
				replace travel_time = . in `i'
				replace distance = . in `i'
				replace service = "No Cars Go" in `i'
				noisily: di "Processed " `i' " of " `cnt' " (Route Impossible)"
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
				noisily: di "Processed " `i' " of " `cnt' " using the OpenStreetMaps API."	
			}
			else {
				local time1 = temp_time in 1
				split temp_time, p(":") generate(blah)
				local time1 = (1/60)*real(blah3) + real(blah2) + 60*real(blah1) in 1
				replace travel_time = `time1' in `i'
				replace distance = real(temp_distance[1]) in `i'
				replace fuelUsed = real(temp_fuel[1]) in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode temp_fuel
				noisily: di "Processed " `i' " of " `cnt' " using the OpenStreetMaps API."	
			}
			}
			}
			}
		}
	cap drop marker
		
	}
end
