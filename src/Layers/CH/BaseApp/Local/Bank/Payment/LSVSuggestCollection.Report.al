// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 3010831 "LSV Suggest Collection"
{
    Caption = 'LSV Suggest Collection';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer Posting Group", "Partner Type";

            trigger OnAfterGetRecord()
            begin
                // Filter all entries: Customer, positive, to due date
                Window.Update(1, Customer."No.");

                EntriesPerCust := 0;

                CustLedgEntry.Reset();
                CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
                CustLedgEntry.SetRange("Customer No.", "No.");
                CustLedgEntry.SetRange(Open, true);
                CustLedgEntry.SetRange(Positive, true);
                CustLedgEntry.SetRange("Payment Method Code", LsvSetup."LSV Payment Method Code");
                CustLedgEntry.SetRange("Due Date", FromDueDate, ToDueDate);
                if LsvSetup."LSV Currency Code" = GLSetup."LCY Code" then
                    CustLedgEntry.SetFilter("Currency Code", '%1', '')
                else
                    CustLedgEntry.SetRange("Currency Code", LsvSetup."LSV Currency Code");
                CustLedgEntry.SetRange("On Hold", '');
                if CustLedgEntry.Find('-') then
                    repeat
                        WritePmtSuggestLines(CustLedgEntry);
                    until CustLedgEntry.Next() = 0;

                // Check for credit memos of customers
                if EntriesPerCust > 0 then begin
                    CrMemoCustEntry.SetCurrentKey("Customer No.", Open, Positive);
                    CrMemoCustEntry.SetRange("Customer No.", "No.");
                    CrMemoCustEntry.SetRange(Open, true);
                    CrMemoCustEntry.SetRange(Positive, false);
                    if CrMemoCustEntry.FindFirst() then begin
                        NoOfCustWithCreditMemo := NoOfCustWithCreditMemo + 1;
                        CustCreditMemoTxt := CopyStr(CustCreditMemoTxt + Customer."No." + ', ', 1, 250);
                    end;
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
                if TempCustLedgEntry.IsEmpty() then
                    if NoOfLinesInserted > 0 then begin
                        Message(Text007, NoOfLinesInserted, LsvSetup."LSV Currency Code", TotalAmt);

                        if LsvJournal."LSV Journal Description" = '' then
                            LsvJournal."LSV Journal Description" :=
                              Format(StrSubstNo(Text021, LsvSetup."LSV Currency Code", FromDueDate, ToDueDate, Customer.GetFilters)
                                , -MaxStrLen(LsvJournal."LSV Journal Description"));

                        LsvJournal."Credit Date" := CollectionDate;
                        LsvJournal.Modify();

                        if NoOfCustWithCreditMemo > 0 then
                            if not Confirm(Text009, true, NoOfCustWithCreditMemo, CustCreditMemoTxt) then
                                Error(Text014);
                    end else
                        Message(Text015, FromDueDate, ToDueDate);
            end;

            trigger OnPreDataItem()
            begin
                if FromDueDate = 0D then
                    FromDueDate := 00000101D;
                if ToDueDate = 0D then
                    Error(Text000);

                Window.Open(
                  Text002 + // LSV suggest collection
                  Text003 + // Customer no #1
                  Text004 + // No of lines #2
                  Text005); // Total amt #3

                if not LsvSetup.Get(LsvJournal."LSV Bank Code") then
                    Error(Text006);

                if LsvJournal."LSV Status" <> LsvJournal."LSV Status"::Edit then
                    Error(Text022);

                LsvSetup.TestField("LSV Payment Method Code");
                LsvSetup.TestField("LSV Currency Code");
                GLSetup.Get();
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
                    field(FromDueDate; FromDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From due date';
                        ToolTip = 'Specifies the start date of the entries to include in the collection.';
                    }
                    field(ToDueDate; ToDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To due date';
                        ToolTip = 'Specifies the end date of the entries to include in the collection.';

                        trigger OnValidate()
                        begin
                            if ToDueDate <> 0D then
                                CollectionDate := ToDueDate;
                        end;
                    }
                    field(CollectionDate; CollectionDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Collection date';
                        ToolTip = 'Specifies the date when the collection was closed.';
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

    trigger OnPostReport()
    begin
        Commit();
        if not TempCustLedgEntry.IsEmpty() then
            if Confirm(Text036) then
                PAGE.RunModal(0, TempCustLedgEntry);
    end;

    trigger OnPreReport()
    begin
        if LsvJournal."LSV Bank Code" = '' then
            Error(Text020);
        TempCustLedgEntry.DeleteAll();
    end;

    var
        Text000: Label 'Define range of due dates. All invoices within this range will be collected.';
        Text002: Label 'LSV suggest collection\';
        Text003: Label 'Customerno.    #1#########\';
        Text004: Label 'No of lines    #2#########\';
        Text005: Label 'Total amount   #3#########\';
        Text006: Label 'LSV Bank must be defined.';
        Text007: Label 'Collection has been successfully suggested. %1 lines with a total of %2 %3 have been transferred to the LSV Journal Line.', Comment = 'Parameter 1 and 3 - numbers, 2 - currency code.';
        Text009: Label 'There are open credit memos for %1 customers within the suggested collection.\\You can apply the open invoices and credit memos and repeat the collection.\\Customers with credit memos: %2.\\Do you want to complete the LSV collection anyway?';
        Text014: Label 'Job cancelled.';
        Text015: Label 'Collection processed. No open invoices within the defined filters that are due from %1 to %2.';
        Text020: Label 'You can start this report only from LSV Journal.';
        Text021: Label 'Currency: %1 from %2 to %3. Filter(%4) ';
        Text022: Label 'You can run this only if LSV Status is edit.';
        Text035: Label 'Collection is Closed, no change possible.';
        Text036: Label 'There are one or more entries for which no collection suggestions have been made because the posting dates of the entries are later than the collection date in the LSV Collect Suggestions batch job request window. Do you want to see the entries?';
        LsvSetup: Record "LSV Setup";
        LsvJournal: Record "LSV Journal";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CrMemoCustEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        ToLSVJourLine: Record "LSV Journal Line";
        LSVJourLineCheck: Record "LSV Journal Line";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        Window: Dialog;
        NoOfLinesInserted: Integer;
        TotalAmt: Decimal;
        CollectionDate: Date;
        FromDueDate: Date;
        ToDueDate: Date;
        NoOfCustWithCreditMemo: Integer;
        CustCreditMemoTxt: Text[250];
        EntriesPerCust: Integer;

    [Scope('OnPrem')]
    procedure SetGlobals(ActualJournalNo: Integer)
    begin
        LsvJournal.Get(ActualJournalNo);
        LsvJournal.TestField("LSV Bank Code");

        if LsvJournal."LSV Status" >= LsvJournal."LSV Status"::Released then
            Error(Text035);
    end;

    [Scope('OnPrem')]
    procedure WritePmtSuggestLines(ActCustLedgEntry: Record "Cust. Ledger Entry")
    begin
        // Collection amt: Cust. Entry amount - Cash disc. possible
        if CustLedgEntry."Posting Date" <= CollectionDate then begin
            // Ensure, that the Entry is only once in the LSV Journal Line
            LSVJourLineCheck.SetCurrentKey("Applies-to Doc. No.");
            LSVJourLineCheck.SetRange("Applies-to Doc. No.", ActCustLedgEntry."Document No.");
            LSVJourLineCheck.SetRange("LSV Status", ToLSVJourLine."LSV Status"::Open, ToLSVJourLine."LSV Status"::"Transferred to Pmt. Journal");
            if LSVJourLineCheck.FindFirst() then
                exit;

            ToLSVJourLine.Init();
            ToLSVJourLine."LSV Journal No." := LsvJournal."No.";
            ToLSVJourLine.Validate("Customer No.", ActCustLedgEntry."Customer No.");
            ToLSVJourLine.Validate("Currency Code", ActCustLedgEntry."Currency Code");
            ActCustLedgEntry.CalcFields("Remaining Amount");
            ToLSVJourLine."Remaining Amount" := ActCustLedgEntry."Remaining Amount";
            ToLSVJourLine."Pmt. Discount" := ActCustLedgEntry."Remaining Pmt. Disc. Possible";
            ToLSVJourLine."Collection Amount" := ActCustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
            ToLSVJourLine."Applies-to Doc. No." := ActCustLedgEntry."Document No.";
            ToLSVJourLine."Cust. Ledg. Entry No." := ActCustLedgEntry."Entry No.";
            ToLSVJourLine.Name := Customer.Name;
            ToLSVJourLine."Direct Debit Mandate ID" := CustLedgEntry."Direct Debit Mandate ID";

            ToLSVJourLine.Insert(true);

            NoOfLinesInserted := NoOfLinesInserted + 1;
            Window.Update(2, NoOfLinesInserted);
            TotalAmt := TotalAmt + ToLSVJourLine."Collection Amount";
            Window.Update(3, TotalAmt);

            EntriesPerCust := EntriesPerCust + 1;
        end else begin
            TempCustLedgEntry := CustLedgEntry;
            TempCustLedgEntry.Insert();
        end;
    end;
}

