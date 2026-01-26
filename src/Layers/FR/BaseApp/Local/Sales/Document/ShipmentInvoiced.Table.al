// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

table 10825 "Shipment Invoiced"
{
    Caption = 'Shipment Invoiced';
    DrillDownPageID = "Invoices bound by Shipment";
    LookupPageID = "Invoices bound by Shipment";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
        }
        field(2; "Invoice Line No."; Integer)
        {
            Caption = 'Invoice Line No.';
        }
        field(3; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
        }
        field(4; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
        }
        field(10; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Qty. to Ship"; Decimal)
        {
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(20; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
    }

    keys
    {
        key(Key1; "Invoice No.", "Invoice Line No.", "Shipment No.", "Shipment Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Shipment No.", "Shipment Line No.")
        {
        }
    }

    fieldgroups
    {
    }
}

