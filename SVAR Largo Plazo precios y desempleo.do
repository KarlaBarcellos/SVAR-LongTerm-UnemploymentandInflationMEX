*Modelo SVAR 
** Variables: inflación y tasa de desempleo.
*** Tasas mensuales, 1980-2019
*** Tratamiento: tasas, tasas en logaritmos y en primeras diferencias

*** Correr desde aquí!

*abrir base

use "C:\Users\estef\Documents\Paper 2020\SVAR LP-Rom.dta", clear

set more off

*declarar serie de tiempo
 tsset t

 *convertir a logaritmo
 gen logpr = log(infla)

***análisis gráfico de las variables
*en log

 #delimit ;
twoway (tsline desem, lcolor(red) lwidth(vvthin) lpattern(solid) connect(direct)) || 
(tsline infla, lcolor(erose) lwidth(vvthin) lpattern(solid) connect(direct)), legend(on size(small));
#delimit cr  

*en diferencias
 #delimit ;
twoway tsline D.logpr, lcolor(green) lwidth(vvthin) lpattern(solid) connect(direct))    || 
(tsline desem, lcolor(erose) lwidth(vvthin) lpattern(solid) connect(direct)), legend(on size(small));
#delimit cr
summarize

*Detectar si hay problemas de raíces unitarias. 
** Una serie con raíz unitaria es no estacionaria por lo que no se puede hacer trabajos de modelación con ellas.
*** Se realiza la prueba dfuller aumentada y se trata de corregir hasta tener series estacionarias.

*Ahora son series estacionarias

*prueba sobre las bases en primera diferencia
dfuller D.logpr, trend regress lags(1)
dfuller desem, trend regress lags(1)


***Largo plazo
*remove a time trend from the unemployment series and store the residuals into unrate_adj
quietly regress desem  t
predict desem_adj, resid

**create dummy variables, one of which equals 1 before the 1988 break point and the other of which equals 1 after the 1988 break point. 
generate bp1 = (t<1988)
generate bp2 = (t>=1988)
*remove the period-specific mean from --- and store the resulting series into ---_adj.
quietly regress D.logpr bp1 bp2, noconstant
predict infla_adj, resid

*Utilizamos la matriz de reestricción
matrix C = (., 0 \ .,.)
*Estimamos el SVAR
svar infla_adj desem_adj, lags(1/8) lreq(C)

*to estimate the covariance of the error terms which is can be found in the stored results e(Sigma);

matlist e(Sigma)


*I have given the impulse–responses a name, lr, and saved them to a file, lrirf.irf.
irf create lr, set(lrirf) step(200) replace
*We can view the impulse–responses with

irf graph sirf, yline(0,lcolor(black)) xlabel(0(4)200) byopts(yrescale)
*The impulse–responses to each shock under the long-run identification scheme are held in sirf and are graphed in the next figure.
*One step is one quarter, so the figure depicts the impulse–response over a period of 10 years.

*" infla impulse" = "supply" shock.
*"desem impulse" = "demand" shock. 

*The top row shows the response of infla and unemployment to a supply shock (to a infla). 
*GNP growth rises; the unemployment rate rises on impact, then falls after about one year, 
* troughs after about two years, then slowly returns to its steady-state value. 
*The bottom row shows the response to a "demand" shock. In response to a "demand" shock, 
*output growth falls initially before recovering after one year. Unemployment rises, 
*peaking about a year after the shock before returning to its steady-state value.

*The following code block creates a new variable, csirf,
*that holds the cumulative impulse–response of infla 
*to each shock and does nothing to the impulse–response to the unemployment rate.
use lrirf.irf, clear

sort irfname impulse response step
gen csirf = sirf
by irfname impulse: replace csirf = sum(sirf) if response=="infla_adj"
order irfname impulse response step sirf csirf
save lrirf2.irf, replace
irf set lrirf2.irf
irf graph csirf, yline(0,lcolor(black)) noci xlabel(0(4)200) byopts(yrescale)
