// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Sales.FinanceCharge;

page 9106 "Customer Ledger Entry FactBox"
{
    Caption = 'Customer Ledger Entry Details';
    PageType = CardPart;
    SourceTable = "Cust. Ledger Entry";

    layout
    {
        area(content)
        {
            field(DocumentHeading; DocumentHeading)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Document';
                DrillDown = true;
                ToolTip = 'Specifies the document that the entry represents.';

                trigger OnDrillDown()
                var
                    GLEntry: Record "G/L Entry";
                begin
                    if not Rec.ShowDoc() then begin
                        GLEntry.SetCurrentKey("Document No.", "Posting Date");
                        GLEntry.SetRange("Document No.", Rec."Document No.");
                        GLEntry.SetRange("Posting Date", Rec."Posting Date");

                        PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                    end;
                end;
            }
            field("Due Date"; Rec."Due Date")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
            {
                ApplicationArea = Basic, Suite;
            }
            field(NoOfReminderFinEntries; NoOfReminderFinEntries)
            {
                ApplicationArea = Suite;
                Caption = 'Reminder/Fin. Charge Entries';
                DrillDown = true;
                ToolTip = 'Specifies reminder entries or finance charge entries for the customer ledger entry.';

                trigger OnDrillDown()
                var
                    ReminderFinEntry: Record "Reminder/Fin. Charge Entry";
                begin
                    ReminderFinEntry.SetRange("Customer Entry No.", Rec."Entry No.");

                    PAGE.Run(PAGE::"Reminder/Fin. Charge Entries", ReminderFinEntry);
                end;
            }
            field(NoOfAppliedEntries; NoOfAppliedEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Applied Entries';
                DrillDown = true;
                ToolTip = 'Specifies applied entries for the customer ledger entry.';

                trigger OnDrillDown()
                var
                    AppliedCustomerEntriesList: Page "Applied Customer Entries";
                begin
                    AppliedCustomerEntriesList.SetTempCustLedgEntry(Rec."Entry No.");
                    AppliedCustomerEntriesList.Run();
                end;
            }
            field(NoOfDetailedCustomerEntries; NoOfDetailedCustomerEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detailed Ledger Entries';
                DrillDown = true;
                ToolTip = 'Specifies detailed ledger entries for the customer ledger entry.';

                trigger OnDrillDown()
                var
                    DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                begin
                    DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", Rec."Entry No.");
                    DetailedCustLedgEntry.SetRange("Customer No.", Rec."Customer No.");
                    PAGE.Run(PAGE::"Detailed Cust. Ledg. Entries", DetailedCustLedgEntry);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DocumentHeading := GetDocumentHeading(Rec);
        CalcNoOfRecords();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        NoOfReminderFinEntries := 0;
        NoOfAppliedEntries := 0;
        DocumentHeading := '';

        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
        DocumentHeading := GetDocumentHeading(Rec);
        CalcNoOfRecords();
    end;

    var
        NoOfReminderFinEntries: Integer;
        NoOfAppliedEntries: Integer;
        NoOfDetailedCustomerEntries: Integer;
        DocumentHeading: Text[250];
#pragma warning disable AA0074
        Text000: Label 'Document';
#pragma warning restore AA0074

    local procedure CalcNoOfRecords()
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        ReminderFinChargeEntry.Reset();
        ReminderFinChargeEntry.SetRange("Customer Entry No.", Rec."Entry No.");
        NoOfReminderFinEntries := ReminderFinChargeEntry.Count();

        NoOfAppliedEntries := 0;
        if Rec."Entry No." <> 0 then
            NoOfAppliedEntries := GetNoOfAppliedEntries(Rec);

        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", Rec."Entry No.");
        DetailedCustLedgEntry.SetRange("Customer No.", Rec."Customer No.");
        NoOfDetailedCustomerEntries := DetailedCustLedgEntry.Count();
    end;

    local procedure GetNoOfAppliedEntries(CustLedgerEntry: Record "Cust. Ledger Entry"): Integer
    var
        IsHandled: Boolean;
        ReturnedValue: Integer;
    begin
        IsHandled := false;
        OnBeforeGetNoOfAppliedEntries(CustLedgerEntry, ReturnedValue, IsHandled);
        if IsHandled then
            exit(ReturnedValue);
        GetAppliedEntries(CustLedgerEntry);
        exit(CustLedgerEntry.Count);
    end;

    local procedure GetAppliedEntries(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DtldCustLedgEntry1: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CreateCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CreateCustLedgEntry := CustLedgerEntry;

        DtldCustLedgEntry1.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry1.SetRange("Cust. Ledger Entry No.", CreateCustLedgEntry."Entry No.");
        DtldCustLedgEntry1.SetRange(Unapplied, false);
        if DtldCustLedgEntry1.FindSet() then
            repeat
                if DtldCustLedgEntry1."Cust. Ledger Entry No." =
                   DtldCustLedgEntry1."Applied Cust. Ledger Entry No."
                then begin
                    DtldCustLedgEntry2.Init();
                    DtldCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    DtldCustLedgEntry2.SetRange(
                      "Applied Cust. Ledger Entry No.", DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                    DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
                    DtldCustLedgEntry2.SetRange(Unapplied, false);
                    if DtldCustLedgEntry2.Find('-') then
                        repeat
                            if DtldCustLedgEntry2."Cust. Ledger Entry No." <>
                               DtldCustLedgEntry2."Applied Cust. Ledger Entry No."
                            then begin
                                CustLedgerEntry.SetCurrentKey("Entry No.");
                                CustLedgerEntry.SetRange("Entry No.", DtldCustLedgEntry2."Cust. Ledger Entry No.");
                                if CustLedgerEntry.FindFirst() then
                                    CustLedgerEntry.Mark(true);
                            end;
                        until DtldCustLedgEntry2.Next() = 0;
                end else begin
                    CustLedgerEntry.SetCurrentKey("Entry No.");
                    CustLedgerEntry.SetRange("Entry No.", DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                    if CustLedgerEntry.FindFirst() then
                        CustLedgerEntry.Mark(true);
                end;
            until DtldCustLedgEntry1.Next() = 0;

        CustLedgerEntry.SetCurrentKey("Entry No.");
        CustLedgerEntry.SetRange("Entry No.");

        if CreateCustLedgEntry."Closed by Entry No." <> 0 then begin
            CustLedgerEntry."Entry No." := CreateCustLedgEntry."Closed by Entry No.";
            CustLedgerEntry.Mark(true);
        end;

        CustLedgerEntry.SetCurrentKey("Closed by Entry No.");
        CustLedgerEntry.SetRange("Closed by Entry No.", CreateCustLedgEntry."Entry No.");
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry.Mark(true);
            until CustLedgerEntry.Next() = 0;

        CustLedgerEntry.SetCurrentKey("Entry No.");
        CustLedgerEntry.SetRange("Closed by Entry No.");

        CustLedgerEntry.MarkedOnly(true);
    end;

    local procedure GetDocumentHeading(CustLedgerEntry: Record "Cust. Ledger Entry"): Text[50]
    var
        Heading: Text[50];
    begin
        if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::" " then
            Heading := Text000
        else
            Heading := Format(CustLedgerEntry."Document Type");
        Heading := Heading + ' ' + CustLedgerEntry."Document No.";
        exit(Heading);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoOfAppliedEntries(CustLedgerEntry: Record "Cust. Ledger Entry"; var ReturnedValue: Integer; var IsHandled: Boolean)
    begin
    end;
}

