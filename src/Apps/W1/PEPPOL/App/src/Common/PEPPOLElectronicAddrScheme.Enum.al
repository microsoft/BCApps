// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

/// <summary>
/// The Peppol Electronic Address Scheme (EAS) code list, which cbc:EndpointID/@schemeID must use.
/// The value name is the EAS code and the ordinal its numeric value; source: https://docs.peppol.eu/poacc/billing/3.0/codelist/eas/
/// Extend the enum to accept a code that OpenPeppol published after this list, with the code as the value name.
/// Captions follow the code list names, without commas as enum captions do not support them.
/// </summary>
enum 37202 "PEPPOL Electronic Addr. Scheme"
{
    Access = Public;
    Extensible = true;

    value(2; "0002")
    {
        Caption = '0002 - System Information et Repertoire des Entreprise et des Etablissements: SIRENE', Locked = true;
    }
    value(7; "0007")
    {
        Caption = '0007 - Organisationsnummer (Swedish legal entities)', Locked = true;
    }
    value(9; "0009")
    {
        Caption = '0009 - SIRET-CODE', Locked = true;
    }
    value(60; "0060")
    {
        Caption = '0060 - Data Universal Numbering System (D-U-N-S Number)', Locked = true;
    }
    value(88; "0088")
    {
        Caption = '0088 - Global Location Number', Locked = true;
    }
    value(96; "0096")
    {
        Caption = '0096 - The Danish Business Authority - P-number (DK:P)', Locked = true;
    }
    value(97; "0097")
    {
        Caption = '0097 - FTI - Ediforum Italia (EDIRA compliant)', Locked = true;
    }
    value(106; "0106")
    {
        Caption = '0106 - Vereniging van Kamers van Koophandel en Fabrieken in Nederland (Association of Chambers of Commerce and Industry in the Netherlands) Scheme (EDIRA compliant)', Locked = true;
    }
    value(130; "0130")
    {
        Caption = '0130 - Directorates of the European Commission', Locked = true;
    }
    value(135; "0135")
    {
        Caption = '0135 - SIA Object Identifiers', Locked = true;
    }
    value(142; "0142")
    {
        Caption = '0142 - SECETI Object Identifiers', Locked = true;
    }
    value(151; "0151")
    {
        Caption = '0151 - Australian Business Number (ABN) Scheme', Locked = true;
    }
    value(158; "0158")
    {
        Caption = '0158 - Identification number of economic subject (ICO) Act on State Statistics of 29 November 2001 § 27', Locked = true;
    }
    value(183; "0183")
    {
        Caption = '0183 - Numéro d''identification suisse des enterprises (IDE) / Swiss Unique Business Identification Number (UIDB)', Locked = true;
    }
    value(184; "0184")
    {
        Caption = '0184 - The Danish Business Authority - CVR-number (DK:CVR)', Locked = true;
    }
    value(188; "0188")
    {
        Caption = '0188 - Corporate Number of The Social Security and Tax Number System', Locked = true;
    }
    value(190; "0190")
    {
        Caption = '0190 - Organisatie-identificatienummer (OIN)', Locked = true;
    }
    value(191; "0191")
    {
        Caption = '0191 - Company code', Locked = true;
    }
    value(192; "0192")
    {
        Caption = '0192 - Organisasjonsnummer', Locked = true;
    }
    value(195; "0195")
    {
        Caption = '0195 - Singapore Nationwide E-Invoice Framework', Locked = true;
    }
    value(196; "0196")
    {
        Caption = '0196 - Icelandic identifier', Locked = true;
    }
    value(198; "0198")
    {
        Caption = '0198 - The Danish Business Authority - SE-number (DK:SE)', Locked = true;
    }
    value(199; "0199")
    {
        Caption = '0199 - Legal Entity Identifier (LEI)', Locked = true;
    }
    value(200; "0200")
    {
        Caption = '0200 - Legal entity code (Lithuania)', Locked = true;
    }
    value(201; "0201")
    {
        Caption = '0201 - Codice Univoco Unità Organizzativa iPA', Locked = true;
    }
    value(204; "0204")
    {
        Caption = '0204 - Peppol-Leitweg-ID', Locked = true;
    }
    value(208; "0208")
    {
        Caption = '0208 - Numero d''entreprise / ondernemingsnummer / Unternehmensnummer', Locked = true;
    }
    value(209; "0209")
    {
        Caption = '0209 - GS1 identification keys', Locked = true;
    }
    value(210; "0210")
    {
        Caption = '0210 - CODICE FISCALE', Locked = true;
    }
    value(211; "0211")
    {
        Caption = '0211 - PARTITA IVA', Locked = true;
    }
    value(216; "0216")
    {
        Caption = '0216 - OVTcode', Locked = true;
    }
    value(218; "0218")
    {
        Caption = '0218 - Unified registration number (Latvia)', Locked = true;
    }
    value(221; "0221")
    {
        Caption = '0221 - The registered number of the qualified invoice issuer (Japan)', Locked = true;
    }
    value(225; "0225")
    {
        Caption = '0225 - FRCTC ELECTRONIC ADDRESS', Locked = true;
    }
    value(230; "0230")
    {
        Caption = '0230 - National e-Invoicing Framework (Malaysia)', Locked = true;
    }
    value(235; "0235")
    {
        Caption = '0235 - UAE Tax Identification Number (TIN)', Locked = true;
    }
    value(240; "0240")
    {
        Caption = '0240 - Register of legal persons (in French : Répertoire des personnes morales)', Locked = true;
    }
    value(242; "0242")
    {
        Caption = '0242 - OpenPeppol Service Provider Identification Scheme', Locked = true;
    }
    value(244; "0244")
    {
        Caption = '0244 - Tax Identification (Tax ID)', Locked = true;
    }
    value(245; "0245")
    {
        Caption = '0245 - Tax identification number (DIČ)', Locked = true;
    }
    value(246; "0246")
    {
        Caption = '0246 - German Electronic Business Address', Locked = true;
    }
    value(248; "0248")
    {
        Caption = '0248 - Oman Value Added Tax Identification Number (VATIN)', Locked = true;
    }
    value(9910; "9910")
    {
        Caption = '9910 - Hungary VAT number', Locked = true;
    }
    value(9913; "9913")
    {
        Caption = '9913 - Business Registers Network', Locked = true;
    }
    value(9914; "9914")
    {
        Caption = '9914 - Österreichische Umsatzsteuer-Identifikationsnummer', Locked = true;
    }
    value(9915; "9915")
    {
        Caption = '9915 - Österreichisches Verwaltungs bzw. Organisationskennzeichen', Locked = true;
    }
    value(9918; "9918")
    {
        Caption = '9918 - SOCIETY FOR WORLDWIDE INTERBANK FINANCIAL TELECOMMUNICATION S.W.I.F.T', Locked = true;
    }
    value(9919; "9919")
    {
        Caption = '9919 - Kennziffer des Unternehmensregisters', Locked = true;
    }
    value(9920; "9920")
    {
        Caption = '9920 - Agencia Española de Administración Tributaria', Locked = true;
    }
    value(9922; "9922")
    {
        Caption = '9922 - Andorra VAT number', Locked = true;
    }
    value(9923; "9923")
    {
        Caption = '9923 - Albania VAT number', Locked = true;
    }
    value(9924; "9924")
    {
        Caption = '9924 - Bosnia and Herzegovina VAT number', Locked = true;
    }
    value(9925; "9925")
    {
        Caption = '9925 - Belgium VAT number', Locked = true;
    }
    value(9926; "9926")
    {
        Caption = '9926 - Bulgaria VAT number', Locked = true;
    }
    value(9927; "9927")
    {
        Caption = '9927 - Switzerland VAT number', Locked = true;
    }
    value(9928; "9928")
    {
        Caption = '9928 - Cyprus VAT number', Locked = true;
    }
    value(9929; "9929")
    {
        Caption = '9929 - Czech Republic VAT number', Locked = true;
    }
    value(9930; "9930")
    {
        Caption = '9930 - Germany VAT number', Locked = true;
    }
    value(9931; "9931")
    {
        Caption = '9931 - Estonia VAT number', Locked = true;
    }
    value(9932; "9932")
    {
        Caption = '9932 - United Kingdom VAT number', Locked = true;
    }
    value(9933; "9933")
    {
        Caption = '9933 - Greece VAT number', Locked = true;
    }
    value(9934; "9934")
    {
        Caption = '9934 - Croatia VAT number', Locked = true;
    }
    value(9935; "9935")
    {
        Caption = '9935 - Ireland VAT number', Locked = true;
    }
    value(9936; "9936")
    {
        Caption = '9936 - Liechtenstein VAT number', Locked = true;
    }
    value(9937; "9937")
    {
        Caption = '9937 - Lithuania VAT number', Locked = true;
    }
    value(9938; "9938")
    {
        Caption = '9938 - Luxemburg VAT number', Locked = true;
    }
    value(9939; "9939")
    {
        Caption = '9939 - Latvia VAT number', Locked = true;
    }
    value(9940; "9940")
    {
        Caption = '9940 - Monaco VAT number', Locked = true;
    }
    value(9941; "9941")
    {
        Caption = '9941 - Montenegro VAT number', Locked = true;
    }
    value(9942; "9942")
    {
        Caption = '9942 - Macedonia (the former Yugoslav Republic of) VAT number', Locked = true;
    }
    value(9943; "9943")
    {
        Caption = '9943 - Malta VAT number', Locked = true;
    }
    value(9944; "9944")
    {
        Caption = '9944 - Netherlands VAT number', Locked = true;
    }
    value(9945; "9945")
    {
        Caption = '9945 - Poland VAT number', Locked = true;
    }
    value(9946; "9946")
    {
        Caption = '9946 - Portugal VAT number', Locked = true;
    }
    value(9947; "9947")
    {
        Caption = '9947 - Romania VAT number', Locked = true;
    }
    value(9948; "9948")
    {
        Caption = '9948 - Serbia VAT number', Locked = true;
    }
    value(9949; "9949")
    {
        Caption = '9949 - Slovenia VAT number', Locked = true;
    }
    value(9950; "9950")
    {
        Caption = '9950 - Slovakia VAT number', Locked = true;
    }
    value(9951; "9951")
    {
        Caption = '9951 - San Marino VAT number', Locked = true;
    }
    value(9952; "9952")
    {
        Caption = '9952 - Turkey VAT number', Locked = true;
    }
    value(9953; "9953")
    {
        Caption = '9953 - Holy See (Vatican City State) VAT number', Locked = true;
    }
    value(9957; "9957")
    {
        Caption = '9957 - French VAT number', Locked = true;
    }
    value(9959; "9959")
    {
        Caption = '9959 - US Employer ID Number', Locked = true;
    }
}
