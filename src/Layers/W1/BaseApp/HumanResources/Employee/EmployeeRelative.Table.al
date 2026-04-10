// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Setup;

table 5205 "Employee Relative"
{
    Caption = 'Employee Relative';
    DataCaptionFields = "Employee No.";
    DrillDownPageID = "Employee Relatives";
    LookupPageID = "Employee Relatives";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Relative Code"; Code[10])
        {
            Caption = 'Relative Code';
            ToolTip = 'Specifies a relative code for the employee.';
            TableRelation = Relative;
        }
        field(4; "First Name"; Text[30])
        {
            Caption = 'First Name';
            ToolTip = 'Specifies the first name of the employee''s relative.';
        }
        field(5; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';
            ToolTip = 'Specifies the middle name of the employee''s relative.';
        }
        field(6; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
        }
        field(7; "Birth Date"; Date)
        {
            Caption = 'Birth Date';
            ToolTip = 'Specifies the relative''s date of birth.';
        }
        field(8; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ToolTip = 'Specifies the relative''s telephone number.';
            ExtendedDatatype = PhoneNo;
        }
        field(9; "Relative's Employee No."; Code[20])
        {
            Caption = 'Relative''s Employee No.';
            TableRelation = Employee;
        }
        field(10; Comment; Boolean)
        {
            CalcFormula = exist("Human Resource Comment Line" where("Table Name" = const("Employee Relative"),
                                                                     "No." = field("Employee No."),
                                                                     "Table Line No." = field("Line No.")));
            Caption = 'Comment';
            ToolTip = 'Specifies if a comment was entered for this entry.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Employee No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        HRCommentLine: Record "Human Resource Comment Line";
    begin
        HRCommentLine.SetRange("Table Name", HRCommentLine."Table Name"::"Employee Relative");
        HRCommentLine.SetRange("No.", "Employee No.");
        HRCommentLine.DeleteAll();
    end;
}

