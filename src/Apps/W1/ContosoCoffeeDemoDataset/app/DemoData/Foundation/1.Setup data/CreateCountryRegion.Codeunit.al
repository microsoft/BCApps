// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Foundation;

using Microsoft.DemoTool.Helpers;
using Microsoft.Foundation.Address;

codeunit 5205 "Create Country/Region"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Description = 'Should contain all country or region where BC is available, updated as of 2024-08-26. Other country/regions added for reference as of 2026-06-22';

    trigger OnRun()
    var
        ContosoCountryOrRegion: Codeunit "Contoso Country Or Region";
    begin
        ContosoCountryOrRegion.InsertCountryOrRegion(AE(), UnitedArabEmiratesLbl, '784', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(AT(), AustriaLbl, '040', ATTok, ATTok, Enum::"Country/Region Address Format"::"Blank Line+Post Code+City", 1, '0007', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(AU(), AustraliaLbl, '036', '', '', Enum::"Country/Region Address Format"::"City+County+Post Code", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(BE(), BelgiumLbl, '056', BETok, BETok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9925', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(BG(), BulgariaLbl, '100', BGTok, BGTok, Enum::"Country/Region Address Format"::"City+County+Post Code", 1, '9926', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(BN(), BruneiDarussalamLbl, '096', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(BR(), BrazilLbl, '076', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(CA(), CanadaLbl, '124', '', '', Enum::"Country/Region Address Format"::"City+County+Post Code", 1, '', 'Province');
        ContosoCountryOrRegion.InsertCountryOrRegion(CH(), SwitzerlandLbl, '756', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(CN(), ChinaLbl, '156', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(CR(), CostaRicaLbl, '188', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(CY(), CyprusLbl, '196', CYTok, CYTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9928', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(CZ(), CzechiaLbl, '203', CZTok, CZTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9929', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(DE(), GermanyLbl, '276', DETok, DETok, Enum::"Country/Region Address Format"::"Blank Line+Post Code+City", 1, '9930', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(DK(), DenmarkLbl, '208', DKTok, DKTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '0184', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(DZ(), AlgeriaLbl, '012', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(EE(), EstoniaLbl, '233', EETok, EETok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9931', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(EL(), GreeceLbl, '300', ELTok, ELTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(ES(), SpainLbl, '724', ESTok, ESTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9920', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(FI(), FinlandLbl, '246', FITok, FITok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(FJ(), FijiIslandsLbl, '242', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(FR(), FranceLbl, '250', FRTok, FRTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '0009', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(GB(), GreatBritainLbl, '826', '', GBTok, Enum::"Country/Region Address Format"::"City+County+Post Code", 1, '9932', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(HR(), CroatiaLbl, '191', HRTok, HRTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9934', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(HU(), HungaryLbl, '348', HUTok, HUTok, Enum::"Country/Region Address Format"::"City+Post Code", 1, '9910', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(ID(), IndonesiaLbl, '360', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(IE(), IrelandLbl, '372', IETok, IETok, Enum::"Country/Region Address Format"::"City+County+Post Code", 1, '9935', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(IND(), IndiaLbl, '356', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(IS(), IcelandLbl, '352', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(IT(), ItalyLbl, '380', ITTok, ITTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '0097', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(JP(), JapanLbl, '392', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(KE(), KenyaLbl, '404', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(LT(), LithuaniaLbl, '440', LTTok, LTTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '0200', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(LU(), LuxembourgLbl, '442', LUTok, LUTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9938', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(LV(), LatviaLbl, '428', LVTok, LVTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9939', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(MA(), MoroccoLbl, '504', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(ME(), MontenegroLbl, '499', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '9941', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(MT(), MaltaLbl, '470', MTTok, MTTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9943', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(MX(), MexicoLbl, '484', '', '', Enum::"Country/Region Address Format"::"City+County+Post Code", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(MY(), MalaysiaLbl, '458', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(MZ(), MozambiqueLbl, '508', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(NG(), NigeriaLbl, '566', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(NI(), NorthernIrelandLbl, CopyStr(GB(), 1, 2), '826', XITok, XITok, Enum::"Country/Region Address Format"::"City+County+Post Code", 1, '9932', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(NL(), NetherlandsLbl, '528', NLTok, NLTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9944', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(NO(), NorwayLbl, '578', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '0192', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(NZ(), NewZealandLbl, '554', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(PH(), PhilippinesLbl, '608', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(PL(), PolandLbl, '616', PLTok, PLTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9945', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(PT(), PortugalLbl, '620', PTTok, PTTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9946', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(RO(), RomaniaLbl, '642', ROTok, ROTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9947', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(RS(), SerbiaLbl, '688', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '9948', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(RU(), RussiaLbl, '643', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 2, '', 'Region');
        ContosoCountryOrRegion.InsertCountryOrRegion(SA(), SaudiArabiaLbl, '682', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(SB(), SolomonIslandsLbl, '090', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(SE(), SwedenLbl, '752', SETok, SETok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9955', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(SG(), SingaporeLbl, '702', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(SI(), SloveniaLbl, '705', SITok, SITok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9949', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(SK(), SlovakiaLbl, '703', SKTok, SKTok, Enum::"Country/Region Address Format"::"Post Code+City", 1, '9950', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(SZ(), SwazilandLbl, '748', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(TH(), ThailandLbl, '764', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(TN(), TunisiaLbl, '788', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(TR(), TürkiyeLbl, '792', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 0, '9952', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(TZ(), TanzaniaLbl, '834', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(UG(), UgandaLbl, '800', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 1, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(US(), USALbl, '840', '', '', Enum::"Country/Region Address Format"::"City+County+Post Code", 1, '', 'State');
        ContosoCountryOrRegion.InsertCountryOrRegion(VU(), VanuatuLbl, '548', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(WS(), SamoaLbl, '882', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion(ZA(), SouthAfricaLbl, '710', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AF', XAfghanistanLbl, '004', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AL', XAlbaniaLbl, '008', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AD', XAndorraLbl, '020', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AO', XAngolaLbl, '024', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AI', XAnguillaLbl, '660', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AQ', XAntarcticaLbl, '010', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AG', XAntiguaBarbudaLbl, '028', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AR', XArgentinaLbl, '032', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AM', XArmeniaLbl, '051', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AW', XArubaLbl, '533', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AZ', XAzerbaijanLbl, '031', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BS', XBahamasLbl, '044', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BH', XBahrainLbl, '048', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BD', XBangladeshLbl, '050', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BB', XBarbadosLbl, '052', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BY', XBelarusLbl, '112', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BZ', XBelizeLbl, '084', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BJ', XBeninLbl, '204', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BM', XBermudaLbl, '060', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BT', XBhutanLbl, '064', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BO', XBoliviaLbl, '068', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BQ', XBonaireLbl, '535', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BA', XBosniaHerzegovinaLbl, '070', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BW', XBotswanaLbl, '072', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BV', XBouvetIslandLbl, '074', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('IO', XBritishIndianOceanLbl, '086', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BF', XBurkinaFasoLbl, '854', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BI', XBurundiLbl, '108', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CV', XCaboVerdeLbl, '132', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KH', XCambodiaLbl, '116', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CM', XCameroonLbl, '120', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KY', XCaymanIslandsLbl, '136', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CF', XCentralAfricanLbl, '140', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TD', XChadLbl, '148', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CL', XChileLbl, '152', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CX', XChristmasIslandLbl, '162', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CC', XCocosIslandsLbl, '166', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CO', XColombiaLbl, '170', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KM', XComorosLbl, '174', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CD', XCongoDRLbl, '180', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CG', XCongoLbl, '178', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CK', XCookIslandsLbl, '184', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CU', XCubaLbl, '192', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CW', XCuracaoLbl, '531', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('CI', XCotedIvoireLbl, '384', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('DJ', XDjiboutiLbl, '262', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('DM', XDominicaLbl, '212', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('DO', XDominicanLbl, '214', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('EC', XEcuadorLbl, '218', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('EG', XEgyptLbl, '818', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SV', XElSalvadorLbl, '222', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GQ', XEquatorialGuineaLbl, '226', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('ER', XEritreaLbl, '232', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('ET', XEthiopiaLbl, '231', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('FK', XFalklandIslandsLbl, '238', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('FO', XFaroeIslandsLbl, '234', '', '', Enum::"Country/Region Address Format"::"Post Code+City", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GF', XFrenchGuianaLbl, '254', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PF', XFrenchPolynesiaLbl, '258', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TF', XFrenchSouthernLbl, '260', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GA', XGabonLbl, '266', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GM', XGambiaLbl, '270', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GE', XGeorgiaLbl, '268', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GH', XGhanaLbl, '288', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GI', XGibraltarLbl, '292', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GL', XGreenlandLbl, '304', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GD', XGrenadaLbl, '308', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GP', XGuadeloupeLbl, '312', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GU', XGuamLbl, '316', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GT', XGuatemalaLbl, '320', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GG', XGuernseyLbl, '831', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GN', XGuineaLbl, '324', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GW', XGuineaBissauLbl, '624', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GY', XGuyanaLbl, '328', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('HT', XHaitiLbl, '332', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('HM', XHeardIslandLbl, '334', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('VA', XHolySeeLbl, '336', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('HN', XHondurasLbl, '340', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('HK', XHongKongLbl, '344', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('IM', XIsleManLbl, '833', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('IL', XIsraelLbl, '376', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('JM', XJamaicaLbl, '388', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('JE', XJerseyLbl, '832', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('JO', XJordanLbl, '400', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KZ', XKazakhstanLbl, '398', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KI', XKiribatiLbl, '296', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KP', XNorthKoreaLbl, '408', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KR', XSouthKoreaLbl, '410', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KW', XKuwaitLbl, '414', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KG', XKyrgyzstanLbl, '417', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('LA', XLaosLbl, '418', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('LB', XLebanonLbl, '422', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('LS', XLesothoLbl, '426', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('LR', XLiberiaLbl, '430', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('LY', XLibyaLbl, '434', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('LI', XLiechtensteinLbl, '438', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MO', XMacaoLbl, '446', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MG', XMadagascarLbl, '450', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MW', XMalawiLbl, '454', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MV', XMaldivesLbl, '462', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('ML', XMaliLbl, '466', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MH', XMarshallIslandsLbl, '584', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MQ', XMartiniqueLbl, '474', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MR', XMauritaniaLbl, '478', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MU', XMauritiusLbl, '480', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('YT', XMayotteLbl, '175', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('FM', XMicronesiaLbl, '583', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MD', XMoldovaLbl, '498', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MC', XMonacoLbl, '492', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MN', XMongoliaLbl, '496', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MS', XMontserratLbl, '500', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MM', XMyanmarLbl, '104', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('NA', XNamibiaLbl, '516', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('NR', XNauruLbl, '520', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('NP', XNepalLbl, '524', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('NC', XNewCaledoniaLbl, '540', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('NE', XNigerLbl, '562', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('NU', XNiueLbl, '570', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('NF', XNorfolkIslandLbl, '574', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MK', XNorthMacedoniaLbl, '807', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MP', XNorthernMarianaLbl, '580', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('OM', XOmanLbl, '512', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PK', XPakistanLbl, '586', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PW', XPalauLbl, '585', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PS', XPalestineLbl, '275', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PA', XPanamaLbl, '591', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PG', XPapuaNewGuineaLbl, '598', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PY', XParaguayLbl, '600', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PE', XPeruLbl, '604', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PN', XPitcairnLbl, '612', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PR', XPuertoRicoLbl, '630', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('QA', XQatarLbl, '634', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('RW', XRwandaLbl, '646', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('RE', XReunionLbl, '638', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('BL', XSaintBarthelemyLbl, '652', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SH', XSaintHelenaLbl, '654', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('KN', XSaintKittsNevisLbl, '659', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('LC', XSaintLuciaLbl, '662', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('MF', XSaintMartinLbl, '663', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('PM', XSaintPierreQuelonLbl, '666', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('VC', XSaintVincentLbl, '670', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SM', XSanMarinoLbl, '674', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('ST', XSaoTomeLbl, '678', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SN', XSenegalLbl, '686', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SC', XSeychellesLbl, '690', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SL', XSierraLeoneLbl, '694', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SX', XSintMaartenLbl, '534', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SO', XSomaliaLbl, '706', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('GS', XSouthGeorgiaLbl, '239', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SS', XSouthSudanLbl, '728', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('LK', XSriLankaLbl, '144', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SD', XSudanLbl, '729', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SR', XSurinameLbl, '740', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SJ', XSvalbardJanMayenLbl, '744', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('SY', XSyriaLbl, '760', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TW', XTaiwanLbl, '158', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TJ', XTajikistanLbl, '762', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TL', XTimorLesteLbl, '626', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TG', XTogoLbl, '768', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TK', XTokelauLbl, '772', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TO', XTongaLbl, '776', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TT', XTrinidadTobagoLbl, '780', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TM', XTurkmenistanLbl, '795', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TC', XTurksCalcosLbl, '796', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('TV', XTuvaluLbl, '798', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('UA', XUkraineLbl, '804', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('UM', XUSMinorOutlyingLbl, '581', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('UY', XUruguayLbl, '858', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('UZ', XUzbekistanLbl, '860', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('VE', XVenezuelLbl, '862', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('VN', XVietnamLbl, '704', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('VG', XVirginIslandsBrLbl, '092', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('VI', XVirginIslandsUSLbl, '850', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('WF', XWallisatunaLbl, '876', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('EH', XWesternSaharaLbl, '732', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('YE', XYemenLbl, '887', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('ZM', XZambiaLbl, '894', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('ZW', XZimbabweLbl, '716', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
        ContosoCountryOrRegion.InsertCountryOrRegion('AX', XAlandIslandsLbl, '248', '', '', Enum::"Country/Region Address Format"::"City+Post Code", 0, '', '');
    end;

    procedure AE(): Code[10]
    begin
        exit(AETok);
    end;

    procedure AT(): Code[10]
    begin
        exit(ATTok);
    end;

    procedure AU(): Code[10]
    begin
        exit(AUTok);
    end;

    procedure BE(): Code[10]
    begin
        exit(BETok);
    end;

    procedure BG(): Code[10]
    begin
        exit(BGTok);
    end;

    procedure BN(): Code[10]
    begin
        exit(BNTok);
    end;

    procedure BR(): Code[10]
    begin
        exit(BRTok);
    end;

    procedure CA(): Code[10]
    begin
        exit(CATok);
    end;

    procedure CH(): Code[10]
    begin
        exit(CHTok);
    end;

    procedure CN(): Code[10]
    begin
        exit(CNTok);
    end;

    procedure CR(): Code[10]
    begin
        exit(CRTok);
    end;

    procedure CY(): Code[10]
    begin
        exit(CYTok);
    end;

    procedure CZ(): Code[10]
    begin
        exit(CZTok);
    end;

    procedure DE(): Code[10]
    begin
        exit(DETok);
    end;

    procedure DK(): Code[10]
    begin
        exit(DKTok);
    end;

    procedure DZ(): Code[10]
    begin
        exit(DZTok);
    end;

    procedure EE(): Code[10]
    begin
        exit(EETok);
    end;

    procedure EL(): Code[10]
    begin
        exit(ELTok);
    end;

    procedure ES(): Code[10]
    begin
        exit(ESTok);
    end;

    procedure FI(): Code[10]
    begin
        exit(FITok);
    end;

    procedure FJ(): Code[10]
    begin
        exit(FJTok);
    end;

    procedure FR(): Code[10]
    begin
        exit(FRTok);
    end;

    procedure GB(): Code[10]
    begin
        exit(GBTok);
    end;

    procedure HR(): Code[10]
    begin
        exit(HRTok);
    end;

    procedure HU(): Code[10]
    begin
        exit(HUTok);
    end;

    procedure ID(): Code[10]
    begin
        exit(IDTok);
    end;

    procedure IE(): Code[10]
    begin
        exit(IETok);
    end;

    procedure IND(): Code[10]
    begin
        exit(INTok);
    end;

    procedure IS(): Code[10]
    begin
        exit(ISTok);
    end;

    procedure IT(): Code[10]
    begin
        exit(ITTok);
    end;

    procedure JP(): Code[10]
    begin
        exit(JPTok);
    end;

    procedure KE(): Code[10]
    begin
        exit(KETok);
    end;

    procedure LT(): Code[10]
    begin
        exit(LTTok);
    end;

    procedure LU(): Code[10]
    begin
        exit(LUTok);
    end;

    procedure LV(): Code[10]
    begin
        exit(LVTok);
    end;

    procedure MA(): Code[10]
    begin
        exit(MATok);
    end;

    procedure ME(): Code[10]
    begin
        exit(METok);
    end;

    procedure MT(): Code[10]
    begin
        exit(MTTok);
    end;

    procedure MX(): Code[10]
    begin
        exit(MXTok);
    end;

    procedure MY(): Code[10]
    begin
        exit(MYTok);
    end;

    procedure MZ(): Code[10]
    begin
        exit(MZTok);
    end;

    procedure NG(): Code[10]
    begin
        exit(NGTok);
    end;

    procedure NI(): Code[10]
    begin
        exit(NITok);
    end;

    procedure NL(): Code[10]
    begin
        exit(NLTok);
    end;

    procedure NO(): Code[10]
    begin
        exit(NOTok);
    end;

    procedure NZ(): Code[10]
    begin
        exit(NZTok);
    end;

    procedure PH(): Code[10]
    begin
        exit(PHTok);
    end;

    procedure PL(): Code[10]
    begin
        exit(PLTok);
    end;

    procedure PT(): Code[10]
    begin
        exit(PTTok);
    end;

    procedure RO(): Code[10]
    begin
        exit(ROTok);
    end;

    procedure RS(): Code[10]
    begin
        exit(RSTok);
    end;

    procedure RU(): Code[10]
    begin
        exit(RUTok);
    end;

    procedure SA(): Code[10]
    begin
        exit(SATok);
    end;

    procedure SB(): Code[10]
    begin
        exit(SBTok);
    end;

    procedure SE(): Code[10]
    begin
        exit(SETok);
    end;

    procedure SG(): Code[10]
    begin
        exit(SGTok);
    end;

    procedure SI(): Code[10]
    begin
        exit(SITok);
    end;

    procedure SK(): Code[10]
    begin
        exit(SKTok);
    end;

    procedure SZ(): Code[10]
    begin
        exit(SZTok);
    end;

    procedure TH(): Code[10]
    begin
        exit(THTok);
    end;

    procedure TN(): Code[10]
    begin
        exit(TNTok);
    end;

    procedure TR(): Code[10]
    begin
        exit(TRTok);
    end;

    procedure TZ(): Code[10]
    begin
        exit(TZTok);
    end;

    procedure UG(): Code[10]
    begin
        exit(UGTok);
    end;

    procedure US(): Code[10]
    begin
        exit(USTok);
    end;

    procedure VU(): Code[10]
    begin
        exit(VUTok);
    end;

    procedure WS(): Code[10]
    begin
        exit(WSTok);
    end;

    procedure ZA(): Code[10]
    begin
        exit(ZATok);
    end;

    var
        AETok: Label 'AE', MaxLength = 10, Locked = true;
        ATTok: Label 'AT', MaxLength = 10, Locked = true;
        AUTok: Label 'AU', MaxLength = 10, Locked = true;
        BETok: Label 'BE', MaxLength = 10, Locked = true;
        BGTok: Label 'BG', MaxLength = 10, Locked = true;
        BNTok: Label 'BN', MaxLength = 10, Locked = true;
        BRTok: Label 'BR', MaxLength = 10, Locked = true;
        CATok: Label 'CA', MaxLength = 10, Locked = true;
        CHTok: Label 'CH', MaxLength = 10, Locked = true;
        CNTok: Label 'CN', MaxLength = 10, Locked = true;
        CRTok: Label 'CR', MaxLength = 10, Locked = true;
        CYTok: Label 'CY', MaxLength = 10, Locked = true;
        CZTok: Label 'CZ', MaxLength = 10, Locked = true;
        DETok: Label 'DE', MaxLength = 10, Locked = true;
        DKTok: Label 'DK', MaxLength = 10, Locked = true;
        DZTok: Label 'DZ', MaxLength = 10, Locked = true;
        EETok: Label 'EE', MaxLength = 10, Locked = true;
        ELTok: Label 'EL', MaxLength = 10, Locked = true;
        ESTok: Label 'ES', MaxLength = 10, Locked = true;
        FITok: Label 'FI', MaxLength = 10, Locked = true;
        FJTok: Label 'FJ', MaxLength = 10, Locked = true;
        FRTok: Label 'FR', MaxLength = 10, Locked = true;
        GBTok: Label 'GB', MaxLength = 10, Locked = true;
        HRTok: Label 'HR', MaxLength = 10, Locked = true;
        HUTok: Label 'HU', MaxLength = 10, Locked = true;
        IDTok: Label 'ID', MaxLength = 10, Locked = true;
        IETok: Label 'IE', MaxLength = 10, Locked = true;
        INTok: Label 'IN', MaxLength = 10, Locked = true;
        ISTok: Label 'IS', MaxLength = 10, Locked = true;
        ITTok: Label 'IT', MaxLength = 10, Locked = true;
        JPTok: Label 'JP', MaxLength = 10, Locked = true;
        KETok: Label 'KE', MaxLength = 10, Locked = true;
        LTTok: Label 'LT', MaxLength = 10, Locked = true;
        LUTok: Label 'LU', MaxLength = 10, Locked = true;
        LVTok: Label 'LV', MaxLength = 10, Locked = true;
        MATok: Label 'MA', MaxLength = 10, Locked = true;
        METok: Label 'ME', MaxLength = 10, Locked = true;
        MTTok: Label 'MT', MaxLength = 10, Locked = true;
        MXTok: Label 'MX', MaxLength = 10, Locked = true;
        MYTok: Label 'MY', MaxLength = 10, Locked = true;
        MZTok: Label 'MZ', MaxLength = 10, Locked = true;
        NGTok: Label 'NG', MaxLength = 10, Locked = true;
        NITok: Label 'NI', MaxLength = 10, Locked = true;
        NLTok: Label 'NL', MaxLength = 10, Locked = true;
        NOTok: Label 'NO', MaxLength = 10, Locked = true;
        NZTok: Label 'NZ', MaxLength = 10, Locked = true;
        PHTok: Label 'PH', MaxLength = 10, Locked = true;
        PLTok: Label 'PL', MaxLength = 10, Locked = true;
        PTTok: Label 'PT', MaxLength = 10, Locked = true;
        ROTok: Label 'RO', MaxLength = 10, Locked = true;
        RSTok: Label 'RS', MaxLength = 10, Locked = true;
        RUTok: Label 'RU', MaxLength = 10, Locked = true;
        SATok: Label 'SA', MaxLength = 10, Locked = true;
        SBTok: Label 'SB', MaxLength = 10, Locked = true;
        SETok: Label 'SE', MaxLength = 10, Locked = true;
        SGTok: Label 'SG', MaxLength = 10, Locked = true;
        SITok: Label 'SI', MaxLength = 10, Locked = true;
        SKTok: Label 'SK', MaxLength = 10, Locked = true;
        SZTok: Label 'SZ', MaxLength = 10, Locked = true;
        THTok: Label 'TH', MaxLength = 10, Locked = true;
        TNTok: Label 'TN', MaxLength = 10, Locked = true;
        TRTok: Label 'TR', MaxLength = 10, Locked = true;
        TZTok: Label 'TZ', MaxLength = 10, Locked = true;
        UGTok: Label 'UG', MaxLength = 10, Locked = true;
        USTok: Label 'US', MaxLength = 10, Locked = true;
        VUTok: Label 'VU', MaxLength = 10, Locked = true;
        WSTok: Label 'WS', MaxLength = 10, Locked = true;
        ZATok: Label 'ZA', MaxLength = 10, Locked = true;
        XITok: Label 'XI', MaxLength = 10, Locked = true;
        UnitedArabEmiratesLbl: Label 'United Arab Emirates', MaxLength = 50;
        AustriaLbl: Label 'Austria', MaxLength = 50;
        AustraliaLbl: Label 'Australia', MaxLength = 50;
        BelgiumLbl: Label 'Belgium', MaxLength = 50;
        BulgariaLbl: Label 'Bulgaria', MaxLength = 50;
        BruneiDarussalamLbl: Label 'Brunei Darussalam', MaxLength = 50;
        BrazilLbl: Label 'Brazil', MaxLength = 50;
        CanadaLbl: Label 'Canada', MaxLength = 50;
        SwitzerlandLbl: Label 'Switzerland', MaxLength = 50;
        ChinaLbl: Label 'China', MaxLength = 50;
        CostaRicaLbl: Label 'Costa Rica', MaxLength = 50;
        CyprusLbl: Label 'Cyprus', MaxLength = 50;
        CzechiaLbl: Label 'Czechia', MaxLength = 50;
        GermanyLbl: Label 'Germany', MaxLength = 50;
        DenmarkLbl: Label 'Denmark', MaxLength = 50;
        AlgeriaLbl: Label 'Algeria', MaxLength = 50;
        EstoniaLbl: Label 'Estonia', MaxLength = 50;
        GreeceLbl: Label 'Greece', MaxLength = 50;
        SpainLbl: Label 'Spain', MaxLength = 50;
        FinlandLbl: Label 'Finland', MaxLength = 50;
        FijiIslandsLbl: Label 'Fiji Islands', MaxLength = 50;
        FranceLbl: Label 'France', MaxLength = 50;
        GreatBritainLbl: Label 'Great Britain', MaxLength = 50;
        CroatiaLbl: Label 'Croatia', MaxLength = 50;
        HungaryLbl: Label 'Hungary', MaxLength = 50;
        IndonesiaLbl: Label 'Indonesia', MaxLength = 50;
        IrelandLbl: Label 'Ireland', MaxLength = 50;
        IndiaLbl: Label 'India', MaxLength = 50;
        IcelandLbl: Label 'Iceland', MaxLength = 50;
        ItalyLbl: Label 'Italy', MaxLength = 50;
        JapanLbl: Label 'Japan', MaxLength = 50;
        KenyaLbl: Label 'Kenya', MaxLength = 50;
        LithuaniaLbl: Label 'Lithuania', MaxLength = 50;
        LuxembourgLbl: Label 'Luxembourg', MaxLength = 50;
        LatviaLbl: Label 'Latvia', MaxLength = 50;
        MoroccoLbl: Label 'Morocco', MaxLength = 50;
        MontenegroLbl: Label 'Montenegro', MaxLength = 50;
        MaltaLbl: Label 'Malta', MaxLength = 50;
        MexicoLbl: Label 'Mexico', MaxLength = 50;
        MalaysiaLbl: Label 'Malaysia', MaxLength = 50;
        MozambiqueLbl: Label 'Mozambique', MaxLength = 50;
        NigeriaLbl: Label 'Nigeria', MaxLength = 50;
        NorthernIrelandLbl: Label 'Northern Ireland', MaxLength = 50;
        NetherlandsLbl: Label 'Netherlands', MaxLength = 50;
        NorwayLbl: Label 'Norway', MaxLength = 50;
        NewZealandLbl: Label 'New Zealand', MaxLength = 50;
        PhilippinesLbl: Label 'Philippines', MaxLength = 50;
        PolandLbl: Label 'Poland', MaxLength = 50;
        PortugalLbl: Label 'Portugal', MaxLength = 50;
        RomaniaLbl: Label 'Romania', MaxLength = 50;
        SerbiaLbl: Label 'Serbia', MaxLength = 50;
        RussiaLbl: Label 'Russia', MaxLength = 50;
        SaudiArabiaLbl: Label 'Saudi Arabia', MaxLength = 50;
        SolomonIslandsLbl: Label 'Solomon Islands', MaxLength = 50;
        SwedenLbl: Label 'Sweden', MaxLength = 50;
        SingaporeLbl: Label 'Singapore', MaxLength = 50;
        SloveniaLbl: Label 'Slovenia', MaxLength = 50;
        SlovakiaLbl: Label 'Slovakia', MaxLength = 50;
        SwazilandLbl: Label 'Swaziland', MaxLength = 50;
        ThailandLbl: Label 'Thailand', MaxLength = 50;
        TunisiaLbl: Label 'Tunisia', MaxLength = 50;
        TürkiyeLbl: Label 'Türkiye', MaxLength = 50;
        TanzaniaLbl: Label 'Tanzania', MaxLength = 50;
        UgandaLbl: Label 'Uganda', MaxLength = 50;
        USALbl: Label 'USA', MaxLength = 50;
        VanuatuLbl: Label 'Vanuatu', MaxLength = 50;
        SamoaLbl: Label 'Samoa', MaxLength = 50;
        SouthAfricaLbl: Label 'South Africa', MaxLength = 50;
        XAfghanistanLbl: Label 'Afghanistan', MaxLength = 50;
        XAlandIslandsLbl: Label 'Aland Islands', MaxLength = 50;
        XAlbaniaLbl: Label 'Albania', MaxLength = 50;
        XAndorraLbl: Label 'Andorra', MaxLength = 50;
        XAngolaLbl: Label 'Angola', MaxLength = 50;
        XAnguillaLbl: Label 'Anguilla', MaxLength = 50;
        XAntarcticaLbl: Label 'Antarctica', MaxLength = 50;
        XAntiguaBarbudaLbl: Label 'Antigua & Barbuda', MaxLength = 50;
        XArgentinaLbl: Label 'Argentina', MaxLength = 50;
        XArmeniaLbl: Label 'Armenia', MaxLength = 50;
        XArubaLbl: Label 'Aruba', MaxLength = 50;
        XAzerbaijanLbl: Label 'Azerbaijan', MaxLength = 50;
        XBahamasLbl: Label 'Bahamas', MaxLength = 50;
        XBahrainLbl: Label 'Bahrain', MaxLength = 50;
        XBangladeshLbl: Label 'Bangladesh', MaxLength = 50;
        XBarbadosLbl: Label 'Barbados', MaxLength = 50;
        XBelarusLbl: Label 'Belarus', MaxLength = 50;
        XBelizeLbl: Label 'Belize', MaxLength = 50;
        XBeninLbl: Label 'Benin', MaxLength = 50;
        XBermudaLbl: Label 'Bermuda', MaxLength = 50;
        XBhutanLbl: Label 'Bhutan', MaxLength = 50;
        XBoliviaLbl: Label 'Bolivia', MaxLength = 50;
        XBonaireLbl: Label 'Bonaire, Sint Eustatius and Saba', MaxLength = 50;
        XBosniaHerzegovinaLbl: Label 'Bosnia & Herzegovina', MaxLength = 50;
        XBotswanaLbl: Label 'Botswana', MaxLength = 50;
        XBouvetIslandLbl: Label 'Bouvet Island', MaxLength = 50;
        XBritishIndianOceanLbl: Label 'British Indian Ocean Territory', MaxLength = 50;
        XBurkinaFasoLbl: Label 'Burkina Faso', MaxLength = 50;
        XBurundiLbl: Label 'Burundi', MaxLength = 50;
        XCaboVerdeLbl: Label 'Cabo Verde', MaxLength = 50;
        XCambodiaLbl: Label 'Cambodia', MaxLength = 50;
        XCameroonLbl: Label 'Cameroon', MaxLength = 50;
        XCaymanIslandsLbl: Label 'Cayman Islands', MaxLength = 50;
        XCentralAfricanLbl: Label 'Central African Republic', MaxLength = 50;
        XChadLbl: Label 'Chad', MaxLength = 50;
        XChileLbl: Label 'Chile', MaxLength = 50;
        XChristmasIslandLbl: Label 'Christmas Island', MaxLength = 50;
        XCocosIslandsLbl: Label 'Cocos (Keeling) Islands', MaxLength = 50;
        XColombiaLbl: Label 'Colombia', MaxLength = 50;
        XComorosLbl: Label 'Comoros', MaxLength = 50;
        XCongoDRLbl: Label 'Congo, Democratic Republic', MaxLength = 50;
        XCongoLbl: Label 'Congo', MaxLength = 50;
        XCookIslandsLbl: Label 'Cook Islands', MaxLength = 50;
        XCotedIvoireLbl: Label 'Cote d''Ivoire', MaxLength = 50;
        XCubaLbl: Label 'Cuba', MaxLength = 50;
        XCuracaoLbl: Label 'Curacao', MaxLength = 50;
        XDjiboutiLbl: Label 'Djibouti', MaxLength = 50;
        XDominicaLbl: Label 'Dominica', MaxLength = 50;
        XDominicanLbl: Label 'Dominican Republic', MaxLength = 50;
        XEcuadorLbl: Label 'Ecuador', MaxLength = 50;
        XEgyptLbl: Label 'Egypt', MaxLength = 50;
        XElSalvadorLbl: Label 'El Salvador', MaxLength = 50;
        XEquatorialGuineaLbl: Label 'Equatorial Guinea', MaxLength = 50;
        XEritreaLbl: Label 'Eritrea', MaxLength = 50;
        XEthiopiaLbl: Label 'Ethiopia', MaxLength = 50;
        XFalklandIslandsLbl: Label 'Falkland Islands', MaxLength = 50;
        XFaroeIslandsLbl: Label 'Faroe Islands', MaxLength = 50;
        XFrenchGuianaLbl: Label 'French Guiana', MaxLength = 50;
        XFrenchPolynesiaLbl: Label 'French Polynesia', MaxLength = 50;
        XFrenchSouthernLbl: Label 'French Southern Territories', MaxLength = 50;
        XGabonLbl: Label 'Gabon', MaxLength = 50;
        XGambiaLbl: Label 'Gambia', MaxLength = 50;
        XGeorgiaLbl: Label 'Georgia', MaxLength = 50;
        XGhanaLbl: Label 'Ghana', MaxLength = 50;
        XGibraltarLbl: Label 'Gibraltar', MaxLength = 50;
        XGreenlandLbl: Label 'Greenland', MaxLength = 50;
        XGrenadaLbl: Label 'Grenada', MaxLength = 50;
        XGuadeloupeLbl: Label 'Guadeloupe', MaxLength = 50;
        XGuamLbl: Label 'Guam', MaxLength = 50;
        XGuatemalaLbl: Label 'Guatemala', MaxLength = 50;
        XGuernseyLbl: Label 'Guernsey', MaxLength = 50;
        XGuineaBissauLbl: Label 'Guinea-Bissau', MaxLength = 50;
        XGuineaLbl: Label 'Guinea', MaxLength = 50;
        XGuyanaLbl: Label 'Guyana', MaxLength = 50;
        XHaitiLbl: Label 'Haiti', MaxLength = 50;
        XHeardIslandLbl: Label 'Heard Island and McDonald Islands', MaxLength = 50;
        XHolySeeLbl: Label 'Vatican City', MaxLength = 50;
        XHondurasLbl: Label 'Honduras', MaxLength = 50;
        XHongKongLbl: Label 'Hong Kong SAR', MaxLength = 50;
        XIsleManLbl: Label 'Isle of Man', MaxLength = 50;
        XIsraelLbl: Label 'Israel', MaxLength = 50;
        XJamaicaLbl: Label 'Jamaica', MaxLength = 50;
        XJerseyLbl: Label 'Jersey', MaxLength = 50;
        XJordanLbl: Label 'Jordan', MaxLength = 50;
        XKazakhstanLbl: Label 'Kazakhstan', MaxLength = 50;
        XKiribatiLbl: Label 'Kiribati', MaxLength = 50;
        XKuwaitLbl: Label 'Kuwait', MaxLength = 50;
        XKyrgyzstanLbl: Label 'Kyrgyzstan', MaxLength = 50;
        XLaosLbl: Label 'Laos', MaxLength = 50;
        XLebanonLbl: Label 'Lebanon', MaxLength = 50;
        XLesothoLbl: Label 'Lesotho', MaxLength = 50;
        XLiberiaLbl: Label 'Liberia', MaxLength = 50;
        XLibyaLbl: Label 'Libya', MaxLength = 50;
        XLiechtensteinLbl: Label 'Liechtenstein', MaxLength = 50;
        XMacaoLbl: Label 'Macao', MaxLength = 50;
        XMadagascarLbl: Label 'Madagascar', MaxLength = 50;
        XMalawiLbl: Label 'Malawi', MaxLength = 50;
        XMaldivesLbl: Label 'Maldives', MaxLength = 50;
        XMaliLbl: Label 'Mali', MaxLength = 50;
        XMarshallIslandsLbl: Label 'Marshall Islands', MaxLength = 50;
        XMartiniqueLbl: Label 'Martinique', MaxLength = 50;
        XMauritaniaLbl: Label 'Mauritania', MaxLength = 50;
        XMauritiusLbl: Label 'Mauritius', MaxLength = 50;
        XMayotteLbl: Label 'Mayotte', MaxLength = 50;
        XMicronesiaLbl: Label 'Micronesia', MaxLength = 50;
        XMoldovaLbl: Label 'Moldova', MaxLength = 50;
        XMonacoLbl: Label 'Monaco', MaxLength = 50;
        XMongoliaLbl: Label 'Mongolia', MaxLength = 50;
        XMontserratLbl: Label 'Montserrat', MaxLength = 50;
        XMyanmarLbl: Label 'Myanmar', MaxLength = 50;
        XNamibiaLbl: Label 'Namibia', MaxLength = 50;
        XNauruLbl: Label 'Nauru', MaxLength = 50;
        XNepalLbl: Label 'Nepal', MaxLength = 50;
        XNewCaledoniaLbl: Label 'New Caledonia', MaxLength = 50;
        XNigerLbl: Label 'Niger', MaxLength = 50;
        XNiueLbl: Label 'Niue', MaxLength = 50;
        XNorfolkIslandLbl: Label 'Norfolk Island', MaxLength = 50;
        XNorthernMarianaLbl: Label 'Northern Mariana Islands', MaxLength = 50;
        XNorthKoreaLbl: Label 'North Korea', MaxLength = 50;
        XNorthMacedoniaLbl: Label 'North Macedonia', MaxLength = 50;
        XOmanLbl: Label 'Oman', MaxLength = 50;
        XPakistanLbl: Label 'Pakistan', MaxLength = 50;
        XPalauLbl: Label 'Palau', MaxLength = 50;
        XPalestineLbl: Label 'Palestine', MaxLength = 50;
        XPanamaLbl: Label 'Panama', MaxLength = 50;
        XPapuaNewGuineaLbl: Label 'Papua New Guinea', MaxLength = 50;
        XParaguayLbl: Label 'Paraguay', MaxLength = 50;
        XPeruLbl: Label 'Peru', MaxLength = 50;
        XPitcairnLbl: Label 'Pitcairn Islands', MaxLength = 50;
        XPuertoRicoLbl: Label 'Puerto Rico', MaxLength = 50;
        XQatarLbl: Label 'Qatar', MaxLength = 50;
        XReunionLbl: Label 'Reunion', MaxLength = 50;
        XRwandaLbl: Label 'Rwanda', MaxLength = 50;
        XSaintBarthelemyLbl: Label 'Saint Barthelemy', MaxLength = 50;
        XSaintHelenaLbl: Label 'St Helena, Ascension, Tristan da Cunha', MaxLength = 50;
        XSaintKittsNevisLbl: Label 'St. Kitts & Nevis', MaxLength = 50;
        XSaintLuciaLbl: Label 'St. Lucia', MaxLength = 50;
        XSaintMartinLbl: Label 'Saint Martin', MaxLength = 50;
        XSaintPierreQuelonLbl: Label 'St. Pierre & Miquelon', MaxLength = 50;
        XSaintVincentLbl: Label 'St. Vincent & Grenadines', MaxLength = 50;
        XSanMarinoLbl: Label 'San Marino', MaxLength = 50;
        XSaoTomeLbl: Label 'Sao Tome & Principe', MaxLength = 50;
        XSenegalLbl: Label 'Senegal', MaxLength = 50;
        XSeychellesLbl: Label 'Seychelles', MaxLength = 50;
        XSierraLeoneLbl: Label 'Sierra Leone', MaxLength = 50;
        XSintMaartenLbl: Label 'Sint Maarten', MaxLength = 50;
        XSomaliaLbl: Label 'Somalia', MaxLength = 50;
        XSouthGeorgiaLbl: Label 'South Georgia and South Sandwich Islands', MaxLength = 50;
        XSouthKoreaLbl: Label 'Korea', MaxLength = 50;
        XSouthSudanLbl: Label 'South Sudan', MaxLength = 50;
        XSriLankaLbl: Label 'Sri Lanka', MaxLength = 50;
        XSudanLbl: Label 'Sudan', MaxLength = 50;
        XSurinameLbl: Label 'Suriname', MaxLength = 50;
        XSvalbardJanMayenLbl: Label 'Svalbard & Jan Mayen', MaxLength = 50;
        XSyriaLbl: Label 'Syria', MaxLength = 50;
        XTaiwanLbl: Label 'Taiwan', MaxLength = 50;
        XTajikistanLbl: Label 'Tajikistan', MaxLength = 50;
        XTimorLesteLbl: Label 'Timor-Leste', MaxLength = 50;
        XTogoLbl: Label 'Togo', MaxLength = 50;
        XTokelauLbl: Label 'Tokelau', MaxLength = 50;
        XTongaLbl: Label 'Tonga', MaxLength = 50;
        XTrinidadTobagoLbl: Label 'Trinidad & Tobago', MaxLength = 50;
        XTurkmenistanLbl: Label 'Turkmenistan', MaxLength = 50;
        XTurksCalcosLbl: Label 'Turks & Caicos Islands', MaxLength = 50;
        XTuvaluLbl: Label 'Tuvalu', MaxLength = 50;
        XUkraineLbl: Label 'Ukraine', MaxLength = 50;
        XUruguayLbl: Label 'Uruguay', MaxLength = 50;
        XUSMinorOutlyingLbl: Label 'U.S. Minor Outlying Islands', MaxLength = 50;
        XUzbekistanLbl: Label 'Uzbekistan', MaxLength = 50;
        XVenezuelLbl: Label 'Venezuela', MaxLength = 50;
        XVietnamLbl: Label 'Vietnam', MaxLength = 50;
        XVirginIslandsBrLbl: Label 'British Virgin Islands', MaxLength = 50;
        XVirginIslandsUSLbl: Label 'U.S. Virgin Islands', MaxLength = 50;
        XWallisatunaLbl: Label 'Wallis & Futuna', MaxLength = 50;
        XWesternSaharaLbl: Label 'Western Sahara', MaxLength = 50;
        XYemenLbl: Label 'Yemen', MaxLength = 50;
        XZambiaLbl: Label 'Zambia', MaxLength = 50;
        XZimbabweLbl: Label 'Zimbabwe', MaxLength = 50;

}
