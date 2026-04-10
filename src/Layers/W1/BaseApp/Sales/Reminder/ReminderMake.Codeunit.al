// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Receivables;
using System.Globalization;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Creates reminder documents for customers by analyzing overdue ledger entries and applying reminder terms.
/// </summary>
codeunit 392 "Reminder-Make"
{

    trigger OnRun()
    begin
    end;

    var
        TempCurrencyGlobal: Record Currency temporary;
        GlobalCustomer: Record Customer;
        GlobalCustLedgEntry: Record "Cust. Ledger Entry";
        GlobalCustLedgEntry2: Record "Cust. Ledger Entry";
        GlobalReminderTerms: Record "Reminder Terms";
        GlobalReminderHeaderReq: Record "Reminder Header";
        GlobalReminderHeader: Record "Reminder Header";
        GlobalReminderEntry: Record "Reminder/Fin. Charge Entry";
        TempCustLedgerEntryOnHold: Record "Cust. Ledger Entry" temporary;
        GlobalCustLedgEntryLineFeeFilters: Record "Cust. Ledger Entry";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AmountsNotDueLineInserted: Boolean;
        OverdueEntriesOnly: Boolean;
        HeaderExists: Boolean;
        IncludeEntriesOnHold: Boolean;
        OpenEntriesNotDueLbl: Label 'Open Entries Not Due';
        OpenEntriesOnHoldLbl: Label 'Open Entries On Hold';
        CustLedgEntryLastIssuedReminderLevelFilter: Text;

    /// <summary>
    /// Executes the reminder creation process for the configured customer and ledger entry filters.
    /// </summary>
    /// <returns>True if at least one reminder was created successfully; otherwise, false.</returns>
    procedure "Code"() RetVal: Boolean
    var
        ReminderLine: Record "Reminder Line";
        IsHandled: Boolean;
    begin
        CustLedgEntryLastIssuedReminderLevelFilter := GlobalCustLedgEntry.GetFilter("Last Issued Reminder Level");
        if GlobalReminderHeader."No." <> '' then begin
            HeaderExists := true;
            GlobalReminderHeader.TestField("Customer No.");
            GlobalCustomer.Get(GlobalReminderHeader."Customer No.");
            IsHandled := false;
            OnCodeOnAfterGlobalReminderGetGlobalCustomer(GlobalReminderHeader, GlobalCustomer, IsHandled, RetVal);
            if IsHandled then
                exit(RetVal);
            GlobalReminderHeader.TestField("Document Date");
            GlobalReminderHeader.TestField("Reminder Terms Code");
            GlobalReminderHeaderReq := GlobalReminderHeader;
            ReminderLine.SetRange("Reminder No.", GlobalReminderHeader."No.");
            ReminderLine.DeleteAll();
        end;

        IsHandled := false;
        OnCodeOnBeforeGetReminderTerms(GlobalCustomer, GlobalCustLedgEntry, CustLedgEntryLastIssuedReminderLevelFilter, GlobalReminderHeader, IsHandled, RetVal);
        if IsHandled then
            exit(RetVal);
        GetReminderTerms();
        if HeaderExists then
            RetVal := MakeReminder(GlobalReminderHeader."Currency Code")
        else begin
            TempCurrencyGlobal.DeleteAll();
            GlobalCustLedgEntry2.CopyFilters(GlobalCustLedgEntry);
            GlobalCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            GlobalCustLedgEntry.SetRange("Customer No.", GlobalCustomer."No.");
            GlobalCustLedgEntry.SetRange(Open, true);
            GlobalCustLedgEntry.SetRange(Positive, true);
            OnBeforeCustLedgerEntryFind(GlobalCustLedgEntry, GlobalReminderHeaderReq, GlobalCustomer);
            if GlobalCustLedgEntry.FindSet() then
                repeat
                    if GlobalCustLedgEntry."On Hold" = '' then begin
                        TempCurrencyGlobal.Code := GlobalCustLedgEntry."Currency Code";
                        if TempCurrencyGlobal.Insert() then;
                    end;
                until GlobalCustLedgEntry.Next() = 0;
            GlobalCustLedgEntry.CopyFilters(GlobalCustLedgEntry2);
            RetVal := true;
            OnCodeOnBeforeCurrencyLoop(GlobalCustLedgEntry, GlobalReminderHeaderReq, GlobalReminderTerms, OverdueEntriesOnly,
                IncludeEntriesOnHold, HeaderExists, CustLedgEntryLastIssuedReminderLevelFilter, TempCurrencyGlobal,
                GlobalCustomer, GlobalCustLedgEntryLineFeeFilters);
            if TempCurrencyGlobal.FindSet() then
                repeat
                    if not MakeReminder(TempCurrencyGlobal.Code) then
                        RetVal := false;
                until TempCurrencyGlobal.Next() = 0;
        end;

        OnAfterCode(RetVal);
    end;

    local procedure GetReminderTerms()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReminderTerms(GlobalReminderHeader, GlobalReminderTerms, IsHandled);
        if IsHandled then
            exit;

        if GlobalCustomer."Reminder Terms Code" = '' then
            GlobalReminderHeader.TestField("Reminder Terms Code");

        if GlobalReminderHeader."Reminder Terms Code" = '' then begin
            GlobalCustomer.TestField("Reminder Terms Code");
            GlobalReminderTerms.Get(GlobalCustomer."Reminder Terms Code");
        end else
            GlobalReminderTerms.Get(GlobalReminderHeader."Reminder Terms Code")
    end;

    /// <summary>
    /// Initializes the reminder creation parameters for batch processing of customer reminders.
    /// </summary>
    /// <param name="Cust2">Specifies the customer to create reminders for.</param>
    /// <param name="CustLedgEntry2">Specifies the customer ledger entries filter to include.</param>
    /// <param name="ReminderHeaderReq2">Specifies the reminder header settings to use as a template.</param>
    /// <param name="OverdueEntriesOnly2">Specifies whether to include only overdue entries.</param>
    /// <param name="IncludeEntriesOnHold2">Specifies whether to include entries that are on hold.</param>
    /// <param name="CustLedgEntryLinefeeOn">Specifies the customer ledger entries filter for line fee calculation.</param>
    procedure Set(Cust2: Record Customer; var CustLedgEntry2: Record "Cust. Ledger Entry"; ReminderHeaderReq2: Record "Reminder Header"; OverdueEntriesOnly2: Boolean; IncludeEntriesOnHold2: Boolean; var CustLedgEntryLinefeeOn: Record "Cust. Ledger Entry")
    begin
        GlobalCustomer := Cust2;
        GlobalCustLedgEntry.Copy(CustLedgEntry2);
        GlobalReminderHeaderReq := ReminderHeaderReq2;
        OverdueEntriesOnly := OverdueEntriesOnly2;
        IncludeEntriesOnHold := IncludeEntriesOnHold2;
        GlobalCustLedgEntryLineFeeFilters.CopyFilters(CustLedgEntryLinefeeOn);

        OnAfterSet(GlobalCustomer, GlobalCustLedgEntry, GlobalReminderHeaderReq, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLinefeeOn);
    end;

    /// <summary>
    /// Suggests reminder lines for an existing reminder header based on overdue customer ledger entries.
    /// </summary>
    /// <param name="ReminderHeader2">Specifies the reminder header to add suggested lines to.</param>
    /// <param name="CustLedgEntry2">Specifies the customer ledger entries filter to include.</param>
    /// <param name="OverdueEntriesOnly2">Specifies whether to include only overdue entries.</param>
    /// <param name="IncludeEntriesOnHold2">Specifies whether to include entries that are on hold.</param>
    /// <param name="CustLedgEntryLinefeeOn">Specifies the customer ledger entries filter for line fee calculation.</param>
    procedure SuggestLines(ReminderHeader2: Record "Reminder Header"; var CustLedgEntry2: Record "Cust. Ledger Entry"; OverdueEntriesOnly2: Boolean; IncludeEntriesOnHold2: Boolean; var CustLedgEntryLinefeeOn: Record "Cust. Ledger Entry")
    begin
        GlobalReminderHeader := ReminderHeader2;
        GlobalCustLedgEntry.Copy(CustLedgEntry2);
        OverdueEntriesOnly := OverdueEntriesOnly2;
        IncludeEntriesOnHold := IncludeEntriesOnHold2;
        GlobalCustLedgEntryLineFeeFilters.CopyFilters(CustLedgEntryLinefeeOn);
        OnAfterSuggestLines(GlobalReminderHeader, CustLedgEntry2, OverdueEntriesOnly2, IncludeEntriesOnHold2, CustLedgEntryLinefeeOn);
    end;

    local procedure MakeReminder(CurrencyCode: Code[10]) RetVal: Boolean
    var
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        MakeDoc: Boolean;
        StartLineInserted: Boolean;
        NextLineNo: Integer;
        LineLevel: Integer;
        MaxLineLevel: Integer;
        MaxReminderLevel: Integer;
        CustAmount: Decimal;
        ReminderDueDate: Date;
        OpenEntriesNotDueTranslated: Text[100];
        OpenEntriesOnHoldTranslated: Text[100];
        IsHandled: Boolean;
        IsGracePeriodExpired: Boolean;
        ShouldMakeDoc: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeReminder(GlobalReminderHeader, CurrencyCode, RetVal, IsHandled, GlobalReminderHeaderReq, OverdueEntriesOnly, IncludeEntriesOnHold, HeaderExists, GlobalCustomer);
        if IsHandled then
            exit;

        FilterCustLedgEntryReminderLevel(GlobalCustLedgEntry, ReminderLevel, CurrencyCode);
        if not ReminderLevel.FindLast() then
            exit(false);
        TempCustLedgerEntryOnHold.DeleteAll();

        if not FindAndMarkReminderCandidates(GlobalCustLedgEntry, ReminderLevel, CustAmount, MakeDoc, MaxReminderLevel, MaxLineLevel) then
            exit(false);

        ReminderLevel.SetRange("Reminder Terms Code", GlobalReminderTerms.Code);
        ReminderLevel.SetRange("No.", 1, MaxLineLevel);
        if not ReminderLevel.FindLast() then
            ReminderLevel.Init();
        ShouldMakeDoc := MakeDoc and (CustAmount > 0) and (CustAmountLCY(CurrencyCode, CustAmount) >= GlobalReminderTerms."Minimum Amount (LCY)");
        OnMakeReminderOnAfterCalcShouldMakeDoc(GlobalReminderHeaderReq, GlobalReminderHeader, GlobalCustomer, ShouldMakeDoc, MakeDoc, GlobalCustLedgEntry);
        if ShouldMakeDoc then begin
            if CheckCustomerIsBlocked(GlobalCustomer) then
                exit(false);
            ReminderLine.LockTable();
            GlobalReminderHeader.LockTable();
            if not HeaderExists then begin
                GlobalReminderHeader.SetCurrentKey("Customer No.", "Currency Code");
                GlobalReminderHeader.SetRange("Customer No.", GlobalCustomer."No.");
                GlobalReminderHeader.SetRange("Currency Code", CurrencyCode);
                OnBeforeReminderHeaderFind(GlobalReminderHeader, GlobalReminderHeaderReq, GlobalReminderTerms, GlobalCustomer, GlobalCustLedgEntry);
                if GlobalReminderHeader.FindFirst() then
                    exit(false);
                GlobalReminderHeader.Init();
                GlobalReminderHeader."No." := '';
                GlobalReminderHeader."Posting Date" := GlobalReminderHeaderReq."Posting Date";
                OnBeforeReminderHeaderInsert(GlobalReminderHeader, GlobalReminderHeaderReq, GlobalReminderTerms, GlobalCustomer);
                GlobalReminderHeader.Insert(true);
                GlobalReminderHeader.Validate("Customer No.", GlobalCustomer."No.");
                GlobalReminderHeader.Validate("Currency Code", CurrencyCode);
                GlobalReminderHeader."Document Date" := GlobalReminderHeaderReq."Document Date";
                GlobalReminderHeader."Use Header Level" := GlobalReminderHeaderReq."Use Header Level";
            end;
            GlobalReminderHeader."Reminder Level" := ReminderLevel."No.";
            OnBeforeReminderHeaderModify(GlobalReminderHeader, GlobalReminderHeaderReq, HeaderExists, GlobalReminderTerms, GlobalCustomer, ReminderLevel, GlobalCustLedgEntry);
            GlobalReminderHeader.Modify();
            NextLineNo := 0;
            ReminderLevel.MarkedOnly(true);
            GlobalCustLedgEntry.MarkedOnly(true);
            ReminderLevel.FindLast();

            repeat
                StartLineInserted := false;
                FilterCustLedgEntries(ReminderLevel);
                OnMakeReminderOnAfterFilterCustLedgEntries(ReminderLine);
                AmountsNotDueLineInserted := false;
                if GlobalCustLedgEntry.FindSet() then
                    repeat
                        SetReminderLine(LineLevel, ReminderDueDate);
                        IsGracePeriodExpired := IsGracePeriodExpiredForOverdueEntry(ReminderDueDate, GlobalReminderHeaderReq."Document Date", ReminderLevel."Grace Period");
                        OnMakeReminderOnAfterCalcIsGracePeriodExpired(ReminderDueDate, GlobalReminderHeaderReq, IsGracePeriodExpired);
                        if IsGracePeriodExpired then begin
                            if (NextLineNo > 0) and not StartLineInserted then
                                InsertReminderLine(
                                  GlobalReminderHeader."No.", ReminderLine."Line Type"::"Reminder Line", '', NextLineNo);
                            InitReminderLine(
                              ReminderLine, GlobalReminderHeader."No.", ReminderLine."Line Type"::"Reminder Line", '', NextLineNo);
                            ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
                            ReminderLine.Validate("Entry No.", GlobalCustLedgEntry."Entry No.");
                            SetReminderLevel(GlobalReminderHeader, ReminderLine, ReminderLevel."No.");
                            OnBeforeReminderLineInsert(ReminderLine, GlobalReminderHeader, ReminderLevel, GlobalCustLedgEntry, GlobalReminderHeaderReq);
                            ReminderLine.Insert();
                            StartLineInserted := true;

                            AddLineFeeForCustLedgEntry(GlobalCustLedgEntry, ReminderLevel, NextLineNo);
                        end;
                    until GlobalCustLedgEntry.Next() = 0;

                OnMakeReminderOnAfterReminderLevelLoop(ReminderLevel, NextLineNo, StartLineInserted, GlobalReminderHeaderReq, GlobalReminderHeader, GlobalCustomer);
            until ReminderLevel.Next(-1) = 0;

            OnAfterReminderLinesInsertLoop(GlobalReminderHeader, CurrencyCode, NextLineNo, MaxReminderLevel, OverdueEntriesOnly);

            GlobalReminderHeader."Reminder Level" := MaxReminderLevel;
            GlobalReminderHeader.Validate("Reminder Level");
            OnMakeReminderOnBeforeReminderHeaderInsertLines(GlobalReminderHeader);
            GlobalReminderHeader.InsertLines();
            ReminderLine.SetRange("Reminder No.", GlobalReminderHeader."No.");
            ReminderLine.FindLast();
            NextLineNo := ReminderLine."Line No.";
            GetOpenEntriesNotDueOnHoldTranslated(GlobalCustomer."Language Code", OpenEntriesNotDueTranslated, OpenEntriesOnHoldTranslated);
            GlobalCustLedgEntry.SetRange("Last Issued Reminder Level");
            OnMakeReminderOnBeforeCustLedgEntryFindSet(GlobalCustLedgEntry, GlobalCustomer, GlobalReminderHeader, MaxReminderLevel, OverdueEntriesOnly);
            if GlobalCustLedgEntry.FindSet() then
                repeat
                    AddRemiderLinesFromCustLedgEntryWithNoReminderLevelFilter(ReminderLine, ReminderLevel, LineLevel, ReminderDueDate, NextLineNo, OpenEntriesNotDueTranslated, StartLineInserted)
                until GlobalCustLedgEntry.Next() = 0;
            OnMakeReminderOnAfterAddRemiderLinesFromCustLedgEntriesWithNoReminderLevelFilter(GlobalCustLedgEntry, GlobalCustomer, GlobalReminderHeader, MaxReminderLevel, OverdueEntriesOnly);

            if IncludeEntriesOnHold then
                if TempCustLedgerEntryOnHold.FindSet() then begin
                    InsertReminderLine(
                      GlobalReminderHeader."No.", ReminderLine."Line Type"::"On Hold", '', NextLineNo);
                    InsertReminderLine(
                      GlobalReminderHeader."No.", ReminderLine."Line Type"::"On Hold", OpenEntriesOnHoldTranslated, NextLineNo);
                    repeat
                        InitReminderLine(
                          ReminderLine, GlobalReminderHeader."No.", ReminderLine."Line Type"::"On Hold", '', NextLineNo);
                        ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
                        ReminderLine.Validate("Entry No.", TempCustLedgerEntryOnHold."Entry No.");
                        ReminderLine."No. of Reminders" := 0;
                        OnMakeReminderOnBeforeOnHoldReminderLineInsert(ReminderLine, GlobalReminderHeader, ReminderLevel, GlobalCustLedgEntry, TempCustLedgerEntryOnHold);
                        ReminderLine.Insert();
                    until TempCustLedgerEntryOnHold.Next() = 0;
                end;
            OnMakeReminderOnBeforeReminderHeaderModify(GlobalReminderHeader, ReminderLine, NextLineNo, MaxReminderLevel);
            GlobalReminderHeader.Modify();
        end;

        RemoveLinesOfNegativeReminder(GlobalReminderHeader);

        ReminderLevel.Reset();
        GlobalCustLedgEntry.Reset();

        OnAfterMakeReminder(GlobalReminderHeader, ReminderLine);

        exit(true);
    end;

    local procedure AddRemiderLinesFromCustLedgEntryWithNoReminderLevelFilter(var ReminderLine: Record "Reminder Line"; var ReminderLevel: Record "Reminder Level"; LineLevel: Integer; ReminderDueDate: Date; var NextLineNo: Integer; OpenEntriesNotDueTranslated: Text[100]; var StartLineInserted: Boolean)
    var
        IsHandled: Boolean;
        IsGracePeriodExpired: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddRemiderLinesFromCustLedgEntryWithNoReminderLevelFilter(GlobalCustLedgEntry, GlobalReminderHeaderReq, GlobalReminderHeader, IsHandled, ReminderLine, NextLineNo, StartLineInserted);
        if IsHandled then
            exit;

        if (not OverdueEntriesOnly) or
           (GlobalCustLedgEntry."Document Type" in [GlobalCustLedgEntry."Document Type"::Payment, GlobalCustLedgEntry."Document Type"::Refund])
        then begin
            SetReminderLine(LineLevel, ReminderDueDate);
            IsGracePeriodExpired :=
                IsGracePeriodExpiredForOverdueEntry(ReminderDueDate, GlobalReminderHeaderReq."Document Date", ReminderLevel."Grace Period");
            if (not IsGracePeriodExpired) and (LineLevel = 1) then begin
                OnAddRemiderLinesFromCustLedgEntryWithNoReminderLevelFilterOnBeforeCheckAmountsNotDueLineInserted(
                    GlobalReminderHeader, ReminderLine, AmountsNotDueLineInserted);
                if not AmountsNotDueLineInserted then begin
                    InsertReminderLine(GlobalReminderHeader."No.", ReminderLine."Line Type"::"Not Due", '', NextLineNo);
                    InsertReminderLine(
                      GlobalReminderHeader."No.", ReminderLine."Line Type"::"Not Due", OpenEntriesNotDueTranslated, NextLineNo);
                    AmountsNotDueLineInserted := true;
                end;
                InitReminderLine(
                  ReminderLine, GlobalReminderHeader."No.", ReminderLine."Line Type"::"Not Due", '', NextLineNo);
                ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
                ReminderLine.Validate("Entry No.", GlobalCustLedgEntry."Entry No.");
                ReminderLine."No. of Reminders" := 0;
                OnAddRemiderLinesFromCustLedgEntryWithNoReminderLevelFilterOnBeforeReminderLineInsert(ReminderLine, GlobalReminderHeader, ReminderLevel, GlobalCustLedgEntry);
                ReminderLine.Insert();
                AmountsNotDueLineInserted := true;
                RemoveNotDueLinesInSectionReminderLine(ReminderLine);
            end;
        end;
    end;

    local procedure FindAndMarkReminderCandidates(var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderLevel: Record "Reminder Level"; var CustAmount: Decimal; var MakeDoc: Boolean; var MaxReminderLevel: Integer; var MaxLineLevel: Integer) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindAndMarkReminderCandidates(
            ReminderLevel, GlobalReminderHeaderReq, GlobalReminderTerms, GlobalReminderEntry,
            CustLedgEntry, TempCustLedgerEntryOnHold, CustLedgEntryLastIssuedReminderLevelFilter, CustAmount,
            MakeDoc, MaxReminderLevel, MaxLineLevel, OverdueEntriesOnly, IncludeEntriesOnHold, IsHandled, Result);
        if IsHandled then
            exit(Result);

        repeat
            FilterCustLedgEntries(ReminderLevel);
            if CustLedgEntry.FindSet() then
                repeat
                    IsHandled := false;
                    OnFindAndMarkReminderCandidatesOnBeforeCustLedgEntryLoop(CustLedgEntry, GlobalReminderHeaderReq, IsHandled);
                    if not IsHandled then
                        if CustLedgEntry."On Hold" = '' then
                            MarkReminderCandidate(CustLedgEntry, ReminderLevel, CustAmount, MakeDoc, MaxReminderLevel, MaxLineLevel)
                        else // The customer ledger entry is on hold
                            if IncludeEntriesOnHold then begin
                                TempCustLedgerEntryOnHold := CustLedgEntry;
                                TempCustLedgerEntryOnHold.Insert();
                            end;
                until CustLedgEntry.Next() = 0;
        until ReminderLevel.Next(-1) = 0;

        IsHandled := false;
        OnAfterFindAndMarkReminderCandidates(GlobalCustLedgEntry, ReminderLevel, CustAmount, MakeDoc, MaxReminderLevel, MaxLineLevel, IsHandled, Result);
        if IsHandled then
            exit(Result);

        exit(true);
    end;

    local procedure MarkReminderCandidate(var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderLevel: Record "Reminder Level"; var CustAmount: Decimal; var MakeDoc: Boolean; var MaxReminderLevel: Integer; var MaxLineLevel: Integer)
    var
        ReminderDueDate: Date;
        LineLevel: Integer;
        MarkEntry: Boolean;
        IsHandled: Boolean;
        IsGracePeriodExpired: Boolean;
    begin
        IsHandled := false;
        OnBeforeMarkReminderCandidate(CustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        SetReminderLine(LineLevel, ReminderDueDate);
        IsGracePeriodExpired := IsGracePeriodExpiredForOverdueEntry(ReminderDueDate, GlobalReminderHeaderReq."Document Date", ReminderLevel."Grace Period");
        IsHandled := false;
        OnMarkReminderCandidateOnAfterCalcIsGracePeriodExpired(ReminderLevel, ReminderDueDate, GlobalReminderHeaderReq, GlobalReminderTerms, CustLedgEntry, GlobalReminderHeader, LineLevel, IsGracePeriodExpired, IsHandled);
        if IsHandled then
            exit;

        MarkEntry := false;
        if IsGracePeriodExpired and
           ((LineLevel <= GlobalReminderTerms."Max. No. of Reminders") or (GlobalReminderTerms."Max. No. of Reminders" = 0))
        then begin
            MarkEntry := true;
            CustLedgEntry.CalcFields("Remaining Amount");
            CustAmount += CustLedgEntry."Remaining Amount";
            if CustLedgEntry.Positive and IsGracePeriodExpired then
                MakeDoc := true;
        end else
            if not IsGracePeriodExpired and
               (not OverdueEntriesOnly or
                (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Payment, CustLedgEntry."Document Type"::Refund]))
            then
                MarkEntry := true;

        if MarkEntry then begin
            CustLedgEntry.Mark(true);
            ReminderLevel.Mark(true);
            if (ReminderLevel."No." > MaxReminderLevel) and
               (CustLedgEntry."Document Type" <> CustLedgEntry."Document Type"::"Credit Memo") and
               IsGracePeriodExpired
            then
                MaxReminderLevel := ReminderLevel."No.";
            if MaxLineLevel < LineLevel then
                MaxLineLevel := LineLevel;
        end;
    end;

    local procedure InsertReminderLine(ReminderNo: Code[50]; LineType: Enum "Reminder Line Type"; Description: Text[100]; var NextLineNo: Integer)
    var
        ReminderLine: Record "Reminder Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReminderLine(ReminderNo, LineType, Description, NextLineNo, IsHandled);
        if IsHandled then
            exit;

        InitReminderLine(ReminderLine, ReminderNo, LineType, Description, NextLineNo);
        ReminderLine.Insert();
    end;

    local procedure InitReminderLine(var ReminderLine: Record "Reminder Line"; ReminderNo: Code[50]; LineType: Enum "Reminder Line Type"; Description: Text[100]; var NextLineNo: Integer)
    begin
        NextLineNo := GetLastLineNo(GlobalReminderHeader."No.") + 10000;

        ReminderLine.Init();
        ReminderLine."Reminder No." := CopyStr(ReminderNo, 1, MaxStrLen(ReminderLine."Reminder No."));
        ReminderLine."Line No." := NextLineNo;
        ReminderLine."Line Type" := LineType;
        ReminderLine.Description := Description;

        OnAfterInitReminderLine(GlobalReminderHeader, ReminderLine, LineType, Description);
    end;

    local procedure CustAmountLCY(CurrencyCode: Code[10]; Amount: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if CurrencyCode <> '' then
            exit(
              CurrExchRate.ExchangeAmtFCYToLCY(
                GlobalReminderHeaderReq."Posting Date", CurrencyCode, Amount,
                CurrExchRate.ExchangeRate(GlobalReminderHeaderReq."Posting Date", CurrencyCode)));
        exit(Amount);
    end;

    /// <summary>
    /// Applies filters to customer ledger entries based on the specified reminder level.
    /// </summary>
    /// <param name="ReminderLevel2">Specifies the reminder level to filter customer ledger entries by.</param>
    procedure FilterCustLedgEntries(var ReminderLevel2: Record "Reminder Level")
    var
        ReminderLevel3: Record "Reminder Level";
        LastLevel: Boolean;
    begin
        if SkipCurrentReminderLevel(ReminderLevel2."No.") then begin
            GlobalCustLedgEntry.SetRange("Last Issued Reminder Level", -1);
            exit;
        end;
        ReminderLevel3 := ReminderLevel2;
        ReminderLevel3.CopyFilters(ReminderLevel2);
        if ReminderLevel3.Next() = 0 then
            LastLevel := true
        else
            LastLevel := false;
        if GlobalReminderTerms."Max. No. of Reminders" > 0 then
            if ReminderLevel2."No." <= GlobalReminderTerms."Max. No. of Reminders" then
                if LastLevel then
                    GlobalCustLedgEntry.SetRange("Last Issued Reminder Level", ReminderLevel2."No." - 1, GlobalReminderTerms."Max. No. of Reminders" - 1)
                else
                    GlobalCustLedgEntry.SetRange("Last Issued Reminder Level", ReminderLevel2."No." - 1)
            else
                GlobalCustLedgEntry.SetRange("Last Issued Reminder Level", -1)
        else
            if LastLevel then
                GlobalCustLedgEntry.SetFilter("Last Issued Reminder Level", '%1..', ReminderLevel2."No." - 1)
            else
                GlobalCustLedgEntry.SetRange("Last Issued Reminder Level", ReminderLevel2."No." - 1);
    end;

    local procedure SkipCurrentReminderLevel(ReminderLevelNo: Integer): Boolean
    var
        "Integer": Record "Integer";
    begin
        if CustLedgEntryLastIssuedReminderLevelFilter = '' then
            exit(false);

        Integer.SetFilter(Number, CustLedgEntryLastIssuedReminderLevelFilter);
        Integer.FindSet();
        if Integer.Number > ReminderLevelNo - 1 then
            exit(true);
        repeat
            if Integer.Number = ReminderLevelNo - 1 then
                exit(false)
        until Integer.Next() = 0;
        exit(true);
    end;

    local procedure FilterCustLedgEntryReminderLevel(var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderLevel: Record "Reminder Level"; CurrencyCode: Code[10])
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Customer No.", GlobalCustomer."No.");
        CustLedgEntry.SetRange("Currency Code", CurrencyCode);
        ReminderLevel.SetRange("Reminder Terms Code", GlobalReminderTerms.Code);

        OnAfterFilterCustLedgEntryReminderLevel(CustLedgEntry, ReminderLevel, GlobalReminderTerms, GlobalCustomer, GlobalReminderHeaderReq, GlobalReminderHeader);
    end;

    /// <summary>
    /// Calculates the reminder level and due date for a customer ledger entry based on previous reminder history.
    /// </summary>
    /// <param name="LineLevel2">Returns the calculated reminder level for the entry.</param>
    /// <param name="ReminderDueDate2">Returns the due date for the reminder entry.</param>
    procedure SetReminderLine(var LineLevel2: Integer; var ReminderDueDate2: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetReminderLine(LineLevel2, ReminderDueDate2, IsHandled, GlobalCustLedgEntry, GlobalReminderEntry);
        if not IsHandled then begin
            if GlobalCustLedgEntry."Last Issued Reminder Level" > 0 then begin
                GlobalReminderEntry.SetCurrentKey("Customer Entry No.", Type);
                GlobalReminderEntry.SetRange("Customer Entry No.", GlobalCustLedgEntry."Entry No.");
                GlobalReminderEntry.SetRange(Type, GlobalReminderEntry.Type::Reminder);
                GlobalReminderEntry.SetRange("Reminder Level", GlobalCustLedgEntry."Last Issued Reminder Level");
                GlobalReminderEntry.SetRange(Canceled, false);
                OnSetReminderLineOnAfterSetFilters(GlobalReminderEntry);
                if GlobalReminderEntry.FindLast() then begin
                    ReminderDueDate2 := GlobalReminderEntry."Due Date";
                    LineLevel2 := GlobalReminderEntry."Reminder Level" + 1;
                    OnSetReminderLineOnAfterFindNextLineLevel(GlobalReminderEntry, LineLevel2, ReminderDueDate2);
                    exit;
                end
            end;
            ReminderDueDate2 := GlobalCustLedgEntry."Due Date";
            LineLevel2 := 1;
        end;

        OnAfterSetReminderLine(GlobalCustLedgEntry, LineLevel2, ReminderDueDate2);
    end;

    /// <summary>
    /// Adds a line fee for a customer ledger entry if applicable based on reminder level settings.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry to add a line fee for.</param>
    /// <param name="ReminderLevel">Specifies the reminder level containing the line fee settings.</param>
    /// <param name="NextLineNo">Specifies the next line number to use for the reminder line.</param>
    procedure AddLineFeeForCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderLevel: Record "Reminder Level"; NextLineNo: Integer)
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        ReminderLine: Record "Reminder Line";
        IssuedReminderLine: Record "Issued Reminder Line";
        CustPostingGr: Record "Customer Posting Group";
        LineFeeAmount: Decimal;
    begin
        TempCustLedgEntry := CustLedgEntry;
        TempCustLedgEntry.Insert();
        TempCustLedgEntry.Reset();
        TempCustLedgEntry.CopyFilters(GlobalCustLedgEntryLineFeeFilters);
        if TempCustLedgEntry.IsEmpty() then
            exit;

        CustLedgEntry.CalcFields("Remaining Amount");
        OnAddLineFeeForCustLedgEntryOnAfterCalcRemainingAmount(CustLedgEntry);
        LineFeeAmount := ReminderLevel.GetAdditionalFee(CustLedgEntry."Remaining Amount",
            GlobalReminderHeader."Currency Code", true, GlobalReminderHeader."Posting Date");
        if LineFeeAmount = 0 then
            exit;

        IssuedReminderLine.SetRange(Type, IssuedReminderLine.Type::"Line Fee");
        IssuedReminderLine.SetRange("Applies-To Document Type", CustLedgEntry."Document Type");
        IssuedReminderLine.SetRange("Applies-To Document No.", CustLedgEntry."Document No.");
        IssuedReminderLine.SetRange("No. of Reminders", ReminderLevel."No.");
        IssuedReminderLine.SetRange(Canceled, false);
        if not IssuedReminderLine.IsEmpty() then
            exit;

        CustPostingGr.Get(GlobalReminderHeader."Customer Posting Group");

        NextLineNo := NextLineNo + 100;
        ReminderLine.Init();
        ReminderLine.Validate("Reminder No.", GlobalReminderHeader."No.");
        ReminderLine.Validate("Line No.", NextLineNo);
        ReminderLine.Validate(Type, ReminderLine.Type::"Line Fee");
        ReminderLine.Validate("No.", CustPostingGr.GetAddFeePerLineAccount());
        ReminderLine.Validate("No. of Reminders", ReminderLevel."No.");
        ReminderLine.Validate("Applies-to Document Type", CustLedgEntry."Document Type");
        ReminderLine.Validate("Applies-to Document No.", CustLedgEntry."Document No.");
        ReminderLine.Validate("Due Date", CalcDate(ReminderLevel."Due Date Calculation", GlobalReminderHeader."Document Date"));
        OnAddLineFeeForCustLedgEntryOnReminderLineInsert(ReminderLine);
        ReminderLine.Insert(true);
    end;

    internal procedure EmitCreateReminderTelemetry()
    begin
        FeatureTelemetry.LogUptake('0000LB0', 'Reminder', Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUptake('0000LB1', 'Reminder', Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000LB2', 'Reminder', 'Make Reminder called.');
    end;

    local procedure GetLastLineNo(ReminderNo: Code[50]): Integer
    var
        ReminderLineExtra: Record "Reminder Line";
    begin
        ReminderLineExtra.SetRange("Reminder No.", ReminderNo);
        if ReminderLineExtra.FindLast() then;
        exit(ReminderLineExtra."Line No.");
    end;

    local procedure SetReminderLevel(ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; LineLevel: Integer)
    begin
        if ReminderHeader."Use Header Level" then
            ReminderLine."No. of Reminders" := ReminderHeader."Reminder Level"
        else
            ReminderLine."No. of Reminders" := LineLevel;
    end;

    local procedure RemoveLinesOfNegativeReminder(var ReminderHeader: Record "Reminder Header")
    var
        ReminderTotal: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRemoveLinesOfNegativeReminder(ReminderHeader, GlobalReminderHeaderReq, GlobalCustomer, IsHandled);
        if IsHandled then
            exit;

        ReminderHeader.CalcFields(
          "Remaining Amount", "Interest Amount", "Additional Fee", "VAT Amount");

        ReminderTotal := ReminderHeader."Remaining Amount" + ReminderHeader."Interest Amount" +
          ReminderHeader."Additional Fee" + ReminderHeader."VAT Amount";

        if ReminderTotal < 0 then
            ReminderHeader.Delete(true);
    end;

    local procedure GetOpenEntriesNotDueOnHoldTranslated(CustomerLanguageCode: Code[10]; var OpenEntriesNotDueTranslated: Text[100]; var OpenEntriesOnHoldTranslated: Text[100])
    var
        Language: Codeunit Language;
        CurrentLanguageCode: Integer;
    begin
        if CustomerLanguageCode <> '' then begin
            CurrentLanguageCode := GlobalLanguage;
            GlobalLanguage(Language.GetLanguageIdOrDefault(CustomerLanguageCode));
            OpenEntriesNotDueTranslated := OpenEntriesNotDueLbl;
            OpenEntriesOnHoldTranslated := OpenEntriesOnHoldLbl;
            GlobalLanguage(CurrentLanguageCode);
        end else begin
            OpenEntriesNotDueTranslated := OpenEntriesNotDueLbl;
            OpenEntriesOnHoldTranslated := OpenEntriesOnHoldLbl;
        end;
    end;

    local procedure RemoveNotDueLinesInSectionReminderLine(ReminderLine: Record "Reminder Line")
    var
        ReminderLineToDelete: Record "Reminder Line";
    begin
        ReminderLineToDelete.SetRange("Reminder No.", ReminderLine."Reminder No.");
        ReminderLineToDelete.SetRange(Type, ReminderLine.Type);
        ReminderLineToDelete.SetRange("Entry No.", ReminderLine."Entry No.");
        ReminderLineToDelete.SetRange("Document Type", ReminderLine."Document Type");
        ReminderLineToDelete.SetRange("Document No.", ReminderLine."Document No.");
        ReminderLineToDelete.SetFilter("Line Type", '<>%1', ReminderLine."Line Type");
        if ReminderLineToDelete.FindFirst() then
            ReminderLineToDelete.Delete(true);
    end;

    local procedure CheckCustomerIsBlocked(Customer: Record Customer) Result: Boolean
    begin
        Result := Customer.Blocked = Customer.Blocked::All;
        OnAfterCheckCustomerIsBlocked(Customer, Result);
    end;

    local procedure IsGracePeriodExpiredForOverdueEntry(DueDate: Date; ReminderDocumentDate: Date; GracePeriod: DateFormula): Boolean
    begin
        exit(CalcDate(GracePeriod, DueDate) < ReminderDocumentDate);
    end;

    /// <summary>
    /// Raised after the reminder creation process completes.
    /// </summary>
    /// <param name="RetVal">Indicates whether at least one reminder was created successfully.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var RetVal: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after filters are applied to customer ledger entries based on reminder level.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry record being filtered.</param>
    /// <param name="ReminderLevel">The reminder level used for filtering.</param>
    /// <param name="ReminderTerms">The reminder terms configuration.</param>
    /// <param name="Customer">The customer record for the reminder.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="ReminderHeader">The reminder header being created.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterCustLedgEntryReminderLevel(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ReminderLevel: Record "Reminder Level"; ReminderTerms: Record "Reminder Terms"; Customer: Record Customer; ReminderHeaderReq: Record "Reminder Header"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised after a reminder line is initialized with default values.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header for the line.</param>
    /// <param name="ReminderLine">The initialized reminder line.</param>
    /// <param name="LineType">The type of the reminder line.</param>
    /// <param name="Description">The description for the reminder line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReminderLine(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; LineType: Enum "Reminder Line Type"; Description: Text)
    begin
    end;

    /// <summary>
    /// Raised after a reminder document is created with all its lines.
    /// </summary>
    /// <param name="ReminderHeader">The completed reminder header.</param>
    /// <param name="ReminderLine">The last reminder line processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeReminder(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    /// <summary>
    /// Raised after the reminder creation parameters are set.
    /// </summary>
    /// <param name="Cust">The customer for reminder creation.</param>
    /// <param name="CustLedgEntry">The customer ledger entries filter.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="OverdueEntriesOnly">Indicates whether only overdue entries are included.</param>
    /// <param name="IncludeEntriesOnHold">Indicates whether entries on hold are included.</param>
    /// <param name="CustLedgEntryLinefeeOn">The customer ledger entries filter for line fees.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSet(var Cust: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderHeaderReq: Record "Reminder Header"; var OverdueEntriesOnly: Boolean; var IncludeEntriesOnHold: Boolean; var CustLedgEntryLinefeeOn: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after the reminder level and due date are calculated for a customer ledger entry.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry being processed.</param>
    /// <param name="LineLevel2">The calculated reminder level for the entry.</param>
    /// <param name="ReminderDueDate2">The calculated due date for the reminder.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReminderLine(CustLedgEntry: Record "Cust. Ledger Entry"; var LineLevel2: Integer; var ReminderDueDate2: Date)
    begin
    end;

    /// <summary>
    /// Raised after the suggest lines parameters are set for an existing reminder.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header to add lines to.</param>
    /// <param name="CustLedgEntry2">The customer ledger entries filter.</param>
    /// <param name="OverdueEntriesOnly2">Indicates whether only overdue entries are included.</param>
    /// <param name="IncludeEntriesOnHold2">Indicates whether entries on hold are included.</param>
    /// <param name="CustLedgEntryLinefeeOn">The customer ledger entries filter for line fees.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestLines(ReminderHeader: Record "Reminder Header"; var CustLedgEntry2: Record "Cust. Ledger Entry"; OverdueEntriesOnly2: Boolean; IncludeEntriesOnHold2: Boolean; var CustLedgEntryLinefeeOn: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after the remaining amount is calculated for a customer ledger entry when adding line fees.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry with calculated remaining amount.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAddLineFeeForCustLedgEntryOnAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before inserting a line fee reminder line.
    /// </summary>
    /// <param name="ReminderLine">The line fee reminder line to be inserted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAddLineFeeForCustLedgEntryOnReminderLineInsert(var ReminderLine: Record "Reminder Line")
    begin
    end;

    /// <summary>
    /// Raised before checking if the amounts not due line has been inserted.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header being processed.</param>
    /// <param name="ReminderLine">The current reminder line.</param>
    /// <param name="AmountsNotDueLineInserted">Indicates whether the amounts not due line has been inserted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAddRemiderLinesFromCustLedgEntryWithNoReminderLevelFilterOnBeforeCheckAmountsNotDueLineInserted(ReminderHeader: Record "Reminder Header"; ReminderLine: Record "Reminder Line"; var AmountsNotDueLineInserted: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before adding reminder lines from customer ledger entries with no reminder level filter.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry to add.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="ReminderHeader">The reminder header being created.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    /// <param name="ReminderLine">The reminder line being created.</param>
    /// <param name="NextLineNo">The next line number to use.</param>
    /// <param name="StartLineInserted">Indicates whether a start line was inserted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddRemiderLinesFromCustLedgEntryWithNoReminderLevelFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; ReminderHeaderReq: Record "Reminder Header"; ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean; var ReminderLine: Record "Reminder Line"; var NextLineNo: Integer; var StartLineInserted: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before finding customer ledger entries for reminder creation.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry record to search.</param>
    /// <param name="ReminderHeader">The reminder header request parameters.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustLedgerEntryFind(var CustLedgerEntry: Record "Cust. Ledger Entry"; ReminderHeader: Record "Reminder Header"; Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised before retrieving the reminder terms for a customer.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header being processed.</param>
    /// <param name="ReminderTerms">The reminder terms to retrieve.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReminderTerms(var ReminderHeader: Record "Reminder Header"; var ReminderTerms: Record "Reminder Terms"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before finding and marking customer ledger entries as reminder candidates.
    /// </summary>
    /// <param name="ReminderLevel">The reminder level configuration.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="ReminderTerms">The reminder terms configuration.</param>
    /// <param name="ReminderEntry">The reminder entry record for history lookup.</param>
    /// <param name="CustLedgEntry">The customer ledger entries to process.</param>
    /// <param name="TempCustLedgEntryOnHold">Temporary table for entries on hold.</param>
    /// <param name="CustLedgEntryLastIssuedReminderLevelFilter">Filter for last issued reminder level.</param>
    /// <param name="CustAmount">The cumulative customer amount.</param>
    /// <param name="MakeDoc">Indicates whether to create a reminder document.</param>
    /// <param name="MaxReminderLevel">The maximum reminder level found.</param>
    /// <param name="MaxLineLevel">The maximum line level found.</param>
    /// <param name="OverdueEntriesOnly">Indicates whether only overdue entries are included.</param>
    /// <param name="IncludeEntriesOnHold">Indicates whether entries on hold are included.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    /// <param name="Result">Returns the result when handling is skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindAndMarkReminderCandidates(var ReminderLevel: Record "Reminder Level"; ReminderHeaderReq: Record "Reminder Header"; ReminderTerms: Record "Reminder Terms"; var ReminderEntry: Record "Reminder/Fin. Charge Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var TempCustLedgEntryOnHold: Record "Cust. Ledger Entry" temporary; var CustLedgEntryLastIssuedReminderLevelFilter: Text; var CustAmount: Decimal; var MakeDoc: Boolean; var MaxReminderLevel: Integer; var MaxLineLevel: Integer; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a reminder line.
    /// </summary>
    /// <param name="ReminderNo">The reminder document number.</param>
    /// <param name="LineType">The type of the reminder line.</param>
    /// <param name="Description">The description for the line.</param>
    /// <param name="NextLineNo">The next line number to use.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReminderLine(ReminderNo: Code[20]; LineType: Enum "Reminder Line Type"; Description: Text[100]; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before creating a reminder for a specific currency.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header to create.</param>
    /// <param name="CurrencyCode">The currency code for the reminder.</param>
    /// <param name="RetVal">Returns the result when handling is skipped.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="OverdueEntriesOnly">Indicates whether only overdue entries are included.</param>
    /// <param name="IncludeEntriesOnHold">Indicates whether entries on hold are included.</param>
    /// <param name="HeaderExists">Indicates whether a reminder header already exists.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeReminder(var ReminderHeader: Record "Reminder Header"; CurrencyCode: Code[10]; var RetVal: Boolean; var IsHandled: Boolean; ReminderHeaderReq: Record "Reminder Header"; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean; HeaderExists: Boolean; Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised before marking a customer ledger entry as a reminder candidate.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry to evaluate.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeMarkReminderCandidate(var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before removing lines from a reminder with negative total amount.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header to evaluate.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemoveLinesOfNegativeReminder(var ReminderHeader: Record "Reminder Header"; ReminderHeaderReq: Record "Reminder Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before finding an existing reminder header for the customer and currency.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record to search.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="ReminderTerms">The reminder terms configuration.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderHeaderFind(var ReminderHeader: Record "Reminder Header"; ReminderHeaderReq: Record "Reminder Header"; ReminderTerms: Record "Reminder Terms"; Customer: Record Customer; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before inserting a new reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header to insert.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="ReminderTerms">The reminder terms configuration.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderHeaderInsert(var ReminderHeader: Record "Reminder Header"; ReminderHeaderReq: Record "Reminder Header"; ReminderTerms: Record "Reminder Terms"; Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised before modifying the reminder header with reminder level and other settings.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header to modify.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="HeaderExists">Indicates whether the header already existed.</param>
    /// <param name="ReminderTerms">The reminder terms configuration.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    /// <param name="ReminderLevel">The reminder level being applied.</param>
    /// <param name="CustLedgerEntry">The customer ledger entries being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderHeaderModify(var ReminderHeader: Record "Reminder Header"; var ReminderHeaderReq: Record "Reminder Header"; HeaderExists: Boolean; ReminderTerms: Record "Reminder Terms"; Customer: Record Customer; ReminderLevel: Record "Reminder Level"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before inserting a reminder line for a customer ledger entry.
    /// </summary>
    /// <param name="ReminderLine">The reminder line to insert.</param>
    /// <param name="ReminderHeader">The reminder header for the line.</param>
    /// <param name="ReminderLevel">The reminder level for the line.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry for the line.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderLineInsert(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header"; ReminderLevel: Record "Reminder Level"; CustLedgerEntry: Record "Cust. Ledger Entry"; ReminderHeaderReq: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised before processing reminders for each currency.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entries to process.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="ReminderTerms">The reminder terms configuration.</param>
    /// <param name="OverdueEntriesOnly">Indicates whether only overdue entries are included.</param>
    /// <param name="IncludeEntriesOnHold">Indicates whether entries on hold are included.</param>
    /// <param name="HeaderExists">Indicates whether a reminder header already exists.</param>
    /// <param name="CustLedgEntryLastIssuedReminderLevelFilter">Filter for last issued reminder level.</param>
    /// <param name="TempCurrency">Temporary table of currencies to process.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    /// <param name="CustLedgEntryLineFeeFilters">The customer ledger entries filter for line fees.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCurrencyLoop(CustLedgEntry: Record "Cust. Ledger Entry"; ReminderHeaderReq: Record "Reminder Header"; ReminderTerms: Record "Reminder Terms"; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean; HeaderExists: Boolean; CustLedgEntryLastIssuedReminderLevelFilter: Text; var TempCurrency: Record Currency temporary; Customer: Record Customer; var CustLedgEntryLineFeeFilters: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before retrieving reminder terms for processing.
    /// </summary>
    /// <param name="Customer">The customer to get reminder terms for.</param>
    /// <param name="CustLedgerEntry">The customer ledger entries being processed.</param>
    /// <param name="CustLedgEntryLastIssuedReminderLevelFilter">Filter for last issued reminder level.</param>
    /// <param name="ReminderHeader">The reminder header being processed.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    /// <param name="ReturnValue">Returns the result when handling is skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeGetReminderTerms(var Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgEntryLastIssuedReminderLevelFilter: Text; var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before processing each customer ledger entry in the reminder candidate loop.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry being processed.</param>
    /// <param name="ReminderHeader">The reminder header request parameters.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFindAndMarkReminderCandidatesOnBeforeCustLedgEntryLoop(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after finding and marking reminder candidates from customer ledger entries.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entries processed.</param>
    /// <param name="ReminderLevel">The reminder level configuration.</param>
    /// <param name="CustAmount">The cumulative customer amount.</param>
    /// <param name="MakeDoc">Indicates whether to create a reminder document.</param>
    /// <param name="MaxReminderLevel">The maximum reminder level found.</param>
    /// <param name="MaxLineLevel">The maximum line level found.</param>
    /// <param name="IsHandled">Set to true to skip default result.</param>
    /// <param name="Result">Returns the result when handling is skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindAndMarkReminderCandidates(CustLedgEntry: Record "Cust. Ledger Entry"; ReminderLevel: Record "Reminder Level"; var CustAmount: Decimal; MakeDoc: Boolean; MaxReminderLevel: Integer; MaxLineLevel: Integer; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after calculating whether a reminder document should be created.
    /// </summary>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="ReminderHeader">The reminder header being created.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    /// <param name="ShouldMakeDoc">Indicates whether a reminder document should be created.</param>
    /// <param name="MakeDoc">The original make document flag.</param>
    /// <param name="CustLedgerEntry">The customer ledger entries being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeReminderOnAfterCalcShouldMakeDoc(ReminderHeaderReq: Record "Reminder Header"; ReminderHeader: Record "Reminder Header"; Customer: Record Customer; var ShouldMakeDoc: Boolean; MakeDoc: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after adding reminder lines from customer ledger entries with no reminder level filter.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entries processed.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    /// <param name="ReminderHeader">The reminder header being created.</param>
    /// <param name="MaxReminderLevel">The maximum reminder level.</param>
    /// <param name="OverdueEntriesOnly">Indicates whether only overdue entries are included.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeReminderOnAfterAddRemiderLinesFromCustLedgEntriesWithNoReminderLevelFilter(var CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer; ReminderHeader: Record "Reminder Header"; MaxReminderLevel: Integer; var OverdueEntriesOnly: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after processing each reminder level in the reminder creation loop.
    /// </summary>
    /// <param name="ReminderLevel">The reminder level processed.</param>
    /// <param name="NextLineNo">The next line number available.</param>
    /// <param name="StartLineInserted">Indicates whether a start line was inserted.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="ReminderHeader">The reminder header being created.</param>
    /// <param name="Customer">The customer for the reminder.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeReminderOnAfterReminderLevelLoop(var ReminderLevel: Record "Reminder Level"; var NextLineNo: Integer; StartLineInserted: Boolean; ReminderHeaderReq: Record "Reminder Header"; ReminderHeader: Record "Reminder Header"; Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised after calculating whether the grace period has expired for an overdue entry.
    /// </summary>
    /// <param name="ReminderDueDate">The due date of the reminder entry.</param>
    /// <param name="ReminderHeader">The reminder header request parameters.</param>
    /// <param name="IsGracePeriodExpired">Indicates whether the grace period has expired.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeReminderOnAfterCalcIsGracePeriodExpired(var ReminderDueDate: Date; var ReminderHeader: Record "Reminder Header"; var IsGracePeriodExpired: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before finding customer ledger entries for processing in the reminder creation.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry record to search.</param>
    /// <param name="Cust">The customer for the reminder.</param>
    /// <param name="ReminderHeader">The reminder header being created.</param>
    /// <param name="MaxReminderLevel">The maximum reminder level.</param>
    /// <param name="OverDueEntriesOnly">Indicates whether only overdue entries are included.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeReminderOnBeforeCustLedgEntryFindSet(var CustLedgEntry: Record "Cust. Ledger Entry"; Cust: Record Customer; ReminderHeader: Record "Reminder Header"; MaxReminderLevel: Integer; var OverDueEntriesOnly: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a reminder line for an on-hold customer ledger entry.
    /// </summary>
    /// <param name="ReminderLine">The reminder line to insert.</param>
    /// <param name="ReminderHeader">The reminder header for the line.</param>
    /// <param name="ReminderLevel">The reminder level configuration.</param>
    /// <param name="CustLedgerEntry">The customer ledger entries being processed.</param>
    /// <param name="CustLedgEntryOnHoldTEMP">Temporary table of entries on hold.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeReminderOnBeforeOnHoldReminderLineInsert(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header"; ReminderLevel: Record "Reminder Level"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgEntryOnHoldTEMP: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    /// <summary>
    /// Raised before modifying the reminder header after all lines are processed.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header to modify.</param>
    /// <param name="ReminderLine">The last reminder line processed.</param>
    /// <param name="NextLineNo">The next line number available.</param>
    /// <param name="MaxReminderLevel">The maximum reminder level.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeReminderOnBeforeReminderHeaderModify(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; var NextLineNo: Integer; MaxReminderLevel: Integer)
    begin
    end;

    /// <summary>
    /// Raised after calculating whether the grace period has expired when marking reminder candidates.
    /// </summary>
    /// <param name="ReminderLevel">The reminder level configuration.</param>
    /// <param name="ReminderDueDate">The due date of the reminder entry.</param>
    /// <param name="ReminderHeaderReq">The reminder header request parameters.</param>
    /// <param name="ReminderTerms">The reminder terms configuration.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry being evaluated.</param>
    /// <param name="ReminderHeader">The reminder header being created.</param>
    /// <param name="LineLevel">The calculated line level.</param>
    /// <param name="IsGracePeriodExpired">Indicates whether the grace period has expired.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMarkReminderCandidateOnAfterCalcIsGracePeriodExpired(var ReminderLevel: Record "Reminder Level"; var ReminderDueDate: Date; var ReminderHeaderReq: Record "Reminder Header"; var ReminderTerms: Record "Reminder Terms"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var ReminderHeader: Record "Reminder Header"; var LineLevel: Integer; var IsGracePeriodExpired: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after setting filters on the reminder entry record when calculating reminder level.
    /// </summary>
    /// <param name="ReminderFinChargeEntry">The reminder entry record with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetReminderLineOnAfterSetFilters(var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry")
    begin
    end;

    /// <summary>
    /// Raised after finding the next line level from the reminder entry history.
    /// </summary>
    /// <param name="ReminderEntry">The reminder entry record found.</param>
    /// <param name="LineLevel2">The calculated next line level.</param>
    /// <param name="ReminderDueDate2">The due date from the reminder entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetReminderLineOnAfterFindNextLineLevel(ReminderEntry: Record "Reminder/Fin. Charge Entry"; var LineLevel2: Integer; var ReminderDueDate2: Date)
    begin
    end;

    /// <summary>
    /// Raised before inserting a reminder line for entries not due with no reminder level filter.
    /// </summary>
    /// <param name="ReminderLine">The reminder line to insert.</param>
    /// <param name="ReminderHeader">The reminder header for the line.</param>
    /// <param name="ReminderLevel">The reminder level configuration.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry for the line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAddRemiderLinesFromCustLedgEntryWithNoReminderLevelFilterOnBeforeReminderLineInsert(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header"; ReminderLevel: Record "Reminder Level"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after checking if a customer is blocked.
    /// </summary>
    /// <param name="Customer">The customer record that was checked.</param>
    /// <param name="Result">Returns whether the customer is blocked.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCustomerIsBlocked(Customer: Record Customer; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after filtering customer ledger entries in the make reminder process.
    /// </summary>
    /// <param name="ReminderLine">The reminder line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeReminderOnAfterFilterCustLedgEntries(var ReminderLine: Record "Reminder Line")
    begin
    end;

    /// <summary>
    /// Raised before the reminder header inserts its standard lines.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header about to insert lines.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeReminderOnBeforeReminderHeaderInsertLines(var ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised before setting the reminder line level and due date.
    /// </summary>
    /// <param name="LineLevel2">The line level to be set.</param>
    /// <param name="ReminderDueDate2">The reminder due date to be set.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry being processed.</param>
    /// <param name="ReminderFinChargeEntry">The reminder entry record for history lookup.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetReminderLine(var LineLevel2: Integer; var ReminderDueDate2: Date; var IsHandled: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry")
    begin
    end;

    /// <summary>
    /// Raised after inserting all reminder lines in the loop.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header with inserted lines.</param>
    /// <param name="CurrencyCode">The currency code for the reminder.</param>
    /// <param name="NextLineNo">The next available line number.</param>
    /// <param name="MaxReminderLevel">The maximum reminder level applied.</param>
    /// <param name="OverdueEntriesOnly">Indicates whether only overdue entries were included.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterReminderLinesInsertLoop(var ReminderHeader: Record "Reminder Header"; CurrencyCode: Code[10]; var NextLineNo: Integer; var MaxReminderLevel: Integer; OverdueEntriesOnly: Boolean);
    begin
    end;

    /// <summary>
    /// Raised after retrieving the customer for an existing reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header being processed.</param>
    /// <param name="Customer">The customer retrieved for the reminder.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    /// <param name="ReturnValue">Returns the result when handling is skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterGlobalReminderGetGlobalCustomer(var ReminderHeader: Record "Reminder Header"; var Customer: Record Customer; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;
}

