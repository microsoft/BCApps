// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7106 "Exp. Policy To Eval Buffer"
{
    Access = Internal;
    TableType = Temporary;
    Caption = 'Expense Policy To Evaluate Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Subject System Id"; Guid)
        {
            Caption = 'Subject System Id';
        }
        field(2; "Policy System Id"; Guid)
        {
            Caption = 'Policy System Id';
        }
        field(10; "Subject Version"; Integer)
        {
            Caption = 'Subject Version';
        }
        field(11; "Policy Line No."; Integer)
        {
            Caption = 'Policy Line No.';
        }
        field(12; "Policy Version"; Integer)
        {
            Caption = 'Policy Version';
        }
        field(13; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
        }
        field(14; "Description"; Text[50])
        {
            Caption = 'Description';
        }
        field(15; "Policy Text"; Text[2048])
        {
            Caption = 'Policy Text';
        }
    }

    keys
    {
        key(PK; "Subject System Id", "Policy System Id")
        {
            Clustered = true;
        }
    }
}
