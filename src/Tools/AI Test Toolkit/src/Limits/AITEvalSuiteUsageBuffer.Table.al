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
            Caption = 'Eval Suite Code';
            ToolTip = 'Specifies the code of the eval suite.';
        }
        field(3; Consumed; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Consumed';
            ToolTip = 'Specifies the total number of consumption units consumed by this eval suite during the specified period.';
            MinValue = 0;
            DecimalPlaces = 2 : 5;
        }
        field(4; "Suite Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the eval suite.';
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
        key(Consumed; Consumed)
        {
        }
    }
}