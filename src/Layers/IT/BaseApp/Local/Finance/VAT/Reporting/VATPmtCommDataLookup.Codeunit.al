// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
#if not CLEAN27
using System.Environment.Configuration;
#endif

codeunit 12151 "VAT Pmt. Comm. Data Lookup"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        CompanyOfficials: Record "Company Officials";
        VATReportSetup: Record "VAT Report Setup";
        VATEntry: Record "VAT Entry";
#if not CLEAN27
        LastPeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#endif
        LastPeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
#if not CLEAN27
        FeatureManagementIT: Codeunit "Feature Management IT";
#endif
        TaxDeclarant: Text[16];
        ChargeCode: Text[2];
        YearOfDeclaration: Text[2];
        StartDate: Date;
        DatesInDifferentYearsErr: Label 'The provided dates are in different years.';
        GeneralManagerFound: Boolean;
        IsSigned: Boolean;
        PeriodicSettlementVATEntryFound: Boolean;
        CommitmentSubmission: Option "0","1","2";
        ExceptionalEvents: Option "None","1","9";
        IsIntermediary: Boolean;
        FlagDeviations: Boolean;
        IsSubcontracting: Boolean;
        VATSales: Decimal;
        VATPurchases: Decimal;
        AdvancedAmount, TaxDebitVariationInterest, CreditVATCompensation, PriorYearInputVAT, PriorPeriodInputVAT, PriorPeriodOutputVAT : Decimal;
        MethodOfCalcAdvanced: Option "No advance",Historical,Budgeting,Analytical,"Specific Subjects";
        SpecifyMethodOfCalcAdvancedAmountErr: Label 'You must select a calculation method for advanced amounts.';
        ExtraordinaryOperations: Boolean;
        ModuleNumber: Option ,"1","2","3","4","5";

    [Scope('OnPrem')]
    procedure Init()
    begin
        CompanyInformation.Get();
        GeneralManagerFound := CompanyOfficials.Get(CompanyInformation."General Manager No.");
        VATReportSetup.Get();
        GeneralLedgerSetup.Get();
    end;

    [Scope('OnPrem')]
    procedure GetStartingDate(): Date
    begin
        exit(StartDate);
    end;

    [Scope('OnPrem')]
    procedure SetStartDate(StartingDate: Date)
    var
        StartYear: Integer;
        EndYear: Integer;
        EndDate: Date;
    begin
        StartDate := StartingDate;
        case GeneralLedgerSetup."VAT Settlement Period" of
            GeneralLedgerSetup."VAT Settlement Period"::Month:
                EndDate := CalcDate('<CM>', StartDate);
            GeneralLedgerSetup."VAT Settlement Period"::Quarter:
                EndDate := CalcDate('<CQ>', StartDate);
        end;
        StartYear := Date2DMY(StartDate, 3);
        EndYear := Date2DMY(EndDate, 3);
        if StartYear <> EndYear then
            Error(DatesInDifferentYearsErr);
        VATEntry.SetRange("Operation Occurred Date", StartDate, EndDate);
#if not CLEAN27
        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then
            InitializeValuesFromLastPeriodicVATSettlementEntries(EndDate)
        else
            PeriodicSettlementVATEntryFound :=
            LastPeriodicSettlementVATEntry.Get(GetVATPeriodFromDate(EndDate));
#else
        InitializeValuesFromLastPeriodicVATSettlementEntries(EndDate);
