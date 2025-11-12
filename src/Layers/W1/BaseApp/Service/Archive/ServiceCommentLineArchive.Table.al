// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Service.Comment;
using Microsoft.Service.Contract;

table 6013 "Service Comment Line Archive"
{
    Caption = 'Service Comment Line Archive';
    DataCaptionFields = Type, "No.", "Doc. No. Occurrence", "Version No.";
    DrillDownPageID = "Service Archive Comment Sheet";
    LookupPageID = "Service Archive Comment Sheet";
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
            TableRelation = if ("Table Name" = const("Service Contract")) "Service Contract Header"."Contract No."
            else
            if ("Table Name" = const("Service Header")) "Service Header Archive"."No." where("Document Type" = field("Table Subtype"),
                                                                                             "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                                             "Version No." = field("Version No."));
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
        }
        field(7; "Comment Date"; Date)
        {
            Caption = 'Comment Date';
        }
        field(8; "Table Subtype"; Enum "Service Comment Table Subtype")
        {
            Caption = 'Table Subtype';
        }
        field(9; "Table Name"; Enum "Service Comment Table Name")
        {
            Caption = 'Table Name';
        }
        field(10; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(11; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
    }

    keys
    {
        key(Key1; "Table Name", "Table Subtype", "No.", Type, "Doc. No. Occurrence", "Version No.", "Table Line No.", "Line No.")
        {
            Clustered = true;
        }
    }
}