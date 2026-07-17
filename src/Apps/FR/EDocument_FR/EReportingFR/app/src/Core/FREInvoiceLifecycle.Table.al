// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;

table 10970 "FR E-Invoice Lifecycle"
{
    Caption = 'FR E-Invoice Lifecycle';
    DataClassification = CustomerContent;
    DrillDownPageId = "FR E-Invoice Lifecycles";
    LookupPageId = "FR E-Invoice Lifecycles";
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "E-Document"."Entry No";
        }
        field(3; "Lifecycle Status"; Enum "FR E-Invoice Lifecycle Status")
        {
            Caption = 'Lifecycle Status';
            DataClassification = SystemMetadata;
        }
        field(4; "Source Occurrence ID"; Guid)
        {
            Caption = 'Source Occurrence ID';
            DataClassification = SystemMetadata;
        }
        field(5; "Original Occurrence Entry No."; Integer)
        {
            Caption = 'Original Occurrence Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "FR E-Invoice Lifecycle"."Entry No.";
        }
        field(6; "Reported Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Reported Amount';
            DataClassification = CustomerContent;
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;
        }
        field(8; "Event Date"; Date)
        {
            Caption = 'Event Date';
            DataClassification = CustomerContent;
        }
        field(9; "Invoice Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Invoice Customer Ledger Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Cust. Ledger Entry"."Entry No.";
        }
        field(10; "Payment Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Payment Customer Ledger Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Cust. Ledger Entry"."Entry No.";
        }
        field(11; "Detailed Ledger Entry No."; Integer)
        {
            Caption = 'Detailed Customer Ledger Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Detailed Cust. Ledg. Entry"."Entry No.";
        }
        field(12; "E-Document Message Entry No."; Integer)
        {
            Caption = 'E-Document Message Entry No.';
            DataClassification = SystemMetadata;
        }
        field(13; "Processing Status"; Enum "FR E-Invoice Lifecycle Proc.")
        {
            Caption = 'Processing Status';
            DataClassification = SystemMetadata;
        }
        field(14; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(15; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            DataClassification = CustomerContent;
        }
        field(16; "Invoice Issue Date"; Date)
        {
            Caption = 'Invoice Issue Date';
            DataClassification = CustomerContent;
        }
        field(17; "Invoice Receipt At"; DateTime)
        {
            Caption = 'Invoice Receipt At';
            DataClassification = CustomerContent;
        }
        field(18; "Sender Platform ID"; Text[50])
        {
            Caption = 'Sender Platform ID';
            DataClassification = CustomerContent;
        }
        field(19; "Sender Platform Scheme"; Code[4])
        {
            Caption = 'Sender Platform Scheme';
            DataClassification = CustomerContent;
        }
        field(20; "Sender Platform Name"; Text[100])
        {
            Caption = 'Sender Platform Name';
            DataClassification = CustomerContent;
        }
        field(21; "Invoice Issuer ID"; Text[50])
        {
            Caption = 'Invoice Issuer ID';
            DataClassification = CustomerContent;
        }
        field(22; "Invoice Issuer Scheme"; Code[4])
        {
            Caption = 'Invoice Issuer Scheme';
            DataClassification = CustomerContent;
        }
        field(23; "Invoice Issuer Name"; Text[100])
        {
            Caption = 'Invoice Issuer Name';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Occurrence; "E-Document Entry No.", "Source Occurrence ID", "Lifecycle Status")
        {
            Unique = true;
        }
        key(EDocument; "E-Document Entry No.", "Created At")
        {
        }
        key(DetailedLedgerEntry; "Lifecycle Status", "Detailed Ledger Entry No.")
        {
        }
    }

    trigger OnModify()
    begin
        TestImmutableFields();
    end;

    trigger OnDelete()
    begin
        Error(ImmutableOccurrenceErr);
    end;

    local procedure TestImmutableFields()
    begin
        if (Rec."E-Document Entry No." <> xRec."E-Document Entry No.") or
           (Rec."Lifecycle Status" <> xRec."Lifecycle Status") or
           (Rec."Source Occurrence ID" <> xRec."Source Occurrence ID") or
           (Rec."Original Occurrence Entry No." <> xRec."Original Occurrence Entry No.") or
           (Rec."Reported Amount" <> xRec."Reported Amount") or
           (Rec."Currency Code" <> xRec."Currency Code") or
           (Rec."Event Date" <> xRec."Event Date") or
           (Rec."Invoice Cust. Ledger Entry No." <> xRec."Invoice Cust. Ledger Entry No.") or
           (Rec."Payment Cust. Ledger Entry No." <> xRec."Payment Cust. Ledger Entry No.") or
           (Rec."Detailed Ledger Entry No." <> xRec."Detailed Ledger Entry No.") or
              (Rec."Created At" <> xRec."Created At") or
              (Rec."Invoice Issue Date" <> xRec."Invoice Issue Date") or
              (Rec."Invoice Receipt At" <> xRec."Invoice Receipt At") or
              (Rec."Sender Platform ID" <> xRec."Sender Platform ID") or
              (Rec."Sender Platform Scheme" <> xRec."Sender Platform Scheme") or
              (Rec."Sender Platform Name" <> xRec."Sender Platform Name") or
              (Rec."Invoice Issuer ID" <> xRec."Invoice Issuer ID") or
              (Rec."Invoice Issuer Scheme" <> xRec."Invoice Issuer Scheme") or
              (Rec."Invoice Issuer Name" <> xRec."Invoice Issuer Name")
        then
            Error(ImmutableOccurrenceErr);
    end;

    var
        ImmutableOccurrenceErr: Label 'The regulatory identity and values of a French electronic invoice lifecycle occurrence cannot be changed.';
}