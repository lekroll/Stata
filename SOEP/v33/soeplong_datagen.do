/* Generierung des GBE-SOEP LS-Datensatzes */
/* L. Kroll */

// Tempfiles
tempfile workdata
tempfile tempdata

// Pull Personal-Data
use ${soepldir}ppfadl.dta , clear
sort cid pid syear
compress
save `workdata'
di _N

// Pull Stellung im Haushalt aus P-Brutto
use cid pid syear stell sample1 stistat befstat using ${soepldir}pbrutto
sort cid pid syear
save `tempdata' , replace 
merge 1:1 cid pid syear using  `workdata' , keep(1 3)
drop _merge
sort cid hid syear 
compress
save `workdata' , replace
d , short

// Pull Stellung im Haushalt aus H-Brutto
use cid hid syear htyp bula regtyp wum4 hhgr datummo using ${soepldir}hbrutto
sort cid hid syear 
save `tempdata' , replace 
use `workdata' 
merge m:1 cid hid syear  using  `tempdata'  , keep(1 3)
drop _merge
sort cid pid syear
compress
save `workdata' , replace
d , short

// Pull variables of interest from pl
use cid pid syear hid  					/// Merge Variablen
	plh017* plh003* plh004*	plh0182		/// Bereichszufriedenheiten
	ple* 								/// Gesundheitskapitel
	pli009* pli0059 pli0060	plb0158		/// Aktivitäten (Sport, Schlafen, Sozialkapital)
	using ${soepldir}pl.dta , clear
sort cid pid syear
save `tempdata' , replace


use `workdata', clear
merge 1:1 cid pid syear using `tempdata' , keep(1 3)
drop _merge
compress
save `workdata' , replace
d , short

// Pull all from PGEN
use "${soepldir}pgen.dta", clear
sort cid pid syear
save `tempdata' , replace
use `workdata', clear
merge 1:1 cid pid syear using `tempdata' ,  keep(1 3)
drop _merge
compress
save `workdata' , replace
d , short


// Pull all but flags and health from PEQUIV
use "${soepldir}pequiv.dta", clear
sort cid pid syear
drop f* m111*
save `tempdata' , replace
use `workdata', clear
merge 1:1 cid pid syear using `tempdata' , keep(1 3)
drop _merge
compress
save `workdata' , replace

// Pull Edu, Mig and Competences from (huge) Bio-dataset
use _all using "${soepldir}biol.dta", clear
ren lb0090 SDedus_v
ren lb0091 SDedus_m
ren lb0247 SDagefirstjob
ren lm0015 SDmiastus
* ren lm0017 SDmifirstmove // muss neu gedacht werden; die Variable ist in v33 mit mehreren Variablen abgebildet, z.B. lm0016, lm0018, lm0019
ren lb1260	KKsprech_d
ren lb1261	KKschreib_d
ren lb1262	KKsprech_hk
ren lb1263	KKschreib_hk
ren lb1264	KKlese_d
ren lb1265	KKlese_hk
drop lm* lb* ln* bint* p_* v0*  b*in
sort cid pid 
save `tempdata' , replace
use `workdata', clear
merge m:1 cid pid syear using `tempdata' , keep(1 3)
drop _merge
compress
save `workdata' , replace
d , short

// Pull variables of interest from HL
use hid syear  hlf* using "${soepldir}hl.dta", clear
sort hid syear 
save `tempdata' , replace
use `workdata', clear
sort hid syear
merge m:1 hid syear using `tempdata' , keep(1 3)
drop _merge
sort cid pid syear
save `workdata' , replace
d , short

// Pull all from HGEN
use "${soepldir}hgen.dta", clear
sort hid syear 
save `tempdata' , replace
use `workdata', clear
sort cid pid syear
merge m:1 hid syear using `tempdata' , keep(1 3)
drop _merge
sort cid pid syear
save `workdata' , replace
d , short

// Pull all SF12v2 SOEP-Data
tempfile tempdata
use "${soepcsdir}/health.dta", clear
ren hhnr cid
ren persnr pid
sort cid pid syear
save `tempdata' , replace

use `workdata', clear
sort cid pid syear
merge 1:1 cid pid syear using `tempdata' , keep(1 3)
drop _merge
sort cid pid syear
d, short

// Missing values
//===============
/*
DOKU
-1 	no answer /don`t know
-2 	does not apply
-3 	implausible value
-4 	inadmissible multiple response
-5 	not included in this version of the questionnaire
-6 	version of questionnaire with modified filtering
-8 	question not part of the survey programm this year*
*/

mvdecode _all , mv(-1  = .k \ -2 = .f \ -3 = .u \ -4 = .m \ -5 = .n \ -6 = .n \ -8 = .n)
compress
save $soeplong , replace
