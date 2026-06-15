<!-- GENERATED FILE - do not edit by hand. Regenerate with scripts/distill_xsd.R -->
# Field glossary (NMD Biotic v3)

Generated 2026-06-15 from `https://www.imr.no/formats/nmdbiotic/v3/nmdbioticv3.xsd`.

Maps plain-English concepts to the **column names** used in the flattened tables. The
**in** column shows where a field appears after flattening (see `data-model.md`).
**code?** = the field is a foreign key into NMDreference (a code, not a literal value).

> Units: `length` is in **metres**, `individualweight` and `catchweight` in **kg**.
> `commonname` is **Norwegian**. Always confirm a column exists with `colnames()`.

## Backbone elements (used in almost every query)

## `mission`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `missiontypename` | Name | string |  | stnall, indall | Name of mission type <missiontype> |
| `callsignal` | Call signal | string |  | stnall, indall | Call sign for platform. |
| `platformname` | Platform name | string |  | stnall, indall | Name of plattform. |
| `cruise` | Cruise number | string |  | stnall, indall | Cruise id |
| `missionstartdate` | Start date | date |  | stnall, indall | Start date of mission (UTC). |
| `missionstopdate` | Stop date | date |  | stnall, indall | End date of mission (UTC). |
| `purpose` | Purpose | string |  | stnall, indall | Description of the purpose of the mission. |
| `missiontype` | Mission type | KeyType | yes | stnall, indall | Type of mission. Defines procedures for sampling and conventions for registrations. |
| `startyear` | Year | integer |  | stnall, indall | The year the mission carried out. |
| `platform` | Platform | KeyType | yes | stnall, indall | The sampling platform for the mission.Identifies via other registries who was responsible for the data collection. For survey cruises this is normally the same as <catchplatform/> on child element fishstation, but these may differ when a sampling platform collects samples from a fishing platform ... |
| `missionnumber` | Period | integer |  | stnall, indall | Sequential numbers identifying the mission among missions of this type <missiontype> on this platform <platform> with this start year <startyear>. |

