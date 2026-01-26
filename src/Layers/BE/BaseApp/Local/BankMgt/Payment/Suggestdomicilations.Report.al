// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 2000039 "Suggest domicilations"
{
    Caption = 'Suggest domicilations';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Cust; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Payment Terms Code", "Payment Method Code";

            trigger OnAfterGetRecord()
            begin
                if "Domiciliation No." <> '' then
                    if not GenJnlManagement.CheckDomiciliationNo("Domiciliation No.") then
                        CurrReport.Skip();
                Window.Update(1, "No.");
                SuggestDomiciliations();
            end;

            trigger OnPreDataItem()
            begin
                if DueDate = 0D then
                    Error(Text000);
                if IncPmtDiscount then begin
                    if PmtDiscDueDate = 0D then
                        Error(Text001);

                    if PmtDiscDueDate < Today then
                        if not Confirm(StrSubstNo(Text002, Today), false) then
                            Error(Text004);
                end;

                Cust2.CopyFilters(Cust);

                DomJnlLine.LockTable();
                DomJnlLine.SetRange("Journal Template Name", DomJnlBatch."Journal Template Name");
                DomJnlLine.SetRange("Journal Batch Name", DomJnlBatch.Name);
                if DomJnlLine.FindLast() then;

                Window.Open(Text005);
            end;
        }
        dataitem(Counter; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                DomJnlLine2.Reset();
                DomJnlLine2.SetRange("Journal Template Name", DomJnlTemplate.Name);
                DomJnlLine2.SetRange("Journal Batch Name", DomJnlBatch.Name);
                DomJnlLine2.SetRange("Customer No.", '');
                DomJnlLine2.DeleteAll();
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
                    field(DueDate; DueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Due Date';
                        ToolTip = 'Specifies the due date that can appear on the customer ledger entries to be included in the batch job. Only entries that have a due date before or on this date will be included.';
                    }
                    field(TakePaymentsDiscounts; IncPmtDiscount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Take Payment Discounts';
                        ToolTip = 'Specifies the date that will appear as the posting date on the lines that the batch job inserts in the domiciliation journal.';
                    }
                    field(PaymentDiscountDate; PmtDiscDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Discount Date';
                        ToolTip = 'Specifies the date that will be used to calculate the payment discount.';
                    }
                    field(SelectPossibleRefunds; Refund)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Select Possible Refunds';
                        Enabled = RefundEnabled;
                        ToolTip = 'Specifies if you want the batch job to also suggest refund entries.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that will appear as the posting date on the lines that the batch job inserts in the domiciliation journal.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DueDate = 0D then
                DueDate := WorkDate();
            if PmtDiscDueDate = 0D then
                PmtDiscDueDate := WorkDate();
            if PostingDate = 0D then
                PostingDate := WorkDate();
            Refund := false;
            SetRefundEnabled();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ClearAll();
        GLSetup.Get();
    end;

    trigger OnPreReport()
    begin
        DomJnlTemplate.Get(DomJnlLine."Journal Template Name");
        DomJnlBatch.Get(DomJnlLine."Journal Template Name", DomJnlLine."Journal Batch Name");
        MakeCurrencyFilter();
    end;

    var
        Text000: Label 'Please enter the Due Date.';
        Text001: Label 'You must enter the Payment Discount Date.';
        Text002: Label 'The Payment Discount Date is earlier than %1.\\Do you want to continue?';
        Text004: Label 'The batch job was interrupted.';
        Text005: Label 'Processing customers        #1########';
        Text006: Label 'BEF';
        Text007: Label 'EUR';
        Cust2: Record Customer;
        DomJnlTemplate: Record "Domiciliation Journal Template";
        DomJnlBatch: Record "Domiciliation Journal Batch";
        DomJnlLine: Record "Domiciliation Journal Line";
        DomJnlLine2: Record "Domiciliation Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        GenJnlManagement: Codeunit DomiciliationJnlManagement;
        Window: Dialog;
        IncPmtDiscount: Boolean;
        Refund: Boolean;
        RefundEnabled: Boolean;
        PostingDate: Date;
        DueDate: Date;
        PmtDiscDueDate: Date;
        CurrencyFilter: Text[30];

    [Scope('OnPrem')]
    procedure SuggestDomiciliations()
    begin
        // selection on entries
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        CustLedgEntry.SetRange(Open, true);
        // selected due entries
        CustLedgEntry.SetRange(Positive, true);
        CustLedgEntry.SetRange("Posting Date", 0D, PostingDate);
        CustLedgEntry.SetRange("Due Date", 0D, DueDate);
        CustLedgEntry.SetFilter("Currency Code", CurrencyFilter);
        CustLedgEntry.SetRange("On Hold", '');
        if CustLedgEntry.FindSet() then
            repeat
                SetDomJnlLine();
            until CustLedgEntry.Next() = 0;
        // entries with payment discount
        if IncPmtDiscount then begin
            CustLedgEntry.SetRange(Positive, true);
            CustLedgEntry.SetRange("Due Date", DueDate + 1, 99991231D);
            CustLedgEntry.SetRange("Pmt. Discount Date", PmtDiscDueDate, DueDate);
            CustLedgEntry.SetFilter("Original Pmt. Disc. Possible", '>0');
            CustLedgEntry.SetRange("On Hold", '');
            if CustLedgEntry.FindSet() then
                repeat
                    SetDomJnlLine();
                until CustLedgEntry.Next() = 0;
        end;
        // creditmemos
        if Refund then begin
            CustLedgEntry.SetRange(Positive, false);
            CustLedgEntry.SetRange("Due Date");
            CustLedgEntry.SetRange("Pmt. Discount Date");
            CustLedgEntry.SetRange("Original Pmt. Disc. Possible");
            CustLedgEntry.SetRange("On Hold", '');
            if CustLedgEntry.FindSet() then
                repeat
                    SetDomJnlLine();
                until CustLedgEntry.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDomJnlLine()
    begin
        // don't insert invoice if already in DomJnlLine
        DomJnlLine2.Reset();
        DomJnlLine2.SetCurrentKey("Customer No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
        DomJnlLine2.SetRange("Customer No.", CustLedgEntry."Customer No.");
        DomJnlLine2.SetRange("Applies-to Doc. Type", CustLedgEntry."Document Type");
        DomJnlLine2.SetRange("Applies-to Doc. No.", CustLedgEntry."Document No.");
        DomJnlLine2.SetFilter(Status, '<>%1', DomJnlLine.Status::Posted);
        if DomJnlLine2.IsEmpty() then begin
            DomJnlLine.Init();
            DomJnlLine."Journal Template Name" := DomJnlTemplate.Name;
            DomJnlLine."Journal Batch Name" := DomJnlBatch.Name;
            DomJnlLine."Posting Date" := PostingDate;
            if IncPmtDiscount then
                DomJnlLine."Pmt. Discount Date" := PmtDiscDueDate
            else
                DomJnlLine."Pmt. Discount Date" := PostingDate;
            DomJnlLine."Line No." := DomJnlLine."Line No." + 10000;
            DomJnlLine.Validate("Customer No.", CustLedgEntry."Customer No.");
            CustLedgEntry.CalcFields("Remaining Amount");
            DomJnlLine.Amount := CustLedgEntry."Remaining Amount";
            DomJnlLine.Validate("Bank Account No.", DomJnlTemplate."Bank Account No.");
            DomJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
            DomJnlLine.Validate("Applies-to Doc. No.", CustLedgEntry."Document No.");
            DomJnlLine."Direct Debit Mandate ID" := CustLedgEntry."Direct Debit Mandate ID";
            DomJnlLine."Applies-to Entry No." := CustLedgEntry."Entry No.";
            DomJnlLine.Processing := false;
            DomJnlLine."Source Code" := DomJnlTemplate."Source Code";
            DomJnlLine."Reason Code" := DomJnlBatch."Reason Code";
            DomJnlLine.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetJournal(DomicJnlLine: Record "Domiciliation Journal Line")
    begin
        DomJnlLine := DomicJnlLine;
    end;

    [Scope('OnPrem')]
    procedure MakeCurrencyFilter()
    var
        Currency: Record Currency;
    begin
        CurrencyFilter := '';
        Currency.SetRange("ISO Code", Text006);
        if Currency.FindSet() then
            repeat
                CurrencyFilter := CurrencyFilter + '|' + Currency.Code;
            until Currency.Next() = 0;
        Currency.SetRange("ISO Code", Text007);
        if Currency.FindSet() then
            repeat
                CurrencyFilter := CurrencyFilter + '|' + Currency.Code;
            until Currency.Next() = 0;
        if GLSetup."LCY Code" in [Text006, Text007] then
            CurrencyFilter := CurrencyFilter + '|''''';
        CurrencyFilter := DelChr(CurrencyFilter, '<>', '|');
    end;

    local procedure IsDomiciliationProcessingCodeunit(CodeunitID: Integer): Boolean
    begin
        exit(CodeunitID = CODEUNIT::"File Domiciliations")
    end;

    local procedure SetRefundEnabled()
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        RefundEnabled := false;

        DomJnlTemplate.Get(DomJnlLine."Journal Template Name");

        if BankAccount.Get(DomJnlTemplate."Bank Account No.") then
            if BankExportImportSetup.Get(BankAccount."SEPA Direct Debit Exp. Format") then
                RefundEnabled := IsDomiciliationProcessingCodeunit(BankExportImportSetup."Processing Codeunit ID");
    end;
}

