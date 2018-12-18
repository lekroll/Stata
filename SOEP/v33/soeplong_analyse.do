/* Rekodierung des GBE-SOEP LS-Datensatzes */
/* L. Kroll */

set more off
capture clear all
capture log close
set linesize 90

// Initialisierung
cd "C:\Dokumente und Einstellungen\krolll\Desktop\Datenreport 2013\"
global soepldir "C:\Kroll\LokaleDaten\Daten\soepnew\stata_de_v28l\"
tempfile workdata
tempfile tempdata
global gewichtung "phrf"

// Datensatz öffnen
use soep_trend_full.dta if syear>=1994 & phrf>0 & age>=18 , clear
svyset [pw=phrf]

// Outcomes
gen sah = 100*inlist(GZmehm1,4,5) if GZmehm1<.
gen adipositas = GVadi*100 if GVadi<.
gen raucherd = (GVrauchen==1)*100 if GVrauchen<.
gen keinsport = (GVsport==4)*100 if GVsport<.
gen oftschmerz = inlist(GZschmerzen,1,2)*100 if GZschmerzen<.
gen hohebelastung = dABgGes==3 if dABgGes<.

gen ABallg_hoch = 100*(dABgGes==3) if dABgGes<.
gen ABphy_hoch =  100*(dABgPhy==3) if dABgPhy<.
gen ABpsy_hoch =  100*(dABgPsy==3) if dABgPsy<.
gen ABzuf_niedrig = 100*(plh0173<5) if plh0173 >0 & plh0173 <.

// Darstellung aufhübschen
lab def SDerwerbsstatus 1 Langzeitarbeitslos 2 Kurzzeitarbeitslos , modify
gen zeitraum:zeitraum = floor((sy-1994)/5)*5 +1994
lab def zeitraum 1994 "1994-98" 1999 "1999-03" 2004 "2004-08" 2009 "2009-13"
lab var zeitraum "Zeitraum"

gen age_45:age_45  = 1+(age>=45) if age<.
lab var age_45 "Alter"
lab def age_45 1 "18-44" 2 "45+"

replace SDstdlgrp = 2 if SDstdlgrp==3
lab def SDstdlgrp 2 "66%-149%" , modify
replace pgtatzt = . if pgtatzt <0

// Log
log using datenreport_2013_soep.smcl , smcl replace

// Ergebnisse
di as text "Daten für " as result "Tab.6 2010/11"
di as text "+++++++++++++++++++++++++++++++++++++++++++"
table SDerwerb agegrp sex if sy==2010 & agegrp<4  [aw=phrf] , row c(mean raucherd) format(%3,1f) col concise
by sex, sort : logit raucherd c.age ib5.SDerwerb if sy==2010 & agegrp<4  [pw=phrf] , nolog or
table SDerwerb agegrp sex if sy==2010 & agegrp<4  [aw=phrf] , row c(mean adipositas) format(%3,1f) col concise
by sex, sort : logit adipositas c.age ib5.SDerwerb if sy==2010 & agegrp<4  [pw=phrf] , nolog or
table SDerwerb agegrp sex if sy==2011 & agegrp<4  [aw=phrf] , row c(mean keinsport) format(%3,1f) col concise
by sex, sort : logit keinsport c.age ib5.SDerwerb if sy==2011 & agegrp<4   [pw=phrf] , nolog or

di as text "Daten für " as result "Tab.7 1994-2011"
di as text "+++++++++++++++++++++++++++++++++++++++++++"
table zeitraum SDoek sex if inlist(agegrp,2,3)  [aw=phrf] , row col c(mean sah) format(%3,1f) concise 
sum sy if sah<. , mean
gen trend = (syear-r(min))/(r(max)-r(min))
logit sah c.age c.trend##ib3.SDoekgr if inlist(agegrp,2,3) & sex==1  [pw=phrf] , or nolog
di "Veränderung in der Armutsrisikogruppe (Männer):"
lincom trend+1.SDoekgrp#c.trend  , or
di "Veränderung in der mittleren Einkommensgruppe (Männer):"
lincom trend+2.SDoekgrp#c.trend  , or
logit sah c.age c.trend##ib3.SDoekgr if inlist(agegrp,2,3) & sex==2  [pw=phrf] , or nolog
di "Veränderung in der Armutsrisikogruppe (Frauen):"
lincom trend+1.SDoekgrp#c.trend  , or
di "Veränderung in der mittleren Einkommensgruppe (Frauen):"
lincom trend+2.SDoekgrp#c.trend  , or

di as text "Daten für " as result "Abb.1 2011"
di as text "+++++++++++++++++++++++++++++++++++++++++++"
table agegrp SDoek sex if sy==2011 [aw=phrf] , row col c(mean sah) format(%3,1f) concise
by sex, sort : logit sah c.age ib3.SDoek if sy==2011 [pw=phrf] , nolog or

di as text "Daten für " as result "Abb.2 2010"
di as text "+++++++++++++++++++++++++++++++++++++++++++"
table agegrp SDoek sex if sy==2010 [aw=phrf] , row col c(mean adipos) format(%3,1f) concise
by sex, sort : logit adipos c.age ib3.SDoek if sy==2010 [pw=phrf] , nolog or

