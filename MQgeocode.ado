*Version 0.1 of MQgeocode (updated 10/30/13)
*Only does reverse geocodes currently
*Uses the Mapquest OpenStreetMaps API
*This uses the INSHEETJSON library to parse the API requests.
*Any mistakes are my own.
*Written by John Voorheis, University of Oregon
*Email jlv@uoregon.edu with any comments or concerns

program MQgeocode
	version 11
	syntax [in], [address(string) lat(string) long(string) outaddress(string)]
	local cnt = _N
	local options = "&outFormat='json'"
	if "`lat'"!="" & "`long'"!="" & "`address'"==""{
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
		}
		
		
		
		}
		}
	
end

