#if not CLEANSCHEMA25 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;

#pragma warning disable AS0109
table 372 "Payment Buffer"
{
    Caption = 'Payment Buffer';
    ReplicateData = false;
    TableType = Temporary;
    ObsoleteReason = 'Replaced by Vendor Payment Buffer.';
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = SystemMetadata;
            TableRelation = Vendor;
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(3; "Vendor Ledg. Entry No."; Integer)
        {
            Caption = 'Vendor Ledg. Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Vendor Ledger Entry";
        }
        field(4; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(6; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(8; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(9; "Vendor Ledg. Entry Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Vendor Ledg. Entry Doc. Type';
            DataClassification = SystemMetadata;
        }
        field(10; "Vendor Ledg. Entry Doc. No."; Code[20])
        {
            Caption = 'Vendor Ledg. Entry Doc. No.';
            DataClassification = SystemMetadata;
        }
        field(11; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            DataClassification = SystemMetadata;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
            DataClassification = SystemMetadata;
            TableRelation = "Vendor Ledger Entry"."Creditor No." where("Entry No." = field("Vendor Ledg. Entry No."));
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
            DataClassification = SystemMetadata;
            TableRelation = "Vendor Ledger Entry"."Payment Reference" where("Entry No." = field("Vendor Ledg. Entry No."));
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            DataClassification = SystemMetadata;
            TableRelation = "Vendor Ledger Entry"."Payment Method Code" where("Vendor No." = field("Vendor No."));
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
            DataClassification = SystemMetadata;
        }
        field(290; "Exported to Payment File"; Boolean)
        {
            Caption = 'Exported to Payment File';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(1000; "Remit-to Code"; Code[20])
        {
            Caption = 'Remit-to Code';
            DataClassification = SystemMetadata;
            TableRelation = "Remit Address".Code where("Vendor No." = field("Vendor No."));
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Currency Code", "Vendor Ledg. Entry No.", "Dimension Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure CopyFieldsFromVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        "Creditor No." := VendorLedgerEntry."Creditor No.";
        "Payment Reference" := VendorLedgerEntry."Payment Reference";
        "Exported to Payment File" := VendorLedgerEntry."Exported to Payment File";
        "Applies-to Ext. Doc. No." := VendorLedgerEntry."External Document No.";
        "Vendor Posting Group" := VendorLedgerEntry."Vendor Posting Group";
        "Remit-to Code" := VendorLedgerEntry."Remit-to Code";

        OnCopyFieldsFromVendorLedgerEntry(VendorLedgerEntry, Rec);
    end;

    procedure CopyFieldsToGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Creditor No." := "Creditor No.";
        GenJournalLine."Payment Reference" := "Payment Reference";
        GenJournalLine."Exported to Payment File" := "Exported to Payment File";
        GenJournalLine."Applies-to Ext. Doc. No." := "Applies-to Ext. Doc. No.";
        GenJournalLine."Posting Group" := "Vendor Posting Group";
        GenJournalLine."Remit-to Code" := "Remit-to Code";

        OnCopyFieldsToGenJournalLine(Rec, GenJournalLine);
    end;

    procedure CopyFieldsFromVendorPaymentBuffer(TempVendorPaymentBuffer: Record "Vendor Payment Buffer")
    begin
        Rec.TransferFields(TempVendorPaymentBuffer, true, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFieldsFromVendorLedgerEntry(VendorLedgerEntrySource: Record "Vendor Ledger Entry"; var PaymentBufferTarget: Record "Payment Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFieldsToGenJournalLine(PaymentBufferSource: Record "Payment Buffer"; var GenJournalLineTarget: Record "Gen. Journal Line")
    begin
    end;
}

 
#endif
