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
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Payment; "Payment Entry No.") { Unique = true; }
        key(Message; "E-Document Message Entry No.") { }
    }
}
