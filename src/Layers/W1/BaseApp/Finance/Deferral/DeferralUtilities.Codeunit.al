// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Security.User;

/// <summary>
/// Central utility functions for deferral processing including schedule creation, calculation methods, and posting operations.
/// Handles all core deferral business logic and integrates with various document types and posting routines.
/// </summary>
codeunit 1720 "Deferral Utilities"
{

    trigger OnRun()
    begin
    end;

    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        AmountRoundingPrecision: Decimal;
        InvalidPostingDateErr: Label '%1 is not within the range of posting dates for your company.', Comment = '%1=The date passed in for the posting date.';
        DeferSchedOutOfBoundsErr: Label 'The deferral schedule falls outside the accounting periods that have been set up for the company.';
        SelectDeferralCodeMsg: Label 'A deferral code must be selected for the line to view the deferral schedule.';
        DescriptionTok: Label '%1-%2', Locked = true;

    /// <summary>
    /// Creates a period-specific description by substituting placeholders with actual date values.
    /// Supports day, week, month, month text, accounting period name, and year placeholders.
    /// </summary>
    /// <param name="PostingDate">The posting date to extract date components from</param>
    /// <param name="Description">Template description with placeholders (%1=Day, %2=Week, %3=Month, %4=Month Text, %5=Period Name, %6=Year)</param>
    /// <returns>Final description with placeholders replaced by actual values</returns>
    procedure CreateRecurringDescription(PostingDate: Date; Description: Text[100]) FinalDescription: Text[100]
    var
        AccountingPeriod: Record "Accounting Period";
        Day: Integer;
        Week: Integer;
        Month: Integer;
        Year: Integer;
        MonthText: Text[30];
    begin
        Day := Date2DMY(PostingDate, 1);
        Week := Date2DWY(PostingDate, 2);
        Month := Date2DMY(PostingDate, 2);
        MonthText := Format(PostingDate, 0, '<Month Text>');
        Year := Date2DMY(PostingDate, 3);
        if IsAccountingPeriodExist(AccountingPeriod, PostingDate) then begin
            AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
            if not AccountingPeriod.FindLast() then
                AccountingPeriod.Name := '';
        end;
        FinalDescription :=
          CopyStr(StrSubstNo(Description, Day, Week, Month, MonthText, AccountingPeriod.Name, Year), 1, MaxStrLen(Description));
    end;

    /// <summary>
    /// Creates a complete deferral schedule based on the specified parameters and calculation method.
    /// Generates header and line records with amounts distributed according to the selected calculation method.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code defining calculation parameters</param>
    /// <param name="DeferralDocType">Type of source document (Purchase, Sales, G/L)</param>
    /// <param name="GenJnlTemplateName">General Journal Template name for G/L deferrals</param>
    /// <param name="GenJnlBatchName">General Journal Batch name for G/L deferrals</param>
    /// <param name="DocumentType">Document type ID from the source document</param>
    /// <param name="DocumentNo">Document number from the source document</param>
    /// <param name="LineNo">Line number within the source document</param>
    /// <param name="AmountToDefer">Total amount to be deferred</param>
    /// <param name="CalcMethod">Method for calculating period amounts (Straight-Line, Equal per Period, etc.)</param>
    /// <param name="StartDate">Date to start the deferral schedule</param>
    /// <param name="NoOfPeriods">Number of periods to distribute the deferral over</param>
    /// <param name="ApplyDeferralPercentage">Whether to apply the deferral percentage from the template</param>
    /// <param name="DeferralDescription">Description for the deferral schedule</param>
    /// <param name="AdjustStartDate">Whether to adjust start date based on template settings</param>
    /// <param name="CurrencyCode">Currency code for foreign currency handling</param>
    procedure CreateDeferralSchedule(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; AmountToDefer: Decimal; CalcMethod: Enum "Deferral Calculation Method"; StartDate: Date; NoOfPeriods: Integer; ApplyDeferralPercentage: Boolean; DeferralDescription: Text[100]; AdjustStartDate: Boolean; CurrencyCode: Code[10])
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralLineAmount: Dictionary of [RecordId, Decimal];
        AdjustedStartDate: Date;
        AdjustedDeferralAmount: Decimal;
        TotalDeferralLineAmount: Decimal;
        IsHandled: Boolean;
        RedistributeDeferralSchedule: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDeferralSchedule(
            DeferralCode, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, AmountToDefer, CalcMethod,
            StartDate, NoOfPeriods, ApplyDeferralPercentage, DeferralDescription, AdjustStartDate, CurrencyCode, IsHandled, RedistributeDeferralSchedule);
        if IsHandled then
            exit;

        InitCurrency(CurrencyCode);
        DeferralTemplate.Get(DeferralCode);
        // "Start Date" passed in needs to be adjusted based on the Deferral Code's Start Date setting
        if AdjustStartDate then
            AdjustedStartDate := SetStartDate(DeferralTemplate, StartDate)
        else
            AdjustedStartDate := StartDate;

        AdjustedDeferralAmount := AmountToDefer;
        if ApplyDeferralPercentage then
            AdjustedDeferralAmount := Round(AdjustedDeferralAmount * (DeferralTemplate."Deferral %" / 100), AmountRoundingPrecision);

        if RedistributeDeferralSchedule then
            SaveUserDefinedDeferralLineAmounts(
                DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType,
                DocumentNo, LineNo, CalcMethod, DeferralLineAmount, TotalDeferralLineAmount);

        SetDeferralRecords(
            DeferralHeader, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo,
            CalcMethod, NoOfPeriods, AdjustedDeferralAmount, AdjustedStartDate,
            DeferralCode, DeferralDescription, AmountToDefer, AdjustStartDate, CurrencyCode);

        case CalcMethod of
            CalcMethod::"Straight-Line":
                CalculateStraightline(DeferralHeader, DeferralLine, DeferralTemplate);
            CalcMethod::"Equal per Period":
                CalculateEqualPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
            CalcMethod::"Days per Period":
                CalculateDaysPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
            CalcMethod::"User-Defined":
                CalculateUserDefined(DeferralHeader, DeferralLine, DeferralTemplate);
            else
                OnCreateDeferralScheduleOnCalcMethodElse(CalcMethod, DeferralHeader, DeferralLine, DeferralTemplate);
        end;

        if RedistributeDeferralSchedule then
            RedistributeDeferralLines(DeferralLine, DeferralLineAmount, DeferralHeader, TotalDeferralLineAmount);
        OnAfterCreateDeferralSchedule(DeferralHeader, DeferralLine, DeferralTemplate, CalcMethod);
    end;

    local procedure SaveUserDefinedDeferralLineAmounts(DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; CalcMethod: Enum "Deferral Calculation Method"; var DeferralLineAmount: Dictionary of [RecordId, Decimal]; var TotalDeferralLineAmount: Decimal)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        if CalcMethod <> CalcMethod::"User-Defined" then
            exit;

        if not DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then
            exit;

        FilterDeferralLines(DeferralLine, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
        DeferralLine.SetFilter(Amount, '<>0');
        if DeferralLine.IsEmpty() then
            exit;

        Clear(DeferralLineAmount);
        SaveDeferralLineAmounts(DeferralLine, DeferralLineAmount);
        DeferralLine.CalcSums(Amount);
        TotalDeferralLineAmount := DeferralLine.Amount;
    end;

    local procedure SaveDeferralLineAmounts(var DeferralLine: Record "Deferral Line"; var DeferralLineAmount: Dictionary of [RecordId, Decimal])
    begin
        if DeferralLine.FindSet() then
            repeat
                DeferralLineAmount.Add(DeferralLine.RecordId, DeferralLine.Amount);
            until DeferralLine.Next() = 0;
    end;

    local procedure RedistributeDeferralLines(var DeferralLine: Record "Deferral Line"; DeferralLineAmount: Dictionary of [RecordId, Decimal]; DeferralHeader: Record "Deferral Header"; InitialAmountToDefer: Decimal)
    var
        InitialDeferralLineAmount: Decimal;
        TotalDeferralLineAmount: Decimal;
    begin
        if DeferralLineAmount.Count = 0 then
            exit;

        FilterDeferralLines(DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(), DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name", DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
        if DeferralLine.FindSet(true) then
            repeat
                if DeferralLineAmount.ContainsKey(DeferralLine.RecordId) then begin
                    InitialDeferralLineAmount := DeferralLineAmount.Get(DeferralLine.RecordId);
                    DeferralLine.Validate(Amount, Round(DeferralHeader."Amount to Defer" / InitialAmountToDefer * InitialDeferralLineAmount, AmountRoundingPrecision));
                    DeferralLine.Modify(true);
                    TotalDeferralLineAmount += DeferralLine.Amount;
                end;
            until DeferralLine.Next() = 0;

        if TotalDeferralLineAmount = DeferralHeader."Amount to Defer" then
            exit;
        DeferralLine.Validate(Amount, DeferralLine.Amount + DeferralHeader."Amount to Defer" - TotalDeferralLineAmount);
        DeferralLine.Modify(true);
    end;

    /// <summary>
    /// Calculates the actual number of deferral periods based on the calculation method and parameters.
    /// For user-defined methods, returns the number of existing deferral lines instead of the parameter value.
    /// </summary>
    /// <param name="CalcMethod">Calculation method (Straight-Line, Equal per Period, Days per Period, User-Defined)</param>
    /// <param name="NoOfPeriods">Number of periods specified in the deferral setup</param>
    /// <param name="StartDate">Start date for the deferral schedule</param>
    /// <returns>Actual number of periods that will be created for the deferral schedule</returns>
    procedure CalcDeferralNoOfPeriods(CalcMethod: Enum "Deferral Calculation Method"; NoOfPeriods: Integer; StartDate: Date): Integer
    var
        DeferralTemplate: Record "Deferral Template";
        AccountingPeriod: Record "Accounting Period";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcDeferralNoOfPeriods(CalcMethod, NoOfPeriods, StartDate, IsHandled);
        if IsHandled then
            exit(NoOfPeriods);

        case CalcMethod of
            DeferralTemplate."Calc. Method"::"Equal per Period",
          DeferralTemplate."Calc. Method"::"User-Defined":
                exit(NoOfPeriods);
            DeferralTemplate."Calc. Method"::"Straight-Line",
            DeferralTemplate."Calc. Method"::"Days per Period":
                begin
                    if IsAccountingPeriodExist(AccountingPeriod, StartDate) then begin
                        AccountingPeriod.SetFilter("Starting Date", '>=%1', StartDate);
                        AccountingPeriod.FindFirst();
                    end;
                    if AccountingPeriod."Starting Date" = StartDate then
                        exit(NoOfPeriods);

                    exit(NoOfPeriods + 1);
                end;
        end;

        DeferralTemplate."Calc. Method" := CalcMethod;
        DeferralTemplate.FieldError("Calc. Method");
    end;

    local procedure CalculateStraightline(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    var
        AccountingPeriod: Record "Accounting Period";
        AmountToDefer: Decimal;
        AmountToDeferFirstPeriod: Decimal;
        FractionOfPeriod: Decimal;
        PeriodicDeferralAmount: Decimal;
        RunningDeferralTotal: Decimal;
        PeriodicCount: Integer;
        HowManyDaysLeftInPeriod: Integer;
        NumberOfDaysInPeriod: Integer;
        PostDate: Date;
        FirstPeriodDate: Date;
        SecondPeriodDate: Date;
        PerDiffSum: Decimal;
        IsHandled: Boolean;
    begin
        // If the Start Date passed in matches the first date of a financial period, this is essentially the same
        // as the "Equal Per Period" deferral method, so call that function.
        OnBeforeCalculateStraightline(DeferralHeader, DeferralLine, DeferralTemplate);

        if IsAccountingPeriodExist(AccountingPeriod, DeferralHeader."Start Date") then begin
            AccountingPeriod.SetFilter("Starting Date", '>=%1', DeferralHeader."Start Date");
            if not AccountingPeriod.FindFirst() then
                Error(DeferSchedOutOfBoundsErr);
        end;

        IsHandled := false;
        OnCalculateStraightlineOnBeforeCalcPeriodicDeferralAmount(DeferralHeader, PeriodicDeferralAmount, AmountRoundingPrecision, IsHandled);
        if not IsHandled then begin
            if AccountingPeriod."Starting Date" = DeferralHeader."Start Date" then begin
                CalculateEqualPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
                exit;
            end;

            PeriodicDeferralAmount := Round(DeferralHeader."Amount to Defer" / DeferralHeader."No. of Periods", AmountRoundingPrecision);
        end;

        for PeriodicCount := 1 to (DeferralHeader."No. of Periods" + 1) do begin
            InitializeDeferralHeaderAndSetPostDate(DeferralLine, DeferralHeader, PeriodicCount, PostDate);

            if (PeriodicCount = 1) or (PeriodicCount = (DeferralHeader."No. of Periods" + 1)) then begin
                if PeriodicCount = 1 then begin
                    Clear(RunningDeferralTotal);

                    // Get the starting date of the accounting period of the posting date is in
                    FirstPeriodDate := GetPeriodStartingDate(PostDate);

                    // Get the starting date of the next accounting period
                    SecondPeriodDate := GetNextPeriodStartingDate(PostDate);
                    OnCalculateStraightlineOnAfterCalcSecondPeriodDate(DeferralHeader, PostDate, FirstPeriodDate, SecondPeriodDate);

                    HowManyDaysLeftInPeriod := (SecondPeriodDate - DeferralHeader."Start Date");
                    NumberOfDaysInPeriod := (SecondPeriodDate - FirstPeriodDate);
                    FractionOfPeriod := (HowManyDaysLeftInPeriod / NumberOfDaysInPeriod);

                    AmountToDeferFirstPeriod := (PeriodicDeferralAmount * FractionOfPeriod);
                    AmountToDefer := Round(AmountToDeferFirstPeriod, AmountRoundingPrecision);
                    RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
                end else
                    // Last period
                    AmountToDefer := (DeferralHeader."Amount to Defer" - RunningDeferralTotal);
            end else begin
                AmountToDefer := Round(PeriodicDeferralAmount, AmountRoundingPrecision);
                RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
            end;

            DeferralLine."Posting Date" := PostDate;
            UpdateDeferralLineDescription(DeferralLine, DeferralHeader, DeferralTemplate, PostDate);

            CheckPostingDate(DeferralHeader, DeferralLine);

            PerDiffSum := PerDiffSum + Round(AmountToDefer / DeferralHeader."No. of Periods", AmountRoundingPrecision);

            DeferralLine.Amount := AmountToDefer;
            OnCalculateStraightlineOnBeforeDeferralLineInsert(DeferralLine, DeferralHeader);
            DeferralLine.Insert();
        end;

        OnAfterCalculateStraightline(DeferralHeader, DeferralLine, DeferralTemplate);
    end;

    local procedure CheckPostingDate(DeferralHeader: Record "Deferral Header"; DeferralLine: Record "Deferral Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDate(DeferralHeader, DeferralLine, IsHandled);
        if IsHandled then
            exit;

        if GenJournalBatch.Get(DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name") then
            GenJnlCheckLine.SetGenJnlBatch(GenJournalBatch);
        if GenJnlCheckLine.DeferralPostingDateNotAllowed(DeferralLine."Posting Date") then
            Error(InvalidPostingDateErr, DeferralLine."Posting Date");
    end;

    local procedure CalculateEqualPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    var
        PeriodicCount: Integer;
        PostDate: Date;
        AmountToDefer: Decimal;
        RunningDeferralTotal: Decimal;
    begin
        OnBeforeCalculateEqualPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);

        for PeriodicCount := 1 to DeferralHeader."No. of Periods" do begin
            InitializeDeferralHeaderAndSetPostDate(DeferralLine, DeferralHeader, PeriodicCount, PostDate);

            DeferralLine.Validate("Posting Date", PostDate);
            UpdateDeferralLineDescription(DeferralLine, DeferralHeader, DeferralTemplate, PostDate);

            AmountToDefer := DeferralHeader."Amount to Defer";
            if PeriodicCount = 1 then
                Clear(RunningDeferralTotal);

            if PeriodicCount <> DeferralHeader."No. of Periods" then begin
                AmountToDefer := Round(AmountToDefer / DeferralHeader."No. of Periods", AmountRoundingPrecision);
                RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
            end else
                AmountToDefer := (DeferralHeader."Amount to Defer" - RunningDeferralTotal);

            DeferralLine.Amount := AmountToDefer;
            OnCalculateEqualPerPeriodOnBeforeDeferralLineInsert(DeferralHeader, DeferralLine);
            DeferralLine.Insert();
        end;

        OnAfterCalculateEqualPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
    end;

    local procedure CalculateDaysPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    var
        AccountingPeriod: Record "Accounting Period";
        AmountToDefer: Decimal;
        PeriodicCount: Integer;
        NumberOfDaysInPeriod: Integer;
        NumberOfDaysInSchedule: Integer;
        NumberOfDaysIntoCurrentPeriod: Integer;
        NumberOfPeriods: Integer;
        PostDate: Date;
        FirstPeriodDate: Date;
        SecondPeriodDate: Date;
        EndDate: Date;
        TempDate: Date;
        NoExtraPeriod: Boolean;
        DailyDeferralAmount: Decimal;
        RunningDeferralTotal: Decimal;
    begin
        OnBeforeCalculateDaysPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);

        if IsAccountingPeriodExist(AccountingPeriod, DeferralHeader."Start Date") then begin
            AccountingPeriod.SetFilter("Starting Date", '>=%1', DeferralHeader."Start Date");
            if not AccountingPeriod.FindFirst() then
                Error(DeferSchedOutOfBoundsErr);
        end;
        if AccountingPeriod."Starting Date" = DeferralHeader."Start Date" then
            NoExtraPeriod := true
        else
            NoExtraPeriod := false;

        // If comparison used <=, it messes up the calculations
        if not NoExtraPeriod then begin
            if IsAccountingPeriodExist(AccountingPeriod, DeferralHeader."Start Date") then begin
                AccountingPeriod.SetFilter("Starting Date", '<%1', DeferralHeader."Start Date");
                AccountingPeriod.FindLast();
            end;
            NumberOfDaysIntoCurrentPeriod := (DeferralHeader."Start Date" - AccountingPeriod."Starting Date");
        end else
            NumberOfDaysIntoCurrentPeriod := 0;

        if NoExtraPeriod then
            NumberOfPeriods := DeferralHeader."No. of Periods"
        else
            NumberOfPeriods := (DeferralHeader."No. of Periods" + 1);

        for PeriodicCount := 1 to NumberOfPeriods do begin
            // Figure out the end date...
            if PeriodicCount = 1 then
                TempDate := DeferralHeader."Start Date";

            if PeriodicCount <> NumberOfPeriods then
                TempDate := GetNextPeriodStartingDate(TempDate)
            else
                // Last Period, special case here...
                if NoExtraPeriod then begin
                    TempDate := GetNextPeriodStartingDate(TempDate);
                    EndDate := TempDate;
                end else
                    EndDate := (TempDate + NumberOfDaysIntoCurrentPeriod);
        end;
        OnCalculateDaysPerPeriodOnAfterCalcEndDate(DeferralHeader, DeferralLine, DeferralTemplate, EndDate);

        NumberOfDaysInSchedule := (EndDate - DeferralHeader."Start Date");
        DailyDeferralAmount := (DeferralHeader."Amount to Defer" / NumberOfDaysInSchedule);

        for PeriodicCount := 1 to NumberOfPeriods do begin
            InitializeDeferralHeaderAndSetPostDate(DeferralLine, DeferralHeader, PeriodicCount, PostDate);

            if PeriodicCount = 1 then begin
                Clear(RunningDeferralTotal);
                FirstPeriodDate := DeferralHeader."Start Date";

                // Get the starting date of the next accounting period
                SecondPeriodDate := GetNextPeriodStartingDate(PostDate);
                NumberOfDaysInPeriod := (SecondPeriodDate - FirstPeriodDate);

                AmountToDefer := Round(NumberOfDaysInPeriod * DailyDeferralAmount, AmountRoundingPrecision);
                RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
            end else begin
                // Get the starting date of the accounting period of the posting date is in
                FirstPeriodDate := GetCurPeriodStartingDate(PostDate);

                // Get the starting date of the next accounting period
                SecondPeriodDate := GetNextPeriodStartingDate(PostDate);

                NumberOfDaysInPeriod := (SecondPeriodDate - FirstPeriodDate);

                if PeriodicCount <> NumberOfPeriods then begin
                    // Not the last period
                    AmountToDefer := Round(NumberOfDaysInPeriod * DailyDeferralAmount, AmountRoundingPrecision);
                    RunningDeferralTotal := RunningDeferralTotal + AmountToDefer;
                end else
                    AmountToDefer := (DeferralHeader."Amount to Defer" - RunningDeferralTotal);
            end;

            DeferralLine."Posting Date" := PostDate;
            UpdateDeferralLineDescription(DeferralLine, DeferralHeader, DeferralTemplate, PostDate);

            CheckPostingDate(DeferralHeader, DeferralLine);

            DeferralLine.Amount := AmountToDefer;

            OnCalculateDaysPerPeriodOnBeforeDeferralLineInsert(DeferralHeader, DeferralLine);
            DeferralLine.Insert();
        end;

        OnAfterCalculateDaysPerPeriod(DeferralHeader, DeferralLine, DeferralTemplate);
    end;

    local procedure CalculateUserDefined(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    var
        PeriodicCount: Integer;
        PostDate: Date;
    begin
        OnBeforeCalculateUserDefined(DeferralHeader, DeferralLine, DeferralTemplate);

        for PeriodicCount := 1 to DeferralHeader."No. of Periods" do begin
            InitializeDeferralHeaderAndSetPostDate(DeferralLine, DeferralHeader, PeriodicCount, PostDate);

            DeferralLine."Posting Date" := PostDate;
            UpdateDeferralLineDescription(DeferralLine, DeferralHeader, DeferralTemplate, PostDate);

            CheckPostingDate(DeferralHeader, DeferralLine);

            // For User-Defined, user must enter in deferral amounts
            OnCalculateUserDefinedOnBeforeDeferralLineInsert(DeferralHeader, DeferralLine);
            DeferralLine.Insert();
        end;

        OnAfterCalculateUserDefined(DeferralHeader, DeferralLine, DeferralTemplate);
    end;

    local procedure UpdateDeferralLineDescription(var DeferralLine: Record "Deferral Line"; DeferralHeader: Record "Deferral Header"; DeferralTemplate: Record "Deferral Template"; PostDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDeferralLineDescription(DeferralLine, DeferralHeader, DeferralTemplate, PostDate, IsHandled);
        if IsHandled then
            exit;

        DeferralLine.Description := CreateRecurringDescription(PostDate, DeferralTemplate."Period Description");
    end;

    /// <summary>
    /// Sets filters on the deferral line record to retrieve lines for a specific source document.
    /// Used throughout the deferral system to isolate deferral lines by their source document parameters.
    /// </summary>
    /// <param name="DeferralLine">Deferral Line record reference to apply filters to</param>
    /// <param name="DeferralDocType">Type of source document (Purchase, Sales, G/L)</param>
    /// <param name="GenJnlTemplateName">General Journal Template name for G/L deferrals</param>
    /// <param name="GenJnlBatchName">General Journal Batch name for G/L deferrals</param>
    /// <param name="DocumentType">Document type ID from the source document</param>
    /// <param name="DocumentNo">Document number from the source document</param>
    /// <param name="LineNo">Line number within the source document</param>
    procedure FilterDeferralLines(var DeferralLine: Record "Deferral Line"; DeferralDocType: Option; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
        DeferralLine.SetRange("Gen. Jnl. Template Name", GenJnlTemplateName);
        DeferralLine.SetRange("Gen. Jnl. Batch Name", GenJnlBatchName);
        DeferralLine.SetRange("Document Type", DocumentType);
        DeferralLine.SetRange("Document No.", DocumentNo);
        DeferralLine.SetRange("Line No.", LineNo);
    end;

    /// <summary>
    /// Checks if the specified posting date is allowed for deferral posting based on user and general ledger setup.
    /// </summary>
    /// <param name="PostingDate">Date to validate for deferral posting</param>
    /// <returns>True if the date is not allowed, false if it is allowed</returns>
    procedure IsDateNotAllowed(PostingDate: Date) Result: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        IsHandled: Boolean;
    begin
        OnBeforeIsDateNotAllowed(PostingDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if UserId() <> '' then
            if UserSetup.Get(UserId()) then begin
                UserSetup.CheckAllowedDeferralPostingDates(1);
                AllowPostingFrom := UserSetup."Allow Deferral Posting From";
                AllowPostingTo := UserSetup."Allow Deferral Posting To";
            end;
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.CheckAllowedDeferralPostingDates(1);
            AllowPostingFrom := GeneralLedgerSetup."Allow Deferral Posting From";
            AllowPostingTo := GeneralLedgerSetup."Allow Deferral Posting To";
        end;
        if AllowPostingTo = 0D then
            AllowPostingTo := DMY2Date(31, 12, 9999);
        Result := not (PostingDate in [AllowPostingFrom .. AllowPostingTo]);
    end;

    local procedure SetStartDate(DeferralTemplate: Record "Deferral Template"; StartDate: Date) AdjustedStartDate: Date
    var
        AccountingPeriod: Record "Accounting Period";
        DeferralStartDate: Enum "Deferral Calculation Start Date";
    begin
        // "Start Date" passed in needs to be adjusted based on the Deferral Code's Start Date setting;
        case DeferralTemplate."Start Date" of
            DeferralStartDate::"Posting Date":
                AdjustedStartDate := StartDate;
            DeferralStartDate::"Beginning of Period":
                begin
                    if AccountingPeriod.IsEmpty() then
                        exit(CalcDate('<-CM>', StartDate));
                    AccountingPeriod.SetRange("Starting Date", 0D, StartDate);
                    if AccountingPeriod.FindLast() then
                        AdjustedStartDate := AccountingPeriod."Starting Date";
                end;
            DeferralStartDate::"End of Period":
                begin
                    if AccountingPeriod.IsEmpty() then
                        exit(CalcDate('<CM>', StartDate));
                    AccountingPeriod.SetFilter("Starting Date", '>%1', StartDate);
                    if AccountingPeriod.FindFirst() then
                        AdjustedStartDate := CalcDate('<-1D>', AccountingPeriod."Starting Date");
                end;
            DeferralStartDate::"Beginning of Next Period":
                begin
                    if AccountingPeriod.IsEmpty() then
                        exit(CalcDate('<CM + 1D>', StartDate));
                    AccountingPeriod.SetFilter("Starting Date", '>%1', StartDate);
                    if AccountingPeriod.FindFirst() then
                        AdjustedStartDate := AccountingPeriod."Starting Date";
                end;
            DeferralStartDate::"Beginning of Next Calendar Year":
                AdjustedStartDate := CalcDate('<CY + 1D>', StartDate);
        end;

        OnAfterSetStartDate(DeferralTemplate, StartDate, AdjustedStartDate);
    end;

    /// <summary>
    /// Creates or updates a deferral header record with the specified parameters.
    /// Handles both new header creation and updating existing headers with new calculation parameters.
    /// </summary>
    /// <param name="DeferralHeader">Deferral Header record reference to create or update</param>
    /// <param name="DeferralDocType">Type of source document (Purchase, Sales, G/L)</param>
    /// <param name="GenJnlTemplateName">General Journal Template name for G/L deferrals</param>
    /// <param name="GenJnlBatchName">General Journal Batch name for G/L deferrals</param>
    /// <param name="DocumentType">Document type ID from the source document</param>
    /// <param name="DocumentNo">Document number from the source document</param>
    /// <param name="LineNo">Line number within the source document</param>
    /// <param name="CalcMethod">Method for calculating period amounts</param>
    /// <param name="NoOfPeriods">Number of periods to distribute the deferral over</param>
    /// <param name="AdjustedDeferralAmount">Final deferral amount after percentage application</param>
    /// <param name="AdjustedStartDate">Final start date after template-based adjustments</param>
    /// <param name="DeferralCode">Deferral template code</param>
    /// <param name="DeferralDescription">Description for the deferral schedule</param>
    /// <param name="AmountToDefer">Original amount to defer before adjustments</param>
    /// <param name="AdjustStartDate">Whether start date was adjusted</param>
    /// <param name="CurrencyCode">Currency code for foreign currency handling</param>
    procedure SetDeferralRecords(var DeferralHeader: Record "Deferral Header"; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; CalcMethod: Enum "Deferral Calculation Method"; NoOfPeriods: Integer; AdjustedDeferralAmount: Decimal; AdjustedStartDate: Date; DeferralCode: Code[10]; DeferralDescription: Text[100]; AmountToDefer: Decimal; AdjustStartDate: Boolean; CurrencyCode: Code[10])
    begin
        if not DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
            // Need to create the header record.
            DeferralHeader."Deferral Doc. Type" := Enum::"Deferral Document Type".FromInteger(DeferralDocType);
            DeferralHeader."Gen. Jnl. Template Name" := GenJnlTemplateName;
            DeferralHeader."Gen. Jnl. Batch Name" := GenJnlBatchName;
            DeferralHeader."Document Type" := DocumentType;
            DeferralHeader."Document No." := DocumentNo;
            DeferralHeader."Line No." := LineNo;
            DeferralHeader.Insert();
        end;
        DeferralHeader."Amount to Defer" := AdjustedDeferralAmount;
        if AdjustStartDate or (DeferralHeader."Initial Amount to Defer" = 0) then
            DeferralHeader."Initial Amount to Defer" := AmountToDefer;
        DeferralHeader."Calc. Method" := CalcMethod;
        DeferralHeader."Start Date" := AdjustedStartDate;
        DeferralHeader."No. of Periods" := NoOfPeriods;
        DeferralHeader."Schedule Description" := DeferralDescription;
        DeferralHeader."Deferral Code" := DeferralCode;
        DeferralHeader."Currency Code" := CurrencyCode;
        OnSetDeferralRecordsOnBeforeDeferralHeaderModify(DeferralHeader);
        DeferralHeader.Modify();
        // Remove old lines as they will be recalculated/recreated
        RemoveDeferralLines(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
    end;

    /// <summary>
    /// Creates, updates, or removes a deferral schedule based on the provided deferral code and parameters.
    /// If no deferral code is provided, removes any existing schedule. If a code is provided, creates or updates the schedule.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code to use, blank to remove schedule</param>
    /// <param name="DeferralDocType">Type of document containing the deferral</param>
    /// <param name="GenJnlTemplateName">General Journal Template name for G/L deferrals</param>
    /// <param name="GenJnlBatchName">General Journal Batch name for G/L deferrals</param>
    /// <param name="DocumentType">Document type ID from the source document</param>
    /// <param name="DocumentNo">Document number from the source document</param>
    /// <param name="LineNo">Line number within the source document</param>
    /// <param name="Amount">Amount to defer</param>
    /// <param name="PostingDate">Posting date for the deferral</param>
    /// <param name="Description">Description for the deferral schedule</param>
    /// <param name="CurrencyCode">Currency code for foreign currency handling</param>
    /// <param name="AdjustStartDate">Whether to adjust the start date based on template settings</param>
    procedure RemoveOrSetDeferralSchedule(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; Amount: Decimal; PostingDate: Date; Description: Text[100]; CurrencyCode: Code[10]; AdjustStartDate: Boolean)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralTemplate: Record "Deferral Template";
        OldDeferralPostingDate: Date;
        UseDeferralCalculationMethod: Enum "Deferral Calculation Method";
        UseNoOfPeriods: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRemoveOrSetDeferralSchedule(DeferralCode, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, Amount, PostingDate, Description, CurrencyCode, AdjustStartDate, IsHandled);
        if IsHandled then
            exit;

        if DeferralCode = '' then
            // If the user cleared the deferral code, we should remove the saved schedule...
            if DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
                DeferralHeader.Delete();
                RemoveDeferralLines(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
            end;
        if DeferralCode <> '' then
            if LineNo <> 0 then
                if DeferralTemplate.Get(DeferralCode) then begin
                    ValidateDeferralTemplate(DeferralTemplate);

                    OldDeferralPostingDate := GetDeferralStartDate(DeferralDocType, DocumentType, DocumentNo, LineNo, DeferralCode, PostingDate);
                    if AdjustStartDate and (OldDeferralPostingDate <> PostingDate) then begin
                        AdjustStartDate := false;
                        PostingDate := OldDeferralPostingDate;
                    end;

                    UseDeferralCalculationMethod := DeferralTemplate."Calc. Method";
                    UseNoOfPeriods := DeferralTemplate."No. of Periods";
                    DeferralHeader.SetLoadFields("Calc. Method", "No. of Periods");
                    if DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
                        UseDeferralCalculationMethod := DeferralHeader."Calc. Method";
                        if DeferralHeader."No. of Periods" >= 1 then
                            UseNoOfPeriods := DeferralHeader."No. of Periods";
                    end;

                    CreateDeferralSchedule(DeferralCode, DeferralDocType,
                      GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, Amount,
                      UseDeferralCalculationMethod, PostingDate, UseNoOfPeriods,
                      true, GetDeferralDescription(GenJnlBatchName, DocumentNo, Description),
                      AdjustStartDate, CurrencyCode);
                end;
    end;

    /// <summary>
    /// Creates posted deferral records from a general journal line's deferral schedule.
    /// Transfers the deferral header and lines to posted tables and links them to the posted general ledger entry.
    /// </summary>
    /// <param name="GenJournalLine">General journal line being posted</param>
    /// <param name="FirstEntryNo">First G/L entry number created from the journal line</param>
    procedure CreateScheduleFromGL(GenJournalLine: Record "Gen. Journal Line"; FirstEntryNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralTemplate: Record "Deferral Template";
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DeferralAccount: Code[20];
        Account: Code[20];
        GLAccount: Code[20];
        GLAccountType: Enum "Gen. Journal Account Type";
    begin
        if DeferralHeader.Get(DeferralHeader."Deferral Doc. Type"::"G/L",
             GenJournalLine."Journal Template Name",
             GenJournalLine."Journal Batch Name", 0, '',
             GenJournalLine."Line No.")
        then begin
            if DeferralTemplate.Get(DeferralHeader."Deferral Code") then
                DeferralAccount := DeferralTemplate."Deferral Account";

            if (GenJournalLine."Account No." = '') and (GenJournalLine."Bal. Account No." <> '') then begin
                GLAccount := GenJournalLine."Bal. Account No.";
                GLAccountType := GenJournalLine."Bal. Account Type";
            end else begin
                GLAccount := GenJournalLine."Account No.";
                GLAccountType := GenJournalLine."Account Type";
            end;

            // Account types not G/L are not storing a GL account in the GenJnlLine's Account field, need to retrieve
            case GLAccountType of
                GenJournalLine."Account Type"::Customer:
                    begin
                        CustomerPostingGroup.Get(GenJournalLine."Posting Group");
                        Account := CustomerPostingGroup.GetReceivablesAccount();
                    end;
                GenJournalLine."Account Type"::Vendor:
                    begin
                        VendorPostingGroup.Get(GenJournalLine."Posting Group");
                        Account := VendorPostingGroup.GetPayablesAccount();
                    end;
                GenJournalLine."Account Type"::"Bank Account":
                    begin
                        BankAccount.Get(GLAccount);
                        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
                        Account := BankAccountPostingGroup."G/L Account No.";
                    end;
                else
                    Account := GLAccount;
            end;

            // Create the Posted Deferral Schedule with the Document Number created from the posted GL Trx...
            PostedDeferralHeader.Init();
            PostedDeferralHeader.TransferFields(DeferralHeader);
            PostedDeferralHeader."Deferral Doc. Type" := DeferralHeader."Deferral Doc. Type"::"G/L";
            // Adding document number so we can connect the Ledger and Deferral Schedule details...
            PostedDeferralHeader."Gen. Jnl. Document No." := GenJournalLine."Document No.";
            PostedDeferralHeader."Account No." := Account;
            PostedDeferralHeader."Document Type" := 0;
            PostedDeferralHeader."Document No." := '';
            PostedDeferralHeader."Line No." := GenJournalLine."Line No.";
            PostedDeferralHeader."Currency Code" := GenJournalLine."Currency Code";
            PostedDeferralHeader."Deferral Account" := DeferralAccount;
            PostedDeferralHeader."Posting Date" := GenJournalLine."Posting Date";
            PostedDeferralHeader."Entry No." := FirstEntryNo;
            OnBeforePostedDeferralHeaderInsert(PostedDeferralHeader, GenJournalLine);
            PostedDeferralHeader.Insert(true);
            FilterDeferralLines(
              DeferralLine, DeferralHeader."Deferral Doc. Type"::"G/L".AsInteger(),
              GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
              0, '', GenJournalLine."Line No.");
            if DeferralLine.FindSet() then
                repeat
                    PostedDeferralLine.Init();
                    PostedDeferralLine.TransferFields(DeferralLine);
                    PostedDeferralLine."Deferral Doc. Type" := DeferralHeader."Deferral Doc. Type"::"G/L";
                    PostedDeferralLine."Gen. Jnl. Document No." := GenJournalLine."Document No.";
                    PostedDeferralLine."Account No." := Account;
                    PostedDeferralLine."Document Type" := 0;
                    PostedDeferralLine."Document No." := '';
                    PostedDeferralLine."Line No." := GenJournalLine."Line No.";
                    PostedDeferralLine."Currency Code" := GenJournalLine."Currency Code";
                    PostedDeferralLine."Deferral Account" := DeferralAccount;
                    OnBeforePostedDeferralLineInsert(PostedDeferralLine, GenJournalLine);
                    PostedDeferralLine.Insert(true);
                until DeferralLine.Next() = 0;
        end;

        OnAfterCreateScheduleFromGL(GenJournalLine, PostedDeferralHeader);

        GenJnlPostLine.RemoveDeferralSchedule(GenJournalLine);
    end;

    /// <summary>
    /// Validates and creates/updates a deferral schedule when a deferral code is entered or changed.
    /// Removes existing schedule if the code is cleared.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code being validated</param>
    /// <param name="DeferralDocType">Type of document containing the deferral</param>
    /// <param name="GenJnlTemplateName">General Journal Template name for G/L deferrals</param>
    /// <param name="GenJnlBatchName">General Journal Batch name for G/L deferrals</param>
    /// <param name="DocumentType">Document type ID from the source document</param>
    /// <param name="DocumentNo">Document number from the source document</param>
    /// <param name="LineNo">Line number within the source document</param>
    /// <param name="Amount">Amount to defer</param>
    /// <param name="PostingDate">Posting date for the deferral</param>
    /// <param name="Description">Description for the deferral schedule</param>
    /// <param name="CurrencyCode">Currency code for foreign currency handling</param>
    procedure DeferralCodeOnValidate(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; Amount: Decimal; PostingDate: Date; Description: Text[100]; CurrencyCode: Code[10])
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralTemplate: Record "Deferral Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeferralCodeOnValidate(DeferralCode, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, Amount, PostingDate, Description, CurrencyCode, IsHandled);
        if IsHandled then
            exit;

        DeferralHeader.Init();
        DeferralLine.Init();
        if DeferralCode = '' then
            // If the user cleared the deferral code, we should remove the saved schedule...
            DeferralCodeOnDelete(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo)
        else
            if LineNo <> 0 then
                if DeferralTemplate.Get(DeferralCode) then begin
                    ValidateDeferralTemplate(DeferralTemplate);

                    CreateDeferralSchedule(DeferralCode, DeferralDocType,
                      GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, Amount,
                      DeferralTemplate."Calc. Method", PostingDate, DeferralTemplate."No. of Periods",
                      true, GetDeferralDescription(GenJnlBatchName, DocumentNo, Description), true, CurrencyCode);
                end;
    end;

    /// <summary>
    /// Removes a deferral schedule when a deferral code is deleted or cleared.
    /// Deletes the header and all associated deferral lines.
    /// </summary>
    /// <param name="DeferralDocType">Type of document containing the deferral</param>
    /// <param name="GenJnlTemplateName">General Journal Template name for G/L deferrals</param>
    /// <param name="GenJnlBatchName">General Journal Batch name for G/L deferrals</param>
    /// <param name="DocumentType">Document type ID from the source document</param>
    /// <param name="DocumentNo">Document number from the source document</param>
    /// <param name="LineNo">Line number within the source document</param>
    procedure DeferralCodeOnDelete(DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
    begin
        if LineNo <> 0 then
            // Deferral Additions
            if DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
                DeferralHeader.Delete();
                RemoveDeferralLines(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
            end;
    end;

    /// <summary>
    /// Opens the deferral schedule editing page for a specific line.
    /// Creates a new schedule if one doesn't exist, or allows editing of an existing schedule.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code</param>
    /// <param name="DeferralDocType">Type of document containing the deferral</param>
    /// <param name="GenJnlTemplateName">General Journal Template name for G/L deferrals</param>
    /// <param name="GenJnlBatchName">General Journal Batch name for G/L deferrals</param>
    /// <param name="DocumentType">Document type ID from the source document</param>
    /// <param name="DocumentNo">Document number from the source document</param>
    /// <param name="LineNo">Line number within the source document</param>
    /// <param name="Amount">Amount to defer</param>
    /// <param name="PostingDate">Posting date for the deferral</param>
    /// <param name="Description">Description for the deferral schedule</param>
    /// <param name="CurrencyCode">Currency code for foreign currency handling</param>
    /// <returns>True if changes were made to the schedule, false otherwise</returns>
    procedure OpenLineScheduleEdit(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; Amount: Decimal; PostingDate: Date; Description: Text[100]; CurrencyCode: Code[10]): Boolean
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        DeferralSchedule: Page "Deferral Schedule";
        Changed: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOpenLineScheduleEdit(DeferralCode, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, Amount, PostingDate, Description, CurrencyCode);
        if DeferralCode = '' then
            Message(SelectDeferralCodeMsg)
        else
            if DeferralTemplate.Get(DeferralCode) then
                if DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
                    IsHandled := false;
                    OnOpenLineScheduleEditOnBeforeDeferralScheduleSetParameters(DeferralSchedule, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, DeferralHeader, IsHandled);
                    if not IsHandled then
                        DeferralSchedule.SetParameter(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
                    DeferralSchedule.RunModal();
                    Changed := DeferralSchedule.GetParameter();
                    Clear(DeferralSchedule);
                end else begin
                    CreateDeferralSchedule(DeferralCode, DeferralDocType,
                      GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo, Amount,
                      DeferralTemplate."Calc. Method", PostingDate, DeferralTemplate."No. of Periods", true,
                      GetDeferralDescription(GenJnlBatchName, DocumentNo, Description), true, CurrencyCode);
                    Commit();
                    if DeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then begin
                        DeferralSchedule.SetParameter(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
                        DeferralSchedule.RunModal();
                        Changed := DeferralSchedule.GetParameter();
                        Clear(DeferralSchedule);
                    end;
                end;
        exit(Changed);
    end;

    /// <summary>
    /// Opens the deferral schedule view page for posted/archived deferrals in read-only mode.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code</param>
    /// <param name="DeferralDocType">Type of document containing the deferral</param>
    /// <param name="GenJnlTemplateName">General Journal Template name for G/L deferrals</param>
    /// <param name="GenJnlBatchName">General Journal Batch name for G/L deferrals</param>
    /// <param name="DocumentType">Document type ID from the source document</param>
    /// <param name="DocumentNo">Document number from the source document</param>
    /// <param name="LineNo">Line number within the source document</param>
    procedure OpenLineScheduleView(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        DeferralTemplate: Record "Deferral Template";
        PostedDeferralHeader: Record "Posted Deferral Header";
    begin
        // On view nothing will happen if the record does not exist
        if DeferralCode <> '' then
            if DeferralTemplate.Get(DeferralCode) then
                if PostedDeferralHeader.Get(DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo) then
                    PAGE.RunModal(PAGE::"Deferral Schedule View", PostedDeferralHeader);
    end;

    /// <summary>
    /// Opens the archived deferral schedule view page for document archive scenarios.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code</param>
    /// <param name="DeferralDocType">Type of document containing the deferral</param>
    /// <param name="DocumentType">Document type ID from the source document</param>
    /// <param name="DocumentNo">Document number from the source document</param>
    /// <param name="DocNoOccurence">Document number occurrence for archive</param>
    /// <param name="VersionNo">Version number for archive</param>
    /// <param name="LineNo">Line number within the source document</param>
    procedure OpenLineScheduleArchive(DeferralCode: Code[10]; DeferralDocType: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurence: Integer; VersionNo: Integer; LineNo: Integer)
    var
        DeferralHeaderArchive: Record "Deferral Header Archive";
    begin
        // On view nothing will happen if the record does not exist
        if DeferralCode <> '' then
            if DeferralHeaderArchive.Get(DeferralDocType, DocumentType, DocumentNo, DocNoOccurence, VersionNo, LineNo) then
                PAGE.RunModal(PAGE::"Deferral Schedule Archive", DeferralHeaderArchive);
    end;

    local procedure RemoveDeferralLines(DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        DeferralLine: Record "Deferral Line";
    begin
        FilterDeferralLines(DeferralLine, DeferralDocType, GenJnlTemplateName, GenJnlBatchName, DocumentType, DocumentNo, LineNo);
        DeferralLine.DeleteAll();
    end;

    local procedure ValidateDeferralTemplate(DeferralTemplate: Record "Deferral Template")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateDeferralTemplate(DeferralTemplate, IsHandled);
        if IsHandled then
            exit;

        DeferralTemplate.TestField("Deferral Account");
        DeferralTemplate.TestField("Deferral %");
        DeferralTemplate.TestField("No. of Periods");
    end;

    /// <summary>
    /// Rounds deferral amounts to appropriate precision based on currency settings.
    /// Handles both LCY and foreign currency amounts with proper rounding.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header containing schedule information</param>
    /// <param name="CurrencyCode">Currency code for the amounts</param>
    /// <param name="CurrencyFactor">Exchange rate factor for currency conversion</param>
    /// <param name="PostingDate">Date for currency exchange rate lookup</param>
    /// <param name="AmtToDefer">Amount to defer (will be updated with rounded value)</param>
    /// <param name="AmtToDeferLCY">LCY amount to defer (will be updated with rounded value)</param>
    procedure RoundDeferralAmount(var DeferralHeader: Record "Deferral Header"; CurrencyCode: Code[10]; CurrencyFactor: Decimal; PostingDate: Date; var AmtToDefer: Decimal; var AmtToDeferLCY: Decimal)
    var
        DeferralLine: Record "Deferral Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        UseDate: Date;
        DeferralCount: Integer;
        TotalAmountLCY: Decimal;
        TotalDeferralCount: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoundDeferralAmount(DeferralHeader, CurrencyCode, CurrencyFactor, PostingDate, IsHandled);
        if IsHandled then
            exit;

        // Calculate the LCY amounts for posting
        if PostingDate = 0D then
            UseDate := WorkDate()
        else
            UseDate := PostingDate;

        DeferralHeader."Amount to Defer (LCY)" :=
          Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(UseDate, CurrencyCode, DeferralHeader."Amount to Defer", CurrencyFactor));
        DeferralHeader.Modify();
        AmtToDefer := DeferralHeader."Amount to Defer";
        AmtToDeferLCY := DeferralHeader."Amount to Defer (LCY)";
        TotalAmountLCY := 0;
        FilterDeferralLines(
          DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
          DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
          DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
        if DeferralLine.FindSet() then begin
            TotalDeferralCount := DeferralLine.Count();
            repeat
                DeferralCount := DeferralCount + 1;
                if DeferralCount = TotalDeferralCount then begin
                    DeferralLine."Amount (LCY)" := DeferralHeader."Amount to Defer (LCY)" - TotalAmountLCY;
                    DeferralLine.Modify();
                end else begin
                    DeferralLine."Amount (LCY)" :=
                      Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(UseDate, CurrencyCode, DeferralLine.Amount, CurrencyFactor));
                    TotalAmountLCY := TotalAmountLCY + DeferralLine."Amount (LCY)";
                    DeferralLine.Modify();
                end;
            until DeferralLine.Next() = 0;
        end;
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    /// <summary>
    /// Initializes a deferral line record with header information and sets the appropriate posting date.
    /// Handles period-based date calculations using accounting periods.
    /// </summary>
    /// <param name="DeferralLine">Deferral line record to initialize</param>
    /// <param name="DeferralHeader">Deferral header containing source information</param>
    /// <param name="PeriodicCount">Current period number in the deferral schedule</param>
    /// <param name="PostDate">Posting date that will be updated based on period calculations</param>
    procedure InitializeDeferralHeaderAndSetPostDate(var DeferralLine: Record "Deferral Line"; DeferralHeader: Record "Deferral Header"; PeriodicCount: Integer; var PostDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        DeferralLine.Init();
        DeferralLine."Deferral Doc. Type" := DeferralHeader."Deferral Doc. Type";
        DeferralLine."Gen. Jnl. Template Name" := DeferralHeader."Gen. Jnl. Template Name";
        DeferralLine."Gen. Jnl. Batch Name" := DeferralHeader."Gen. Jnl. Batch Name";
        DeferralLine."Document Type" := DeferralHeader."Document Type";
        DeferralLine."Document No." := DeferralHeader."Document No.";
        DeferralLine."Line No." := DeferralHeader."Line No.";
        DeferralLine."Currency Code" := DeferralHeader."Currency Code";
        OnInitializeDeferralHeaderAndSetPostDateAfterInitDeferralLine(DeferralLine);

        if PeriodicCount = 1 then begin
            if not AccountingPeriod.IsEmpty() then begin
                AccountingPeriod.SetFilter("Starting Date", '..%1', DeferralHeader."Start Date");
                if not AccountingPeriod.FindFirst() then
                    Error(DeferSchedOutOfBoundsErr);
            end;
            PostDate := DeferralHeader."Start Date";
        end else begin
            if IsAccountingPeriodExist(AccountingPeriod, CalcDate('<CM>', PostDate) + 1) then begin
                AccountingPeriod.SetFilter("Starting Date", '>%1', PostDate);
                if not AccountingPeriod.FindFirst() then
                    Error(DeferSchedOutOfBoundsErr);
            end;
            PostDate := AccountingPeriod."Starting Date";
        end;
    end;

    local procedure IsAccountingPeriodExist(var AccountingPeriod: Record "Accounting Period"; PostingDate: Date): Boolean
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        AccountingPeriod.Reset();
        if not AccountingPeriod.IsEmpty() then
            exit(true);

        AccountingPeriodMgt.InitDefaultAccountingPeriod(AccountingPeriod, PostingDate);
        exit(false);
    end;

    /// <summary>
    /// Gets the start date for a deferral from existing schedule or calculates from template settings.
    /// Used to maintain consistency when adjusting existing deferrals.
    /// </summary>
    /// <param name="DeferralDocType">Type of document containing the deferral</param>
    /// <param name="RecordDocumentType">Document type ID from the source document</param>
    /// <param name="RecordDocumentNo">Document number from the source document</param>
    /// <param name="RecordLineNo">Line number within the source document</param>
    /// <param name="DeferralCode">Deferral template code</param>
    /// <param name="PostingDate">Default posting date if no template or schedule exists</param>
    /// <returns>Start date for the deferral schedule</returns>
    procedure GetDeferralStartDate(DeferralDocType: Integer; RecordDocumentType: Integer; RecordDocumentNo: Code[20]; RecordLineNo: Integer; DeferralCode: Code[10]; PostingDate: Date): Date
    var
        DeferralHeader: Record "Deferral Header";
        DeferralTemplate: Record "Deferral Template";
    begin
        if DeferralHeader.Get(DeferralDocType, '', '', RecordDocumentType, RecordDocumentNo, RecordLineNo) then
            exit(DeferralHeader."Start Date");

        if DeferralTemplate.Get(DeferralCode) then
            exit(SetStartDate(DeferralTemplate, PostingDate));

        exit(PostingDate);
    end;

    /// <summary>
    /// Adjusts total amounts for deferral posting by subtracting deferred amounts from totals.
    /// Handles both LCY and ACY amounts with VAT base calculations.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code, blank if no deferral</param>
    /// <param name="AmtToDefer">Amount being deferred (may be zeroed if fully deferred)</param>
    /// <param name="AmtToDeferACY">ACY amount being deferred</param>
    /// <param name="TotalAmount">Total amount to adjust</param>
    /// <param name="TotalAmountACY">Total ACY amount to adjust</param>
    /// <param name="TotalVATBase">VAT base amount to set</param>
    /// <param name="TotalVATBaseACY">ACY VAT base amount to set</param>
    procedure AdjustTotalAmountForDeferrals(DeferralCode: Code[10]; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        AdjustTotalAmountForDeferrals(DeferralCode, AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, 0, 0);
    end;

    /// <summary>
    /// Adjusts total amounts for deferral posting including discount handling.
    /// Extended version with discount amount parameters.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code, blank if no deferral</param>
    /// <param name="AmtToDefer">Amount being deferred (may be zeroed if fully deferred)</param>
    /// <param name="AmtToDeferACY">ACY amount being deferred</param>
    /// <param name="TotalAmount">Total amount to adjust</param>
    /// <param name="TotalAmountACY">Total ACY amount to adjust</param>
    /// <param name="TotalVATBase">VAT base amount to set</param>
    /// <param name="TotalVATBaseACY">ACY VAT base amount to set</param>
    /// <param name="DiscountAmount">Discount amount to consider</param>
    /// <param name="DiscountAmountACY">ACY discount amount to consider</param>
    procedure AdjustTotalAmountForDeferrals(DeferralCode: Code[10]; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    begin
        TotalVATBase := TotalAmount;
        TotalVATBaseACY := TotalAmountACY;
        if DeferralCode <> '' then
            if (AmtToDefer = TotalAmount - DiscountAmount) and (AmtToDeferACY = TotalAmountACY - DiscountAmountACY) then begin
                AmtToDefer := 0;
                AmtToDeferACY := 0;
            end else begin
                TotalAmount := TotalAmount - AmtToDefer;
                TotalAmountACY := TotalAmountACY - AmtToDeferACY;
            end;

        OnAfterAdjustTotalAmountForDeferrals(DeferralCode, AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY, DiscountAmount, DiscountAmountACY);
    end;

    /// <summary>
    /// Adjusts total amounts for deferral posting without VAT base calculations.
    /// Simplified version for scenarios where VAT base is not required.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code, blank if no deferral</param>
    /// <param name="AmtToDefer">Amount being deferred (may be zeroed if fully deferred)</param>
    /// <param name="AmtToDeferACY">ACY amount being deferred</param>
    /// <param name="TotalAmount">Total amount to adjust</param>
    /// <param name="TotalAmountACY">Total ACY amount to adjust</param>
    procedure AdjustTotalAmountForDeferralsNoBase(DeferralCode: Code[10]; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
        AdjustTotalAmountForDeferralsNoBase(DeferralCode, AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY, 0, 0);
    end;

    /// <summary>
    /// Adjusts total amounts for deferral posting without VAT base calculations, including discount handling.
    /// Extended version with discount amount parameters.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code, blank if no deferral</param>
    /// <param name="AmtToDefer">Amount being deferred (may be zeroed if fully deferred)</param>
    /// <param name="AmtToDeferACY">ACY amount being deferred</param>
    /// <param name="TotalAmount">Total amount to adjust</param>
    /// <param name="TotalAmountACY">Total ACY amount to adjust</param>
    /// <param name="DiscountAmount">Discount amount to consider</param>
    /// <param name="DiscountAmountACY">ACY discount amount to consider</param>
    procedure AdjustTotalAmountForDeferralsNoBase(DeferralCode: Code[10]; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    begin
        if DeferralCode <> '' then
            if (AmtToDefer = TotalAmount - DiscountAmount) and (AmtToDeferACY = TotalAmountACY - DiscountAmountACY) then begin
                AmtToDefer := 0;
                AmtToDeferACY := 0;
            end else begin
                TotalAmount := TotalAmount - AmtToDefer;
                TotalAmountACY := TotalAmountACY - AmtToDeferACY;
            end;

        OnAfterAdjustTotalAmountForDeferrals(DeferralCode, AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY, DiscountAmount, DiscountAmountACY);
    end;

    /// <summary>
    /// Validates general journal line conditions for deferral usage.
    /// Ensures source codes are properly configured for deferral processing.
    /// </summary>
    /// <param name="GenJournalLine">General journal line to validate</param>
    procedure CheckDeferralConditionForGenJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        RequiredSourceCode: Code[10];
        ErrorInfo: ErrorInfo;
        SameSourceCodeErr: Label 'Journal Source Code %1 is same as Source Code set for Purchase/Sales documents. This is not allowed when using deferrals. If you want to use this journal for deferrals, please update Source Codes on Gen Journal Template and generate line again.', Comment = '%1->Source Code';
        RequiredSourceCodeErr: Label 'Journal Source Code %1 is not same as default Source Code set for Gen. Journal Template with type %2. Deferrals can only be used when the journal line has the same source code as the source code defined for the journal in source code Setup. Please update this Gen. Journal Template or change the setup in Source Code Setup.', Comment = '%1->Source Code, %2->Gen. Journal Template Type';
        OpenSourceCodeSetupTxt: Label 'Open Source Code Setup';
        OpenSourceCodeSetupDescTxt: Label 'Open Source Code Setup page to check Source code setup.';
        OpenGenJournalTemplateTxt: Label 'Open Gen. Journal Template';
        OpenGenJournalTemplateDescTxt: Label 'Open Gen. Journal Template page to update Source code.';
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDeferralConditionForGenJournal(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        if GenJournalLine."Deferral Code" = '' then
            exit;

        SourceCodeSetup.Get();
        if GenJournalLine."Source Code" in [SourceCodeSetup.Sales, SourceCodeSetup.Purchases] then begin
            ErrorInfo.ErrorType(ErrorType::Client);
            ErrorInfo.Verbosity(Verbosity::Error);
            ErrorInfo.Message(StrSubstNo(SameSourceCodeErr, GenJournalLine."Source Code"));
            ErrorInfo.TableId(GenJournalLine.RecordId.TableNo);
            ErrorInfo.RecordId(GenJournalLine.RecordId);
            ErrorInfo.AddAction(OpenGenJournalTemplateTxt, Codeunit::"Deferral Utilities", 'ShowGenJournalTemplate', OpenGenJournalTemplateDescTxt);
            ErrorInfo.AddAction(OpenSourceCodeSetupTxt, Codeunit::"Deferral Utilities", 'ShowSourceCodeSetup', OpenSourceCodeSetupDescTxt);
            Error(ErrorInfo);
        end;

        GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
        case
            GenJournalTemplate.Type of
            GenJournalTemplate.Type::General:
                RequiredSourceCode := SourceCodeSetup."General Journal";
            GenJournalTemplate.Type::Purchases:
                RequiredSourceCode := SourceCodeSetup."Purchase Journal";
            GenJournalTemplate.Type::Sales:
                RequiredSourceCode := SourceCodeSetup."Sales Journal";
        end;

        if GenJournalLine."Source Code" <> RequiredSourceCode then begin
            ErrorInfo.ErrorType(ErrorType::Client);
            ErrorInfo.Verbosity(Verbosity::Error);
            ErrorInfo.Message(StrSubstNo(RequiredSourceCodeErr, GenJournalLine."Source Code", GenJournalTemplate.Type));
            ErrorInfo.TableId(GenJournalLine.RecordId.TableNo);
            ErrorInfo.RecordId(GenJournalLine.RecordId);
            ErrorInfo.AddAction(OpenGenJournalTemplateTxt, Codeunit::"Deferral Utilities", 'ShowGenJournalTemplate', OpenGenJournalTemplateDescTxt);
            ErrorInfo.AddAction(OpenSourceCodeSetupTxt, Codeunit::"Deferral Utilities", 'ShowSourceCodeSetup', OpenSourceCodeSetupDescTxt);
            Error(ErrorInfo);
        end;
    end;

    /// <summary>
    /// Opens the General Journal Templates page filtered to the template from the error context.
    /// Action method for error handling in deferral validation.
    /// </summary>
    /// <param name="ErrorInfo">Error information containing the journal line context</param>
    procedure ShowGenJournalTemplate(ErrorInfo: ErrorInfo)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournalTemplates: Page "General Journal Templates";
        RecordRef: RecordRef;
    begin
        RecordRef := ErrorInfo.RecordId.GetRecord();
        RecordRef.SetTable(GenJournalLine);
        GenJournalTemplate.SetRange(Name, GenJournalLine."Journal Template Name");
        GeneralJournalTemplates.SetTableView(GenJournalTemplate);
        GeneralJournalTemplates.RunModal();
    end;

    /// <summary>
    /// Opens the Source Code Setup page for configuring source codes.
    /// Action method for error handling in deferral validation.
    /// </summary>
    /// <param name="ErrorInfo">Error information for context</param>
    procedure ShowSourceCodeSetup(ErrorInfo: ErrorInfo)
    var
        SourceCodeSetup: Page "Source Code Setup";
    begin
        SourceCodeSetup.RunModal();
    end;

    local procedure GetPeriodStartingDate(PostingDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty() then
            exit(CalcDate('<-CM>', PostingDate));

        AccountingPeriod.SetFilter("Starting Date", '<%1', PostingDate);
        if AccountingPeriod.FindLast() then
            exit(AccountingPeriod."Starting Date");

        Error(DeferSchedOutOfBoundsErr);
    end;

    local procedure GetNextPeriodStartingDate(PostingDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty() then
            exit(CalcDate('<CM+1D>', PostingDate));

        AccountingPeriod.SetFilter("Starting Date", '>%1', PostingDate);
        if AccountingPeriod.FindFirst() then
            exit(AccountingPeriod."Starting Date");

        Error(DeferSchedOutOfBoundsErr);
    end;

    local procedure GetCurPeriodStartingDate(PostingDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty() then
            exit(CalcDate('<-CM>', PostingDate));

        AccountingPeriod.SetFilter("Starting Date", '<=%1', PostingDate);
        AccountingPeriod.FindLast();
        exit(AccountingPeriod."Starting Date");
    end;

    local procedure GetDeferralDescription(GenJnlBatchName: Code[10]; DocumentNo: Code[20]; Description: Text[100]) Result: Text[100]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDeferralDescription(GenJnlBatchName, DocumentNo, Description, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if GenJnlBatchName <> '' then
            exit(CopyStr(StrSubstNo(DescriptionTok, GenJnlBatchName, Description), 1, 100));
        exit(CopyStr(StrSubstNo(DescriptionTok, DocumentNo, Description), 1, 100));
    end;

    /// <summary>
    /// Creates a copy of an existing deferral schedule for a new source line.
    /// Used when copying document lines to maintain consistent deferral schedules.
    /// </summary>
    /// <param name="DeferralHeader">Source deferral header to copy from</param>
    /// <param name="NewSourceLineNo">New line number for the copied schedule</param>
    procedure CreateCopyOfDeferralSchedule(DeferralHeader: Record "Deferral Header"; NewSourceLineNo: Integer)
    var
        DeferralLine: Record "Deferral Line";
        NewDeferralHeader: Record "Deferral Header";
        NewDeferralLine: Record "Deferral Line";
    begin
        if NewDeferralHeader.Get(
            DeferralHeader."Deferral Doc. Type", DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
             DeferralHeader."Document Type", DeferralHeader."Document No.", NewSourceLineNo) then
            exit;

        NewDeferralHeader.TransferFields(DeferralHeader);
        NewDeferralHeader."Line No." := NewSourceLineNo;
        NewDeferralHeader.Insert();

        FilterDeferralLines(NewDeferralLine, NewDeferralHeader."Deferral Doc. Type".AsInteger(),
                    NewDeferralHeader."Gen. Jnl. Template Name", NewDeferralHeader."Gen. Jnl. Batch Name",
                    NewDeferralHeader."Document Type", NewDeferralHeader."Document No.", NewDeferralHeader."Line No.");
        if not NewDeferralLine.IsEmpty() then
            exit;

        FilterDeferralLines(DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
                    DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                    DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
        if DeferralLine.FindSet() then
            repeat
                NewDeferralLine.TransferFields(DeferralLine);
                NewDeferralLine."Line No." := NewDeferralHeader."Line No.";
                NewDeferralLine.Insert();
            until DeferralLine.Next() = 0;
    end;

    /// <summary>
    /// Integration event raised after calculating deferral amounts using days per period method.
    /// Enables custom processing or adjustments to deferral calculations.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="DeferralLine">Deferral line record with calculated amounts</param>
    /// <param name="DeferralTemplate">Deferral template containing calculation settings</param>
    /// <remarks>
    /// Raised from CalculateDaysPerPeriod procedure after completing days-based deferral calculations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateDaysPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    /// <summary>
    /// Integration event raised after calculating deferral amounts using equal per period method.
    /// Enables custom processing or adjustments to equal period deferral calculations.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="DeferralLine">Deferral line record with calculated amounts</param>
    /// <param name="DeferralTemplate">Deferral template containing calculation settings</param>
    /// <remarks>
    /// Raised from CalculateEqualPerPeriod procedure after completing equal period deferral calculations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateEqualPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    /// <summary>
    /// Integration event raised after calculating deferral amounts using straight-line method.
    /// Enables custom processing or adjustments to straight-line deferral calculations.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="DeferralLine">Deferral line record with calculated amounts</param>
    /// <param name="DeferralTemplate">Deferral template containing calculation settings</param>
    /// <remarks>
    /// Raised from CalculateStraightline procedure after completing straight-line deferral calculations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateStraightline(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    /// <summary>
    /// Integration event raised after calculating deferral amounts using user-defined method.
    /// Enables custom processing or adjustments to user-defined deferral calculations.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="DeferralLine">Deferral line record with calculated amounts</param>
    /// <param name="DeferralTemplate">Deferral template containing calculation settings</param>
    /// <remarks>
    /// Raised from CalculateUserDefined procedure after completing user-defined deferral calculations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateUserDefined(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    /// <summary>
    /// Integration event raised after creating the complete deferral schedule.
    /// Enables custom processing or validation after schedule generation is complete.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record for the created schedule</param>
    /// <param name="DeferralLine">Deferral line record representing the schedule lines</param>
    /// <param name="DeferralTemplate">Deferral template used for schedule creation</param>
    /// <param name="CalcMethod">Calculation method used for the schedule</param>
    /// <remarks>
    /// Raised from CreateDeferralSchedule procedure after completing schedule creation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDeferralSchedule(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template"; CalcMethod: Enum "Deferral Calculation Method")
    begin
    end;

    /// <summary>
    /// Integration event raised after creating deferral schedule from general journal line posting.
    /// Enables custom processing or field updates after G/L deferral schedule creation.
    /// </summary>
    /// <param name="GenJournalLine">General journal line that was posted</param>
    /// <param name="PostedDeferralHeader">Posted deferral header created from the journal line</param>
    /// <remarks>
    /// Raised from CreateScheduleFromGL procedure after creating posted deferral records.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateScheduleFromGL(var GenJournalLine: Record "Gen. Journal Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting the start date for deferral calculations.
    /// Enables custom start date logic or adjustments based on deferral template settings.
    /// </summary>
    /// <param name="DeferralTemplate">Deferral template containing start date calculation rules</param>
    /// <param name="StartDate">Original start date for the deferral</param>
    /// <param name="AdjustedStartDate">Adjusted start date for calculations (can be modified by subscribers)</param>
    /// <remarks>
    /// Raised from SetStartDate procedure after calculating adjusted start date.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetStartDate(DeferralTemplate: Record "Deferral Template"; var StartDate: Date; var AdjustedStartDate: Date)
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating deferral amounts using days per period method.
    /// Enables custom preprocessing or parameter modification before days-based calculations.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="DeferralLine">Deferral line record to be calculated</param>
    /// <param name="DeferralTemplate">Deferral template containing calculation settings</param>
    /// <remarks>
    /// Raised from CalculateDaysPerPeriod procedure before starting days-based deferral calculations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateDaysPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating deferral amounts using equal per period method.
    /// Enables custom preprocessing or parameter modification before equal period calculations.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="DeferralLine">Deferral line record to be calculated</param>
    /// <param name="DeferralTemplate">Deferral template containing calculation settings</param>
    /// <remarks>
    /// Raised from CalculateEqualPerPeriod procedure before starting equal period deferral calculations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateEqualPerPeriod(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating deferral amounts using straight-line method.
    /// Enables custom preprocessing or parameter modification before straight-line calculations.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="DeferralLine">Deferral line record to be calculated</param>
    /// <param name="DeferralTemplate">Deferral template containing calculation settings</param>
    /// <remarks>
    /// Raised from CalculateStraightline procedure before starting straight-line deferral calculations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateStraightline(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating deferral amounts using user-defined method.
    /// Enables custom preprocessing or parameter modification before user-defined calculations.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="DeferralLine">Deferral line record to be calculated</param>
    /// <param name="DeferralTemplate">Deferral template containing calculation settings</param>
    /// <remarks>
    /// Raised from CalculateUserDefined procedure before starting user-defined deferral calculations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateUserDefined(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    /// <summary>
    /// Integration event raised before creating a deferral schedule with comprehensive parameters.
    /// Enables custom schedule creation logic or parameter validation before schedule generation.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code for the schedule</param>
    /// <param name="DeferralDocType">Document type for the deferral (G/L, Sales, Purchase)</param>
    /// <param name="GenJnlTemplateName">General journal template name if applicable</param>
    /// <param name="GenJnlBatchName">General journal batch name if applicable</param>
    /// <param name="DocumentType">Document type identifier</param>
    /// <param name="DocumentNo">Document number for the deferral</param>
    /// <param name="LineNo">Line number within the document</param>
    /// <param name="AmountToDefer">Total amount to be deferred</param>
    /// <param name="CalcMethod">Calculation method for the schedule</param>
    /// <param name="StartDate">Start date for the deferral schedule</param>
    /// <param name="NoOfPeriods">Number of periods for the deferral</param>
    /// <param name="ApplyDeferralPercentage">Whether to apply percentage-based deferrals</param>
    /// <param name="DeferralDescription">Description for the deferral schedule</param>
    /// <param name="AdjustStartDate">Whether to adjust the start date</param>
    /// <param name="CurrencyCode">Currency code for the deferral</param>
    /// <param name="IsHandled">Set to true to skip standard schedule creation</param>
    /// <param name="RedistributeDeferralSchedule">Whether to redistribute the schedule</param>
    /// <remarks>
    /// Raised from CreateDeferralSchedule procedure before creating deferral header and lines.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDeferralSchedule(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; AmountToDefer: Decimal; CalcMethod: Enum "Deferral Calculation Method"; var StartDate: Date; var NoOfPeriods: Integer; ApplyDeferralPercentage: Boolean; DeferralDescription: Text[100]; var AdjustStartDate: Boolean; CurrencyCode: Code[10]; var IsHandled: Boolean; var RedistributeDeferralSchedule: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating deferral code input.
    /// Enables custom deferral code validation logic or preprocessing.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code being validated</param>
    /// <param name="DeferralDocType">Document type for the deferral</param>
    /// <param name="GenJnlTemplateName">General journal template name if applicable</param>
    /// <param name="GenJnlBatchName">General journal batch name if applicable</param>
    /// <param name="DocumentType">Document type identifier</param>
    /// <param name="DocumentNo">Document number for the deferral</param>
    /// <param name="LineNo">Line number within the document</param>
    /// <param name="Amount">Deferral amount</param>
    /// <param name="PostingDate">Posting date for the deferral</param>
    /// <param name="Description">Description for the deferral</param>
    /// <param name="CurrencyCode">Currency code for the deferral</param>
    /// <param name="IsHandled">Set to true to skip standard deferral code validation</param>
    /// <remarks>
    /// Raised from DeferralCodeOnValidate procedure before standard deferral code processing.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeferralCodeOnValidate(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; Amount: Decimal; PostingDate: Date; Description: Text[100]; CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting posted deferral header record.
    /// Enables custom field updates or validation before posted deferral header creation.
    /// </summary>
    /// <param name="PostedDeferralHeader">Posted deferral header record to be inserted</param>
    /// <param name="GenJournalLine">Source general journal line for the deferral</param>
    /// <remarks>
    /// Raised from CreateScheduleFromGL procedure before inserting posted deferral header.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDeferralHeaderInsert(var PostedDeferralHeader: Record "Posted Deferral Header"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting posted deferral line record.
    /// Enables custom field updates or validation before posted deferral line creation.
    /// </summary>
    /// <param name="PostedDeferralLine">Posted deferral line record to be inserted</param>
    /// <param name="GenJournalLine">Source general journal line for the deferral</param>
    /// <remarks>
    /// Raised from CreateScheduleFromGL procedure before inserting posted deferral lines.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDeferralLineInsert(var PostedDeferralLine: Record "Posted Deferral Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before opening deferral schedule editor for line editing.
    /// Enables custom preprocessing or parameter modification before schedule editing.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code for the schedule</param>
    /// <param name="DeferralDocType">Document type for the deferral</param>
    /// <param name="GenJnlTemplateName">General journal template name if applicable</param>
    /// <param name="GenJnlBatchName">General journal batch name if applicable</param>
    /// <param name="DocumentType">Document type identifier</param>
    /// <param name="DocumentNo">Document number for the deferral</param>
    /// <param name="LineNo">Line number within the document</param>
    /// <param name="Amount">Deferral amount</param>
    /// <param name="PostingDate">Posting date for the deferral</param>
    /// <param name="Description">Description for the deferral</param>
    /// <param name="CurrencyCode">Currency code for the deferral</param>
    /// <remarks>
    /// Raised from OpenLineScheduleEdit procedure before opening deferral schedule page.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenLineScheduleEdit(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; Amount: Decimal; PostingDate: Date; Description: Text[100]; CurrencyCode: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event raised after adjusting total amounts for deferral calculations.
    /// Enables custom processing or validation after deferral amount adjustments.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code</param>
    /// <param name="AmtToDefer">Amount to defer in local currency</param>
    /// <param name="AmtToDeferACY">Amount to defer in additional currency</param>
    /// <param name="TotalAmount">Total amount in local currency</param>
    /// <param name="TotalAmountACY">Total amount in additional currency</param>
    /// <param name="DiscountAmount">Discount amount in local currency</param>
    /// <param name="DiscountAmountACY">Discount amount in additional currency</param>
    /// <remarks>
    /// Raised from AdjustTotalAmountForDeferrals procedure after calculating adjusted amounts.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustTotalAmountForDeferrals(DeferralCode: Code[10]; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; DiscountAmount: Decimal; DiscountAmountACY: Decimal);
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating number of deferral periods.
    /// Enables custom period calculation logic based on calculation method and start date.
    /// </summary>
    /// <param name="CalcMethod">Calculation method for determining periods</param>
    /// <param name="NoOfPeriods">Number of periods (can be modified by subscribers)</param>
    /// <param name="StartDate">Start date for period calculation</param>
    /// <param name="IsHandled">Set to true to skip standard period calculation</param>
    /// <remarks>
    /// Raised from CalcDeferralNoOfPeriods procedure before standard period calculation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDeferralNoOfPeriods(CalcMethod: Enum "Deferral Calculation Method"; var NoOfPeriods: Integer; StartDate: Date; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking posting date validity for deferral lines.
    /// Enables custom posting date validation logic for deferral schedules.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header context for validation</param>
    /// <param name="DeferralLine">Deferral line with posting date to validate</param>
    /// <param name="IsHandled">Set to true to skip standard posting date validation</param>
    /// <remarks>
    /// Raised from CheckPostingDate procedure before standard date validation logic.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDate(DeferralHeader: Record "Deferral Header"; var DeferralLine: record "Deferral Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before generating deferral description text.
    /// Enables custom description logic for deferral schedule entries.
    /// </summary>
    /// <param name="GenJnlBatchName">General journal batch name for context</param>
    /// <param name="DocumentNo">Document number for the deferral</param>
    /// <param name="Description">Source description text</param>
    /// <param name="Result">Generated description result (can be modified by subscribers)</param>
    /// <param name="IsHandled">Set to true to skip standard description generation</param>
    /// <remarks>
    /// Raised from GetDeferralDescription procedure before standard description generation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeferralDescription(GenJnlBatchName: Code[10]; DocumentNo: Code[20]; Description: Text[100]; var Result: Text[100]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting deferral line during equal per period calculation.
    /// Enables custom field updates or validation before line insertion.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header context for the calculation</param>
    /// <param name="DeferralLine">Deferral line record to be inserted</param>
    /// <remarks>
    /// Raised from CalculateEqualPerPeriod procedure before inserting each deferral line.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCalculateEqualPerPeriodOnBeforeDeferralLineInsert(DeferralHeader: Record "Deferral Header"; var DeferralLine: record "Deferral Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after calculating the second period date in straight-line deferral calculations.
    /// Enables custom period date adjustments for straight-line deferral schedules.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="PostDate">Original posting date for the deferral</param>
    /// <param name="FirstPeriodDate">First period date for the deferral schedule</param>
    /// <param name="SecondPeriodDate">Second period date (can be modified by subscribers)</param>
    /// <remarks>
    /// Raised from CalculateStraightline procedure after calculating the second period date.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCalculateStraightlineOnAfterCalcSecondPeriodDate(DeferralHeader: Record "Deferral Header"; PostDate: Date; var FirstPeriodDate: Date; var SecondPeriodDate: Date)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting deferral line during straight-line calculation.
    /// Enables custom field updates or validation before line insertion.
    /// </summary>
    /// <param name="DeferralLine">Deferral line record to be inserted</param>
    /// <param name="DeferralHeader">Deferral header context for the calculation</param>
    /// <remarks>
    /// Raised from CalculateStraightline procedure before inserting each deferral line.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCalculateStraightlineOnBeforeDeferralLineInsert(var DeferralLine: Record "Deferral Line"; DeferralHeader: Record "Deferral Header")
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating periodic deferral amount in straight-line method.
    /// Enables custom amount calculation logic for straight-line deferral periods.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="PeriodicDeferralAmount">Periodic deferral amount (can be modified by subscribers)</param>
    /// <param name="AmountRoundingPrecision">Rounding precision for amount calculations</param>
    /// <param name="IsHandled">Set to true to skip standard periodic amount calculation</param>
    /// <remarks>
    /// Raised from CalculateStraightline procedure before calculating periodic deferral amounts.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCalculateStraightlineOnBeforeCalcPeriodicDeferralAmount(var DeferralHeader: Record "Deferral Header"; var PeriodicDeferralAmount: Decimal; AmountRoundingPrecision: Decimal; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised after calculating end date for days per period deferral method.
    /// Enables custom end date adjustments for days-based deferral calculations.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record containing calculation parameters</param>
    /// <param name="DeferralLine">Deferral line record with calculated dates</param>
    /// <param name="DeferralTemplate">Deferral template containing calculation settings</param>
    /// <param name="EndDate">Calculated end date (can be modified by subscribers)</param>
    /// <remarks>
    /// Raised from CalculateDaysPerPeriod procedure after calculating period end date.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCalculateDaysPerPeriodOnAfterCalcEndDate(var DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template"; var EndDate: Date)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting deferral line during days per period calculation.
    /// Enables custom field updates or validation before line insertion.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header context for the calculation</param>
    /// <param name="DeferralLine">Deferral line record to be inserted</param>
    /// <remarks>
    /// Raised from CalculateDaysPerPeriod procedure before inserting each deferral line.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCalculateDaysPerPeriodOnBeforeDeferralLineInsert(DeferralHeader: Record "Deferral Header"; var DeferralLine: record "Deferral Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting deferral line during user-defined calculation.
    /// Enables custom field updates or validation before line insertion.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header context for the calculation</param>
    /// <param name="DeferralLine">Deferral line record to be inserted</param>
    /// <remarks>
    /// Raised from CalculateUserDefined procedure before inserting each deferral line.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCalculateUserDefinedOnBeforeDeferralLineInsert(DeferralHeader: Record "Deferral Header"; var DeferralLine: record "Deferral Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying deferral header during record setup.
    /// Enables custom field updates or validation before deferral header modification.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record to be modified</param>
    /// <remarks>
    /// Raised from SetDeferralRecords procedure before modifying deferral header.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnSetDeferralRecordsOnBeforeDeferralHeaderModify(var DeferralHeader: Record "Deferral Header")
    begin
    end;

    /// <summary>
    /// Integration event raised before checking if a posting date is allowed for deferral processing.
    /// Enables custom date validation logic for deferral schedule processing.
    /// </summary>
    /// <param name="PostingDate">Posting date to be validated</param>
    /// <param name="Result">Validation result (can be modified by subscribers)</param>
    /// <param name="IsHandled">Set to true to skip standard date validation</param>
    /// <remarks>
    /// Raised from IsDateNotAllowed procedure before standard posting date validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDateNotAllowed(PostingDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before updating deferral line description during schedule creation.
    /// Enables custom description generation logic for deferral line entries.
    /// </summary>
    /// <param name="DeferralLine">Deferral line record to update</param>
    /// <param name="DeferralHeader">Deferral header context for description generation</param>
    /// <param name="DeferralTemplate">Deferral template containing description settings</param>
    /// <param name="PostDate">Posting date for the deferral line</param>
    /// <param name="IsHandled">Set to true to skip standard description update</param>
    /// <remarks>
    /// Raised from UpdateDeferralLineDescription procedure before updating line description.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDeferralLineDescription(var DeferralLine: Record "Deferral Line"; DeferralHeader: Record "Deferral Header"; DeferralTemplate: Record "Deferral Template"; PostDate: Date; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating deferral template settings.
    /// Enables custom validation logic for deferral template configuration.
    /// </summary>
    /// <param name="DeferralTemplate">Deferral template record to validate</param>
    /// <param name="IsHandled">Set to true to skip standard template validation</param>
    /// <remarks>
    /// Raised from ValidateDeferralTemplate procedure before standard template validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDeferralTemplate(DeferralTemplate: Record "Deferral Template"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after initializing deferral line during deferral header initialization.
    /// Enables custom field updates or additional processing after deferral line setup.
    /// </summary>
    /// <param name="DeferralLine">Deferral line record that was initialized</param>
    /// <remarks>
    /// Raised from InitializeDeferralHeaderAndSetPostDate procedure after initializing deferral line.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnInitializeDeferralHeaderAndSetPostDateAfterInitDeferralLine(var DeferralLine: Record "Deferral Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before setting parameters for deferral schedule page during line editing.
    /// Enables custom parameter setup or validation before opening deferral schedule editor.
    /// </summary>
    /// <param name="DeferralSchedule">Deferral schedule page instance</param>
    /// <param name="DeferralDocType">Document type for the deferral</param>
    /// <param name="GenJnlTemplateName">General journal template name if applicable</param>
    /// <param name="GenJnlBatchName">General journal batch name if applicable</param>
    /// <param name="DocumentType">Document type identifier</param>
    /// <param name="DocumentNo">Document number for the deferral</param>
    /// <param name="DeferralHeader">Deferral header context for the schedule</param>
    /// <param name="IsHandled">Set to true to skip standard parameter setup</param>
    /// <remarks>
    /// Raised from OpenLineScheduleEdit procedure before setting deferral schedule parameters.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnOpenLineScheduleEditOnBeforeDeferralScheduleSetParameters(var DeferralSchedule: Page "Deferral Schedule"; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; DeferralHeader: Record "Deferral Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking deferral conditions for general journal lines.
    /// Enables custom deferral condition logic for journal line processing.
    /// </summary>
    /// <param name="GenJournalLine">General journal line to check for deferral conditions</param>
    /// <param name="IsHandled">Set to true to skip standard deferral condition checking</param>
    /// <remarks>
    /// Raised from CheckDeferralConditionForGenJournal procedure before standard condition validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDeferralConditionForGenJournal(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before removing or setting up deferral schedule for a document line.
    /// Enables custom deferral schedule management logic and validation.
    /// </summary>
    /// <param name="DeferralCode">Deferral template code for the schedule</param>
    /// <param name="DeferralDocType">Document type for the deferral</param>
    /// <param name="GenJnlTemplateName">General journal template name if applicable</param>
    /// <param name="GenJnlBatchName">General journal batch name if applicable</param>
    /// <param name="DocumentType">Document type identifier</param>
    /// <param name="DocumentNo">Document number for the deferral</param>
    /// <param name="LineNo">Line number within the document</param>
    /// <param name="Amount">Deferral amount</param>
    /// <param name="PostingDate">Posting date for the deferral</param>
    /// <param name="Description">Description for the deferral</param>
    /// <param name="CurrencyCode">Currency code for the deferral</param>
    /// <param name="AdjustStartDate">Whether to adjust the start date</param>
    /// <param name="IsHandled">Set to true to skip standard deferral schedule processing</param>
    /// <remarks>
    /// Raised from RemoveOrSetDeferralSchedule procedure before standard schedule management.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemoveOrSetDeferralSchedule(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; Amount: Decimal; PostingDate: Date; Description: Text[100]; CurrencyCode: Code[10]; AdjustStartDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundDeferralAmount(var DeferralHeader: Record "Deferral Header"; CurrencyCode: Code[10]; CurrencyFactor: Decimal; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDeferralScheduleOnCalcMethodElse(CalcMethod: Enum "Deferral Calculation Method"; DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;
}

