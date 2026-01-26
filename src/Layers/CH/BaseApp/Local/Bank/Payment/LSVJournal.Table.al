// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Receivables;
using System.Security.AccessControl;

table 3010832 "LSV Journal"
{
    Caption = 'LSV Journal';
    DrillDownPageID = "LSV Journal List";
    LookupPageID = "LSV Journal List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "LSV Journal Description"; Text[150])
        {
            Caption = 'LSV Journal Description';
        }
        field(5; "LSV Status"; Option)
        {
            Caption = 'LSV Status';
            Editable = false;
            OptionCaption = 'Edit,Released,File Created,Finished';
            OptionMembers = Edit,Released,"File Created",Finished;

            trigger OnValidate()
            begin
                if "LSV Status" in ["LSV Status"::"File Created", "LSV Status"::Finished] then begin
                    LSVJournalLine.Reset();
                    LSVJournalLine.SetRange("LSV Journal No.", "No.");
                    LSVJournalLine.SetRange("LSV Status", LSVJournalLine."LSV Status"::Open);
                    if LSVJournalLine.FindFirst() then
                        "LSV Status" := "LSV Status"::"File Created"
                    else
                        "LSV Status" := "LSV Status"::Finished;
                end;
            end;
        }
        field(10; "Credit Date"; Date)
        {
            Caption = 'Credit Date';
        }
        field(12; "LSV Bank Code"; Code[20])
        {
            Caption = 'LSV Bank Code';
            TableRelation = "LSV Setup";

            trigger OnValidate()
            begin
                if "LSV Bank Code" <> '' then begin
                    LSVSetup.Get("LSV Bank Code");
                    "Currency Code" := LSVSetup."LSV Currency Code";
                end;
            end;
        }
        field(30; "Collection Completed On"; Date)
        {
            Caption = 'Collection Completed On';
        }
        field(40; "File Written On"; Date)
        {
            Caption = 'File Written On';
        }
        field(50; "No. Of Entries"; Integer)
        {
            Caption = 'No. Of Entries';
        }
        field(51; "No. Of Entries Plus"; Integer)
        {
            CalcFormula = count("LSV Journal Line" where("LSV Journal No." = field("No.")));
            Caption = 'No. Of Entries Plus';
            FieldClass = FlowField;
        }
        field(52; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(53; "Amount Plus"; Decimal)
        {
            CalcFormula = sum("LSV Journal Line"."Collection Amount" where("LSV Journal No." = field("No.")));
            Caption = 'Amount Plus';
            FieldClass = FlowField;
        }
        field(54; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(100; "Collection Completed By"; Code[50])
        {
            Caption = 'Collection Completed By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(130; "DebitDirect Orderno."; Code[2])
        {
            Caption = 'DebitDirect Orderno.';
        }
        field(1200; "Partner Type"; Option)
        {
            Caption = 'Partner Type';
            OptionCaption = ' ,Company,Person';
            OptionMembers = " ",Company,Person;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "LSV Journal Description")
        {
        }
    }

    trigger OnDelete()
    begin
        if not ("LSV Status" in ["LSV Status"::Edit, "LSV Status"::Finished]) then
            Error(Text001);

        LSVJournalLine.Reset();
        LSVJournalLine.SetRange("LSV Journal No.", "No.");
        LSVJournalLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if LsvJournal2.FindLast() then
            "No." := LsvJournal2."No." + 1
        else
            "No." := 1;

        CustLedgerEntry.Reset();
        CustLedgerEntry.SetCurrentKey("LSV No.");
        if CustLedgerEntry.FindLast() then
            if CustLedgerEntry."LSV No." > "No." then
                "No." := CustLedgerEntry."LSV No." + 1;
    end;

    var
        LsvJournal2: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJournalLine: Record "LSV Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Text001: Label 'You can only delete LSV Journal entries with Status edit or finished.';

    [Scope('OnPrem')]
    procedure CreateDirectDebitFile()
    var
        BankAcc: Record "Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        BankAcc.Get("LSV Bank Code");

        DirectDebitCollection.CreateRecord(Format("No."), "LSV Bank Code", Enum::"Partner Type".FromInteger("Partner Type"));
        DirectDebitCollection."Source Table ID" := DATABASE::"LSV Journal";
        DirectDebitCollection.Modify();
        Commit();

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        RunFileExportCodeunit(BankAcc.GetDDExportCodeunitID(), DirectDebitCollection."No.", DirectDebitCollectionEntry);
        DeleteDirectDebitCollection(DirectDebitCollection."No.");
    end;

    local procedure RunFileExportCodeunit(CodeunitID: Integer; DirectDebitCollectionNo: Integer; var DirectDebitCollEntry: Record "Direct Debit Collection Entry")
    var
        LastError: Text;
    begin
        if CODEUNIT.Run(CodeunitID, DirectDebitCollEntry) then begin
            DirectDebitCollEntry.DeletePaymentFileErrors();
            "LSV Status" := "LSV Status"::"File Created";
            "File Written On" := Today;
            Modify();
            exit;
        end;

        LastError := GetLastErrorText;
        DeleteDirectDebitCollection(DirectDebitCollectionNo);
        Commit();
        Error(LastError);
    end;

    local procedure DeleteDirectDebitCollection(DirectDebitCollectionNo: Integer)
    var
        DirectDebitColl: Record "Direct Debit Collection";
    begin
        if DirectDebitColl.Get(DirectDebitCollectionNo) then
            DirectDebitColl.Delete(true);
    end;
}

