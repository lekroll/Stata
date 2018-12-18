/* Rekodierung des SOEP LS-Datensatzes */
/* Autor: L. Kroll 	 */
/* Datum: 20170817 	 */
/* QS: keine für v32 */

// Initialisierung
tempfile workdata
tempfile tempdata
set more off

// Datensatz öffnen
use $soeplong , clear 

// Determinanten
//===============

gen start = .

gen tsphrf = w11101
lab var tsphrf "Gewichtungsfaktor ohne 1st Subsample (f. Zeitreihen)"
svyset hid [pw=tsphrf]

lab var syear "Jahr" 
lab var sex "Geschlecht"
lab def sex 1 "Männer" 2 "Frauen", modify

* Altersgruppen
gen age = syear-gebjahr if gebj>0 & gebj<.
lab var age "Alter"

gen agegrp: agegrp = 1 if inrange(age,18,29)
	replace agegrp = 2 if inrange(age,30,44)
	replace agegrp = 3 if inrange(age,45,64)
	replace agegrp = 4 if inrange(age,65,150)
	lab def agegrp 1 "18-29" 2 "30-44" 3 "45-64" 4 "65+"
lab var agegrp "Alter"

* Bildung
gen SDcasmin :nmh =  1 if inrange(pgcasmin,0,3)
replace  SDcasmin =  2 if inrange(pgcasmin,4,7)
replace  SDcasmin =  3 if inrange(pgcasmin,8,9)
lab def nmh 1 "niedrig" 2 "mittel" 3 "hoch"
lab var SDcasmin "Bild (Casmin)"

* Beruf
gen SDbstatus:nmh  = .
lab var SDbstatus "Berufsstatus (ISEI, Quintile)"
sum syear , mean
local minyear = r(min)
local maxyear = r(max)
forvalues syear = `minyear'(1)`maxyear' {
di "`syear'"
	xtile pgisei_`syear' = pgisei if syear==`syear' [aw=phrf] , nq(5)
	replace SDbstatus = 1 if pgisei_`jahr' ==1
	replace SDbstatus = 2 if inrange(pgisei_`jahr',2,4)
	replace SDbstatus = 3 if pgisei_`jahr' ==5
	drop pgisei_`syear' 
	}

gen SDautono:nmh = pgautono if pgautono>0 & pgautono<.
replace SDautono = SDautono -1 if 	SDautono >1 & SDautono <.
replace SDautono  = SDautono -1 if 	SDautono ==4
lab var SDautono "Autonomie im Beruf"

* Bruttostundenlohn (* 4.345 Wochen pro Monat)
gen SDstdlohn = pglabgro/(4.345*pgvebzeit) if (pglabgro>0) & (pgvebzeit>0) & (pglabgro<.)  & (pgvebzeit<.) 
lab var SDstdlohn "Bruttostundenlohn in EUR" 

gen SDstdlpos :SDstdlpos = .
lab var SDstdlpos "Position Bruttostdlohn"
sum syear , mean
local minyear = r(min)
local maxyear = r(max)
forvalues syear = `minyear'(1)`maxyear' {
	quietly: sum SDstdlohn [aw=phrf] if (syear==`syear') & (SDstdlohn >0)  , ///
		detail
	replace SDstdlpos = SDstdlohn /r(p50) if (syear==`syear') & (SDstdlohn >0) & (SDstdlohn <.)
	}

gen SDstdlgrp:SDstdlgrp  = 1 if float(SDstdlpos)<0.66
replace SDstdlgrp  		 = 2 if float(SDstdlpos)>=0.66 & float(SDstdlpos)<1.00 
replace SDstdlgrp  		 = 3 if float(SDstdlpos)>=1.00 & float(SDstdlpos)<1.50 
replace SDstdlgrp  		 = 4 if float(SDstdlpos)>=1.50 & float(SDstdlpos)<.
lab var SDstdlgrp "Lohnposition"
lab def SDstdlgrp 1 "<66%" 2 "66%-99%" 3 "100-149" 4 "150% u.m."

* ILO Labour Force Status
gen SDilo:SDilo  = 1 if inrange(pglfs,1,5)
replace SDilo = 2 if inlist(pglfs,6,12,8)
replace SDilo = 3 if inlist(pglfs,9,10,11)
replace SDilo = 4 if (inrange(age,0,14) | age >= 75) & !inlist(SDilo,1,2)

lab def SDilo  1 "Nichtewerbstätig" 2 "Erwerbslos"  3 "Erwerbstätig" 4 "Nichterwerbspersonen (Alter 0-14/75+)" , modify
lab var SDilo "ILO Labour Force Status"

