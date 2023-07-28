********************************************************************************
* Analyse des déterminants des exportations des pays de l'UEMOA dans le marché 
* africain
********************************************************************************
clear all
cd "C:\Users\MPlusPlus\Desktop\Memoire-traitement\donnees"


* Gravity_V202211
use Gravity_V202211.dta
keep year country_id_o country_id_d distcap contig diplo_disagreement scaled_sci_2021 comlang_off comcol col45 legal_old_o legal_old_d legal_new_o legal_new_d comrelig pop_o pop_d gdp_o gdp_d gdpcap_o gdpcap_d gatt_o gatt_d wto_o wto_d eu_o eu_d fta_wto rta_coverage tradeflow_comtrade_o tradeflow_comtrade_d tradeflow_baci manuf_tradeflow_baci tradeflow_imf_o tradeflow_imf_d 

gen id_exp_imp = country_id_o + "_" + country_id_d
tostring year, gen(str_year)
gen id_exp_annee = country_id_o + "_" + str_year
save donneestemporaire, replace

* CEPII Geo data
use dist_cepii.dta, clear
gen id_exp_imp = iso_o + "_" + iso_d
keep id_exp_imp smctry
merge 1:m id_exp_imp id_exp_imp using donneestemporaire.dta 
drop _merge
gen id_exp = country_id_o
save donneestemporaire, replace


* geo cepii data 
use geo_cepii.dta, clear
keep landlocked iso3
duplicates drop
gen id_exp = iso3
merge 1:m id_exp id_exp using donneestemporaire.dta 
drop _merge
save donneestemporaire, replace

* WGI data
use wgidataset.dta, clear

keep code year vae pve gee rqe rle cce
tostring year, gen(str_year)
gen id_exp_annee = code + "_" + str_year

merge 1:m id_exp_annee id_exp_annee using donneestemporaire.dta 
drop _merge
gen id_exp_imp_annee = country_id_o + "_" +  country_id_d + "_" + str_year
save donneestemporaire, replace

* RTA data
use rta_20221214.dta, clear
tostring year, gen(str_year)
gen id_exp_imp_annee =  exporter + "_" + importer + "_" + str_year
merge 1:m id_exp_imp_annee id_exp_imp_annee using donneestemporaire.dta 
drop _merge exporter importer str_year id*
save donneestemporaire, replace

*pays africains comme importateurs
keep if country_id_d== "DZA" | country_id_d== "AGO" | country_id_d== "BEN" | country_id_d== "BWA" | country_id_d== "BFA" | country_id_d== "BDI" | country_id_d== "CMR" | country_id_d== "CPV" | country_id_d== "CAF" | country_id_d== "TCD" | country_id_d== "COM" | country_id_d== "COG" | country_id_d== "COD" | country_id_d== "CIV" | country_id_d== "DJI" | country_id_d== "EGY" | country_id_d== "GNQ" | country_id_d== "ERI" | country_id_d== "ETH" | country_id_d== "GAB" | country_id_d== "GMB" | country_id_d== "GHA" | country_id_d== "GIN" | country_id_d== "GNB" | country_id_d== "KEN" | country_id_d== "LSO" | country_id_d== "LBR" | country_id_d== "LBY" | country_id_d== "MDG" | country_id_d== "MLI" | country_id_d== "MWI" | country_id_d== "MRT" | country_id_d== "MUS" | country_id_d== "MAR" | country_id_d== "MOZ" | country_id_d== "NAM" | country_id_d== "NER" | country_id_d== "NGA" | country_id_d== "RWA" | country_id_d== "STP" | country_id_d== "SEN" | country_id_d== "SYC" | country_id_d== "SLE" | country_id_d== "SOM" | country_id_d== "ZAF" | country_id_d== "SDN" | country_id_d== "SWZ" | country_id_d== "TZA" | country_id_d== "TGO" | country_id_d== "TUN" | country_id_d== "UGA" | country_id_d== "ZMB" | country_id_d== "ZWE"


* pays de l'UEMOA comme exportateurs
keep if country_id_o=="BFA" | country_id_o=="BEN" | country_id_o=="CIV" | country_id_o=="GNB" | country_id_o=="MLI" | country_id_o=="NER" | country_id_o=="SEN" | country_id_o=="TGO"

save basedetravail, replace


********************************************************************************
clear all
cd "C:\Users\MPlusPlus\Desktop\Memoire-traitement\donnees"
use basedetravail.dta, clear

gen trade = tradeflow_comtrade_o
tabstat trade, stats(N min mean max) by(country_id_o)
nmissing trade

replace trade = 0 if trade == .
tabstat trade, stats(N min mean max) by(country_id_o)
nmissing trade

drop if year<2000
tabstat trade, stats(N min mean max) by(country_id_o)

// * structure de panel
// egen countrypair=group(country_id_o country_id_d)
// isid countrypair year
// xtset countrypair year

* transformation logarithmique
gen lgdp_o = ln(gdp_o)
gen lgdp_d = ln(gdp_d)
gen ldist = ln(distcap)
gen lflow = ln(trade)

gen exporter = country_id_o
gen importer = country_id_d

* STATA commands to create importer- and exporter-time fixed effects:
egen exp_time = group(exporter year)
tabulate exp_time, generate(EXPORTER_TIME_FE)
egen imp_time = group(importer year)
tabulate imp_time, generate(IMPORTER_TIME_FE)

* STATA commands to compute country-pair fixed effects:
* Asymmetric country-pair fixed effects
egen pair_id = group(exporter importer) 
tabulate pair_id, generate(PAIR_FE)

gen RTA = rta
