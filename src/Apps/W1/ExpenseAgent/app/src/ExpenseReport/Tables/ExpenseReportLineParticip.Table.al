// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;

table 6908 "Expense Report Line Particip."
{
    Access = Internal;
    Caption = 'Expense Report Line Participants';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Report Line Particips";
    ReplicateData = false;

    fields
    {
        field(1; "Expense Report No."; Code[20])
        {
            Caption = 'Expense Report No.';
            TableRelation = "Expense Report Header"."No.";
        }
        field(2; "Expense Report Line No."; Integer)
        {
            Caption = 'Expense Report Line No.';
            TableRelation = "Expense Report Line"."Line No." where("Document No." = field("Expense Report No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
        }
        field(6; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            TableRelation = "Expense Category".Code where(Inactive = const(false));
        }
        field(7; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            TableRelation = "Expense SubCategory".Code where("Expense Category Code" = field("Expense Category Code"), Inactive = const(false));
        }
        field(8; "Participant Type"; Enum "Expense Participant Type")
        {
            Caption = 'Participant Type';

            trigger OnValidate()
            var
                CompanyInformation: Record "Company Information";
            begin
                TestStatusOpenOfExpenseReport();

                if Rec."Participant Type" <> xRec."Participant Type" then begin
                    Rec.Validate("Participant Employee No.", '');
                    ClearParticipantsInformation();
                end;

                if Rec."Participant Type" = Rec."Participant Type"::Employee then begin
                    CompanyInformation.Get();
                    Rec."Participant Organization" := CompanyInformation.Name;
                end;
            end;
        }
        field(9; "Participant Employee No."; Code[20])
        {
            Caption = 'Participant Employee No.';
            TableRelation = if ("Participant Type" = const(Employee)) Employee."No.";

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                if Rec."Participant Employee No." <> '' then
                    Rec.TestField("Participant Type", Rec."Participant Type"::Employee);

                if Rec."Participant Employee No." <> xRec."Participant Employee No." then
                    ClearParticipantsInformation();

                if (rec."Participant Type" = Rec."Participant Type"::Employee) and (Rec."Participant Employee No." <> '') then
                    UpdateParticipantForEmployee(Rec."Participant Employee No.");
            end;
        }
        field(10; "Participant Name"; Text[100])
        {
            Caption = 'Participant Name';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                CheckEmployeeMandatory();
            end;
        }
        field(11; "Participant Organization"; Text[100])
        {
            Caption = 'Participant Organization';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                CheckEmployeeMandatory();
            end;
        }
        field(12; "Participant Country/Region"; Code[10])
        {
            Caption = 'Participant Country/Region';
            TableRelation = "Country/Region".Code;

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                CheckEmployeeMandatory();
            end;
        }
        field(13; "Participant Title"; Text[30])
        {
            Caption = 'Participant Title';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                CheckEmployeeMandatory();
            end;
        }
        field(14; "Participant Email"; Text[80])
        {
            Caption = 'Participant Email';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                CheckEmployeeMandatory();
            end;
        }
    }

    keys
    {
        key(PK; "Expense Report No.", "Expense Report Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Expense Report No.");
        TestField("Expense Report Line No.");
        TestField("Line No.");

        TestStatusOpenOfExpenseReport();
        UpdateExpenseReportLineInformation("Expense Report No.", "Expense Report Line No.");

        InvalidateParentPolicy();
    end;

    trigger OnModify()
    begin
        InvalidateParentPolicy();
    end;

    trigger OnDelete()
    begin
        TestStatusOpenOfExpenseReport();

        InvalidateParentPolicy();
    end;

    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHelper: Codeunit "Expense Report";

    local procedure InvalidateParentPolicy()
    var
        ParentExpenseReportLine: Record "Expense Report Line";
    begin
        if ParentExpenseReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.") then
            ParentExpenseReportLine.InvalidatePolicyEvaluation();
    end;

    local procedure UpdateExpenseReportLineInformation(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer)
    begin
        ExpenseReportLine := ExpenseReportHelper.GetExpenseReportLine(ExpenseReportNo, ExpenseReportLineNo);

        Rec.Validate("Expense No.", ExpenseReportLine."Expense No.");
        Rec.Validate("Expense Category Code", ExpenseReportLine."Expense Category");
    end;

    local procedure ClearParticipantsInformation()
    begin
        Rec."Participant Name" := '';
        Rec."Participant Title" := '';
        Rec."Participant Organization" := '';
        Rec."Participant Country/Region" := '';
        Rec."Participant Email" := '';
    end;

    local procedure UpdateParticipantForEmployee(EmployeeNo: Code[20])
    var
        Employee: Record Employee;
        CompanyInformation: Record "Company Information";
    begin
        Employee.Get(EmployeeNo);
        CompanyInformation.Get();

        Rec."Participant Name" := Employee."First Name" + ' ' + Employee."Last Name";
        Rec."Participant Organization" := CompanyInformation.Name;
        Rec."Participant Country/Region" := Employee."Country/Region Code";
        Rec."Participant Title" := Employee."Job Title";
        Rec."Participant Email" := Employee."Company E-Mail";
    end;

    local procedure CheckEmployeeMandatory()
    begin
        if not (Rec."Participant Type" = Rec."Participant Type"::Employee) then
            exit;

        Rec.TestField("Participant Employee No.");
    end;

    local procedure TestStatusOpenOfExpenseReport()
    var
        ExpReportLine: Record "Expense Report Line";
    begin
        ExpReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.");

        ExpReportLine.TestStatusOpen();
    end;
}