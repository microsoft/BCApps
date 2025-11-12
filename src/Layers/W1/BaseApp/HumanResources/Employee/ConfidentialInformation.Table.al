// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.HumanResources.Setup;

table 5216 "Confidential Information"
{
    Caption = 'Confidential Information';
    DataCaptionFields = "Employee No.";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;
        }
        field(2; "Confidential Code"; Code[10])
        {
            Caption = 'Confidential Code';
            NotBlank = true;
            TableRelation = Confidential;

            trigger OnValidate()
            begin
                Confidential.Get("Confidential Code");
                Description := Confidential.Description;
            end;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; Comment; Boolean)
        {
            CalcFormula = exist("HR Confidential Comment Line" where("Table Name" = const("Confidential Information"),
                                                                      "No." = field("Employee No."),
                                                                      "Code" = field("Confidential Code"),
                                                                      "Table Line No." = field("Line No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Employee No.", "Confidential Code", "Line No.")
        {
            Clustered = true;
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

    var
        Confidential: Record Confidential;

#pragma warning disable AA0074
        Text000: Label 'You can not delete confidential information if there are comments associated with it.';
#pragma warning restore AA0074
}

