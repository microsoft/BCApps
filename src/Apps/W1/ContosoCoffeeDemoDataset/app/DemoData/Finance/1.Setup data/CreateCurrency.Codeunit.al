// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Finance;

using Microsoft.DemoTool;
using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.Currency;

codeunit 5525 "Create Currency"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        Currency: Record "Currency";
        CreateGLAccount: Codeunit "Create G/L Account";
        ContosoCurrency: Codeunit "Contoso Currency";
    begin
        ContosoCoffeeDemoDataSetup.Get();

        ContosoCurrency.InsertCurrency(AED(), '784', UnitedArabEmiratesdirhamLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.25, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'AU' then
            ContosoCurrency.InsertCurrency(AUD(), '036', AustralianDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(BGN(), '975', BulgarianLevaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(BND(), '096', BruneiDarussalemDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(BRL(), '986', BrazilianRealLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'CA' then
            ContosoCurrency.InsertCurrency(CAD(), '124', CanadianDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'CH' then
            ContosoCurrency.InsertCurrency(CHF(), '756', SwissFrancLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'CZ' then
            ContosoCurrency.InsertCurrency(CZK(), '203', CzechKorunaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'DK' then
            ContosoCurrency.InsertCurrency(DKK(), '208', DanishkroneLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(DZD(), '012', AlgerianDinarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if not (ContosoCoffeeDemoDataSetup."Country/Region Code" in ['AT', 'BE', 'DE', 'ES', 'FI', 'FR', 'IT', 'NL']) then
            ContosoCurrency.InsertCurrency(EUR(), '978', EuroLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, true, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(FJD(), '242', FijiDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if not (ContosoCoffeeDemoDataSetup."Country/Region Code" in ['GB', 'W1']) then
            ContosoCurrency.InsertCurrency(GBP(), '826', BritishPoundLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(HKD(), '344', HongKongDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(HRK(), '191', CroatianKunaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(HUF(), '348', HungarianForintLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(IDR(), '360', IndonesianRupiahLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 0.1, false, '0:0', '0:3');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'IN' then
            ContosoCurrency.InsertCurrency(INR(), '356', IndianRupeeLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'IS' then
            ContosoCurrency.InsertCurrency(ISK(), '352', IcelandicKronaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(JPY(), '392', JapaneseYenLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(KES(), '404', KenyanShillingLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.5, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(MAD(), '504', MoroccanDirhamLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'MX' then
            ContosoCurrency.InsertCurrency(MXN(), '484', MexicanPesoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(MYR(), '458', MalaysianRinggitLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(MZN(), '943', MozambiqueMeticalLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 10, Currency."Invoice Rounding Type"::Nearest, 1, 0.01, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency(NGN(), '566', NigerianNairaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'NO' then
            ContosoCurrency.InsertCurrency(NOK(), '578', NorwegianKroneLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'NZ' then
            ContosoCurrency.InsertCurrency(NZD(), '554', NewZealandDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(PHP(), '608', PhilippinesPesoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(PLN(), '985', PolishZlotyLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(RON(), '946', RomanianLeuLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.01, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(RSD(), '941', SerbianDinarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(RUB(), '643', RussianRubleLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(SAR(), '682', SaudiArabianRyialLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(SBD(), '090', SolomonIslandsDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'SE' then
            ContosoCurrency.InsertCurrency(SEK(), '752', SwedishKronaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(SGD(), '702', SingaporeDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(SZL(), '748', SwazilandLilangeniLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(THB(), '764', ThaiBahtLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency(TND(), '788', TunesianDinarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.001, 0.001, false, '3:3', '2:5');
        ContosoCurrency.InsertCurrency(TOP(), '776', TonganPaangaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(TRY(), '949', NewTurkishLiraLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(UGX(), '800', UgandanShillingLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 0.1, false, '0:0', '0:3');
        if ContosoCoffeeDemoDataSetup."Country/Region Code" <> 'US' then
            ContosoCurrency.InsertCurrency(USD(), '840', USDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(VUV(), '548', VanuatuVatuLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(WST(), '882', WesternSamoanTalaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(XPF(), '953', FrenchPacificFrancLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency(ZAR(), '710', SouthAfricanRandLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('AFN', '971', AfghaniLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('ALL', '008', LekLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('AMD', '051', ArmenianDramLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('AOA', '973', KwanzaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('ARS', '032', ArgentinePesoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('AWG', '533', ArubanFlorinLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('AZN', '944', AzerbaijanManatLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BAM', '977', ConvertibleMarkLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BBD', '052', BarbadosDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BDT', '050', TakaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BHD', '048', BahrainiDinarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.001, Currency."Invoice Rounding Type"::Nearest, 0.001, 0.0001, false, '3:3', '3:6');
        ContosoCurrency.InsertCurrency('BIF', '108', BurundiFrancLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('BMD', '060', BermudianDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BOB', '068', BolivianoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BOV', '984', MvdolLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BSD', '044', BahamianDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BTN', '064', NgultrumLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BWP', '072', PulaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BYN', '933', BelarusianRubleLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('BZD', '084', BelizeDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('CDF', '976', CongoleseFrancLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('CLF', '990', UnidadDeFomentoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.0001, Currency."Invoice Rounding Type"::Nearest, 0.0001, 0.00001, false, '4:4', '4:7');
        ContosoCurrency.InsertCurrency('CLP', '152', ChileanPesoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('CNY', '156', YuanRenminbiLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('COP', '170', ColombianPesoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('CRC', '188', CostaRicanColonLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('CUP', '192', CubanPesoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('CVE', '132', CaboVerdeEscudoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('DJF', '262', DjiboutiFrancLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('DOP', '214', DominicanPesoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('EGP', '818', EgyptianPoundLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('ERN', '232', NakfaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('ETB', '230', EthiopianBirrLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('FKP', '238', FalklandIslandsPoundLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('GEL', '981', LariLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('GHS', '936', GhanaCediLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('GIP', '292', GibraltarPoundLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('GMD', '270', DalasiLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('GNF', '324', GuineanFrancLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('GTQ', '320', QuetzalLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('GYD', '328', GuyanaDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('HNL', '340', LempiraLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('HTG', '332', GourdeLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('ILS', '376', NewIsraeliSheqelLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('IQD', '368', IraqiDinarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.001, Currency."Invoice Rounding Type"::Nearest, 0.001, 0.0001, false, '3:3', '3:6');
        ContosoCurrency.InsertCurrency('IRR', '364', IranianRialLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('JMD', '388', JamaicanDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('JOD', '400', JordanianDinarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.001, Currency."Invoice Rounding Type"::Nearest, 0.001, 0.0001, false, '3:3', '3:6');
        ContosoCurrency.InsertCurrency('KGS', '417', SomLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('KHR', '116', RielLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('KMF', '174', ComorianFrancLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('KPW', '408', NorthKoreanWonLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('KRW', '410', WonLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('KWD', '414', KuwaitiDinarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.001, Currency."Invoice Rounding Type"::Nearest, 0.001, 0.0001, false, '3:3', '3:6');
        ContosoCurrency.InsertCurrency('KYD', '136', CaymanIslandsDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('KZT', '398', TengeLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('LAK', '418', LaoKipLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('LBP', '422', LebanesePoundLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('LKR', '144', SriLankaRupeeLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('LRD', '430', LiberianDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('LSL', '426', LotiLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('LYD', '434', LibyanDinarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.001, Currency."Invoice Rounding Type"::Nearest, 0.001, 0.0001, false, '3:3', '3:6');
        ContosoCurrency.InsertCurrency('MDL', '498', MoldovanLeuLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('MGA', '969', MalagasyAriaryLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('MKD', '807', DenarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('MMK', '104', KyatLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('MNT', '496', TugrikLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('MOP', '446', PatacaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('MRU', '929', OuguiyaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('MUR', '480', MauritiusRupeeLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('MVR', '462', RufiyaaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('MWK', '454', MalawiKwachaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('NAD', '516', NamibiaDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('NIO', '558', CordobaOroLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('NPR', '524', NepaleseRupeeLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('OMR', '512', RialOmaniLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.001, Currency."Invoice Rounding Type"::Nearest, 0.001, 0.0001, false, '3:3', '3:6');
        ContosoCurrency.InsertCurrency('PAB', '590', BalboaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('PEN', '604', SolLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('PGK', '598', KinaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('PKR', '586', PakistanRupeeLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('PYG', '600', GuaraniLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('QAR', '634', QatariRialLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('RWF', '646', RwandaFrancLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('SCR', '690', SeychellesRupeeLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('SDG', '938', SudanesePoundLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('SHP', '654', SaintHelenaPoundLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('SLE', '925', LeoneLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('SOS', '706', SomaliShillingLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('SRD', '968', SurinamDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('SSP', '728', SouthSudanesePoundLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('STN', '930', DobraLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('SVC', '222', ElSalvadorColonLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('SYP', '760', SyrianPoundLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('TJS', '972', SomoniLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('TMT', '934', TurkmenistanNewManatLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('TTD', '780', TrinidadAndTobagoDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('TWD', '901', NewTaiwanDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('TZS', '834', TanzanianShillingLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('UAH', '980', HryvniaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('UYI', '940', UruguayPesoEnUnidadesIndexadasUiLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('UYU', '858', PesoUruguayoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('UYW', '927', UnidadPrevisionalLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.0001, Currency."Invoice Rounding Type"::Nearest, 0.0001, 0.00001, false, '4:4', '4:7');
        ContosoCurrency.InsertCurrency('UZS', '860', UzbekistanSumLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('VED', '926', BolivarSoberanoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('VES', '928', BolivarSoberanoVesLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('VND', '704', DongLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('XAD', '396', ArabAccountingDinarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('XAF', '950', CfaFrancBeacLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('XCD', '951', EastCaribbeanDollarLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('XCG', '532', CaribbeanGuilderLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('XOF', '952', CfaFrancBceaoLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 1, Currency."Invoice Rounding Type"::Nearest, 1, 1, false, '0:0', '0:3');
        ContosoCurrency.InsertCurrency('YER', '886', YemeniRialLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('ZMW', '967', ZambianKwachaLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
        ContosoCurrency.InsertCurrency('ZWG', '924', ZimbabweGoldLbl, CreateGLAccount.UnrealizedFXGains(), CreateGLAccount.RealizedFXGains(), CreateGLAccount.UnrealizedFXLosses(), CreateGLAccount.RealizedFXLosses(), 0.01, Currency."Invoice Rounding Type"::Nearest, 0.01, 0.001, false, '2:2', '2:5');
    end;

    procedure AED(): Code[10]
    begin
        exit('AED');
    end;

    procedure AUD(): Code[10]
    begin
        exit('AUD');
    end;

    procedure BGN(): Code[10]
    begin
        exit('BGN');
    end;

    procedure BND(): Code[10]
    begin
        exit('BND');
    end;

    procedure BRL(): Code[10]
    begin
        exit('BRL');
    end;

    procedure CAD(): Code[10]
    begin
        exit('CAD');
    end;

    procedure CHF(): Code[10]
    begin
        exit('CHF');
    end;

    procedure CZK(): Code[10]
    begin
        exit('CZK');
    end;

    procedure DKK(): Code[10]
    begin
        exit('DKK');
    end;

    procedure DZD(): Code[10]
    begin
        exit('DZD');
    end;

    procedure EUR(): Code[10]
    begin
        exit('EUR');
    end;

    procedure FJD(): Code[10]
    begin
        exit('FJD');
    end;

    procedure GBP(): Code[10]
    begin
        exit('GBP');
    end;

    procedure HKD(): Code[10]
    begin
        exit('HKD');
    end;

    procedure HRK(): Code[10]
    begin
        exit('HRK');
    end;

    procedure HUF(): Code[10]
    begin
        exit('HUF');
    end;

    procedure IDR(): Code[10]
    begin
        exit('IDR');
    end;

    procedure INR(): Code[10]
    begin
        exit('INR');
    end;

    procedure ISK(): Code[10]
    begin
        exit('ISK');
    end;

    procedure JPY(): Code[10]
    begin
        exit('JPY');
    end;

    procedure KES(): Code[10]
    begin
        exit('KES');
    end;

    procedure MAD(): Code[10]
    begin
        exit('MAD');
    end;

    procedure MXN(): Code[10]
    begin
        exit('MXN');
    end;

    procedure MYR(): Code[10]
    begin
        exit('MYR');
    end;

    procedure MZN(): Code[10]
    begin
        exit('MZN');
    end;

    procedure NGN(): Code[10]
    begin
        exit('NGN');
    end;

    procedure NOK(): Code[10]
    begin
        exit('NOK');
    end;

    procedure NZD(): Code[10]
    begin
        exit('NZD');
    end;

    procedure PHP(): Code[10]
    begin
        exit('PHP');
    end;

    procedure PLN(): Code[10]
    begin
        exit('PLN');
    end;

    procedure RON(): Code[10]
    begin
        exit('RON');
    end;

    procedure RSD(): Code[10]
    begin
        exit('RSD');
    end;

    procedure RUB(): Code[10]
    begin
        exit('RUB');
    end;

    procedure SAR(): Code[10]
    begin
        exit('SAR');
    end;

    procedure SBD(): Code[10]
    begin
        exit('SBD');
    end;

    procedure SEK(): Code[10]
    begin
        exit('SEK');
    end;

    procedure SGD(): Code[10]
    begin
        exit('SGD');
    end;

    procedure SZL(): Code[10]
    begin
        exit('SZL');
    end;

    procedure THB(): Code[10]
    begin
        exit('THB');
    end;

    procedure TND(): Code[10]
    begin
        exit('TND');
    end;

    procedure TOP(): Code[10]
    begin
        exit('TOP');
    end;

    procedure TRY(): Code[10]
    begin
        exit('TRY');
    end;

    procedure UGX(): Code[10]
    begin
        exit('UGX');
    end;

    procedure USD(): Code[10]
    begin
        exit('USD');
    end;

    procedure VUV(): Code[10]
    begin
        exit('VUV');
    end;

    procedure WST(): Code[10]
    begin
        exit('WST');
    end;

    procedure XPF(): Code[10]
    begin
        exit('XPF');
    end;

    procedure ZAR(): Code[10]
    begin
        exit('ZAR');
    end;

    var
        EuroLbl: Label 'Euro', MaxLength = 30;
        AustraliandollarLbl: Label 'Australian dollar', MaxLength = 30;
        BulgarianlevaLbl: Label 'Bulgarian leva', MaxLength = 30;
        BruneiDarussalemdollarLbl: Label 'Brunei Darussalem dollar', MaxLength = 30;
        BrazilianrealLbl: Label 'Brazilian real', MaxLength = 30;
        CanadiandollarLbl: Label 'Canadian dollar', MaxLength = 30;
        CroatianKunaLbl: Label 'Croatian Kuna', MaxLength = 30;
        SwissfrancLbl: Label 'Swiss franc', MaxLength = 30;
        CzechkorunaLbl: Label 'Czech koruna', MaxLength = 30;
        DanishkroneLbl: Label 'Danish krone', MaxLength = 30;
        FijidollarLbl: Label 'Fiji dollar', MaxLength = 30;
        BritishpoundLbl: Label 'Pound Sterling', MaxLength = 30;
        HongKongdollarLbl: Label 'Hong Kong dollar', MaxLength = 30;
        IndonesianrupiahLbl: Label 'Indonesian rupiah', MaxLength = 30;
        JapaneseyenLbl: Label 'Japanese yen', MaxLength = 30;
        IndianrupeeLbl: Label 'Indian rupee', MaxLength = 30;
        IcelandickronaLbl: Label 'Icelandic krona', MaxLength = 30;
        MalaysianringgitLbl: Label 'Malaysian ringgit', MaxLength = 30;
        MexicanpesoLbl: Label 'Mexican peso', MaxLength = 30;
        NorwegiankroneLbl: Label 'Norwegian krone', MaxLength = 30;
        NewZealanddollarLbl: Label 'New Zealand dollar', MaxLength = 30;
        PhilippinespesoLbl: Label 'Philippines peso', MaxLength = 30;
        PolishzlotyLbl: Label 'Polish zloty', MaxLength = 30;
        RussianrubleLbl: Label 'Russian ruble', MaxLength = 30;
        SwedishkronaLbl: Label 'Swedish krona', MaxLength = 30;
        SingaporedollarLbl: Label 'Singapore dollar', MaxLength = 30;
        SaudiArabianryialLbl: Label 'Saudi Arabian ryial', MaxLength = 30;
        SolomonIslandsdollarLbl: Label 'Solomon Islands dollar', MaxLength = 30;
        ThaibahtLbl: Label 'Thai baht', MaxLength = 30;
        USdollarLbl: Label 'US dollar', MaxLength = 30;
        VanuatuvatuLbl: Label 'Vanuatu vatu', MaxLength = 30;
        WesternSamoantalaLbl: Label 'Western Samoan tala', MaxLength = 30;
        SouthAfricanrandLbl: Label 'South African rand', MaxLength = 30;
        UnitedArabEmiratesdirhamLbl: Label 'United Arab Emirates dirham', MaxLength = 30;
        AlgeriandinarLbl: Label 'Algerian dinar', MaxLength = 30;
        HungarianforintLbl: Label 'Hungarian forint', MaxLength = 30;
        KenyanShillingLbl: Label 'Kenyan Shilling', MaxLength = 30;
        MoroccandirhamLbl: Label 'Moroccan dirham', MaxLength = 30;
        MozambiquemeticalLbl: Label 'Mozambique metical', MaxLength = 30;
        NigeriannairaLbl: Label 'Nigerian naira', MaxLength = 30;
        RomanianleuLbl: Label 'Romanian leu', MaxLength = 30;
        SwazilandlilangeniLbl: Label 'Swaziland lilangeni', MaxLength = 30;
        SerbianDinarLbl: Label 'Serbian Dinar', MaxLength = 30;
        TunesiandinarLbl: Label 'Tunesian dinar', MaxLength = 30;
        UgandanShillingLbl: Label 'Ugandan Shilling', MaxLength = 30;
        NewTurkishliraLbl: Label 'New Turkish lira', MaxLength = 30;
        TonganPaangaLbl: Label 'Tongan Pa anga', MaxLength = 30;
        FrenchPacificFrancLbl: Label 'French Pacific Franc', MaxLength = 30;
        AfghaniLbl: Label 'Afghani', MaxLength = 30;
        LekLbl: Label 'Lek', MaxLength = 30;
        ArmenianDramLbl: Label 'Armenian Dram', MaxLength = 30;
        KwanzaLbl: Label 'Kwanza', MaxLength = 30;
        ArgentinePesoLbl: Label 'Argentine Peso', MaxLength = 30;
        ArubanFlorinLbl: Label 'Aruban Florin', MaxLength = 30;
        AzerbaijanManatLbl: Label 'Azerbaijan Manat', MaxLength = 30;
        ConvertibleMarkLbl: Label 'Convertible Mark', MaxLength = 30;
        BarbadosDollarLbl: Label 'Barbados Dollar', MaxLength = 30;
        TakaLbl: Label 'Taka', MaxLength = 30;
        BahrainiDinarLbl: Label 'Bahraini Dinar', MaxLength = 30;
        BurundiFrancLbl: Label 'Burundi Franc', MaxLength = 30;
        BermudianDollarLbl: Label 'Bermudian Dollar', MaxLength = 30;
        BolivianoLbl: Label 'Boliviano', MaxLength = 30;
        MvdolLbl: Label 'Mvdol', MaxLength = 30;
        BahamianDollarLbl: Label 'Bahamian Dollar', MaxLength = 30;
        NgultrumLbl: Label 'Ngultrum', MaxLength = 30;
        PulaLbl: Label 'Pula', MaxLength = 30;
        BelarusianRubleLbl: Label 'Belarusian Ruble', MaxLength = 30;
        BelizeDollarLbl: Label 'Belize Dollar', MaxLength = 30;
        CongoleseFrancLbl: Label 'Congolese Franc', MaxLength = 30;
        UnidadDeFomentoLbl: Label 'Unidad de Fomento', MaxLength = 30;
        ChileanPesoLbl: Label 'Chilean Peso', MaxLength = 30;
        YuanRenminbiLbl: Label 'Yuan Renminbi', MaxLength = 30;
        ColombianPesoLbl: Label 'Colombian Peso', MaxLength = 30;
        CostaRicanColonLbl: Label 'Costa Rican Colon', MaxLength = 30;
        CubanPesoLbl: Label 'Cuban Peso', MaxLength = 30;
        CaboVerdeEscudoLbl: Label 'Cabo Verde Escudo', MaxLength = 30;
        DjiboutiFrancLbl: Label 'Djibouti Franc', MaxLength = 30;
        DominicanPesoLbl: Label 'Dominican Peso', MaxLength = 30;
        EgyptianPoundLbl: Label 'Egyptian Pound', MaxLength = 30;
        NakfaLbl: Label 'Nakfa', MaxLength = 30;
        EthiopianBirrLbl: Label 'Ethiopian Birr', MaxLength = 30;
        FalklandIslandsPoundLbl: Label 'Falkland Islands Pound', MaxLength = 30;
        LariLbl: Label 'Lari', MaxLength = 30;
        GhanaCediLbl: Label 'Ghana Cedi', MaxLength = 30;
        GibraltarPoundLbl: Label 'Gibraltar Pound', MaxLength = 30;
        DalasiLbl: Label 'Dalasi', MaxLength = 30;
        GuineanFrancLbl: Label 'Guinean Franc', MaxLength = 30;
        QuetzalLbl: Label 'Quetzal', MaxLength = 30;
        GuyanaDollarLbl: Label 'Guyana Dollar', MaxLength = 30;
        LempiraLbl: Label 'Lempira', MaxLength = 30;
        GourdeLbl: Label 'Gourde', MaxLength = 30;
        NewIsraeliSheqelLbl: Label 'New Israeli Sheqel', MaxLength = 30;
        IraqiDinarLbl: Label 'Iraqi Dinar', MaxLength = 30;
        IranianRialLbl: Label 'Iranian Rial', MaxLength = 30;
        JamaicanDollarLbl: Label 'Jamaican Dollar', MaxLength = 30;
        JordanianDinarLbl: Label 'Jordanian Dinar', MaxLength = 30;
        SomLbl: Label 'Som', MaxLength = 30;
        RielLbl: Label 'Riel', MaxLength = 30;
        ComorianFrancLbl: Label 'Comorian Franc', MaxLength = 30;
        NorthKoreanWonLbl: Label 'North Korean Won', MaxLength = 30;
        WonLbl: Label 'Won', MaxLength = 30;
        KuwaitiDinarLbl: Label 'Kuwaiti Dinar', MaxLength = 30;
        CaymanIslandsDollarLbl: Label 'Cayman Islands Dollar', MaxLength = 30;
        TengeLbl: Label 'Tenge', MaxLength = 30;
        LaoKipLbl: Label 'Lao Kip', MaxLength = 30;
        LebanesePoundLbl: Label 'Lebanese Pound', MaxLength = 30;
        SriLankaRupeeLbl: Label 'Sri Lanka Rupee', MaxLength = 30;
        LiberianDollarLbl: Label 'Liberian Dollar', MaxLength = 30;
        LotiLbl: Label 'Loti', MaxLength = 30;
        LibyanDinarLbl: Label 'Libyan Dinar', MaxLength = 30;
        MoldovanLeuLbl: Label 'Moldovan Leu', MaxLength = 30;
        MalagasyAriaryLbl: Label 'Malagasy Ariary', MaxLength = 30;
        DenarLbl: Label 'Denar', MaxLength = 30;
        KyatLbl: Label 'Kyat', MaxLength = 30;
        TugrikLbl: Label 'Tugrik', MaxLength = 30;
        PatacaLbl: Label 'Pataca', MaxLength = 30;
        OuguiyaLbl: Label 'Ouguiya', MaxLength = 30;
        MauritiusRupeeLbl: Label 'Mauritius Rupee', MaxLength = 30;
        RufiyaaLbl: Label 'Rufiyaa', MaxLength = 30;
        MalawiKwachaLbl: Label 'Malawi Kwacha', MaxLength = 30;
        NamibiaDollarLbl: Label 'Namibia Dollar', MaxLength = 30;
        CordobaOroLbl: Label 'Cordoba Oro', MaxLength = 30;
        NepaleseRupeeLbl: Label 'Nepalese Rupee', MaxLength = 30;
        RialOmaniLbl: Label 'Rial Omani', MaxLength = 30;
        BalboaLbl: Label 'Balboa', MaxLength = 30;
        SolLbl: Label 'Sol', MaxLength = 30;
        KinaLbl: Label 'Kina', MaxLength = 30;
        PakistanRupeeLbl: Label 'Pakistan Rupee', MaxLength = 30;
        GuaraniLbl: Label 'Guarani', MaxLength = 30;
        QatariRialLbl: Label 'Qatari Rial', MaxLength = 30;
        RwandaFrancLbl: Label 'Rwanda Franc', MaxLength = 30;
        SeychellesRupeeLbl: Label 'Seychelles Rupee', MaxLength = 30;
        SudanesePoundLbl: Label 'Sudanese Pound', MaxLength = 30;
        SaintHelenaPoundLbl: Label 'Saint Helena Pound', MaxLength = 30;
        LeoneLbl: Label 'Leone', MaxLength = 30;
        SomaliShillingLbl: Label 'Somali Shilling', MaxLength = 30;
        SurinamDollarLbl: Label 'Surinam Dollar', MaxLength = 30;
        SouthSudanesePoundLbl: Label 'South Sudanese Pound', MaxLength = 30;
        DobraLbl: Label 'Dobra', MaxLength = 30;
        ElSalvadorColonLbl: Label 'El Salvador Colon', MaxLength = 30;
        SyrianPoundLbl: Label 'Syrian Pound', MaxLength = 30;
        SomoniLbl: Label 'Somoni', MaxLength = 30;
        TurkmenistanNewManatLbl: Label 'Turkmenistan New Manat', MaxLength = 30;
        TrinidadAndTobagoDollarLbl: Label 'Trinidad and Tobago Dollar', MaxLength = 30;
        NewTaiwanDollarLbl: Label 'New Taiwan Dollar', MaxLength = 30;
        TanzanianShillingLbl: Label 'Tanzanian Shilling', MaxLength = 30;
        HryvniaLbl: Label 'Hryvnia', MaxLength = 30;
        UruguayPesoEnUnidadesIndexadasUiLbl: Label 'Uruguay Peso en Unidades Index', MaxLength = 30;
        PesoUruguayoLbl: Label 'Peso Uruguayo', MaxLength = 30;
        UnidadPrevisionalLbl: Label 'Unidad Previsional', MaxLength = 30;
        UzbekistanSumLbl: Label 'Uzbekistan Sum', MaxLength = 30;
        BolivarSoberanoLbl: Label 'Bolívar Soberano', MaxLength = 30;
        BolivarSoberanoVesLbl: Label 'Bolívar Soberano', MaxLength = 30;
        DongLbl: Label 'Dong', MaxLength = 30;
        ArabAccountingDinarLbl: Label 'Arab Accounting Dinar', MaxLength = 30;
        CfaFrancBeacLbl: Label 'CFA Franc BEAC', MaxLength = 30;
        EastCaribbeanDollarLbl: Label 'East Caribbean Dollar', MaxLength = 30;
        CaribbeanGuilderLbl: Label 'Caribbean Guilder', MaxLength = 30;
        CfaFrancBceaoLbl: Label 'CFA Franc BCEAO', MaxLength = 30;
        YemeniRialLbl: Label 'Yemeni Rial', MaxLength = 30;
        ZambianKwachaLbl: Label 'Zambian Kwacha', MaxLength = 30;
        ZimbabweGoldLbl: Label 'Zimbabwe Gold', MaxLength = 30;
}