* Arbeitslosigkeit 
gen SDerwerbsstatus:SDerwerbsstatus  = .
lab var SDerwerbsstatus "Erwerbsstatus"
lab def SDerwerbsstatus  5 "Sicher beschäftigt" 4 "prekär beschäftigt" ///
	3 "Arbeitslos" 2 "Arbeitslos (ALG I)" 1 "Arbeitslos (ALG II)"
replace SDerwerbsstatus  = 5 if inlist(pgemplst,1,2,4) 
replace SDerwerbsstatus  = 4 if inlist(pgemplst,1,2,4) & (inlist(plh0042,1) ///
	| ((alg2>0) & (alg2<.)) ) // Sorgen Alo-Sicherheit od. ALG-2 (Aufstocker)
replace SDerwerbsstatus  = 3 if inlist(pgstib,12)  & (syear<2006)
replace SDerwerbsstatus  = 2 if inlist(pgstib,12)  & (syear>=2006)
replace SDerwerbsstatus  = 1 if inlist(pgstib,12)  & (alg2>0) & (alg2<.) 

gen SDalo:SDalo  = 0 if inlist(pgemplst,1,2,3)
  replace SDalo  = 1 if inlist(SDerwerbsstatus,1,2,3)
  replace SDalo  = 2 if inlist(pgemplst,5,6) & SDalo  >=.
  lab def SDalo  0 "Erwerbstätig" 1 "Arbeitslos" 2 "Nichterwerbstätig"
  lab var SDalo "Arbeitslosigkeit"

* Einkommen
* =========
// HH-Größe
gen hhsize_all = d11106 if d11106 >0 &  d11106 <.
lab var hhsize_all "Number of hh members"

gen hhsize_u15 = h11101 if h11101 >=0 &  h11101 <.
lab var hhsize_u15 "Number of hh members 0-14"

// Äquivalenzeinkommen
/* Nach DIW/BMAS-Vorgabe: 0-13, Einkommen aus Vorjahr, Bedarf aus aktuellem Jahr, 
Gesundheit aus aktuellem Jahr. */
gen bedarfsgewicht = (1 + 0.5*(d11106-h11101-1) + 0.3*h11101) 

// Haushaltsnettoeinkommen in EUR inkl. Miete ohne Fälle ohne Einkommen
    gen SDeinkz  = .
replace SDeinkz  = (i11102 + i11105)/12 
replace SDeinkz  = . if (i11102 + i11105)<=0
lab var SDeinkz   "HH-Nettoeinkommen in Euro im Vorjahr (inkl. Wohneigentum)"

// Asset flows (Firmenwagen etc.)
* replace SDeinkz  = SDeinkz  + i11104 if i11104>0 & i11104<. 

// Vorjahreseinkommen
gen SDeqinc = (SDeinkz)  / bedarfsgewicht 
lab var SDeqinc  "Äquivalenzeinkommen in EUR inkl. Wohneigentum (Vorjahreseinkommen)"

