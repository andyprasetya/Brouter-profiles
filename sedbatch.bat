@echo off
rem @Setlocal EnableDelayedExpansion

rem Ver 1.1 Fixed generation for Hiking-wet profiles ( by error identical to dry ones )
rem Ver 1.2 Parameter "main" generates only main/major profiles
rem Ver 1.2.1 Fixed names of Trekking-Dry/Wet profiles ( Was Poutnik instead of Trekking ])
rem Ver 1.3.1 Added Shortest-P profile

rem windows batch to automatically generate a bunch of Brouter profiles 
rem based on the bike/car/foot profile templates by Poutnik

rem Linux users should be easily able modify the batch to create the Linux sh script
rem as I am not good in unix shell scripts.

Rem When the batch is launched, 
rem   1/  it create a working subfolder in a folder where the script resides
rem   2/  it downloads latest Trekking-Poutnik.brf template from GitHub depository
rem   3/  it generates end user profiles by automatic subtitution of the modifiers
rem   4/  it packs them into a single ZIP archive BR-Trekking-Profiles.zip and deletes the working subfolder.

rem prerequisities for windows

rem 1/  Install CygWin ( https://www.cygwin.com/ ), or alternative ( like GNUWinNN ] 
rem     to have available Windows ports of UNIX utilities SED and WGET
rem        In case of Cygwin, they should be present on folder c:\cygwin64\bin, resp. c:\cygwin32\bin
rem        If not, install them via cygwin setup.exe, if these utilities are not default ones.

rem 2/  Install 7-zip from http://www.7-zip.org/download.html 
rem     ( optional, if you want to get zipped profiles, e.g. for mass transfer to the phone) 

rem 3/  Set environment variables below to there pathnames ( in my case, junction bin64 means c:\Program files )

rem ******************************************************
rem             P R E P A R A T I O N
rem ******************************************************

set sedexe=c:\cygwin64\bin\sed.exe
set wgetexe=c:\cygwin64\bin\wget.exe
set zipexe=C:\bin64\7-Zip\7z.exe

set scope=main

rem ******************************************************
rem               B R A N C H I N G
rem ******************************************************

if "%*"=="" goto :legend

:shiftloop

if /i "%1"=="all" set scope=all
if /i "%1"=="main" set scope=main
if /i "%1"=="locus" set scope=locus


if /i "%1"=="car" call :car
if /i "%1"=="bike" call :bike
if /i "%1"=="foot" call :foot

shift
if not "%1"=="" goto :shiftloop
exit /b


rem ******************************************************
rem                     L E G E N D
rem ******************************************************

:legend

echo The sedbatch.bat expects particular command line parameters to do anything.
echo Launch it by either of the following ways
echo "sedbatch main" generates the most important profiles from the car, bike and foot profile template
echo "sedbatch [car] [bike] [foot]" generates the all defined profile variants
echo for all listed transportation modes  (  [] means optional )
echo "sedbatch all" is equivaltent to  "sedbatch car bike foot" 
echo and generates the all profiles for all car, bike and foot transportation modes
pause
exit /b

rem ******************************************************
rem                     W D I R
rem ******************************************************
:wdir
if not exist .\sedwdir md .\sedwdir
cd .\sedwdir
if exist .\*.brf del .\*.brf
exit /b

rem ******************************************************
rem     GET TEMPLATE
rem ******************************************************

:gettemplate

if not exist %wgetexe% goto :nowget
%wgetexe% %1
exit /b
:nowget
echo As you do not have wget configured to use, 
Echo Download  %1  manually
Echo and place the file to sedwdir subfolder in the folder where this batch resides.
Echo Press any kay when done

exit /b

rem ******************************************************
rem     B R O U T E R   B I C Y C L E   P R O F I L E S
rem ******************************************************

:bike

call :wdir

set tmplpath=master
set src=Trekking-Poutnik
set archivefile=BR-Bike-Profiles%1

set legfile=%archivefile%-Legend.txt

call :gettemplate  https://raw.githubusercontent.com/poutnikl/Trekking-Poutnik/%tmplpath%/Trekking-Poutnik.brf


if exist %legfile% del %legfile% 

Echo Profile name,  Profile description ( generated )  >%legfile% 

if /i not %scope%==locus call :replaceone is_wet 0 1 %src% %src%-wet

call :replaceone is_wet 0 0 %src%     Trekking-dry "Standard Trekking profile by Poutnik, for dry weather"
if /i not %scope%==locus  call :replaceone is_wet 0 1 %src%-wet Trekking-wet "Standard Trekking profile by Poutnik, for wet weather ( partially avoids muddy or slicky surface, but does not forbid them )"

call :replaceone MTB_factor 0.0 0.5  %src%  Trekking-MTB-medium    "Trekking profile with medium focus on unpaved roads, moderately penalizing mainroads."
call :replaceone MTB_factor 0.0 -0.5 %src%  Trekking-Fast          "Trekking profile with moderate focus on mainroads, penalizing unpaved roads. Between Trekking and FastBike."

call :replacetwo MTB_factor 0.0 2.0 smallpaved_factor 0.0 -0.5  %src%    MTB "MTB profile, based on MTBiker feedback"
call :replacetwo MTB_factor 0.0 1.0 smallpaved_factor 0.0 -0.3  %src%    MTB-light "Light MTB profile for tired bikers, based on MTBiker feedback. Preferred to Trekking-MTB-strong"

call :replacetwo MTB_factor 0.0 -1.7 smallpaved_factor  0.0 2.0 %src%       Trekking-SmallRoads       "Trekking profile more preferring small paved roads and tracks"

if /i %scope%==main goto :closing

call :replaceone MTB_factor 0.0 0.2  %src%  Trekking-MTB-light     "Trekking profile with light focus on unpaved roads, slightly penalizing mainroads."
call :replaceone MTB_factor 0.0 1.0  %src%  Trekking-MTB-strong    "Trekking profile with strong focus on unpaved roads, strongly penalizes mainroads. Similar to MTB light, that is preferred."

call :replaceone cycleroutes_pref 0.2 0.0 %src%      Trekking-ICR  "Trekking profile ignoring existence of cycleroutes"
call :replaceone cycleroutes_pref 0.2 0.5 %src%      Trekking-FCR  "Trekking profile sticking to cycleroutes, more preferring lond distance cycleroutes"
call :replaceone cycleroutes_pref 0.2 0.8 %src%      Trekking-LCR  "Trekking profile for long distance cycleroutes"

call :replaceone hills 1 4 %src%  Trekking-Valley  "Trekking in Valley mode, preferred flats as far as possible, even in expense of steep valley escape. On-the-slope based penalizations by Up-down-costfactors."
call :replaceone hills 1 5 %src%  Trekking-No-Flat  "Trekking in No-Flat mode, giving penalty to flat roads, with zero hillcost."

call :replacetwo MTB_factor 0.0 1.5 smallpaved_factor 0.0 -0.75  %src% %src%-tmp
call :replaceone isbike_for_mainroads true false %src%-tmp  Trekking-tracks "Trekking in Tracks mode, Strong preference of unpaved tracks and paths"
del %src%-tmp.brf 


call :replacetwo MTB_factor 0.0 2.0 smallpaved_factor 0.0 -1.0  %src% %src%-tmp
call :replacetwo isbike_for_mainroads true false  path_preference  0.0 20.0 %src%-tmp  Trekking-hilly-paths "Trekking in Hilly paths mode, Very strong preference of unpaved hilly paths"
del %src%-tmp.brf 

if /i %scope%==locus goto :closing

call :replaceone MTB_factor 0.0 0.2  %src%-wet  Trekking-MTB-light-wet     "Trekking wet weather profile with light focus on unpaved roads, slightly penalizing mainroads."
call :replaceone MTB_factor 0.0 0.5  %src%-wet  Trekking-MTB-medium-wet    "Trekking wet weather profile with medium focus on unpaved roads, moderately penalizing mainroads."
call :replaceone MTB_factor 0.0 1.0  %src%-wet  Trekking-MTB-strong-wet    "Trekking wet weather profile with strong focus on unpaved roads, strongly penalizes mainroads. Similar to MTB light, that is preferred."
call :replaceone MTB_factor 0.0 -0.5 %src%-wet  Trekking-Fast-wet          "Trekking wet weather profile with moderate focus on mainroads, penalizing unpaved roads. Between Trekking and FastBike."

call :replacetwo MTB_factor 0.0 2.0 smallpaved_factor 0.0 -0.5  %src%-wet MTB-wet "MTB wet weather profile, based on MTBiker feedback"
call :replacetwo MTB_factor 0.0 1.0 smallpaved_factor 0.0 -0.3  %src%-wet MTB-light-wet "Light MTB wet weather profile for tired bikers, based on MTBiker feedback. Preferred to Trekking-MTB-strong"

call :replaceone cycleroutes_pref 0.2 0.0 %src%-wet  Trekking-ICR-wet  "Trekking profile ignoring existence of cycleroutes, wet weather variant"
call :replaceone cycleroutes_pref 0.2 0.5 %src%-wet  Trekking-FCR-wet  "Trekking profile sticking to cycleroutes, more preferring lond distance cycleroutes, wet weather variant"
call :replaceone cycleroutes_pref 0.2 0.8 %src%-wet  Trekking-LCR-wet  "Trekking profile for long distance cycleroutes, wet weather variant"

call :replacetwo MTB_factor 0.0 -1.7 smallpaved_factor  0.0 2.0 %src%-wet   Trekking-SmallRoads-wet   "Trekking profile more preferring small paved roads and tracks, wet weather variant"

goto :closing

rem ******************************************************
rem     B R O U T E R   C A R   P R O F I L E S
rem ******************************************************

:car
call :wdir

set tmplpath=master
set archivefile=BR-Car-Profiles%1
set src=Car-test-Template

set legfile=%archivefile%-Legend.txt

call :gettemplate  https://raw.githubusercontent.com/poutnikl/Car-Profile/%tmplpath%/Car-test-Template.brf


if exist %legfile% del %legfile% 

Echo Profile name,  Profile description ( generated )  >%legfile% 

call :replaceone avoid_toll      0 1 %src% %src%-TollFree
call :replaceone avoid_motorways 0 1 %src% %src%-NoMotorway
call :replaceone avoid_unpaved   0 1 %src% %src%-NoUnpaved

call :replaceone drivestyle 2 3 %src%  Car-Fast                "Car profile going for Speed - possible with booth or vignette tolls"
call :replaceone drivestyle 2 1 %src%  Car-Eco                 "Economic Car profile, fuel saving. Possible with booth or vignette tolls. May be slow."
call :replaceone drivestyle 2 2 %src%  Car-FastEco             "Car profile balancing Speed and Cost - RECOMMENDED"
call :replaceone drivestyle 2 0 %src%  Car-Short               "Car profile, shortest route, probably useless unless for technical emergency."

call :replaceone drivestyle 2 3 %src%-TollFree  Car-Fast-TollFree      "Toll free, Car profile going for Speed"
call :replaceone drivestyle 2 2 %src%-TollFree  Car-FastEco-TollFree   "Toll free, Car profile balancing Speed and Cost - RECOMMENDED"
call :replaceone drivestyle 2 1 %src%-TollFree  Car-Eco-TollFree       "Toll free, Car profile going for low cost - May be slow, as low cost speed is 60-80 km per h"

call :replaceone drivestyle 2 3 %src%-NoMotorway   Car-Fast-NoMotorway       "Car profile going for Speed - Avoiding motorways\/motorroads"
call :replaceone drivestyle 2 3 %src%-NoUnpaved  Car-Fast-NoUnpaved      "Car profile going for Speed - Avoiding unpaved ways"

if /i "%1"=="main" goto :closing

call :replaceone drivestyle 2 2 %src%-NoMotorway  Car-FastEco-NoMotorway    "Car profile balancing Speed and Cost - Avoiding motorways\/motorroads, RECOMMENDED"
call :replaceone drivestyle 2 1 %src%-NoMotorway   Car-Eco-NoMotorway        "Economic Car profile, fuel saving, Avoiding motorways\/motorroads, May be slow."

call :replaceone drivestyle 2 2 %src%-NoUnpaved Car-FastEco-NoUnpaved   "Car profile balancing Speed and Cost - Avoiding unpaved ways"
call :replaceone drivestyle 2 1 %src%-NoUnpaved  Car-Eco-NoUnpaved       "Car profile going for low cost - Avoiding unpaved ways - May be slow."

call :replacetwo drivestyle 2 3  road_restriction 1 3  %src%           Car-Fast-NoMinorRoads            "Fast profile avoiding unpaved and minor paved roads"
call :replacetwo drivestyle 2 3  road_restriction 1 3  %src%-TollFree  Car-Fast-TollFree-NoMinorRoads   "Fast tollfree profile avoiding unpaved and minor paved roads"

call :replacetwo drivestyle 2 3  road_restriction 1 4  %src%           Car-Fast-TertiaryRoads           "Fast long distance profile following tertiary and better roads"
call :replacetwo drivestyle 2 3  road_restriction 1 4  %src%-TollFree  Car-Fast-TollFree-TertiaryRoads  "Fast tollfree long distance profile following tertiary and better roads"

call :replacetwo drivestyle 2 3  road_restriction 1 5  %src%           Car-Fast-SecondaryRoads           "Fast long distance profile following secondary and better roads"
call :replacetwo drivestyle 2 3  road_restriction 1 5  %src%-TollFree  Car-Fast-TollFree-SecondaryRoads  "Fast tollfree long distance profile following secondary and better roads"

call :replacetwo drivestyle 2 2  road_restriction 1 3  %src%           Car-FastEco-NoMinorRoads            "FastEco profile avoiding unpaved and minor paved roads"
call :replacetwo drivestyle 2 2  road_restriction 1 3  %src%-TollFree  Car-FastEco-TollFree-NoMinorRoads   "FastEco tollfree profile avoiding unpaved and minor paved roads"

call :replacetwo drivestyle 2 2  road_restriction 1 4  %src%           Car-FastEco-TertiaryRoads           "FastEco long distance profile following tertiary and better roads"
call :replacetwo drivestyle 2 2  road_restriction 1 4  %src%-TollFree  Car-FastEco-TollFree-TertiaryRoads  "FastEco tollfree long distance profile following tertiary and better roads"

call :replacetwo drivestyle 2 2  road_restriction 1 5  %src%           Car-FastEco-SecondaryRoads           "FastEco long distance profile following secondary and better roads"
call :replacetwo drivestyle 2 2  road_restriction 1 5  %src%-TollFree  Car-FastEco-TollFree-SecondaryRoads  "FastEco tollfree long distance profile following secondary and better roads"

goto :closing


rem ******************************************************
rem     B R O U T E R   H I K I N G   P R O F I L E S
rem ******************************************************

:foot

call :wdir

set tmplpath=master
set archivefile=BR-Foot-Profiles%1
set src=Hiking-template

set legfile=%archivefile%-Legend.txt


call :gettemplate  https://raw.githubusercontent.com/poutnikl/Hiking-Poutnik/%tmplpath%/Hiking.brf

ren Hiking.brf Hiking-template.brf

if exist %legfile% del %legfile% 

Echo Profile name,  Profile description ( generated )  >%legfile% 
call :replaceone assign shortest_way  0 1 %src% Shortest-P "Shortest way - implemented naviagtion hints."

call :replaceone is_wet 0 1 %src% %src%-wet
rem StrongHikingRoutePreference  SHRP
call :replaceone  hiking_routes_preference  0.20 0.60 %src% %src%-SHRP
rem VeryStrongHikingRoutePreference  VSHRP
call :replaceone  hiking_routes_preference  0.20 2.00 %src% %src%-VSHRP

call :replacetwo SAC_scale_limit 3 1 SAC_scale_preferred 1 0 %src%  Walking "SAC T1 - hiking - Trail well cleared, 	Area flat or slightly sloped, no fall hazard"
call :replacetwo SAC_scale_limit 3 1 SAC_scale_preferred 1 0 %src%-wet  Walking-wet "SAC T1 - hiking - Wet variant"
call :replacetwo SAC_scale_limit 3 2 SAC_scale_preferred 1 1 %src%  Hiking-SAC2 "SAC T2 - mountain_hiking - Trail with continuous line and balanced ascent, Terrain partially steep, fall hazard possible, Hiking shoes recommended, Some sure footedness"
call :replacetwo SAC_scale_limit 3 3 SAC_scale_preferred 1 1 %src%  Hiking-Mountain-SAC3 "SAC T3 - demanding_mountain_hiking - exposed sites may be secured, possible need of hands for balance,	Partly exposed with fall hazard, Well sure-footed, Good hiking shoes, Basic alpine experience "

if /i "%1"=="main" goto :closing

call :replacetwo SAC_scale_limit 3 4 SAC_scale_preferred 1 2 %src%  Hiking-Alpine-SAC4 "SAC T4 - alpine_hiking - sometimes need for hand use, Terrain quite exposed, jagged rocks, Familiarity with exposed terrain, Solid trekking boots, Some ability for terrain assessment, Alpine experience"
call :replacetwo SAC_scale_limit 3 5 SAC_scale_preferred 1 3 %src%  Hiking-Alpine-SAC5 "SAC T5 - demanding_alpine_hiking - single plainly climbing up to second grade, Exposed, demanding terrain, jagged rocks,  Mountaineering boots, Reliable assessment of terrain, Profound alpine experience, Elementary knowledge of handling with ice axe and rope"
call :replacetwo SAC_scale_limit 3 6 SAC_scale_preferred 1 4 %src%  Hiking-Alpine-SAC6 "SAC T6 - difficult_alpine_hiking - climbing up to second grade, Often very exposed, precarious jagged rocks, glacier with danger to slip and fall, Mature alpine experience, Familiarity with the handling of technical alpine equipment"

call :replacetwo SAC_scale_limit 3 1 SAC_scale_preferred 1 0 %src%-SHRP  Walking-SAC1-SHRP "SAC T1 - hiking - Trail well cleared, 	Area flat or slightly sloped, no fall hazard, Strong Hiking Route Preference"
call :replacetwo SAC_scale_limit 3 2 SAC_scale_preferred 1 1 %src%-SHRP  Hiking-SAC2-SHRP "SAC T2 - mountain_hiking - Trail with continuous line and balanced ascent, Terrain partially steep, fall hazard possible, Hiking shoes recommended, Some sure footedness, Strong Hiking Route Preference"
call :replacetwo SAC_scale_limit 3 3 SAC_scale_preferred 1 1 %src%-SHRP  Hiking-Mountain-SAC3-SHRP "SAC T3 - demanding_mountain_hiking - exposed sites may be secured, possible need of hands for balance,	Partly exposed with fall hazard, Well sure-footed, Good hiking shoes, Basic alpine experience, Strong Hiking Route Preference "
call :replacetwo SAC_scale_limit 3 4 SAC_scale_preferred 1 2 %src%-SHRP  Hiking-Alpine-SAC4-SHRP "SAC T4 - alpine_hiking - sometimes need for hand use, Terrain quite exposed, jagged rocks, Familiarity with exposed terrain, Solid trekking boots, Some ability for terrain assessment, Alpine experience, Strong Hiking Route Preference"
call :replacetwo SAC_scale_limit 3 5 SAC_scale_preferred 1 3 %src%-SHRP  Hiking-Alpine-SAC5-SHRP "SAC T5 - demanding_alpine_hiking - single plainly climbing up to second grade, Exposed, demanding terrain, jagged rocks,  Mountaineering boots, Reliable assessment of terrain, Profound alpine experience, Elementary knowledge of handling with ice axe and rope, Strong Hiking Route Preference"
call :replacetwo SAC_scale_limit 3 6 SAC_scale_preferred 1 4 %src%-SHRP  Hiking-Alpine-SAC6-SHRP "SAC T6 - difficult_alpine_hiking - climbing up to second grade, Often very exposed, precarious jagged rocks, glacier with danger to slip and fall, Mature alpine experience, Familiarity with the handling of technical alpine equipment, Strong Hiking Route Preference"

call :replacetwo SAC_scale_limit 3 1 SAC_scale_preferred 1 0 %src%-VSHRP  Walking-SAC1-VSHRP "SAC T1 - hiking - Trail well cleared, 	Area flat or slightly sloped, no fall hazard, VERY Strong Hiking Route Preference"
call :replacetwo SAC_scale_limit 3 2 SAC_scale_preferred 1 1 %src%-VSHRP  Hiking-SAC2-VSHRP "SAC T2 - mountain_hiking - Trail with continuous line and balanced ascent, Terrain partially steep, fall hazard possible, Hiking shoes recommended, Some sure footedness, VERY Strong Hiking Route Preference"
call :replacetwo SAC_scale_limit 3 3 SAC_scale_preferred 1 1 %src%-VSHRP  Hiking-Mountain-SAC3-VSHRP "SAC T3 - demanding_mountain_hiking - exposed sites may be secured, possible need of hands for balance,	Partly exposed with fall hazard, Well sure-footed, Good hiking shoes, Basic alpine experience, VERY Strong Hiking Route Preference "
call :replacetwo SAC_scale_limit 3 4 SAC_scale_preferred 1 2 %src%-VSHRP  Hiking-Alpine-SAC4-VSHRP "SAC T4 - alpine_hiking - sometimes need for hand use, Terrain quite exposed, jagged rocks, Familiarity with exposed terrain, Solid trekking boots, Some ability for terrain assessment, Alpine experience, VERY Strong Hiking Route Preference"
call :replacetwo SAC_scale_limit 3 5 SAC_scale_preferred 1 3 %src%-VSHRP  Hiking-Alpine-SAC5-VSHRP "SAC T5 - demanding_alpine_hiking - single plainly climbing up to second grade, Exposed, demanding terrain, jagged rocks,  Mountaineering boots, Reliable assessment of terrain, Profound alpine experience, Elementary knowledge of handling with ice axe and rope, VERY Strong Hiking Route Preference"
call :replacetwo SAC_scale_limit 3 6 SAC_scale_preferred 1 4 %src%-VSHRP  Hiking-Alpine-SAC6-VSHRP "SAC T6 - difficult_alpine_hiking - climbing up to second grade, Often very exposed, precarious jagged rocks, glacier with danger to slip and fall, Mature alpine experience, Familiarity with the handling of technical alpine equipment, VERY Strong Hiking Route Preference"


rem call :replacetwo SAC_scale_limit 3 1 SAC_scale_preferred 1 0 %src%-wet  Walking-wet "SAC T1 - hiking - Wet variant"
rem call :replacetwo SAC_scale_limit 3 2 SAC_scale_preferred 1 1 %src%-wet  Hiking-SAC2 "SAC T2 - mountain_hiking - Wet variant"
rem call :replacetwo SAC_scale_limit 3 3 SAC_scale_preferred 1 1 %src%-wet  Hiking-Mountain-SAC3 "SAC T3 - demanding_mountain_hiking - Wet variant"
rem call :replacetwo SAC_scale_limit 3 4 SAC_scale_preferred 1 2 %src%-wet  Hiking-Alpine-SAC4 "SAC T4 - alpine_hiking - Wet variant"
rem call :replacetwo SAC_scale_limit 3 5 SAC_scale_preferred 1 3 %src%-wet  Hiking-Alpine-SAC5 "SAC T5 - demanding_alpine_hiking - Wet variant"
rem call :replacetwo SAC_scale_limit 3 6 SAC_scale_preferred 1 4 %src%-wet  Hiking-Alpine-SAC6 "SAC T6 - difficult_alpine_hiking - Wet variant"

goto :closing

rem ******************************************************
rem                    C L O S I N G
rem ******************************************************

:closing

del %src%*.brf

if exist ..\%archivefile%.zip del ..\%archivefile%.zip
if exist ..\%archivefile%.7z del ..\%archivefile%.7z

if exist %zipexe%  %zipexe% a ..\%archivefile%.zip -tzip *.brf %legfile% -x!%src%*.brf
if exist %zipexe%  %zipexe% a ..\%archivefile%.7z -t7z *.brf %legfile% -x!%src%*.brf

Echo GENERATED PROFILES
echo .
type %legfile%
copy %legfile% ..\%legfile%
cd ..
exit /b

rem ******************************************************
rem     E X E C U T I V E    S U B R O U T I N E S
rem ******************************************************

:replaceone
 rem parameters 1=keyword 2=oldvalue 3=newvalue 4=oldfile but ext 5=new file but ext  6=optionally Legend
 
if "%~6"=="" (
%sedexe% -b -e  "s/\(assign\s\+%1\s\+\)%2/\1%3/gi" %4.brf  >%5.brf 
) else (
%sedexe% -b -e  "s/\(assign\s\+%1\s\+\)%2/\1%3/gi" %4.brf | %sedexe% -b -e "s/# LEGEND/# %~6/" >%5.brf
echo %5.brf, %~6 >>%legfile%

)

exit /b

:replacetwo
rem parameters 1=keyword1 2=oldvalue1 3=newvalue2 4=keyword2 5=oldvalue2 6=newvalue2 7=oldfile but ext 8=new file but ext 9=optionally legend

if "%~9"=="" (
%sedexe% -b -e  "s/\(assign\s\+%1\s\+\)%2/\1%3/gi" %7.brf | %sedexe% -b -e  "s/\(assign\s\+%4\s\+\)%5/\1%6/gi"  >%8.brf
) else (
%sedexe% -b -e  "s/\(assign\s\+%1\s\+\)%2/\1%3/gi" %7.brf | %sedexe% -b -e  "s/\(assign\s\+%4\s\+\)%5/\1%6/gi" | %sedexe% -b -e "s/# LEGEND/# %~9/"  >%8.brf
echo %8.brf, %~9 >>%legfile% 
)

exit /b
