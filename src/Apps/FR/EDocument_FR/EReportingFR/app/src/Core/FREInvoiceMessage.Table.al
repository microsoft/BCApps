// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

table 10970 "FR E-Invoice Message"
{
    Access = Internal;
    Caption = 'FR E-Invoice Message';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = X;
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
        field(3; Type; Enum "FR E-Invoice Message Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(4; "Source Occurrence ID"; Guid)
        {
            Caption = 'Source Occurrence ID';
            DataClassification = SystemMetadata;
        }
        field(5; "Original Entry No."; Integer)
        {
            Caption = 'Original Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "FR E-Invoice Message"."Entry No.";
        }
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = CustomerContent;
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }
        field(8; "Event Date"; Date)
        {
            Caption = 'Event Date';
            DataClassification = CustomerContent;
        }
        field(9; "Detailed Ledger Entry No."; Integer)
        {
            Caption = 'Detailed Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Reason Code"; Code[20])
        {
            Caption = 'Reason Code';
            DataClassification = CustomerContent;
        }
        field(11; "Reason Description"; Text[500])
        {
            Caption = 'Reason Description';
            DataClassification = CustomerContent;
        }
        field(12; "E-Document Message Entry No."; Integer)
        {
            Caption = 'E-Document Message Entry No.';
            DataClassification = SystemMetadata;
        }
        field(13; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(14; "External Message ID"; Text[250])
        {
            Caption = 'External Message ID';
            DataClassification = CustomerContent;
        }
        field(15; "Received At"; DateTime)
        {
            Caption = 'Received At';
            DataClassification = SystemMetadata;
        }
        field(16; "Sender Platform ID"; Text[50])
        {
            Caption = 'Sender Platform ID';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(17; "Sender Platform Scheme"; Code[4])
        {
            Caption = 'Sender Platform Scheme';
            DataClassification = SystemMetadata;
        }
        field(18; "Sender Platform Name"; Text[100])
        {
            Caption = 'Sender Platform Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(19; "Invoice Issue Date"; Date)
        {
            Caption = 'Invoice Issue Date';
            DataClassification = CustomerContent;
        }
        field(20; "Invoice Receipt At"; DateTime)
        {
            Caption = 'Invoice Receipt At';
            DataClassification = CustomerContent;
        }
        field(21; "Invoice Issuer ID"; Text[50])
        {
            Caption = 'Invoice Issuer ID';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(22; "Invoice Issuer Scheme"; Code[4])
        {
            Caption = 'Invoice Issuer Scheme';
            DataClassification = SystemMetadata;
        }
        field(23; "Invoice Issuer Name"; Text[100])
        {
            Caption = 'Invoice Issuer Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Occurrence; "E-Document Entry No.", "Source Occurrence ID", Type)
        {
            Unique = true;
        }
        key(DetailedLedgerEntry; Type, "Detailed Ledger Entry No.")
        {
        }
        key(EDocumentMessage; "E-Document Message Entry No.")
        {
        }
    }
}