## `fishstation`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `nation` | Nation | KeyType | yes | - | Code identifying the nation that sampled the station. Obtained from reference table in Data Manager. |
| `catchplatform` | Platform | KeyType | yes | - | Code identifying the platform. Obtained from reference table in Data Manager. |
| `station` | Station | integer |  | stnall, indall | Identifies station, sampling unit. When several gears are used on the same stations there will be several recordings with the same station number. For special gears (such as multisampler), catch from different compartments may accour as different registrations with the same station number. Differ... |
| `fixedstation` | Fixed station | KeyType | yes | - | Code that identifies a regular station that is repeated in the same position at regular intervals. |
| `stationstartdate` | Start date | date |  | stnall, indall | Date when the gear reached fishing depth (UTC). |
| `stationstarttime` | Start time | time |  | stnall, indall | Time (UTC) when the gear reached fishing depth. For longline or gillnet, this is the time when the first hook or net was set. |
| `stationstopdate` | Stop date | date |  | - | Date (UTC) when the gear left fishing depth. |
| `stationstoptime` | Stop time | time |  | - | Time (UTC) when the gear reached fishing depth. For longline or gillnet, this is the time when the last hook or net left the water. |
| `stationtype` | Station type | KeyType | yes | - | Code for the type of station. |
| `latitudestart` | Lat. start | decimal |  | stnall, indall | Latitudinal position, when the gear reach the fishing depth. (decimal degrees, datum: WGS 84). |
| `longitudestart` | Lon. start | decimal |  | stnall, indall | Longitudinal position, when the gear reach the fishing depth. (decimal degrees, datum: WGS 84). |
| `latitudeend` | Lat. end | decimal |  | - | Latitudinal position, when the gear left the fishing depth. (decimal degrees, datum: WGS 84). |
| `longitudeend` | Lon. end | decimal |  | - | Longitudinal position, when the gear left the fishing depth. (decimal degrees, datum: WGS 84). |
| `system` | System | KeyType | yes | - | System for coding <area/> and <location/>. The most important are: Statistical areas and locations defined by the Norwegian directorate of fisheries: 2 ICES areas: 3 See Norwegian documentation for additional details. |
| `area` | Area | KeyType | yes | - | Area as defined by system. |
| `location` | Location | KeyType | yes | - | Location within area, as defined by system. |
| `bottomdepthstart` | Bot. depth start | decimal |  | stnall, indall | Depth in meters, when the gear reached fishing depth. |
| `bottomdepthstop` | Bot. depth stop | decimal |  | - | Depth in meters, when the gear left fishing depth. |
| `bottomdepthmean` | Bot. depth mean | decimal |  | - | Mean depth (m) at catch location, defined as the positions from the time the gear reached fishing depth to when it left fishing depth. |
| `fishingdepthstart` | Fishing depth start | decimal |  | - | Fishingdepth at startof station, when the gear is consider to have reached the targeted fishing depth. |
| `fishingdepthstop` | Fishing depth stop | decimal |  | - | Fishingdepth at end of station, when the gear is consider to have first left the targeted fishing depth. |
| `fishingdepthcount` | Num. Depths | integer |  | - | The number of targeted fishing depths at the station. The deepest and shallowest fishing depth can be read from <fishingdepthmax/> and <fishingdepthmin/>. Equal depth intervals are assumed if more than one fishingdepth is provided. |
| `fishingdepthmax` | Fishing depth max. | decimal |  | - | The maximal fishing depth of the gear, given in meters. If the gear has been fishing at constant depth, this field should be filled. For seine, use the maximal depth of the shoal or school, for trawl use the maximal depth of the headline i for the duration of the station. For standardised trawlin... |
| `fishingdepthmin` | Fishing depth min. | decimal |  | stnall, indall | The minimal depth the gear has been fishing, given in meters. Not filled if the gear has fished at constant depth. For trawl, use the minimal depth of the headline i for the duration of the station. For seine, give the minimal depth of the shoal or school. In older data (early 2000s and before). ... |
| `fishingdepthmean` | Fishing depth mean | decimal |  | - | Used if minimal and maximal fishing depth can not be given. Primarily used by for data contribution from fishing vessels (the reference fleet). |
| `fishingdepthtemperature` | Temperature fishing depth | decimal |  | - | Avergae temperature at fishing depth in degrees Celcius, as read from sesnor on trawl door. |
| `gearno` | Gear no. | integer |  | - | Specify the exact gear used, see identifier on gear (if present). |
| `sweeplength` | Sweep length | decimal |  | - | Sweep length (m). |
| `gear` | Gear | KeyType | yes | stnall, indall | Code for the gear used. See Norwegian documentation for additional details. |
| `gearcount` | Gear count | integer |  | - | The number of gears used, for chained gears or fishing with multiple identical gears. For gillnets: the number of nets in the chain. For longlines, the number of hooks on the line. For other gear (such as traps): the number of gears. |
| `direction` | Direction | decimal |  | - | Direction of haul, relative to north. Only filled if the hauled was done in approximately constant direction. North is entered as 360 degrees. |
| `gearflow` | Gear flow | decimal |  | - | Flow through gear in knots (nm/h). Read from sensor. |
| `vesselspeed` | Vessel speed | decimal |  | - | Vessel speed over ground in knots (nm/h). Read from GPS. |
| `logstart` | Start log | decimal |  | - | Log (nm) read at start of station. |
| `logstop` | Stop log | decimal |  | - | Log (nm) at end of station. |
| `distance` | Distance | decimal |  | stnall, indall | Towed distance in nautical miles. GPS data should be used when possible. When bottom trawling for quantitative estimates of stocks, the trawl should be towed a given distance over the seabed as measured by GPS. Time, speed and distance for the haul should be registered independet of each other. T... |
| `gearcondition` | Gear condition | KeyType | yes | - | Condition of the gear after haul. |
| `samplequality` | Quality | KeyType | yes | - | Specifies how the catch reflect the amount of fish and composition of species in the area, based on the way catch was fished or reported and based on the behaviour of the gear during fishing. |
| `verticaltrawlopening` | Vertical trawl opening | decimal |  | - | Mean opening of trawl during station (m). Read from SCANMAR . |
| `verticaltrawlopeningsd` | Trawl opening SD | decimal |  | - | Standard deviation of trawl opening (m). Read from SCANMAR. |
| `trawldoortype` | Door type | KeyType | yes | - | Code for type of trawldoor. |
| `trawldoorarea` | Door surface | decimal |  | - | Area of the trawl door in square meters. |
| `trawldoorweight` | Door weight | decimal |  | - | Weight of trawl door in kg. |
| `trawldoorspread` | Door spread | decimal |  | - | Mean distance between trawl-doors (m). Read from sensors mounted on doors. |
| `trawldoorspreadsd` | Door spread SD | decimal |  | - | Standard deviation of door spread (m). Accurate to one decimal point. Read from PC connected to SCANMAR (Scan-prog.) |
| `wingspread` | Wingspread | decimal |  | - | Mean wingspread (m) for the trawling. Read from sensor. |
| `wingspreadsd` | Wingspread SD | decimal |  | - | Standard deviation of wingspread (m). |
| `wirelength` | Wire length | decimal |  | - | Representative length of trawl-wires (m) during the station. |
| `wirediameter` | Wire diameter | decimal |  | - | Diameter for trawl wire (mm). |
| `wiredensity` | Wire density | decimal |  | - | Wire density in kg / m wire. |
| `soaktime` | Soak time | decimal |  | - | Time the gear has been in the sea. Given in decimal hours. |
| `tripno` | Trip numb. | integer |  | - | Trip number. Used by commercial vessels, such as the reference fleet. A trip is usually defined as the time period between departure from port and landing of catch. |
| `fishabundance` | Fish abundance | KeyType | yes | - | Code for amount of fish. Special field used 1989-1993. Legacy codes. See Norwegian documentation for additional information. |
| `fishdistribution` | Fish distribution | KeyType | yes | - | Code for vertical distribution of fish. Special field used 1989-1993. Legacy codes. See Norwegian documentation for additional information. |
| `landingsite` | Landing site | KeyType | yes | - | Code for landing site or location. |
| `fishingground` | Fishing ground | KeyType | yes | - | Name (code) of fishing grounds where the vessel is fishing. Reported from inspections. By the Directorate of Fisheries. |
| `vesselcount` | Count of vessels at ground | integer |  | - | Number of vessels fishing on fishing grounds. Reported from inspections from the directorate of fisheries. |
| `dataquality` | Data quality | KeyType | yes | - | Code for the quality of the data. See Norwegian documentation for additional details. If this field is not filled, specific knowledge of how the station was sampled is likely required to interpret the data from this station. |
| `haulvalidity` | Haul validity | KeyType | yes | - | Code for vailidty of haul. Conflated with the field <samplequality>. Conventions for which of these fields to use are governed by missiontype. |
| `flora` | Flora | KeyType | yes | - | Code for describing the kind of vegetation on seabed. |
| `vegetationcover` | Vegetation cover | KeyType | yes | - | Code for the amount of vegetational cover on seabed. |
| `visibility` | Visibility | KeyType | yes | - | Code for visibility through the water. Observed at end of station. |
| `waterlevel` | Water level | decimal |  | - | water level (cm). Measured with 5 cm presicion relative to normal height which is subjectively determined from growth on rocks etc. Observed at end of station. |
| `winddirection` | Wind direction | decimal |  | - | Direction of wind in degrees, relative to north. Observed at end of station. |
| `windspeed` | Wind speed | decimal |  | - | Wind speed (knots). Observed at end of station. |
| `clouds` | Clouds | KeyType | yes | - | Meterological code (WMO code 2700) describing the cloud coverage in unit: okta. Observed at end of station. |
| `sea` | Sea | KeyType | yes | - | Meterological code (WMO code 3700, Douglas Sea scale) describing height of waves. Observed at end of station. |
| `weather` | Weather | KeyType | yes | - | Meterological code (WMO code 4561) describing the weather. Observed at end of station. |
| `stationcomment` | Comment | string |  | - | Information about noteworthy events at the station. |
| `serialnumber` | Serial no | integer |  | stnall, indall | In addition to addressing via mission, a fishstation record is uniquely identified within a year (FishstationType/stationstartdate) by its serial number. Ranges of serial numbers are typically used for each samplingplatform or mission type, but are reallocated when needed. See Norwegian documenta... |

