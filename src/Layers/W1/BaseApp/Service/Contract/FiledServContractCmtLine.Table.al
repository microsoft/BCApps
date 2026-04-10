// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Service.Comment;

table 5974 "Filed Serv. Contract Cmt. Line"
{
    Caption = 'Filed Service Contract Comment Line';
    DataCaptionFields = Type, "No.";
    DrillDownPageID = "Filed Serv. Contract Cm. Sheet";
    LookupPageID = "Filed Serv. Contract Cm. Sheet";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Service Comment Line Type")
        {
            Caption = 'Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if ("Table Name" = const("Service Contract")) "Filed Service Contract Header"."Contract No.";
        }
        field(3; "Table Line No."; Integer)
        {
            Caption = 'Table Line No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies the comment itself.';
        }
        field(7; "Comment Date"; Date)
        {
            Caption = 'Comment Date';
            ToolTip = 'Specifies the date when the comment was created.';
        }
        field(8; "Table Subtype"; Enum "Service Comment Table Subtype")
        {
            Caption = 'Table Subtype';
        }
        field(9; "Table Name"; Enum "Service Comment Table Name")
        {
            Caption = 'Table Name';
        }
        field(100; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique number of filed service contract or service contract quote.';
        }
    }

    keys
    {
        key(Key1; "Entry No.", Type, "Table Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.")
        {
        }
    }
}