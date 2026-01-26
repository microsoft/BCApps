// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Utilities;

report 11409 "VAT- VIES Decl. Tax Auth NL"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/VATVIESDeclTaxAuthNL.rdlc';
    Caption = 'VAT- VIES Declaration Tax Auth';
    UseRequestPage = true;
    ApplicationArea = Basic, Suite;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date") where(Type = const(Sale), "VAT Calculation Type" = const("Reverse Charge VAT"), "Document Type" = filter(Invoice | "Credit Memo"));
            RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date";

            trigger OnAfterGetRecord()
            begin
                TempICL.Init();
                TempICL."Entry No." := RecordEntryNo;
                RecordEntryNo := RecordEntryNo + 1;
                TempICL."EU 3-Party Trade" := "EU 3-Party Trade";

                if "Reporting Currency" = true then
                    TempICL.Base := "Additional-Currency Base"
                else
                    TempICL.Base := Base;

                if "VAT Registration No." <> '' then begin
                    TempICL."VAT Registration No." := "VAT Registration No.";
                    TempICL."Country/Region Code" := "Country/Region Code";
                    TempICL.Insert();
                end else
                    AddError(StrSubstNo(Text1000003, "Document No."));
            end;
        }
        dataitem(Integer1; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            MaxIteration = 1;
            column(Company__VAT_Registration_No__; Company."VAT Registration No.")
            {
            }
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(CompanyAddr_4_; CompanyAddr[4])
            {
            }
            column(CompanyAddr_5_; CompanyAddr[5])
            {
            }
            column(CompanyAddr_6_; CompanyAddr[6])
            {
            }
            column(CompanyAddr_7_; CompanyAddr[7])
            {
            }
            column(CompanyAddr_8_; CompanyAddr[8])
            {
            }
            column(CurrencyReportCode; CurrencyReportCode)
            {
            }
            column(EmptyString; '')
            {
            }
            column(EmptyString_Control1000087; '')
            {
            }
            column(EmptyString_Control1000088; '')
            {
            }
            column(EmptyString_Control1000089; '')
            {
            }
            column(EmptyString_Control1000090; '')
            {
            }
            column(EmptyString_Control1000091; '')
            {
            }
            column(EmptyString_Control1000092; '')
            {
            }
            column(EmptyString_Control1000093; '')
            {
            }
            column(EmptyString_Control1000094; '')
            {
            }
            column(EmptyString_Control1000095; '')
            {
            }
            column(EmptyString_Control1000096; '')
            {
            }
            column(EmptyString_Control1000097; '')
            {
            }
            column(EmptyString_Control1000106; '')
            {
            }
            column(EmptyString_Control1000109; '')
            {
            }
            column(EmptyString_Control1000110; '')
            {
            }
            column(EmptyString_Control1000111; '')
            {
            }
            column(EmptyString_Control1000113; '')
            {
            }
            column(EmptyString_Control1000114; '')
            {
            }
            column(EmptyString_Control1000115; '')
            {
            }
            column(EmptyString_Control1000116; '')
            {
            }
            column(EmptyString_Control1000117; '')
            {
            }
            column(EmptyString_Control1000121; '')
            {
            }
            column(EmptyString_Control1000122; '')
            {
            }
            column(EmptyString_Control1000123; '')
            {
            }
            column(CurrencyReportText; CurrencyReportText)
            {
            }
            column(Company__VAT_Registration_No___Control1000073; Company."VAT Registration No.")
            {
            }
            column(BelDienstAdres1; BelDienstAdres1)
            {
            }
            column(BelDienstAdres2; BelDienstAdres2)
            {
            }
            column(BelDienstTelNr; BelDienstTelNr)
            {
            }
            column(Date_Filter_; "Date Filter")
            {
            }
            column(Company__Country_Region_Code_; Company."Country/Region Code")
            {
            }
            column(Integer1_Number; Number)
            {
            }
            column(OpgaafCaption; OpgaafCaptionLbl)
            {
            }
            column(OmzetbelastingCaption; OmzetbelastingCaptionLbl)
            {
            }
            column(Intracommunautaire_leveringenCaption; Intracommunautaire_leveringenCaptionLbl)
            {
            }
            column(Centrale_eenheid_intracommunautaire_transactiesCaption; Centrale_eenheid_intracommunautaire_transactiesCaptionLbl)
            {
            }
            column(AanCaption; AanCaptionLbl)
            {
            }
            column(Deze_opgaaf_moet_uiterlijk_Caption; Deze_opgaaf_moet_uiterlijk_CaptionLbl)
            {
            }
            column(binnen_zijn_opCaption; binnen_zijn_opCaptionLbl)
            {
            }
            column(TijdvakCaption; TijdvakCaptionLbl)
            {
            }
            column(BTW_identificatienummerCaption; BTW_identificatienummerCaptionLbl)
            {
            }
            column(Ruimte_voor_gegevens_belastingconsulentCaption; Ruimte_voor_gegevens_belastingconsulentCaptionLbl)
            {
            }
            column(KenmerkCaption; KenmerkCaptionLbl)
            {
            }
            column(TelefoonCaption; TelefoonCaptionLbl)
            {
            }
            column(Muntsoort__euro_sCaption; Muntsoort__euro_sCaptionLbl)
            {
            }
            column(Muntsoort_Caption; Muntsoort_CaptionLbl)
            {
            }
            column(V1_____Fiscale_eenheidCaption; V1_____Fiscale_eenheidCaptionLbl)
            {
            }
            column(V2_____Correcties_eerdere_opgavenCaption; V2_____Correcties_eerdere_opgavenCaptionLbl)
            {
            }
            column(V2a___Intracommunautaire_leveringenCaption; V2a___Intracommunautaire_leveringenCaptionLbl)
            {
            }
            column(BTW_identificatienummer_onderdeel_fiscale_eenheidCaption; BTW_identificatienummer_onderdeel_fiscale_eenheidCaptionLbl)
            {
            }
            column(LandcodeCaption; LandcodeCaptionLbl)
            {
            }
            column(BTW_identificatienummerCaption_Control1000076; BTW_identificatienummerCaption_Control1000076Lbl)
            {
            }
            column(correctiebedragCaption; correctiebedragCaptionLbl)
            {
            }
            column(of___t_o_v__deCaption; of___t_o_v__deCaptionLbl)
            {
            }
            column(oorspronkelijke_opgaaf_Caption; oorspronkelijke_opgaaf_CaptionLbl)
            {
            }
            column(moet_de_aanduidingCaption; moet_de_aanduidingCaptionLbl)
            {
            }
            column(bij__loonwerk__wordenCaption; bij__loonwerk__wordenCaptionLbl)
            {
            }
            column(gecorrigeerd_Caption; gecorrigeerd_CaptionLbl)
            {
            }
            column(TijdvakCaption_Control1000083; TijdvakCaption_Control1000083Lbl)
            {
            }
            column(landcodeCaption_Control1000084; landcodeCaption_Control1000084Lbl)
            {
            }
            column(nummerCaption; nummerCaptionLbl)
            {
            }
            column(JaCaption; JaCaptionLbl)
            {
            }
            column(JaCaption_Control1000102; JaCaption_Control1000102Lbl)
            {
            }
            column(JaCaption_Control1000103; JaCaption_Control1000103Lbl)
            {
            }
            column(V2b___Intracommunautaire_leveringen_A_B_C_leveringen__vereenvoudigde_regeling_Caption; V2b___Intracommunautaire_leveringen_A_B_C_leveringen__vereenvoudigde_regeling_CaptionLbl)
            {
            }
            column(TijdvakCaption_Control1000105; TijdvakCaption_Control1000105Lbl)
            {
            }
            column(BTW_identificatienummerCaption_Control1000107; BTW_identificatienummerCaption_Control1000107Lbl)
            {
            }
            column(landcodeCaption_Control1000108; landcodeCaption_Control1000108Lbl)
            {
            }
            column(nummerCaption_Control1000112; nummerCaption_Control1000112Lbl)
            {
            }
            column(correctiebedragCaption_Control1000118; correctiebedragCaption_Control1000118Lbl)
            {
            }
            column(of___t_o_v__deCaption_Control1000119; of___t_o_v__deCaption_Control1000119Lbl)
            {
            }
            column(oorspronkelijke_opgaaf_Caption_Control1000120; oorspronkelijke_opgaaf_Caption_Control1000120Lbl)
            {
            }
            column(BelastingdienstCaption; BelastingdienstCaptionLbl)
            {
            }
            column(nummerCaption_Control1000045; nummerCaption_Control1000045Lbl)
            {
            }
            column(Totaalbedrag_A_B_C_leveringenCaption; Totaalbedrag_A_B_C_leveringenCaptionLbl)
            {
            }
            column(V3____Gegevens_intracommunautaire_leveringenCaption; V3____Gegevens_intracommunautaire_leveringenCaptionLbl)
            {
            }
            column(V3a__Intracommunautaire_leveringenCaption; V3a__Intracommunautaire_leveringenCaptionLbl)
            {
            }
            column(BTW_identificatienummer_afnemerCaption; BTW_identificatienummer_afnemerCaptionLbl)
            {
            }
            column(LandcodeCaption_Control1000010; LandcodeCaption_Control1000010Lbl)
            {
            }
            column(nummerCaption_Control1000012; nummerCaption_Control1000012Lbl)
            {
            }
            column(per_afnemer_in_dit_tijdvakCaption; per_afnemer_in_dit_tijdvakCaptionLbl)
            {
            }
            column(Totaalbedrag_leveringenCaption; Totaalbedrag_leveringenCaptionLbl)
            {
            }
        }
        dataitem(TempIntracommLev1; "Reporting ICP")
        {
            DataItemTableView = sorting("EU 3-Party Trade", "Country/Region Code", "VAT Registration No.") where("EU 3-Party Trade" = const(false));
            column(TempIntracommLev1_Base; Base)
            {
            }
            column(TempIntracommLev1__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(TempIntracommLev1__Country_Region_Code_; "Country/Region Code")
            {
            }
            column(TempIntracommLev1_Entry_No_; "Entry No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if FirstTime then
                    FirstTime := false
                else
                    if (CountryRegionOld <> "Country/Region Code") or
                       (EU3PartyTradeOld <> "EU 3-Party Trade")
                    then
                        VATRegNoOld := '';

                if VATRegNoOld <> "VAT Registration No." then
                    LineCount += 1;

                VATRegNoOld := "VAT Registration No.";
                CountryRegionOld := "Country/Region Code";
                EU3PartyTradeOld := "EU 3-Party Trade";

                Base := -1 * Base;
            end;

            trigger OnPreDataItem()
            begin
                FirstTime := true;
                VATRegNoOld := '';
                LineCount := 14;
            end;
        }
        dataitem(Integer2; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            MaxIteration = 1;
            column(Integer2_Number; Number)
            {
            }
            column(V3b__Intracommunautaire_A_B_C_leveringen__vereenvoudigde_regeling_Caption; V3b__Intracommunautaire_A_B_C_leveringen__vereenvoudigde_regeling_CaptionLbl)
            {
            }
            column(Totaalbedrag_A_B_C_leveringenCaption_Control1000007; Totaalbedrag_A_B_C_leveringenCaption_Control1000007Lbl)
            {
            }
            column(BTW_identificatienummer_afnemerCaption_Control1000009; BTW_identificatienummer_afnemerCaption_Control1000009Lbl)
            {
            }
            column(per_afnemer_in_dit_tijdvakCaption_Control1000003; per_afnemer_in_dit_tijdvakCaption_Control1000003Lbl)
            {
            }
            column(nummerCaption_Control1000027; nummerCaption_Control1000027Lbl)
            {
            }
            column(LandcodeCaption_Control1000043; LandcodeCaption_Control1000043Lbl)
            {
            }
        }
        dataitem(TempIntracommLev2; "Reporting ICP")
        {
            DataItemTableView = sorting("EU 3-Party Trade", "Country/Region Code", "VAT Registration No.") where("EU 3-Party Trade" = const(true));
            column(TempIntracommLev2_Base; Base)
            {
            }
            column(TempIntracommLev2__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(TempIntracommLev2__Country_Region_Code_; "Country/Region Code")
            {
            }
            column(TempIntracommLev2_Entry_No_; "Entry No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if FirstTime then
                    FirstTime := false
                else
                    if (CountryRegionOld <> "Country/Region Code") or
                       (EU3PartyTradeOld <> "EU 3-Party Trade")
                    then
                        VATRegNoOld := '';

                if VATRegNoOld <> "VAT Registration No." then
                    LineCount += 1;

                VATRegNoOld := "VAT Registration No.";
                CountryRegionOld := "Country/Region Code";
                EU3PartyTradeOld := "EU 3-Party Trade";
                Base := -1 * Base;
            end;

            trigger OnPreDataItem()
            begin
                FirstTime := true;
                VATRegNoOld := '';
            end;
        }
        dataitem(IntegerRTC; "Integer")
        {
            column(IntegerRTC_Number; Number)
            {
            }

            trigger OnPreDataItem()
            begin
                LineCount := LinesPerPage - LineCount mod LinesPerPage;
                if (LineCount > 0) and (LineCount < (LinesPerPage - LinesPerPageWithFooter)) then
                    LineCount += LinesPerPageWithFooter
                else
                    LineCount -= (LinesPerPage - LinesPerPageWithFooter);
                SetRange(Number, 0, LineCount);
            end;
        }
        dataitem(Integer3; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            MaxIteration = 1;
            column(EmptyString_Control1000140; '')
            {
            }
            column(EmptyString_Control1000125; '')
            {
            }
            column(EmptyString_Control1000134; '')
            {
            }
            column(EmptyString_Control1000136; '')
            {
            }
            column(EmptyString_Control1000138; '')
            {
            }
            column(EmptyString_Control1000142; '')
            {
            }
            column(Integer3_Number; Number)
            {
            }
            column(NaamCaption; NaamCaptionLbl)
            {
            }
            column(PlaatsCaption; PlaatsCaptionLbl)
            {
            }
            column(HandtekeningCaption; HandtekeningCaptionLbl)
            {
            }
            column(TelefoonCaption_Control1000139; TelefoonCaption_Control1000139Lbl)
            {
            }
            column(DatumCaption; DatumCaptionLbl)
            {
            }
            column(Aantal_bijlagenCaption; Aantal_bijlagenCaptionLbl)
            {
            }
            column(OndertekeningCaption; OndertekeningCaptionLbl)
            {
            }
        }
        dataitem("Error report"; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(ErrorText_Number_; ErrorText[Number])
            {
            }
            column(Error_report_Number; Number)
            {
            }
            column(Error_reportCaption; Error_reportCaptionLbl)
            {
            }

            trigger OnPostDataItem()
            begin
                ErrorCounter := 0;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, ErrorCounter);
            end;
        }
    }

    requestpage
    {
        Caption = 'VAT- VIES Declaration Tax Auth';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowAmtInAddReportingCurrency; "Reporting Currency")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amount in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want report amounts to be shown in the additional reporting currency.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        TempICL.DeleteAll();
    end;

    trigger OnPreReport()
    begin
        SetDateFilter();
        "Date Filter" := CopyStr("VAT Entry".GetFilter("VAT Reporting Date"), 1, 250);

        TempICL.DeleteAll();
        RecordEntryNo := 1;

        Company.Get();
        if Company."VAT Registration No." = '' then
            AddError(Text1000000);

        FormatAddr.Company(CompanyAddr, Company);

        DetermineCurrency();

        // Fill address information of the belastingdienst in the variables
        BelDienstAdres1 := Text1000001;
        BelDienstAdres2 := Text1000002;
        BelDienstTelNr := '(0570) 68 34 00';

        LinesPerPage := 60;
        LinesPerPageWithFooter := 52;
    end;

    var
        Text1000000: Label 'There is no VAT Registration number filled in the company information.';
        Text1000001: Label 'Antwoordnummer 999';
        Text1000002: Label '7400 WZ Deventer';
        Text1000003: Label 'No VAT Registration No. in VAT-entry with document number %1.';
        GLSetup: Record "General Ledger Setup";
        Company: Record "Company Information";
        Currency: Record Currency;
        TempICL: Record "Reporting ICP";
        FormatAddr: Codeunit "Format Address";
        CompanyAddr: array[8] of Text[100];
        "Date Filter": Text[250];
        "Reporting Currency": Boolean;
        FirstTime: Boolean;
        EU3PartyTradeOld: Boolean;
        CurrencyReportCode: Code[10];
        CountryRegionOld: Code[10];
        CurrencyReportText: Text[30];
        BelDienstAdres1: Text[30];
        BelDienstAdres2: Text[30];
        BelDienstTelNr: Text[15];
        VATRegNoOld: Text[20];
        RecordEntryNo: Integer;
        ErrorCounter: Integer;
        LineCount: Integer;
        LinesPerPage: Integer;
        LinesPerPageWithFooter: Integer;
        ErrorText: array[50] of Text[250];
        OpgaafCaptionLbl: Label 'Opgaaf';
        OmzetbelastingCaptionLbl: Label 'Omzetbelasting';
        Intracommunautaire_leveringenCaptionLbl: Label 'Intracommunautaire leveringen';
        Centrale_eenheid_intracommunautaire_transactiesCaptionLbl: Label 'Centrale eenheid intracommunautaire transacties';
        AanCaptionLbl: Label 'Aan';
        Deze_opgaaf_moet_uiterlijk_CaptionLbl: Label 'Deze opgaaf moet uiterlijk';
        binnen_zijn_opCaptionLbl: Label 'binnen zijn op', Locked = true;
        TijdvakCaptionLbl: Label 'Tijdvak';
        BTW_identificatienummerCaptionLbl: Label 'BTW-identificatienummer';
        Ruimte_voor_gegevens_belastingconsulentCaptionLbl: Label 'Ruimte voor gegevens belastingconsulent';
        KenmerkCaptionLbl: Label 'Kenmerk';
        TelefoonCaptionLbl: Label 'Telefoon';
        Muntsoort__euro_sCaptionLbl: Label 'Muntsoort: euro''s';
        Muntsoort_CaptionLbl: Label 'Muntsoort:';
        V1_____Fiscale_eenheidCaptionLbl: Label '1     Fiscale eenheid';
        V2_____Correcties_eerdere_opgavenCaptionLbl: Label '2     Correcties eerdere opgaven';
        V2a___Intracommunautaire_leveringenCaptionLbl: Label '2a   Intracommunautaire leveringen';
        BTW_identificatienummer_onderdeel_fiscale_eenheidCaptionLbl: Label 'BTW-identificatienummer onderdeel fiscale eenheid';
        LandcodeCaptionLbl: Label 'Landcode';
        BTW_identificatienummerCaption_Control1000076Lbl: Label 'BTW-identificatienummer';
        correctiebedragCaptionLbl: Label 'correctiebedrag', Locked = true;
        of___t_o_v__deCaptionLbl: Label '(+ of - t.o.v. de';
        oorspronkelijke_opgaaf_CaptionLbl: Label 'oorspronkelijke opgaaf)', Locked = true;
        moet_de_aanduidingCaptionLbl: Label 'moet de aanduiding', Locked = true;
        bij__loonwerk__wordenCaptionLbl: Label 'bij "loonwerk" worden', Locked = true;
        gecorrigeerd_CaptionLbl: Label 'gecorrigeerd?', Locked = true;
        TijdvakCaption_Control1000083Lbl: Label 'Tijdvak';
        landcodeCaption_Control1000084Lbl: Label 'landcode', Locked = true;
        nummerCaptionLbl: Label 'nummer', Locked = true;
        JaCaptionLbl: Label 'Ja';
        JaCaption_Control1000102Lbl: Label 'Ja';
        JaCaption_Control1000103Lbl: Label 'Ja';
        V2b___Intracommunautaire_leveringen_A_B_C_leveringen__vereenvoudigde_regeling_CaptionLbl: Label '2b   Intracommunautaire leveringen A-B-C-leveringen (vereenvoudigde regeling)';
        TijdvakCaption_Control1000105Lbl: Label 'Tijdvak';
        BTW_identificatienummerCaption_Control1000107Lbl: Label 'BTW-identificatienummer';
        landcodeCaption_Control1000108Lbl: Label 'landcode', Locked = true;
        nummerCaption_Control1000112Lbl: Label 'nummer', Locked = true;
        correctiebedragCaption_Control1000118Lbl: Label 'correctiebedrag', Locked = true;
        of___t_o_v__deCaption_Control1000119Lbl: Label '(+ of - t.o.v. de';
        oorspronkelijke_opgaaf_Caption_Control1000120Lbl: Label 'oorspronkelijke opgaaf)', Locked = true;
        BelastingdienstCaptionLbl: Label 'Belastingdienst';
        nummerCaption_Control1000045Lbl: Label 'nummer', Locked = true;
        Totaalbedrag_A_B_C_leveringenCaptionLbl: Label 'Totaalbedrag A-B-C leveringen';
        V3____Gegevens_intracommunautaire_leveringenCaptionLbl: Label '3    Gegevens intracommunautaire leveringen';
        V3a__Intracommunautaire_leveringenCaptionLbl: Label '3a  Intracommunautaire leveringen';
        BTW_identificatienummer_afnemerCaptionLbl: Label 'BTW-identificatienummer afnemer';
        LandcodeCaption_Control1000010Lbl: Label 'Landcode';
        nummerCaption_Control1000012Lbl: Label 'nummer', Locked = true;
        per_afnemer_in_dit_tijdvakCaptionLbl: Label 'per afnemer in dit tijdvak', Locked = true;
        Totaalbedrag_leveringenCaptionLbl: Label 'Totaalbedrag leveringen';
        V3b__Intracommunautaire_A_B_C_leveringen__vereenvoudigde_regeling_CaptionLbl: Label '3b  Intracommunautaire A-B-C-leveringen (vereenvoudigde regeling)';
        Totaalbedrag_A_B_C_leveringenCaption_Control1000007Lbl: Label 'Totaalbedrag A-B-C leveringen';
        BTW_identificatienummer_afnemerCaption_Control1000009Lbl: Label 'BTW-identificatienummer afnemer';
        per_afnemer_in_dit_tijdvakCaption_Control1000003Lbl: Label 'per afnemer in dit tijdvak', Locked = true;
        nummerCaption_Control1000027Lbl: Label 'nummer', Locked = true;
        LandcodeCaption_Control1000043Lbl: Label 'Landcode';
        NaamCaptionLbl: Label 'Naam';
        PlaatsCaptionLbl: Label 'Plaats';
        HandtekeningCaptionLbl: Label 'Handtekening';
        TelefoonCaption_Control1000139Lbl: Label 'Telefoon';
        DatumCaptionLbl: Label 'Datum';
        Aantal_bijlagenCaptionLbl: Label 'Aantal bijlagen';
        OndertekeningCaptionLbl: Label 'Ondertekening';
        Error_reportCaptionLbl: Label 'Error report';

    [Scope('OnPrem')]
    procedure DetermineCurrency()
    begin
        GLSetup.Get();
        if "Reporting Currency" = true then
            CurrencyReportCode := GLSetup."Additional Reporting Currency"
        else
            CurrencyReportCode := GLSetup."LCY Code";

        if Currency.Get(CurrencyReportCode) then
            CurrencyReportText := Currency.Description
        else
            CurrencyReportText := '';
    end;

    [Scope('OnPrem')]
    procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure SetDateFilter()
    begin
        if "VAT Entry".GetFilter("Document Date") <> '' then
            "Date Filter" := CopyStr("VAT Entry".GetFilter("Document Date"), 1, 250);
        if "VAT Entry".GetFilter("Posting Date") <> '' then
            "Date Filter" := CopyStr("VAT Entry".GetFilter("Posting Date"), 1, 250);
        if "VAT Entry".GetFilter("VAT Reporting Date") <> '' then
            "Date Filter" := CopyStr("VAT Entry".GetFilter("VAT Reporting Date"), 1, 250);
    end;
}

