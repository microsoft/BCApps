// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 393 "Reminder-Issue"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Issued Reminder Header" = rimd,
                  TableData "Issued Reminder Line" = rimd,
                  TableData "Reminder/Fin. Charge Entry" = rimd;

    trigger OnRun()
    var
        CustPostingGr: Record "Customer Posting Group";
        ReminderLine: Record "Reminder Line";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        ReminderCommentLine: Record "Reminder Comment Line";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
        ShouldInsertReminderEntry: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssueReminder(GlobalReminderHeader, ReplacePostingDate, PostingDate, IsHandled, GlobalIssuedReminderHeader);
        if IsHandled then
            exit;

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, GlobalReminderHeader.RecordId, 0, '');

        GlobalReminderHeader.UpdateReminderRounding(GlobalReminderHeader);
        if (PostingDate <> 0D) and (ReplacePostingDate or (GlobalReminderHeader."Posting Date" = 0D)) then
            GlobalReminderHeader.Validate("Posting Date", PostingDate);
        if (VATDate <> 0D) and ReplaceVATDate then
            GlobalReminderHeader.Validate("VAT Reporting Date", VATDate);
        GlobalReminderHeader.TestField("Customer No.");
        CheckIfBlocked(GlobalReminderHeader."Customer No.");

        CheckVATDate(GlobalReminderHeader);

        GlobalReminderHeader.TestField("Posting Date");
        GlobalReminderHeader.TestField("Document Date");
        GlobalReminderHeader.TestField("Due Date");
        GlobalReminderHeader.TestField("Customer Posting Group");
        OnRunOnAfterGlobalReminderHeaderChecks(GlobalReminderHeader);

        if ErrorMessageHandler.HasErrors() then
            if ErrorMessageHandler.ShowErrors() then
                Error('');

        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then
            if GlobalReminderHeader."Post Additional Fee" or GlobalReminderHeader."Post Interest" or GlobalReminderHeader."Post Add. Fee per Line" then begin
                if GenJnlBatch."Journal Template Name" = '' then
                    Error(MissingJournalFieldErr, TempGenJnlLine.FieldCaption("Journal Template Name"));
                if GenJnlBatch.Name = '' then
                    Error(MissingJournalFieldErr, TempGenJnlLine.FieldCaption("Journal Batch Name"));
            end;

        CheckDimensions();

        CustPostingGr.Get(GlobalReminderHeader."Customer Posting Group");
        CalcAndEnsureAmountsNotEmpty();
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField(Reminder);
        SrcCode := SourceCodeSetup.Reminder;

        if (GlobalReminderHeader."Issuing No." = '') and (GlobalReminderHeader."No. Series" <> GlobalReminderHeader."Issuing No. Series") then begin
            GlobalReminderHeader.TestField("Issuing No. Series");
            GlobalReminderHeader."Issuing No." := NoSeries.GetNextNo(GlobalReminderHeader."Issuing No. Series", GlobalReminderHeader."Posting Date");
            GlobalReminderHeader.Modify();
            Commit();
        end;
        if GlobalReminderHeader."Issuing No." <> '' then
            DocNo := GlobalReminderHeader."Issuing No."
        else
            DocNo := GlobalReminderHeader."No.";

        ProcessReminderLines(GlobalReminderHeader, ReminderLine, DocNo);

        IsHandled := false;
        OnRunOnBeforePostInterestCheck(GlobalReminderHeader, ReminderLine, TempGenJnlLine, GenJnlBatch, ReminderInterestAmount, IsHandled);
        if not IsHandled then begin
            if (ReminderInterestAmount <> 0) and GlobalReminderHeader."Post Interest" then begin
                if ReminderInterestAmount < 0 then
                    Error(InterestsMustBePositiveLbl);
                InitGenJnlLine(TempGenJnlLine."Account Type"::"G/L Account", CustPostingGr.GetInterestAccount(), true);
                OnRunOnAfterInitGenJnlLinePostInterest(TempGenJnlLine, GlobalReminderHeader, ReminderLine);
                TempGenJnlLine.Validate("VAT Bus. Posting Group", GlobalReminderHeader."VAT Bus. Posting Group");
                TempGenJnlLine.Validate(Amount, -ReminderInterestAmount - ReminderInterestVATAmount);
                OnRunOnBeforeGenJnlLineUpdateLineBalance(TempGenJnlLine, ReminderInterestVATAmount, TotalAmount);
                TempGenJnlLine.UpdateLineBalance();
                TotalAmount := TotalAmount - TempGenJnlLine.Amount;
                TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
                TempGenJnlLine."Bill-to/Pay-to No." := GlobalReminderHeader."Customer No.";
                OnRunOnBeforeGenJnlLineInsertPostInterest(TempGenJnlLine, GlobalReminderHeader, ReminderLine);
                TempGenJnlLine.Insert();
                OnRunOnAfterGenJnlLineInsertPostInterest(TempGenJnlLine, GlobalReminderHeader, ReminderLine);
            end;

            if (TotalAmount <> 0) or (TotalAmountLCY <> 0) then begin
                InitGenJnlLine(TempGenJnlLine."Account Type"::Customer, GlobalReminderHeader."Customer No.", true);
                TempGenJnlLine.Validate(Amount, TotalAmount);
                TempGenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
                OnRunOnBeforeGenJnlLineInsertTotalAmount(TempGenJnlLine, GlobalReminderHeader, ReminderLine);
                TempGenJnlLine.Insert();
                OnRunOnAfterGenJnlLineInsertTotalAmount(TempGenJnlLine, GlobalReminderHeader, ReminderLine);
            end;
        end;

        Clear(GenJnlPostLine);
        if TempGenJnlLine.FindSet() then
            repeat
                GenJnlLine2 := TempGenJnlLine;
                SetGenJnlLine2Dim();
                OnBeforeGenJnlPostLineRun(GenJnlLine2, TempGenJnlLine, GlobalReminderHeader, ReminderLine);
                GenJnlPostLine.Run(GenJnlLine2);
                OnRunOnAfterGenJnlPostLineRun(GenJnlLine2, TempGenJnlLine, GlobalReminderHeader, ReminderLine, GenJnlPostLine);
            until TempGenJnlLine.Next() = 0;

        TempGenJnlLine.DeleteAll();

        if (ReminderInterestAmount <> 0) and GlobalReminderHeader."Post Interest" then begin
            GlobalReminderHeader.TestField("Fin. Charge Terms Code");
            FinChrgTerms.Get(GlobalReminderHeader."Fin. Charge Terms Code");
            if FinChrgTerms."Interest Calculation" in
               [FinChrgTerms."Interest Calculation"::"Closed Entries",
                FinChrgTerms."Interest Calculation"::"All Entries"]
            then begin
                ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
                OnRunOnAfterSetReminderLineFilter(ReminderLine);
                if ReminderLine.FindSet() then
                    repeat
                        UpdateCustLedgEntriesCalculateInterest(ReminderLine."Entry No.", GlobalReminderHeader."Currency Code");
                    until ReminderLine.Next() = 0;
                ReminderLine.SetRange(Type);
                OnRunOnAfterRemoveReminderLineFilter(ReminderLine);
            end;
        end;
        OnRunOnAfterUpdateCustLedgEntriesCalculateInterestLoops(GlobalReminderHeader, ReminderLine);

        InsertIssuedReminderHeader(GlobalReminderHeader, GlobalIssuedReminderHeader);

        if NextEntryNo = 0 then begin
            ReminderFinChargeEntry.LockTable();
            NextEntryNo := ReminderFinChargeEntry.GetLastEntryNo() + 1;
        end;

        ReminderCommentLine.CopyComments(
            ReminderCommentLine.Type::Reminder.AsInteger(), ReminderCommentLine.Type::"Issued Reminder".AsInteger(),
            GlobalReminderHeader."No.", GlobalIssuedReminderHeader."No.");
        ReminderCommentLine.DeleteComments(ReminderCommentLine.Type::Reminder.AsInteger(), GlobalReminderHeader."No.");

        ReminderLine.SetRange("Detailed Interest Rates Entry");
        if ReminderLine.FindSet() then
            repeat
                ShouldInsertReminderEntry := (ReminderLine.Type = ReminderLine.Type::"Customer Ledger Entry") and
                                             (ReminderLine."Entry No." <> 0) and (not ReminderLine."Detailed Interest Rates Entry");
                OnRunOnAfterCalcShouldInsertReminderEntry(GlobalReminderHeader, ReminderLine, ShouldInsertReminderEntry);
                if ShouldInsertReminderEntry then begin
                    InsertReminderEntry(GlobalReminderHeader, ReminderLine);
                    NextEntryNo := NextEntryNo + 1;
                end;
                InsertIssuedReminderLine(ReminderLine, GlobalIssuedReminderHeader."No.");
            until ReminderLine.Next() = 0;
        OnRunOnBeforeReminderLineDeleteAll(GlobalReminderHeader, GlobalIssuedReminderHeader, NextEntryNo);
        ReminderLine.DeleteAll();
        GlobalReminderHeader.Delete();

        ErrorMessageMgt.PopContext(ErrorContextElement);
        OnAfterIssueReminder(GlobalReminderHeader, GlobalIssuedReminderHeader."No.", GenJnlPostLine);
    end;

    local procedure CheckDimensions()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimensions(GlobalReminderHeader, IsHandled);
        if IsHandled then
            exit;

        if not DimMgt.CheckDimIDComb(GlobalReminderHeader."Dimension Set ID") then
            Error(
              DimensionCombinationIsBlockedErr,
              GlobalReminderHeader.TableCaption, GlobalReminderHeader."No.", DimMgt.GetDimCombErr());

        TableID[1] := DATABASE::Customer;
        No[1] := GlobalReminderHeader."Customer No.";
        if not DimMgt.CheckDimValuePosting(TableID, No, GlobalReminderHeader."Dimension Set ID") then
            Error(
              DimensionCausedErrorTxt,
              GlobalReminderHeader.TableCaption, GlobalReminderHeader."No.", DimMgt.GetDimValuePostingErr());
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        FinChrgTerms: Record "Finance Charge Terms";
        GlobalReminderHeader: Record "Reminder Header";
        GlobalIssuedReminderHeader: Record "Issued Reminder Header";
        GlobalIssuedReminderLine: Record "Issued Reminder Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlLine2: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        SourceCode: Record "Source Code";
        DimMgt: Codeunit DimensionManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
        DocNo: Code[20];
        NextEntryNo: Integer;
        ReplacePostingDate, ReplaceVATDate : Boolean;
        PostingDate, VATDate : Date;
        SrcCode: Code[10];
        ReminderInterestAmount: Decimal;
        ReminderInterestVATAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        ThereIsNothingToIssueLbl: Label 'There is nothing to issue.';
        InterestsMustBePositiveLbl: Label 'Interests must be positive or 0';
        DimensionCombinationIsBlockedErr: Label 'The combination of dimensions used in %1 %2 is blocked. %3.', Comment = '%1: TABLECAPTION(Reminder Header); %2: Field(No.); %3: Text GetDimCombErr';
        DimensionCausedErrorTxt: Label 'A dimension used in %1 %2 has caused an error. %3', Comment = '%1: Name of the table, e.g. Reminder Header; %2: Unique code of the table %3: Actual error';
        CustomerBlockedErr: Label '%1 must not be %2 in %3 %4.', Comment = '%1 = Field name, %2 = field value, %3 = table caption, %4 customer number';
        LineFeeAmountErr: Label 'Line Fee amount must be positive and non-zero for Line Fee applied to %1 %2.', Comment = '%1 = Document Type, %2 = Document No.. E.g. Line Fee amount must be positive and non-zero for Line Fee applied to Invoice 102421';
        AppliesToDocErr: Label 'Line Fee has to be applied to an open overdue document.';
        EntryNotOverdueErr: Label '%1 %2 in %3 is not overdue.', Comment = '%1 = Document Type, %2 = Document No., %3 = Table name. E.g. Invoice 12313 in Cust. Ledger Entry is not overdue.';
        LineFeeAlreadyIssuedErr: Label 'The Line Fee for %1 %2 on reminder level %3 has already been issued.', Comment = '%1 = Document Type, %2 = Document No. %3 = Reminder Level. E.g. The Line Fee for Invoice 141232 on reminder level 2 has already been issued.';
        MultipleLineFeesSameDocErr: Label 'You cannot issue multiple line fees for the same level for the same document. Error with line fees for %1 %2.', Comment = '%1 = Document Type, %2 = Document No. E.g. You cannot issue multiple line fees for the same level for the same document. Error with line fees for Invoice 1312312.';
        MissingJournalFieldErr: Label 'Please enter a %1 when posting Additional Fees or Interest.', Comment = '%1 - field caption';


    procedure Set(var NewReminderHeader: Record "Reminder Header"; NewReplacePostingDate: Boolean; NewPostingDate: Date; NewReplaceVATDate: Boolean; NewVATDate: Date)
    begin
        Set(NewReminderHeader, NewReplacePostingDate, NewPostingDate);
        ReplaceVATDate := NewReplaceVATDate;
        VATDate := NewVATDate;
    end;

    procedure Set(var NewReminderHeader: Record "Reminder Header"; NewReplacePostingDate: Boolean; NewPostingDate: Date)
    begin
        GlobalReminderHeader := NewReminderHeader;
        ReplacePostingDate := NewReplacePostingDate;
        PostingDate := NewPostingDate;
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    local procedure SetGenJnlLine2Dim()
    var
        DimSetIDArr: array[10] of Integer;
    begin
        GenJnlLine2."Shortcut Dimension 1 Code" := GlobalReminderHeader."Shortcut Dimension 1 Code";
        GenJnlLine2."Shortcut Dimension 2 Code" := GlobalReminderHeader."Shortcut Dimension 2 Code";
        DimSetIDArr[1] := TempGenJnlLine."Dimension Set ID";
        DimSetIDArr[2] := GlobalReminderHeader."Dimension Set ID";
        GenJnlLine2."Dimension Set ID" :=
            DimMgt.GetCombinedDimensionSetID(
                DimSetIDArr, GenJnlLine2."Shortcut Dimension 1 Code", GenJnlLine2."Shortcut Dimension 2 Code");

        OnAfterSetGenJnlLine2Dim(GlobalReminderHeader, GenJnlLine2);
    end;

    local procedure CalcAndEnsureAmountsNotEmpty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAndEnsureAmountsNotEmpty(GlobalReminderHeader, IsHandled);
        if IsHandled then
            exit;

        GlobalReminderHeader.CalcFields("Interest Amount", "Additional Fee", "Remaining Amount", "Add. Fee per Line");
        if (GlobalReminderHeader."Interest Amount" = 0) and (GlobalReminderHeader."Additional Fee" = 0) and (GlobalReminderHeader."Remaining Amount" = 0) and (GlobalReminderHeader."Add. Fee per Line" = 0) then
            Error(ThereIsNothingToIssueLbl);
    end;

    procedure GetIssuedReminder(var NewIssuedReminderHeader: Record "Issued Reminder Header")
    begin
        NewIssuedReminderHeader := GlobalIssuedReminderHeader;
    end;

    local procedure InitGenJnlLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; SystemCreatedEntry: Boolean)
    begin
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := TempGenJnlLine."Line No." + 1;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Reminder;
        TempGenJnlLine."Document No." := DocNo;
        if GlobalReminderHeader."Post Additional Fee" or GlobalReminderHeader."Post Interest" or GlobalReminderHeader."Post Add. Fee per Line" then begin
            TempGenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
            TempGenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        end;
        TempGenJnlLine."Posting Date" := GlobalReminderHeader."Posting Date";
        TempGenJnlLine."VAT Reporting Date" := GlobalReminderHeader."VAT Reporting Date";
        TempGenJnlLine."Document Date" := GlobalReminderHeader."Document Date";
        TempGenJnlLine."Account Type" := AccType;
        TempGenJnlLine."Account No." := AccNo;
        TempGenJnlLine.Validate("Account No.");
        if TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::"G/L Account" then begin
            TempGenJnlLine."Gen. Posting Type" := TempGenJnlLine."Gen. Posting Type"::Sale;
            TempGenJnlLine."Gen. Bus. Posting Group" := GlobalReminderHeader."Gen. Bus. Posting Group";
            TempGenJnlLine."VAT Bus. Posting Group" := GlobalReminderHeader."VAT Bus. Posting Group";
        end;
        TempGenJnlLine.Validate("Currency Code", GlobalReminderHeader."Currency Code");
        if TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Customer then begin
            TempGenJnlLine.Validate(Amount, TotalAmount);
            TempGenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
            TempGenJnlLine."Due Date" := GlobalReminderHeader."Due Date";
        end;
        TempGenJnlLine.Description := GlobalReminderHeader."Posting Description";
        TempGenJnlLine."Source Type" := TempGenJnlLine."Source Type"::Customer;
        TempGenJnlLine."Source No." := GlobalReminderHeader."Customer No.";
        TempGenJnlLine."Source Code" := SrcCode;
        TempGenJnlLine."Reason Code" := GlobalReminderHeader."Reason Code";
        TempGenJnlLine."System-Created Entry" := SystemCreatedEntry;
        TempGenJnlLine."Posting No. Series" := GlobalReminderHeader."Issuing No. Series";
        TempGenJnlLine."Salespers./Purch. Code" := '';
        TempGenJnlLine."Country/Region Code" := GlobalReminderHeader."Country/Region Code";
        TempGenJnlLine."VAT Registration No." := GlobalReminderHeader."VAT Registration No.";

        OnAfterInitGenJnlLine(TempGenJnlLine, GlobalReminderHeader, SrcCode, AccNo);
    end;

    procedure DeleteIssuedReminderLines(ParentIssuedReminderHeader: Record "Issued Reminder Header")
    var
        IssuedReminderLineToDelete: Record "Issued Reminder Line";
    begin
        IssuedReminderLineToDelete.SetRange("Reminder No.", ParentIssuedReminderHeader."No.");
        IssuedReminderLineToDelete.DeleteAll();
    end;

    procedure IncrNoPrinted(var IssuedReminderHeaderToIncrement: Record "Issued Reminder Header")
    begin
        IssuedReminderHeaderToIncrement.Find();
        IssuedReminderHeaderToIncrement."No. Printed" := IssuedReminderHeaderToIncrement."No. Printed" + 1;
        OnIncrNoPrintedOnBeforeModify(IssuedReminderHeaderToIncrement);
        IssuedReminderHeaderToIncrement.Modify();
        Commit();
    end;

    procedure TestDeleteHeader(ReminderHeaderToDelete: Record "Reminder Header"; var IssuedReminderHeaderToDelete: Record "Issued Reminder Header")
    begin
        Clear(IssuedReminderHeaderToDelete);
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        if (ReminderHeaderToDelete."Issuing No. Series" <> '') and
           ((ReminderHeaderToDelete."Issuing No." <> '') or (ReminderHeaderToDelete."No. Series" = ReminderHeaderToDelete."Issuing No. Series"))
        then begin
            IssuedReminderHeaderToDelete.TransferFields(ReminderHeaderToDelete);
            if ReminderHeaderToDelete."Issuing No." <> '' then
                IssuedReminderHeaderToDelete."No." := ReminderHeaderToDelete."Issuing No.";
            IssuedReminderHeaderToDelete."Pre-Assigned No. Series" := ReminderHeaderToDelete."No. Series";
            IssuedReminderHeaderToDelete."Pre-Assigned No." := ReminderHeaderToDelete."No.";
            IssuedReminderHeaderToDelete."Posting Date" := Today;
            IssuedReminderHeaderToDelete."User ID" := CopyStr(UserId(), 1, MaxStrLen(IssuedReminderHeaderToDelete."User ID"));
            IssuedReminderHeaderToDelete."Source Code" := SourceCode.Code;
            OnAfterTestDeleteHeader(IssuedReminderHeaderToDelete, ReminderHeaderToDelete);
        end;
    end;

    procedure DeleteHeader(ReminderHeader: Record "Reminder Header"; var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteHeader(ReminderHeader, IssuedReminderHeader, IsHandled);
        if IsHandled then
            exit;

        TestDeleteHeader(ReminderHeader, IssuedReminderHeader);
        if IssuedReminderHeader."No." <> '' then begin
            IssuedReminderHeader."Shortcut Dimension 1 Code" := '';
            IssuedReminderHeader."Shortcut Dimension 2 Code" := '';
            IssuedReminderHeader.Insert();
            GlobalIssuedReminderLine.Init();
            GlobalIssuedReminderLine."Reminder No." := ReminderHeader."No.";
            GlobalIssuedReminderLine."Line No." := 10000;
            GlobalIssuedReminderLine.Description := SourceCode.Description;
            OnDeleteHeaderOnBeforeIssuedReminderLineInsert(GlobalIssuedReminderLine, IssuedReminderHeader);
            GlobalIssuedReminderLine.Insert();
        end;
    end;

    procedure ChangeDueDate(var ReminderEntry2: Record "Reminder/Fin. Charge Entry"; NewDueDate: Date; OldDueDate: Date)
    var
        IsHandled: Boolean;
    begin
        OnBeforeChangeDueDate(ReminderEntry2, NewDueDate, OldDueDate, IsHandled);
        if IsHandled then
            exit;

        ReminderEntry2.Validate("Due Date", NewDueDate);
        ReminderEntry2.Modify();
    end;

    local procedure InsertIssuedReminderHeader(ReminderHeader: Record "Reminder Header"; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader.TransferFields(ReminderHeader);
        IssuedReminderHeader."No." := DocNo;
        IssuedReminderHeader."Pre-Assigned No." := ReminderHeader."No.";
        IssuedReminderHeader."Source Code" := SrcCode;
        IssuedReminderHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(IssuedReminderHeader."User ID"));
        OnBeforeIssuedReminderHeaderInsert(IssuedReminderHeader, ReminderHeader);
        IssuedReminderHeader.Insert();
    end;

    local procedure InsertIssuedReminderLine(ReminderLine: Record "Reminder Line"; IssuedReminderNo: Code[20])
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.Init();
        IssuedReminderLine.TransferFields(ReminderLine);
        IssuedReminderLine."Reminder No." := IssuedReminderNo;
        OnBeforeIssuedReminderLineInsert(IssuedReminderLine, ReminderLine);
        IssuedReminderLine.Insert();
    end;

    local procedure InsertGenJnlLineForFee(var ReminderLine: Record "Reminder Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertGenJnlLineForFee(ReminderLine, TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ReminderLine.Amount <> 0 then begin
            ReminderLine.TestField("No.");
            InitGenJnlLine(TempGenJnlLine."Account Type"::"G/L Account",
              ReminderLine."No.",
              ReminderLine."Line Type" = ReminderLine."Line Type"::Rounding);
            TempGenJnlLine."Gen. Prod. Posting Group" := ReminderLine."Gen. Prod. Posting Group";
            TempGenJnlLine."VAT Prod. Posting Group" := ReminderLine."VAT Prod. Posting Group";
            TempGenJnlLine."VAT Calculation Type" := ReminderLine."VAT Calculation Type";
            if ReminderLine."VAT Calculation Type" =
               ReminderLine."VAT Calculation Type"::"Sales Tax"
            then begin
                TempGenJnlLine."Tax Area Code" := GlobalReminderHeader."Tax Area Code";
                TempGenJnlLine."Tax Liable" := GlobalReminderHeader."Tax Liable";
                TempGenJnlLine."Tax Group Code" := ReminderLine."Tax Group Code";
            end;
            TempGenJnlLine."VAT %" := ReminderLine."VAT %";
            TempGenJnlLine.Validate(Amount, -ReminderLine.Amount - ReminderLine."VAT Amount");
            TempGenJnlLine."VAT Amount" := -ReminderLine."VAT Amount";
            TempGenJnlLine.UpdateLineBalance();
            TotalAmount := TotalAmount - TempGenJnlLine.Amount;
            TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
            TempGenJnlLine."Bill-to/Pay-to No." := GlobalReminderHeader."Customer No.";
            OnInsertGenJnlLineForFeeOnBeforeGenJnlLineInsert(TempGenJnlLine, GlobalReminderHeader, ReminderLine);
            TempGenJnlLine.Insert();
        end;

        OnAfterInsertGenJnlLineForFee(ReminderLine, TempGenJnlLine);
    end;

    local procedure InsertReminderEntry(ReminderHeader: Record "Reminder Header"; ReminderLine: Record "Reminder Line")
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
    begin
        ReminderFinChargeEntry."Entry No." := NextEntryNo;
        ReminderFinChargeEntry.Type := ReminderFinChargeEntry.Type::Reminder;
        ReminderFinChargeEntry."No." := GlobalIssuedReminderHeader."No.";
        ReminderFinChargeEntry."Posting Date" := ReminderHeader."Posting Date";
        ReminderFinChargeEntry."Document Date" := ReminderHeader."Document Date";
        ReminderFinChargeEntry."Due Date" := GlobalIssuedReminderHeader."Due Date";
        ReminderFinChargeEntry."Customer No." := ReminderHeader."Customer No.";
        ReminderFinChargeEntry."Customer Entry No." := ReminderLine."Entry No.";
        ReminderFinChargeEntry."Document Type" := ReminderLine."Document Type";
        ReminderFinChargeEntry."Document No." := ReminderLine."Document No.";
        ReminderFinChargeEntry."Reminder Level" := ReminderLine."No. of Reminders";
        ReminderFinChargeEntry."Remaining Amount" := ReminderLine."Remaining Amount";
        ReminderFinChargeEntry."Interest Amount" := ReminderLine.Amount;
        ReminderFinChargeEntry."Interest Posted" :=
          (ReminderFinChargeEntry."Interest Amount" <> 0) and ReminderHeader."Post Interest";
        ReminderFinChargeEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReminderFinChargeEntry."User ID"));
        OnBeforeReminderEntryInsert(ReminderFinChargeEntry, ReminderHeader, ReminderLine);
        ReminderFinChargeEntry.Insert();
        if ReminderLine."Line Type" <> ReminderLine."Line Type"::"Not Due" then
            UpdateCustLedgEntryLastIssuedReminderLevel(ReminderFinChargeEntry);
        OnAfterInsertReminderEntry(ReminderFinChargeEntry, ReminderHeader, ReminderLine, NextEntryNo);
    end;

    local procedure CheckLineFee(var ReminderLine: Record "Reminder Line"; var ReminderHeader: Record "Reminder Header")
    var
        CustLedgEntry3: Record "Cust. Ledger Entry";
        ReminderLine2: Record "Reminder Line";
    begin
        if ReminderLine.Amount <= 0 then
            Error(LineFeeAmountErr, ReminderLine."Applies-to Document Type", ReminderLine."Applies-to Document No.");
        if ReminderLine."Applies-to Document No." = '' then
            Error(AppliesToDocErr);

        CustLedgEntry3.SetRange("Document Type", ReminderLine."Applies-to Document Type");
        CustLedgEntry3.SetRange("Document No.", ReminderLine."Applies-to Document No.");
        CustLedgEntry3.SetRange("Customer No.", ReminderHeader."Customer No.");
        CustLedgEntry3.FindFirst();
        if CustLedgEntry3."Due Date" >= ReminderHeader."Document Date" then
            Error(
              EntryNotOverdueErr, CustLedgEntry3.FieldCaption("Document No."), ReminderLine."Applies-to Document No.", CustLedgEntry3.TableCaption());

        GlobalIssuedReminderLine.Reset();
        GlobalIssuedReminderLine.SetRange("Applies-To Document Type", ReminderLine."Applies-to Document Type");
        GlobalIssuedReminderLine.SetRange("Applies-To Document No.", ReminderLine."Applies-to Document No.");
        GlobalIssuedReminderLine.SetRange(Type, GlobalIssuedReminderLine.Type::"Line Fee");
        GlobalIssuedReminderLine.SetRange("No. of Reminders", ReminderLine."No. of Reminders");
        if GlobalIssuedReminderLine.FindFirst() then
            Error(
              LineFeeAlreadyIssuedErr, ReminderLine."Applies-to Document Type", ReminderLine."Applies-to Document No.",
              ReminderLine."No. of Reminders");

        ReminderLine2.Reset();
        ReminderLine2.SetRange("Applies-to Document Type", ReminderLine."Applies-to Document Type");
        ReminderLine2.SetRange("Applies-to Document No.", ReminderLine."Applies-to Document No.");
        ReminderLine2.SetRange(Type, GlobalIssuedReminderLine.Type::"Line Fee");
        ReminderLine2.SetRange("No. of Reminders", ReminderLine."No. of Reminders");
        if ReminderLine2.Count > 1 then
            Error(MultipleLineFeesSameDocErr, ReminderLine."Applies-to Document Type", ReminderLine."Applies-to Document No.");
    end;

    local procedure ProcessReminderLines(ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; DocNo: Code[20])
    begin
        OnBeforeProcessReminderLines(GlobalReminderHeader, ReminderLine, DocNo);

        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderLine.SetRange("Detailed Interest Rates Entry", false);
        if ReminderLine.FindSet() then
            repeat
                case ReminderLine.Type of
                    ReminderLine.Type::" ":
                        ReminderLine.TestField(Amount, 0);
                    ReminderLine.Type::"G/L Account":
                        if ReminderHeader."Post Additional Fee" then
                            InsertGenJnlLineForFee(ReminderLine);
                    ReminderLine.Type::"Customer Ledger Entry":
                        begin
                            ReminderLine.TestField("Entry No.");
                            ReminderInterestAmount := ReminderInterestAmount + ReminderLine.Amount;
                            ReminderInterestVATAmount := ReminderInterestVATAmount + ReminderLine."VAT Amount";
                            OnProcessReminderLinesOnAfterCalcInterestAmounts(ReminderHeader, ReminderLine, ReminderInterestAmount, ReminderInterestVATAmount);
                        end;
                    ReminderLine.Type::"Line Fee":
                        if ReminderHeader."Post Add. Fee per Line" then begin
                            CheckLineFee(ReminderLine, ReminderHeader);
                            InsertGenJnlLineForFee(ReminderLine);
                        end;
                end;
            until ReminderLine.Next() = 0;

        OnAfterProcessReminderLines(ReminderHeader, ReminderLine, ReminderInterestAmount, ReminderInterestVATAmount);
    end;

    procedure UpdateCustLedgEntryLastIssuedReminderLevel(ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.LockTable();
        CustLedgEntry.Get(ReminderFinChargeEntry."Customer Entry No.");
        CustLedgEntry."Last Issued Reminder Level" := ReminderFinChargeEntry."Reminder Level";
        OnUpdateCustLedgEntryLastIssuedReminderLevelOnBeforeModify(CustLedgEntry, ReminderFinChargeEntry);
        CustLedgEntry.Modify();
    end;

    local procedure UpdateCustLedgEntriesCalculateInterest(EntryNo: Integer; CurrencyCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry.TestField("Currency Code", CurrencyCode);
        CustLedgerEntry.CalcFields("Remaining Amount");
        OnUpdateCustLedgEntriesCalculateInterestOnBeforeCustLedgerEntryModify(CustLedgerEntry);
        if CustLedgerEntry."Remaining Amount" = 0 then begin
            CustLedgerEntry."Calculate Interest" := false;
            CustLedgerEntry.Modify();
        end;
        CustLedgerEntry2.SetCurrentKey("Closed by Entry No.");
        CustLedgerEntry2.SetRange("Closed by Entry No.", EntryNo);
        CustLedgerEntry2.SetRange("Closing Interest Calculated", false);
        OnUpdateCustLedgEntriesCalculateInterestOnBeforeCustLedgerEntry2ModifyAll(CustLedgerEntry2, CustLedgerEntry);
        CustLedgerEntry2.ModifyAll("Closing Interest Calculated", true);
    end;

    local procedure CheckVATDate(var ReminderHeader2: Record "Reminder Header")
    begin
        // ensure VAT Date is filled in
        if ReminderHeader2."VAT Reporting Date" = 0D then begin
            ReminderHeader2."VAT Reporting Date" := GLSetup.GetVATDate(ReminderHeader2."Posting Date", ReminderHeader2."Document Date");
            ReminderHeader2.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ReminderHeader: Record "Reminder Header"; var SrcCode: Code[10]; AccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIssueReminder(var ReminderHeader: Record "Reminder Header"; IssuedReminderNo: Code[20]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessReminderLines(ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; var InterestAmount: Decimal; var InterestVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGenJnlLine2Dim(ReminderHeader: Record "Reminder Header"; var GenJnlLine2: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestDeleteHeader(var IssuedReminderHeader: Record "Issued Reminder Header"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssueReminder(var ReminderHeader: Record "Reminder Header"; var ReplacePostingDate: Boolean; var PostingDate: Date; var IsHandled: Boolean; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedReminderHeaderInsert(var IssuedReminderHeader: Record "Issued Reminder Header"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedReminderLineInsert(var IssuedReminderLine: Record "Issued Reminder Line"; ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderEntryInsert(var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry"; ReminderHeader: Record "Reminder Header"; ReminderLine: Record "Reminder Line")
    begin
    end;

    local procedure CheckIfBlocked(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        Customer.Get(CustomerNo);

        if Customer."Privacy Blocked" then
            Error(CustomerBlockedErr, Customer.FieldCaption("Privacy Blocked"), Customer."Privacy Blocked", Customer.TableCaption(), CustomerNo);

        IsHandled := false;
        OnBeforeCheckCustomerIsBlocked(Customer, IsHandled);
        if IsHandled then
            exit;

        if Customer.Blocked = Customer.Blocked::All then
            Error(CustomerBlockedErr, Customer.FieldCaption(Blocked), Customer.Blocked, Customer.TableCaption(), CustomerNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimensions(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlPostLineRun(var GenJnlLine2: Record "Gen. Journal Line"; GenJnlLine: Record "Gen. Journal Line"; var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGenJnlLineForFee(var ReminderLine: Record "Reminder Line"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGenJnlLineForFee(var ReminderLine: Record "Reminder Line"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGenJnlLineForFeeOnBeforeGenJnlLineInsert(var GenJnlLine: Record "Gen. Journal Line"; ReminderHeader: Record "Reminder Header"; ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertReminderEntry(var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry"; ReminderHeader: Record "Reminder Header"; ReminderLine: Record "Reminder Line"; NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustLedgEntryLastIssuedReminderLevelOnBeforeModify(var CustLedgEntry: Record "Cust. Ledger Entry"; ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustLedgEntriesCalculateInterestOnBeforeCustLedgerEntryModify(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustLedgEntriesCalculateInterestOnBeforeCustLedgerEntry2ModifyAll(var CustLedgEntry2: Record "Cust. Ledger Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAndEnsureAmountsNotEmpty(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerIsBlocked(Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIncrNoPrintedOnBeforeModify(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessReminderLines(ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; DocumentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessReminderLinesOnAfterCalcInterestAmounts(ReminderHeader: Record "Reminder Header"; ReminderLine: Record "Reminder Line"; var ReminderInterestAmount: Decimal; var ReminderInterestVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGenJnlPostLineRun(var GenJnlLine2: Record "Gen. Journal Line"; var GenJnlLine: Record "Gen. Journal Line"; var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInitGenJnlLinePostInterest(var GenJnlLine: Record "Gen. Journal Line"; var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGenJnlLineInsertPostInterest(var GenJnlLine: Record "Gen. Journal Line"; var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCalcShouldInsertReminderEntry(ReminderHeader: Record "Reminder Header"; ReminderLine: Record "Reminder Line"; var ShouldInsertReminderEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGenJnlLineInsertPostInterest(var GenJnlLine: Record "Gen. Journal Line"; var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGenJnlLineInsertTotalAmount(var GenJnlLine: Record "Gen. Journal Line"; var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGenJnlLineInsertTotalAmount(var GenJnlLine: Record "Gen. Journal Line"; var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeReminderLineDeleteAll(var ReminderHeader: Record "Reminder Header"; var IssuedReminderHeader: Record "Issued Reminder Header"; NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGenJnlLineUpdateLineBalance(var GenJnlLine: Record "Gen. Journal Line"; ReminderInterestVATAmount: Decimal; var TotalAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforePostInterestCheck(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; GenJnlBatch: Record "Gen. Journal Batch"; var ReminderInterestAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGlobalReminderHeaderChecks(var ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterRemoveReminderLineFilter(var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetReminderLineFilter(var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterUpdateCustLedgEntriesCalculateInterestLoops(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHeaderOnBeforeIssuedReminderLineInsert(var IssuedReminderLine: Record "Issued Reminder Line"; IssuedReminderHeader: Record "Issued Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeDueDate(var ReminderEntry2: Record "Reminder/Fin. Charge Entry"; NewDueDate: Date; OldDueDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteHeader(ReminderHeader: Record "Reminder Header"; var IssuedReminderHeader: Record "Issued Reminder Header"; var IsHandled: Boolean)
    begin
    end;
}

