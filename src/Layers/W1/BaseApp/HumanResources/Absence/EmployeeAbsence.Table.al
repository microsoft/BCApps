// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Absence;

using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;

table 5207 "Employee Absence"
{
    Caption = 'Employee Absence';
    DataCaptionFields = "Employee No.";
    DrillDownPageID = "Employee Absences";
    LookupPageID = "Employee Absences";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            ToolTip = 'Specifies a number for the employee.';
            NotBlank = true;
            TableRelation = Employee;

            trigger OnValidate()
            begin
                Employee.Get("Employee No.");
                if Employee."Privacy Blocked" then
                    Error(BlockedErr);
            end;
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "From Date"; Date)
        {
            Caption = 'From Date';
            ToolTip = 'Specifies the first day of the employee''s absence registered on this line.';
        }
        field(4; "To Date"; Date)
        {
            Caption = 'To Date';
            ToolTip = 'Specifies the last day of the employee''s absence registered on this line.';
        }
        field(5; "Cause of Absence Code"; Code[10])
        {
            Caption = 'Cause of Absence Code';
            ToolTip = 'Specifies a cause of absence code to define the type of absence.';
            TableRelation = "Cause of Absence";

            trigger OnValidate()
            begin
                CauseOfAbsence.Get("Cause of Absence Code");
                Description := CauseOfAbsence.Description;
                Validate("Unit of Measure Code", CauseOfAbsence."Unit of Measure Code");
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the absence.';
        }
        field(7; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity associated with absences, in hours or days.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Quantity (Base)" := UOMMgt.CalcBaseQty(Quantity, "Qty. per Unit of Measure");
            end;
        }
        field(8; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Human Resource Unit of Measure";

            trigger OnValidate()
            begin
                HumanResUnitOfMeasure.Get("Unit of Measure Code");
                "Qty. per Unit of Measure" := HumanResUnitOfMeasure."Qty. per Unit of Measure";
                Validate(Quantity);
            end;
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("Human Resource Comment Line" where("Table Name" = const("Employee Absence"),
                                                                     "Table Line No." = field("Entry No.")));
            Caption = 'Comment';
            ToolTip = 'Specifies if a comment is associated with this entry.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(13; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "From Date")
        {
            SumIndexFields = Quantity, "Quantity (Base)";
        }
        key(Key3; "Employee No.", "Cause of Absence Code", "From Date")
        {
            SumIndexFields = Quantity, "Quantity (Base)";
        }
        key(Key4; "Cause of Absence Code", "From Date")
        {
            SumIndexFields = Quantity, "Quantity (Base)";
        }
        key(Key5; "From Date", "To Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        EmployeeAbsence.SetCurrentKey("Entry No.");
        if EmployeeAbsence.FindLast() then
            "Entry No." := EmployeeAbsence."Entry No." + 1
        else begin
            CheckBaseUOM();
            "Entry No." := 1;
        end;
    end;

    var
        CauseOfAbsence: Record "Cause of Absence";
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        HumanResUnitOfMeasure: Record "Human Resource Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";

        BlockedErr: Label 'You cannot register absence because the employee is blocked due to privacy.';

    local procedure CheckBaseUOM()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("Base Unit of Measure");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var EmployeeAbsence: Record "Employee Absence"; var IsHandled: Boolean)
    begin
    end;
}