#endif
    end;

    local procedure InitializeValuesFromLastPeriodicVATSettlementEntries(PeriodEndDate: Date)
    begin
        AdvancedAmount := 0;
        TaxDebitVariationInterest := 0;
        CreditVATCompensation := 0;
        PriorYearInputVAT := 0;
        PriorPeriodInputVAT := 0;
        PriorPeriodOutputVAT := 0;
        PeriodicSettlementVATEntryFound := false;
        LastPeriodicVATSettlementEntry.SetRange("VAT Period", GetVATPeriodFromDate(PeriodEndDate));
        if LastPeriodicVATSettlementEntry.FindSet() then
            repeat
                PeriodicSettlementVATEntryFound := true;
                AdvancedAmount += LastPeriodicVATSettlementEntry."Advanced Amount";
                TaxDebitVariationInterest += LastPeriodicVATSettlementEntry."Tax Debit Variation Interest";
                CreditVATCompensation += LastPeriodicVATSettlementEntry."Credit VAT Compensation";
                PriorYearInputVAT += LastPeriodicVATSettlementEntry."Prior Year Input VAT";
                PriorPeriodInputVAT += LastPeriodicVATSettlementEntry."Prior Period Input VAT";
                PriorPeriodOutputVAT += LastPeriodicVATSettlementEntry."Prior Period Output VAT";
            until LastPeriodicVATSettlementEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SetYearOfDeclaration(YearOfDecl: Integer)
    begin
        if YearOfDecl < 10 then
            YearOfDeclaration := StrSubstNo('0%1', YearOfDecl)
        else
            YearOfDeclaration := Format(YearOfDecl);
    end;

    [Scope('OnPrem')]
    procedure GetSupplyCode(): Text[5]
    begin
        exit(StrSubstNo('IVP%1', YearOfDeclaration));
    end;

    [Scope('OnPrem')]
    procedure SetTaxDeclarant(Value: Text[16])
    begin
        TaxDeclarant := Value;
    end;

    [Scope('OnPrem')]
    procedure HasTaxDeclarant(): Boolean
    begin
        exit(TaxDeclarant <> '');
    end;

    [Scope('OnPrem')]
    procedure GetTaxDeclarant(): Text[16]
    begin
        exit(TaxDeclarant);
    end;

    [Scope('OnPrem')]
    procedure SetChargeCode(Value: Text[2])
    begin
        ChargeCode := Value;
    end;

    [Scope('OnPrem')]
    procedure HasChargeCode(): Boolean
    begin
        exit(HasTaxDeclarant());
    end;

    [Scope('OnPrem')]
    procedure GetChargeCode(): Text[2]
    begin
        exit(ChargeCode);
    end;

    [Scope('OnPrem')]
    procedure GetSystemID(): Text[16]
    begin
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetCommunicationID(): Text[5]
    begin
        VATReportSetup."Spesometro Communication ID" += 1;
        VATReportSetup.Modify();
        exit(FormatCommunicationId(VATReportSetup."Spesometro Communication ID"));
    end;

    [Scope('OnPrem')]
    procedure FormatCommunicationId(Id: Integer): Text[5]
    begin
        exit(PadStr('', 5 - StrLen(Format(Id)), '0') + Format(Id));
    end;

    [Scope('OnPrem')]
    procedure GetFiscalCode(): Code[16]
    begin
        exit(Truncate(CompanyInformation."Fiscal Code", 16));
    end;

    [Scope('OnPrem')]
    procedure GetCurrentYear(): Text[4]
    begin
        exit(Format(Date2DMY(StartDate, 3), 0, 9));
    end;

    [Scope('OnPrem')]
    procedure GetVATRegistrationNo(): Text[11]
    begin
        exit(Truncate(CompanyInformation."VAT Registration No.", 11));
    end;

    [Scope('OnPrem')]
    procedure GetTaxDeclarantVATNo(): Text[16]
    begin
        if not GeneralManagerFound then
            exit('');
        exit(Truncate(CompanyOfficials."Fiscal Code", 16));
    end;

    [Scope('OnPrem')]
    procedure GetTaxDeclarantPosionCode(): Text[2]
    begin
        if not GeneralManagerFound then
            exit('');
        exit(CompanyOfficials."Appointment Code");
    end;

    [Scope('OnPrem')]
    procedure GetDeclarantFiscalCode(): Text[11]
    begin
        exit(Truncate(CompanyInformation."Fiscal Code", 16));
    end;

    [Scope('OnPrem')]
    procedure SetIsSigned(Value: Boolean)
    begin
        IsSigned := Value;
    end;

    [Scope('OnPrem')]
    procedure GetIsSigned(): Text[1]
    begin
        if IsSigned then
            exit('1');
        exit('0');
    end;

    [Scope('OnPrem')]
    procedure HasIntermediary(): Boolean
    begin
        exit(VATReportSetup."Intermediary VAT Reg. No." <> '');
    end;

    [Scope('OnPrem')]
    procedure GetIntermediary(): Text[16]
    begin
        exit(Truncate(VATReportSetup."Intermediary VAT Reg. No.", 16));
    end;

    [Scope('OnPrem')]
    procedure SetCommitmentSubmission(Value: Option)
    begin
        CommitmentSubmission := Value;
    end;

    [Scope('OnPrem')]
    procedure HasCommitmentSubmission(): Boolean
    begin
        exit(CommitmentSubmission <> CommitmentSubmission::"0");
    end;

    [Scope('OnPrem')]
    procedure GetCommitmentSubmission(): Text[1]
    begin
        exit(Format(CommitmentSubmission, 0, 9));
    end;

    [Scope('OnPrem')]
    procedure GetIntermediaryDate(): Text[8]
    begin
        exit(Format(VATReportSetup."Intermediary Date", 0, '<Day,2><Month,2><Year4>'));
    end;

    [Scope('OnPrem')]
    procedure SetIsIntermediary(Value: Boolean)
    begin
        IsIntermediary := Value;
    end;

    [Scope('OnPrem')]
    procedure WasIntermediarySet(): Boolean
    begin
        exit(IsIntermediary);
    end;

    [Scope('OnPrem')]
    procedure GetIsIntermediary(): Text[1]
    begin
        if IsIntermediary then
            exit('1');
        exit('0');
    end;

    [Scope('OnPrem')]
    procedure SetFlagDeviations(Value: Boolean)
    begin
        FlagDeviations := Value;
    end;

    [Scope('OnPrem')]
    procedure GetFlagDeviations(): Text[1]
    begin
        if FlagDeviations then
            exit('1');
        exit('0');
    end;

    [Scope('OnPrem')]
    procedure GetSoftware(): Text
    begin
        exit('MICROSOFT NAV');
    end;

    [Scope('OnPrem')]
    procedure GetQuarter(): Text[1]
    begin
        exit(Format(StartDate, 0, '<Quarter>'));
    end;

    [Scope('OnPrem')]
    procedure GetMonth(): Text[2]
    begin
        exit(Format(StartDate, 0, '<Month>'));
    end;

    [Scope('OnPrem')]
    procedure SetMethodOfCalcAdvanced(Value: Option)
    begin
        MethodOfCalcAdvanced := Value;
    end;

    [Scope('OnPrem')]
    procedure GetMethodOfCalcAdvancedNo(): Integer
    begin
        if MethodOfCalcAdvanced = MethodOfCalcAdvanced::"No advance" then
            Error(SpecifyMethodOfCalcAdvancedAmountErr);
        exit(MethodOfCalcAdvanced);
    end;

    [Scope('OnPrem')]
    procedure HasSubcontracting(): Boolean
    begin
        exit(GetSubcontracting() = '1');
    end;

    [Scope('OnPrem')]
    procedure SetSubcontracting(Value: Boolean)
    begin
        IsSubcontracting := Value;
    end;

    [Scope('OnPrem')]
    procedure GetSubcontracting(): Text[1]
    begin
        if IsSubcontracting then
            exit('1');
        exit('0');
    end;

    [Scope('OnPrem')]
    procedure SetExceptions(Value: Option)
    begin
        ExceptionalEvents := Value;
    end;

    [Scope('OnPrem')]
    procedure HasExceptionalEvents(): Boolean
    begin
        exit(ExceptionalEvents <> ExceptionalEvents::None);
    end;

    [Scope('OnPrem')]
    procedure GetExceptionalEvents(): Text[1]
    begin
        exit(Format(ExceptionalEvents, 0, 9));
    end;

    [Scope('OnPrem')]
    procedure SetExtraordinaryOperations(Value: Boolean)
    begin
        ExtraordinaryOperations := Value;
    end;

    [Scope('OnPrem')]
    procedure GetExtraordinaryOperations(): Text[1]
    begin
        if ExtraordinaryOperations then
            exit('1');
        exit('0');
    end;

    [Scope('OnPrem')]
    procedure SetModuleNumber(Value: Option)
    begin
        ModuleNumber := Value;
    end;

    [Scope('OnPrem')]
    procedure GetModuleNumber() NumeroModulo: Integer
    begin
        NumeroModulo := ModuleNumber;
        ModuleNumber += 1;
    end;

    [Scope('OnPrem')]
    procedure GetTotalSales() TotalSales: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Include in VAT Comm. Rep.", true);
        if VATPostingSetup.FindSet() then begin
            VATEntry.SetRange(Type, VATEntry.Type::Sale);
            VATEntry.SetFilter(
              "VAT Calculation Type", '<>%1&<>%2',
              VATEntry."VAT Calculation Type"::"Reverse Charge VAT", VATEntry."VAT Calculation Type"::"Full VAT");
            OnGetTotalSalesOnAfterVATEntrySetFilters(VATEntry);
            repeat
                VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
                VATEntry.CalcSums(Base);
                TotalSales -= VATEntry.Base;
            until VATPostingSetup.Next() = 0;
            VATEntry.SetRange("VAT Bus. Posting Group");
            VATEntry.SetRange("VAT Prod. Posting Group");
            VATEntry.SetRange(Type);
            VATEntry.SetRange("VAT Calculation Type");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTotalPurchases() TotalPurchases: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Include in VAT Comm. Rep.", true);
        if VATPostingSetup.FindSet() then begin
            VATEntry.SetRange(Type, VATEntry.Type::Purchase);
            VATEntry.SetFilter("VAT Calculation Type", '<>%1', VATEntry."VAT Calculation Type"::"Full VAT");
            OnGetTotalPurchasesOnAfterVATEntrySetFilters(VATEntry);
            repeat
                VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
                VATEntry.CalcSums(Base, "Nondeductible Base");
                TotalPurchases += VATEntry.Base + VATEntry."Nondeductible Base";
            until VATPostingSetup.Next() = 0;
            VATEntry.SetRange("VAT Bus. Posting Group");
            VATEntry.SetRange("VAT Prod. Posting Group");
            VATEntry.SetRange("VAT Calculation Type");
            VATEntry.SetRange(Type);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVATSales(): Decimal
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        OnGetVATSalesOnAfterVATEntrySetFilters(VATEntry);
        VATEntry.CalcSums(Amount);
        VATSales := -VATEntry.Amount;
        VATEntry.SetRange(Type);
        exit(VATSales);
    end;

    [Scope('OnPrem')]
    procedure GetVATPurchases(): Decimal
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        OnGetVATPurchasesOnAfterVATEntrySetFilters(VATEntry);
        VATEntry.CalcSums(Amount);
        VATPurchases := VATEntry.Amount;
        VATEntry.SetRange(Type);
