// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46946 "BC14 Value Entry"
{
    Caption = 'Value Entry Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = false;
        }
        field(11; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
        }
        field(13; "Item Ledger Entry Quantity"; Decimal)
        {
            Caption = 'Item Ledger Entry Quantity';
            AutoFormatType = 0;
        }
        field(43; "Cost Amount (Actual)"; Decimal)
        {
            Caption = 'Cost Amount (Actual)';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item Ledger Entry No.")
        {
            SumIndexFields = "Cost Amount (Actual)", "Item Ledger Entry Quantity";
        }
    }
}
