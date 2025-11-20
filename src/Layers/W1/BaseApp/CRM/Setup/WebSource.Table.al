// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Comment;

table 5059 "Web Source"
{
    Caption = 'Web Source';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Web Sources";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; URL; Text[250])
        {
            Caption = 'URL';
        }
        field(4; Comment; Boolean)
        {
            CalcFormula = exist("Rlshp. Mgt. Comment Line" where("Table Name" = const("Web Source"),
                                                                  "No." = field(Code),
                                                                  "Sub No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::"Web Source");
        RMCommentLine.SetRange("No.", Code);
        RMCommentLine.DeleteAll();
    end;

    var
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
}

