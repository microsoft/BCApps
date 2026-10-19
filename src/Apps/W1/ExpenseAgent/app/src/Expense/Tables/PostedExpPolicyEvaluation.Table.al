// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7105 "Posted Exp. Policy Evaluation"
{
    Access = Internal;
    Caption = 'Posted Expense Policy Evaluation';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Subject System Id"; Guid)
        {
            Caption = 'Subject System Id';
            DataClassification = CustomerContent;
        }
        field(2; "Policy System Id"; Guid)
        {
            Caption = 'Policy System Id';
            DataClassification = CustomerContent;
            TableRelation = "Expense Policy".SystemId;
        }
        field(3; "Subject Version"; Integer)
        {
            Caption = 'Subject Version';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Policy Version"; Integer)
        {
            Caption = 'Policy Version';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "Subject Type"; Enum "Expense Policy Subject")
        {
            Caption = 'Subject Type';
            DataClassification = CustomerContent;
        }
        field(6; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            DataClassification = CustomerContent;
        }
        field(7; "Reason"; Text[2048])
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
        }
        field(8; "Policy Text"; Text[2048])
        {
            Caption = 'Policy Text';
            DataClassification = CustomerContent;
        }
        field(9; "Evaluated At"; DateTime)
        {
            Caption = 'Evaluated At';
            DataClassification = CustomerContent;
        }
        field(10; "Compliant"; Boolean)
        {
            Caption = 'Compliant';
            DataClassification = CustomerContent;
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
        key(PK; "Subject Type", "Subject System Id", "Policy System Id", "Subject Version", "Policy Version")
        {
            Clustered = true;
        }
        key(Category; "Expense Category Code")
        {
        }
        key(EvaluatedAt; "Evaluated At")
        {
        }
    }
}