## `catchsample`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `commonname` | Taxa name | string |  | stnall, indall | Vernacular name or other non-standardized name for species or stock. |
| `catchcategory` | Species | KeyType | yes | stnall, indall | Species and stock code. Usually corresponds to taxonomic serial number (TSN/ITIS). Exceptions are marked in reference table. |
| `catchpartnumber` | Sample no. | integer |  | stnall, indall | Number to identify the sample given species and station. See Norwegian documentaiton for additional information. |
| `aphia` | Aphia-code | KeyType | yes | - | Code for taxonomic classification in the WORMS (World Register of Marine Species) database. |
| `scientificname` | Sci.name | string |  | - | Scientific name for taxonomic classification. |
| `identification` | Identification | KeyType | yes | - | Degree of certainty in identification of species. |
| `foreignobject` | Foreign object | KeyType | yes | - | Registering of non-biological material. |
| `sampletype` | Sample type | KeyType | yes | - | Code for the type of sample. See Norwegian documentation for historical codes and additional information. |
| `group` | Group | KeyType | yes | - | Code to flag if the sample is taken from a particular segment of the catch for this species. See Norwegian documentation for additional details. |
| `conservation` | Preservation | KeyType | yes | - | Code for how the sample is preserved. |
| `catchproducttype` | Product type | KeyType | yes | - | Description of the product on which measurements of total catch are performed <catchweight/>, <catchvolume/>. Amongst other things the degree of prosessing (gutting) of fish is desribed. |
| `raisingfactor` | Raising factor | decimal |  | - | Used if catch sample measurements (<catchweight/>, <catchvolume/> og<catchcount/>) were done on a representative subsample, rather than the entire catch. For instance when species are sorted after subsampling. The raising factor is the ratio of the total catch to the subsample. This field is not ... |
| `catchweight` | Weight | decimal |  | stnall, indall | Weigth (kg) of the part of the total catch that is represented by this sample. See <catchproducttype/> for product. If catch has been subsampled this is an estimate. The raising factor used is given by <raisingfactor/>, but total catch may be estimated even if <raisingfactor/> is not given. |
| `catchvolume` | Volume | decimal |  | - | Volume(l) of the part of the total catch that is represented by this sample. See <catchproducttype/> for product type. If catch has been subsampled this is an estimate. The raising factor used is given by <raisingfactor/>, but total catch may be estimated even if <raisingfactor/> is not given. |
| `catchcount` | Count | integer |  | stnall, indall | Count of fish in the part of the total catch that is represented by this sample. Often estimated from weight and count in length-measurements (<lengthsamplecount/>*<catchweight/>/<lenghsampleweight/>). |
| `abundancecategory` | Abundance category | KeyType | yes | - | Code for qualitative description of the amount of catch. |
| `sampleproducttype` | Sample product type | KeyType | yes | - | Description of the product on which sample measurements were made (<lengthsampleweight/>, <lengthsamplevolume/>). Amongst other things the degree of prosessing (gutting) of fish is desribed. |
| `lengthmeasurement` | Length measurement | KeyType | yes | - | Method of measurement. Length is measured for fish, diameter for jellyfish and carapax length etc. for shellfish. See Norwegian documentation for additional details. |
| `lengthsampleweight` | Length sample weight | decimal |  | stnall, indall | Weight (kg) of the fish for which length was measured. See <sampleproducttype/> for product type. |
| `lengthsamplevolume` | Length sample volum | decimal |  | - | Volume (l) of the fish for which length was measured. See <sampleproducttype/> for product type. |
| `lengthsamplecount` | Length sample count | integer |  | stnall, indall | Count of fish for which length was measured. Including samples where more measurements than length were done (<specimensamplecount/>. |
| `specimensamplecount` | Specimen sample count | integer |  | - | Count of fish for which detailed individual samples were taken (<individual/>). This refers to all samples where more than length measurements were taken. |
| `agesamplecount` | Age sample count | integer |  | - | Count of fish for which age samples were taken from this catch sample. |
| `agingstructure` | Aging structure | KeyType | yes | - | Specifies which kind of structure is collected for age determination. |
| `parasite` | Parasite | KeyType | yes | - | Specifies if parasites were checked for or found. |
| `stomach` | Stomach | KeyType | yes | - | Specifies the kind of stomach sampling done, if any. |
| `intestine` | Intestine | KeyType | yes | - | Specifies the kind of intestine sample collected, if any. |
| `tissuesample` | Genetics | KeyType | yes | - | Specifies if samples for genetic identification was taken. |
| `samplerecipient` | Sample frozen | KeyType | yes | - | Code for recipient of sample. Used when sample is shipped for further processing. |
| `catchcomment` | Comment | string |  | - | Information about observations on species or incidents while measuring. |
| `catchsampleid` | Catch sample no. | integer |  | stnall, indall | Catch sample number. Identifies a catch sample for a station. |

## `individual`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `individualproducttype` | Product type | KeyType | yes | - | Description of the product on which sample measurements was made (<individualweight/>, <individualvolume/>). Amongst other things the degree of prosessing (gutting) of fish is desribed. |
| `individualweight` | Weight | decimal |  | indall | Weight (kg). |
| `individualvolume` | Volume | decimal |  | - | Volume (l). |
| `lengthresolution` | Length interval | KeyType | yes | - | Code for the precision used when measuring length. |
| `length` | Length | decimal |  | indall | Length (m). Measured to the precision specified by <lengthresolution/>. As specified in <CatchsampleType/lengthmeasurement>. Electronic registration from measuring devices may provide data that seem to be of higher resolution, but the resolution provided in <lengthresolution/> still reflects the ... |
| `fat` | Fat | KeyType | yes | - | Code for qualitative specification of fat in fish. |
| `fatpercent` | Fat percent | decimal |  | - | Measurement of fat content as fraction in filet (%) using instrument from Distell. Used for Herring and Mackerel. |
| `sex` | Sex | KeyType | yes | indall | Codef or sex. |
| `maturationstage` | Stage | KeyType | yes | indall | Maturation given by the general description of stage. See the Norwegian documentation for additional detail. |
| `specialstage` | Spec. stage | CompositeTaxaSexKeyType | yes | indall | Maturation given by species specific descriptions. See the reference table and the Norwegian documentation for additional details. Reference table is organised under taxa, and lookup can be done using species, sex and code. |
| `eggstage` | Egg stage | CompositeTaxaSexKeyType | yes | - | Stadium used for capelin. See the reference table and the Norwegian documentation for additional information. Reference table is organised under taxa, and lookup can be done using species, sex and code. |
| `moultingstage` | Moulting stage | CompositeTaxaKeyType | yes | - | Moulting stage. See Norwegian documentation for additional details. |
| `spawningfrequency` | Spawning frequency | CompositeTaxaKeyType | yes | - | Code for Frequency of spawning. Used for some shellfish. |
| `stomachfillfield` | Stomach fill Field | KeyType | yes | - | Stomach content, as determined in field. |
| `stomachfilllab` | Stomach fill Lab. | KeyType | yes | - | Stomach content, as determined in laboratory. |
| `digestion` | Digestion | KeyType | yes | - | Degree of digestion. |
| `liver` | Liver | KeyType | yes | - | Qualitative description of the size of the liver. |
| `liverparasite` | Liver parasite | KeyType | yes | - | Qualitative description of the amount of parasites on the liver. |
| `gillworms` | Gill worms | KeyType | yes | - | Denotes any finding of gillworms. |
| `swollengills` | Gill tumors | KeyType | yes | - | Denotes if gills are swollen due to gill tumors. |
| `fungusheart` | Fungus-heart | KeyType | yes | - | Signs of fungal disease from inspection of heart. |
| `fungusspores` | Fungal spores | KeyType | yes | - | Signs of fungal disease from microscopic examination of heart. |
| `fungusouter` | Fungus-outer | KeyType | yes | - | Signs of fungal disease from external examination. |
| `blackspot` | Black spot | KeyType | yes | - | Small black spots on the fish. Used for cod. |
| `vertebraecount` | Vertebrae | integer |  | - | The number of vertebrae. See Norwegian documentation for additional details. |
| `gonadweight` | Gonad weight | decimal |  | - | Weight gonade (kg). |
| `liverweight` | Liver weight | decimal |  | - | Weight liver (kg). |
| `stomachweight` | Stomach weight | decimal |  | - | Weight stomach (kg). |
| `diameter` | Diameter | decimal |  | - | Diameter (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `mantlelength` | Mantle length | decimal |  | - | Mantle length (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `carapacelength` | Carapace length | decimal |  | - | Carapace length (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `headlength` | Head length | decimal |  | - | Head length (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `snouttoendoftail` | Snout to end of tail | decimal |  | - | Snout to end of tail (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `snouttoendsqueezed` | Snout to end of tail squeezed | decimal |  | - | Snout to end of tail squeezed (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `snouttoanalfin` | Snout to anal fin | decimal |  | - | Snout to anal fin (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `snouttodorsalfin` | Snout to dorsal fin | decimal |  | - | Snout to dorsal fin (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `forklength` | Fork length | decimal |  | - | Snout to fork in tail (Fork length, m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `snouttoboneknob` | Snout to bone knob | decimal |  | - | Snout to bone knob (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `lengthwithouthead` | Length without head | decimal |  | - | Length without head (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `carapacewidth` | Carapace width | decimal |  | - | Carapace width (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `rightclawwidth` | Width of right claw | decimal |  | - | Width of right claw (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `rightclawlength` | Length of right claw | decimal |  | - | Length of right claw (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `meroswidth` | Width of third foot meros | decimal |  | - | Width of third foot meros (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `meroslength` | Length of third foot meros | decimal |  | - | Length of third foot meros (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `japanesecut` | Japanese cut | decimal |  | - | Japanese cut (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `abdomenwidth` | Abdomen width | decimal |  | - | Abdomen width (m). Only specified if this is measured in addition to main length measurement (<CatchsampleType/lengthmeasurement>). |
| `tissuesamplenumber` | Tissue sample no. | integer |  | - | Identifier for tissue samples. |
| `individualcomment` | Comment | string |  | - | Comments. |
| `preferredagereading` | App. Agereading | integer |  | - | Indicates preferred age reading for an individual refers to <AgedterminationType/agedeterminationid>. |
| `specimenid` | Specimen no. | integer |  | indall | Identifies the individual in a catchsample |

## `agedetermination`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `agingstructureread` | Aging structure read | CompositeTaxaKeyType | yes | - | Code for specifying which aging structure was read. |
| `agingstructureweight` | Weight of ageing structure | decimal |  | - | Weight in mg. |
| `agingstructurelength` | Length of ageing structure | decimal |  | - | Length in mm. |
| `nowearpoint` | NWP | decimal |  | - | The spine thickness (mm) at the point where the enamel is starting to be worn and the zones are no longer counted. Measured in the fish's longitudinal direction. |
| `externalspinebase` | ESB | decimal |  | - | The spine thickness (mm) at the base of the spine. Measured in the fish´ longitudinal direction. |
| `countedannualage` | Counted annual zones | integer |  | - | The interpreted number of annual zones in the enamel of the spine. If the enamel is worn on the outer part of the spine, zones are counted from the base to the point where the enamel is starting to be worn, the no-wear-point (NWP). |
| `age` | Age | integer |  | indall | Age. See Norwegian documentation for details about how age is determined. |
| `spawningage` | Spawning age | integer |  | - | Age of specimen at first spawning. |
| `smoltage` | Smolt age | integer |  | - | Smolt age read from scales. The smolt age is the number of years spent in river before migration to sea. |
| `marineage` | Marine age | integer |  | - | Marine age read from scales. The marine age is the number of years spent in sea, after migration from river. |
| `spawningzones` | Spawning zones | integer |  | - | The number of spawning zones read. |
| `readability` | Readability | KeyType | yes | indall | Code for legibility of aging structure. |
| `otolithtype` | Otolith type | CompositeTaxaKeyType | yes | - | Classification of otolith. See Norwegian documentation for additional details. |
| `otolithedge` | Otolith edge | KeyType | yes | - | Desciption of edge on otolith. |
| `otolithcentre` | Otolith centre | KeyType | yes | - | Description of otolith core. |
| `calibration` | Calibration | integer |  | - | The number of divisions in the eyepiece graticule on 2 milimeters. Calibration is done for the lens and magnification used when reading the growthzones. |
| `growthzone1` | Growthzone 1 | integer |  | - | Size of growth zone in integer number of divisions (see <calibration/>). |
| `growthzone2` | Growthzone 2 | integer |  | - | Size of growth zone in integer number of divisions (see <calibration/>). |
| `growthzone3` | Growthzone 3 | integer |  | - | Size of growth zone in integer number of divisions (see <calibration/>). |
| `growthzone4` | Growthzone 4 | integer |  | - | Size of growth zone in integer number of divisions (see <calibration/>). |
| `growthzone5` | Growthzone 5 | integer |  | - | Size of growth zone in integer number of divisions (see <calibration/>). |
| `growthzone6` | Growthzone 6 | integer |  | - | Size of growth zone in integer number of divisions (see <calibration/>). |
| `growthzone7` | Growthzone 7 | integer |  | - | Size of growth zone in integer number of divisions (see <calibration/>). |
| `growthzone8` | Growthzone 8 | integer |  | - | Size of growth zone in integer number of divisions (see <calibration/>). |
| `growthzone9` | Growthzone 9 | integer |  | - | Size of growth zone in integer number of divisions (see <calibration/>). |
| `growthzonestotal` | Growth zones total | integer |  | - | Total number of growth zones measured. |
| `coastalannuli` | Coastal annuli | integer |  | - | Historically used for a Norwegian spring-spawning herring stock. See Norwgeian documentaiton for additional details. |
| `oceanicannuli` | Oceanic annuli | integer |  | - | Historically used for a Norwegian spring-spawning herring stock. See Norwgeian documentaiton for additional details. |
| `blindreading` | Blind reading | KeyType | yes | - | Age was determined without knowledge of length, weight, sex or maturation. |
| `readingdate` | Reading date | date |  | - | Date (UTC) when age was read. |
| `agereader` | Age reader | KeyType | yes | - | Code to identify the person that read the age. |
| `agedeterminationid` | No | integer |  | - | Identifies age reading |

## `prey`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `preypartnumber` | Sample no. | integer |  | - | Identifies the prey sample. Use different number for different prey samples that are of the same species and taken from the same individual. |
| `preycategory` | Species | KeyType | yes | - | Species of prey (TSN code). |
| `source` | Source | KeyType | yes | - | Code to indicate the source of the prey sample. |
| `preydigestion` | Digestion | KeyType | yes | - | Degree of digestion of prey. |
| `totalcount` | Count | integer |  | - | Number of individuals of this prey in stomach. |
| `weightresolution` | Weight unit | KeyType | yes | - | The precision of the weight (<totalweight/>). |
| `totalweight` | Prey weight | decimal |  | - | Total weight of prey (kg). Precision of measurement as identified in <weightresolution/>. |
| `interval` | Interval | KeyType | yes | - | Interval for length groups measured <preylength/>. |
| `devstage` | Dev. stage | KeyType | yes | - | Developmental stage for prey. |
| `preylengthmeasurement` | Length unit | KeyType | yes | - | Code for method of measurement for lengths given as <preylength/>. |
| `preysampleid` | Prey sample no. | integer |  | - | Identifies prey sample from a predator. |

## `tag`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `tagtype` | Tag type | KeyType | yes | - | Code for the type of tag used. |
| `tagid` | Tag no. | integer |  | - | Tag number for tagged or recaptured fish. |

## Other elements

<details><summary>Expand the full list of remaining elements</summary>


## `agereadertable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `reference` |  | ref:AgeReaderElementType |  | - | KeyType t, indexes reference/code==t |

## `copepodedevstage`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `devstagecount` | Count | integer |  | - | The number of organisms in the given developmental stage <copepodedevstage/>. |
| `copepodedevstage` | Copep. stage | KeyType | yes | - | Copepode stadium whoose count is given in <devstagecount/>. |

## `fixedstationtable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `reference` |  | ref:FixedCoastalstationType |  | - | KeyType t, indexes reference/station==t |

## `geartable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `reference` |  | ref:EquipmentElementType |  | - | KeyType t, indexes reference/code==t |

## `list`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `row` |  | anyType |  | - |  |

## `listtable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `reference` |  | ref:KeyValueElementType |  | - | KeyType indexes reference/code |

## `missiontypetable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `reference` |  | ref:MissionTypeElementType |  | - | KeyType t, indexes reference/code==t |

## `nationtable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `reference` |  | ref:NationElementType |  | - | KeyType t, indexes reference/nation==t |

## `platformtable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `reference` |  | ref:PlatformElementType |  | - | KeyType t, indexes reference/platformnumber |

## `preylength`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `lengthintervalstart` | Length | decimal |  | - | Shortest length (inclusive) for organisms counted in <lengthintervalcount/>. Given in meters. |
| `lengthintervalcount` | Count | integer |  | - | The number of organisms in the interval given by the lower limit <lengthintervalstart/> and PreyType/<interval/>. |
| `preylengthid` | No | integer |  | - | Identifies a line of length measurements in frequency table. |

## `referencetable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `referenceurl` |  | string |  | - | Url identifying a referece table for all possible (legal) codes for the data. |

## `taxatable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `reference` |  | ref:TaxaElementType |  | - | Type for associating KeyTypes to the reference table taxa. KeyType t, indexes ref:reference/tsn==t. Taxa-conditional reference data are also found in this structure through composite keys. referencedata for specialstage has key composed from CompositeTaxaSexKeyType key and are located in: ref:ref... |

## `trawldoortable`

| column | label (EN) | type | code? | in | description (EN) |
|---|---|---|---|---|---|
| `reference` |  | ref:TrawldoorElementType |  | - | KeyType t, indexes reference/code==t |

</details>
