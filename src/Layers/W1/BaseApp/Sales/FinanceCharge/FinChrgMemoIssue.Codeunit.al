// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

/// <summary>
/// Issues finance charge memos by posting interest and fees to the general ledger and creating customer ledger entries.
/// </summary>
codeunit 395 "FinChrgMemo-Issue"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Reminder/Fin. Charge Entry" = rimd,
                  TableData "Issued Fin. Charge Memo Header" = rimd,
                  TableData "Issued Fin. Charge Memo Line" = rimd;

    trigger OnRun()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
        FinChrgMemoLine: Record "Finance Charge Memo Line";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        FinChrgCommentLine: Record "Fin. Charge Comment Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssueFinChargeMemo(FinChrgMemoHeader, ReplacePostingDate, PostingDate, IsHandled, IssuedFinChrgMemoHeader);
        if IsHandled then
            exit;

        FinChrgMemoHeader.UpdateFinanceChargeRounding(FinChrgMemoHeader);
        if (PostingDate <> 0D) and (ReplacePostingDate or (FinChrgMemoHeader."Posting Date" = 0D)) then
            FinChrgMemoHeader.Validate("Posting Date", PostingDate);

        CheckVATDate(FinChrgMemoHeader);
        FinChrgMemoHeader.TestField("Customer No.");
        FinChrgMemoHeader.TestField("Posting Date");
        FinChrgMemoHeader.TestField("Document Date");
        FinChrgMemoHeader.TestField("Due Date");
        FinChrgMemoHeader.TestField("Customer Posting Group");
        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then
            if FinChrgMemoHeader."Post Additional Fee" or FinChrgMemoHeader."Post Interest" then begin
                if GenJnlBatch."Journal Template Name" = '' then
                    Error(MissingJournalFieldErr, TempGenJnlLine.FieldCaption("Journal Template Name"));
                if GenJnlBatch.Name = '' then
                    Error(MissingJournalFieldErr, TempGenJnlLine.FieldCaption("Journal Batch Name"));
            end;

        CheckDimensions();

        Customer.Get(FinChrgMemoHeader."Customer No.");
        Customer.TestField("Customer Posting Group");
        if FinChrgMemoHeader."Customer Posting Group" <> Customer."Customer Posting Group" then
            Customer.CheckAllowMultiplePostingGroups();
        CustomerPostingGroup.Get(FinChrgMemoHeader."Customer Posting Group");
        FinChrgMemoHeader.CalcFields("Interest Amount", "Additional Fee", "Remaining Amount");
        if (FinChrgMemoHeader."Interest Amount" = 0) and (FinChrgMemoHeader."Additional Fee" = 0) and (FinChrgMemoHeader."Remaining Amount" = 0) then
            Error(Text000);
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Finance Charge Memo");
        SrcCode := SourceCodeSetup."Finance Charge Memo";

        if (FinChrgMemoHeader."Issuing No." = '') and (FinChrgMemoHeader."No. Series" <> FinChrgMemoHeader."Issuing No. Series") then begin
            FinChrgMemoHeader.TestField("Issuing No. Series");
            FinChrgMemoHeader."Issuing No." := NoSeries.GetNextNo(FinChrgMemoHeader."Issuing No. Series", FinChrgMemoHeader."Posting Date");
            FinChrgMemoHeader.Modify();
            Commit();
        end;
        if FinChrgMemoHeader."Issuing No." = '' then
            DocNo := FinChrgMemoHeader."No."
        else
            DocNo := FinChrgMemoHeader."Issuing No.";

        FinChrgMemoLine.SetRange("Finance Charge Memo No.", FinChrgMemoHeader."No.");
        FinChrgMemoLine.SetRange("Detailed Interest Rates Entry", false);
        if FinChrgMemoLine.FindSet() then
            repeat
                case FinChrgMemoLine.Type of
                    FinChrgMemoLine.Type::" ":
                        FinChrgMemoLine.TestField(Amount, 0);
                    FinChrgMemoLine.Type::"G/L Account":
                        if (FinChrgMemoLine.Amount <> 0) and
                           (FinChrgMemoHeader."Post Additional Fee" or (FinChrgMemoLine."Line Type" = FinChrgMemoLine."Line Type"::Rounding))
                        then begin
                            FinChrgMemoLine.TestField("No.");
                            InitGenJnlLine(TempGenJnlLine."Account Type"::"G/L Account",
                              FinChrgMemoLine."No.",
                              FinChrgMemoLine."Line Type" = FinChrgMemoLine."Line Type"::Rounding);
                            TempGenJnlLine."Gen. Prod. Posting Group" := FinChrgMemoLine."Gen. Prod. Posting Group";
                            TempGenJnlLine."VAT Prod. Posting Group" := FinChrgMemoLine."VAT Prod. Posting Group";
                            TempGenJnlLine."VAT Calculation Type" := FinChrgMemoLine."VAT Calculation Type";
                            if FinChrgMemoLine."VAT Calculation Type" =
                               FinChrgMemoLine."VAT Calculation Type"::"Sales Tax"
                            then begin
                                TempGenJnlLine."Tax Area Code" := FinChrgMemoHeader."Tax Area Code";
                                TempGenJnlLine."Tax Liable" := FinChrgMemoHeader."Tax Liable";
                                TempGenJnlLine."Tax Group Code" := FinChrgMemoLine."Tax Group Code";
                            end;
                            TempGenJnlLine."VAT %" := FinChrgMemoLine."VAT %";
                            TempGenJnlLine.Validate(Amount, -FinChrgMemoLine.Amount - FinChrgMemoLine."VAT Amount");
                            TempGenJnlLine."VAT Amount" := -FinChrgMemoLine."VAT Amount";
                            TempGenJnlLine.UpdateLineBalance();
                            TotalAmount := TotalAmount - TempGenJnlLine.Amount;
                            TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
                            TempGenJnlLine."Bill-to/Pay-to No." := FinChrgMemoHeader."Customer No.";
                            OnRunOnBeforeGLAccountGenJnlLineInsert(TempGenJnlLine, FinChrgMemoLine);
                            TempGenJnlLine.Insert();
                            OnRunOnAfterGLAccountGenJnlLineInsert(TempGenJnlLine);
                        end;
                    FinChrgMemoLine.Type::"Customer Ledger Entry":
                        begin
                            FinChrgMemoLine.TestField("Entry No.");
                            CustLedgEntry.Get(FinChrgMemoLine."Entry No.");
                            CustLedgEntry.TestField("Currency Code", FinChrgMemoHeader."Currency Code");
                            CheckNegativeFinChrgMemoLineAmount(FinChrgMemoLine);
                            FinChrgMemoInterestAmount := FinChrgMemoInterestAmount + FinChrgMemoLine.Amount;
                            FinChrgMemoInterestVATAmount := FinChrgMemoInterestVATAmount + FinChrgMemoLine."VAT Amount";
                        end;
                end;
                OnAfterGetFinChrgMemoLine(FinChrgMemoLine, DocNo, CurrencyExchangeRate.ExchangeRate(FinChrgMemoHeader."Posting Date", FinChrgMemoHeader."Currency Code"));
            until FinChrgMemoLine.Next() = 0;

        OnAfterCalculateFinChrgMemoInterestAmounts(FinChrgMemoHeader, TempGenJnlLine, FinChrgMemoInterestAmount, FinChrgMemoInterestVATAmount);

        if (FinChrgMemoInterestAmount <> 0) and FinChrgMemoHeader."Post Interest" then begin
            InitGenJnlLine(TempGenJnlLine."Account Type"::"G/L Account", CustomerPostingGroup.GetInterestAccount(), true);
            TempGenJnlLine.Validate("VAT Bus. Posting Group", FinChrgMemoHeader."VAT Bus. Posting Group");
            TempGenJnlLine.Validate(Amount, -FinChrgMemoInterestAmount - FinChrgMemoInterestVATAmount);
            TempGenJnlLine.UpdateLineBalance();
            TotalAmount := TotalAmount - TempGenJnlLine.Amount;
            TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
            TempGenJnlLine."Bill-to/Pay-to No." := FinChrgMemoHeader."Customer No.";
            OnRunOnBeforeInterestGenJnlLineInsert(TempGenJnlLine);
            TempGenJnlLine.Insert();
            OnRunOnAfterInterestGenJnlLineInsert(TempGenJnlLine);
        end;

        if (TotalAmount <> 0) or (TotalAmountLCY <> 0) then begin
            InitGenJnlLine(TempGenJnlLine."Account Type"::Customer, FinChrgMemoHeader."Customer No.", true);
            TempGenJnlLine.Validate(Amount, TotalAmount);
            TempGenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
            OnRunOnBeforeTotalGenJnlLineInsert(TempGenJnlLine);
            TempGenJnlLine.Insert();
            OnRunOnAfterTotalGenJnlLineInsert(TempGenJnlLine);
        end;
        if TempGenJnlLine.FindSet() then
            repeat
                GenJnlLine2 := TempGenJnlLine;
                SetDimensions(GenJnlLine2, FinChrgMemoHeader);
                OnBeforeGenJnlPostLineRunWithCheck(GenJnlLine2, FinChrgMemoHeader);
                GenJnlPostLine.RunWithCheck(GenJnlLine2);
                OnRunOnAfterGenJnlPostLineRunWithCheck(TempGenJnlLine, GenJnlPostLine);
            until TempGenJnlLine.Next() = 0;

        TempGenJnlLine.DeleteAll();

        if FinChrgMemoInterestAmount <> 0 then begin
            FinChrgMemoHeader.TestField("Fin. Charge Terms Code");
            FinChrgTerms.Get(FinChrgMemoHeader."Fin. Charge Terms Code");
            if FinChrgTerms."Interest Calculation" in
               [FinChrgTerms."Interest Calculation"::"Closed Entries",
                FinChrgTerms."Interest Calculation"::"All Entries"]
            then begin
                FinChrgMemoLine.SetRange(Type, FinChrgMemoLine.Type::"Customer Ledger Entry");
                if FinChrgMemoLine.FindSet() then
                    repeat
                        UpdateCustLedgEntriesCalculateInterest(FinChrgMemoLine."Entry No.", FinChrgMemoHeader."Document Date");
                    until FinChrgMemoLine.Next() = 0;
                FinChrgMemoLine.SetRange(Type);
            end;
        end;

        InsertIssuedFinChrgMemoHeader(FinChrgMemoHeader, IssuedFinChrgMemoHeader);

        if NextEntryNo = 0 then begin
            ReminderFinChargeEntry.LockTable();
            NextEntryNo := ReminderFinChargeEntry.GetLastEntryNo() + 1;
        end;

        FinChrgCommentLine.CopyComments(
          FinChrgCommentLine.Type::"Finance Charge Memo", FinChrgCommentLine.Type::"Issued Finance Charge Memo", FinChrgMemoHeader."No.",
          IssuedFinChrgMemoHeader."No.");
        FinChrgCommentLine.DeleteComments(FinChrgCommentLine.Type::"Finance Charge Memo", FinChrgMemoHeader."No.");

        FinChrgMemoLine.SetRange("Detailed Interest Rates Entry");
        if FinChrgMemoLine.FindSet() then
            repeat
                if (FinChrgMemoLine.Type = FinChrgMemoLine.Type::"Customer Ledger Entry") and
                   not FinChrgMemoLine."Detailed Interest Rates Entry"
                then begin
                    InsertFinChargeEntry(IssuedFinChrgMemoHeader, FinChrgMemoLine);
                    NextEntryNo := NextEntryNo + 1;
                end;
                InsertIssuedFinChrgMemoLine(FinChrgMemoLine, IssuedFinChrgMemoHeader."No.");
            until FinChrgMemoLine.Next() = 0;

        FinChrgMemoLine.DeleteAll();
        FinChrgMemoHeader.Delete();

        OnAfterIssueFinChargeMemo(FinChrgMemoHeader, IssuedFinChrgMemoHeader."No.");
    end;

    local procedure CheckDimensions()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimensions(FinChrgMemoHeader, IsHandled);
        if IsHandled then
            exit;

        if not DimMgt.CheckDimIDComb(FinChrgMemoHeader."Dimension Set ID") then
            Error(
              Text002,
              FinChrgMemoHeader.TableCaption, FinChrgMemoHeader."No.", DimMgt.GetDimCombErr());

        TableID[1] := DATABASE::Customer;
        No[1] := FinChrgMemoHeader."Customer No.";
        if not DimMgt.CheckDimValuePosting(TableID, No, FinChrgMemoHeader."Dimension Set ID") then
            Error(
              Text003,
              FinChrgMemoHeader.TableCaption, FinChrgMemoHeader."No.", DimMgt.GetDimValuePostingErr());
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        FinChrgTerms: Record "Finance Charge Terms";
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
        GenJnlBatch: Record "Gen. Journal Batch";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlLine2: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        SourceCode: Record "Source Code";
        DimMgt: Codeunit DimensionManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocNo: Code[20];
        NextEntryNo: Integer;
        ReplacePostingDate: Boolean;
        PostingDate: Date;
        SrcCode: Code[10];
        FinChrgMemoInterestAmount: Decimal;
        FinChrgMemoInterestVATAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];

