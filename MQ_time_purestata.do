*Version 0.1.1 of MQtime
*Uses the Mapquest OpenStreetMaps API, with the commercial mapquest service as backup.
*Written by John Voorheis, University of Oregon
*Email jlv@uoregon.edu with and comments or concerns
program MQtime
	version 12
	syntax, start_x(string) start_y(string) end_x(string) end_y(string)
	quietly {
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
		local cnt = _N
		forval i = 1/`cnt'{
			local sx = `start_x'[`i']
			local sy = `start_y'[`i']
			local ex = `end_x'[`i'] 
			local ey = `end_y'[`i']
			local start_coords = string(`sy')+","+string(`sx')
			local end_coords = string(`ey')+","+string(`ex')
			local api_request = "http://open.mapquestapi.com/directions/v1/route?key=Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz&from=" + "`start_coords'" + "&to=" + "`end_coords'"+"&outFormat='json'"
			local mp_api_request = "http://www.mapquestapi.com/directions/v1/route?key=Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz&from=" + "`start_coords'" + "&to=" + "`end_coords'"+"&outFormat='json'"
			cap gen str240 temp_time = ""
			cap gen str240 temp_distance = ""
			cap gen str240 errorcode = ""
			cap gen str240 temp_fuel = ""
			insheetjson temp_time temp_distance errorcode using "`api_request'", columns("route:formattedTime" "route:distance" "info:statuscode") flatten replace
			*noisily: display `time1'
			if errorcode[1] != "0" & errorcode[1] != "400" & errorcode[1] != "500"{
				insheetjson temp_time temp_distance errorcode using "`mp_api_request'", columns("route:formattedTime" "route:distance" "info:statuscode") flatten replace
				replace service = "Mapquest" in `i'			
			}
			else if errorcode[1] == "400" {
				replace travel_time = . in `i'
				replace distance = . in `i'
				replace service = "No Cars Go"
			}
			else if errorcode[1] == "500{
				sleep 500
				insheetjson temp_time temp_distance errorcode temp_fuel using "`api_request'", columns("route:formattedTime" "route:distance" "info:statuscode" "route:fuelUsed") flatten replace
			}
			else {
				local time1 = temp_time in 1
				split temp_time, p(":") generate(blah)
				local time1 = (1/60)*real(blah3) + real(blah2) + 60*real(blah1) in 1
				replace travel_time = `time1' in `i'
				replace distance = real(temp_distance[1]) in `i'
				replace fuelUsed = real(temp_fuel[1]) in `i'
				cap drop temp_time temp_distance blah1 blah2 blah3 errorcode
				noisily: di "Processed " `i' " of " `cnt'
			}
		}
	}
end