#if not CLEAN27
        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then
            OnAfterGetVATPurchases(LastPeriodicVATSettlementEntry, PeriodicSettlementVATEntryFound, VATPurchases)
        else
            OnGetVATPurchasesOnBeforeExit(LastPeriodicSettlementVATEntry, PeriodicSettlementVATEntryFound, VATPurchases);
#else
        OnAfterGetVATPurchases(LastPeriodicVATSettlementEntry, PeriodicSettlementVATEntryFound, VATPurchases);
#endif
        exit(VATPurchases);
    end;

    [Scope('OnPrem')]
    procedure HasVATDebit(): Boolean
    begin
        exit((VATSales - VATPurchases) > 0);
    end;

    [Scope('OnPrem')]
    procedure GetVATDebit(): Decimal
    begin
        if HasVATDebit() then
            exit(VATSales - VATPurchases);
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure HasVATCredit(): Boolean
    begin
        exit(not HasVATDebit());
    end;

    [Scope('OnPrem')]
    procedure GetVATCredit(): Decimal
    begin
        if HasVATCredit() then
            exit(VATPurchases - VATSales);
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetPeriodVATDebit(): Decimal
    begin
#if not CLEAN27
        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then begin
            if not PeriodicSettlementVATEntryFound then
                exit(0);
            exit(PriorPeriodOutputVAT)
        end else
            if PeriodicSettlementVATEntryFound then
                exit(LastPeriodicSettlementVATEntry."Prior Period Output VAT");
