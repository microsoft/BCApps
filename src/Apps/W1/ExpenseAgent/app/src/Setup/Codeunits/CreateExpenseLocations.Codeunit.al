// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7104 "Create Expense Locations"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Expense Location";

    trigger OnRun()
    begin
        InsertExpenseLocations(Rec);
    end;

    internal procedure InsertExpenseLocations(var ExpenseLocation: Record "Expense Location")
    begin
        InsertExpenseLocation(ExpenseLocation, CanadaAll(), CanadaAllLocationLbl, 'CA', '', '');
        InsertExpenseLocation(ExpenseLocation, DenmarkAll(), DenmarkLbl, 'DK', '', '');
        InsertExpenseLocation(ExpenseLocation, DenmarkCph(), DKCopenhagenLbl, 'DK', CopenhagenLbl, '');
        InsertExpenseLocation(ExpenseLocation, Domestic(), DomesticLbl, '', '', '');
        InsertExpenseLocation(ExpenseLocation, FranceAll(), FranceLbl, 'FR', '', '');
        InsertExpenseLocation(ExpenseLocation, FranceParis(), FranceParisLbl, 'FR', ParisLbl, '');
        InsertExpenseLocation(ExpenseLocation, GermanyAll(), GermanyLbl, 'DE', '', '');
        InsertExpenseLocation(ExpenseLocation, UKLondon(), UKLondonAreaLbl, 'GB', LondonLbl, '');
        InsertExpenseLocation(ExpenseLocation, UKOther(), UKOtherLbl, 'GB', '', '');
        InsertExpenseLocation(ExpenseLocation, USAFlorida(), USAFloridaLbl, 'US', '', FLLbl);
        InsertExpenseLocation(ExpenseLocation, USANY(), USANYLbl, 'US', NewYorkLbl, '');
        InsertExpenseLocation(ExpenseLocation, USAOther(), USAOtherLbl, 'US', '', '');
        InsertExpenseLocation(ExpenseLocation, UnitedArabEmiratesAll(), UnitedArabEmiratesAllLocationLbl, 'AE', '', '');
        InsertExpenseLocation(ExpenseLocation, AustriaAll(), AustriaAllLocationLbl, 'AT', '', '');
        InsertExpenseLocation(ExpenseLocation, AustraliaAll(), AustraliaAllLocationLbl, 'AU', '', '');
        InsertExpenseLocation(ExpenseLocation, BelgiumAll(), BelgiumAllLocationLbl, 'BE', '', '');
        InsertExpenseLocation(ExpenseLocation, BulgariaAll(), BulgariaAllLocationLbl, 'BG', '', '');
        InsertExpenseLocation(ExpenseLocation, BruneiDarussalamAll(), BruneiDarussalamAllLocationLbl, 'BN', '', '');
        InsertExpenseLocation(ExpenseLocation, BrazilAll(), BrazilAllLocationLbl, 'BR', '', '');
        InsertExpenseLocation(ExpenseLocation, SwitzerlandAll(), SwitzerlandAllLocationLbl, 'CH', '', '');
        InsertExpenseLocation(ExpenseLocation, SwitzerlandGeneva(), SwitzerlandGenevaLbl, 'CH', GenevaLbl, '');
        InsertExpenseLocation(ExpenseLocation, SwitzerlandZurich(), SwitzerlandZurichLbl, 'CH', ZurichLbl, '');
        InsertExpenseLocation(ExpenseLocation, ChinaAll(), ChinaAllLocationLbl, 'CN', '', '');
        InsertExpenseLocation(ExpenseLocation, CostaRicaAll(), CostaRicaAllLocationLbl, 'CR', '', '');
        InsertExpenseLocation(ExpenseLocation, CyprusAll(), CyprusAllLocationLbl, 'CY', '', '');
        InsertExpenseLocation(ExpenseLocation, CzechiaAll(), CzechiaAllLocationLbl, 'CZ', '', '');
        InsertExpenseLocation(ExpenseLocation, AlgeriaAll(), AlgeriaAllLocationLbl, 'DZ', '', '');
        InsertExpenseLocation(ExpenseLocation, EstoniaAll(), EstoniaAllLocationLbl, 'EE', '', '');
        InsertExpenseLocation(ExpenseLocation, GreeceAll(), GreeceAllLocationLbl, 'EL', '', '');
        InsertExpenseLocation(ExpenseLocation, SpainAll(), SpainAllLocationLbl, 'ES', '', '');
        InsertExpenseLocation(ExpenseLocation, FinlandAll(), FinlandAllLocationLbl, 'FI', '', '');
        InsertExpenseLocation(ExpenseLocation, FijiIslandsAll(), FijiIslandsAllLocationLbl, 'FJ', '', '');
        InsertExpenseLocation(ExpenseLocation, CroatiaAll(), CroatiaAllLocationLbl, 'HR', '', '');
        InsertExpenseLocation(ExpenseLocation, HungaryAll(), HungaryAllLocationLbl, 'HU', '', '');
        InsertExpenseLocation(ExpenseLocation, IndonesiaAll(), IndonesiaAllLocationLbl, 'ID', '', '');
        InsertExpenseLocation(ExpenseLocation, IrelandAll(), IrelandAllLocationLbl, 'IE', '', '');
        InsertExpenseLocation(ExpenseLocation, IndiaAll(), IndiaAllLocationLbl, 'IN', '', '');
        InsertExpenseLocation(ExpenseLocation, IcelandAll(), IcelandAllLocationLbl, 'IS', '', '');
        InsertExpenseLocation(ExpenseLocation, ItalyAll(), ItalyAllLocationLbl, 'IT', '', '');
        InsertExpenseLocation(ExpenseLocation, JapanAll(), JapanAllLocationLbl, 'JP', '', '');
        InsertExpenseLocation(ExpenseLocation, JapanTokyo(), JapanTokyoLbl, 'JP', TokyoLbl, '');
        InsertExpenseLocation(ExpenseLocation, KenyaAll(), KenyaAllLocationLbl, 'KE', '', '');
        InsertExpenseLocation(ExpenseLocation, LithuaniaAll(), LithuaniaAllLocationLbl, 'LT', '', '');
        InsertExpenseLocation(ExpenseLocation, LuxembourgAll(), LuxembourgAllLocationLbl, 'LU', '', '');
        InsertExpenseLocation(ExpenseLocation, LatviaAll(), LatviaAllLocationLbl, 'LV', '', '');
        InsertExpenseLocation(ExpenseLocation, MoroccoAll(), MoroccoAllLocationLbl, 'MA', '', '');
        InsertExpenseLocation(ExpenseLocation, MontenegroAll(), MontenegroAllLocationLbl, 'ME', '', '');
        InsertExpenseLocation(ExpenseLocation, MaltaAll(), MaltaAllLocationLbl, 'MT', '', '');
        InsertExpenseLocation(ExpenseLocation, MexicoAll(), MexicoAllLocationLbl, 'MX', '', '');
        InsertExpenseLocation(ExpenseLocation, MalaysiaAll(), MalaysiaAllLocationLbl, 'MY', '', '');
        InsertExpenseLocation(ExpenseLocation, MozambiqueAll(), MozambiqueAllLocationLbl, 'MZ', '', '');
        InsertExpenseLocation(ExpenseLocation, NigeriaAll(), NigeriaAllLocationLbl, 'NG', '', '');
        InsertExpenseLocation(ExpenseLocation, NorthernIrelandAll(), NorthernIrelandAllLocationLbl, 'NI', '', '');
        InsertExpenseLocation(ExpenseLocation, NetherlandsAll(), NetherlandsAllLocationLbl, 'NL', '', '');
        InsertExpenseLocation(ExpenseLocation, NorwayAll(), NorwayAllLocationLbl, 'NO', '', '');
        InsertExpenseLocation(ExpenseLocation, NorwayOslo(), NorwayOsloLbl, 'NO', OsloLbl, '');
        InsertExpenseLocation(ExpenseLocation, NewZealandAll(), NewZealandAllLocationLbl, 'NZ', '', '');
        InsertExpenseLocation(ExpenseLocation, PhilippinesAll(), PhilippinesAllLocationLbl, 'PH', '', '');
        InsertExpenseLocation(ExpenseLocation, PolandAll(), PolandAllLocationLbl, 'PL', '', '');
        InsertExpenseLocation(ExpenseLocation, PortugalAll(), PortugalAllLocationLbl, 'PT', '', '');
        InsertExpenseLocation(ExpenseLocation, RomaniaAll(), RomaniaAllLocationLbl, 'RO', '', '');
        InsertExpenseLocation(ExpenseLocation, SerbiaAll(), SerbiaAllLocationLbl, 'RS', '', '');
        InsertExpenseLocation(ExpenseLocation, RussiaAll(), RussiaAllLocationLbl, 'RU', '', '');
        InsertExpenseLocation(ExpenseLocation, SaudiArabiaAll(), SaudiArabiaAllLocationLbl, 'SA', '', '');
        InsertExpenseLocation(ExpenseLocation, SolomonIslandsAll(), SolomonIslandsAllLocationLbl, 'SB', '', '');
        InsertExpenseLocation(ExpenseLocation, SwedenAll(), SwedenAllLocationLbl, 'SE', '', '');
        InsertExpenseLocation(ExpenseLocation, SingaporeAll(), SingaporeAllLocationLbl, 'SG', '', '');
        InsertExpenseLocation(ExpenseLocation, SloveniaAll(), SloveniaAllLocationLbl, 'SI', '', '');
        InsertExpenseLocation(ExpenseLocation, SlovakiaAll(), SlovakiaAllLocationLbl, 'SK', '', '');
        InsertExpenseLocation(ExpenseLocation, SwazilandAll(), SwazilandAllLocationLbl, 'SZ', '', '');
        InsertExpenseLocation(ExpenseLocation, ThailandAll(), ThailandAllLocationLbl, 'TH', '', '');
        InsertExpenseLocation(ExpenseLocation, TunisiaAll(), TunisiaAllLocationLbl, 'TN', '', '');
        InsertExpenseLocation(ExpenseLocation, TurkiyeAll(), TurkiyeAllLocationLbl, 'TR', '', '');
        InsertExpenseLocation(ExpenseLocation, TanzaniaAll(), TanzaniaAllLocationLbl, 'TZ', '', '');
        InsertExpenseLocation(ExpenseLocation, UgandaAll(), UgandaAllLocationLbl, 'UG', '', '');
        InsertExpenseLocation(ExpenseLocation, VanuatuAll(), VanuatuAllLocationLbl, 'VU', '', '');
        InsertExpenseLocation(ExpenseLocation, SamoaAll(), SamoaAllLocationLbl, 'WS', '', '');
        InsertExpenseLocation(ExpenseLocation, SouthAfricaAll(), SouthAfricaAllLocationLbl, 'ZA', '', '');
        InsertExpenseLocation(ExpenseLocation, AfghanistanAll(), AfghanistanAllLocationLbl, 'AF', '', '');
        InsertExpenseLocation(ExpenseLocation, AlbaniaAll(), AlbaniaAllLocationLbl, 'AL', '', '');
        InsertExpenseLocation(ExpenseLocation, AndorraAll(), AndorraAllLocationLbl, 'AD', '', '');
        InsertExpenseLocation(ExpenseLocation, AngolaAll(), AngolaAllLocationLbl, 'AO', '', '');
        InsertExpenseLocation(ExpenseLocation, AnguillaAll(), AnguillaAllLocationLbl, 'AI', '', '');
        InsertExpenseLocation(ExpenseLocation, AntarcticaAll(), AntarcticaAllLocationLbl, 'AQ', '', '');
        InsertExpenseLocation(ExpenseLocation, AntiguaBarbudaAll(), AntiguaBarbudaAllLocationLbl, 'AG', '', '');
        InsertExpenseLocation(ExpenseLocation, ArgentinaAll(), ArgentinaAllLocationLbl, 'AR', '', '');
        InsertExpenseLocation(ExpenseLocation, ArmeniaAll(), ArmeniaAllLocationLbl, 'AM', '', '');
        InsertExpenseLocation(ExpenseLocation, ArubaAll(), ArubaAllLocationLbl, 'AW', '', '');
        InsertExpenseLocation(ExpenseLocation, AzerbaijanAll(), AzerbaijanAllLocationLbl, 'AZ', '', '');
        InsertExpenseLocation(ExpenseLocation, BahamasAll(), BahamasAllLocationLbl, 'BS', '', '');
        InsertExpenseLocation(ExpenseLocation, BahrainAll(), BahrainAllLocationLbl, 'BH', '', '');
        InsertExpenseLocation(ExpenseLocation, BangladeshAll(), BangladeshAllLocationLbl, 'BD', '', '');
        InsertExpenseLocation(ExpenseLocation, BarbadosAll(), BarbadosAllLocationLbl, 'BB', '', '');
        InsertExpenseLocation(ExpenseLocation, BelarusAll(), BelarusAllLocationLbl, 'BY', '', '');
        InsertExpenseLocation(ExpenseLocation, BelizeAll(), BelizeAllLocationLbl, 'BZ', '', '');
        InsertExpenseLocation(ExpenseLocation, BeninAll(), BeninAllLocationLbl, 'BJ', '', '');
        InsertExpenseLocation(ExpenseLocation, BermudaAll(), BermudaAllLocationLbl, 'BM', '', '');
        InsertExpenseLocation(ExpenseLocation, BhutanAll(), BhutanAllLocationLbl, 'BT', '', '');
        InsertExpenseLocation(ExpenseLocation, BoliviaAll(), BoliviaAllLocationLbl, 'BO', '', '');
        InsertExpenseLocation(ExpenseLocation, BonaireAll(), BonaireAllLocationLbl, 'BQ', '', '');
        InsertExpenseLocation(ExpenseLocation, BosniaHerzegovinaAll(), BosniaHerzegovinaAllLocationLbl, 'BA', '', '');
        InsertExpenseLocation(ExpenseLocation, BotswanaAll(), BotswanaAllLocationLbl, 'BW', '', '');
        InsertExpenseLocation(ExpenseLocation, BouvetIslandAll(), BouvetIslandAllLocationLbl, 'BV', '', '');
        InsertExpenseLocation(ExpenseLocation, BritishIndianOceanAll(), BritishIndianOceanAllLocationLbl, 'IO', '', '');
        InsertExpenseLocation(ExpenseLocation, BurkinaFasoAll(), BurkinaFasoAllLocationLbl, 'BF', '', '');
        InsertExpenseLocation(ExpenseLocation, BurundiAll(), BurundiAllLocationLbl, 'BI', '', '');
        InsertExpenseLocation(ExpenseLocation, CaboVerdeAll(), CaboVerdeAllLocationLbl, 'CV', '', '');
        InsertExpenseLocation(ExpenseLocation, CambodiaAll(), CambodiaAllLocationLbl, 'KH', '', '');
        InsertExpenseLocation(ExpenseLocation, CameroonAll(), CameroonAllLocationLbl, 'CM', '', '');
        InsertExpenseLocation(ExpenseLocation, CaymanIslandsAll(), CaymanIslandsAllLocationLbl, 'KY', '', '');
        InsertExpenseLocation(ExpenseLocation, CentralAfricanAll(), CentralAfricanAllLocationLbl, 'CF', '', '');
        InsertExpenseLocation(ExpenseLocation, ChadAll(), ChadAllLocationLbl, 'TD', '', '');
        InsertExpenseLocation(ExpenseLocation, ChileAll(), ChileAllLocationLbl, 'CL', '', '');
        InsertExpenseLocation(ExpenseLocation, ChristmasIslandAll(), ChristmasIslandAllLocationLbl, 'CX', '', '');
        InsertExpenseLocation(ExpenseLocation, CocosIslandsAll(), CocosIslandsAllLocationLbl, 'CC', '', '');
        InsertExpenseLocation(ExpenseLocation, ColombiaAll(), ColombiaAllLocationLbl, 'CO', '', '');
        InsertExpenseLocation(ExpenseLocation, ComorosAll(), ComorosAllLocationLbl, 'KM', '', '');
        InsertExpenseLocation(ExpenseLocation, CongoDRAll(), CongoDRAllLocationLbl, 'CD', '', '');
        InsertExpenseLocation(ExpenseLocation, CongoAll(), CongoAllLocationLbl, 'CG', '', '');
        InsertExpenseLocation(ExpenseLocation, CookIslandsAll(), CookIslandsAllLocationLbl, 'CK', '', '');
        InsertExpenseLocation(ExpenseLocation, CubaAll(), CubaAllLocationLbl, 'CU', '', '');
        InsertExpenseLocation(ExpenseLocation, CuracaoAll(), CuracaoAllLocationLbl, 'CW', '', '');
        InsertExpenseLocation(ExpenseLocation, CotedIvoireAll(), CotedIvoireAllLocationLbl, 'CI', '', '');
        InsertExpenseLocation(ExpenseLocation, DjiboutiAll(), DjiboutiAllLocationLbl, 'DJ', '', '');
        InsertExpenseLocation(ExpenseLocation, DominicaAll(), DominicaAllLocationLbl, 'DM', '', '');
        InsertExpenseLocation(ExpenseLocation, DominicanAll(), DominicanAllLocationLbl, 'DO', '', '');
        InsertExpenseLocation(ExpenseLocation, EcuadorAll(), EcuadorAllLocationLbl, 'EC', '', '');
        InsertExpenseLocation(ExpenseLocation, EgyptAll(), EgyptAllLocationLbl, 'EG', '', '');
        InsertExpenseLocation(ExpenseLocation, ElSalvadorAll(), ElSalvadorAllLocationLbl, 'SV', '', '');
        InsertExpenseLocation(ExpenseLocation, EquatorialGuineaAll(), EquatorialGuineaAllLocationLbl, 'GQ', '', '');
        InsertExpenseLocation(ExpenseLocation, EritreaAll(), EritreaAllLocationLbl, 'ER', '', '');
        InsertExpenseLocation(ExpenseLocation, EthiopiaAll(), EthiopiaAllLocationLbl, 'ET', '', '');
        InsertExpenseLocation(ExpenseLocation, FalklandIslandsAll(), FalklandIslandsAllLocationLbl, 'FK', '', '');
        InsertExpenseLocation(ExpenseLocation, FaroeIslandsAll(), FaroeIslandsAllLocationLbl, 'FO', '', '');
        InsertExpenseLocation(ExpenseLocation, FrenchGuianaAll(), FrenchGuianaAllLocationLbl, 'GF', '', '');
        InsertExpenseLocation(ExpenseLocation, FrenchPolynesiaAll(), FrenchPolynesiaAllLocationLbl, 'PF', '', '');
        InsertExpenseLocation(ExpenseLocation, FrenchSouthernAll(), FrenchSouthernAllLocationLbl, 'TF', '', '');
        InsertExpenseLocation(ExpenseLocation, GabonAll(), GabonAllLocationLbl, 'GA', '', '');
        InsertExpenseLocation(ExpenseLocation, GambiaAll(), GambiaAllLocationLbl, 'GM', '', '');
        InsertExpenseLocation(ExpenseLocation, GeorgiaAll(), GeorgiaAllLocationLbl, 'GE', '', '');
        InsertExpenseLocation(ExpenseLocation, GhanaAll(), GhanaAllLocationLbl, 'GH', '', '');
        InsertExpenseLocation(ExpenseLocation, GibraltarAll(), GibraltarAllLocationLbl, 'GI', '', '');
        InsertExpenseLocation(ExpenseLocation, GreenlandAll(), GreenlandAllLocationLbl, 'GL', '', '');
        InsertExpenseLocation(ExpenseLocation, GrenadaAll(), GrenadaAllLocationLbl, 'GD', '', '');
        InsertExpenseLocation(ExpenseLocation, GuadeloupeAll(), GuadeloupeAllLocationLbl, 'GP', '', '');
        InsertExpenseLocation(ExpenseLocation, GuamAll(), GuamAllLocationLbl, 'GU', '', '');
        InsertExpenseLocation(ExpenseLocation, GuatemalaAll(), GuatemalaAllLocationLbl, 'GT', '', '');
        InsertExpenseLocation(ExpenseLocation, GuernseyAll(), GuernseyAllLocationLbl, 'GG', '', '');
        InsertExpenseLocation(ExpenseLocation, GuineaAll(), GuineaAllLocationLbl, 'GN', '', '');
        InsertExpenseLocation(ExpenseLocation, GuineaBissauAll(), GuineaBissauAllLocationLbl, 'GW', '', '');
        InsertExpenseLocation(ExpenseLocation, GuyanaAll(), GuyanaAllLocationLbl, 'GY', '', '');
        InsertExpenseLocation(ExpenseLocation, HaitiAll(), HaitiAllLocationLbl, 'HT', '', '');
        InsertExpenseLocation(ExpenseLocation, HeardIslandAll(), HeardIslandAllLocationLbl, 'HM', '', '');
        InsertExpenseLocation(ExpenseLocation, HolySeeAll(), HolySeeAllLocationLbl, 'VA', '', '');
        InsertExpenseLocation(ExpenseLocation, HondurasAll(), HondurasAllLocationLbl, 'HN', '', '');
        InsertExpenseLocation(ExpenseLocation, HongKongAll(), HongKongAllLocationLbl, 'HK', '', '');
        InsertExpenseLocation(ExpenseLocation, IsleManAll(), IsleManAllLocationLbl, 'IM', '', '');
        InsertExpenseLocation(ExpenseLocation, IsraelAll(), IsraelAllLocationLbl, 'IL', '', '');
        InsertExpenseLocation(ExpenseLocation, JamaicaAll(), JamaicaAllLocationLbl, 'JM', '', '');
        InsertExpenseLocation(ExpenseLocation, JerseyAll(), JerseyAllLocationLbl, 'JE', '', '');
        InsertExpenseLocation(ExpenseLocation, JordanAll(), JordanAllLocationLbl, 'JO', '', '');
        InsertExpenseLocation(ExpenseLocation, KazakhstanAll(), KazakhstanAllLocationLbl, 'KZ', '', '');
        InsertExpenseLocation(ExpenseLocation, KiribatiAll(), KiribatiAllLocationLbl, 'KI', '', '');
        InsertExpenseLocation(ExpenseLocation, NorthKoreaAll(), NorthKoreaAllLocationLbl, 'KP', '', '');
        InsertExpenseLocation(ExpenseLocation, SouthKoreaAll(), SouthKoreaAllLocationLbl, 'KR', '', '');
        InsertExpenseLocation(ExpenseLocation, KuwaitAll(), KuwaitAllLocationLbl, 'KW', '', '');
        InsertExpenseLocation(ExpenseLocation, KyrgyzstanAll(), KyrgyzstanAllLocationLbl, 'KG', '', '');
        InsertExpenseLocation(ExpenseLocation, LaosAll(), LaosAllLocationLbl, 'LA', '', '');
        InsertExpenseLocation(ExpenseLocation, LebanonAll(), LebanonAllLocationLbl, 'LB', '', '');
        InsertExpenseLocation(ExpenseLocation, LesothoAll(), LesothoAllLocationLbl, 'LS', '', '');
        InsertExpenseLocation(ExpenseLocation, LiberiaAll(), LiberiaAllLocationLbl, 'LR', '', '');
        InsertExpenseLocation(ExpenseLocation, LibyaAll(), LibyaAllLocationLbl, 'LY', '', '');
        InsertExpenseLocation(ExpenseLocation, LiechtensteinAll(), LiechtensteinAllLocationLbl, 'LI', '', '');
        InsertExpenseLocation(ExpenseLocation, MacaoAll(), MacaoAllLocationLbl, 'MO', '', '');
        InsertExpenseLocation(ExpenseLocation, MadagascarAll(), MadagascarAllLocationLbl, 'MG', '', '');
        InsertExpenseLocation(ExpenseLocation, MalawiAll(), MalawiAllLocationLbl, 'MW', '', '');
        InsertExpenseLocation(ExpenseLocation, MaldivesAll(), MaldivesAllLocationLbl, 'MV', '', '');
        InsertExpenseLocation(ExpenseLocation, MaliAll(), MaliAllLocationLbl, 'ML', '', '');
        InsertExpenseLocation(ExpenseLocation, MarshallIslandsAll(), MarshallIslandsAllLocationLbl, 'MH', '', '');
        InsertExpenseLocation(ExpenseLocation, MartiniqueAll(), MartiniqueAllLocationLbl, 'MQ', '', '');
        InsertExpenseLocation(ExpenseLocation, MauritaniaAll(), MauritaniaAllLocationLbl, 'MR', '', '');
        InsertExpenseLocation(ExpenseLocation, MauritiusAll(), MauritiusAllLocationLbl, 'MU', '', '');
        InsertExpenseLocation(ExpenseLocation, MayotteAll(), MayotteAllLocationLbl, 'YT', '', '');
        InsertExpenseLocation(ExpenseLocation, MicronesiaAll(), MicronesiaAllLocationLbl, 'FM', '', '');
        InsertExpenseLocation(ExpenseLocation, MoldovaAll(), MoldovaAllLocationLbl, 'MD', '', '');
        InsertExpenseLocation(ExpenseLocation, MonacoAll(), MonacoAllLocationLbl, 'MC', '', '');
        InsertExpenseLocation(ExpenseLocation, MongoliaAll(), MongoliaAllLocationLbl, 'MN', '', '');
        InsertExpenseLocation(ExpenseLocation, MontserratAll(), MontserratAllLocationLbl, 'MS', '', '');
        InsertExpenseLocation(ExpenseLocation, MyanmarAll(), MyanmarAllLocationLbl, 'MM', '', '');
        InsertExpenseLocation(ExpenseLocation, NamibiaAll(), NamibiaAllLocationLbl, 'NA', '', '');
        InsertExpenseLocation(ExpenseLocation, NauruAll(), NauruAllLocationLbl, 'NR', '', '');
        InsertExpenseLocation(ExpenseLocation, NepalAll(), NepalAllLocationLbl, 'NP', '', '');
        InsertExpenseLocation(ExpenseLocation, NewCaledoniaAll(), NewCaledoniaAllLocationLbl, 'NC', '', '');
        InsertExpenseLocation(ExpenseLocation, NigerAll(), NigerAllLocationLbl, 'NE', '', '');
        InsertExpenseLocation(ExpenseLocation, NiueAll(), NiueAllLocationLbl, 'NU', '', '');
        InsertExpenseLocation(ExpenseLocation, NorfolkIslandAll(), NorfolkIslandAllLocationLbl, 'NF', '', '');
        InsertExpenseLocation(ExpenseLocation, NorthMacedoniaAll(), NorthMacedoniaAllLocationLbl, 'MK', '', '');
        InsertExpenseLocation(ExpenseLocation, NorthernMarianaAll(), NorthernMarianaAllLocationLbl, 'MP', '', '');
        InsertExpenseLocation(ExpenseLocation, OmanAll(), OmanAllLocationLbl, 'OM', '', '');
        InsertExpenseLocation(ExpenseLocation, PakistanAll(), PakistanAllLocationLbl, 'PK', '', '');
        InsertExpenseLocation(ExpenseLocation, PalauAll(), PalauAllLocationLbl, 'PW', '', '');
        InsertExpenseLocation(ExpenseLocation, PalestineAll(), PalestineAllLocationLbl, 'PS', '', '');
        InsertExpenseLocation(ExpenseLocation, PanamaAll(), PanamaAllLocationLbl, 'PA', '', '');
        InsertExpenseLocation(ExpenseLocation, PapuaNewGuineaAll(), PapuaNewGuineaAllLocationLbl, 'PG', '', '');
        InsertExpenseLocation(ExpenseLocation, ParaguayAll(), ParaguayAllLocationLbl, 'PY', '', '');
        InsertExpenseLocation(ExpenseLocation, PeruAll(), PeruAllLocationLbl, 'PE', '', '');
        InsertExpenseLocation(ExpenseLocation, PitcairnAll(), PitcairnAllLocationLbl, 'PN', '', '');
        InsertExpenseLocation(ExpenseLocation, PuertoRicoAll(), PuertoRicoAllLocationLbl, 'PR', '', '');
        InsertExpenseLocation(ExpenseLocation, QatarAll(), QatarAllLocationLbl, 'QA', '', '');
        InsertExpenseLocation(ExpenseLocation, RwandaAll(), RwandaAllLocationLbl, 'RW', '', '');
        InsertExpenseLocation(ExpenseLocation, ReunionAll(), ReunionAllLocationLbl, 'RE', '', '');
        InsertExpenseLocation(ExpenseLocation, SaintBarthelemyAll(), SaintBarthelemyAllLocationLbl, 'BL', '', '');
        InsertExpenseLocation(ExpenseLocation, SaintHelenaAll(), SaintHelenaAllLocationLbl, 'SH', '', '');
        InsertExpenseLocation(ExpenseLocation, SaintKittsNevisAll(), SaintKittsNevisAllLocationLbl, 'KN', '', '');
        InsertExpenseLocation(ExpenseLocation, SaintLuciaAll(), SaintLuciaAllLocationLbl, 'LC', '', '');
        InsertExpenseLocation(ExpenseLocation, SaintMartinAll(), SaintMartinAllLocationLbl, 'MF', '', '');
        InsertExpenseLocation(ExpenseLocation, SaintPierreQuelonAll(), SaintPierreQuelonAllLocationLbl, 'PM', '', '');
        InsertExpenseLocation(ExpenseLocation, SaintVincentAll(), SaintVincentAllLocationLbl, 'VC', '', '');
        InsertExpenseLocation(ExpenseLocation, SanMarinoAll(), SanMarinoAllLocationLbl, 'SM', '', '');
        InsertExpenseLocation(ExpenseLocation, SaoTomeAll(), SaoTomeAllLocationLbl, 'ST', '', '');
        InsertExpenseLocation(ExpenseLocation, SenegalAll(), SenegalAllLocationLbl, 'SN', '', '');
        InsertExpenseLocation(ExpenseLocation, SeychellesAll(), SeychellesAllLocationLbl, 'SC', '', '');
        InsertExpenseLocation(ExpenseLocation, SierraLeoneAll(), SierraLeoneAllLocationLbl, 'SL', '', '');
        InsertExpenseLocation(ExpenseLocation, SintMaartenAll(), SintMaartenAllLocationLbl, 'SX', '', '');
        InsertExpenseLocation(ExpenseLocation, SomaliaAll(), SomaliaAllLocationLbl, 'SO', '', '');
        InsertExpenseLocation(ExpenseLocation, SouthGeorgiaAll(), SouthGeorgiaAllLocationLbl, 'GS', '', '');
        InsertExpenseLocation(ExpenseLocation, SouthSudanAll(), SouthSudanAllLocationLbl, 'SS', '', '');
        InsertExpenseLocation(ExpenseLocation, SriLankaAll(), SriLankaAllLocationLbl, 'LK', '', '');
        InsertExpenseLocation(ExpenseLocation, SudanAll(), SudanAllLocationLbl, 'SD', '', '');
        InsertExpenseLocation(ExpenseLocation, SurinameAll(), SurinameAllLocationLbl, 'SR', '', '');
        InsertExpenseLocation(ExpenseLocation, SvalbardJanMayenAll(), SvalbardJanMayenAllLocationLbl, 'SJ', '', '');
        InsertExpenseLocation(ExpenseLocation, SyriaAll(), SyriaAllLocationLbl, 'SY', '', '');
        InsertExpenseLocation(ExpenseLocation, TaiwanAll(), TaiwanAllLocationLbl, 'TW', '', '');
        InsertExpenseLocation(ExpenseLocation, TajikistanAll(), TajikistanAllLocationLbl, 'TJ', '', '');
        InsertExpenseLocation(ExpenseLocation, TimorLesteAll(), TimorLesteAllLocationLbl, 'TL', '', '');
        InsertExpenseLocation(ExpenseLocation, TogoAll(), TogoAllLocationLbl, 'TG', '', '');
        InsertExpenseLocation(ExpenseLocation, TokelauAll(), TokelauAllLocationLbl, 'TK', '', '');
        InsertExpenseLocation(ExpenseLocation, TongaAll(), TongaAllLocationLbl, 'TO', '', '');
        InsertExpenseLocation(ExpenseLocation, TrinidadTobagoAll(), TrinidadTobagoAllLocationLbl, 'TT', '', '');
        InsertExpenseLocation(ExpenseLocation, TurkmenistanAll(), TurkmenistanAllLocationLbl, 'TM', '', '');
        InsertExpenseLocation(ExpenseLocation, TurksCalcosAll(), TurksCalcosAllLocationLbl, 'TC', '', '');
        InsertExpenseLocation(ExpenseLocation, TuvaluAll(), TuvaluAllLocationLbl, 'TV', '', '');
        InsertExpenseLocation(ExpenseLocation, UkraineAll(), UkraineAllLocationLbl, 'UA', '', '');
        InsertExpenseLocation(ExpenseLocation, USMinorOutlyingAll(), USMinorOutlyingAllLocationLbl, 'UM', '', '');
        InsertExpenseLocation(ExpenseLocation, UruguayAll(), UruguayAllLocationLbl, 'UY', '', '');
        InsertExpenseLocation(ExpenseLocation, UzbekistanAll(), UzbekistanAllLocationLbl, 'UZ', '', '');
        InsertExpenseLocation(ExpenseLocation, VenezuelAll(), VenezuelAllLocationLbl, 'VE', '', '');
        InsertExpenseLocation(ExpenseLocation, VietnamAll(), VietnamAllLocationLbl, 'VN', '', '');
        InsertExpenseLocation(ExpenseLocation, VirginIslandsBrAll(), VirginIslandsBrAllLocationLbl, 'VG', '', '');
        InsertExpenseLocation(ExpenseLocation, VirginIslandsUSAll(), VirginIslandsUSAllLocationLbl, 'VI', '', '');
        InsertExpenseLocation(ExpenseLocation, WallisatunaAll(), WallisatunaAllLocationLbl, 'WF', '', '');
        InsertExpenseLocation(ExpenseLocation, WesternSaharaAll(), WesternSaharaAllLocationLbl, 'EH', '', '');
        InsertExpenseLocation(ExpenseLocation, YemenAll(), YemenAllLocationLbl, 'YE', '', '');
        InsertExpenseLocation(ExpenseLocation, ZambiaAll(), ZambiaAllLocationLbl, 'ZM', '', '');
        InsertExpenseLocation(ExpenseLocation, ZimbabweAll(), ZimbabweAllLocationLbl, 'ZW', '', '');
        InsertExpenseLocation(ExpenseLocation, AlandIslandsAll(), AlandIslandsAllLocationLbl, 'AX', '', '');
    end;

    var
        UnitedArabEmiratesAllTok: Label 'UNITEDARABEMIR-ALL', MaxLength = 20, Locked = true;
        UnitedArabEmiratesAllLocationLbl: Label 'United Arab Emirates - all location', MaxLength = 100;
        CanadaAllTok: Label 'CANADA-ALL', MaxLength = 20, Locked = true;
        DenmarkAllTok: Label 'DENMARK-ALL', MaxLength = 20, Locked = true;
        DenmarkCphTok: Label 'DK-COPENHAGEN', MaxLength = 20, Locked = true;
        DenmarkLbl: Label 'Denmark', MaxLength = 100;
        DKCopenhagenLbl: Label 'Denmark - Copenhagen', MaxLength = 100;
        CopenhagenLbl: Label 'Copenhagen', MaxLength = 30;
        DomesticTok: Label 'DOMESTIC', MaxLength = 20, Locked = true;
        FranceAllTok: Label 'FRANCE-ALL', MaxLength = 20, Locked = true;
        FranceParisTok: Label 'FRANCE-PARIS', MaxLength = 20, Locked = true;
        GermanyAllTok: Label 'GERMANY-ALL', MaxLength = 20, Locked = true;
        UKLondonTok: Label 'UK-LONDON', MaxLength = 20, Locked = true;
        UKOtherTok: Label 'UK-OTHER', MaxLength = 20, Locked = true;
        UKOtherLbl: Label 'United Kingdom - other', MaxLength = 100;
        USAFloridaTok: Label 'USA-FLORIDA', MaxLength = 20, Locked = true;
        USANYTok: Label 'USA-NY', MaxLength = 20, Locked = true;
        USAOtherTok: Label 'USA-OTHER', MaxLength = 20, Locked = true;
        CanadaAllLocationLbl: Label 'Canada - all location', MaxLength = 100;
        DomesticLbl: Label 'Domestic', MaxLength = 100;
        FranceLbl: Label 'France', MaxLength = 100;
        FranceParisLbl: Label 'France - Paris', MaxLength = 100;
        ParisLbl: Label 'Paris', MaxLength = 30;
        GermanyLbl: Label 'Germany', MaxLength = 100;
        UKLondonAreaLbl: Label 'United Kingdom - London area', MaxLength = 100;
        LondonLbl: Label 'London', MaxLength = 30;
        USAFloridaLbl: Label 'United States - Florida', MaxLength = 100;
        USANYLbl: Label 'United States - New York', MaxLength = 100;
        USAOtherLbl: Label 'United States - Other', MaxLength = 100;
        NewYorkLbl: Label 'New York', MaxLength = 30;
        FLLbl: Label 'FL', MaxLength = 30;
        AustriaAllTok: Label 'AUSTRIA-ALL', MaxLength = 20, Locked = true;
        AustriaAllLocationLbl: Label 'Austria - all location', MaxLength = 100;
        AustraliaAllTok: Label 'AUSTRALIA-ALL', MaxLength = 20, Locked = true;
        AustraliaAllLocationLbl: Label 'Australia - all location', MaxLength = 100;
        BelgiumAllTok: Label 'BELGIUM-ALL', MaxLength = 20, Locked = true;
        BelgiumAllLocationLbl: Label 'Belgium - all location', MaxLength = 100;
        BulgariaAllTok: Label 'BULGARIA-ALL', MaxLength = 20, Locked = true;
        BulgariaAllLocationLbl: Label 'Bulgaria - all location', MaxLength = 100;
        BruneiDarussalamAllTok: Label 'BRUNEIDARUSSALAM-ALL', MaxLength = 20, Locked = true;
        BruneiDarussalamAllLocationLbl: Label 'Brunei Darussalam - all location', MaxLength = 100;
        BrazilAllTok: Label 'BRAZIL-ALL', MaxLength = 20, Locked = true;
        BrazilAllLocationLbl: Label 'Brazil - all location', MaxLength = 100;
        SwitzerlandAllTok: Label 'SWITZERLAND-ALL', MaxLength = 20, Locked = true;
        SwitzerlandAllLocationLbl: Label 'Switzerland - all location', MaxLength = 100;
        SwitzerlandGenevaTok: Label 'SWITZERLAND-GENEVA', MaxLength = 20, Locked = true;
        SwitzerlandGenevaLbl: Label 'Switzerland - Geneva', MaxLength = 100;
        GenevaLbl: Label 'Geneva', MaxLength = 30;
        SwitzerlandZurichTok: Label 'SWITZERLAND-ZURICH', MaxLength = 20, Locked = true;
        SwitzerlandZurichLbl: Label 'Switzerland - Zurich', MaxLength = 100;
        ZurichLbl: Label 'Zurich', MaxLength = 30;
        ChinaAllTok: Label 'CHINA-ALL', MaxLength = 20, Locked = true;
        ChinaAllLocationLbl: Label 'China - all location', MaxLength = 100;
        CostaRicaAllTok: Label 'COSTARICA-ALL', MaxLength = 20, Locked = true;
        CostaRicaAllLocationLbl: Label 'Costa Rica - all location', MaxLength = 100;
        CyprusAllTok: Label 'CYPRUS-ALL', MaxLength = 20, Locked = true;
        CyprusAllLocationLbl: Label 'Cyprus - all location', MaxLength = 100;
        CzechiaAllTok: Label 'CZECHIA-ALL', MaxLength = 20, Locked = true;
        CzechiaAllLocationLbl: Label 'Czechia - all location', MaxLength = 100;
        AlgeriaAllTok: Label 'ALGERIA-ALL', MaxLength = 20, Locked = true;
        AlgeriaAllLocationLbl: Label 'Algeria - all location', MaxLength = 100;
        EstoniaAllTok: Label 'ESTONIA-ALL', MaxLength = 20, Locked = true;
        EstoniaAllLocationLbl: Label 'Estonia - all location', MaxLength = 100;
        GreeceAllTok: Label 'GREECE-ALL', MaxLength = 20, Locked = true;
        GreeceAllLocationLbl: Label 'Greece - all location', MaxLength = 100;
        SpainAllTok: Label 'SPAIN-ALL', MaxLength = 20, Locked = true;
        SpainAllLocationLbl: Label 'Spain - all location', MaxLength = 100;
        FinlandAllTok: Label 'FINLAND-ALL', MaxLength = 20, Locked = true;
        FinlandAllLocationLbl: Label 'Finland - all location', MaxLength = 100;
        FijiIslandsAllTok: Label 'FIJIISLANDS-ALL', MaxLength = 20, Locked = true;
        FijiIslandsAllLocationLbl: Label 'Fiji Islands - all location', MaxLength = 100;
        CroatiaAllTok: Label 'CROATIA-ALL', MaxLength = 20, Locked = true;
        CroatiaAllLocationLbl: Label 'Croatia - all location', MaxLength = 100;
        HungaryAllTok: Label 'HUNGARY-ALL', MaxLength = 20, Locked = true;
        HungaryAllLocationLbl: Label 'Hungary - all location', MaxLength = 100;
        IndonesiaAllTok: Label 'INDONESIA-ALL', MaxLength = 20, Locked = true;
        IndonesiaAllLocationLbl: Label 'Indonesia - all location', MaxLength = 100;
        IrelandAllTok: Label 'IRELAND-ALL', MaxLength = 20, Locked = true;
        IrelandAllLocationLbl: Label 'Ireland - all location', MaxLength = 100;
        IndiaAllTok: Label 'INDIA-ALL', MaxLength = 20, Locked = true;
        IndiaAllLocationLbl: Label 'India - all location', MaxLength = 100;
        IcelandAllTok: Label 'ICELAND-ALL', MaxLength = 20, Locked = true;
        IcelandAllLocationLbl: Label 'Iceland - all location', MaxLength = 100;
        ItalyAllTok: Label 'ITALY-ALL', MaxLength = 20, Locked = true;
        ItalyAllLocationLbl: Label 'Italy - all location', MaxLength = 100;
        JapanAllTok: Label 'JAPAN-ALL', MaxLength = 20, Locked = true;
        JapanAllLocationLbl: Label 'Japan - all location', MaxLength = 100;
        JapanTokyoTok: Label 'JAPAN-TOKYO', MaxLength = 20, Locked = true;
        JapanTokyoLbl: Label 'Japan - Tokyo', MaxLength = 100;
        TokyoLbl: Label 'Tokyo', MaxLength = 30;
        KenyaAllTok: Label 'KENYA-ALL', MaxLength = 20, Locked = true;
        KenyaAllLocationLbl: Label 'Kenya - all location', MaxLength = 100;
        LithuaniaAllTok: Label 'LITHUANIA-ALL', MaxLength = 20, Locked = true;
        LithuaniaAllLocationLbl: Label 'Lithuania - all location', MaxLength = 100;
        LuxembourgAllTok: Label 'LUXEMBOURG-ALL', MaxLength = 20, Locked = true;
        LuxembourgAllLocationLbl: Label 'Luxembourg - all location', MaxLength = 100;
        LatviaAllTok: Label 'LATVIA-ALL', MaxLength = 20, Locked = true;
        LatviaAllLocationLbl: Label 'Latvia - all location', MaxLength = 100;
        MoroccoAllTok: Label 'MOROCCO-ALL', MaxLength = 20, Locked = true;
        MoroccoAllLocationLbl: Label 'Morocco - all location', MaxLength = 100;
        MontenegroAllTok: Label 'MONTENEGRO-ALL', MaxLength = 20, Locked = true;
        MontenegroAllLocationLbl: Label 'Montenegro - all location', MaxLength = 100;
        MaltaAllTok: Label 'MALTA-ALL', MaxLength = 20, Locked = true;
        MaltaAllLocationLbl: Label 'Malta - all location', MaxLength = 100;
        MexicoAllTok: Label 'MEXICO-ALL', MaxLength = 20, Locked = true;
        MexicoAllLocationLbl: Label 'Mexico - all location', MaxLength = 100;
        MalaysiaAllTok: Label 'MALAYSIA-ALL', MaxLength = 20, Locked = true;
        MalaysiaAllLocationLbl: Label 'Malaysia - all location', MaxLength = 100;
        MozambiqueAllTok: Label 'MOZAMBIQUE-ALL', MaxLength = 20, Locked = true;
        MozambiqueAllLocationLbl: Label 'Mozambique - all location', MaxLength = 100;
        NigeriaAllTok: Label 'NIGERIA-ALL', MaxLength = 20, Locked = true;
        NigeriaAllLocationLbl: Label 'Nigeria - all location', MaxLength = 100;
        NorthernIrelandAllTok: Label 'NORTHERNIRELAND-ALL', MaxLength = 20, Locked = true;
        NorthernIrelandAllLocationLbl: Label 'Northern Ireland - all location', MaxLength = 100;
        NetherlandsAllTok: Label 'NETHERLANDS-ALL', MaxLength = 20, Locked = true;
        NetherlandsAllLocationLbl: Label 'Netherlands - all location', MaxLength = 100;
        NorwayAllTok: Label 'NORWAY-ALL', MaxLength = 20, Locked = true;
        NorwayAllLocationLbl: Label 'Norway - all location', MaxLength = 100;
        NorwayOsloTok: Label 'NORWAY-OSLO', MaxLength = 20, Locked = true;
        NorwayOsloLbl: Label 'Norway - Oslo', MaxLength = 100;
        OsloLbl: Label 'Norway - Oslo', MaxLength = 30;
        NewZealandAllTok: Label 'NEWZEALAND-ALL', MaxLength = 20, Locked = true;
        NewZealandAllLocationLbl: Label 'New Zealand - all location', MaxLength = 100;
        PhilippinesAllTok: Label 'PHILIPPINES-ALL', MaxLength = 20, Locked = true;
        PhilippinesAllLocationLbl: Label 'Philippines - all location', MaxLength = 100;
        PolandAllTok: Label 'POLAND-ALL', MaxLength = 20, Locked = true;
        PolandAllLocationLbl: Label 'Poland - all location', MaxLength = 100;
        PortugalAllTok: Label 'PORTUGAL-ALL', MaxLength = 20, Locked = true;
        PortugalAllLocationLbl: Label 'Portugal - all location', MaxLength = 100;
        RomaniaAllTok: Label 'ROMANIA-ALL', MaxLength = 20, Locked = true;
        RomaniaAllLocationLbl: Label 'Romania - all location', MaxLength = 100;
        SerbiaAllTok: Label 'SERBIA-ALL', MaxLength = 20, Locked = true;
        SerbiaAllLocationLbl: Label 'Serbia - all location', MaxLength = 100;
        RussiaAllTok: Label 'RUSSIA-ALL', MaxLength = 20, Locked = true;
        RussiaAllLocationLbl: Label 'Russia - all location', MaxLength = 100;
        SaudiArabiaAllTok: Label 'SAUDIARABIA-ALL', MaxLength = 20, Locked = true;
        SaudiArabiaAllLocationLbl: Label 'Saudi Arabia - all location', MaxLength = 100;
        SolomonIslandsAllTok: Label 'SOLOMONISLANDS-ALL', MaxLength = 20, Locked = true;
        SolomonIslandsAllLocationLbl: Label 'Solomon Islands - all location', MaxLength = 100;
        SwedenAllTok: Label 'SWEDEN-ALL', MaxLength = 20, Locked = true;
        SwedenAllLocationLbl: Label 'Sweden - all location', MaxLength = 100;
        SingaporeAllTok: Label 'SINGAPORE-ALL', MaxLength = 20, Locked = true;
        SingaporeAllLocationLbl: Label 'Singapore - all location', MaxLength = 100;
        SloveniaAllTok: Label 'SLOVENIA-ALL', MaxLength = 20, Locked = true;
        SloveniaAllLocationLbl: Label 'Slovenia - all location', MaxLength = 100;
        SlovakiaAllTok: Label 'SLOVAKIA-ALL', MaxLength = 20, Locked = true;
        SlovakiaAllLocationLbl: Label 'Slovakia - all location', MaxLength = 100;
        SwazilandAllTok: Label 'SWAZILAND-ALL', MaxLength = 20, Locked = true;
        SwazilandAllLocationLbl: Label 'Swaziland - all location', MaxLength = 100;
        ThailandAllTok: Label 'THAILAND-ALL', MaxLength = 20, Locked = true;
        ThailandAllLocationLbl: Label 'Thailand - all location', MaxLength = 100;
        TunisiaAllTok: Label 'TUNISIA-ALL', MaxLength = 20, Locked = true;
        TunisiaAllLocationLbl: Label 'Tunisia - all location', MaxLength = 100;
        TurkiyeAllTok: Label 'TURKIYE-ALL', MaxLength = 20, Locked = true;
        TurkiyeAllLocationLbl: Label 'Türkiye - all location', MaxLength = 100;
        TanzaniaAllTok: Label 'TANZANIA-ALL', MaxLength = 20, Locked = true;
        TanzaniaAllLocationLbl: Label 'Tanzania - all location', MaxLength = 100;
        UgandaAllTok: Label 'UGANDA-ALL', MaxLength = 20, Locked = true;
        UgandaAllLocationLbl: Label 'Uganda - all location', MaxLength = 100;
        VanuatuAllTok: Label 'VANUATU-ALL', MaxLength = 20, Locked = true;
        VanuatuAllLocationLbl: Label 'Vanuatu - all location', MaxLength = 100;
        SamoaAllTok: Label 'SAMOA-ALL', MaxLength = 20, Locked = true;
        SamoaAllLocationLbl: Label 'Samoa - all location', MaxLength = 100;
        SouthAfricaAllTok: Label 'SOUTHAFRICA-ALL', MaxLength = 20, Locked = true;
        SouthAfricaAllLocationLbl: Label 'South Africa - all location', MaxLength = 100;
        AfghanistanAllTok: Label 'AFGHANISTAN-ALL', MaxLength = 20, Locked = true;
        AfghanistanAllLocationLbl: Label 'Afghanistan - all location', MaxLength = 100;
        AlbaniaAllTok: Label 'ALBANIA-ALL', MaxLength = 20, Locked = true;
        AlbaniaAllLocationLbl: Label 'Albania - all location', MaxLength = 100;
        AndorraAllTok: Label 'ANDORRA-ALL', MaxLength = 20, Locked = true;
        AndorraAllLocationLbl: Label 'Andorra - all location', MaxLength = 100;
        AngolaAllTok: Label 'ANGOLA-ALL', MaxLength = 20, Locked = true;
        AngolaAllLocationLbl: Label 'Angola - all location', MaxLength = 100;
        AnguillaAllTok: Label 'ANGUILLA-ALL', MaxLength = 20, Locked = true;
        AnguillaAllLocationLbl: Label 'Anguilla - all location', MaxLength = 100;
        AntarcticaAllTok: Label 'ANTARCTICA-ALL', MaxLength = 20, Locked = true;
        AntarcticaAllLocationLbl: Label 'Antarctica - all location', MaxLength = 100;
        AntiguaBarbudaAllTok: Label 'ANTIGUABARBUDA-ALL', MaxLength = 20, Locked = true;
        AntiguaBarbudaAllLocationLbl: Label 'Antigua & Barbuda - all location', MaxLength = 100;
        ArgentinaAllTok: Label 'ARGENTINA-ALL', MaxLength = 20, Locked = true;
        ArgentinaAllLocationLbl: Label 'Argentina - all location', MaxLength = 100;
        ArmeniaAllTok: Label 'ARMENIA-ALL', MaxLength = 20, Locked = true;
        ArmeniaAllLocationLbl: Label 'Armenia - all location', MaxLength = 100;
        ArubaAllTok: Label 'ARUBA-ALL', MaxLength = 20, Locked = true;
        ArubaAllLocationLbl: Label 'Aruba - all location', MaxLength = 100;
        AzerbaijanAllTok: Label 'AZERBAIJAN-ALL', MaxLength = 20, Locked = true;
        AzerbaijanAllLocationLbl: Label 'Azerbaijan - all location', MaxLength = 100;
        BahamasAllTok: Label 'BAHAMAS-ALL', MaxLength = 20, Locked = true;
        BahamasAllLocationLbl: Label 'Bahamas - all location', MaxLength = 100;
        BahrainAllTok: Label 'BAHRAIN-ALL', MaxLength = 20, Locked = true;
        BahrainAllLocationLbl: Label 'Bahrain - all location', MaxLength = 100;
        BangladeshAllTok: Label 'BANGLADESH-ALL', MaxLength = 20, Locked = true;
        BangladeshAllLocationLbl: Label 'Bangladesh - all location', MaxLength = 100;
        BarbadosAllTok: Label 'BARBADOS-ALL', MaxLength = 20, Locked = true;
        BarbadosAllLocationLbl: Label 'Barbados - all location', MaxLength = 100;
        BelarusAllTok: Label 'BELARUS-ALL', MaxLength = 20, Locked = true;
        BelarusAllLocationLbl: Label 'Belarus - all location', MaxLength = 100;
        BelizeAllTok: Label 'BELIZE-ALL', MaxLength = 20, Locked = true;
        BelizeAllLocationLbl: Label 'Belize - all location', MaxLength = 100;
        BeninAllTok: Label 'BENIN-ALL', MaxLength = 20, Locked = true;
        BeninAllLocationLbl: Label 'Benin - all location', MaxLength = 100;
        BermudaAllTok: Label 'BERMUDA-ALL', MaxLength = 20, Locked = true;
        BermudaAllLocationLbl: Label 'Bermuda - all location', MaxLength = 100;
        BhutanAllTok: Label 'BHUTAN-ALL', MaxLength = 20, Locked = true;
        BhutanAllLocationLbl: Label 'Bhutan - all location', MaxLength = 100;
        BoliviaAllTok: Label 'BOLIVIA-ALL', MaxLength = 20, Locked = true;
        BoliviaAllLocationLbl: Label 'Bolivia - all location', MaxLength = 100;
        BonaireAllTok: Label 'BONAIRE-ALL', MaxLength = 20, Locked = true;
        BonaireAllLocationLbl: Label 'Bonaire, Sint Eustatius and Saba - all location', MaxLength = 100;
        BosniaHerzegovinaAllTok: Label 'BOSNIAHERZEGOVIN-ALL', MaxLength = 20, Locked = true;
        BosniaHerzegovinaAllLocationLbl: Label 'Bosnia & Herzegovina - all location', MaxLength = 100;
        BotswanaAllTok: Label 'BOTSWANA-ALL', MaxLength = 20, Locked = true;
        BotswanaAllLocationLbl: Label 'Botswana - all location', MaxLength = 100;
        BouvetIslandAllTok: Label 'BOUVETISLAND-ALL', MaxLength = 20, Locked = true;
        BouvetIslandAllLocationLbl: Label 'Bouvet Island - all location', MaxLength = 100;
        BritishIndianOceanAllTok: Label 'BRITISHINDIANOCE-ALL', MaxLength = 20, Locked = true;
        BritishIndianOceanAllLocationLbl: Label 'British Indian Ocean Territory - all location', MaxLength = 100;
        BurkinaFasoAllTok: Label 'BURKINAFASO-ALL', MaxLength = 20, Locked = true;
        BurkinaFasoAllLocationLbl: Label 'Burkina Faso - all location', MaxLength = 100;
        BurundiAllTok: Label 'BURUNDI-ALL', MaxLength = 20, Locked = true;
        BurundiAllLocationLbl: Label 'Burundi - all location', MaxLength = 100;
        CaboVerdeAllTok: Label 'CABOVERDE-ALL', MaxLength = 20, Locked = true;
        CaboVerdeAllLocationLbl: Label 'Cabo Verde - all location', MaxLength = 100;
        CambodiaAllTok: Label 'CAMBODIA-ALL', MaxLength = 20, Locked = true;
        CambodiaAllLocationLbl: Label 'Cambodia - all location', MaxLength = 100;
        CameroonAllTok: Label 'CAMEROON-ALL', MaxLength = 20, Locked = true;
        CameroonAllLocationLbl: Label 'Cameroon - all location', MaxLength = 100;
        CaymanIslandsAllTok: Label 'CAYMANISLANDS-ALL', MaxLength = 20, Locked = true;
        CaymanIslandsAllLocationLbl: Label 'Cayman Islands - all location', MaxLength = 100;
        CentralAfricanAllTok: Label 'CENTRALAFRICAN-ALL', MaxLength = 20, Locked = true;
        CentralAfricanAllLocationLbl: Label 'Central African Republic - all location', MaxLength = 100;
        ChadAllTok: Label 'CHAD-ALL', MaxLength = 20, Locked = true;
        ChadAllLocationLbl: Label 'Chad - all location', MaxLength = 100;
        ChileAllTok: Label 'CHILE-ALL', MaxLength = 20, Locked = true;
        ChileAllLocationLbl: Label 'Chile - all location', MaxLength = 100;
        ChristmasIslandAllTok: Label 'CHRISTMASISLAND-ALL', MaxLength = 20, Locked = true;
        ChristmasIslandAllLocationLbl: Label 'Christmas Island - all location', MaxLength = 100;
        CocosIslandsAllTok: Label 'COCOSISLANDS-ALL', MaxLength = 20, Locked = true;
        CocosIslandsAllLocationLbl: Label 'Cocos (Keeling) Islands - all location', MaxLength = 100;
        ColombiaAllTok: Label 'COLOMBIA-ALL', MaxLength = 20, Locked = true;
        ColombiaAllLocationLbl: Label 'Colombia - all location', MaxLength = 100;
        ComorosAllTok: Label 'COMOROS-ALL', MaxLength = 20, Locked = true;
        ComorosAllLocationLbl: Label 'Comoros - all location', MaxLength = 100;
        CongoDRAllTok: Label 'CONGODR-ALL', MaxLength = 20, Locked = true;
        CongoDRAllLocationLbl: Label 'Congo, Democratic Republic - all location', MaxLength = 100;
        CongoAllTok: Label 'CONGO-ALL', MaxLength = 20, Locked = true;
        CongoAllLocationLbl: Label 'Congo - all location', MaxLength = 100;
        CookIslandsAllTok: Label 'COOKISLANDS-ALL', MaxLength = 20, Locked = true;
        CookIslandsAllLocationLbl: Label 'Cook Islands - all location', MaxLength = 100;
        CubaAllTok: Label 'CUBA-ALL', MaxLength = 20, Locked = true;
        CubaAllLocationLbl: Label 'Cuba - all location', MaxLength = 100;
        CuracaoAllTok: Label 'CURACAO-ALL', MaxLength = 20, Locked = true;
        CuracaoAllLocationLbl: Label 'Curacao - all location', MaxLength = 100;
        CotedIvoireAllTok: Label 'COTEDIVOIRE-ALL', MaxLength = 20, Locked = true;
        CotedIvoireAllLocationLbl: Label 'Cote d''Ivoire - all location', MaxLength = 100;
        DjiboutiAllTok: Label 'DJIBOUTI-ALL', MaxLength = 20, Locked = true;
        DjiboutiAllLocationLbl: Label 'Djibouti - all location', MaxLength = 100;
        DominicaAllTok: Label 'DOMINICA-ALL', MaxLength = 20, Locked = true;
        DominicaAllLocationLbl: Label 'Dominica - all location', MaxLength = 100;
        DominicanAllTok: Label 'DOMINICAN-ALL', MaxLength = 20, Locked = true;
        DominicanAllLocationLbl: Label 'Dominican Republic - all location', MaxLength = 100;
        EcuadorAllTok: Label 'ECUADOR-ALL', MaxLength = 20, Locked = true;
        EcuadorAllLocationLbl: Label 'Ecuador - all location', MaxLength = 100;
        EgyptAllTok: Label 'EGYPT-ALL', MaxLength = 20, Locked = true;
        EgyptAllLocationLbl: Label 'Egypt - all location', MaxLength = 100;
        ElSalvadorAllTok: Label 'ELSALVADOR-ALL', MaxLength = 20, Locked = true;
        ElSalvadorAllLocationLbl: Label 'El Salvador - all location', MaxLength = 100;
        EquatorialGuineaAllTok: Label 'EQUATORIALGUINEA-ALL', MaxLength = 20, Locked = true;
        EquatorialGuineaAllLocationLbl: Label 'Equatorial Guinea - all location', MaxLength = 100;
        EritreaAllTok: Label 'ERITREA-ALL', MaxLength = 20, Locked = true;
        EritreaAllLocationLbl: Label 'Eritrea - all location', MaxLength = 100;
        EthiopiaAllTok: Label 'ETHIOPIA-ALL', MaxLength = 20, Locked = true;
        EthiopiaAllLocationLbl: Label 'Ethiopia - all location', MaxLength = 100;
        FalklandIslandsAllTok: Label 'FALKLANDISLANDS-ALL', MaxLength = 20, Locked = true;
        FalklandIslandsAllLocationLbl: Label 'Falkland Islands - all location', MaxLength = 100;
        FaroeIslandsAllTok: Label 'FAROEISLANDS-ALL', MaxLength = 20, Locked = true;
        FaroeIslandsAllLocationLbl: Label 'Faroe Islands - all location', MaxLength = 100;
        FrenchGuianaAllTok: Label 'FRENCHGUIANA-ALL', MaxLength = 20, Locked = true;
        FrenchGuianaAllLocationLbl: Label 'French Guiana - all location', MaxLength = 100;
        FrenchPolynesiaAllTok: Label 'FRENCHPOLYNESIA-ALL', MaxLength = 20, Locked = true;
        FrenchPolynesiaAllLocationLbl: Label 'French Polynesia - all location', MaxLength = 100;
        FrenchSouthernAllTok: Label 'FRENCHSOUTHERN-ALL', MaxLength = 20, Locked = true;
        FrenchSouthernAllLocationLbl: Label 'French Southern Territories - all location', MaxLength = 100;
        GabonAllTok: Label 'GABON-ALL', MaxLength = 20, Locked = true;
        GabonAllLocationLbl: Label 'Gabon - all location', MaxLength = 100;
        GambiaAllTok: Label 'GAMBIA-ALL', MaxLength = 20, Locked = true;
        GambiaAllLocationLbl: Label 'Gambia - all location', MaxLength = 100;
        GeorgiaAllTok: Label 'GEORGIA-ALL', MaxLength = 20, Locked = true;
        GeorgiaAllLocationLbl: Label 'Georgia - all location', MaxLength = 100;
        GhanaAllTok: Label 'GHANA-ALL', MaxLength = 20, Locked = true;
        GhanaAllLocationLbl: Label 'Ghana - all location', MaxLength = 100;
        GibraltarAllTok: Label 'GIBRALTAR-ALL', MaxLength = 20, Locked = true;
        GibraltarAllLocationLbl: Label 'Gibraltar - all location', MaxLength = 100;
        GreenlandAllTok: Label 'GREENLAND-ALL', MaxLength = 20, Locked = true;
        GreenlandAllLocationLbl: Label 'Greenland - all location', MaxLength = 100;
        GrenadaAllTok: Label 'GRENADA-ALL', MaxLength = 20, Locked = true;
        GrenadaAllLocationLbl: Label 'Grenada - all location', MaxLength = 100;
        GuadeloupeAllTok: Label 'GUADELOUPE-ALL', MaxLength = 20, Locked = true;
        GuadeloupeAllLocationLbl: Label 'Guadeloupe - all location', MaxLength = 100;
        GuamAllTok: Label 'GUAM-ALL', MaxLength = 20, Locked = true;
        GuamAllLocationLbl: Label 'Guam - all location', MaxLength = 100;
        GuatemalaAllTok: Label 'GUATEMALA-ALL', MaxLength = 20, Locked = true;
        GuatemalaAllLocationLbl: Label 'Guatemala - all location', MaxLength = 100;
        GuernseyAllTok: Label 'GUERNSEY-ALL', MaxLength = 20, Locked = true;
        GuernseyAllLocationLbl: Label 'Guernsey - all location', MaxLength = 100;
        GuineaAllTok: Label 'GUINEA-ALL', MaxLength = 20, Locked = true;
        GuineaAllLocationLbl: Label 'Guinea - all location', MaxLength = 100;
        GuineaBissauAllTok: Label 'GUINEABISSAU-ALL', MaxLength = 20, Locked = true;
        GuineaBissauAllLocationLbl: Label 'Guinea-Bissau - all location', MaxLength = 100;
        GuyanaAllTok: Label 'GUYANA-ALL', MaxLength = 20, Locked = true;
        GuyanaAllLocationLbl: Label 'Guyana - all location', MaxLength = 100;
        HaitiAllTok: Label 'HAITI-ALL', MaxLength = 20, Locked = true;
        HaitiAllLocationLbl: Label 'Haiti - all location', MaxLength = 100;
        HeardIslandAllTok: Label 'HEARDISLAND-ALL', MaxLength = 20, Locked = true;
        HeardIslandAllLocationLbl: Label 'Heard Island and McDonald Islands - all location', MaxLength = 100;
        HolySeeAllTok: Label 'HOLYSEE-ALL', MaxLength = 20, Locked = true;
        HolySeeAllLocationLbl: Label 'Vatican City - all location', MaxLength = 100;
        HondurasAllTok: Label 'HONDURAS-ALL', MaxLength = 20, Locked = true;
        HondurasAllLocationLbl: Label 'Honduras - all location', MaxLength = 100;
        HongKongAllTok: Label 'HONGKONG-ALL', MaxLength = 20, Locked = true;
        HongKongAllLocationLbl: Label 'Hong Kong SAR - all location', MaxLength = 100;
        IsleManAllTok: Label 'ISLEMAN-ALL', MaxLength = 20, Locked = true;
        IsleManAllLocationLbl: Label 'Isle of Man - all location', MaxLength = 100;
        IsraelAllTok: Label 'ISRAEL-ALL', MaxLength = 20, Locked = true;
        IsraelAllLocationLbl: Label 'Israel - all location', MaxLength = 100;
        JamaicaAllTok: Label 'JAMAICA-ALL', MaxLength = 20, Locked = true;
        JamaicaAllLocationLbl: Label 'Jamaica - all location', MaxLength = 100;
        JerseyAllTok: Label 'JERSEY-ALL', MaxLength = 20, Locked = true;
        JerseyAllLocationLbl: Label 'Jersey - all location', MaxLength = 100;
        JordanAllTok: Label 'JORDAN-ALL', MaxLength = 20, Locked = true;
        JordanAllLocationLbl: Label 'Jordan - all location', MaxLength = 100;
        KazakhstanAllTok: Label 'KAZAKHSTAN-ALL', MaxLength = 20, Locked = true;
        KazakhstanAllLocationLbl: Label 'Kazakhstan - all location', MaxLength = 100;
        KiribatiAllTok: Label 'KIRIBATI-ALL', MaxLength = 20, Locked = true;
        KiribatiAllLocationLbl: Label 'Kiribati - all location', MaxLength = 100;
        NorthKoreaAllTok: Label 'NORTHKOREA-ALL', MaxLength = 20, Locked = true;
        NorthKoreaAllLocationLbl: Label 'North Korea - all location', MaxLength = 100;
        SouthKoreaAllTok: Label 'SOUTHKOREA-ALL', MaxLength = 20, Locked = true;
        SouthKoreaAllLocationLbl: Label 'Korea - all location', MaxLength = 100;
        KuwaitAllTok: Label 'KUWAIT-ALL', MaxLength = 20, Locked = true;
        KuwaitAllLocationLbl: Label 'Kuwait - all location', MaxLength = 100;
        KyrgyzstanAllTok: Label 'KYRGYZSTAN-ALL', MaxLength = 20, Locked = true;
        KyrgyzstanAllLocationLbl: Label 'Kyrgyzstan - all location', MaxLength = 100;
        LaosAllTok: Label 'LAOS-ALL', MaxLength = 20, Locked = true;
        LaosAllLocationLbl: Label 'Laos - all location', MaxLength = 100;
        LebanonAllTok: Label 'LEBANON-ALL', MaxLength = 20, Locked = true;
        LebanonAllLocationLbl: Label 'Lebanon - all location', MaxLength = 100;
        LesothoAllTok: Label 'LESOTHO-ALL', MaxLength = 20, Locked = true;
        LesothoAllLocationLbl: Label 'Lesotho - all location', MaxLength = 100;
        LiberiaAllTok: Label 'LIBERIA-ALL', MaxLength = 20, Locked = true;
        LiberiaAllLocationLbl: Label 'Liberia - all location', MaxLength = 100;
        LibyaAllTok: Label 'LIBYA-ALL', MaxLength = 20, Locked = true;
        LibyaAllLocationLbl: Label 'Libya - all location', MaxLength = 100;
        LiechtensteinAllTok: Label 'LIECHTENSTEIN-ALL', MaxLength = 20, Locked = true;
        LiechtensteinAllLocationLbl: Label 'Liechtenstein - all location', MaxLength = 100;
        MacaoAllTok: Label 'MACAO-ALL', MaxLength = 20, Locked = true;
        MacaoAllLocationLbl: Label 'Macao - all location', MaxLength = 100;
        MadagascarAllTok: Label 'MADAGASCAR-ALL', MaxLength = 20, Locked = true;
        MadagascarAllLocationLbl: Label 'Madagascar - all location', MaxLength = 100;
        MalawiAllTok: Label 'MALAWI-ALL', MaxLength = 20, Locked = true;
        MalawiAllLocationLbl: Label 'Malawi - all location', MaxLength = 100;
        MaldivesAllTok: Label 'MALDIVES-ALL', MaxLength = 20, Locked = true;
        MaldivesAllLocationLbl: Label 'Maldives - all location', MaxLength = 100;
        MaliAllTok: Label 'MALI-ALL', MaxLength = 20, Locked = true;
        MaliAllLocationLbl: Label 'Mali - all location', MaxLength = 100;
        MarshallIslandsAllTok: Label 'MARSHALLISLANDS-ALL', MaxLength = 20, Locked = true;
        MarshallIslandsAllLocationLbl: Label 'Marshall Islands - all location', MaxLength = 100;
        MartiniqueAllTok: Label 'MARTINIQUE-ALL', MaxLength = 20, Locked = true;
        MartiniqueAllLocationLbl: Label 'Martinique - all location', MaxLength = 100;
        MauritaniaAllTok: Label 'MAURITANIA-ALL', MaxLength = 20, Locked = true;
        MauritaniaAllLocationLbl: Label 'Mauritania - all location', MaxLength = 100;
        MauritiusAllTok: Label 'MAURITIUS-ALL', MaxLength = 20, Locked = true;
        MauritiusAllLocationLbl: Label 'Mauritius - all location', MaxLength = 100;
        MayotteAllTok: Label 'MAYOTTE-ALL', MaxLength = 20, Locked = true;
        MayotteAllLocationLbl: Label 'Mayotte - all location', MaxLength = 100;
        MicronesiaAllTok: Label 'MICRONESIA-ALL', MaxLength = 20, Locked = true;
        MicronesiaAllLocationLbl: Label 'Micronesia - all location', MaxLength = 100;
        MoldovaAllTok: Label 'MOLDOVA-ALL', MaxLength = 20, Locked = true;
        MoldovaAllLocationLbl: Label 'Moldova - all location', MaxLength = 100;
        MonacoAllTok: Label 'MONACO-ALL', MaxLength = 20, Locked = true;
        MonacoAllLocationLbl: Label 'Monaco - all location', MaxLength = 100;
        MongoliaAllTok: Label 'MONGOLIA-ALL', MaxLength = 20, Locked = true;
        MongoliaAllLocationLbl: Label 'Mongolia - all location', MaxLength = 100;
        MontserratAllTok: Label 'MONTSERRAT-ALL', MaxLength = 20, Locked = true;
        MontserratAllLocationLbl: Label 'Montserrat - all location', MaxLength = 100;
        MyanmarAllTok: Label 'MYANMAR-ALL', MaxLength = 20, Locked = true;
        MyanmarAllLocationLbl: Label 'Myanmar - all location', MaxLength = 100;
        NamibiaAllTok: Label 'NAMIBIA-ALL', MaxLength = 20, Locked = true;
        NamibiaAllLocationLbl: Label 'Namibia - all location', MaxLength = 100;
        NauruAllTok: Label 'NAURU-ALL', MaxLength = 20, Locked = true;
        NauruAllLocationLbl: Label 'Nauru - all location', MaxLength = 100;
        NepalAllTok: Label 'NEPAL-ALL', MaxLength = 20, Locked = true;
        NepalAllLocationLbl: Label 'Nepal - all location', MaxLength = 100;
        NewCaledoniaAllTok: Label 'NEWCALEDONIA-ALL', MaxLength = 20, Locked = true;
        NewCaledoniaAllLocationLbl: Label 'New Caledonia - all location', MaxLength = 100;
        NigerAllTok: Label 'NIGER-ALL', MaxLength = 20, Locked = true;
        NigerAllLocationLbl: Label 'Niger - all location', MaxLength = 100;
        NiueAllTok: Label 'NIUE-ALL', MaxLength = 20, Locked = true;
        NiueAllLocationLbl: Label 'Niue - all location', MaxLength = 100;
        NorfolkIslandAllTok: Label 'NORFOLKISLAND-ALL', MaxLength = 20, Locked = true;
        NorfolkIslandAllLocationLbl: Label 'Norfolk Island - all location', MaxLength = 100;
        NorthMacedoniaAllTok: Label 'NORTHMACEDONIA-ALL', MaxLength = 20, Locked = true;
        NorthMacedoniaAllLocationLbl: Label 'North Macedonia - all location', MaxLength = 100;
        NorthernMarianaAllTok: Label 'NORTHERNMARIANA-ALL', MaxLength = 20, Locked = true;
        NorthernMarianaAllLocationLbl: Label 'Northern Mariana Islands - all location', MaxLength = 100;
        OmanAllTok: Label 'OMAN-ALL', MaxLength = 20, Locked = true;
        OmanAllLocationLbl: Label 'Oman - all location', MaxLength = 100;
        PakistanAllTok: Label 'PAKISTAN-ALL', MaxLength = 20, Locked = true;
        PakistanAllLocationLbl: Label 'Pakistan - all location', MaxLength = 100;
        PalauAllTok: Label 'PALAU-ALL', MaxLength = 20, Locked = true;
        PalauAllLocationLbl: Label 'Palau - all location', MaxLength = 100;
        PalestineAllTok: Label 'PALESTINE-ALL', MaxLength = 20, Locked = true;
        PalestineAllLocationLbl: Label 'Palestine - all location', MaxLength = 100;
        PanamaAllTok: Label 'PANAMA-ALL', MaxLength = 20, Locked = true;
        PanamaAllLocationLbl: Label 'Panama - all location', MaxLength = 100;
        PapuaNewGuineaAllTok: Label 'PAPUANEWGUINEA-ALL', MaxLength = 20, Locked = true;
        PapuaNewGuineaAllLocationLbl: Label 'Papua New Guinea - all location', MaxLength = 100;
        ParaguayAllTok: Label 'PARAGUAY-ALL', MaxLength = 20, Locked = true;
        ParaguayAllLocationLbl: Label 'Paraguay - all location', MaxLength = 100;
        PeruAllTok: Label 'PERU-ALL', MaxLength = 20, Locked = true;
        PeruAllLocationLbl: Label 'Peru - all location', MaxLength = 100;
        PitcairnAllTok: Label 'PITCAIRN-ALL', MaxLength = 20, Locked = true;
        PitcairnAllLocationLbl: Label 'Pitcairn Islands - all location', MaxLength = 100;
        PuertoRicoAllTok: Label 'PUERTORICO-ALL', MaxLength = 20, Locked = true;
        PuertoRicoAllLocationLbl: Label 'Puerto Rico - all location', MaxLength = 100;
        QatarAllTok: Label 'QATAR-ALL', MaxLength = 20, Locked = true;
        QatarAllLocationLbl: Label 'Qatar - all location', MaxLength = 100;
        RwandaAllTok: Label 'RWANDA-ALL', MaxLength = 20, Locked = true;
        RwandaAllLocationLbl: Label 'Rwanda - all location', MaxLength = 100;
        ReunionAllTok: Label 'REUNION-ALL', MaxLength = 20, Locked = true;
        ReunionAllLocationLbl: Label 'Reunion - all location', MaxLength = 100;
        SaintBarthelemyAllTok: Label 'SAINTBARTHELEMY-ALL', MaxLength = 20, Locked = true;
        SaintBarthelemyAllLocationLbl: Label 'Saint Barthelemy - all location', MaxLength = 100;
        SaintHelenaAllTok: Label 'SAINTHELENA-ALL', MaxLength = 20, Locked = true;
        SaintHelenaAllLocationLbl: Label 'St Helena, Ascension, Tristan da Cunha - all location', MaxLength = 100;
        SaintKittsNevisAllTok: Label 'SAINTKITTSNEVIS-ALL', MaxLength = 20, Locked = true;
        SaintKittsNevisAllLocationLbl: Label 'St. Kitts & Nevis - all location', MaxLength = 100;
        SaintLuciaAllTok: Label 'SAINTLUCIA-ALL', MaxLength = 20, Locked = true;
        SaintLuciaAllLocationLbl: Label 'St. Lucia - all location', MaxLength = 100;
        SaintMartinAllTok: Label 'SAINTMARTIN-ALL', MaxLength = 20, Locked = true;
        SaintMartinAllLocationLbl: Label 'Saint Martin - all location', MaxLength = 100;
        SaintPierreQuelonAllTok: Label 'SAINTPIERREQUELO-ALL', MaxLength = 20, Locked = true;
        SaintPierreQuelonAllLocationLbl: Label 'St. Pierre & Miquelon - all location', MaxLength = 100;
        SaintVincentAllTok: Label 'SAINTVINCENT-ALL', MaxLength = 20, Locked = true;
        SaintVincentAllLocationLbl: Label 'St. Vincent & Grenadines - all location', MaxLength = 100;
        SanMarinoAllTok: Label 'SANMARINO-ALL', MaxLength = 20, Locked = true;
        SanMarinoAllLocationLbl: Label 'San Marino - all location', MaxLength = 100;
        SaoTomeAllTok: Label 'SAOTOME-ALL', MaxLength = 20, Locked = true;
        SaoTomeAllLocationLbl: Label 'Sao Tome & Principe - all location', MaxLength = 100;
        SenegalAllTok: Label 'SENEGAL-ALL', MaxLength = 20, Locked = true;
        SenegalAllLocationLbl: Label 'Senegal - all location', MaxLength = 100;
        SeychellesAllTok: Label 'SEYCHELLES-ALL', MaxLength = 20, Locked = true;
        SeychellesAllLocationLbl: Label 'Seychelles - all location', MaxLength = 100;
        SierraLeoneAllTok: Label 'SIERRALEONE-ALL', MaxLength = 20, Locked = true;
        SierraLeoneAllLocationLbl: Label 'Sierra Leone - all location', MaxLength = 100;
        SintMaartenAllTok: Label 'SINTMAARTEN-ALL', MaxLength = 20, Locked = true;
        SintMaartenAllLocationLbl: Label 'Sint Maarten - all location', MaxLength = 100;
        SomaliaAllTok: Label 'SOMALIA-ALL', MaxLength = 20, Locked = true;
        SomaliaAllLocationLbl: Label 'Somalia - all location', MaxLength = 100;
        SouthGeorgiaAllTok: Label 'SOUTHGEORGIA-ALL', MaxLength = 20, Locked = true;
        SouthGeorgiaAllLocationLbl: Label 'South Georgia and South Sandwich Islands - all location', MaxLength = 100;
        SouthSudanAllTok: Label 'SOUTHSUDAN-ALL', MaxLength = 20, Locked = true;
        SouthSudanAllLocationLbl: Label 'South Sudan - all location', MaxLength = 100;
        SriLankaAllTok: Label 'SRILANKA-ALL', MaxLength = 20, Locked = true;
        SriLankaAllLocationLbl: Label 'Sri Lanka - all location', MaxLength = 100;
        SudanAllTok: Label 'SUDAN-ALL', MaxLength = 20, Locked = true;
        SudanAllLocationLbl: Label 'Sudan - all location', MaxLength = 100;
        SurinameAllTok: Label 'SURINAME-ALL', MaxLength = 20, Locked = true;
        SurinameAllLocationLbl: Label 'Suriname - all location', MaxLength = 100;
        SvalbardJanMayenAllTok: Label 'SVALBARDJANMAYEN-ALL', MaxLength = 20, Locked = true;
        SvalbardJanMayenAllLocationLbl: Label 'Svalbard & Jan Mayen - all location', MaxLength = 100;
        SyriaAllTok: Label 'SYRIA-ALL', MaxLength = 20, Locked = true;
        SyriaAllLocationLbl: Label 'Syria - all location', MaxLength = 100;
        TaiwanAllTok: Label 'TAIWAN-ALL', MaxLength = 20, Locked = true;
        TaiwanAllLocationLbl: Label 'Taiwan - all location', MaxLength = 100;
        TajikistanAllTok: Label 'TAJIKISTAN-ALL', MaxLength = 20, Locked = true;
        TajikistanAllLocationLbl: Label 'Tajikistan - all location', MaxLength = 100;
        TimorLesteAllTok: Label 'TIMORLESTE-ALL', MaxLength = 20, Locked = true;
        TimorLesteAllLocationLbl: Label 'Timor-Leste - all location', MaxLength = 100;
        TogoAllTok: Label 'TOGO-ALL', MaxLength = 20, Locked = true;
        TogoAllLocationLbl: Label 'Togo - all location', MaxLength = 100;
        TokelauAllTok: Label 'TOKELAU-ALL', MaxLength = 20, Locked = true;
        TokelauAllLocationLbl: Label 'Tokelau - all location', MaxLength = 100;
        TongaAllTok: Label 'TONGA-ALL', MaxLength = 20, Locked = true;
        TongaAllLocationLbl: Label 'Tonga - all location', MaxLength = 100;
        TrinidadTobagoAllTok: Label 'TRINIDADTOBAGO-ALL', MaxLength = 20, Locked = true;
        TrinidadTobagoAllLocationLbl: Label 'Trinidad & Tobago - all location', MaxLength = 100;
        TurkmenistanAllTok: Label 'TURKMENISTAN-ALL', MaxLength = 20, Locked = true;
        TurkmenistanAllLocationLbl: Label 'Turkmenistan - all location', MaxLength = 100;
        TurksCalcosAllTok: Label 'TURKSCALCOS-ALL', MaxLength = 20, Locked = true;
        TurksCalcosAllLocationLbl: Label 'Turks & Caicos Islands - all location', MaxLength = 100;
        TuvaluAllTok: Label 'TUVALU-ALL', MaxLength = 20, Locked = true;
        TuvaluAllLocationLbl: Label 'Tuvalu - all location', MaxLength = 100;
        UkraineAllTok: Label 'UKRAINE-ALL', MaxLength = 20, Locked = true;
        UkraineAllLocationLbl: Label 'Ukraine - all location', MaxLength = 100;
        USMinorOutlyingAllTok: Label 'USMINOROUTLYING-ALL', MaxLength = 20, Locked = true;
        USMinorOutlyingAllLocationLbl: Label 'U.S. Minor Outlying Islands - all location', MaxLength = 100;
        UruguayAllTok: Label 'URUGUAY-ALL', MaxLength = 20, Locked = true;
        UruguayAllLocationLbl: Label 'Uruguay - all location', MaxLength = 100;
        UzbekistanAllTok: Label 'UZBEKISTAN-ALL', MaxLength = 20, Locked = true;
        UzbekistanAllLocationLbl: Label 'Uzbekistan - all location', MaxLength = 100;
        VenezuelAllTok: Label 'VENEZUEL-ALL', MaxLength = 20, Locked = true;
        VenezuelAllLocationLbl: Label 'Venezuela - all location', MaxLength = 100;
        VietnamAllTok: Label 'VIETNAM-ALL', MaxLength = 20, Locked = true;
        VietnamAllLocationLbl: Label 'Vietnam - all location', MaxLength = 100;
        VirginIslandsBrAllTok: Label 'VIRGINISLANDSBR-ALL', MaxLength = 20, Locked = true;
        VirginIslandsBrAllLocationLbl: Label 'British Virgin Islands - all location', MaxLength = 100;
        VirginIslandsUSAllTok: Label 'VIRGINISLANDSUS-ALL', MaxLength = 20, Locked = true;
        VirginIslandsUSAllLocationLbl: Label 'U.S. Virgin Islands - all location', MaxLength = 100;
        WallisatunaAllTok: Label 'WALLISATUNA-ALL', MaxLength = 20, Locked = true;
        WallisatunaAllLocationLbl: Label 'Wallis & Futuna - all location', MaxLength = 100;
        WesternSaharaAllTok: Label 'WESTERNSAHARA-ALL', MaxLength = 20, Locked = true;
        WesternSaharaAllLocationLbl: Label 'Western Sahara - all location', MaxLength = 100;
        YemenAllTok: Label 'YEMEN-ALL', MaxLength = 20, Locked = true;
        YemenAllLocationLbl: Label 'Yemen - all location', MaxLength = 100;
        ZambiaAllTok: Label 'ZAMBIA-ALL', MaxLength = 20, Locked = true;
        ZambiaAllLocationLbl: Label 'Zambia - all location', MaxLength = 100;
        ZimbabweAllTok: Label 'ZIMBABWE-ALL', MaxLength = 20, Locked = true;
        ZimbabweAllLocationLbl: Label 'Zimbabwe - all location', MaxLength = 100;
        AlandIslandsAllTok: Label 'ALANDISLANDS-ALL', MaxLength = 20, Locked = true;
        AlandIslandsAllLocationLbl: Label 'Aland Islands - all location', MaxLength = 100;


    internal procedure InsertExpenseLocation(var ExpenseLocation: Record "Expense Location"; Code: Code[20]; Description: Text[100]; CountryRegionCode: Code[10]; City: Text[30]; County: Text[30])
    begin
        if ExpenseLocation.Get(Code) then
            exit;
        ExpenseLocation.Validate("No.", Code);
        ExpenseLocation.Validate(Description, Description);
        ExpenseLocation.Validate("Country/Region Code", CountryRegionCode);
        ExpenseLocation.Validate("City", City);
        ExpenseLocation.Validate("County", County);
        ExpenseLocation.Insert();
    end;

    procedure UnitedArabEmiratesAll(): Code[20]
    begin
        exit(UnitedArabEmiratesAllTok);
    end;

    procedure AustriaAll(): Code[20]
    begin
        exit(AustriaAllTok);
    end;

    procedure AustraliaAll(): Code[20]
    begin
        exit(AustraliaAllTok);
    end;

    procedure BelgiumAll(): Code[20]
    begin
        exit(BelgiumAllTok);
    end;

    procedure BulgariaAll(): Code[20]
    begin
        exit(BulgariaAllTok);
    end;

    procedure BruneiDarussalamAll(): Code[20]
    begin
        exit(BruneiDarussalamAllTok);
    end;

    procedure BrazilAll(): Code[20]
    begin
        exit(BrazilAllTok);
    end;

    procedure SwitzerlandAll(): Code[20]
    begin
        exit(SwitzerlandAllTok);
    end;

    procedure SwitzerlandGeneva(): Code[20]
    begin
        exit(SwitzerlandGenevaTok);
    end;

    procedure SwitzerlandZurich(): Code[20]
    begin
        exit(SwitzerlandZurichTok);
    end;

    procedure ChinaAll(): Code[20]
    begin
        exit(ChinaAllTok);
    end;

    procedure CostaRicaAll(): Code[20]
    begin
        exit(CostaRicaAllTok);
    end;

    procedure CyprusAll(): Code[20]
    begin
        exit(CyprusAllTok);
    end;

    procedure CzechiaAll(): Code[20]
    begin
        exit(CzechiaAllTok);
    end;

    procedure AlgeriaAll(): Code[20]
    begin
        exit(AlgeriaAllTok);
    end;

    procedure EstoniaAll(): Code[20]
    begin
        exit(EstoniaAllTok);
    end;

    procedure GreeceAll(): Code[20]
    begin
        exit(GreeceAllTok);
    end;

    procedure SpainAll(): Code[20]
    begin
        exit(SpainAllTok);
    end;

    procedure FinlandAll(): Code[20]
    begin
        exit(FinlandAllTok);
    end;

    procedure FijiIslandsAll(): Code[20]
    begin
        exit(FijiIslandsAllTok);
    end;

    procedure CroatiaAll(): Code[20]
    begin
        exit(CroatiaAllTok);
    end;

    procedure HungaryAll(): Code[20]
    begin
        exit(HungaryAllTok);
    end;

    procedure IndonesiaAll(): Code[20]
    begin
        exit(IndonesiaAllTok);
    end;

    procedure IrelandAll(): Code[20]
    begin
        exit(IrelandAllTok);
    end;

    procedure IndiaAll(): Code[20]
    begin
        exit(IndiaAllTok);
    end;

    procedure IcelandAll(): Code[20]
    begin
        exit(IcelandAllTok);
    end;

    procedure ItalyAll(): Code[20]
    begin
        exit(ItalyAllTok);
    end;

    procedure JapanAll(): Code[20]
    begin
        exit(JapanAllTok);
    end;

    procedure JapanTokyo(): Code[20]
    begin
        exit(JapanTokyoTok);
    end;

    procedure KenyaAll(): Code[20]
    begin
        exit(KenyaAllTok);
    end;

    procedure LithuaniaAll(): Code[20]
    begin
        exit(LithuaniaAllTok);
    end;

    procedure LuxembourgAll(): Code[20]
    begin
        exit(LuxembourgAllTok);
    end;

    procedure LatviaAll(): Code[20]
    begin
        exit(LatviaAllTok);
    end;

    procedure MoroccoAll(): Code[20]
    begin
        exit(MoroccoAllTok);
    end;

    procedure MontenegroAll(): Code[20]
    begin
        exit(MontenegroAllTok);
    end;

    procedure MaltaAll(): Code[20]
    begin
        exit(MaltaAllTok);
    end;

    procedure MexicoAll(): Code[20]
    begin
        exit(MexicoAllTok);
    end;

    procedure MalaysiaAll(): Code[20]
    begin
        exit(MalaysiaAllTok);
    end;

    procedure MozambiqueAll(): Code[20]
    begin
        exit(MozambiqueAllTok);
    end;

    procedure NigeriaAll(): Code[20]
    begin
        exit(NigeriaAllTok);
    end;

    procedure NorthernIrelandAll(): Code[20]
    begin
        exit(NorthernIrelandAllTok);
    end;

    procedure NetherlandsAll(): Code[20]
    begin
        exit(NetherlandsAllTok);
    end;

    procedure NorwayAll(): Code[20]
    begin
        exit(NorwayAllTok);
    end;

    procedure NorwayOslo(): Code[20]
    begin
        exit(NorwayOsloTok);
    end;

    procedure NewZealandAll(): Code[20]
    begin
        exit(NewZealandAllTok);
    end;

    procedure PhilippinesAll(): Code[20]
    begin
        exit(PhilippinesAllTok);
    end;

    procedure PolandAll(): Code[20]
    begin
        exit(PolandAllTok);
    end;

    procedure PortugalAll(): Code[20]
    begin
        exit(PortugalAllTok);
    end;

    procedure RomaniaAll(): Code[20]
    begin
        exit(RomaniaAllTok);
    end;

    procedure SerbiaAll(): Code[20]
    begin
        exit(SerbiaAllTok);
    end;

    procedure RussiaAll(): Code[20]
    begin
        exit(RussiaAllTok);
    end;

    procedure SaudiArabiaAll(): Code[20]
    begin
        exit(SaudiArabiaAllTok);
    end;

    procedure SolomonIslandsAll(): Code[20]
    begin
        exit(SolomonIslandsAllTok);
    end;

    procedure SwedenAll(): Code[20]
    begin
        exit(SwedenAllTok);
    end;

    procedure SingaporeAll(): Code[20]
    begin
        exit(SingaporeAllTok);
    end;

    procedure SloveniaAll(): Code[20]
    begin
        exit(SloveniaAllTok);
    end;

    procedure SlovakiaAll(): Code[20]
    begin
        exit(SlovakiaAllTok);
    end;

    procedure SwazilandAll(): Code[20]
    begin
        exit(SwazilandAllTok);
    end;

    procedure ThailandAll(): Code[20]
    begin
        exit(ThailandAllTok);
    end;

    procedure TunisiaAll(): Code[20]
    begin
        exit(TunisiaAllTok);
    end;

    procedure TurkiyeAll(): Code[20]
    begin
        exit(TurkiyeAllTok);
    end;

    procedure TanzaniaAll(): Code[20]
    begin
        exit(TanzaniaAllTok);
    end;

    procedure UgandaAll(): Code[20]
    begin
        exit(UgandaAllTok);
    end;

    procedure VanuatuAll(): Code[20]
    begin
        exit(VanuatuAllTok);
    end;

    procedure SamoaAll(): Code[20]
    begin
        exit(SamoaAllTok);
    end;

    procedure SouthAfricaAll(): Code[20]
    begin
        exit(SouthAfricaAllTok);
    end;

    procedure AfghanistanAll(): Code[20]
    begin
        exit(AfghanistanAllTok);
    end;

    procedure AlbaniaAll(): Code[20]
    begin
        exit(AlbaniaAllTok);
    end;

    procedure AndorraAll(): Code[20]
    begin
        exit(AndorraAllTok);
    end;

    procedure AngolaAll(): Code[20]
    begin
        exit(AngolaAllTok);
    end;

    procedure AnguillaAll(): Code[20]
    begin
        exit(AnguillaAllTok);
    end;

    procedure AntarcticaAll(): Code[20]
    begin
        exit(AntarcticaAllTok);
    end;

    procedure AntiguaBarbudaAll(): Code[20]
    begin
        exit(AntiguaBarbudaAllTok);
    end;

    procedure ArgentinaAll(): Code[20]
    begin
        exit(ArgentinaAllTok);
    end;

    procedure ArmeniaAll(): Code[20]
    begin
        exit(ArmeniaAllTok);
    end;

    procedure ArubaAll(): Code[20]
    begin
        exit(ArubaAllTok);
    end;

    procedure AzerbaijanAll(): Code[20]
    begin
        exit(AzerbaijanAllTok);
    end;

    procedure BahamasAll(): Code[20]
    begin
        exit(BahamasAllTok);
    end;

    procedure BahrainAll(): Code[20]
    begin
        exit(BahrainAllTok);
    end;

    procedure BangladeshAll(): Code[20]
    begin
        exit(BangladeshAllTok);
    end;

    procedure BarbadosAll(): Code[20]
    begin
        exit(BarbadosAllTok);
    end;

    procedure BelarusAll(): Code[20]
    begin
        exit(BelarusAllTok);
    end;

    procedure BelizeAll(): Code[20]
    begin
        exit(BelizeAllTok);
    end;

    procedure BeninAll(): Code[20]
    begin
        exit(BeninAllTok);
    end;

    procedure BermudaAll(): Code[20]
    begin
        exit(BermudaAllTok);
    end;

    procedure BhutanAll(): Code[20]
    begin
        exit(BhutanAllTok);
    end;

    procedure BoliviaAll(): Code[20]
    begin
        exit(BoliviaAllTok);
    end;

    procedure BonaireAll(): Code[20]
    begin
        exit(BonaireAllTok);
    end;

    procedure BosniaHerzegovinaAll(): Code[20]
    begin
        exit(BosniaHerzegovinaAllTok);
    end;

    procedure BotswanaAll(): Code[20]
    begin
        exit(BotswanaAllTok);
    end;

    procedure BouvetIslandAll(): Code[20]
    begin
        exit(BouvetIslandAllTok);
    end;

    procedure BritishIndianOceanAll(): Code[20]
    begin
        exit(BritishIndianOceanAllTok);
    end;

    procedure BurkinaFasoAll(): Code[20]
    begin
        exit(BurkinaFasoAllTok);
    end;

    procedure BurundiAll(): Code[20]
    begin
        exit(BurundiAllTok);
    end;

    procedure CaboVerdeAll(): Code[20]
    begin
        exit(CaboVerdeAllTok);
    end;

    procedure CambodiaAll(): Code[20]
    begin
        exit(CambodiaAllTok);
    end;

    procedure CameroonAll(): Code[20]
    begin
        exit(CameroonAllTok);
    end;

    procedure CaymanIslandsAll(): Code[20]
    begin
        exit(CaymanIslandsAllTok);
    end;

    procedure CentralAfricanAll(): Code[20]
    begin
        exit(CentralAfricanAllTok);
    end;

    procedure ChadAll(): Code[20]
    begin
        exit(ChadAllTok);
    end;

    procedure ChileAll(): Code[20]
    begin
        exit(ChileAllTok);
    end;

    procedure ChristmasIslandAll(): Code[20]
    begin
        exit(ChristmasIslandAllTok);
    end;

    procedure CocosIslandsAll(): Code[20]
    begin
        exit(CocosIslandsAllTok);
    end;

    procedure ColombiaAll(): Code[20]
    begin
        exit(ColombiaAllTok);
    end;

    procedure ComorosAll(): Code[20]
    begin
        exit(ComorosAllTok);
    end;

    procedure CongoDRAll(): Code[20]
    begin
        exit(CongoDRAllTok);
    end;

    procedure CongoAll(): Code[20]
    begin
        exit(CongoAllTok);
    end;

    procedure CookIslandsAll(): Code[20]
    begin
        exit(CookIslandsAllTok);
    end;

    procedure CubaAll(): Code[20]
    begin
        exit(CubaAllTok);
    end;

    procedure CuracaoAll(): Code[20]
    begin
        exit(CuracaoAllTok);
    end;

    procedure CotedIvoireAll(): Code[20]
    begin
        exit(CotedIvoireAllTok);
    end;

    procedure DjiboutiAll(): Code[20]
    begin
        exit(DjiboutiAllTok);
    end;

    procedure DominicaAll(): Code[20]
    begin
        exit(DominicaAllTok);
    end;

    procedure DominicanAll(): Code[20]
    begin
        exit(DominicanAllTok);
    end;

    procedure EcuadorAll(): Code[20]
    begin
        exit(EcuadorAllTok);
    end;

    procedure EgyptAll(): Code[20]
    begin
        exit(EgyptAllTok);
    end;

    procedure ElSalvadorAll(): Code[20]
    begin
        exit(ElSalvadorAllTok);
    end;

    procedure EquatorialGuineaAll(): Code[20]
    begin
        exit(EquatorialGuineaAllTok);
    end;

    procedure EritreaAll(): Code[20]
    begin
        exit(EritreaAllTok);
    end;

    procedure EthiopiaAll(): Code[20]
    begin
        exit(EthiopiaAllTok);
    end;

    procedure FalklandIslandsAll(): Code[20]
    begin
        exit(FalklandIslandsAllTok);
    end;

    procedure FaroeIslandsAll(): Code[20]
    begin
        exit(FaroeIslandsAllTok);
    end;

    procedure FrenchGuianaAll(): Code[20]
    begin
        exit(FrenchGuianaAllTok);
    end;

    procedure FrenchPolynesiaAll(): Code[20]
    begin
        exit(FrenchPolynesiaAllTok);
    end;

    procedure FrenchSouthernAll(): Code[20]
    begin
        exit(FrenchSouthernAllTok);
    end;

    procedure GabonAll(): Code[20]
    begin
        exit(GabonAllTok);
    end;

    procedure GambiaAll(): Code[20]
    begin
        exit(GambiaAllTok);
    end;

    procedure GeorgiaAll(): Code[20]
    begin
        exit(GeorgiaAllTok);
    end;

    procedure GhanaAll(): Code[20]
    begin
        exit(GhanaAllTok);
    end;

    procedure GibraltarAll(): Code[20]
    begin
        exit(GibraltarAllTok);
    end;

    procedure GreenlandAll(): Code[20]
    begin
        exit(GreenlandAllTok);
    end;

    procedure GrenadaAll(): Code[20]
    begin
        exit(GrenadaAllTok);
    end;

    procedure GuadeloupeAll(): Code[20]
    begin
        exit(GuadeloupeAllTok);
    end;

    procedure GuamAll(): Code[20]
    begin
        exit(GuamAllTok);
    end;

    procedure GuatemalaAll(): Code[20]
    begin
        exit(GuatemalaAllTok);
    end;

    procedure GuernseyAll(): Code[20]
    begin
        exit(GuernseyAllTok);
    end;

    procedure GuineaAll(): Code[20]
    begin
        exit(GuineaAllTok);
    end;

    procedure GuineaBissauAll(): Code[20]
    begin
        exit(GuineaBissauAllTok);
    end;

    procedure GuyanaAll(): Code[20]
    begin
        exit(GuyanaAllTok);
    end;

    procedure HaitiAll(): Code[20]
    begin
        exit(HaitiAllTok);
    end;

    procedure HeardIslandAll(): Code[20]
    begin
        exit(HeardIslandAllTok);
    end;

    procedure HolySeeAll(): Code[20]
    begin
        exit(HolySeeAllTok);
    end;

    procedure HondurasAll(): Code[20]
    begin
        exit(HondurasAllTok);
    end;

    procedure HongKongAll(): Code[20]
    begin
        exit(HongKongAllTok);
    end;

    procedure IsleManAll(): Code[20]
    begin
        exit(IsleManAllTok);
    end;

    procedure IsraelAll(): Code[20]
    begin
        exit(IsraelAllTok);
    end;

    procedure JamaicaAll(): Code[20]
    begin
        exit(JamaicaAllTok);
    end;

    procedure JerseyAll(): Code[20]
    begin
        exit(JerseyAllTok);
    end;

    procedure JordanAll(): Code[20]
    begin
        exit(JordanAllTok);
    end;

    procedure KazakhstanAll(): Code[20]
    begin
        exit(KazakhstanAllTok);
    end;

    procedure KiribatiAll(): Code[20]
    begin
        exit(KiribatiAllTok);
    end;

    procedure NorthKoreaAll(): Code[20]
    begin
        exit(NorthKoreaAllTok);
    end;

    procedure SouthKoreaAll(): Code[20]
    begin
        exit(SouthKoreaAllTok);
    end;

    procedure KuwaitAll(): Code[20]
    begin
        exit(KuwaitAllTok);
    end;

    procedure KyrgyzstanAll(): Code[20]
    begin
        exit(KyrgyzstanAllTok);
    end;

    procedure LaosAll(): Code[20]
    begin
        exit(LaosAllTok);
    end;

    procedure LebanonAll(): Code[20]
    begin
        exit(LebanonAllTok);
    end;

    procedure LesothoAll(): Code[20]
    begin
        exit(LesothoAllTok);
    end;

    procedure LiberiaAll(): Code[20]
    begin
        exit(LiberiaAllTok);
    end;

    procedure LibyaAll(): Code[20]
    begin
        exit(LibyaAllTok);
    end;

    procedure LiechtensteinAll(): Code[20]
    begin
        exit(LiechtensteinAllTok);
    end;

    procedure MacaoAll(): Code[20]
    begin
        exit(MacaoAllTok);
    end;

    procedure MadagascarAll(): Code[20]
    begin
        exit(MadagascarAllTok);
    end;

    procedure MalawiAll(): Code[20]
    begin
        exit(MalawiAllTok);
    end;

    procedure MaldivesAll(): Code[20]
    begin
        exit(MaldivesAllTok);
    end;

    procedure MaliAll(): Code[20]
    begin
        exit(MaliAllTok);
    end;

    procedure MarshallIslandsAll(): Code[20]
    begin
        exit(MarshallIslandsAllTok);
    end;

    procedure MartiniqueAll(): Code[20]
    begin
        exit(MartiniqueAllTok);
    end;

    procedure MauritaniaAll(): Code[20]
    begin
        exit(MauritaniaAllTok);
    end;

    procedure MauritiusAll(): Code[20]
    begin
        exit(MauritiusAllTok);
    end;

    procedure MayotteAll(): Code[20]
    begin
        exit(MayotteAllTok);
    end;

    procedure MicronesiaAll(): Code[20]
    begin
        exit(MicronesiaAllTok);
    end;

    procedure MoldovaAll(): Code[20]
    begin
        exit(MoldovaAllTok);
    end;

    procedure MonacoAll(): Code[20]
    begin
        exit(MonacoAllTok);
    end;

    procedure MongoliaAll(): Code[20]
    begin
        exit(MongoliaAllTok);
    end;

    procedure MontserratAll(): Code[20]
    begin
        exit(MontserratAllTok);
    end;

    procedure MyanmarAll(): Code[20]
    begin
        exit(MyanmarAllTok);
    end;

    procedure NamibiaAll(): Code[20]
    begin
        exit(NamibiaAllTok);
    end;

    procedure NauruAll(): Code[20]
    begin
        exit(NauruAllTok);
    end;

    procedure NepalAll(): Code[20]
    begin
        exit(NepalAllTok);
    end;

    procedure NewCaledoniaAll(): Code[20]
    begin
        exit(NewCaledoniaAllTok);
    end;

    procedure NigerAll(): Code[20]
    begin
        exit(NigerAllTok);
    end;

    procedure NiueAll(): Code[20]
    begin
        exit(NiueAllTok);
    end;

    procedure NorfolkIslandAll(): Code[20]
    begin
        exit(NorfolkIslandAllTok);
    end;

    procedure NorthMacedoniaAll(): Code[20]
    begin
        exit(NorthMacedoniaAllTok);
    end;

    procedure NorthernMarianaAll(): Code[20]
    begin
        exit(NorthernMarianaAllTok);
    end;

    procedure OmanAll(): Code[20]
    begin
        exit(OmanAllTok);
    end;

    procedure PakistanAll(): Code[20]
    begin
        exit(PakistanAllTok);
    end;

    procedure PalauAll(): Code[20]
    begin
        exit(PalauAllTok);
    end;

    procedure PalestineAll(): Code[20]
    begin
        exit(PalestineAllTok);
    end;

    procedure PanamaAll(): Code[20]
    begin
        exit(PanamaAllTok);
    end;

    procedure PapuaNewGuineaAll(): Code[20]
    begin
        exit(PapuaNewGuineaAllTok);
    end;

    procedure ParaguayAll(): Code[20]
    begin
        exit(ParaguayAllTok);
    end;

    procedure PeruAll(): Code[20]
    begin
        exit(PeruAllTok);
    end;

    procedure PitcairnAll(): Code[20]
    begin
        exit(PitcairnAllTok);
    end;

    procedure PuertoRicoAll(): Code[20]
    begin
        exit(PuertoRicoAllTok);
    end;

    procedure QatarAll(): Code[20]
    begin
        exit(QatarAllTok);
    end;

    procedure RwandaAll(): Code[20]
    begin
        exit(RwandaAllTok);
    end;

    procedure ReunionAll(): Code[20]
    begin
        exit(ReunionAllTok);
    end;

    procedure SaintBarthelemyAll(): Code[20]
    begin
        exit(SaintBarthelemyAllTok);
    end;

    procedure SaintHelenaAll(): Code[20]
    begin
        exit(SaintHelenaAllTok);
    end;

    procedure SaintKittsNevisAll(): Code[20]
    begin
        exit(SaintKittsNevisAllTok);
    end;

    procedure SaintLuciaAll(): Code[20]
    begin
        exit(SaintLuciaAllTok);
    end;

    procedure SaintMartinAll(): Code[20]
    begin
        exit(SaintMartinAllTok);
    end;

    procedure SaintPierreQuelonAll(): Code[20]
    begin
        exit(SaintPierreQuelonAllTok);
    end;

    procedure SaintVincentAll(): Code[20]
    begin
        exit(SaintVincentAllTok);
    end;

    procedure SanMarinoAll(): Code[20]
    begin
        exit(SanMarinoAllTok);
    end;

    procedure SaoTomeAll(): Code[20]
    begin
        exit(SaoTomeAllTok);
    end;

    procedure SenegalAll(): Code[20]
    begin
        exit(SenegalAllTok);
    end;

    procedure SeychellesAll(): Code[20]
    begin
        exit(SeychellesAllTok);
    end;

    procedure SierraLeoneAll(): Code[20]
    begin
        exit(SierraLeoneAllTok);
    end;

    procedure SintMaartenAll(): Code[20]
    begin
        exit(SintMaartenAllTok);
    end;

    procedure SomaliaAll(): Code[20]
    begin
        exit(SomaliaAllTok);
    end;

    procedure SouthGeorgiaAll(): Code[20]
    begin
        exit(SouthGeorgiaAllTok);
    end;

    procedure SouthSudanAll(): Code[20]
    begin
        exit(SouthSudanAllTok);
    end;

    procedure SriLankaAll(): Code[20]
    begin
        exit(SriLankaAllTok);
    end;

    procedure SudanAll(): Code[20]
    begin
        exit(SudanAllTok);
    end;

    procedure SurinameAll(): Code[20]
    begin
        exit(SurinameAllTok);
    end;

    procedure SvalbardJanMayenAll(): Code[20]
    begin
        exit(SvalbardJanMayenAllTok);
    end;

    procedure SyriaAll(): Code[20]
    begin
        exit(SyriaAllTok);
    end;

    procedure TaiwanAll(): Code[20]
    begin
        exit(TaiwanAllTok);
    end;

    procedure TajikistanAll(): Code[20]
    begin
        exit(TajikistanAllTok);
    end;

    procedure TimorLesteAll(): Code[20]
    begin
        exit(TimorLesteAllTok);
    end;

    procedure TogoAll(): Code[20]
    begin
        exit(TogoAllTok);
    end;

    procedure TokelauAll(): Code[20]
    begin
        exit(TokelauAllTok);
    end;

    procedure TongaAll(): Code[20]
    begin
        exit(TongaAllTok);
    end;

    procedure TrinidadTobagoAll(): Code[20]
    begin
        exit(TrinidadTobagoAllTok);
    end;

    procedure TurkmenistanAll(): Code[20]
    begin
        exit(TurkmenistanAllTok);
    end;

    procedure TurksCalcosAll(): Code[20]
    begin
        exit(TurksCalcosAllTok);
    end;

    procedure TuvaluAll(): Code[20]
    begin
        exit(TuvaluAllTok);
    end;

    procedure UkraineAll(): Code[20]
    begin
        exit(UkraineAllTok);
    end;

    procedure USMinorOutlyingAll(): Code[20]
    begin
        exit(USMinorOutlyingAllTok);
    end;

    procedure UruguayAll(): Code[20]
    begin
        exit(UruguayAllTok);
    end;

    procedure UzbekistanAll(): Code[20]
    begin
        exit(UzbekistanAllTok);
    end;

    procedure VenezuelAll(): Code[20]
    begin
        exit(VenezuelAllTok);
    end;

    procedure VietnamAll(): Code[20]
    begin
        exit(VietnamAllTok);
    end;

    procedure VirginIslandsBrAll(): Code[20]
    begin
        exit(VirginIslandsBrAllTok);
    end;

    procedure VirginIslandsUSAll(): Code[20]
    begin
        exit(VirginIslandsUSAllTok);
    end;

    procedure WallisatunaAll(): Code[20]
    begin
        exit(WallisatunaAllTok);
    end;

    procedure WesternSaharaAll(): Code[20]
    begin
        exit(WesternSaharaAllTok);
    end;

    procedure YemenAll(): Code[20]
    begin
        exit(YemenAllTok);
    end;

    procedure ZambiaAll(): Code[20]
    begin
        exit(ZambiaAllTok);
    end;

    procedure ZimbabweAll(): Code[20]
    begin
        exit(ZimbabweAllTok);
    end;

    procedure AlandIslandsAll(): Code[20]
    begin
        exit(AlandIslandsAllTok);
    end;

    procedure CanadaAll(): Code[20]
    begin
        exit(CanadaAllTok);
    end;

    procedure DenmarkAll(): Code[20]
    begin
        exit(DenmarkAllTok);
    end;

    procedure DenmarkCph(): Code[20]
    begin
        exit(DenmarkCphTok);
    end;

    procedure Domestic(): Code[20]
    begin
        exit(DomesticTok);
    end;

    procedure FranceAll(): Code[20]
    begin
        exit(FranceAllTok);
    end;

    procedure FranceParis(): Code[20]
    begin
        exit(FranceParisTok);
    end;

    procedure GermanyAll(): Code[20]
    begin
        exit(GermanyAllTok);
    end;

    procedure UKLondon(): Code[20]
    begin
        exit(UKLondonTok);
    end;

    procedure UKOther(): Code[20]
    begin
        exit(UKOtherTok);
    end;

    procedure USAFlorida(): Code[20]
    begin
        exit(USAFloridaTok);
    end;

    procedure USANY(): Code[20]
    begin
        exit(USANYTok);
    end;

    procedure USAOther(): Code[20]
    begin
        exit(USAOtherTok);
    end;
}