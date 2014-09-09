clear all
do "/home/john/Dropbox/econ stuff/Google Maps/mqtime/mqtime.ado"
do "/home/john/Dropbox/econ stuff/Google Maps/mqtime/mqgeocode.ado"
insheet using "/home/john/Dropbox/econ stuff/Google Maps/mqtime/CA_polluters2012.csv", clear
cap mqtime
mqtime if cot==0 in 1/20, start_add(fzip) end_add(fcity)
mqgeocode if cot==0 in 1/20, address("address") outaddress("coords")
cap mqgeocode
mqtime
*mqgeocode in 1/10, address("address") outaddress("coords")
*mqgeocode, address("address") outaddress("coords")


insheet using "/home/john/Dropbox/econ stuff/Google Maps/mqtime/statecap.csv", clear
rename v1 address
rename v2 city
rename v3 state
rename v4 address1
rename v5 city1
rename v6 state1
gen capitol = address + "," + city + "," + state
*mqgeocode in 1/2, address(capitol) outaddress(coords)
*list  address city state
*list capitol coords

rename capitol capitol_origin
gen capitol_destination = address1 + "," + city1 + "," + state1
keep capitol_origin capitol_destination
list

mqtime, start_add(capitol_origin) end_add(capitol_destination)
drop capitol_origin capitol_destination
list



