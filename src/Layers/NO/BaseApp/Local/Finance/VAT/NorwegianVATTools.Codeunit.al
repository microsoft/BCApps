// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Utilities;

codeunit 10600 "Norwegian VAT Tools"
{

    trigger OnRun()
    begin
    end;

    var
        Text003: Label 'This will delete the current VAT Periods and create new.\Create the six standard Norwegian VAT Periods?';
        Text004: Label '%1 to %2';
        Text005: Label 'is in a settled and closed VAT period (%1 period %2)';
        Text006: Label '=%1 can only be used with Sale';
        Text007: Label '=%1 can only be used when posting without Tax';
        Text008: Label 'must be zero when posting outside tax area';
        Text009: Label 'must be zero when %1 in %2 is True';
        AdjustmentTok: Label 'justering', Locked = true;
        AdjustmentDescriptionTxt: Label 'Justering av merverdiavgift for kapitalvarer', Locked = true;
        LossesOnClaimsTok: Label 'tapPåKrav', Locked = true;
        LossesOnClaimsDescriptionTxt: Label 'Tap på Krav', Locked = true;
        ReversalInputVATTok: Label 'tilbakeføringAvInngåendeMerverdiavgift', Locked = true;
        ReversalInputVATDescriptionTxt: Label 'Tilbakeføring av merverdiavgift for kapitalvarer (kun personkjøretøy og fast eiendom)', Locked = true;
        WithdrawalsTok: Label 'uttak', Locked = true;
        WithdrawalsDescriptionTxt: Label 'uttak', Locked = true;
        GoodsTok: Label 'varer', Locked = true;
        GoodsDescriptionTxt: Label 'varer', Locked = true;
        ServicesTok: Label 'tjenester', Locked = true;
        ServicesDescriptionTxt: Label 'tjenester', Locked = true;
        OutputVATDescriptionTxt: Label 'Output VAT (Withdrawals)', MaxLength = 30;
        NoOutputVATDescriptionTxt: Label 'No output VAT', MaxLength = 30;
        InputVATDeductDomDescrTxt: Label 'Input VAT deduct. (domestic)', MaxLength = 30;
        ImportOfGoodsDescrTxt: Label 'Imp. of goods, VAT deduct.', MaxLength = 30;
        NonStandardInvoicingTok: Label 'avvikende fakturering', Locked = true;
        NonStandardInvoicingDescriptionTxt: Label 'Husleie som faktureres kvartalsvis, halvårlig eller årlig eller sesongvariasjoner i virksomheten', Locked = true;
        AccrualsTok: Label 'periodisering', Locked = true;
        AccrualsDescriptionTxt: Label 'Korrigering pga. etterfakturering, tidligere utelatt eller glemt faktura eller årsoppgjørsdisposisjoner', Locked = true;
        PreviouslyUsedVATCodeNotCorrectTok: Label 'feil mva-kode brukt tidligere', Locked = true;
        PreviouslyUsedVATCodeNotCorrectDescrTxt: Label 'Korrigering på grunn av rapportering under feil mva-kode', Locked = true;
        ErrorsInAccSoftwareTok: Label 'feil i regnskapsprogram', Locked = true;
        ErrorsInAccSoftwareDescrTxt: Label 'Omsetningen er korrigert på grunn av tidligere feil i regnskapsprogram', Locked = true;
        InsuranceSettlementTok: Label 'Forsikringsoppgjør', Locked = true;
        InsuranceSettlementDescrTxt: Label 'Det er fradragsført merverdiavgift i forbindelse med et forsikringsoppgjør som gjelder virksomheten', Locked = true;
        TurnoverBeforeRegistrationTok: Label 'Omsetning før registrering', Locked = true;
        TurnoverBeforeRegistrationDescrTxt: Label 'Omsetning før registrering i Merverdiavgiftsregisteret', Locked = true;
        RecalculationOfReturnsTok: Label 'Omberegning eller retur', Locked = true;
        RecalculationOfReturnsDescrTxt: Label 'Forklaring på differanse mellom rapport fra Toll (tolldeklarasjoner) og skattemeldingen for merverdiavgift', Locked = true;
        TemporaryImportTok: Label 'Midlertidig innførsel', Locked = true;
        TemporaryImportDescrTxt: Label 'Forklaring på differanse mellom rapport fra Toll (tolldeklarasjoner) og skattemeldingen for merverdiavgift', Locked = true;
        ReimportTok: Label 'Gjeninnførsel', Locked = true;
        ReimportDescrTxt: Label 'Forklaring på differanse mellom rapport fra Toll (tolldeklarasjoner) og skattemeldingen for merverdiavgift', Locked = true;
        CustDeclUnderIncorrVATRegNumberTok: Label 'Tolldeklarasjon på feil organisasjonsnummer', Locked = true;
        CustDeclUnderIncorrVATRegNumberDescrTxt: Label 'Forklaring på differanse mellom rapport fra Toll (tolldeklarasjoner) og skattemeldingen for merverdiavgift', Locked = true;
        ReexportOfReturnsTok: Label 'Gjenutførsel eller retur', Locked = true;
        ReexportOfReturnsDescrTxt: Label 'Forklaring på differanse mellom rapport fra Toll (tolldeklarasjoner) og skattemeldingen for merverdiavgift', Locked = true;
        TemporaryExportTok: Label 'Midlertidig utførsel', Locked = true;
        TemporaryExportDescrTxt: Label 'Forklaring på differanse mellom rapport fra Toll (tolldeklarasjoner) og skattemeldingen for merverdiavgift', Locked = true;
        ExportOfServicesTok: Label 'Tjenesteeksport', Locked = true;
        ExportOfServicesDescrTxt: Label 'Forklaring på differanse mellom rapport fra Toll (tolldeklarasjoner) og skattemeldingen for merverdiavgift', Locked = true;
        LargePurchasesTok: Label 'Store anskaffelser', Locked = true;
        LargePurchasesDescrTxt: Label 'Forklaring på store fradrag for inngående merverdiavgift', Locked = true;
        CreditNotesTok: Label 'Kreditnota', Locked = true;
        CreditNotesDescrTxt: Label 'Faktura er brukt til å endre hele eller deler av en tidligere faktura', Locked = true;
        PurchMadeBeforeRegTok: Label 'Anskaffelser foretatt før mva registrering', Locked = true;
        PurchMadeBeforeRegDescrTxt: Label 'Anskaffelser foretatt før registrering i Merverdiavgiftsregisteret, tilbakegående avgiftsoppgjør eller forklaring på store fradrag for inngående merverdiavgift', Locked = true;
        BuldForOwnExpenseAndRiskTok: Label 'Bygg i egenregi', Locked = true;
        BuldForOwnExpenseAndRiskDescrTxt: Label 'Varer og tjenester tatt ut til fra virksomheten før bygget selges', Locked = true;
        WithdrawalAfterCessationTok: Label 'Uttak av varer ved opphør', Locked = true;
        WithdrawalAfterCessationDescrTxt: Label 'Uttak av varer ved opphør av virksomheten', Locked = true;
        RealPropertyTok: Label 'fast eiendom', Locked = true;
        RealPropertyDescrTxt: Label 'Tilbakeføring av merverdiavgift på kapitalvarer som gjelder fast eiendom', Locked = true;
        PassengerVehiclesTok: Label 'personkjøretøy', Locked = true;
        PassengerVehiclesDescrTxt: Label 'Tilbakeføring av merverdiavgift på kapitalvarer som gjelder personkjøretøy', Locked = true;
        DemonstrationCarTok: Label 'demobil', Locked = true;
        DemonstrationCarDescrTxt: Label 'Beregning av utgående avgift på bil som er fradragsført og registrert i virksomheten', Locked = true;
        BindingAdvanceRulingTok: Label 'Bindende forhåndsuttalelse', Locked = true;
        BindingAdvanceRulingDescrTxt: Label 'Skatteetatens bindende forhåndsuttalelse (BFU) skal legges til grunn', Locked = true;
        EnterpriseUnderLiquidationTok: Label 'Virksomhet under avvikling', Locked = true;
        EnterpriseUnderLiquidationDescrTxt: Label 'Virksomheten skal slettes i Merverdiavgiftsregisteret', Locked = true;
        EnterpriseChangedLegalStructureTok: Label 'Virksomheten har endret selskapsform', Locked = true;
        EnterpriseChangedLegalStructureDescrTxt: Label 'Virksomheten er overført til/fra annet organisasjonsnummer', Locked = true;
        DropInRevenueExtrCircTok: Label 'Omsetningssvikt pga. ekstraordinære forhold', Locked = true;
        DropInRevenueExtrCircDescrTxt: Label 'Mindre omsetning enn det som er vanlig for virksomheten', Locked = true;
        ShipwreckTok: Label 'Forlis', Locked = true;
        ShipwreckDescrTxt: Label 'Utbetaling ved forlis mv.', Locked = true;
        VATFreeSalesOfFishingVesselTok: Label 'Avgiftsfritt salg av fiskefartøy', Locked = true;
        VATFreeSalesOfFishingVesselDescrTxt: Label 'Avgiftsfritt salg av fiskefartøy', Locked = true;


    [Scope('OnPrem')]
    procedure GLEntryCalcPropDeduction(var PropDeductionVAT: Decimal; var PropDeductionVATACY: Decimal; GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; AddCurrGLEntryVATAmt: Decimal): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Purchase) and
           VATPostingSetup."Calc. Prop. Deduction VAT" and
           (GLEntry.Amount <> 0)
        then begin
            // Calculate Amount adjustments
            PropDeductionVAT :=
              GLEntry."VAT Amount" - AdjustForPropDeduction(GLEntry."VAT Amount", GenJnlLine, VATPostingSetup);
            GLSetup.Get();
            if GenJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency" then
                PropDeductionVATACY :=
                  AddCurrGLEntryVATAmt - AdjustForPropDeduction(AddCurrGLEntryVATAmt, GenJnlLine, VATPostingSetup)
            else
                exit(false);
        end else begin
            PropDeductionVAT := 0;
            PropDeductionVATACY := 0;
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure AdjustForPropDeduction(Amount: Decimal; GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        if (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Purchase) and
           VATPostingSetup."Calc. Prop. Deduction VAT" and
           (Amount <> 0)
        then
            exit(Round(Amount * VATPostingSetup."Proportional Deduction VAT %" / 100));
        exit(Amount);
    end;

    procedure VATEntrySetVATInformation(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATReportingCode: Record "VAT Reporting Code";
    begin
        case GenJournalLine."VAT Base Amount Type" of
            GenJournalLine."VAT Base Amount Type"::Automatic:
                if VATEntry.Amount = 0 then begin
                    VATProductPostingGroup.Get(GenJournalLine."VAT Prod. Posting Group");
                    if VATProductPostingGroup."Outside Tax Area" then
                        VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"Outside Tax Area"
                    else
                        VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"Without VAT";
                end else
                    VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"With VAT";
            GenJournalLine."VAT Base Amount Type"::"With VAT":
                VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"With VAT";
            GenJournalLine."VAT Base Amount Type"::"Without VAT":
                VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"Without VAT";
        end;
        VATEntry."VAT Number" := GenJournalLine."VAT Number";

        // Test the Gen. Posting Type against the setup
        if VATEntry."VAT Number" <> '' then begin
            VATReportingCode.Get(VATEntry."VAT Number");
            case VATReportingCode."Test Gen. Posting Type" of
                VATReportingCode."Test Gen. Posting Type"::Mandatory:
                    GenJournalLine.TestField("Gen. Posting Type");
                VATReportingCode."Test Gen. Posting Type"::Same:
                    GenJournalLine.TestField("Gen. Posting Type", VATReportingCode."Gen. Posting Type");
            end;
        end;
    end;

    procedure InitVATCodeGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; UseBalanceFields: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATReportingCode: Record "VAT Reporting Code";
    begin
        if UseBalanceFields then begin
            if VATPostingSetup.Get(GenJournalLine."Bal. VAT Bus. Posting Group", GenJournalLine."Bal. VAT Prod. Posting Group") then begin
                GenJournalLine."Bal. VAT Number" := VATPostingSetup."VAT Number";
                if VATPostingSetup."VAT Number" <> '' then begin
                    VATReportingCode.Get(VATPostingSetup."VAT Number");
                    GenJournalLine."Bal. Gen. Posting Type" := "General Posting Type".FromInteger(VATReportingCode."Gen. Posting Type");
                end;
            end else
                GenJournalLine."Bal. VAT Number" := '';
        end else
            if VATPostingSetup.Get(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group") then begin
                GenJournalLine."VAT Number" := VATPostingSetup."VAT Number";
                if VATPostingSetup."VAT Number" <> '' then begin
                    VATReportingCode.Get(VATPostingSetup."VAT Number");
                    GenJournalLine."Gen. Posting Type" := "General Posting Type".FromInteger(VATReportingCode."Gen. Posting Type");
                end;
            end else
                GenJournalLine."VAT Number" := '';
    end;

    procedure InitVATCodeSalesLine(var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATReportingCode: Record "VAT Reporting Code";
    begin
        if VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then begin
            SalesLine."VAT Number" := VATPostingSetup."VAT Number";
            if VATPostingSetup."VAT Number" <> '' then
                VATReportingCode.Get(VATPostingSetup."VAT Number");
        end else
            SalesLine."VAT Number" := '';
    end;

    procedure InitVATCodePurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATReportingCode: Record "VAT Reporting Code";
    begin
        if VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group") then begin
            PurchaseLine."VAT Number" := VATPostingSetup."VAT Number";
            if VATPostingSetup."VAT Number" <> '' then
                VATReportingCode.Get(VATPostingSetup."VAT Number");
        end else
            PurchaseLine."VAT Number" := '';
    end;

    procedure InitPostingGroupsGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; UseBalanceFields: Boolean)
    var
        VATReportingCode: Record "VAT Reporting Code";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if UseBalanceFields then
            if GenJournalLine."Bal. VAT Number" = '' then begin
                GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::" ");
                GenJournalLine.Validate("Bal. VAT Bus. Posting Group", '');
                GenJournalLine.Validate("Bal. VAT Prod. Posting Group", '');
            end else begin
                VATReportingCode.Get(GenJournalLine."Bal. VAT Number");
                VATPostingSetup.SetCurrentKey("VAT Number");
                VATPostingSetup.SetRange("VAT Number", GenJournalLine."Bal. VAT Number");
                VATPostingSetup.FindFirst();
                GenJournalLine.Validate("Bal. Gen. Posting Type", VATReportingCode."Gen. Posting Type");
                GenJournalLine.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                GenJournalLine.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            end
        else
            if GenJournalLine."VAT Number" = '' then begin
                GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::" ");
                GenJournalLine.Validate("VAT Bus. Posting Group", '');
                GenJournalLine.Validate("VAT Prod. Posting Group", '');
            end else begin
                VATReportingCode.Get(GenJournalLine."VAT Number");
                VATPostingSetup.SetCurrentKey("VAT Number");
                VATPostingSetup.SetRange("VAT Number", GenJournalLine."VAT Number");
                VATPostingSetup.FindFirst();
                GenJournalLine.Validate("Gen. Posting Type", VATReportingCode."Gen. Posting Type");
                GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            end;
    end;

    procedure InitPostingGroupsSalesLine(var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if SalesLine."VAT Number" = '' then begin
            SalesLine.Validate("VAT Bus. Posting Group", '');
            SalesLine.Validate("VAT Prod. Posting Group", '');
        end else begin
            VATPostingSetup.SetCurrentKey("VAT Number");
            VATPostingSetup.SetRange("VAT Number", SalesLine."VAT Number");
            VATPostingSetup.FindFirst();
            SalesLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
            SalesLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
            SalesLine.Validate("VAT Bus. Posting Group");
            SalesLine.Validate("VAT Prod. Posting Group");
        end;
    end;

    procedure InitPostingGroupsPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if PurchaseLine."VAT Number" = '' then begin
            PurchaseLine.Validate("VAT Bus. Posting Group", '');
            PurchaseLine.Validate("VAT Prod. Posting Group", '');
        end else begin
            VATPostingSetup.SetCurrentKey("VAT Number");
            VATPostingSetup.SetRange("VAT Number", PurchaseLine."VAT Number");
            VATPostingSetup.FindFirst();
            PurchaseLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
            PurchaseLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
            PurchaseLine.Validate("VAT Bus. Posting Group");
            PurchaseLine.Validate("VAT Prod. Posting Group");
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateStdVATPeriods(AskUser: Boolean)
    var
        VATPeriod: Record "VAT Period";
        Date: Record Date;
        PeriodNo: Integer;
        MonthName1: Text[30];
        MonthName2: Text[30];
    begin
        // Create Norwegian std. six VAT Periods
        if AskUser then
            if not Confirm(Text003) then
                exit;
        VATPeriod.DeleteAll();
        for PeriodNo := 1 to 6 do begin
            VATPeriod.Validate("Period No.", PeriodNo);
            VATPeriod.Validate("Start Day", 1);
            VATPeriod.Validate("Start Month", 2 * PeriodNo - 1);

            // Find month names
            Date.SetRange("Period Type", Date."Period Type"::Month);
            Date.SetRange("Period Start", DMY2Date(1, PeriodNo * 2 - 1, 2000), 20010101D);
            Date.FindSet();
            MonthName1 := Date."Period Name";
            Date.Next();
            MonthName2 := Date."Period Name";

            VATPeriod.Validate(Description, StrSubstNo(Text004, MonthName1, MonthName2));
            VATPeriod.Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure FirstDateInVATPeriod(DateInPeriod: Date): Date
    var
        VATPeriod: Record "VAT Period";
        Day: Integer;
        Month: Integer;
    begin
        if Format(DateInPeriod) = '' then
            exit(20000101D);
        Day := Date2DMY(DateInPeriod, 1);
        Month := Date2DMY(DateInPeriod, 2);
        VATPeriod.CheckPeriods();
        VATPeriod.SetCurrentKey("Start Month", "Start Day");
        VATPeriod.SetRange("Start Month", 0, Month);
        VATPeriod.SetRange("Start Day", 0, Day);
        VATPeriod.FindLast();
        exit(DMY2Date(VATPeriod."Start Day", VATPeriod."Start Month", Date2DMY(DateInPeriod, 3)));
    end;

    [Scope('OnPrem')]
    procedure VATPeriodNo(DateInPeriod: Date): Integer
    var
        VATPeriod: Record "VAT Period";
        Day: Integer;
        Month: Integer;
    begin
        Day := Date2DMY(DateInPeriod, 1);
        Month := Date2DMY(DateInPeriod, 2);
        VATPeriod.CheckPeriods();
        VATPeriod.SetCurrentKey("Start Month", "Start Day");
        VATPeriod.SetRange("Start Month", 0, Month);
        VATPeriod.SetRange("Start Day", 0, Day);
        VATPeriod.FindLast();
        exit(VATPeriod."Period No.");
    end;

    [Scope('OnPrem')]
    procedure RunCheckNorwegianVAT(GenJnlLine: Record "Gen. Journal Line"; var AllowPostingInClosedVATPeriod: Boolean)
    var
        SettledVATPeriod: Record "Settled VAT Period";
        VATProdPostGrp: Record "VAT Product Posting Group";
        GLSetup: Record "General Ledger Setup";
    begin
        if AllowPostingInClosedVATPeriod then
            AllowPostingInClosedVATPeriod := false
        else
            if SettledVATPeriod.Get(Date2DMY(GenJnlLine."VAT Reporting Date", 3), VATPeriodNo(GenJnlLine."VAT Reporting Date")) then
                if SettledVATPeriod.Closed then
                    GenJnlLine.FieldError("VAT Reporting Date", StrSubstNo(Text005, SettledVATPeriod.Year, SettledVATPeriod."Period No."));

        if GenJnlLine."VAT Base Amount Type" <> GenJnlLine."VAT Base Amount Type"::Automatic then begin
            if (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Purchase) or
               (GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::Purchase)
            then
                GenJnlLine.FieldError("VAT Base Amount Type", StrSubstNo(Text006, GenJnlLine."VAT Base Amount Type"));
            if (GenJnlLine."VAT Amount" <> 0) or (GenJnlLine."Bal. VAT Amount" <> 0) then
                GenJnlLine.FieldError("VAT Base Amount Type", StrSubstNo(Text007, GenJnlLine."VAT Base Amount Type"));
        end;
        // VAT not possible Outside Tax Area
        if GenJnlLine."VAT Prod. Posting Group" <> '' then begin
            VATProdPostGrp.Get(GenJnlLine."VAT Prod. Posting Group");
            if VATProdPostGrp."Outside Tax Area" and (GenJnlLine."VAT Amount" <> 0) then
                GenJnlLine.FieldError("VAT Amount", Text008);
        end;
        if GenJnlLine."Bal. VAT Prod. Posting Group" <> '' then begin
            VATProdPostGrp.Get(GenJnlLine."Bal. VAT Prod. Posting Group");
            if VATProdPostGrp."Outside Tax Area" and (GenJnlLine."Bal. VAT Amount" <> 0) then
                GenJnlLine.FieldError("Bal. VAT Amount", Text008);
        end;
        // VAT other than Reverse Charge is not possible if the company is Not VAT xxx
        GLSetup.Get();
        if GLSetup."Non-Taxable" then begin
            if (GenJnlLine."VAT Amount" <> 0) and (GenJnlLine."VAT Calculation Type" <> GenJnlLine."VAT Calculation Type"::"Reverse Charge VAT") then
                GenJnlLine.FieldError("VAT Amount", StrSubstNo(Text009, GLSetup.FieldCaption("Non-Taxable"), GLSetup.TableCaption()));
            if (GenJnlLine."Bal. VAT Amount" <> 0) and (GenJnlLine."Bal. VAT Calculation Type" <> GenJnlLine."Bal. VAT Calculation Type"::"Reverse Charge VAT") then
                GenJnlLine.FieldError("Bal. VAT Amount", StrSubstNo(Text009, GLSetup.FieldCaption("Non-Taxable"), GLSetup.TableCaption()));
        end;
    end;

    procedure GetVATSpecifications2022(var TempVATSpecification: Record "VAT Specification" temporary)
    begin
        AddTempVATSpecification(TempVATSpecification, GetAdjustmentCode(), AdjustmentDescriptionTxt);
        AddTempVATSpecification(TempVATSpecification, GetLossesOnClaimsSpecificationCode(), LossesOnClaimsDescriptionTxt);
        AddTempVATSpecification(TempVATSpecification, GetReversalInputVATSpecificationCode(), ReversalInputVATDescriptionTxt);
        AddTempVATSpecification(TempVATSpecification, GetWithdrawalSpecificationCode(), WithdrawalsDescriptionTxt);
        AddTempVATSpecification(TempVATSpecification, GoodsTok, GoodsDescriptionTxt);
        AddTempVATSpecification(TempVATSpecification, ServicesTok, ServicesDescriptionTxt);
    end;

    procedure GetVATNotes2022(var TempVATNote: Record "VAT Note" temporary)
    begin
        AddTempVATNote(TempVATNote, NonStandardInvoicingTok, NonStandardInvoicingDescriptionTxt);
        AddTempVATNote(TempVATNote, AccrualsTok, AccrualsDescriptionTxt);
        AddTempVATNote(TempVATNote, PreviouslyUsedVATCodeNotCorrectTok, PreviouslyUsedVATCodeNotCorrectDescrTxt);
        AddTempVATNote(TempVATNote, ErrorsInAccSoftwareTok, ErrorsInAccSoftwareDescrTxt);
        AddTempVATNote(TempVATNote, InsuranceSettlementTok, InsuranceSettlementDescrTxt);
        AddTempVATNote(TempVATNote, TurnoverBeforeRegistrationTok, TurnoverBeforeRegistrationDescrTxt);
        AddTempVATNote(TempVATNote, RecalculationOfReturnsTok, RecalculationOfReturnsDescrTxt);
        AddTempVATNote(TempVATNote, TemporaryImportTok, TemporaryImportDescrTxt);
        AddTempVATNote(TempVATNote, ReimportTok, ReimportDescrTxt);
        AddTempVATNote(TempVATNote, CustDeclUnderIncorrVATRegNumberTok, CustDeclUnderIncorrVATRegNumberDescrTxt);
        AddTempVATNote(TempVATNote, ReexportOfReturnsTok, ReexportOfReturnsDescrTxt);
        AddTempVATNote(TempVATNote, TemporaryExportTok, TemporaryExportDescrTxt);
        AddTempVATNote(TempVATNote, ExportOfServicesTok, ExportOfServicesDescrTxt);
        AddTempVATNote(TempVATNote, LargePurchasesTok, LargePurchasesDescrTxt);
        AddTempVATNote(TempVATNote, CreditNotesTok, CreditNotesDescrTxt);
        AddTempVATNote(TempVATNote, PurchMadeBeforeRegTok, PurchMadeBeforeRegDescrTxt);
        AddTempVATNote(TempVATNote, BuldForOwnExpenseAndRiskTok, BuldForOwnExpenseAndRiskDescrTxt);
        AddTempVATNote(TempVATNote, WithdrawalAfterCessationTok, WithdrawalAfterCessationDescrTxt);
        AddTempVATNote(TempVATNote, GetRealPropertyTok(), RealPropertyDescrTxt);
        AddTempVATNote(TempVATNote, GetPassengerVehicles(), PassengerVehiclesDescrTxt);
        AddTempVATNote(TempVATNote, DemonstrationCarTok, DemonstrationCarDescrTxt);
        AddTempVATNote(TempVATNote, BindingAdvanceRulingTok, BindingAdvanceRulingDescrTxt);
        AddTempVATNote(TempVATNote, EnterpriseUnderLiquidationTok, EnterpriseUnderLiquidationDescrTxt);
        AddTempVATNote(TempVATNote, EnterpriseChangedLegalStructureTok, EnterpriseChangedLegalStructureDescrTxt);
        AddTempVATNote(TempVATNote, DropInRevenueExtrCircTok, DropInRevenueExtrCircDescrTxt);
        AddTempVATNote(TempVATNote, ShipwreckTok, ShipwreckDescrTxt);
        AddTempVATNote(TempVATNote, VATFreeSalesOfFishingVesselTok, VATFreeSalesOfFishingVesselDescrTxt);
    end;

    local procedure AddTempVATNote(var TempVATNote: Record "VAT Note" temporary; Value: Text[50]; Description: Text[250])
    begin
        TempVATNote.Validate(Code, Value);
        TempVATNote.Validate("VAT Report Value", Value);
        TempVATNote.Validate(Description, Description);
        TempVATNote.Insert(true);
    end;

    local procedure AddTempVATSpecification(var TempVATSpecification: Record "VAT Specification" temporary; Value: Text[50]; Description: Text[250])
    begin
        TempVATSpecification.Validate(Code, Value);
        TempVATSpecification.Validate("VAT Report Value", Value);
        TempVATSpecification.Validate(Description, Description);
        TempVATSpecification.Insert(true);
    end;

    local procedure GetWithdrawalSpecificationCode(): Text[50]
    begin
        exit(WithdrawalsTok);
    end;

    local procedure GetReversalInputVATSpecificationCode(): Text[50]
    begin
        exit(ReversalInputVATTok);
    end;

    local procedure GetLossesOnClaimsSpecificationCode(): Text[50]
    begin
        exit(LossesOnClaimsTok);
    end;

    local procedure GetAdjustmentCode(): Text[50]
    begin
        exit(AdjustmentTok);
    end;

    local procedure GetRealPropertyTok(): Text[50]
    begin
        exit(RealPropertyTok);
    end;

    local procedure GetPassengerVehicles(): Text[50]
    begin
        exit(PassengerVehiclesTok);
    end;

    procedure GetVATReportingCodes2022(var TempVATReportingCode: Record "VAT Reporting Code" temporary)
    begin
        AddTempVATReportingCode(TempVATReportingCode, '31U', OutputVATDescriptionTxt, GetWithdrawalSpecificationCode(), '', '31');
        AddTempVATReportingCode(TempVATReportingCode, '33U', OutputVATDescriptionTxt, GetWithdrawalSpecificationCode(), '', '33');
        AddTempVATReportingCode(TempVATReportingCode, '3U', OutputVATDescriptionTxt, GetWithdrawalSpecificationCode(), '', '3');
        AddTempVATReportingCode(TempVATReportingCode, '5U', NoOutputVATDescriptionTxt, GetWithdrawalSpecificationCode(), '', '5');
        AddTempVATReportingCode(TempVATReportingCode, '11U', InputVATDeductDomDescrTxt, GetWithdrawalSpecificationCode(), '', '11');
        AddTempVATReportingCode(TempVATReportingCode, '11T', InputVATDeductDomDescrTxt, GetLossesOnClaimsSpecificationCode(), '', '11');
        AddTempVATReportingCode(TempVATReportingCode, '13T', InputVATDeductDomDescrTxt, GetLossesOnClaimsSpecificationCode(), '', '13');
        AddTempVATReportingCode(TempVATReportingCode, '1T', InputVATDeductDomDescrTxt, GetLossesOnClaimsSpecificationCode(), '', '1');
        AddTempVATReportingCode(TempVATReportingCode, '1J', InputVATDeductDomDescrTxt, GetAdjustmentCode(), '', '1');
        AddTempVATReportingCode(TempVATReportingCode, '1TF', InputVATDeductDomDescrTxt, GetReversalInputVATSpecificationCode(), GetRealPropertyTok(), '1');
        AddTempVATReportingCode(TempVATReportingCode, '1TP', InputVATDeductDomDescrTxt, GetReversalInputVATSpecificationCode(), GetPassengerVehicles(), '1');
        AddTempVATReportingCode(TempVATReportingCode, '81TP', ImportOfGoodsDescrTxt, GetReversalInputVATSpecificationCode(), GetPassengerVehicles(), '81');
        AddTempVATReportingCode(TempVATReportingCode, '12T', InputVATDeductDomDescrTxt, GetLossesOnClaimsSpecificationCode(), '', '12');
    end;

    local procedure AddTempVATReportingCode(var TempVATReportingCode: Record "VAT Reporting Code" temporary; Code: Code[10]; Description: Text[30]; VATSpecificationCode: Code[50]; VATNoteCode: Code[50]; SAFTVATCode: Code[10])
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        if SAFTVATCode <> '' then
            if VATReportingCode.Get(SAFTVATCode) then
                TempVATReportingCode := VATReportingCode
            else
                exit;
        TempVATReportingCode.Validate(Code, Code);
        TempVATReportingCode.Validate(Description, Description);
        TempVATReportingCode.Validate("VAT Specification Code", VATSpecificationCode);
        TempVATReportingCode.Validate("SAF-T VAT Code", SAFTVATCode);
        TempVATReportingCode.Validate("VAT Note Code", VATNoteCode);
        TempVATReportingCode.Insert(true);
    end;
}

