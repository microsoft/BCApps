// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

table 962 "Alt. Employee Posting Group"
{
    Caption = 'Alternative Employee Posting Group';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee Posting Group"; Code[20])
        {
            Caption = 'Employee Posting Group';
            TableRelation = "Employee Posting Group";
        }
        field(2; "Alt. Employee Posting Group"; Code[20])
        {
            Caption = 'Alternative Employee Posting Group';
            TableRelation = "Employee Posting Group";
            ToolTip = 'Specifies the employee group for posting business transactions to general ledger accounts.';

            trigger OnValidate()
            begin
                if "Employee Posting Group" = "Alt. Employee Posting Group" then
                    Error(PostingGroupReplaceErr);
            end;
        }
    }

    keys
    {
        key(Key1; "Employee Posting Group", "Alt. Employee Posting Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PostingGroupReplaceErr: Label 'Posting Group cannot replace itself.';
}

