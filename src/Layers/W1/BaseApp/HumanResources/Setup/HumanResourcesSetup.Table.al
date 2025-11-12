// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Setup;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Absence;

table 5218 "Human Resources Setup"
{
    Caption = 'Human Resources Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Human Resources Setup";
    LookupPageID = "Human Resources Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Employee Nos."; Code[20])
        {
            Caption = 'Employee Nos.';
            TableRelation = "No. Series";
        }
        field(3; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Human Resource Unit of Measure";

            trigger OnValidate()
            var
                EmployeeAbsence: Record "Employee Absence";
                HumanResUnitOfMeasure: Record "Human Resource Unit of Measure";
            begin
                if "Base Unit of Measure" <> xRec."Base Unit of Measure" then
                    if not EmployeeAbsence.IsEmpty() then
                        Error(ChangeNotAllowedErr, FieldCaption("Base Unit of Measure"), EmployeeAbsence.TableCaption());

                HumanResUnitOfMeasure.Get("Base Unit of Measure");
                HumanResUnitOfMeasure.TestField("Qty. per Unit of Measure", 1);
            end;
        }
        field(4; "Automatically Create Resource"; Boolean)
        {
            Caption = 'Automatically Create Resource';
            DataClassification = SystemMetadata;
        }
        field(175; "Allow Multiple Posting Groups"; Boolean)
        {
            Caption = 'Allow Multiple Posting Groups';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies if multiple posting groups can be used for the same employee in a general journal or payment document.';
        }
        field(176; "Check Multiple Posting Groups"; enum "Posting Group Change Method")
        {
            Caption = 'Check Multiple Posting Groups';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies implementation method of checking which posting groups can be used for the employee.';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0470
        ChangeNotAllowedErr: Label 'You cannot change %1 because there are %2.';
#pragma warning restore AA0470
}

