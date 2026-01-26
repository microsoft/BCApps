// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 3010834 "LSV Journal Line"
{
    Caption = 'LSV Journal Line';
    DrillDownPageID = "LSV Journal Line List";
    LookupPageID = "LSV Journal Line List";
    Permissions = TableData "Cust. Ledger Entry" = rm;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "LSV Journal No."; Integer)
        {
            Caption = 'LSV Journal No.';
            TableRelation = "LSV Journal"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            begin
                if "Customer No." <> xRec."Customer No." then begin
                    "Applies-to Doc. No." := '';
                    "Cust. Ledg. Entry No." := 0;
                end;
            end;
        }
        field(7; "Collection Amount"; Decimal)
        {
            Caption = 'Collection Amount';
            Editable = false;
        }
        field(8; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(11; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            begin
                TestField("Customer No.");
                LSVJournal.Get("LSV Journal No.");
                CustLedgEntry.Reset();
                CustLedgEntry.FilterGroup := 2;
                if (LSVJournal."LSV Status" = LSVJournal."LSV Status"::Edit) and ("Applies-to Doc. No." = '') then begin
                    CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
                    CustLedgEntry.SetRange("Customer No.", "Customer No.");
                    CustLedgEntry.SetRange(Open, true);
                    CustLedgEntry.SetRange("On Hold", '');
                    GLSetup.Get();
                    if not (LSVJournal."Currency Code" = GLSetup."LCY Code") then
                        CustLedgEntry.SetRange("Currency Code", LSVJournal."Currency Code");
                end else begin
                    CustLedgEntry.SetCurrentKey("Document No.");
                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                    CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                end;

                if CustLedgEntry.Get("Cust. Ledg. Entry No.") then;
                CustLedgEntry.FilterGroup := 0;
                if PAGE.RunModal(0, CustLedgEntry) = ACTION::LookupOK then begin
                    if CustLedgEntry."Entry No." = 0 then
                        exit;
                    "Applies-to Doc. No." := CustLedgEntry."Document No.";
                    "Cust. Ledg. Entry No." := CustLedgEntry."Entry No.";
                    CompletePmtSuggestLines(Rec);
                end;
            end;

            trigger OnValidate()
            begin
                if "Applies-to Doc. No." = '' then
                    exit;

                CustLedgEntry.SetCurrentKey("Document No.");
                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                if not CustLedgEntry.FindFirst() then
                    Error(Text000);

                "Cust. Ledg. Entry No." := CustLedgEntry."Entry No.";
                CompletePmtSuggestLines(Rec);
            end;
        }
        field(13; "Cust. Ledg. Entry No."; Integer)
        {
            Caption = 'Cust. Ledg. Entry No.';
            TableRelation = "Cust. Ledger Entry"."Entry No.";

            trigger OnLookup()
            begin
                TestField("Customer No.");
                LSVJournal.Get("LSV Journal No.");
                CustLedgEntry.FilterGroup := 2;
                if (LSVJournal."LSV Status" = LSVJournal."LSV Status"::Edit) and ("Cust. Ledg. Entry No." = 0) then begin
                    CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
                    CustLedgEntry.SetRange("Customer No.", "Customer No.");
                    CustLedgEntry.SetRange(Open, true);
                    CustLedgEntry.SetRange("On Hold", '');
                    LSVJournal.Get("LSV Journal No.");
                    GLSetup.Get();
                    if not (LSVJournal."Currency Code" = GLSetup."LCY Code") then
                        CustLedgEntry.SetRange("Currency Code", LSVJournal."Currency Code");
                end else begin
                    CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
                    CustLedgEntry.SetRange("Customer No.", "Customer No.");
                    CustLedgEntry.SetRange("Entry No.", "Cust. Ledg. Entry No.");
                end;

                if CustLedgEntry.Get("Cust. Ledg. Entry No.") then;
                CustLedgEntry.FilterGroup := 0;
                if PAGE.RunModal(0, CustLedgEntry) = ACTION::LookupOK then begin
                    "Applies-to Doc. No." := CustLedgEntry."Document No.";
                    "Cust. Ledg. Entry No." := CustLedgEntry."Entry No.";
                    "Customer No." := CustLedgEntry."Customer No.";
                    CompletePmtSuggestLines(Rec);
                end;
            end;

            trigger OnValidate()
            begin
                if "Cust. Ledg. Entry No." = 0 then
                    exit;

                CustLedgEntry.Reset();
                CustLedgEntry.FilterGroup := 2;
                CustLedgEntry.SetCurrentKey("Entry No.");
                CustLedgEntry.SetRange("Entry No.", "Cust. Ledg. Entry No.");
                if CustLedgEntry.Get("Cust. Ledg. Entry No.") then;
                CustLedgEntry.FilterGroup := 0;
                CompletePmtSuggestLines(Rec);
            end;
        }
        field(15; "LSV Status"; Option)
        {
            Caption = 'LSV Status';
            OptionCaption = 'Open,Closed by Import File,Transferred to Pmt. Journal,Rejected';
            OptionMembers = Open,"Closed by Import File","Transferred to Pmt. Journal",Rejected;

            trigger OnValidate()
            begin
                LSVJournal.Get("LSV Journal No.");
                if LSVJournal."LSV Status" <> LSVJournal."LSV Status"::"File Created" then
                    Error(Text005);

                if xRec."LSV Status" >= "LSV Status"::"Closed by Import File" then
                    Error(Text003);

                if "LSV Status" in ["LSV Status"::"Closed by Import File", "LSV Status"::"Transferred to Pmt. Journal"] then
                    Error(Text003);

                if "LSV Status" = "LSV Status"::Rejected then
                    UpdateCustLedgEntry("Cust. Ledg. Entry No.", 0, 3);
            end;
        }
        field(16; "DD Rejection Reason"; Option)
        {
            Caption = 'DD Rejection Reason';
            Editable = false;
            OptionCaption = ' ,Insufficient cover funds,Customer protestation,Customer account number and address do not match,Postal account closed,Postal account blocked/frozen,Postal account holder deceased,Postal account number non-existent';
            OptionMembers = " ","Insufficient cover funds","Customer protestation","Customer account number and address do not match","Postal account closed","Postal account blocked/frozen","Postal account holder deceased","Postal account number non-existent";
        }
        field(20; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            Editable = false;
        }
        field(21; "Pmt. Discount"; Decimal)
        {
            Caption = 'Pmt. Discount';
            Editable = false;
        }
        field(80; "Last Modified By"; Code[50])
        {
            Caption = 'Last Modified By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(81; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(1230; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Customer No."));
        }
    }

    keys
    {
        key(Key1; "LSV Journal No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Collection Amount";
        }
        key(Key2; "Applies-to Doc. No.")
        {
        }
        key(Key3; "LSV Journal No.", "Cust. Ledg. Entry No.")
        {
        }
        key(Key4; "LSV Journal No.", "Transaction No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LSVJournal.Get("LSV Journal No.");
        if LSVJournal."LSV Status" = LSVJournal."LSV Status"::"File Created" then
            Error(Text004);
        if LSVJournal."LSV Status" <> LSVJournal."LSV Status"::Finished then begin
            UpdateCustLedgEntry("Cust. Ledg. Entry No.", 0, 3);

            LSVJournal.Get("LSV Journal No.");
            LSVJournal.Validate("LSV Status");
        end;


        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := Format(DATABASE::"LSV Journal");
        GenJnlLine."Document No." := Format("LSV Journal No.");
        GenJnlLine."Line No." := "Line No.";
        GenJnlLine.DeletePaymentFileErrors();
    end;

    trigger OnInsert()
    begin
        "Last Modified By" := UserId;
        UpdateCustLedgEntry("Cust. Ledg. Entry No.", "LSV Journal No.", 1);

        LSVJournalLine2.SetRange("LSV Journal No.", "LSV Journal No.");
        if LSVJournalLine2.FindLast() then
            "Line No." := LSVJournalLine2."Line No." + 1
        else
            "Line No." := 1;
    end;

    trigger OnModify()
    begin
        "Last Modified By" := UserId;
        if "LSV Status" <> "LSV Status"::Rejected then
            UpdateCustLedgEntry("Cust. Ledg. Entry No.", "LSV Journal No.", 2);

        LSVJournal.Get("LSV Journal No.");
        LSVJournal.Validate("LSV Status");
        LSVJournal.Modify();
    end;

    var
        Text000: Label 'This value does not exist.';
        Text001: Label 'The %1 entry is set on hold by %2.';
        Text002: Label 'For this collection only Currency %1 is allowed.';
        Text003: Label 'This change is not allowed.';
        Text004: Label 'Delete not allowed because File has already been created.';
        Text005: Label 'Change only allowed when File has already been created.';
        CustLedgEntry: Record "Cust. Ledger Entry";
        LSVJournal: Record "LSV Journal";
        LSVJournalLine2: Record "LSV Journal Line";
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";

    local procedure UpdateCustLedgEntry(CustLedgEntryNo: Integer; LSVNo: Integer; Caller: Integer)
    begin
        CustLedgEntry.Reset();
        if not CustLedgEntry.Get(CustLedgEntryNo) then
            exit;

        case Caller of
            1:
                begin
                    if CustLedgEntry."On Hold" <> '' then begin
                        Rec := xRec;
                        Error(Text001, CustLedgEntry.TableCaption(), CustLedgEntry."On Hold");
                    end;
                    CustLedgEntry."On Hold" := 'LSV';
                    CustLedgEntry."LSV No." := LSVNo;
                end;
            2:
                begin
                    CustLedgEntry."On Hold" := 'LSV';
                    CustLedgEntry."LSV No." := LSVNo;
                end;
            3:
                begin
                    CustLedgEntry."On Hold" := '';
                    CustLedgEntry."LSV No." := 0;
                end;
        end;
        CustLedgEntry.Modify();
    end;

    [Scope('OnPrem')]
    procedure CompletePmtSuggestLines(var ActLSVJournalLine: Record "LSV Journal Line")
    var
        ActCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        ActCustLedgEntry.Get(ActLSVJournalLine."Cust. Ledg. Entry No.");

        GLSetup.Get();
        if ActCustLedgEntry."Currency Code" = '' then
            ActCustLedgEntry."Currency Code" := GLSetup."LCY Code";

        LSVJournal.Get("LSV Journal No.");
        if LSVJournal."Currency Code" <> ActCustLedgEntry."Currency Code" then
            Error(Text002, LSVJournal."Currency Code");

        ActCustLedgEntry.CalcFields("Remaining Amount");
        ActLSVJournalLine."Remaining Amount" := ActCustLedgEntry."Remaining Amount";
        ActLSVJournalLine."Pmt. Discount" := ActCustLedgEntry."Remaining Pmt. Disc. Possible";
        ActLSVJournalLine."Collection Amount" := ActCustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";

        "Customer No." := CustLedgEntry."Customer No.";
        Customer.Get("Customer No.");
        Name := Customer.Name;

        if "Applies-to Doc. No." = '' then
            "Applies-to Doc. No." := CustLedgEntry."Document No.";

        if "Cust. Ledg. Entry No." = 0 then
            "Cust. Ledg. Entry No." := CustLedgEntry."Entry No.";

        if "Direct Debit Mandate ID" = '' then
            "Direct Debit Mandate ID" := CustLedgEntry."Direct Debit Mandate ID";
    end;
}

