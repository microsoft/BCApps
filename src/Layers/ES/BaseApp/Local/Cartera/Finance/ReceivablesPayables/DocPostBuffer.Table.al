// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

table 7000011 "Doc. Post. Buffer"
{
    Caption = 'Doc. Post. Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "No. of Days"; Integer)
        {
            Caption = 'No. of Days';
        }
        field(3; Amount; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

