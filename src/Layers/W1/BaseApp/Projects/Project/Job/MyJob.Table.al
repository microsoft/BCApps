// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using System.Security.AccessControl;

table 9154 "My Job"
{
    Caption = 'My Project';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the project numbers that are displayed in the My Project Cue on the Role Center.';
            NotBlank = true;
            TableRelation = Job;
        }
        field(3; "Exclude from Business Chart"; Boolean)
        {
            Caption = 'Exclude from Business Chart';
            ToolTip = 'Specifies if this project should appear in the business charts for this role center.';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the project.';
        }
        field(5; Status; Enum "Job Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the project''s status.';
            InitValue = Open;
        }
        field(6; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
        }
        field(7; "Percent Completed"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Percent Completed';
            ToolTip = 'Specifies the completion rate of the project.';
        }
        field(8; "Percent Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Percent Invoiced';
            ToolTip = 'Specifies how much of the project has been invoiced.';
        }
    }

    keys
    {
        key(Key1; "User ID", "Job No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

