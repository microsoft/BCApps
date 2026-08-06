// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7105 "Posted Exp. Policy Flag"
{
    Access = Internal;
    Caption = 'Posted Expense Policy Flag';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Subject System Id"; Guid)
        {
            Caption = 'Subject System Id';
        }
        field(2; "Policy System Id"; Guid)
        {
            Caption = 'Policy System Id';
            TableRelation = "Expense Policy".SystemId;
        }
        field(3; "Subject Version"; Integer)
        {
            Caption = 'Subject Version';
            Editable = false;
        }
        field(4; "Policy Version"; Integer)
        {
            Caption = 'Policy Version';
            Editable = false;
        }
        field(5; "Subject Type"; Enum "Expense Policy Subject")
        {
            Caption = 'Subject Type';
        }
        field(6; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
        }
        field(7; "Description"; Text[2048])
        {
            Caption = 'Description';
        }
        field(8; "Policy Text"; Text[2048])
        {
            Caption = 'Policy Text';
        }
        field(9; "Flagged At"; DateTime)
        {
            Caption = 'Flagged At';
        }
        field(10; "Compliant"; Boolean)
        {
            Caption = 'Compliant';
        }
        field(11; "Policy Line No."; Integer)
        {
            Caption = 'Policy Line No.';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense Policy"."Line No." where(SystemId = field("Policy System Id")));
            Editable = false;
        }
        field(12; "Is Current"; Boolean)
        {
            Caption = 'Is Current';
            FieldClass = FlowField;
            CalcFormula = exist("Expense Policy" where(SystemId = field("Policy System Id"), "Version" = field("Policy Version")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Subject System Id", "Policy System Id", "Subject Version", "Policy Version")
        {
            Clustered = true;
        }
        key(Category; "Expense Category Code")
        {
        }
    }
}
