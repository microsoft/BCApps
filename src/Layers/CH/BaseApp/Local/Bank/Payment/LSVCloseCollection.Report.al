// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.Receivables;

report 3010833 "LSV Close Collection"
{
    Caption = 'LSV Close Collection';
    Permissions = TableData "Cust. Ledger Entry" = rm;
    ProcessingOnly = true;

    dataset
    {
        dataitem("LSV Journal Line"; "LSV Journal Line")
        {
            DataItemTableView = sorting("LSV Journal No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                // Allocate invoices to LSV Journal, adapte cash discount if necessary

                CustLedgEntry.SetCurrentKey("Document No.");
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                CustLedgEntry.SetRange("Customer No.", "Customer No.");

                CheckCustEntries();

                TotalAmt := TotalAmt + "Collection Amount";
                NoOfLines := NoOfLines + 1;

                Window.Update(1, "Customer No.");
                Window.Update(2, NoOfLines);
            end;

            trigger OnPostDataItem()
            begin
                // Write LSV journal entry
                LsvJournal.LockTable();
                LsvJournal."LSV Bank Code" := LsvSetup."Bank Code";
                LsvJournal."Credit Date" := CollectionDate;
                LsvJournal."Collection Completed On" := Today;
                LsvJournal."Collection Completed By" := UserId;
                LsvJournal."LSV Status" := LsvJournal."LSV Status"::Released;
                LsvJournal.Modify();

                Message(Text012, LsvJournal."No.", NoOfLines, LsvSetup."LSV Currency Code", TotalAmt);
            end;

            trigger OnPreDataItem()
            begin
                // *** Transfer applied invoices according to pmt. journal to LSV Journal

                // Check collection date
                if CollectionDate = 0D then
                    Error(Text000);

                if CollectionDate < Today then
                    Error(Text001, CollectionDate);

                // CollDatum = Sat
                if Date2DWY(CollectionDate, 1) = 6 then begin // Sat => Mon
                    if not Confirm(Text002, true, CollectionDate, CollectionDate + 2) then
                        Error(Text004);
                    CollectionDate := CollectionDate + 2;
                end;
                // CollDate = Sunday
                if Date2DWY(CollectionDate, 1) = 7 then begin // Sun => Mon
                    if not Confirm(Text005, true, CollectionDate, CollectionDate + 1) then
                        Error(Text004);
                    CollectionDate := CollectionDate + 1;
                end;
                if not LsvSetup.Get(LsvSetup."Bank Code") then
                    Error(Text006);

                SetRange("LSV Journal No.", LsvJournal."No.");

                if not FindFirst() then
                    Error(Text007);

                Window.Open(
                  Text008 +
                  Text009 +
                  Text010)
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("LsvJournal.""No."""; LsvJournal."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No.';
                        Editable = false;
                        ToolTip = 'Specifies the number.';
                    }
                    field(CollectionDate; CollectionDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Collection Date';
                        Editable = false;
                        ToolTip = 'Specifies the date when the collection was completed.';
                    }
                    field("LsvJournal.""LSV Bank Code"""; LsvJournal."LSV Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Credit to LSV Bank';
                        Editable = false;
                        Lookup = true;
                        TableRelation = "LSV Setup";
                        ToolTip = 'Specifies the bank for which you want to complete the collection.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if LsvJournal."LSV Status" > LsvJournal."LSV Status"::Edit then
                Error(Text028);
        end;
    }

    labels
    {
    }

    var
        Text000: Label 'Define the desired collection date.';
        Text001: Label 'The collection date %1 may not be in the past.';
        Text002: Label 'The collection date %1 is a Saturday. It must be a weekday.\Do you want to move it to Monday,  %2?';
        Text004: Label 'Job cancelled.';
        Text005: Label 'The collection date %1 is a Sunday. It must be a weekday.\Do you want to move it to Monday,  %2?';
        Text006: Label 'Please define LSV bank.';
        Text007: Label 'No payments are prepared as collections in the actual journal.';
        Text008: Label 'Prepare customer entries\';
        Text009: Label 'Customer      #1########\';
        Text010: Label 'Entries       #2########';
        Text012: Label 'The collection has been successfully prepared for the LSV journal %1.\%2 records for %3 %4 have been processed.\\Open the LSV journal if you want to write the LSV file and to print the collection order.', Comment = 'Parameter 1 - journal number, 2 and 4 - number, 3 - currency code.';
        Text016: Label 'Customer entry with doc. no. %1 for customer %2 not found.';
        Text017: Label 'Invoice %1 for customer %2 is no longer open. It cannot be collected.';
        Text023: Label 'The collection amount %1 in the journal must have a negative sign.';
        Text024: Label 'The collection amount %1 must not be higher than the remaining amount of the cust. entry %2.';
        Text025: Label 'The collection amount %1 in the journal for invoice %2 does not match the open amount %3 (Remaining %4 - Cash. disc. possible %5) of the customer entry.\Do you want to correct the difference of %6 as the cash discount?', Comment = 'Parameter 2 - document number, other ones - numbers.';
        Text028: Label 'Collection Status is not Edit.';
        LsvSetup: Record "LSV Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        LsvJournal: Record "LSV Journal";
        Window: Dialog;
        CollectionDate: Date;
        TotalAmt: Decimal;
        NoOfLines: Integer;

    [Scope('OnPrem')]
    procedure CheckCustEntries()
    var
        CustEntryCashAmt: Decimal;
        NewCashDiscAmt: Decimal;
    begin
        // Cust entry according to application ID exists, open? Adapt cash discount?

        if not CustLedgEntry.FindFirst() then
            Error(Text016, "LSV Journal Line"."Applies-to Doc. No.", "LSV Journal Line"."Customer No.");

        // Invoice not open
        if not CustLedgEntry.Open then
            Error(Text017, CustLedgEntry."Document No.", CustLedgEntry."Customer No.");

        if "LSV Journal Line"."Collection Amount" < 0 then
            Error(Text023, "LSV Journal Line"."Collection Amount");

        // Check and modify cash disc. date and disc. amt.
        CustLedgEntry.CalcFields("Remaining Amount");
        CustEntryCashAmt := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
        if CustEntryCashAmt <> "LSV Journal Line"."Collection Amount" then begin
            NewCashDiscAmt := CustLedgEntry."Remaining Amount" - "LSV Journal Line"."Collection Amount";
            if NewCashDiscAmt < 0 then
                Error(Text024, "LSV Journal Line"."Collection Amount", CustLedgEntry."Remaining Amount");

            if Confirm(Text025, true,
                 "LSV Journal Line"."Collection Amount",
                 CustLedgEntry."Document No.",
                 CustEntryCashAmt,
                 CustLedgEntry."Remaining Amount",
                 CustLedgEntry."Remaining Pmt. Disc. Possible",
                 NewCashDiscAmt)
            then begin
                CustLedgEntry."Remaining Pmt. Disc. Possible" := NewCashDiscAmt;
                CustLedgEntry.Modify();
            end else
                Error(Text004);
        end;

        // Cash disc. date to collection date. Toleracne, if credit memo late
        if CustLedgEntry."Remaining Pmt. Disc. Possible" > 0 then
            CustLedgEntry."Pmt. Discount Date" := CollectionDate + 10;
    end;

    [Scope('OnPrem')]
    procedure SetGlobals(ActLsvJournal: Record "LSV Journal")
    begin
        LsvJournal.Copy(ActLsvJournal);
        LsvJournal.TestField("LSV Bank Code");

        LsvSetup.Get(LsvJournal."LSV Bank Code");
        CollectionDate := LsvJournal."Credit Date";
    end;
}

