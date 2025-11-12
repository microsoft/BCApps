// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Environment.Configuration;
using System.Utilities;

codeunit 1395 "Cancel Issued Fin. Charge Memo"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Reminder/Fin. Charge Entry" = rm,
                  TableData "Issued Fin. Charge Memo Header" = rm,
                  TableData "Issued Fin. Charge Memo Line" = rm;
    TableNo = "Issued Fin. Charge Memo Header";

    trigger OnRun()
    begin
        if CheckIssuedFinChargeMemo(Rec) then
            CancelIssuedFinChargeMemo(Rec);
    end;

    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlBatch: Record "Gen. Journal Batch";
        SourceCodeSetup: Record "Source Code Setup";
        TempErrorMessage: Record "Error Message" temporary;
        GLSetup: Record "General Ledger Setup";
        FinChargeMemoSourceCode: Code[10];
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        CancelAppliedEntryErr: Label 'You must unapply customer ledger entry %1 before canceling issued finance charge memo %2.', Comment = '%1 - entry number, %2 - issued finance charge memo number';
        ShowCustomerLedgerEntryTxt: Label 'Show customer ledger entry %1.', Comment = '%1 - entry number.';
        SkipShowNotification: Boolean;
        UseSameDocumentNo: Boolean;
        UseSamePostingDate: Boolean;
        NewPostingDate: Date;
        MissingFieldNameErr: Label 'Please enter a %1.', Comment = '%1 - field caption';

    local procedure CheckIssuedFinChargeMemo(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"): Boolean
    begin
        IssuedFinChargeMemoHeader.TestField(Canceled, false);

        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then begin
            if GenJnlBatch."Journal Template Name" = '' then
                Error(MissingFieldNameErr, TempGenJnlLine.FieldCaption("Journal Template Name"));
            if GenJnlBatch.Name = '' then
                Error(MissingFieldNameErr, TempGenJnlLine.FieldCaption("Journal Batch Name"));
        end;

        exit(CheckAppliedFinChargeMemoCustLedgerEntry(IssuedFinChargeMemoHeader));
    end;

    local procedure CancelIssuedFinChargeMemo(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        FeePosted: Boolean;
        DocumentNo: Code[20];
        PostingDate: Date;
        InterestAmount: Decimal;
        InterestVATAmount: Decimal;
    begin
        OnBeforeCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);

        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Finance Charge Memo");
        FinChargeMemoSourceCode := SourceCodeSetup."Finance Charge Memo";
        FinanceChargeTerms.Get(IssuedFinChargeMemoHeader."Fin. Charge Terms Code");
        FeePosted := IsFeePosted(IssuedFinChargeMemoHeader);
        GetDocumentNoAndPostingDate(IssuedFinChargeMemoHeader, DocumentNo, PostingDate);

        SetIssuedFinChargeMemoCancelled(IssuedFinChargeMemoHeader, DocumentNo);

        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
        IssuedFinChargeMemoLine.SetRange("Detailed Interest Rates Entry", false);
        if IssuedFinChargeMemoLine.FindSet() then
            repeat
                case IssuedFinChargeMemoLine.Type of
                    IssuedFinChargeMemoLine.Type::"Customer Ledger Entry":
                        begin
                            UpdateCustLedgEntryCalculateInterest(IssuedFinChargeMemoLine."Entry No.");
                            SetFinChargeMemoEntryCancelled(IssuedFinChargeMemoLine);
                            InterestAmount := InterestAmount + IssuedFinChargeMemoLine.Amount;
                            InterestVATAmount := InterestVATAmount + IssuedFinChargeMemoLine."VAT Amount";
                        end;
                    IssuedFinChargeMemoLine.Type::"G/L Account":
                        if FinanceChargeTerms."Post Additional Fee" or (IssuedFinChargeMemoLine."Line Type" = IssuedFinChargeMemoLine."Line Type"::Rounding) then
                            InsertGenJnlLineForFee(IssuedFinChargeMemoHeader, IssuedFinChargeMemoLine, DocumentNo, PostingDate);
                end;
            until IssuedFinChargeMemoLine.Next() = 0;

        if (InterestAmount <> 0) and FeePosted then
            InsertGenJnlLineForInterest(
              IssuedFinChargeMemoHeader, DocumentNo, PostingDate, InterestAmount, InterestVATAmount);

        if (TotalAmount <> 0) or (TotalAmountLCY <> 0) then begin
            InitGenJnlLine(
              IssuedFinChargeMemoHeader, TempGenJnlLine, TempGenJnlLine."Account Type"::Customer,
              IssuedFinChargeMemoHeader."Customer No.", true, DocumentNo, PostingDate);
            TempGenJnlLine.Validate(Amount, TotalAmount);
            TempGenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
            TempGenJnlLine.Insert();
        end;

        if FeePosted then
            PostGenJnlLines();

        OnAfterCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);
    end;

    local procedure CheckAppliedFinChargeMemoCustLedgerEntry(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", IssuedFinChargeMemoHeader."Customer No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Finance Charge Memo");
        CustLedgerEntry.SetRange("Document No.", IssuedFinChargeMemoHeader."No.");
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
            OnCheckAppliedFinChargeMemoCustLedgerEntryOnAfterCalcAmounts(CustLedgerEntry);
            if CustLedgerEntry.Amount <> CustLedgerEntry."Remaining Amount" then begin
                TempErrorMessage.LogMessage(
                  IssuedFinChargeMemoHeader,
                  IssuedFinChargeMemoHeader.FieldNo("No."),
                  TempErrorMessage."Message Type"::Error,
                  StrSubstNo(CancelAppliedEntryErr, CustLedgerEntry."Entry No.", IssuedFinChargeMemoHeader."No."));
                if not SkipShowNotification then
                    ShowAppliedCustomerLedgerEntryNotification(CustLedgerEntry."Entry No.", IssuedFinChargeMemoHeader);
                exit(false);
            end;
        end;

        exit(true);
    end;

    local procedure SetFinChargeMemoEntryCancelled(IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line")
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
    begin
        ReminderFinChargeEntry.SetRange("No.", IssuedFinChargeMemoLine."Finance Charge Memo No.");
        ReminderFinChargeEntry.SetRange("Customer Entry No.", IssuedFinChargeMemoLine."Entry No.");
        if ReminderFinChargeEntry.FindFirst() then begin
            ReminderFinChargeEntry.Canceled := true;
            ReminderFinChargeEntry.Modify();
        end;
    end;

    local procedure InsertGenJnlLineForFee(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line"; DocumentNo: Code[20]; PostingDate: Date)
    begin
        if IssuedFinChargeMemoLine.Amount <> 0 then begin
            IssuedFinChargeMemoLine.TestField("No.");
            InitGenJnlLine(IssuedFinChargeMemoHeader, TempGenJnlLine, TempGenJnlLine."Account Type"::"G/L Account",
              IssuedFinChargeMemoLine."No.",
              IssuedFinChargeMemoLine."System-Created Entry", DocumentNo, PostingDate);
            TempGenJnlLine.CopyFromIssuedFinChargeMemoLine(IssuedFinChargeMemoLine);
            if IssuedFinChargeMemoLine."VAT Calculation Type" = IssuedFinChargeMemoLine."VAT Calculation Type"::"Sales Tax" then begin
                TempGenJnlLine.Validate("Tax Area Code", IssuedFinChargeMemoHeader."Tax Area Code");
                TempGenJnlLine.Validate("Tax Liable", IssuedFinChargeMemoHeader."Tax Liable");
                TempGenJnlLine.Validate("Tax Group Code", IssuedFinChargeMemoLine."Tax Group Code");
            end;
            TempGenJnlLine.UpdateLineBalance();
            TotalAmount := TotalAmount - TempGenJnlLine.Amount;
            TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
            TempGenJnlLine."Bill-to/Pay-to No." := IssuedFinChargeMemoHeader."Customer No.";
            TempGenJnlLine.Insert();
        end;
    end;

    local procedure InsertGenJnlLineForInterest(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; DocumentNo: Code[20]; PostingDate: Date; InterestAmount: Decimal; InterestVATAmount: Decimal)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(IssuedFinChargeMemoHeader."Customer Posting Group");
        InitGenJnlLine(
          IssuedFinChargeMemoHeader, TempGenJnlLine, TempGenJnlLine."Account Type"::"G/L Account",
          CustomerPostingGroup.GetInterestAccount(), true, DocumentNo, PostingDate);

        TempGenJnlLine.Validate("VAT Bus. Posting Group", IssuedFinChargeMemoHeader."VAT Bus. Posting Group");
        TempGenJnlLine.Validate(Amount, InterestAmount + InterestVATAmount);
        TempGenJnlLine.UpdateLineBalance();
        TotalAmount := TotalAmount - TempGenJnlLine.Amount;
        TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
        TempGenJnlLine."Bill-to/Pay-to No." := IssuedFinChargeMemoHeader."Customer No.";
        TempGenJnlLine.Insert();
    end;

    local procedure InitGenJnlLine(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var GenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; SystemCreatedEntry: Boolean; DocumentNo: Code[20]; PostingDate: Date)
    begin
        GenJnlLine.Init();
        GenJnlLine."Line No." := GenJnlLine."Line No." + 1;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine."Posting Date" := PostingDate;

        GenJnlLine."Account Type" := AccountType;
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine.CopyFromIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader);
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then begin
            GenJnlLine.Amount := TotalAmount;
            GenJnlLine."Amount (LCY)" := TotalAmountLCY;
            GenJnlLine."Due Date" := IssuedFinChargeMemoHeader."Due Date";
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Finance Charge Memo";
            GenJnlLine."Applies-to Doc. No." := IssuedFinChargeMemoHeader."No.";
        end;
        GenJnlLine."Source Code" := FinChargeMemoSourceCode;
        GenJnlLine."System-Created Entry" := SystemCreatedEntry;
        GenJnlLine."Salespers./Purch. Code" := '';
        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then begin
            GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
            GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        end;

        OnAfterInitGenJnlLine(GenJnlLine, IssuedFinChargeMemoHeader);
    end;

    procedure GetAppliedCustomerLedgerEntryNotificationId(): Guid
    begin
        exit('3C569183-8468-4978-936C-EF8A7C58B050');
    end;

    procedure GetErrorMessages(var TempErrorMessageResult: Record "Error Message" temporary): Boolean
    begin
        TempErrorMessageResult.Copy(TempErrorMessage, true);
        exit(not TempErrorMessage.IsEmpty);
    end;

    local procedure GetDocumentNoAndPostingDate(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var DocumentNo: Code[20]; var PostingDate: Date)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if UseSamePostingDate then
            PostingDate := IssuedFinChargeMemoHeader."Posting Date"
        else
            PostingDate := NewPostingDate;

        if UseSameDocumentNo then
            DocumentNo := IssuedFinChargeMemoHeader."No."
        else begin
            SalesSetup.Get();
            SalesSetup.TestField("Canc. Iss. Fin. Ch. Mem. Nos.");
            DocumentNo := NoSeries.GetNextNo(SalesSetup."Canc. Iss. Fin. Ch. Mem. Nos.", PostingDate);
        end;
    end;

    local procedure PostGenJnlLines()
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        if TempGenJnlLine.FindSet() then
            repeat
                GenJnlPostLine.RunWithCheck(TempGenJnlLine);
            until TempGenJnlLine.Next() = 0;

        TempGenJnlLine.DeleteAll();
    end;

    procedure SetParameters(NewUseSameDocumentNo: Boolean; NewUseSamePostingDate: Boolean; PostingDate: Date; NewSkipShowNotification: Boolean)
    begin
        UseSameDocumentNo := NewUseSameDocumentNo;
        UseSamePostingDate := NewUseSamePostingDate;
        NewPostingDate := PostingDate;
        SkipShowNotification := NewSkipShowNotification;
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    local procedure SetIssuedFinChargeMemoCancelled(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; DocumentNo: Code[20])
    begin
        IssuedFinChargeMemoHeader.Validate(Canceled, true);
        IssuedFinChargeMemoHeader."Canceled By" := UserId;
        IssuedFinChargeMemoHeader."Canceled Date" := Today;
        IssuedFinChargeMemoHeader."Canceled By Document No." := DocumentNo;
        IssuedFinChargeMemoHeader.Modify();
    end;

    local procedure ShowAppliedCustomerLedgerEntryNotification(EntryNo: Integer; IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        AppliedCustomerLedgerNotification: Notification;
    begin
        AppliedCustomerLedgerNotification.Id := GetAppliedCustomerLedgerEntryNotificationId();
        AppliedCustomerLedgerNotification.Message :=
          StrSubstNo(CancelAppliedEntryErr, EntryNo, IssuedFinChargeMemoHeader."No.");
        AppliedCustomerLedgerNotification.AddAction(
          StrSubstNo(ShowCustomerLedgerEntryTxt, EntryNo),
          CODEUNIT::"Cancel Issued Fin. Charge Memo",
          'ShowCustomerLedgerEntry');
        AppliedCustomerLedgerNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        AppliedCustomerLedgerNotification.SetData('EntryNo', Format(EntryNo));
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          AppliedCustomerLedgerNotification, IssuedFinChargeMemoHeader.RecordId, GetAppliedCustomerLedgerEntryNotificationId());
    end;

    procedure ShowCustomerLedgerEntry(Notification: Notification)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        Evaluate(EntryNo, Notification.GetData('EntryNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);
    end;

    local procedure UpdateCustLedgEntryCalculateInterest(EntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetCurrentKey("Closed by Entry No.");
        CustLedgerEntry.SetRange("Closed by Entry No.", EntryNo);
        CustLedgerEntry.SetRange("Closing Interest Calculated", true);
        CustLedgerEntry.ModifyAll("Closing Interest Calculated", false);
    end;

    local procedure IsFeePosted(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", IssuedFinChargeMemoHeader."Customer No.");
        CustLedgerEntry.SetRange("Document No.", IssuedFinChargeMemoHeader."No.");
        exit(not CustLedgerEntry.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCancelIssuedFinChargeMemo(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCancelIssuedFinChargeMemo(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAppliedFinChargeMemoCustLedgerEntryOnAfterCalcAmounts(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

