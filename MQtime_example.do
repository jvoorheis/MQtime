insheet using "/home/john/Dropbox/econ stuff/Google Maps/MQtime/statecap.csv", clear
rename v1 address
rename v2 city
rename v3 state
rename v4 address1
rename v5 city1
rename v6 state1
gen capitol = address + "," + city + "," + state
MQgeocode in 1/10, address(capitol) outaddress(coords)
list

rename capitol capitol_origin
gen capitol_destination = address1 + "," + city1 + "," + state1
keep capitol_origin capitol_destination
list

MQtime, start_add(capitol_origin) end_add(capitol_destination)
drop capitol_origin capitol_destination
list