#pragma warning disable AA0074
        Text000: Label 'There is nothing to issue.';
        Text001: Label 'must be positive or 0';
#pragma warning disable AA0470
        Text002: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        Text003: Label 'A dimension in %1 %2 has caused an error. %3';
#pragma warning restore AA0470
#pragma warning restore AA0074
        MissingJournalFieldErr: Label 'Please enter a %1 when posting Additional Fees or Interest.', Comment = '%1 - field caption';

    /// <summary>
    /// Sets the finance charge memo header and posting options for the issue process.
    /// </summary>
    /// <param name="NewFinChrgMemoHeader">Specifies the finance charge memo header to issue.</param>
    /// <param name="NewReplacePostingDate">Specifies whether to replace the posting date on the finance charge memo.</param>
    /// <param name="NewPostingDate">Specifies the new posting date to use if NewReplacePostingDate is true.</param>
    procedure Set(var NewFinChrgMemoHeader: Record "Finance Charge Memo Header"; NewReplacePostingDate: Boolean; NewPostingDate: Date)
    begin
        FinChrgMemoHeader := NewFinChrgMemoHeader;
        ReplacePostingDate := NewReplacePostingDate;
        PostingDate := NewPostingDate;
    end;

    /// <summary>
    /// Sets the general journal batch to use when posting finance charge memo entries.
    /// </summary>
    /// <param name="NewGenJnlBatch">Specifies the general journal batch for posting entries.</param>
    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    /// <summary>
    /// Retrieves the issued finance charge memo header that was created during the issue process.
    /// </summary>
    /// <param name="NewIssuedFinChrgMemoHeader">Returns the issued finance charge memo header record.</param>
    procedure GetIssuedFinChrgMemo(var NewIssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        NewIssuedFinChrgMemoHeader := IssuedFinChrgMemoHeader;
    end;

    local procedure InitGenJnlLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; SystemCreatedEntry: Boolean)
    begin
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := TempGenJnlLine."Line No." + 1;
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::"Finance Charge Memo";
        TempGenJnlLine."Document No." := DocNo;
        if FinChrgMemoHeader."Post Additional Fee" or FinChrgMemoHeader."Post Interest" then begin
            TempGenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
            TempGenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        end;
        TempGenJnlLine."Posting Date" := FinChrgMemoHeader."Posting Date";
        TempGenJnlLine."VAT Reporting Date" := FinChrgMemoHeader."VAT Reporting Date";
        TempGenJnlLine."Document Date" := FinChrgMemoHeader."Document Date";
        TempGenJnlLine."Account Type" := AccType;
        TempGenJnlLine."Account No." := AccNo;
        TempGenJnlLine.Validate("Account No.");
        TempGenJnlLine."Posting Group" := FinChrgMemoHeader."Customer Posting Group";
        if TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::"G/L Account" then begin
            TempGenJnlLine."Gen. Posting Type" := TempGenJnlLine."Gen. Posting Type"::Sale;
            TempGenJnlLine."Gen. Bus. Posting Group" := FinChrgMemoHeader."Gen. Bus. Posting Group";
            TempGenJnlLine."VAT Bus. Posting Group" := FinChrgMemoHeader."VAT Bus. Posting Group";
        end;
        TempGenJnlLine.Validate("Currency Code", FinChrgMemoHeader."Currency Code");
        if TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Customer then begin
            TempGenJnlLine.Validate(Amount, TotalAmount);
            TempGenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
            TempGenJnlLine."Due Date" := FinChrgMemoHeader."Due Date";
        end;
        TempGenJnlLine.Description := FinChrgMemoHeader."Posting Description";
        TempGenJnlLine."Source Type" := TempGenJnlLine."Source Type"::Customer;
        TempGenJnlLine."Source No." := FinChrgMemoHeader."Customer No.";
        TempGenJnlLine."Source Code" := SrcCode;
        TempGenJnlLine."Reason Code" := FinChrgMemoHeader."Reason Code";
        TempGenJnlLine."System-Created Entry" := SystemCreatedEntry;
        TempGenJnlLine."Posting No. Series" := FinChrgMemoHeader."Issuing No. Series";
        TempGenJnlLine."Salespers./Purch. Code" := '';
        OnAfterInitGenJnlLine(TempGenJnlLine, FinChrgMemoHeader, SrcCode);
    end;

    local procedure CheckNegativeFinChrgMemoLineAmount(FinChrgMemoLine: Record "Finance Charge Memo Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNegativeFinChrgMemoLineAmount(FinChrgMemoHeader, FinChrgMemoLine, FinChrgTerms, IsHandled);
        if IsHandled then
            exit;
        if FinChrgMemoLine.Amount < 0 then
            FinChrgMemoLine.FieldError(Amount, Text001);
    end;

    /// <summary>
    /// Deletes all lines associated with the specified issued finance charge memo header.
    /// </summary>
    /// <param name="IssuedFinChrgMemoHeader">Specifies the issued finance charge memo header whose lines will be deleted.</param>
    procedure DeleteIssuedFinChrgLines(IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        IssuedFinChrgMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChrgMemoHeader."No.");
        IssuedFinChrgMemoLine.DeleteAll();
    end;

    /// <summary>
    /// Increments the number of times the issued finance charge memo has been printed.
    /// </summary>
    /// <param name="IssuedFinChrgMemoHeader">Specifies the issued finance charge memo header to update the print count for.</param>
    procedure IncrNoPrinted(var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        IssuedFinChrgMemoHeader.Find();
        IssuedFinChrgMemoHeader."No. Printed" := IssuedFinChrgMemoHeader."No. Printed" + 1;
        OnIncrNoPrintedOnBeforeModify(IssuedFinChrgMemoHeader);
        IssuedFinChrgMemoHeader.Modify();
        Commit();
    end;

    /// <summary>
    /// Prepares the issued finance charge memo header for deletion by transferring fields and setting up source code information.
    /// </summary>
    /// <param name="FinChrgMemoHeader">Specifies the finance charge memo header to test for deletion.</param>
    /// <param name="IssuedFinChrgMemoHeader">Returns the prepared issued finance charge memo header record.</param>
    procedure TestDeleteHeader(FinChrgMemoHeader: Record "Finance Charge Memo Header"; var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        Clear(IssuedFinChrgMemoHeader);
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        if (FinChrgMemoHeader."Issuing No. Series" <> '') and
           ((FinChrgMemoHeader."Issuing No." <> '') or (FinChrgMemoHeader."No. Series" = FinChrgMemoHeader."Issuing No. Series"))
        then begin
            IssuedFinChrgMemoHeader.TransferFields(FinChrgMemoHeader);
            if FinChrgMemoHeader."Issuing No." <> '' then
                IssuedFinChrgMemoHeader."No." := FinChrgMemoHeader."Issuing No.";
            IssuedFinChrgMemoHeader."Pre-Assigned No. Series" := FinChrgMemoHeader."No. Series";
            IssuedFinChrgMemoHeader."Pre-Assigned No." := FinChrgMemoHeader."No.";
            IssuedFinChrgMemoHeader."Posting Date" := Today;
            IssuedFinChrgMemoHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(IssuedFinChrgMemoHeader."User ID"));
            IssuedFinChrgMemoHeader."Source Code" := SourceCode.Code;
        end;

        OnAfterTestDeleteHeader(IssuedFinChrgMemoHeader, FinChrgMemoHeader);
    end;

    /// <summary>
    /// Deletes a finance charge memo header and creates a corresponding issued finance charge memo record for audit purposes.
    /// </summary>
    /// <param name="FinChrgMemoHeader">Specifies the finance charge memo header to delete.</param>
    /// <param name="IssuedFinChrgMemoHeader">Returns the created issued finance charge memo header for the deleted document.</param>
    procedure DeleteHeader(FinChrgMemoHeader: Record "Finance Charge Memo Header"; var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        TestDeleteHeader(FinChrgMemoHeader, IssuedFinChrgMemoHeader);
        if IssuedFinChrgMemoHeader."No." <> '' then begin
            IssuedFinChrgMemoHeader."Shortcut Dimension 1 Code" := '';
            IssuedFinChrgMemoHeader."Shortcut Dimension 2 Code" := '';
            IssuedFinChrgMemoHeader.Insert();
            IssuedFinChrgMemoLine.Init();
            IssuedFinChrgMemoLine."Finance Charge Memo No." := FinChrgMemoHeader."No.";
            IssuedFinChrgMemoLine."Line No." := 10000;
            IssuedFinChrgMemoLine.Description := SourceCode.Description;
            IssuedFinChrgMemoLine.Insert();
        end;
    end;

    local procedure InsertIssuedFinChrgMemoHeader(FinChrgMemoHeader: Record "Finance Charge Memo Header"; var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        IssuedFinChrgMemoHeader.Init();
        IssuedFinChrgMemoHeader.TransferFields(FinChrgMemoHeader);
        IssuedFinChrgMemoHeader."No. Series" := FinChrgMemoHeader."Issuing No. Series";
        IssuedFinChrgMemoHeader."No." := DocNo;
        IssuedFinChrgMemoHeader."Pre-Assigned No. Series" := FinChrgMemoHeader."No. Series";
        IssuedFinChrgMemoHeader."Pre-Assigned No." := FinChrgMemoHeader."No.";
        IssuedFinChrgMemoHeader."Source Code" := SrcCode;
        IssuedFinChrgMemoHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(IssuedFinChrgMemoHeader."User ID"));
        OnBeforeIssuedFinChrgMemoHeaderInsert(IssuedFinChrgMemoHeader, FinChrgMemoHeader);
        IssuedFinChrgMemoHeader.Insert();
    end;

    local procedure InsertIssuedFinChrgMemoLine(FinChrgMemoLine: Record "Finance Charge Memo Line"; IssuedDocNo: Code[20])
    var
        IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        IssuedFinChrgMemoLine.Init();
        IssuedFinChrgMemoLine.TransferFields(FinChrgMemoLine);
        IssuedFinChrgMemoLine."Finance Charge Memo No." := IssuedDocNo;
        IssuedFinChrgMemoLine.Insert();
        OnAfterInsertIssuedFinChrgMemoLine(FinChrgMemoLine, IssuedFinChrgMemoLine, CurrencyExchangeRate.ExchangeRate(FinChrgMemoHeader."Posting Date", FinChrgMemoHeader."Currency Code"));
    end;

    local procedure InsertFinChargeEntry(IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header"; FinChrgMemoLine: Record "Finance Charge Memo Line")
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
    begin
        ReminderFinChargeEntry.Init();
        ReminderFinChargeEntry."Entry No." := NextEntryNo;
        ReminderFinChargeEntry.Type := ReminderFinChargeEntry.Type::"Finance Charge Memo";
        ReminderFinChargeEntry."No." := IssuedFinChrgMemoHeader."No.";
        ReminderFinChargeEntry."Posting Date" := IssuedFinChrgMemoHeader."Posting Date";
        ReminderFinChargeEntry."Due Date" := IssuedFinChrgMemoHeader."Due Date";
        ReminderFinChargeEntry."Document Date" := IssuedFinChrgMemoHeader."Document Date";
        ReminderFinChargeEntry."Customer No." := IssuedFinChrgMemoHeader."Customer No.";
        ReminderFinChargeEntry."Customer Entry No." := FinChrgMemoLine."Entry No.";
        ReminderFinChargeEntry."Document Type" := FinChrgMemoLine."Document Type";
        ReminderFinChargeEntry."Document No." := FinChrgMemoLine."Document No.";
        ReminderFinChargeEntry."Remaining Amount" := FinChrgMemoLine."Remaining Amount";
        ReminderFinChargeEntry."Interest Amount" := FinChrgMemoLine.Amount;
        ReminderFinChargeEntry."Interest Posted" := (FinChrgMemoInterestAmount <> 0) and FinChrgMemoHeader."Post Interest";
        ReminderFinChargeEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReminderFinChargeEntry."User ID"));
        OnBeforeInsertFinChargeEntry(ReminderFinChargeEntry, FinChrgMemoHeader, FinChrgMemoLine);
        ReminderFinChargeEntry.Insert();
    end;

    local procedure SetDimensions(var GenJnlLine: Record "Gen. Journal Line"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        DefaultDimension: Record "Default Dimension";
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        GenJnlLine."Shortcut Dimension 1 Code" := FinanceChargeMemoHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := FinanceChargeMemoHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := FinanceChargeMemoHeader."Dimension Set ID";
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account" then begin
            DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", GenJnlLine."Account No.");
            DefaultDimension.SetRange("Table ID", Database::"G/L Account");
            DefaultDimension.SetRange("No.", GenJnlLine."Account No.");
            if not DefaultDimension.IsEmpty() then
                GenJnlLine."Dimension Set ID" :=
                    DimMgt.GetRecDefaultDimID(
                        GenJnlLine, 0, DefaultDimSource, SrcCode, GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code", GenJnlLine."Dimension Set ID", 0);
        end;

        OnAfterSetDimensionsProcedure(GenJnlLine, FinanceChargeMemoHeader, DefaultDimSource, SrcCode);
    end;

    local procedure UpdateCustLedgEntriesCalculateInterest(EntryNo: Integer; DocumentDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustLedgEntriesCalculateInterest(EntryNo, DocumentDate, IsHandled);
        if IsHandled then
            exit;

        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry.SetFilter("Date Filter", '..%1', DocumentDate);
        CustLedgerEntry.CalcFields("Remaining Amount");
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

    local procedure CheckVATDate(var FinChrgMemoHeader2: Record "Finance Charge Memo Header")
    begin
        // ensure VAT Date is filled in
        if FinChrgMemoHeader2."VAT Reporting Date" = 0D then begin
            FinChrgMemoHeader2."VAT Reporting Date" := GLSetup.GetVATDate(FinChrgMemoHeader2."Posting Date", FinChrgMemoHeader2."Document Date");
            FinChrgMemoHeader2.Modify();
        end;
    end;

    /// <summary>
    /// Raised after the interest amounts are calculated for all finance charge memo lines.
    /// </summary>
    /// <param name="FinChargeMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="TempGenJournalLine">Specifies the temporary general journal line records.</param>
    /// <param name="FinChrgMemoInterestAmount">Specifies the calculated interest amount.</param>
    /// <param name="FinChrgMemoInterestVATAmount">Specifies the calculated interest VAT amount.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateFinChrgMemoInterestAmounts(var FinChargeMemoHeader: Record "Finance Charge Memo Header"; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var FinChrgMemoInterestAmount: Decimal; var FinChrgMemoInterestVATAmount: Decimal)
    begin
    end;

    /// <summary>
    /// Raised after a general journal line is initialized for posting.
    /// </summary>
    /// <param name="GenJnlLine">Specifies the general journal line record.</param>
    /// <param name="FinChargeMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="SrcCode">Specifies the source code.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; FinChargeMemoHeader: Record "Finance Charge Memo Header"; var SrcCode: Code[10])
    begin
    end;

    /// <summary>
    /// Raised after the finance charge memo is successfully issued.
    /// </summary>
    /// <param name="FinChargeMemoHeader">Specifies the finance charge memo header that was issued.</param>
    /// <param name="IssuedFinChargeMemoNo">Specifies the document number of the issued finance charge memo.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIssueFinChargeMemo(var FinChargeMemoHeader: Record "Finance Charge Memo Header"; IssuedFinChargeMemoNo: Code[20])
    begin
    end;

    /// <summary>
    /// Raised after dimensions are set on the general journal line.
    /// </summary>
    /// <param name="GenJnlLine">Specifies the general journal line record.</param>
    /// <param name="FinanceChargeMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="DefaultDimSource">Specifies the list of default dimension sources.</param>
    /// <param name="SrcCode">Specifies the source code.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimensionsProcedure(var GenJnlLine: Record "Gen. Journal Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var SrcCode: Code[10])
    begin
    end;

    /// <summary>
    /// Raised after the TestDeleteHeader procedure prepares the issued finance charge memo header.
    /// </summary>
    /// <param name="IssuedFinChargeMemoHeader">Specifies the prepared issued finance charge memo header record.</param>
    /// <param name="FinanceChargeMemoHeader">Specifies the original finance charge memo header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterTestDeleteHeader(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    /// <summary>
    /// Raised before dimensions are validated on the finance charge memo.
    /// </summary>
    /// <param name="FinChargeMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="IsHandled">Set to true to skip the default dimension validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimensions(var FinChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before a reminder or finance charge entry is inserted.
    /// </summary>
    /// <param name="ReminderFinChargeEntry">Specifies the reminder or finance charge entry to be inserted.</param>
    /// <param name="FinanceChargeMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="FinanceChargeMemoLine">Specifies the finance charge memo line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFinChargeEntry(var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FinanceChargeMemoLine: Record "Finance Charge Memo Line")
    begin
    end;

    /// <summary>
    /// Raised before the finance charge memo issue process begins.
    /// </summary>
    /// <param name="FinChargeMemoHeader">Specifies the finance charge memo header to issue.</param>
    /// <param name="ReplacePostingDate">Specifies whether to replace the posting date.</param>
    /// <param name="PostingDate">Specifies the posting date to use.</param>
    /// <param name="IsHandled">Set to true to skip the default issue process.</param>
    /// <param name="IssuedFinChargeMemoHeader">Specifies the issued finance charge memo header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssueFinChargeMemo(var FinChargeMemoHeader: Record "Finance Charge Memo Header"; var ReplacePostingDate: Boolean; var PostingDate: Date; var IsHandled: Boolean; IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
    end;

    /// <summary>
    /// Raised before the issued finance charge memo header is inserted.
    /// </summary>
    /// <param name="IssuedFinChargeMemoHeader">Specifies the issued finance charge memo header to be inserted.</param>
    /// <param name="FinanceChargeMemoHeader">Specifies the original finance charge memo header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedFinChrgMemoHeaderInsert(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    /// <summary>
    /// Raised before the general journal line is posted with validation.
    /// </summary>
    /// <param name="GenJournalLine">Specifies the general journal line to be posted.</param>
    /// <param name="FinanceChargeMemoHeader">Specifies the finance charge memo header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlPostLineRunWithCheck(var GenJournalLine: Record "Gen. Journal Line"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    /// <summary>
    /// Raised before updating customer ledger entries with the closing interest calculated flag.
    /// </summary>
    /// <param name="CustLedgEntry2">Specifies the customer ledger entries to be updated.</param>
    /// <param name="CustLedgEntry">Specifies the original customer ledger entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustLedgEntriesCalculateInterestOnBeforeCustLedgerEntry2ModifyAll(var CustLedgEntry2: Record "Cust. Ledger Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after an issued finance charge memo line is inserted.
    /// </summary>
    /// <param name="FinChrgMemoLine">Specifies the original finance charge memo line.</param>
    /// <param name="IssuedFinChrgMemoLine">Specifies the inserted issued finance charge memo line.</param>
    /// <param name="CurrencyFactor">Specifies the currency exchange rate factor.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertIssuedFinChrgMemoLine(FinChrgMemoLine: Record "Finance Charge Memo Line"; var IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line"; CurrencyFactor: Decimal)
    begin
    end;

    /// <summary>
    /// Raised after a finance charge memo line is processed during the issue process.
    /// </summary>
    /// <param name="FinChrgMemoLine">Specifies the finance charge memo line that was processed.</param>
    /// <param name="DocNo">Specifies the document number of the issued finance charge memo.</param>
    /// <param name="CurrencyFactor">Specifies the currency exchange rate factor.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFinChrgMemoLine(FinChrgMemoLine: Record "Finance Charge Memo Line"; DocNo: Code[20]; CurrencyFactor: Decimal)
    begin
    end;

    /// <summary>
    /// Raised before checking if the finance charge memo line amount is negative.
    /// </summary>
    /// <param name="FinChrgMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="FinChrgMemoLine">Specifies the finance charge memo line to check.</param>
    /// <param name="FinChrgTerms">Specifies the finance charge terms record.</param>
    /// <param name="IsHandled">Set to true to skip the default negative amount check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNegativeFinChrgMemoLineAmount(FinChrgMemoHeader: Record "Finance Charge Memo Header"; FinChrgMemoLine: Record "Finance Charge Memo Line"; FinChrgTerms: Record "Finance Charge Terms"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before the print count is incremented on the issued finance charge memo.
    /// </summary>
    /// <param name="IssuedFinChrgMemoHeader">Specifies the issued finance charge memo header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnIncrNoPrintedOnBeforeModify(var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
    end;

    /// <summary>
    /// Raised after a general journal line for a G/L account fee is inserted.
    /// </summary>
    /// <param name="GenJournalLine">Specifies the inserted general journal line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGLAccountGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Raised before a general journal line for a G/L account fee is inserted.
    /// </summary>
    /// <param name="GenJournalLine">Specifies the general journal line to be inserted.</param>
    /// <param name="FinanceChargeMemoLine">Specifies the finance charge memo line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGLAccountGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; FinanceChargeMemoLine: Record "Finance Charge Memo Line")
    begin
    end;

    /// <summary>
    /// Raised after a general journal line for interest is inserted.
    /// </summary>
    /// <param name="GenJournalLine">Specifies the inserted general journal line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInterestGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Raised before a general journal line for interest is inserted.
    /// </summary>
    /// <param name="GenJournalLine">Specifies the general journal line to be inserted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInterestGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Raised after a general journal line for the customer total is inserted.
    /// </summary>
    /// <param name="GenJournalLine">Specifies the inserted general journal line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterTotalGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Raised before a general journal line for the customer total is inserted.
    /// </summary>
    /// <param name="GenJournalLine">Specifies the general journal line to be inserted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeTotalGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Raised after the general journal line is posted with validation.
    /// </summary>
    /// <param name="GenJournalLine">Specifies the posted general journal line.</param>
    /// <param name="GenJnlPostLine">Specifies the posting codeunit instance.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGenJnlPostLineRunWithCheck(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Raised before customer ledger entries are updated with the calculate interest flag.
    /// </summary>
    /// <param name="EntryNo">Specifies the customer ledger entry number.</param>
    /// <param name="DocumentDate">Specifies the document date for the calculation.</param>
    /// <param name="IsHandled">Set to true to skip the default update process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgEntriesCalculateInterest(EntryNo: Integer; DocumentDate: Date; var IsHandled: Boolean)
    begin
    end;
}

