set more off
capture clear all
capture log close
version 14.1

/* 
Hinweise vor Aktualisierung 
- Es werden sowohl Quer- als auch LS-Datensätze benötigt, da die Sf12 Variablen nur als QS-Datensatz 
	(health.dta) zur Verfügung gestellt werden.
- Als Zusatzdaten für die Zuspielung von Konstrukten wird derzeit nur die Arbeitsbelastung nach Kroll 2011
	über die kldb92 zugespielt. Alle Zusatzdaten müssen im Verzeichnis Zusatzdaten des Arbeitsordners abgelegt werden.
- Unter Rekodierung müssen ggf. noch Jahre bei der Variablen Sport ausgeschlossen werden. I.d.R. weichen nämlich die	
	Kaetegorien von Aktivitäten in ungeraden Jahren vom Standard ab. Dadurch werden Prävalenzschätzer verzehrt.
- Aktueller Stand der Syntax: 16.08.2017, Bearbeiter: Lars Kroll, FG28
- Hinweis bitte unter keinen Umständen komplette Datensätze zuspielen, sondern 
	lediglich Auszüge mit relevanten Merkmalen. Ausnahmen sind nur die generierten
	Variablen aus HGEN, PGEN und PEQUIV!
*/

// Initialisierung
/* Anzupassen bei Änderung der Ausgangsdaten */
global ausgabeverzeichnis "C:\SOEP\v33\" 
global soepfg28			  "S:\OE\FG28\101 Daten\SOEP\v33"
global soepldir  		  "C:\SOEP\v33\LONG\"    // long 
global soepcsdir 		  "C:\SOEP\v33\CORE\" 	 // wide 

/* Anzupassen bei Änderung der Ausgangsdaten */
global gewichtung 			"tsphrf"
global soepsyntax			"S:\OE\FG28\101 Daten\SOEP\SOEP_Aufbereitung\v33"
global soeplong				"${ausgabeverzeichnis}/soep_long.dta"
global soep_arbeitsdaten 	"${ausgabeverzeichnis}/soep_arbeitsdaten.dta"
global soep_trend_full 		"${ausgabeverzeichnis}/soep_trend_full.dta"

// Beginn der Datensatzerstellung
cd "${ausgabeverzeichnis}"

// Teildatensätze zusammenführen
do "${soepsyntax}/soeplong_datagen.do"

// Rekodierungen und Konstruktbildungen
do "${soepsyntax}/soeplong_recode.do"

/* [NOCH ZU AKTUALISIEREN:] SES
do "S:\OE\FG28\206 Soziodemografie\SES_Berechnung\SES_SOEP\soep_ses_v32.do"
*/