#else
        if not PeriodicSettlementVATEntryFound then
            exit(0);
        exit(PriorPeriodOutputVAT);
#endif
    end;

    [Scope('OnPrem')]
    procedure GetPeriodVATCredit(): Decimal
    begin
#if not CLEAN27
        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then begin
            if not PeriodicSettlementVATEntryFound then
                exit(0);
            exit(PriorPeriodInputVAT)
        end else
            if PeriodicSettlementVATEntryFound then
                exit(LastPeriodicSettlementVATEntry."Prior Period Input VAT");
#else
        if not PeriodicSettlementVATEntryFound then
            exit(0);
        exit(PriorPeriodInputVAT);
#endif
    end;

    [Scope('OnPrem')]
    procedure GetAnnualVATCredit(): Decimal
    begin
#if not CLEAN27
        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then begin
            if not PeriodicSettlementVATEntryFound then
                exit(0);
            exit(PriorYearInputVAT)
        end else
            if PeriodicSettlementVATEntryFound then
                exit(LastPeriodicSettlementVATEntry."Prior Year Input VAT");
#else
        if not PeriodicSettlementVATEntryFound then
            exit(0);
        exit(PriorYearInputVAT);
#endif
    end;

    [Scope('OnPrem')]
    procedure GetCreditVATCompensation(): Decimal
    begin
