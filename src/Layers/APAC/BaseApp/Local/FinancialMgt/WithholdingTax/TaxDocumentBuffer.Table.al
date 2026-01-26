// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

table 28080 "Tax Document Buffer"
{
    Caption = 'Tax Document Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; "Payment Discount %"; Integer)
        {
            Caption = 'Payment Discount %';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Bill-to Customer No.", "Currency Code", "Payment Discount %")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

