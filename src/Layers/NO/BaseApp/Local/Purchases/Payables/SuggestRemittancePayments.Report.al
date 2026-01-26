// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;

report 15000001 "Suggest Remittance Payments"
{
    Caption = 'Suggest Remittance Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting(Remittance, "No.") where(Remittance = const(true));
            RequestFilterFields = "Remittance Account Code", "No.", "Payment Method Code";

            trigger OnAfterGetRecord()
            begin
                if StopPayments then
                    CurrReport.Break();
                Window.Update(1, "No.");
                RemAccount.Get("Remittance Account Code");
                GetVendLedgEntries(false, false);
                CheckAmounts(false);
            end;

            trigger OnPostDataItem()
            begin
                if UsePriority and not StopPayments then begin
                    Reset();
                    CopyFilters(Vend2);
                    SetCurrentKey(Priority);
                    SetRange(Priority, 0);
                    if Find('-') then
                        repeat
                            Window.Update(1, "No.");
                            GetVendLedgEntries(true, false);
                            GetVendLedgEntries(false, false);
                            CheckAmounts(false);
                        until (Next() = 0) or StopPayments;
                end;

                if UsePaymentDisc and not StopPayments then begin
                    Reset();
                    CopyFilters(Vend2);
                    Window.Open(Text007);
                    if Find('-') then
                        repeat
                            Window.Update(1, "No.");
                            PayableVendLedgEntry.SetRange("Vendor No.", "No.");
                            GetVendLedgEntries(true, true);
                            GetVendLedgEntries(false, true);
                            CheckAmounts(true);
                        until (Next() = 0) or StopPayments;
                end;

                GenJnlLine.LockTable();
                GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                if GenJnlLine.FindLast() then begin
                    LastLineNo := GenJnlLine."Line No.";
                    GenJnlLine.Init();
                end;

                Window.Open(Text008);

                PayableVendLedgEntry.Reset();
                PayableVendLedgEntry.SetRange(Priority, 1, 2147483647);
                MakeGenJnlLines();
                PayableVendLedgEntry.Reset();
                PayableVendLedgEntry.SetRange(Priority, 0);
                MakeGenJnlLines();
                PayableVendLedgEntry.Reset();
                PayableVendLedgEntry.DeleteAll();

                Window.Close();
                ShowMessage(MessageText);
            end;

            trigger OnPreDataItem()
            begin
                if LastDueDateToPayReq = 0D then
                    Error(Text000);
                if (PostingDate = 0D) and not ReplacePostingDateWithDueDate then
                    Error(Text001);

                BankPmtType := GenJnlLine."Bank Payment Type";
                BalAccType := GenJnlLine."Bal. Account Type";
                BalAccNo := GenJnlLine."Bal. Account No.";
                GenJnlLineInserted := false;
                SeveralCurrencies := false;
                MessageText := '';

                if BankPmtType = BankPmtType::"Manual Check" then
                    Error(Text017, SelectStr(BankPmtType.AsInteger() + 1, Text023));

                if ReplacePostingDateWithDueDate then
                    PostingDate := 0D;

                if UsePaymentDisc and (LastDueDateToPayReq < WorkDate()) then
                    if not Confirm(Text003, false, WorkDate()) then
                        Error(Text005);

                Vend2.CopyFilters(Vendor);

                OriginalAmtAvailable := AmountAvailable;
                if UsePriority then begin
                    SetCurrentKey(Priority);
                    SetRange(Priority, 1, 2147483647);
                    UsePriority := true;
                end;
                Window.Open(Text006);

                NextEntryNo := 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(LastPaymentDate; LastDueDateToPayReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Payment Date';
                        ToolTip = 'Specifies the last payment date. This will include all open entries that have a due date until the last payment date.';
                    }
                    field(UsePaymentDisc; UsePaymentDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find Payment Discounts';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to include entries where a payment discount is available.';
                    }
                    field(UsePriority; UsePriority)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Vendor Priority';
                        ToolTip = 'Specifies if you want to use vendor priority when entries are searched. This is helpful if you only have a limited amount available for payments to vendors.';

                        trigger OnValidate()
                        begin
                            if not UsePriority and (AmountAvailable <> 0) then
                                Error(Text011);
                        end;
                    }
                    field(AmountAvailable; AmountAvailable)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Available Amount (LCY)';
                        ToolTip = 'Specifies a maximum amount (in LCY) that is available for payments. The batch job will then create a payment suggestion on the basis of this amount and the Use Vendor Priority check box. It will only include vendor entries that can be paid fully.';

                        trigger OnValidate()
                        begin
                            AmountAvailableOnAfterValidate();
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the payments. If the Find Payment Discounts field is selected, the payment discount date will be used as the posting date.';

                        trigger OnValidate()
                        begin
                            ValidatePostingDate();
                        end;
                    }
                    field(ReplacePostingDateWithDueDate; ReplacePostingDateWithDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Posting Date with Due Date';
                        ToolTip = 'Specifies if you want to use the due date instead of the posting date for the payments.';
                    }
                    field(CheckLedgEntryType; CheckLedgEntryType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Document Type';
                        OptionCaption = 'All,Invoice/Credit memo';
                        ToolTip = 'Specifies which document types should be tested for payments. Select All to test all document types. Select Invoice/Credit memo to test only invoice and credit memo entries. Other document types, such as payments or unspecified entries will not be paid.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();
            ValidatePostingDate();
            OnAfterOpenPage(GenJnlLine, UsePaymentDisc, PostingDate);
        end;
    }

    labels
    {
    }

    var
        Text000: Label 'Please enter the last payment date.';
        Text001: Label 'Please enter the posting date.';
        Text003: Label 'The payment date is earlier than %1.\\Do you want to continue?';
        Text005: Label 'The batch job was interrupted.';
        Text006: Label 'Processing vendors     #1##########';
        Text007: Label 'Processing vendors for payment discounts #1##########';
        Text008: Label 'Inserting payment journal lines #1##########';
        Text011: Label 'Use Vendor Priority must be activated when the value in the Amount Available field is not 0.';
        Text016: Label ' is already applied to %1 %2 for vendor %3.', Comment = 'Parameter 1 - document type, 2 - document number, 3 - vendor number.';
        Text017: Label 'When Bank Payment Type = %1 and you have not selected in the Summarize per Vendor field,\then you must select the New Doc. No. per Line field.';
        Text019: Label 'You have only created suggested vendor payment lines for the Currency Code %1. There are, however, other open vendor ledger entries in currencies other than %2.';
        Text021: Label 'You have only created suggested vendor payment lines for the Currency Code %1. There are no other open vendor ledger entries in other currencies.';
        Text022: Label 'You have created suggested vendor payment lines for all currencies.';
        Vend2: Record Vendor;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        PayableVendLedgEntry: Record "Payable Vendor Ledger Entry" temporary;
        TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary;
        OldTempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary;
        RemAccount: Record "Remittance Account";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        Vend3: Record Vendor;
        DimMgt: Codeunit DimensionManagement;
        RemTools: Codeunit "Remittance Tools";
        Window: Dialog;
        UsePaymentDisc: Boolean;
        PostingDate: Date;
        LastDueDateToPayReq: Date;
        NextDocNo: Code[20];
        AmountAvailable: Decimal;
        OriginalAmtAvailable: Decimal;
        UsePriority: Boolean;
        LastLineNo: Integer;
        NextEntryNo: Integer;
        StopPayments: Boolean;
        BankPmtType: Enum "Bank Payment Type";
        BalAccType: Enum "Gen. Journal Account Type";
        BalAccNo: Code[20];
        MessageText: Text[250];
        GenJnlLineInserted: Boolean;
        SeveralCurrencies: Boolean;
        Text023: Label ' ,Computer Check,Manual Check';
        StartText: Text[30];
        CheckLedgEntryType: Option All,"Invoice/Credit Memo";
        Text15000000: Label 'Refund';
        Text15000001: Label 'Payment';
        Text15000002: Label '%1 of %2 %3 (%4)', Comment = 'Parameter 1 - Refund or Payment, 2 - document type, 3 and 4 - document numbers.';
        ReplacePostingDateWithDueDate: Boolean;

    protected var
        VendLedgEntry: Record "Vendor Ledger Entry";

    [Scope('OnPrem')]
    procedure SetGenJnlLine(NewGenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine := NewGenJnlLine;
    end;

    local procedure ValidatePostingDate()
    var
        NoSeries: Codeunit "No. Series";
    begin
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        if GenJnlBatch."No. Series" = '' then
            NextDocNo := ''
        else
            NextDocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", PostingDate);
    end;

    [Scope('OnPrem')]
    procedure GetVendLedgEntries(Positive: Boolean; Future: Boolean)
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange(Positive, Positive);

        if CheckLedgEntryType = CheckLedgEntryType::"Invoice/Credit Memo" then
            VendLedgEntry.SetFilter(
              "Document Type", '%1|%2', VendLedgEntry."Document Type"::Invoice, VendLedgEntry."Document Type"::"Credit Memo");

        if Future then begin
            VendLedgEntry.SetRange("Due Date", LastDueDateToPayReq + 1, DMY2Date(31, 12, 9999));
            VendLedgEntry.SetRange("Pmt. Discount Date", PostingDate, LastDueDateToPayReq);
            VendLedgEntry.SetFilter("Remaining Pmt. Disc. Possible", '<>0');
        end else
            VendLedgEntry.SetRange("Due Date", 0D, LastDueDateToPayReq);
        VendLedgEntry.SetRange("On Hold", '');
        VendLedgEntry.SetFilter("Global Dimension 1 Code", Vendor.GetFilter("Global Dimension 1 Filter"));
        VendLedgEntry.SetFilter("Global Dimension 2 Code", Vendor.GetFilter("Global Dimension 2 Filter"));
        OnGetVendLedgEntriesOnAfterVendLedgEntrySetFilters(VendLedgEntry, Vendor);
        if VendLedgEntry.Find('-') then
            repeat
                SaveAmount();
            until VendLedgEntry.Next() = 0;
    end;

    local procedure SaveAmount()
    var
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        GenJnlLine.Validate("Posting Date", CalcPostingdate(VendLedgEntry));
        if VendLedgEntry.Positive then
            // Cr.Memo
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" "
        else
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
        GenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code");
        VendLedgEntry.CalcFields("Remaining Amount");

        if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(GenJnlLine, VendLedgEntry, 0, false) then
            GenJnlLine.Amount := -(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible")
        else
            GenJnlLine.Amount := -VendLedgEntry."Remaining Amount";
        GenJnlLine.Validate(Amount);

        if UsePriority then
            PayableVendLedgEntry.Priority := Vendor.Priority
        else
            PayableVendLedgEntry.Priority := 0;
        PayableVendLedgEntry."Vendor No." := VendLedgEntry."Vendor No.";
        PayableVendLedgEntry."Entry No." := NextEntryNo;
        PayableVendLedgEntry."Vendor Ledg. Entry No." := VendLedgEntry."Entry No.";
        PayableVendLedgEntry.Amount := GenJnlLine.Amount;
        PayableVendLedgEntry."Amount (LCY)" := GenJnlLine."Amount (LCY)";
        PayableVendLedgEntry.Positive := (PayableVendLedgEntry.Amount > 0);
        PayableVendLedgEntry.Future := (VendLedgEntry."Due Date" > LastDueDateToPayReq);
        PayableVendLedgEntry."Currency Code" := VendLedgEntry."Currency Code";
        PayableVendLedgEntry.Insert();
        NextEntryNo := NextEntryNo + 1;
    end;

    [Scope('OnPrem')]
    procedure CheckAmounts(Future: Boolean)
    var
        CurrencyBalance: Decimal;
        PrevCurrency: Code[10];
    begin
        PayableVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        PayableVendLedgEntry.SetRange(Future, Future);

        if PayableVendLedgEntry.Find('-') then begin
            PrevCurrency := PayableVendLedgEntry."Currency Code";
            repeat
                if PayableVendLedgEntry."Currency Code" <> PrevCurrency then begin
                    if CurrencyBalance < 0 then begin
                        PayableVendLedgEntry.SetRange("Currency Code", PrevCurrency);
                        PayableVendLedgEntry.DeleteAll();
                        PayableVendLedgEntry.SetRange("Currency Code");
                    end else
                        AmountAvailable := AmountAvailable - CurrencyBalance;
                    CurrencyBalance := 0;
                    PrevCurrency := PayableVendLedgEntry."Currency Code";
                end;
                if (OriginalAmtAvailable = 0) or
                   (AmountAvailable >= CurrencyBalance + PayableVendLedgEntry."Amount (LCY)")
                then
                    CurrencyBalance := CurrencyBalance + PayableVendLedgEntry."Amount (LCY)"
                else
                    PayableVendLedgEntry.Delete();
            until PayableVendLedgEntry.Next() = 0;

            if (CurrencyBalance < 0) and
               ((not UsePaymentDisc) or (UsePaymentDisc and Future))
            then begin
                PayableVendLedgEntry.SetRange("Currency Code", PrevCurrency);
                PayableVendLedgEntry.DeleteAll();
                PayableVendLedgEntry.SetRange("Currency Code");
            end else
                if OriginalAmtAvailable > 0 then
                    AmountAvailable := AmountAvailable - CurrencyBalance;
            if (OriginalAmtAvailable > 0) and (AmountAvailable <= 0) then
                StopPayments := true;
        end;
        PayableVendLedgEntry.Reset();
    end;

    local procedure MakeGenJnlLines()
    var
        GenJnlLine3: Record "Gen. Journal Line";
    begin
        TempVendorPaymentBuffer.Reset();
        TempVendorPaymentBuffer.DeleteAll();

        if BalAccType = BalAccType::"Bank Account" then begin
            CheckCurrencies(BalAccType, BalAccNo, PayableVendLedgEntry);
            SetBankAccCurrencyFilter(BalAccType, BalAccNo, PayableVendLedgEntry);
        end;

        if PayableVendLedgEntry.Find('-') then
            repeat
                PayableVendLedgEntry.SetRange("Vendor No.", PayableVendLedgEntry."Vendor No.");
                PayableVendLedgEntry.Find('-');
                repeat
                    VendLedgEntry.Get(PayableVendLedgEntry."Vendor Ledg. Entry No.");
                    TempVendorPaymentBuffer."Vendor No." := VendLedgEntry."Vendor No.";
                    TempVendorPaymentBuffer."Currency Code" := VendLedgEntry."Currency Code";
                    TempVendorPaymentBuffer."Dimension Entry No." := 0;
                    TempVendorPaymentBuffer."Global Dimension 1 Code" := '';
                    TempVendorPaymentBuffer."Global Dimension 2 Code" := '';

                    GenJnlLine3.Reset();
                    GenJnlLine3.SetCurrentKey(
                      "Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
                    GenJnlLine3.SetRange("Account Type", GenJnlLine3."Account Type"::Vendor);
                    GenJnlLine3.SetRange("Account No.", VendLedgEntry."Vendor No.");
                    GenJnlLine3.SetRange("Applies-to Doc. Type", VendLedgEntry."Document Type");
                    GenJnlLine3.SetRange("Applies-to Doc. No.", VendLedgEntry."Document No.");
                    if GenJnlLine3.FindFirst() then
                        GenJnlLine3.FieldError(
                          "Applies-to Doc. No.",
                          StrSubstNo(
                            Text016,
                            VendLedgEntry."Document Type", VendLedgEntry."Document No.",
                            VendLedgEntry."Vendor No."));

                    TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. Type" := VendLedgEntry."Document Type";
                    TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. No." := VendLedgEntry."Document No.";
                    TempVendorPaymentBuffer."Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                    TempVendorPaymentBuffer."Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                    TempVendorPaymentBuffer."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                    TempVendorPaymentBuffer."Vendor Ledg. Entry No." := VendLedgEntry."Entry No.";
                    TempVendorPaymentBuffer.Amount := PayableVendLedgEntry.Amount;
                    Window.Update(1, VendLedgEntry."Vendor No.");
                    TempVendorPaymentBuffer.Insert();
                until PayableVendLedgEntry.Next() = 0;
                PayableVendLedgEntry.DeleteAll();
                PayableVendLedgEntry.SetRange("Vendor No.");
            until not PayableVendLedgEntry.Find('-');

        Clear(OldTempVendorPaymentBuffer);
        TempVendorPaymentBuffer.SetCurrentKey("Document No.");
        if TempVendorPaymentBuffer.Find('-') then
            repeat
                GenJnlLine.Init();
                Window.Update(1, TempVendorPaymentBuffer."Vendor No.");
                LastLineNo := LastLineNo + 10000;
                GenJnlLine."Line No." := LastLineNo;

                VendLedgEntry2.Get(TempVendorPaymentBuffer."Vendor Ledg. Entry No.");
                GenJnlLine.Validate("Posting Date", CalcPostingdate(VendLedgEntry2));
                if VendLedgEntry2.Positive then begin
                    // Cr.Memo
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                    StartText := Text15000000;
                end else begin
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                    StartText := Text15000001;
                end;

                GenJnlLine."Posting No. Series" := GenJnlBatch."Posting No. Series";
                if (TempVendorPaymentBuffer."Vendor No." = OldTempVendorPaymentBuffer."Vendor No.") and
                   (TempVendorPaymentBuffer."Currency Code" = OldTempVendorPaymentBuffer."Currency Code")
                then
                    GenJnlLine."Document No." := OldTempVendorPaymentBuffer."Document No."
                else begin
                    GenJnlLine."Document No." := NextDocNo;
                    NextDocNo := IncStr(NextDocNo);
                    OldTempVendorPaymentBuffer := TempVendorPaymentBuffer;
                    OldTempVendorPaymentBuffer."Document No." := GenJnlLine."Document No.";
                end;
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                GenJnlLine.Validate("Account No.", TempVendorPaymentBuffer."Vendor No.");
                GenJnlLine."Bal. Account Type" := BalAccType;
                GenJnlLine.Validate("Bal. Account No.", BalAccNo);
                GenJnlLine.Validate("Currency Code", TempVendorPaymentBuffer."Currency Code");
                GenJnlLine."Bank Payment Type" := BankPmtType;

                VendLedgEntry2.Get(TempVendorPaymentBuffer."Vendor Ledg. Entry No.");
                // Find VendLedg.Entry. Need "External Document No."
                GenJnlLine.Description :=
                  CopyStr(
                    StrSubstNo(
                      Text15000002,
                      StartText, VendLedgEntry2."Document Type", VendLedgEntry2."Document No.",
                      VendLedgEntry2."External Document No."), 1, MaxStrLen(GenJnlLine.Description));
                Vend3.Get(VendLedgEntry2."Vendor No.");
                GenJnlLine.Validate("Remittance Account Code", Vend3."Remittance Account Code");
                GenJnlLine.Validate("Payment Due Date", VendLedgEntry2."Due Date");
                GenJnlLine.Validate("External Document No.", VendLedgEntry2."External Document No.");

                GenJnlLine."Shortcut Dimension 1 Code" := TempVendorPaymentBuffer."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := TempVendorPaymentBuffer."Global Dimension 2 Code";
                GenJnlLine."Source Code" := GenJnlTemplate."Source Code";
                GenJnlLine."Reason Code" := GenJnlBatch."Reason Code";
                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                GenJnlLine."Bal. Account No." := '';
                GenJnlLine.Validate(Amount, TempVendorPaymentBuffer.Amount);
                GenJnlLine."Applies-to Doc. Type" := TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. Type";
                GenJnlLine."Applies-to Doc. No." := TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. No.";
                RemTools.CreateJournalData(GenJnlLine, VendLedgEntry2);
                GenJnlLine."Payment Type Code Abroad" := VendLedgEntry2."Payment Type Code Abroad";
                GenJnlLine."Specification (Norges Bank)" := VendLedgEntry2."Specification (Norges Bank)";

                GenJnlLine."Dimension Set ID" := TempVendorPaymentBuffer."Dimension Set ID";
                UpdateDimensions(GenJnlLine);
                OnBeforeGenJnlLineInsertVendorPaymentBuffer(GenJnlLine, TempVendorPaymentBuffer);
                GenJnlLine.Insert();
                GenJnlLineInserted := true;
            until TempVendorPaymentBuffer.Next() = 0;
    end;

    local procedure SetBankAccCurrencyFilter(BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; var TmpPayableVendLedgEntry: Record "Payable Vendor Ledger Entry")
    var
        BankAcc: Record "Bank Account";
    begin
        if BalAccType = BalAccType::"Bank Account" then
            if BalAccNo <> '' then begin
                BankAcc.Get(BalAccNo);
                if BankAcc."Currency Code" <> '' then
                    TmpPayableVendLedgEntry.SetRange("Currency Code", BankAcc."Currency Code");
            end;
    end;

    local procedure ShowMessage(Text: Text[250])
    begin
        if (Text <> '') and GenJnlLineInserted then
            Message(Text);
    end;

    local procedure CheckCurrencies(BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; var TmpPayableVendLedgEntry: Record "Payable Vendor Ledger Entry")
    var
        BankAcc: Record "Bank Account";
        TmpPayableVendLedgEntry2: Record "Payable Vendor Ledger Entry" temporary;
    begin
        if BalAccType = BalAccType::"Bank Account" then
            if BalAccNo <> '' then begin
                BankAcc.Get(BalAccNo);
                if BankAcc."Currency Code" <> '' then begin
                    TmpPayableVendLedgEntry2.Reset();
                    TmpPayableVendLedgEntry2.DeleteAll();
                    if TmpPayableVendLedgEntry.Find('-') then
                        repeat
                            TmpPayableVendLedgEntry2 := TmpPayableVendLedgEntry;
                            TmpPayableVendLedgEntry2.Insert();
                        until TmpPayableVendLedgEntry.Next() = 0;

                    TmpPayableVendLedgEntry2.SetFilter("Currency Code", '<>%1', BankAcc."Currency Code");
                    SeveralCurrencies := SeveralCurrencies or TmpPayableVendLedgEntry2.FindFirst();

                    if SeveralCurrencies then
                        MessageText := StrSubstNo(Text019, BankAcc."Currency Code")
                    else
                        MessageText := StrSubstNo(Text021, BankAcc."Currency Code");
                end else
                    MessageText := Text022;
            end;
    end;

    local procedure CalcPostingdate(VendLedgEntry: Record "Vendor Ledger Entry"): Date
    var
        NewPostingDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        NewPostingDate := PostingDate;
        OnBeforeCalcPostingDate(
          VendLedgEntry, ReplacePostingDateWithDueDate, UsePaymentDisc, LastDueDateToPayReq, NewPostingDate, IsHandled);
        if IsHandled then
            exit(NewPostingDate);

        if ReplacePostingDateWithDueDate then begin
            if UsePaymentDisc and
               (VendLedgEntry."Pmt. Discount Date" <> 0D) and
               (VendLedgEntry."Pmt. Discount Date" <= LastDueDateToPayReq) and
               (VendLedgEntry."Remaining Pmt. Disc. Possible" <> 0)
            then
                exit(VendLedgEntry."Pmt. Discount Date");

            exit(VendLedgEntry."Due Date");
        end;

        exit(PostingDate);
    end;

    local procedure AmountAvailableOnAfterValidate()
    begin
        if AmountAvailable <> 0 then
            UsePriority := true;
    end;

    local procedure UpdateDimensions(var GenJnlLine: Record "Gen. Journal Line")
    var
        DimSetID: Integer;
        DimSetIDArr: array[10] of Integer;
    begin
        DimSetID := GenJnlLine."Dimension Set ID";
        GenJnlLine.CreateDimFromDefaultDim(GenJnlLine.FieldNo("Account No."));
        if DimSetID <> GenJnlLine."Dimension Set ID" then begin
            DimSetIDArr[1] := GenJnlLine."Dimension Set ID";
            DimSetIDArr[2] := DimSetID;
            GenJnlLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimSetIDArr, GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage(GenJournalLine: Record "Gen. Journal Line"; var UsePaymentDisc: Boolean; var PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPostingDate(VendorLedgerEntry: Record "Vendor Ledger Entry"; ReplacePostingDateWithDueDate: Boolean; UsePaymentDisc: Boolean; LastDueDateToPayReq: Date; var NewPostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsertVendorPaymentBuffer(var GenJournalLine: Record "Gen. Journal Line"; var TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendLedgEntriesOnAfterVendLedgEntrySetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; var Vendor: Record Vendor)
    begin
    end;
}