* Armutsrisikoquote, Grenze und Armutsluecke
/* Anpassung 27.04.2017: Für die Mortalitätsanalysen sollen alle Probanden 
Werte zum Einkommen erhalten, unabhängig davon, ob Sie zur ARB-Population gehören. 
Darum wird der touse Filter bei der Wertezuweisung gelöscht. Dies wirkt sich aber nicht
auf den Arbeitsdatensatz aus, da diese Fälle dort trotzdem herausgefiltert werden. */
gen touse = (tsphrf >0)  & (hgowner < 5)
sum syear , mean
local minyear = r(min)
local maxyear = r(max)
gen SDincpos  = .
lab var SDincpos  "Relative Einkommensposition"
gen SDarmgrenze = .
lab var SDarmgrenze  "Armutsgrenze (60% des Medianeinkommens)"
gen SDarmluecke = .
lab var SDarmluecke  "Armutslücke (Differenz Einkommen-Armutsgrenze) in %"
forvalues syear = `minyear'(1)`maxyear' {
di "`syear'"
	quietly: sum SDeqinc if (syear==`syear')  & (touse==1)  [aw=tsphrf] , detail
		replace SDincpos    =  (SDeqinc /r(p50))    if (syear==`syear') // & (touse==1) 
		replace SDarmgrenze =  (r(p50)*.60)         if (syear==`syear') // & (touse==1)
		replace SDarmluecke =  (((r(p50)*.60)-SDeqinc)/(r(p50)*.60))*100 if (syear==`syear') & (SDeqinc < SDarmgrenze) // & (touse==1)  
		} 
compress SDincpos 
gen 	SDoekgrp:SDoekgrp 	= 1 if float(SDincpos)<0.60
replace SDoekgrp 			= 2 if float(SDincpos)>=0.60 & float(SDincpos)<1.50 
replace SDoekgrp 			= 3 if float(SDincpos)>=1.50 & SDincpos<. 
lab def SDoekgrp 1 "<60%" 2 "60-150%" 3 "150% u.m."
lab var SDoekgrp "Einkommensposition"
	
* Migrationshintergrund
gen SDmigback:SDmigback	= 1 if inrange(migback,1,1)
replace SDmigback 		= 2 if inrange(migback,2,4)
lab def SDmigback 1 "Kein Migrationshintergrund" 2 "Migrationshintergrund"
lab var SDmigback "Migrationshintergrund"

* Art des Migrationshintergrundes
gen SDmigart:SDmigart  = SDmigback
lab var SDmigart "Migrationshintergrund"
lab def SDmigart 1 "Kein Migrationshintergrund" ///
	2 "Migrationshintergrund (türkisch)" 3 "Migrationshintergrund (anderer)" 
replace SDmigart = 3 if SDmigart == 2
replace SDmigart = 2 if SDmigart == 3 & ((corigin==2)|(pgnation==2))

* Lebensform
    gen SDlform_all:lform = 1 if  inlist(hgtyp1,1) 
replace SDlform_all = 2 if  inlist(hgtyp1,3) 
replace SDlform_all = 3 if  inlist(hgtyp1,2,8) 
replace SDlform_all = 4 if inlist(hgtyp1,4,5,6,7) 
lab def  lform ///
  1 "Allein lebend" ///
  2 "Allein erziehend" ///
  3 "Mit Partner, ohne Kinder" ///
  4 "Mit Partner, mit Kindern" 
lab var SDlform_all "Lebensform"

gen SDlform_erw:lform = SDlform_all if inlist(stell,0,1,2,13) 
lab var SDlform_erw "Lebensform (HH-vorstand bzw. d. Partner)"
compress SD*

// Outcomes
//==========
* Allg. Gesundheit
gen GZmehm1:ple0008 = ple0008 if ple0008>=0
lab var GZmehm1 "Allg. Gesundheitszustand"

* Sport
gen GVsport:GVsport = pli0092 if pli0092>0
lab var GVsport "Aktiver Sport"
lab def GVsport 1"jede Woche" 2"jeden Monat" 3"seltener" 4"nie"


/* ANFANG KORREKTUR */
/* 	[Lars]: Werte für Jahr 2001 fehlen, in den Jahren 2013, 1990, 1984 wurde 
			eine abweichende Skala benutzt, ohne dass dies in pli0092 
			berücksichtigt ist. Hierzu gibt es einen Datensatz pl2 in dem diese 
			Variablen sind.
*/
* Werte aus 2001
preserve
use "${soepcsdir}\rp.dta" , clear
keep persnr rp0303
ren persnr pid 
gen syear = 2001
replace rp0303 = . if rp0303 < 0
keep if rp0303 <.
tab rp0303 
sort pid syear 
tempfile zummergen
save `zummergen' , replace 
restore

sort pid syear 
merge 1:1 pid syear using `zummergen' ,  nogenerate
replace GVsport = rp0303 if syear == 2001
drop rp0303 

* Abweichende Skala in 1984, 2013
replace GVsport = . if inlist(syear,1984,1990,2013)
/* ENDE KORREKTUR */

* Rauchen 
gen GVrauchen:ple0081 = ple0081 if ple0081>0
replace GVrauchen = 2 if ple0081==-2
lab var GVrauchen "Rauchen gegenwärtig"

/* ANFANG Korrektur */
/* In einigen Jahren ist die Information zum Rauchen in der Variable ple0080 */
replace GVrauchen = ple0080 if ple0081==-8 & ple0080!=-8  & ple0080>0
replace GVrauchen = 2 if ple0081==-8 & ple0080>1  & ple0080<9

/* ENDE Korrektur */

* Anzahl Zigaretten
* Werte lt. Empfehlung RKI Workshop zur Erhebung des Rauchens
gen GVrauchmenge = 0 if ple0081==2
replace GVrauchmenge = ple0086 if ple0086>0 // Anz. Zigaretten
replace GVrauchmenge = GVrauchmenge +ple0087*3 if ple0087>0 // Anz. Pfeiffen
replace GVrauchmenge = GVrauchmenge +ple0088*4 if ple0088>0 // Anz. Zigarren
lab var GVrauchmenge "Anzahl Zigaretten (bzw. Äquivalente)" 

* Adipositas
gen GVbmi = ple0007/((ple0006/100)^2) if (ple0006>0) & (ple0007>0) ///
	& ((ple0007/((ple0006/100)^2))<70)
lab var GVbmi "BMI auf Basis von Selbstangaben"

gen GVadipositas:GVadipositas  = GVbmi >=30 if GVbmi <.
lab var GVadipositas "Adipositas lt. BMI-Selbstangaben"

* Sorgen
gen PSYsorgen:plh0033 = plh0033 if plh0033>0
lab var PSYsorgen "Sorgen eig. wirtschaftl. Lage"

* Bereichszufriedenheiten
gen Zgesund	:plh0171	=	plh0171	if	plh0171>=0
gen Zarbeit	:plh0173	=	plh0173	if	plh0173>=0
gen Zhhtgtkt:plh0174	=	plh0174	if	plh0174>=0
gen Zhheink	:plh0175	=	plh0175	if	plh0175>=0
gen Zwhg	:plh0177	=	plh0177	if	plh0177>=0
gen Zfreizeit :plh0178	=	plh0178	if	plh0178>=0
gen Zkindbtr :plh0179	=	plh0179	if	plh0179>=0
gen Zleben :plh0182		=	plh0182	if	plh0182>=0
gen Zperseink :plh0176	=	plh0176	if	plh0176>=0
gen Zdemokr	:plh0170	=	plh0170	if	plh0170>=0
gen Zschlaf	:plh0172	=	plh0172	if	plh0172>=0

lab var Zgesund "Zufriedenheit Gesundheit"
lab var Zarbeit "Zufriedenheit Arbeit"
lab var Zhhtgtkt "Zufriedenheit HH-Taetigk."
lab var Zhheink "Zufriedenheit HH-Einkommen"
lab var Zwhg "Zufriedenheit Wohnung"
lab var Zfreizeit "Zufriedenheit Freizeit"
lab var Zkindbtr "Zufriedenheit Kinderbetreuung"
lab var Zleben "Lebenszufriedenheit gegenwaertig"
lab var Zperseink "Zufriedenheit mit persoenlichem Einkommen"
lab var Zdemokr "Zufriedenh. Demokratie Deutschland"
lab var Zschlaf "Zufriedenheit Schlaf"

* SOEPvSF12
foreach num of numlist 1(1)11  {
local orignum = 24+`num'
local origlab : var label ple00`orignum' 
gen GZsf12_`num' : ple00`orignum' = ple00`orignum'  if ple00`orignum'>0
lab var GZsf12_`num' "`origlab'"
}

// KERNINDIKATOREN der ARB
//========================
// HILFSVARIABLE ANZAHL BEREICHE OHNE bzw. MIT EINSCHRÄNKUNGEN
/*
Fragebogenitem: Wenn Sie Treppen steigen müssen, also mehrere Stockwerke 
	zu Fuß hochgehen: 
	Beeinträchtigt Sie dabei Ihr Gesundheitszustand „stark“, 
	„ein wenig“ oder „gar nicht“?
	
Fragebogenitem: Und wie ist das mit anderen anstrengenden Tätigkeiten im Alltag,
	wo man z.B. etwas Schweres heben muss oder Beweglichkeit braucht: 
	Beeinträchtigt Sie dabei Ihr Gesundheitszustand „stark“, „ein wenig“ 
	oder „gar nicht“?
	
Fragebogenitem: Bitte denken Sie einmal an die letzten vier Wochen. Wie oft kam 
es in dieser Zeit vor,… („immer“, „oft“, „manchmal“, „fast nie“ oder „nie“)
...dass Sie wegen gesundheitlicher Probleme körperlicher Art in Ihrer Arbeit 
	oder Ihren alltäglichen Beschäftigungen in der Art Ihrer Tätigkeiten 
	eingeschränkt waren?
	
...dass Sie wegen seelischer oder emotionaler Probleme in Ihrer Arbeit oder 
	Ihren alltäglichen Beschäftigungen Ihre Arbeit oder Tätigkeit weniger 
	sorgfältig als sonst gemacht haben?
	
...dass Sie wegen gesundheitlicher oder seelischer Probleme in Ihren 
	sozialen Kontakten, z.B. mit Freunden, Bekannten oder Verwandten, 
	eingeschränkt waren?
*/

// Fehlende Werte bei Hilfsvariablen 
gen HVanzb_stark_oft = ((ple0004 ==1) + (ple0005 ==1) + inlist(ple0032,1,2) ///
	+ inlist(ple0034,1,2)   + inlist(ple0035,1,2)) ///
	if (ple0004+ple0005+ple0032+ple0034+ple0035)<. 
	
gen HVanzb_keinerlei = ((ple0004 ==3) + (ple0005 ==3) + inlist(ple0032,5)  ///
	+ inlist(ple0034,5)     + inlist(ple0035,5))   ///
	if (ple0004+ple0005+ple0032+ple0034+ple0035)<. 

/*
ÄNDERUNG ALT:
Indikator R.2. „Sehr guter bzw. guter Gesundheitszustand“: 
Selbsteinschätzung des allgemeinen Gesundheitszustandes als „sehr gut“ oder 
„gut“ und keinerlei gesundheitlich bedingte Einschränkungen in fünf vorgegebenen 
Funktionsbereichen und keine Behinderung.

ÄNDERUNG NEU:
Indikator R.2. „Sehr guter bzw. guter Gesundheitszustand“: 
Selbsteinschätzung des allgemeinen Gesundheitszustandes als „sehr gut“ oder 
„gut“ und keinerlei Behinderungen, unabhängig vom Schweregrad.

Fragebogenitem: Wie würden Sie Ihren gegenwärtigen Gesundheitszustand 
	beschreiben? („Sehr gut“, „gut“, „zufriedenstellend“, „weniger gut“ 
	oder „schlecht“)
*/

// Fehlende Werte beim Grad der Behinderung erzeugen
replace ple0041 = 0 if ple0041==.f  // Keine Behinderung
gen     R2_kernindikator = 100*(inlist(ple0008,1,2) & (int(ple0041)==0)) ///
							if (ple0008 >0 ) & (ple0041 <.) 
lab var R2_kern "R2:Sehr guter bzw. guter Gesundheitszustand“"

/*
Indikator A.3. „Gesundheitliche Beeinträchtigung“: Selbsteinschätzung des 
allgemeinen Gesundheitszustandes als „weniger gut“ oder „schlecht“ und in 
mindestens drei von fünf vorgegebenen Bereichen „stark“ bzw. „oft“ oder „immer“ 
funktionell eingeschränkt.

Fragebogenitem: Wie würden Sie Ihren gegenwärtigen Gesundheitszustand 
	beschreiben? („Sehr gut“, „gut“, „zufriedenstellend“, „weniger gut“ 
	oder „schlecht“)
*/

gen     A3_kernindikator = ///
	100*(inlist(ple0008,4,5) & (HVanzb_stark_oft >=3)) ///
		if ple0008 <. & HVanzb_stark_oft<. 
lab var A3_kernindikator "A3:Gesundheitliche Beeinträchtigung"
/*
Indikator A.4. „Grad der Behinderung“ (Indikator A.4.): Grad der Behinderung 
mindestens 50%.

Fragebogenitem: Sind Sie nach amtlicher Feststellung erwerbsgemindert oder 
	schwerbehindert? Wenn ja, wie hoch ist ihre Erwerbsminderung oder 
	Behinderung nach der letzten Feststellung in Prozent?
*/

gen     A4_kernindikator = (ple0041>=50)*100 if ple0041<. 
lab var A4_kernindikator  "A4:Grad der Behinderung mindestens 50%"	

// Population auswählen
gen stop = . 
// keep if phrf>0   -> Filter entfernt für Mortalitätsanalysen
compress

// Gesamtdatensatz speichern
save $soep_trend_full , replace
zipfile $soep_trend_full , saving("${soepfg28}/soep_trend_full.zip" , replace)

// Arbeitsdatensatz erstellen
use $soep_trend_full  , clear
keep if (tsphrf >0)  & (hgowner < 5) // PRÜFEN bei v34: IST HGOWNER NOCH IMMER gültig??
keep cid pid hid syear sex todjahr todinfo netto pop sampreg hgnuts1   psample ///
start - stop pgcasmin
drop start stop
svyset hid [pw=tsphrf]
save $soep_arbeitsdaten , replace

// Resultat ins FG 28 Laufwerk schreiben
save "${soepfg28}/soep_arbeitsdaten.dta" 


/*******************************************************************************
Erweiterung zur Erstellung des Arbeitsdatensatzes für die IMIRA-SOEP-Analysen
*******************************************************************************/

// Wenn Start ab hier, vorher die Globals aus dem Master-Do-File durchlaufen lassen

// Migrantendatensatz erstellen
use if syear>=2013 using $soep_trend_full  , clear
keep if (phrf >0)  
keep cid pid hid syear sex todjahr todinfo netto pop sampreg hgnuts1 phrf  ///
start - stop pgcasmin phrf psample
drop start stop
svyset hid [pw=phrf]

// Resultat ins FG 28 Laufwerk schreiben
save "${soepfg28}/soep_migrationsanalysen.dta" , replace

