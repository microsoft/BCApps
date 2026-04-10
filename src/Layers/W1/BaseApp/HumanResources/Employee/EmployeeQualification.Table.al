// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Setup;

table 5203 "Employee Qualification"
{
    Caption = 'Employee Qualification';
    DataCaptionFields = "Employee No.";
    DrillDownPageID = "Qualified Employees";
    LookupPageID = "Employee Qualifications";
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
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Qualification Code"; Code[10])
        {
            Caption = 'Qualification Code';
            ToolTip = 'Specifies a qualification code for the employee.';
            TableRelation = Qualification;

            trigger OnValidate()
            begin
                Qualification.Get("Qualification Code");
                Description := Qualification.Description;
            end;
        }
        field(4; "From Date"; Date)
        {
            Caption = 'From Date';
            ToolTip = 'Specifies the date when the employee started working on obtaining this qualification.';
        }
        field(5; "To Date"; Date)
        {
            Caption = 'To Date';
            ToolTip = 'Specifies the date when the employee is considered to have obtained this qualification.';
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies a type for the qualification, which specifies where the qualification was obtained.';
            OptionCaption = ' ,Internal,External,Previous Position';
            OptionMembers = " ",Internal,External,"Previous Position";
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the qualification.';
        }
        field(8; "Institution/Company"; Text[100])
        {
            Caption = 'Institution/Company';
            ToolTip = 'Specifies the institution from which the employee obtained the qualification.';
        }
        field(9; Cost; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Cost';
            ToolTip = 'Specifies the cost of the qualification.';
        }
        field(10; "Course Grade"; Text[50])
        {
            Caption = 'Course Grade';
            ToolTip = 'Specifies the grade that the employee received for the course, specified by the qualification on this line.';
        }
        field(11; "Employee Status"; Enum "Employee Status")
        {
            Caption = 'Employee Status';
            Editable = false;
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = exist("Human Resource Comment Line" where("Table Name" = const("Employee Qualification"),
                                                                     "No." = field("Employee No."),
                                                                     "Table Line No." = field("Line No.")));
            Caption = 'Comment';
            ToolTip = 'Specifies whether a comment was entered for this entry.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            ToolTip = 'Specifies the date when the qualification on this line expires.';
        }
    }

    keys
    {
        key(Key1; "Employee No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Qualification Code")
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
    begin
        Employee.Get("Employee No.");
        "Employee Status" := Employee.Status;
    end;

    var
        Qualification: Record Qualification;
        Employee: Record Employee;

#pragma warning disable AA0074
        Text000: Label 'You cannot delete employee qualification information if there are comments associated with it.';
#pragma warning restore AA0074
}

