// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

table 149041 "AIT Eval Suite Usage Buffer"
{
    Access = Internal;
    Caption = 'AI Eval Suite Usage Buffer';
    TableType = Temporary;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; Index; Integer)
        {
            Caption = 'Index';
            ToolTip = 'Specifies the order of the records.';
        }
        field(2; "Suite Code"; Code[10])
        {
            Caption = 'Suite Code';
            ToolTip = 'Specifies the code of the eval suite.';
        }
        field(3; "Suite Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the eval suite.';
        }
        field(4; "Environment Consumed"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Units Consumed (Environment)';
            ToolTip = 'Specifies the total number of consumption units consumed by this eval suite across all companies in the environment during the specified period.';
            MinValue = 0;
            DecimalPlaces = 2 : 5;
        }
        field(5; "Company Consumed"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Units Consumed (Company)';
            ToolTip = 'Specifies the total number of consumption units consumed by this eval suite in the current company during the specified period.';
            MinValue = 0;
            DecimalPlaces = 2 : 5;
        }
    }

    keys
    {
        key(PK; Index)
        {
            Clustered = true;
        }
        key(Code; "Suite Code")
        {
        }
        key(Consumed; "Environment Consumed")
        {
        }
    }
}