#if not CLEAN27
        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then begin
            if not PeriodicSettlementVATEntryFound then
                exit(0);
            exit(CreditVATCompensation)
        end else
            if PeriodicSettlementVATEntryFound then
                exit(LastPeriodicSettlementVATEntry."Credit VAT Compensation");
#else
        if not PeriodicSettlementVATEntryFound then
            exit(0);
        exit(CreditVATCompensation);
#endif
    end;

    [Scope('OnPrem')]
    procedure GetTaxDebitVariationInterest(): Decimal
    begin
#if not CLEAN27
        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then begin
            if not PeriodicSettlementVATEntryFound then
                exit(0);
            exit(TaxDebitVariationInterest);
        end else
            if PeriodicSettlementVATEntryFound then
                exit(LastPeriodicSettlementVATEntry."Tax Debit Variation Interest");
#else
        if not PeriodicSettlementVATEntryFound then
            exit(0);
        exit(TaxDebitVariationInterest);
#endif
    end;

    [Scope('OnPrem')]
    procedure GetAdvancedTaxAmount(): Decimal
    begin
#if not CLEAN27
        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then begin
            if not PeriodicSettlementVATEntryFound then
                exit(0);
            exit(AdvancedAmount)
        end else
            if PeriodicSettlementVATEntryFound then
                exit(LastPeriodicSettlementVATEntry."Advanced Amount");
#else
        if not PeriodicSettlementVATEntryFound then
            exit(0);
        exit(AdvancedAmount);
#endif
    end;

    local procedure GetTotalCalculation(): Decimal
    begin
        exit(GetVATDebit() - GetVATCredit() + GetPeriodVATDebit() +
          GetTaxDebitVariationInterest() - (GetCreditVATCompensation() + GetPeriodVATCredit() +
                                          GetAnnualVATCredit() + GetAdvancedTaxAmount()));
    end;

    [Scope('OnPrem')]
    procedure HasTaxDebit(): Boolean
    begin
        exit(GetTotalCalculation() > 0);
    end;

    [Scope('OnPrem')]
    procedure GetTaxDebit(): Decimal
    begin
        exit(GetTotalCalculation());
    end;

    [Scope('OnPrem')]
    procedure HasTexCredit(): Boolean
    begin
        exit(not HasTaxDebit());
    end;

    [Scope('OnPrem')]
    procedure GetTexCredit(): Decimal
    begin
        exit(-GetTotalCalculation());
    end;

    local procedure Truncate(Text: Text; MaxLength: Integer): Text
    begin
        if StrLen(Text) > MaxLength then
            exit(CopyStr(Text, 1, MaxLength));
        exit(Text);
    end;

    local procedure GetVATPeriodFromDate(GivenDate: Date): Code[10]
    begin
        exit(Format(Date2DMY(GivenDate, 3)) + '/' +
          ConvertStr(Format(Date2DMY(GivenDate, 2), 2), ' ', '0'));
    end;
#if not CLEAN27
    [IntegrationEvent(false, false)]
    [Obsolete('This event is obsolete. Use OnAfterGetVATPurchases instead.', '27.0')]
    local procedure OnGetVATPurchasesOnBeforeExit(LastPeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry"; PeriodicSettlementVATEntryFound: Boolean; var VATPurchases: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPurchases(LastPeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry"; PeriodicSettlementVATEntryFound: Boolean; var VATPurchases: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTotalPurchasesOnAfterVATEntrySetFilters(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTotalSalesOnAfterVATEntrySetFilters(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVATPurchasesOnAfterVATEntrySetFilters(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVATSalesOnAfterVATEntrySetFilters(var VATEntry: Record "VAT Entry")
    begin
    end;
}

