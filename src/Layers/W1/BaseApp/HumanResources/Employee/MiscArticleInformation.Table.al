// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Setup;

table 5214 "Misc. Article Information"
{
    Caption = 'Misc. Article Information';
    DataCaptionFields = "Employee No.";
    DrillDownPageID = "Misc. Article Information";
    LookupPageID = "Misc. Article Information";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            ToolTip = 'Specifies a number for the employee.';
            NotBlank = true;
            TableRelation = Employee;
        }
        field(2; "Misc. Article Code"; Code[10])
        {
            Caption = 'Misc. Article Code';
            ToolTip = 'Specifies a code to define the type of miscellaneous article.';
            NotBlank = true;
            TableRelation = "Misc. Article";

            trigger OnValidate()
            begin
                MiscArticle.Get("Misc. Article Code");
                Description := MiscArticle.Description;
            end;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the miscellaneous article.';
        }
        field(5; "From Date"; Date)
        {
            Caption = 'From Date';
            ToolTip = 'Specifies the date when the employee first received the miscellaneous article.';
        }
        field(6; "To Date"; Date)
        {
            Caption = 'To Date';
            ToolTip = 'Specifies the date when the employee no longer possesses the miscellaneous article.';
        }
        field(7; "In Use"; Boolean)
        {
            Caption = 'In Use';
            ToolTip = 'Specifies that the miscellaneous article is in use.';
        }
        field(8; Comment; Boolean)
        {
            CalcFormula = exist("Human Resource Comment Line" where("Table Name" = const("Misc. Article Information"),
                                                                     "No." = field("Employee No."),
                                                                     "Alternative Address Code" = field("Misc. Article Code"),
                                                                     "Table Line No." = field("Line No.")));
            Caption = 'Comment';
            ToolTip = 'Specifies if a comment is associated with this entry.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Serial No."; Text[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number of the miscellaneous article.';
        }
    }

    keys
    {
        key(Key1; "Employee No.", "Misc. Article Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Comment then
            Error(Text000);
    end;

    trigger OnInsert()
    var
        MiscArticleInfo: Record "Misc. Article Information";
    begin
        MiscArticleInfo.SetCurrentKey("Line No.");
        if MiscArticleInfo.FindLast() then
            "Line No." := MiscArticleInfo."Line No." + 1
        else
            "Line No." := 1;
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You cannot delete information if there are comments associated with it.';
#pragma warning restore AA0074
        MiscArticle: Record "Misc. Article";
}

