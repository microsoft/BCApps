// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Text;

table 134833 "Amount AutoFormat Currency"
{
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }
        field(2; Case1LCY; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies Case 1, Amount, LCY';
            Caption = 'Case 1 LCY';
        }
        field(3; Case1FCY; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            ToolTip = 'Specifies Case 1, Amount, Currency';
            Caption = 'Case 1 FCY';
        }
        field(4; Case2LCY; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            ToolTip = 'Specifies Case 2, Unit Amount, LCY';
            Caption = 'Case 2 LCY';
        }
        field(5; Case2FCY; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = Rec."Currency Code";
            ToolTip = 'Specifies Case 2, Unit Amount, Currency';
            Caption = 'Case 2 FCY';
        }
        field(6; Case4LCY; Decimal)
        {
            AutoFormatType = 4;
            AutoFormatExpression = '';
            ToolTip = 'Specifies Case 4, Amount, No Currency';
            Caption = 'Case 4 LCY';
        }
        field(7; Case4FCY; Decimal)
        {
            AutoFormatType = 4;
            AutoFormatExpression = Rec."Currency Code";
            ToolTip = 'Specifies Case 4, Amount, No Currency';
            Caption = 'Case 4 FCY';
        }
        field(8; Case5LCY; Decimal)
        {
            AutoFormatType = 5;
            AutoFormatExpression = '';
            ToolTip = 'Specifies Case 5, Unit Amount, No Currency';
            Caption = 'Case 5 LCY';
        }
        field(9; Case5FCY; Decimal)
        {
            AutoFormatType = 5;
            AutoFormatExpression = Rec."Currency Code";
            ToolTip = 'Specifies Case 5, Unit Amount, No Currency';
            Caption = 'Case 5 FCY';
        }
        field(100; "Currency Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Currency Code';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}