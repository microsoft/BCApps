// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 10864 "Suggest Customer Payments"
{
    Caption = 'Suggest Customer Payments';
    Permissions = TableData "Cust. Ledger Entry" = rm;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Payment Method Code";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                GetCustLedgEntries(true, false);
                GetCustLedgEntries(false, false);
                CheckAmounts(false);
            end;

            trigger OnPostDataItem()
            begin
                if UsePaymentDisc then begin
                    Reset();
                    CopyFilters(Cust2);
                    Window.Open(Text007);
                    if Find('-') then
                        repeat
                            Window.Update(1, "No.");
                            PayableCustLedgEntry.SetRange("Vendor No.", "No.");
                            GetCustLedgEntries(true, true);
                            GetCustLedgEntries(false, true);
                            CheckAmounts(true);
                        until Next() = 0;
                end;

                GenPayLine.LockTable();
                GenPayLine.SetRange("No.", GenPayLine."No.");
                if GenPayLine.FindLast() then begin
                    LastLineNo := GenPayLine."Line No.";
                    GenPayLine.Init();
                end;

                Window.Open(Text008);

                PayableCustLedgEntry.Reset();
                PayableCustLedgEntry.SetRange(Priority, 1, 2147483647);
                MakeGenPayLines();
                PayableCustLedgEntry.Reset();
                PayableCustLedgEntry.SetRange(Priority, 0);
                MakeGenPayLines();
                PayableCustLedgEntry.Reset();
                PayableCustLedgEntry.DeleteAll();
                Window.Close();

                if GenPayLineInserted and (Customer.GetFilter("Partner Type") <> '') then begin
                    GenPayHead."Partner Type" := Customer."Partner Type";
                    GenPayHead.Modify();
                end;
                ShowMessage(MessageText);
            end;

            trigger OnPreDataItem()
            begin
                if LastDueDateToPayReq = 0D then
                    Error(Text000);
                if PostingDate = 0D then
                    Error(Text001);

                GenPayLineInserted := false;
                MessageText := '';

                if UsePaymentDisc and (LastDueDateToPayReq < WorkDate()) then
                    if not
                       Confirm(
                         Text003 +
                         Text004, false,
                         WorkDate())
                    then
                        Error(Text005);

                Cust2.CopyFilters(Customer);
                Window.Open(Text006);

                NextEntryNo := 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = false;

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
                        ToolTip = 'Specifies the latest payment date that can appear on the customer ledger entries to include in the batch job. ';
                    }
                    field(UsePaymentDisc; UsePaymentDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find Payment Discounts';
                        MultiLine = true;
                        ToolTip = 'Specifies whether to include customer ledger entries for which you can receive a payment discount.';
                    }
                    field(SummarizePer; SummarizePer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Summarize per';
                        OptionCaption = ' ,Customer,Due date';
                        ToolTip = 'Specifies how to summarize. Choose the Customer option for one summarized line per customer for open ledger entries. Choose the Due Date option for one summarized line per due date per customer for open ledger entries. Choose the empty option if you want each open customer ledger entry to result in an individual payment line.';
                    }
                    field(CurrencyFilter; CurrencyFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Currency Filter';
                        Editable = false;
                        TableRelation = Currency;
                        ToolTip = 'Specifies the currencies to include in the transfer. To see the available currencies, choose the Filter field.';
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

    var
        Text000: Label 'Please enter the last payment date.';
        Text001: Label 'Please enter the posting date.';
        Text003: Label 'The selected last due date is earlier than %1.\\';
        Text004: Label 'Do you still want to run the batch job?';
        Text005: Label 'The batch job was interrupted.';
        Text006: Label 'Processing customers     #1##########';
        Text007: Label 'Processing customers for payment discounts #1##########';
        Text008: Label 'Inserting payment journal lines #1##########';
        Text016: Label ' is already applied to %1 %2 for customer %3.';
        Cust2: Record Customer;
        GenPayHead: Record "Payment Header";
        GenPayLine: Record "Payment Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        PayableCustLedgEntry: Record "Payable Vendor Ledger Entry" temporary;
        TempPaymentPostBuffer: Record "Payment Post. Buffer" temporary;
        OldTempPaymentPostBuffer: Record "Payment Post. Buffer" temporary;
        PaymentClass: Record "Payment Class";
        Window: Dialog;
        UsePaymentDisc: Boolean;
        PostingDate: Date;
        LastDueDateToPayReq: Date;
        NextDocNo: Code[20];
        SummarizePer: Option " ",Customer,"Due date";
        LastLineNo: Integer;
        NextEntryNo: Integer;
        MessageText: Text[250];
        GenPayLineInserted: Boolean;
        CurrencyFilter: Code[10];

    [Scope('OnPrem')]
    procedure SetGenPayLine(NewGenPayLine: Record "Payment Header")
    begin
        GenPayHead := NewGenPayLine;
        GenPayLine."No." := NewGenPayLine."No.";
        PaymentClass.Get(GenPayHead."Payment Class");
        PostingDate := GenPayHead."Posting Date";
        CurrencyFilter := GenPayHead."Currency Code";
    end;

    [Scope('OnPrem')]
    procedure GetCustLedgEntries(Positive: Boolean; Future: Boolean)
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange(Positive, Positive);
        CustLedgEntry.SetRange("Currency Code", CurrencyFilter);
        CustLedgEntry.SetRange("Applies-to ID", '');
        if Future then begin
            CustLedgEntry.SetRange("Due Date", LastDueDateToPayReq + 1, 99991231D);
            CustLedgEntry.SetRange("Pmt. Discount Date", PostingDate, LastDueDateToPayReq);
            CustLedgEntry.SetFilter("Original Pmt. Disc. Possible", '<0');
        end else
            CustLedgEntry.SetRange("Due Date", 0D, LastDueDateToPayReq);
        CustLedgEntry.SetRange("On Hold", '');
        OnGetCustLedgEntriesOnAfterSetFilters(CustLedgEntry);

        if CustLedgEntry.FindSet() then
            repeat
                SaveAmount();
            until CustLedgEntry.Next() = 0;
    end;

    local procedure SaveAmount()
    begin
        GenPayLine."Account Type" := GenPayLine."Account Type"::Customer;
        GenPayLine.Validate("Account No.", CustLedgEntry."Customer No.");
        GenPayLine."Posting Date" := CustLedgEntry."Posting Date";
        GenPayLine."Currency Factor" := CustLedgEntry."Adjusted Currency Factor";
        if GenPayLine."Currency Factor" = 0 then
            GenPayLine."Currency Factor" := 1;
        GenPayLine.Validate("Currency Code", CustLedgEntry."Currency Code");
        CustLedgEntry.CalcFields("Remaining Amount");
        if ((CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo") and
            (CustLedgEntry."Remaining Pmt. Disc. Possible" <> 0) or
            (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice)) and
           (PostingDate <= CustLedgEntry."Pmt. Discount Date") and UsePaymentDisc
        then
            GenPayLine.Amount := -(CustLedgEntry."Remaining Amount" - CustLedgEntry."Original Pmt. Disc. Possible")
        else
            GenPayLine.Amount := -CustLedgEntry."Remaining Amount";
        GenPayLine.Validate(Amount);

        PayableCustLedgEntry."Vendor No." := CustLedgEntry."Customer No.";
        PayableCustLedgEntry."Entry No." := NextEntryNo;
        PayableCustLedgEntry."Vendor Ledg. Entry No." := CustLedgEntry."Entry No.";
        PayableCustLedgEntry.Amount := GenPayLine.Amount;
        PayableCustLedgEntry."Amount (LCY)" := GenPayLine."Amount (LCY)";
        PayableCustLedgEntry.Positive := (PayableCustLedgEntry.Amount > 0);
        PayableCustLedgEntry.Future := (CustLedgEntry."Due Date" > LastDueDateToPayReq);
        PayableCustLedgEntry."Currency Code" := CustLedgEntry."Currency Code";
        PayableCustLedgEntry."Due Date" := CustLedgEntry."Due Date";
        PayableCustLedgEntry.Insert();
        NextEntryNo := NextEntryNo + 1;
    end;

    [Scope('OnPrem')]
    procedure CheckAmounts(Future: Boolean)
    var
        CurrencyBalance: Decimal;
        PrevCurrency: Code[10];
    begin
        PayableCustLedgEntry.SetRange("Vendor No.", Customer."No.");
        PayableCustLedgEntry.SetRange(Future, Future);
        if PayableCustLedgEntry.Find('-') then begin
            PrevCurrency := PayableCustLedgEntry."Currency Code";
            repeat
                if PayableCustLedgEntry."Currency Code" <> PrevCurrency then begin
                    if CurrencyBalance < 0 then begin
                        PayableCustLedgEntry.SetRange("Currency Code", PrevCurrency);
                        PayableCustLedgEntry.DeleteAll();
                        PayableCustLedgEntry.SetRange("Currency Code");
                    end;
                    CurrencyBalance := 0;
                    PrevCurrency := PayableCustLedgEntry."Currency Code";
                end;
                CurrencyBalance := CurrencyBalance + PayableCustLedgEntry."Amount (LCY)"
            until PayableCustLedgEntry.Next() = 0;
            if CurrencyBalance > 0 then begin
                PayableCustLedgEntry.SetRange("Currency Code", PrevCurrency);
                PayableCustLedgEntry.DeleteAll();
                PayableCustLedgEntry.SetRange("Currency Code");
            end;
        end;
        PayableCustLedgEntry.Reset();
    end;

    local procedure InsertTempPaymentPostBuffer(var TempPaymentPostBuffer: Record "Payment Post. Buffer" temporary; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        TempPaymentPostBuffer."Applies-to Doc. Type" := CustLedgEntry."Document Type";
        TempPaymentPostBuffer."Applies-to Doc. No." := CustLedgEntry."Document No.";
        TempPaymentPostBuffer."Currency Factor" := CustLedgEntry."Adjusted Currency Factor";
        TempPaymentPostBuffer.Amount := PayableCustLedgEntry.Amount;
        TempPaymentPostBuffer."Amount (LCY)" := PayableCustLedgEntry."Amount (LCY)";
        TempPaymentPostBuffer."Global Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
        TempPaymentPostBuffer."Global Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
        TempPaymentPostBuffer."Auxiliary Entry No." := CustLedgEntry."Entry No.";
        TempPaymentPostBuffer.Insert();
    end;

    local procedure MakeGenPayLines()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        GenPayLine3: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
    begin
        TempPaymentPostBuffer.DeleteAll();

        if PayableCustLedgEntry.Find('-') then
            repeat
                PayableCustLedgEntry.SetRange("Vendor No.", PayableCustLedgEntry."Vendor No.");
                PayableCustLedgEntry.Find('-');
                repeat
                    CustLedgEntry.Get(PayableCustLedgEntry."Vendor Ledg. Entry No.");
                    TempPaymentPostBuffer."Account No." := CustLedgEntry."Customer No.";
                    TempPaymentPostBuffer."Currency Code" := CustLedgEntry."Currency Code";
                    if SummarizePer = SummarizePer::"Due date" then
                        TempPaymentPostBuffer."Due Date" := CustLedgEntry."Due Date";

                    TempPaymentPostBuffer."Dimension Entry No." := 0;
                    TempPaymentPostBuffer."Global Dimension 1 Code" := '';
                    TempPaymentPostBuffer."Global Dimension 2 Code" := '';

                    if SummarizePer in [SummarizePer::Customer, SummarizePer::"Due date"] then begin
                        TempPaymentPostBuffer."Auxiliary Entry No." := 0;
                        if TempPaymentPostBuffer.Find() then begin
                            TempPaymentPostBuffer.Amount := TempPaymentPostBuffer.Amount + PayableCustLedgEntry.Amount;
                            TempPaymentPostBuffer."Amount (LCY)" := TempPaymentPostBuffer."Amount (LCY)" + PayableCustLedgEntry."Amount (LCY)";
                            TempPaymentPostBuffer.Modify();
                        end else begin
                            LastLineNo := LastLineNo + 10000;
                            TempPaymentPostBuffer."Payment Line No." := LastLineNo;
                            if PaymentClass."Line No. Series" = '' then begin
                                NextDocNo := CopyStr(GenPayHead."No." + '/' + Format(LastLineNo), 1, MaxStrLen(NextDocNo));
                                TempPaymentPostBuffer."Applies-to ID" := NextDocNo;
                            end else begin
                                NextDocNo := NoSeries.GetNextNo(PaymentClass."Line No. Series", PostingDate);
                                TempPaymentPostBuffer."Applies-to ID" := GenPayHead."No." + '/' + NextDocNo;
                            end;
                            TempPaymentPostBuffer."Document No." := NextDocNo;
                            NextDocNo := IncStr(NextDocNo);
                            TempPaymentPostBuffer.Amount := PayableCustLedgEntry.Amount;
                            TempPaymentPostBuffer."Amount (LCY)" := PayableCustLedgEntry."Amount (LCY)";
                            Window.Update(1, CustLedgEntry."Customer No.");
                            TempPaymentPostBuffer.Insert();
                        end;
                        CustLedgEntry."Applies-to ID" := TempPaymentPostBuffer."Applies-to ID";
                        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry)
                    end else begin
                        GenPayLine3.Reset();
                        GenPayLine3.SetCurrentKey(
                          "Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
                        GenPayLine3.SetRange("Account Type", GenPayLine3."Account Type"::Customer);
                        GenPayLine3.SetRange("Account No.", CustLedgEntry."Customer No.");
                        GenPayLine3.SetRange("Applies-to Doc. Type", CustLedgEntry."Document Type");
                        GenPayLine3.SetRange("Applies-to Doc. No.", CustLedgEntry."Document No.");
                        if GenPayLine3.FindFirst() then
                            GenPayLine3.FieldError(
                              "Applies-to Doc. No.",
                              StrSubstNo(
                                Text016,
                                CustLedgEntry."Document Type", CustLedgEntry."Document No.",
                                CustLedgEntry."Customer No."));
                        InsertTempPaymentPostBuffer(TempPaymentPostBuffer, CustLedgEntry);
                        Window.Update(1, CustLedgEntry."Customer No.");
                    end;
                    CustLedgEntry.CalcFields("Remaining Amount");
                    CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
                    CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry)
                until PayableCustLedgEntry.Next() = 0;
                PayableCustLedgEntry.SetFilter("Vendor No.", '>%1', PayableCustLedgEntry."Vendor No.");
            until not PayableCustLedgEntry.Find('-');

        Clear(OldTempPaymentPostBuffer);
        TempPaymentPostBuffer.SetCurrentKey("Document No.");
        if TempPaymentPostBuffer.FindSet() then
            repeat
                GenPayLine.Init();
                Window.Update(1, TempPaymentPostBuffer."Account No.");
                if SummarizePer = SummarizePer::" " then begin
                    LastLineNo := LastLineNo + 10000;
                    GenPayLine."Line No." := LastLineNo;
                    if PaymentClass."Line No. Series" = '' then begin
                        NextDocNo := CopyStr(GenPayHead."No." + '/' + Format(GenPayLine."Line No."), 1, MaxStrLen(NextDocNo));
                        GenPayLine."Applies-to ID" := NextDocNo;
                    end else begin
                        NextDocNo := NoSeries.GetNextNo(PaymentClass."Line No. Series", PostingDate);
                        GenPayLine."Applies-to ID" := GenPayHead."No." + '/' + NextDocNo;
                    end;
                end else begin
                    GenPayLine."Line No." := TempPaymentPostBuffer."Payment Line No.";
                    NextDocNo := TempPaymentPostBuffer."Document No.";
                    GenPayLine."Applies-to ID" := TempPaymentPostBuffer."Applies-to ID";
                end;
                GenPayLine."Document No." := NextDocNo;
                OldTempPaymentPostBuffer := TempPaymentPostBuffer;
                OldTempPaymentPostBuffer."Document No." := GenPayLine."Document No.";
                if SummarizePer = SummarizePer::" " then begin
                    CustLedgEntry.Get(TempPaymentPostBuffer."Auxiliary Entry No.");
                    CustLedgEntry."Applies-to ID" := GenPayLine."Applies-to ID";
                    CustLedgEntry.Modify();
                end;
                GenPayLine."Account Type" := GenPayLine."Account Type"::Customer;
                GenPayLine.Validate("Account No.", TempPaymentPostBuffer."Account No.");
                GenPayLine."Currency Code" := TempPaymentPostBuffer."Currency Code";
                GenPayLine.Amount := TempPaymentPostBuffer.Amount;
                if GenPayLine.Amount > 0 then
                    GenPayLine."Debit Amount" := GenPayLine.Amount
                else
                    GenPayLine."Credit Amount" := -GenPayLine.Amount;
                GenPayLine."Amount (LCY)" := TempPaymentPostBuffer."Amount (LCY)";
                GenPayLine."Currency Factor" := TempPaymentPostBuffer."Currency Factor";
                if (GenPayLine."Currency Factor" = 0) and (GenPayLine.Amount <> 0) then
                    GenPayLine."Currency Factor" := GenPayLine.Amount / GenPayLine."Amount (LCY)";
                Cust2.Get(GenPayLine."Account No.");
                GenPayLine.Validate("Bank Account Code", Cust2."Preferred Bank Account Code");
                GenPayLine."Payment Class" := GenPayHead."Payment Class";
                GenPayLine.Validate("Status No.");
                GenPayLine."Posting Date" := PostingDate;
                if SummarizePer = SummarizePer::" " then begin
                    GenPayLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
                    GenPayLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
                    GenPayLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                    if SEPADirectDebitMandate.Get(CustLedgEntry."Direct Debit Mandate ID") then
                        GenPayLine.Validate("Bank Account Code", SEPADirectDebitMandate."Customer Bank Account Code");
                    GenPayLine."Direct Debit Mandate ID" := CustLedgEntry."Direct Debit Mandate ID";
                end;
                case SummarizePer of
                    SummarizePer::" ":
                        GenPayLine."Due Date" := CustLedgEntry."Due Date";
                    SummarizePer::Customer:
                        begin
                            PayableCustLedgEntry.SetCurrentKey("Vendor No.", "Due Date");
                            PayableCustLedgEntry.SetRange("Vendor No.", TempPaymentPostBuffer."Account No.");
                            PayableCustLedgEntry.Find('+');
                            GenPayLine."Due Date" := PayableCustLedgEntry."Due Date";
                            PayableCustLedgEntry.DeleteAll();
                        end;
                    SummarizePer::"Due date":
                        GenPayLine."Due Date" := TempPaymentPostBuffer."Due Date";
                end;
                if GenPayLine.Amount <> 0 then begin
                    if GenPayLine."Dimension Set ID" = 0 then
                        GenPayLine.DimensionSetup();
                    // per "Vendor", per "Due Date"
                    GenPayLine.Insert(true);
                end;
                GenPayLineInserted := true;
            until TempPaymentPostBuffer.Next() = 0;
    end;

    local procedure ShowMessage(Text: Text)
    begin
        if (Text <> '') and GenPayLineInserted then
            Message(Text);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetCustLedgEntriesOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

