// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

table 957 "Time Sheet Cmt. Line Archive"
{
    Caption = 'Time Sheet Cmt. Line Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date when a comment was entered for an archived time sheet.';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for a comment for an archived time sheet.';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies the comment relating to an archived time sheet or time sheet line.';
        }
    }

    keys
    {
        key(Key1; "No.", "Time Sheet Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

