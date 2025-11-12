// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using System.Security.AccessControl;

table 9155 "My Time Sheets"
{
    Caption = 'My Time Sheets';
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
        field(2; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            Description = 'Specifies the number of the time sheet.';
        }
        field(3; "Start Date"; Date)
        {
            Caption = 'Start Date';
            Description = 'Specifies the start date of the assignment.';
        }
        field(4; "End Date"; Date)
        {
            Caption = 'End Date';
            Description = 'Specifies the end date of the assignment.';
        }
        field(5; Comment; Boolean)
        {
            Caption = 'Comment';
            Description = 'Specifies if any comments are available about the assignment.';
        }
    }

    keys
    {
        key(Key1; "User ID", "Time Sheet No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

