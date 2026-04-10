// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Comment;

table 5138 "Comment Line Archive"
{
    Caption = 'Comment Line Archive';
    DrillDownPageID = "Comment Archive List";
    LookupPageID = "Comment Archive List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Enum "Comment Line Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date the comment was created.';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the comment.';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies the comment itself.';
        }
        field(20; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Version No.", "Line No.")
        {
            Clustered = true;
        }
    }
}

