// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

table 924 "Vendor Purchase Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
            DataClassification = SystemMetadata;
        }
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
            ToolTip = 'Specifies the name of the period that you want to view.';
            DataClassification = SystemMetadata;
        }
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            ToolTip = 'Specifies purchase statistics for each vendor for a period of time, starting on the date that you specify.';
            DataClassification = SystemMetadata;
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        field(10; "Balance Due (LCY)"; Decimal)
        {
            Caption = 'Balance Due (LCY)';
            DataClassification = SystemMetadata;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(11; "Purchases (LCY)"; Decimal)
        {
            Caption = 'Purchases (LCY)';
            DataClassification = SystemMetadata;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
    }
}
