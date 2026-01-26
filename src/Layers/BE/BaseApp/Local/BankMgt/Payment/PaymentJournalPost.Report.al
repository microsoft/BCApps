// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 2000004 "Payment Journal Post"
{
    Caption = 'Payment Journal Post';
    Permissions = TableData "Cust. Ledger Entry" = rim,
                  TableData "Vendor Ledger Entry" = rim,
                  TableData "Gen. Journal Line" = rim;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Payment Journal Line"; "Payment Journal Line")
        {
            DataItemTableView = sorting("Bank Account", "Beneficiary Bank Account No.", Status, "Account Type", "Account No.", "Currency Code", "Posting Date");

            trigger OnAfterGetRecord()
            var
                NewGroupLoc: Boolean;
            begin
                // Mark record for status modification after writing the data
                Mark(true);

                if "Account Type" = "Account Type"::Customer then begin
                    CustomerAmt[1] += Amount;
                    CustomerAmt[2] += "Amount (LCY)"
                end else begin
                    VendorAmt[1] += Amount;
                    VendorAmt[2] += "Amount (LCY)";
                end;

                NewGroupLoc := CheckNewGroup();
                if NewGroupLoc then begin
                    AppliesToID := CopyStr(Format("Ledger Entry No.") + '/' + "Bank Account", 1, MaxStrLen("Applies-to ID"));
                    if CustomerAmt[1] + VendorAmt[1] > 0 then
                        WriteDataRecord("Account Type");
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Status, Status::Created);

                // Check records for posting
                if Count = 0 then
                    Error(Text009);
            end;
        }
        dataitem(Docket; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                if CustomerTotalAmount[2] > 0 then
                    WriteTrailerRecord("Payment Journal Line"."Account Type"::Customer);
                if VendorTotalAmount[2] > 0 then
                    WriteTrailerRecord("Payment Journal Line"."Account Type"::Vendor);
            end;
        }
        dataitem(Posting; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnPreDataItem()
            begin
                if CustomerTotalAmount[1] + VendorTotalAmount[1] > 0 then begin
                    GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");

                    GenJnlLine.Reset();
                    GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
                    GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

                    LastGenJnlLine.Copy(GenJnlLine);
                    if LastGenJnlLine.FindLast() then;

                    PaymJnlLine.Copy("Payment Journal Line");
                    PaymJnlLine.SetCurrentKey(
                      "Bank Account", "Beneficiary Bank Account No.", Status, "Account Type", "Account No.", "Currency Code", "Posting Date");
                    PaymJnlLine.SetRange(Status, PaymJnlLine.Status::Processed);
                    PaymJnlLine.SetRange("Account Type");
                    if PaymJnlLine.FindSet() then begin
                        AppliesToID := '';
                        DocumentNo := NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series", PaymJnlLine."Posting Date");
                        repeat
                            SetGenJnlLine(PaymJnlLine);
                        until PaymJnlLine.Next() = 0;
                        PaymJnlLine.ModifyAll(Status, PaymJnlLine.Status::Posted);
                    end;
                    if TempPaymJnlLine.FindSet() then
                        repeat
                            SetGenJnlLine(TempPaymJnlLine);
                        until TempPaymJnlLine.Next() = 0;

                    PaymJnlBatch.Get("Payment Journal Line"."Journal Template Name", "Payment Journal Line"."Journal Batch Name");
                    PJBatchName := IncStr(PaymJnlBatch.Name);
                    if PJBatchName <> '' then begin
                        PaymJnlBatch.Status := PaymJnlBatch.Status::Processed;

                        PaymJnlBatch.Modify(true);
                        PaymJnlBatch.Status := PaymJnlBatch.Status::" ";
                        PaymJnlBatch.Name := PJBatchName;
                        if PaymJnlBatch.Insert(true) then;
                    end;

                    if PJBatchName <> '' then begin
                        PaymJnlLine.Reset();
                        PaymJnlLine.SetRange("Journal Template Name", "Payment Journal Line"."Journal Template Name");
                        PaymJnlLine.SetRange("Journal Batch Name", PJBatchName);
                        if PaymJnlLine.FindLast() then
                            LineNo := PaymJnlLine."Line No."
                        else
                            LineNo := 0;

                        // Rename
                        PaymJnlLine.Reset();
                        PaymJnlLine.SetRange("Journal Template Name", "Payment Journal Line"."Journal Template Name");
                        PaymJnlLine.SetRange("Journal Batch Name", "Payment Journal Line"."Journal Batch Name");
                        PaymJnlLine.SetFilter("Separate Line", "Payment Journal Line".GetFilter("Separate Line"));
                        PaymJnlLine.SetFilter(Status, '<%1', PaymJnlLine.Status::Processed);
                        if PaymJnlLine.FindSet() then
                            repeat
                                LineNo := LineNo + 10000;
                                PaymJnlLine.Rename(PaymJnlLine."Journal Template Name", PJBatchName, LineNo);
                            until not PaymJnlLine.FindFirst();
                    end;

                    // Post
                    if AutomaticPosting then
                        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJnlLine);
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ClearAll();
        GLSetup.Get();
        EBSetup.Get();
    end;

    trigger OnPreReport()
    begin
        PostPaymentRecord := EBSetup."Summarize Gen. Jnl. Lines";

        SelectedDim.SetRange("User ID", UserId);
        SelectedDim.SetRange("Object Type", 3);
        SelectedDim.SetRange("Object ID", ReportID);
        IncludeDim := SelectedDim.FindFirst() and EBSetup."Summarize Gen. Jnl. Lines";
        // check general journal
        GenJnlBatch.Reset();
        if not GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") then
            Error(Text001, GenJnlLine.FieldCaption("Journal Batch Name"));

        if not (GenJnlBatch."Bal. Account Type" = GenJnlBatch."Bal. Account Type"::"G/L Account") then
            Error(Text002, GenJnlBatch.FieldCaption("Bal. Account Type"), GenJnlBatch.Name);

        if GenJnlBatch."Bal. Account No." = '' then
            Error(Text003, GenJnlBatch.FieldCaption("Bal. Account No."), GenJnlBatch.Name);

        if not GLAcc.Get(GenJnlBatch."Bal. Account No.") then
            Error(Text004, GenJnlBatch."Bal. Account No.");

        if not (GLAcc."Account Type" = GLAcc."Account Type"::Posting) then
            Error(Text005, GLAcc.FieldCaption("Account Type"), GLAcc."No.");

        GenJnlBatch.TestField("No. Series");

        // currency for balancing amount
        LocalCurrency.InitRoundingPrecision()
    end;

    var
        Text001: Label 'The %1 for posting is not specified.';
        Text002: Label '%1 in %2 must be G/L Account.';
        Text003: Label '%1 in %2 is not a valid G/L Account No.';
        Text004: Label '%1 in Journal Template is not a G/L Account No.';
        Text005: Label '%1 in G/L Account %2 must be %3.';
        Text009: Label 'There are no payment records in the selection.';
        Text014: Label 'Payment %1';
        Text016: Label 'The combination of invoices and credit memos for %1 %2 has caused an attempt to write a negative amount to the payment file. The format of the file does not allow this.', Comment = 'Parameter 1 - account type (,Customer,Vendor), 2 - account number.';
        GLSetup: Record "General Ledger Setup";
        EBSetup: Record "Electronic Banking Setup";
        GLAcc: Record "G/L Account";
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        LastGenJnlLine: Record "Gen. Journal Line";
        SelectedDim: Record "Selected Dimension";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymJnlLine: Record "Payment Journal Line";
        TempPaymJnlLine: Record "Payment Journal Line" temporary;
        LocalCurrency: Record Currency;
        DimensionSetEntry: Record "Dimension Set Entry";
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        BalancingPostingDate: Date;
        PJBatchName: Code[10];
        DocumentNo: Code[20];
        AppliesToID: Code[50];
        RemitteeName: Text[50];
        LineNo: Integer;
        EntryNo: Integer;
        ReportID: Integer;
        CustomerAmt: array[2] of Decimal;
        CustomerTotalAmount: array[2] of Decimal;
        VendorAmt: array[2] of Decimal;
        VendorTotalAmount: array[2] of Decimal;
        AutomaticPosting: Boolean;
        PostPaymentRecord: Boolean;
        IncludeDim: Boolean;

    local procedure WriteDataRecord(AccountType: Option)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        LocalAmt: Decimal;
        LocalAmtLCY: Decimal;
    begin
        if CustomerAmt[1] + VendorAmt[1] > 0 then begin
            if AccountType = PaymJnlLine."Account Type"::Customer then begin
                LocalAmt := CustomerAmt[1];
                LocalAmtLCY := CustomerAmt[2];
            end else begin
                LocalAmt := VendorAmt[1];
                LocalAmtLCY := VendorAmt[2];
            end;
            // Totals for balancing amount in LCY
            if PostPaymentRecord then
                LocalAmtLCY := Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      "Payment Journal Line"."Posting Date", "Payment Journal Line"."Currency Code",
                      LocalAmt, "Payment Journal Line"."Currency Factor"),
                    LocalCurrency."Amount Rounding Precision");
            if AccountType = PaymJnlLine."Account Type"::Customer then begin
                CustomerTotalAmount[1] += LocalAmt;
                CustomerTotalAmount[2] += LocalAmtLCY;
            end else begin
                VendorTotalAmount[1] += LocalAmt;
                VendorTotalAmount[2] += LocalAmtLCY;
            end;

            // Modify Status
            PaymJnlLine.Copy("Payment Journal Line");
            PaymJnlLine.MarkedOnly(true);

            // Add applies to ID for each payment
            if PostPaymentRecord then begin
                PaymJnlLine.SetRange("Partial Payment", false);
                if not IncludeDim then
                    PaymJnlLine.ModifyAll("Applies-to ID", AppliesToID, true)
                else
                    if PaymJnlLine.FindSet() then
                        repeat
                            TempDimBuf.Reset();
                            TempDimBuf.DeleteAll();
                            if SelectedDim.FindSet() then
                                repeat
                                    if DimensionSetEntry.Get(
                                         PaymJnlLine."Dimension Set ID", SelectedDim."Dimension Code")
                                    then begin
                                        TempDimBuf."Table ID" := DATABASE::"Payment Journal Line";
                                        TempDimBuf."Dimension Code" := DimensionSetEntry."Dimension Code";
                                        TempDimBuf."Dimension Value Code" := DimensionSetEntry."Dimension Value Code";
                                        TempDimBuf.Insert();
                                    end;
                                until SelectedDim.Next() = 0;
                            EntryNo := DimBufMgt.FindDimensions(TempDimBuf);
                            if EntryNo = 0 then
                                EntryNo := DimBufMgt.InsertDimensions(TempDimBuf);
                            PaymJnlLine."Applies-to ID" := CopyStr(Format(EntryNo) + '/' + AppliesToID, 1, MaxStrLen(PaymJnlLine."Applies-to ID"));
                            PaymJnlLine.Modify(true);
                        until PaymJnlLine.Next() = 0;

                PaymJnlLine.SetRange("Partial Payment");
            end;
            // Order of MODIFYALL is important
            PaymJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Account Type", "Account No.");
            PaymJnlLine.ModifyAll(PaymJnlLine.Status, PaymJnlLine.Status::Processed, true);
            PaymJnlLine.ModifyAll(PaymJnlLine.Processing, true, true);
        end;

        // reset for next iteration
        "Payment Journal Line".ClearMarks();

        if LocalAmt <= 0 then
            Error(Text016, "Payment Journal Line"."Account Type", "Payment Journal Line"."Account No.");

        Clear(CustomerAmt);
        Clear(VendorAmt);
    end;

    local procedure WriteTrailerRecord(AccountType: Option)
    begin
        TempPaymJnlLine := "Payment Journal Line";
        TempPaymJnlLine."Account Type" := GenJnlBatch."Bal. Account Type".AsInteger();
        TempPaymJnlLine."Account No." := GenJnlBatch."Bal. Account No.";
        TempPaymJnlLine."Currency Code" := '';
        TempPaymJnlLine."Currency Factor" := 0;
        if AccountType = "Payment Journal Line"."Account Type"::Customer then begin
            TempPaymJnlLine."Line No." := GetCustBalLineNo();
            TempPaymJnlLine.Amount := -CustomerTotalAmount[2]
        end else begin
            TempPaymJnlLine."Line No." := GetVendBalLineNo();
            TempPaymJnlLine.Amount := -VendorTotalAmount[2];
        end;
        if not TempPaymJnlLine."Separate Line" then
            TempPaymJnlLine."Payment Message" := '';
        TempPaymJnlLine."Applies-to Doc. Type" := TempPaymJnlLine."Applies-to Doc. Type"::" ";
        TempPaymJnlLine."Applies-to Doc. No." := '';
        TempPaymJnlLine."Applies-to ID" := '';
        if BalancingPostingDate <> 0D then
            TempPaymJnlLine."Posting Date" := BalancingPostingDate;
        TempPaymJnlLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetGenJnlLine(PaymentJnlLine: Record "Payment Journal Line")
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        PaymJnlManagement.ModifyPmtDiscDueDate(PaymentJnlLine);

        if PostPaymentRecord and
           not PaymentJnlLine."Partial Payment" and
           not PaymentJnlLine."Separate Line"
        then
            PaymJnlManagement.SetApplID(PaymentJnlLine);

        if PostPaymentRecord and
            not PaymentJnlLine."Partial Payment" and
            not PaymentJnlLine."Separate Line" and
            (AppliesToID = PaymentJnlLine."Applies-to ID") and
            (PaymentJnlLine."Account Type" in [PaymentJnlLine."Account Type"::Customer, PaymentJnlLine."Account Type"::Vendor])
        then begin
            GenJnlLine := LastGenJnlLine;
            GenJnlLine.Find();
            // add amounts
            GenJnlLine.Validate(Amount, GenJnlLine.Amount + PaymentJnlLine.Amount);
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::" ";
            GenJnlLine."Applies-to Doc. No." := '';
            GenJnlLine.Validate("Applies-to ID", AppliesToID);
            GenJnlLine.Modify();
        end else begin
            Clear(GenJnlLine);
            GenJnlLine.Init();
            case PaymentJnlLine."Account Type" of
                PaymentJnlLine."Account Type"::Customer:
                    begin
                        Cust.Get(PaymentJnlLine."Account No.");
                        RemitteeName := CopyStr(Cust.Name, 1, MaxStrLen(RemitteeName));
                        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                        GenJnlLine."Posting Group" := Cust."Customer Posting Group";
                        GenJnlLine."Salespers./Purch. Code" := Cust."Salesperson Code";
                        GenJnlLine."Payment Terms Code" := Cust."Payment Terms Code";
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
                    end;
                PaymentJnlLine."Account Type"::Vendor:
                    begin
                        Vend.Get(PaymentJnlLine."Account No.");
                        RemitteeName := CopyStr(Vend.Name, 1, MaxStrLen(RemitteeName));
                        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
                        GenJnlLine."Posting Group" := Vend."Vendor Posting Group";
                        GenJnlLine."Salespers./Purch. Code" := Vend."Purchaser Code";
                        GenJnlLine."Payment Terms Code" := Vend."Payment Terms Code";
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                    end;
                else begin
                    Clear(RemitteeName);
                    if PaymentJnlLine."Line No." = GetCustBalLineNo() then
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund
                    else
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                end;
            end;
            GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
            GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
            if (PaymentJnlLine."Line No." = GetCustBalLineNo()) and (PaymentJnlLine."Account Type" = 0) then begin
                GenJournalLine.Copy(LastGenJnlLine);
                GenJournalLine.SetRange("Account Type", GenJnlLine."Account Type"::Customer);
                GenJournalLine.FindLast();
                GenJnlLine."Line No." := GenJournalLine."Line No." + 1;
            end else
                GenJnlLine."Line No." := LastGenJnlLine."Line No." + 10000;
            // keep track of break on applies-to ID
            AppliesToID := PaymentJnlLine."Applies-to ID";

            GenJnlLine."Document No." := DocumentNo;
            GenJnlLine."Posting Date" := PaymentJnlLine."Posting Date";
            GenJnlLine."Document Date" := PaymentJnlLine."Posting Date";

            GenJnlLine."Account Type" := "Gen. Journal Account Type".FromInteger(PaymentJnlLine."Account Type");
            if PaymentJnlLine."Account Type" = 0 then
                GenJnlLine.Validate("Account No.", PaymentJnlLine."Account No.")
            else begin
                GenJnlLine."Account No." := PaymentJnlLine."Account No.";
                GenJnlLine."Bill-to/Pay-to No." := PaymJnlLine."Account No.";
            end;
            if PostPaymentRecord and
               not PaymentJnlLine."Partial Payment" and
               not PaymentJnlLine."Separate Line" and
               (PaymentJnlLine."Applies-to Doc. Type" <> PaymentJnlLine."Applies-to Doc. Type"::"Credit Memo")
            then
                GenJnlLine."Applies-to ID" := AppliesToID
            else begin
                GenJnlLine."Applies-to Doc. Type" := PaymentJnlLine."Applies-to Doc. Type";
                GenJnlLine."Applies-to Doc. No." := PaymentJnlLine."Applies-to Doc. No.";
            end;

            GenJnlLine."Currency Code" := PaymentJnlLine."Currency Code";
            GenJnlLine."Currency Factor" := PaymentJnlLine."Currency Factor";
            GenJnlLine.Validate(Amount, PaymentJnlLine.Amount);

            if PostPaymentRecord and
               not PaymentJnlLine."Partial Payment" and
               not PaymentJnlLine."Separate Line"
            then
                GenJnlLine.Description :=
                  CopyStr(StrSubstNo(Text014, RemitteeName), 1, MaxStrLen(GenJnlLine.Description))
            else
                if PaymentJnlLine."Payment Message" <> '' then
                    GenJnlLine.Description := PaymentJnlLine."Payment Message";

            GenJnlLine."Reason Code" := PaymentJnlLine."Reason Code";
            GenJnlLine."Source Code" := PaymentJnlLine."Source Code";
            GenJnlLine."Source No." := PaymentJnlLine."Account No.";
            UpdateDimSetID(GenJnlLine."Dimension Set ID", PaymentJnlLine);
            GenJnlLine.Validate("Dimension Set ID");
            GenJnlLine."Message to Recipient" := CopyStr(PaymentJnlLine."Payment Message", 1, MaxStrLen(GenJnlLine."Message to Recipient"));
            GenJnlLine."Exported to Payment File" := true;
            OnBeforeGenJnlLineInsert(GenJnlLine, PaymentJnlLine);
            GenJnlLine.Insert();

            if PaymentJnlLine."Line No." = GetCustBalLineNo() then
                GenJnlLine."Line No." := LastGenJnlLine."Line No." + 10000;

            LastGenJnlLine := GenJnlLine;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckNewGroup(): Boolean
    var
        PmtJnlLineLoc: Record "Payment Journal Line";
        NewGroupLoc: Boolean;
    begin
        NewGroupLoc := false;
        PmtJnlLineLoc.Copy("Payment Journal Line");
        if PmtJnlLineLoc.Next() = 1 then begin
            if (PmtJnlLineLoc."Account No." <> "Payment Journal Line"."Account No.") or
               (PmtJnlLineLoc."Account Type" <> "Payment Journal Line"."Account Type") or
               (PmtJnlLineLoc."Currency Code" <> "Payment Journal Line"."Currency Code") or
               (PmtJnlLineLoc."Posting Date" <> "Payment Journal Line"."Posting Date")
            then
                NewGroupLoc := true;
        end else
            NewGroupLoc := true;
        exit(NewGroupLoc);
    end;

    procedure SetParameters(GenJnlLineParam: Record "Gen. Journal Line"; AutomaticPostingParam: Boolean; ReportIDParam: Integer; BalancingPostingDateParam: Date)
    begin
        GenJnlLine := GenJnlLineParam;
        AutomaticPosting := AutomaticPostingParam;
        ReportID := ReportIDParam;
        BalancingPostingDate := BalancingPostingDateParam;
    end;

    local procedure UpdateDimSetID(var DimSetID: Integer; PaymentJnlLine: Record "Payment Journal Line")
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
    begin
        if PaymentJnlLine."Account Type" in [PaymentJnlLine."Account Type"::Customer, PaymentJnlLine."Account Type"::Vendor] then begin
            SelectedDim.SetRange("User ID", UserId);
            SelectedDim.SetRange("Object Type", 3);
            SelectedDim.SetRange("Object ID", ReportID);
            if SelectedDim.FindSet() then
                repeat
                    if DimensionSetEntry.Get(PaymJnlLine."Dimension Set ID", SelectedDim."Dimension Code") then begin
                        TempDimBuf."Dimension Code" := DimensionSetEntry."Dimension Code";
                        TempDimBuf."Dimension Value Code" := DimensionSetEntry."Dimension Value Code";
                        TempDimBuf.Insert();
                    end;
                until SelectedDim.Next() = 0;
            DimSetID := DimMgt.CreateDimSetIDFromDimBuf(TempDimBuf);
        end;
    end;

    local procedure GetCustBalLineNo(): Integer
    begin
        exit(1);
    end;

    local procedure GetVendBalLineNo(): Integer
    begin
        exit(2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; PaymentJournalLine: Record "Payment Journal Line")
    begin
    end;
}

