*Version 0.5 of mqgeocode (updated 12/29/14)
*normal geocodes working, more or less
*Fixed running count display error.
*Uses the Mapquest OpenStreetMaps API with HERE Maps API as a backup.
*This uses the INSHEETJSON library to parse the API requests.
*Any mistakes are my own.
*Written by John Voorheis, University of Oregon
*Email jlv@uoregon.edu with any comments or concerns

program mqgeocode
	version 10
	syntax [if] [in], address(string) [outaddress(string) lat(string) long(string)  here_id(string) here_code(string)]
	cap which insheetjson
	if _rc == 111 noisily dis as text "Insheetjson.ado not found, please ssc install insheetjson"
	if _rc == 111 assert 1==2
	cap which libjson.mlib
	if _rc == 111 noisily dis as text "Libjson.mlib not found, please ssc install libjson"
	if _rc == 111 assert 1==2
	if ("`here_id'" != "" & "`here_code'"=="") {
	noisily dis as text "To Use your personal HERE API credentials, must specify both here_id() and here_code()"
	assert 1==2
	}
	if ("`here_id'" == "" & "`here_code'"!=""){
	 noisily dis as text "To Use your personal HERE API credentials, must specify both here_id() and here_code()"
	assert 1==2
	}
	local cnt = _N
	local options = "&outFormat='json'"
	local mapquestcount = 0
	quietly{
	/*if "`address'" == "" & ("`lat'" == "" | "`long'" == "") {
		noisily di "You must specify address() or lat() and long()"
		blah=""
	}*/
	if "`outaddress'"=="" local outaddress = "coords"
	cap drop geocode_marker
	cap gen geocode_marker = 0
	if "`if'" ~= ""{
		replace geocode_marker = 1 `if'
	}
	else{
		replace geocode_marker = 1
	}
	if "`lat'"!="" & "`long'"!="" & "`address'"==""{
		*Note: reverse geocoding is deprecated as of version 0.4
		cap gen str240 `outaddress' = ""
		local osm_url1 = "http://open.mapquestapi.com/geocoding/v1/reverse?key=Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz&location="
		if "`in'" == ""{
		forval i=1/`cnt'{
			local lat_temp = `lat'[`i']
			local long_temp = `long'[`i']
			local coords = string(`lat_temp')+","+string(`long_temp')
			local api_request = "`osm_url1'" + "`coords'" + "`options'"
			cap gen str240 temp_street = ""
			cap gen str240 temp_city = ""
			cap gen str240 temp_state = ""
			cap gen str240 temp_post = ""
			cap gen str240 temp_quality = ""
			cap gen str240 temp_county = ""
			insheetjson temp_street temp_city temp_state temp_post temp_quality temp_county using "`api_request'", columns("results:1:locations:1:street" "results:1:locations:1:adminArea5"  "results:1:locations:1:adminArea3" "results:1:locations:1:postalCode" "results:1:locations:1:geocodeQuality" "results:1:locations:1:adminArea4") flatten replace

			local tc = temp_city in 1
			if temp_quality == "ADDRESS"{
				if "`tc'"	== "" in 1{
					local temp_address = temp_street + ", " + temp_county + ", " + temp_state + " " +temp_post in 1
				}
				else{
					local temp_address = temp_street + ", " + temp_city + ", " + temp_state + " " +temp_post in 1
				}
			}
			else if temp_quality[1] == "ZIP"{ 
				local temp_address = temp_city + ", " + temp_state + " " +  temp_post in 1
			}
			else{
				local temp_address = temp_city + ", " + temp_state + " " +temp_post in 1
			}
			replace `outaddress' = "`temp_address'" in `i'
			cap drop temp_street
			cap drop temp_city
			cap drop temp_state
			cap drop temp_post
			cap drop temp_quality
			cap drop temp_county
			noisily disp "Observation " `i' " of " `cnt' " geocoded."
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
				local lat_temp = `lat'[`i']
				local long_temp = `long'[`i']
				local coords = string(`lat_temp')+","+string(`long_temp')
				local api_request = "`osm_url1'" + "`coords'" + "`options'"
				cap gen str240 temp_street = ""
				cap gen str240 temp_city = ""
				cap gen str240 temp_state = ""
				cap gen str240 temp_post = ""
				cap gen str240 temp_quality = ""
				cap gen str240 temp_county = ""
				insheetjson temp_street temp_city temp_state temp_post temp_quality temp_county using "`api_request'", columns("results:1:locations:1:street" "results:1:locations:1:adminArea5"  "results:1:locations:1:adminArea3" "results:1:locations:1:postalCode" "results:1:locations:1:geocodeQuality" "results:1:locations:1:adminArea4") flatten replace

				local tc = temp_city in 1
				if temp_quality == "ADDRESS"{
					if "`tc'"	== "" in 1{
						local temp_address = temp_street + ", " + temp_county + ", " + temp_state + " " +temp_post in 1
					}
					else{
						local temp_address = temp_street + ", " + temp_city + ", " + temp_state + " " +temp_post in 1
					}
				}
				else if temp_quality[1] == "ZIP"{ 
					local temp_address = temp_city + ", " + temp_state + " " +  temp_post in 1
				}
				else{
					local temp_address = temp_city + ", " + temp_state + " " +temp_post in 1
				}
				replace `outaddress' = "`temp_address'" in `i'
				cap drop temp_street
				cap drop temp_city
				cap drop temp_state
				cap drop temp_post
				cap drop temp_quality
				cap drop temp_county
				noisily disp "Observation " `i' " of " `cnt' " geocoded."
			}
		
		
		
			}
		}
		else if "`lat'"=="" & "`long'"=="" & "`address'"!=""{
			cap gen str240 geocode_service = ""
			cap gen str240 `outaddress' = ""
			local osm_url1 = "http://open.mapquestapi.com/geocoding/v1/address?key=Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz&location="
			local here_url1 = "http://geocoder.api.here.com/6.2/geocode.json?searchtext="
			if "`here_id'"!="" & "`here_code'"!=""{
				local api_key = "&app_id=" + "`here_id'" + "&app_code=" + "`here_code'"
			}
			else{
				local api_key = "&app_id=Ts7OEhI9RqLTIGB8LNUt&app_code=47FfXAKAm3-Kio9AqSVwvg"
			}
			
			if "`in'" == ""{
				forval i=1/`cnt'{
					if geocode_marker[`i'] == 1{
					local coords = `address'[`i']
					local api_request = "`osm_url1'" + "`coords'" + "`options'"
					local api_request = subinstr("`api_request'", " ", "%20", .)
					cap gen str240 temp_lat=""
					cap gen str240 temp_lng=""
					insheetjson temp_lat temp_lng using "`api_request'", columns("results:1:locations:1:latLng:lat" "results:1:locations:1:latLng:lng") flatten replace
					if temp_lat=="[]"{
						local coords = subinstr("`coords'", ".", "", .)
						local api_request = "`here_url1'" + "`coords'" + "`api_key'"
						local api_request = subinstr("`api_request'", " ", "%20", .)
						insheetjson temp_lat temp_lng using "`api_request'", columns("Response:View:1:Result:1:Location:DisplayPosition:Latitude" "Response:View:1:Result:1:Location:DisplayPosition:Longitude") flatten replace
						local temp_address = temp_lat + "," + temp_lng in 1
						replace `outaddress' = "`temp_address'" in `i'
						cap drop temp_lat
						cap drop temp_lng
						local mapquestcount = `mapquestcount' + 1 
						replace geocode_service = "HERE Maps" in `i'
						noisily disp "Observation " `i' " of " `cnt' " geocoded using the HERE Maps API. (`mapquestcount' total requests this run)"
					}
					else{
						local temp_address = temp_lat + "," + temp_lng in 1
						replace `outaddress' = "`temp_address'" in `i'
						cap drop temp_lat
						cap drop temp_lng
						replace geocode_service = "OSM" in `i'
						noisily disp "Observation " `i' " of " `cnt' " geocoded using the OpenStreetMaps API."
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
				forval i = `2'{
					if geocode_marker[`i'] == 1{
					local coords = `address'[`i']

					local api_request = "`osm_url1'" + "`coords'" + "`options'"
					local api_request = subinstr("`api_request'", " ", "%20", .)
					cap gen str240 temp_lat = ""
					cap gen str240 temp_lng = ""
					
					insheetjson temp_lat temp_lng using "`api_request'", columns("results:1:locations:1:latLng:lat" "results:1:locations:1:latLng:lng") flatten replace
					if temp_lat=="[]"{
						local coords = subinstr("`coords'", ".", "", .)
						local api_request = "`here_url1'" + "`coords'" + "`api_key'"
						local api_request = subinstr("`api_request'", " ", "%20", .)
												insheetjson temp_lat temp_lng using "`api_request'", columns("Response:View:1:Result:1:Location:DisplayPosition:Latitude" "Response:View:1:Result:1:Location:DisplayPosition:Longitude") flatten replace
						local temp_address = temp_lat + "," + temp_lng in 1
						replace `outaddress' = "`temp_address'" in `i'
						cap drop temp_lat
						cap drop temp_lng
						local mapquestcount = `mapquestcount' + 1 
						replace geocode_service = "HERE Maps" in `i'
						noisily disp "Observation " `i' " of " `cnt' " geocoded using the HERE Maps API. (`mapquestcount' total requests this run)"
					}
					else{
						local temp_address = temp_lat + "," + temp_lng in 1
						replace `outaddress' = "`temp_address'" in `i'
						cap drop temp_lat
						cap drop temp_lng
						replace geocode_service = "OSM" in `i'
						noisily disp "Observation " `i' " of " `cnt' " geocoded using the OpenStreetMaps API."
					}
				}
				}
			}
		}
		
	}
	cap drop geocode_marker
	
end