di as text "Daten für " as result "Abb.5 2010"
di as text "+++++++++++++++++++++++++++++++++++++++++++"
table agegrp SDcasmin sex if sy==2010 [aw=phrf] , row col c(mean oftschm) format(%3,1f) concise
by sex, sort : logit oftschm c.age ib3.SDcasmin if sy==2010 [pw=phrf] , nolog or

di as text "Daten für " as result "Abb.06 2011"
di as text "+++++++++++++++++++++++++++++++++++++++++++"
gr bar (mean)  ABphy_hoch ABpsy_hoch ABzuf_niedrig  if inlist(sy,2011) & inlist(agegrp,2,3) [aw=phrf] , ///
     over(SDstdlgr) by(sex , note("")) blabel(bar, format(%3,1f) color(black)) ///
	 legend(order(1 "Hohe körperliche Belastung" 2 "Hohe psychosoziale Belastung" 3 "Geringe Arbeitszufriedenheit")) ytitle("Anteil in %")
by sex, sort: logit ABphy_hoch c.age c.pgtatzt ib4.SDstdlgrp [pw=phrf] if inlist(sy,2011) , or nolog
by sex, sort: logit ABpsy_hoch c.age c.pgtatzt ib4.SDstdlgrp [pw=phrf] if inlist(sy,2011) , or nolog
by sex, sort: logit ABzuf_niedrig c.age c.pgtatzt ib4.SDstdlgrp [pw=phrf] if inlist(sy,2011) , or nolog


di as text "Daten für " as result "Abb.10 2010"
di as text "+++++++++++++++++++++++++++++++++++++++++++"

* Schmerzen
table SDmigback age_45  sex if sy==2010 [aw=phrf] , row col c(mean oftschm) format(%3,1f) concise
table SDmigart age_45 sex if sy==2010 [aw=phrf] , row col c(mean oftschm) format(%3,1f) concise
by sex, sort : logit oftschm c.age ib2.SDmigback if sy==2010 [pw=phrf] , nolog or
by sex, sort : logit oftschm c.age ib1.SDmigart  if sy==2010 [pw=phrf] , nolog or
* Rauchen
table SDmigback age_45  sex if sy==2010 [aw=phrf] , row col c(mean oftschm) format(%3,1f) concise
table SDmigart age_45 sex if sy==2010 [aw=phrf] , row col c(mean oftschm) format(%3,1f) concise
by sex, sort : logit oftschm c.age ib2.SDmigback if sy==2010 [pw=phrf] , nolog or
by sex, sort : logit oftschm c.age ib2.SDmigart  if sy==2010 [pw=phrf] , nolog or

di as text "Daten für " as result "Abb.13 1999-2010"
di as text "+++++++++++++++++++++++++++++++++++++++++++"
sum sy if raucherd<. , mean
replace trend = (syear-r(min))/(r(max)-r(min))
table sy SDcasmin sex if inlist(agegrp,2,3) [aw=phrf] , row col c(mean raucherd) format(%3,1f) concise
logit raucherd  c.age c.trend##ib3.SDcasmin  if inlist(agegrp,2,3) & sex==1  [pw=phrf] , or nolog
di "Veränderung in der unteren Bildungsgruppe (Männer):"
lincom trend+1.SDcasmin #c.trend  , or
di "Veränderung in der mittleren Bildungsgruppe (Männer):"
lincom trend+2.SDcasmin #c.trend  , or
logit raucherd c.age c.trend##ib3.SDcasmin  if inlist(agegrp,2,3) & sex==2  [pw=phrf] , or nolog
di "Veränderung in der unteren Bildungsgruppe  (Frauen):"
lincom trend+1.SDcasmin #c.trend  , or
di "Veränderung in der mittleren Bildungsgruppe (Frauen):"
lincom trend+2.SDcasmin #c.trend  , or

di as text "Daten für " as result "Abb.14 1994-2011"
di as text "+++++++++++++++++++++++++++++++++++++++++++"
sum sy if keinsport<. , mean
replace trend = (syear-r(min))/(r(max)-r(min))
table sy SDcasmin sex if inlist(agegrp,2,3)  [aw=phrf] , row col c(mean keinsport) format(%3,1f) concise
logit keinsport  c.age c.trend##ib3.SDcasmin  if inlist(agegrp,2,3) & sex==1  [pw=phrf] , or nolog
di "Veränderung in der unteren Bildungsgruppe (Männer):"
lincom trend+1.SDcasmin #c.trend  , or
di "Veränderung in der mittleren Bildungsgruppe (Männer):"
lincom trend+2.SDcasmin #c.trend  , or
logit keinsport c.age c.trend##ib3.SDcasmin  if inlist(agegrp,2,3) & sex==2  [pw=phrf] , or nolog
di "Veränderung in der unteren Bildungsgruppe  (Frauen):"
lincom trend+1.SDcasmin #c.trend  , or
di "Veränderung in der mittleren Bildungsgruppe (Frauen):"
lincom trend+2.SDcasmin #c.trend  , or

log close

log2html datenreport_2013_soep.smcl , title("Analysen SOEP für Datenreport") linesize(90)  bold   replace
copy datenreport_2013_soep.html "T:\FG27-Kuntz-Lampert\Datenreport 2013\Archiv\" , replace
