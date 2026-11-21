// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.Receivables;

table 3354 "MX Payment Complement"
{
    Caption = 'MX Payment Complement';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = X;
    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }

        field(2; "Payment Entry No."; Integer)
        {
            TableRelation = "Cust. Ledger Entry"."Entry No.";
            DataClassification = SystemMetadata;
        }

        field(3; "Parent E-Document Entry No."; Integer)
        {
            TableRelation = "E-Document"."Entry No";
            DataClassification = SystemMetadata;
        }

        field(4; "E-Document Message Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }

        field(5; "Source Occurrence ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }

        field(6; "Created At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }

        field(7; Reversed; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Stamped UUID"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Stamped UUID';
        }
        field(9; "PAC Response XML"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'PAC Response XML';
        }
        field(10; "Cancellation Status"; Enum "MX Compl. Cancel Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Cancellation Status';
        }
        field(11; "CFDI Cancellation ID"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'CFDI Cancellation ID';
        }
        field(12; "Cancellation Reason Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Cancellation Reason Code';
        }
        field(13; "Substitution UUID"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Substitution UUID';
        }
        field(14; "Date/Time Canceled"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Date/Time Canceled';
        }
        field(15; "Marked as Canceled"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Marked as Canceled';
        }
        field(16; "Cancellation Error"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Cancellation Error';
        }
        field(17; "Stamped At"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Stamped At';
        }
        field(18; "Cancellation Response XML"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Cancellation Response XML';
        }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Payment; "Payment Entry No.", Reversed) { }
        key(Message; "E-Document Message Entry No.") { }
    }
}