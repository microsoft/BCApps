// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;

table 2250 "Vendor Ledger Entry Buffer"
{
    Caption = 'Vendor Ledger Entry Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
        }
        field(14; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
        }
        field(36; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(47; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(8001; "Vendor Id"; Guid)
        {
            Caption = 'Vendor Id';
        }
        field(8002; "Gen. Journal Line Id"; Guid)
        {
            Caption = 'Gen. Journal Line Id';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure LoadDataFromFilter(VendorIdFilter: Text; GenJournalLineIdFilter: Text)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Vendor.GetBySystemId(VendorIdFilter);
        GenJournalLine.GetBySystemId(GenJournalLineIdFilter);
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");

        if VendorLedgerEntry.FindSet() then
            repeat
                Clear(Rec);
                Rec.TransferFields(VendorLedgerEntry);
                VendorLedgerEntry.CalcFields("Remaining Amount");
                Rec."Remaining Amount" := VendorLedgerEntry."Remaining Amount";
                Rec.SystemId := VendorLedgerEntry.SystemId;
                Rec."Vendor Id" := Vendor.SystemId;
                Rec."Gen. Journal Line Id" := GenJournalLine.SystemId;
                Rec.Insert();
            until VendorLedgerEntry.Next() = 0;
    end;
}
