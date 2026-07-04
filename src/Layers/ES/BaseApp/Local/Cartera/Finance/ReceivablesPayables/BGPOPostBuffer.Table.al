// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Dimension;

table 7000012 "BG/PO Post. Buffer"
{
    Caption = 'BG/PO Post. Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Account; Code[20])
        {
            Caption = 'Account';
        }
        field(2; "Balance Account"; Code[20])
        {
            Caption = 'Balance Account';
        }
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
        }
        field(4; "Gain - Loss Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Gain - Loss Amount (LCY)';
        }
        field(5; "Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
        }
        field(6; "Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
        }
        field(7; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; Account, "Balance Account", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

