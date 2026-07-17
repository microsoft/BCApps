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
    }

    trigger OnModify()
    begin
        TestImmutableFields();
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
           (Rec."Created At" <> xRec."Created At")
        then
            Error(ImmutableOccurrenceErr);
    end;

    var
        ImmutableOccurrenceErr: Label 'The regulatory identity and values of a French electronic invoice lifecycle occurrence cannot be changed.';
}