// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;

table 6904 "Expense Participant"
{
    Access = Internal;
    Caption = 'Expense Participants';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Participants";
    ReplicateData = false;

    fields
    {
        field(1; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";

            trigger OnValidate()
            begin
                UpdateExpenseInformation("Expense No.");
            end;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            TableRelation = "Expense Category".Code where(Inactive = const(false));
        }
        field(5; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            TableRelation = "Expense SubCategory".Code where("Expense Category Code" = field("Expense Category Code"), Inactive = const(false));
        }
        field(6; "Participant Type"; Enum "Expense Participant Type")
        {
            Caption = 'Participant Type';

            trigger OnValidate()
            var
                CompanyInformation: Record "Company Information";
            begin
                TestStatusOpenOfExpense();

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
        field(7; "Participant Employee No."; Code[20])
        {
            Caption = 'Participant Employee No.';
            TableRelation = if ("Participant Type" = const(Employee)) Employee."No.";

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                if Rec."Participant Employee No." <> '' then
                    Rec.TestField("Participant Type", Rec."Participant Type"::Employee);

                if Rec."Participant Employee No." <> xRec."Participant Employee No." then
                    ClearParticipantsInformation();

                if (rec."Participant Type" = Rec."Participant Type"::Employee) and (Rec."Participant Employee No." <> '') then
                    UpdateParticipantForEmployee(Rec."Participant Employee No.");
            end;
        }
        field(8; "Participant Name"; Text[100])
        {
            Caption = 'Participant Name';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                CheckEmployeeMandatory();
            end;
        }
        field(9; "Participant Organization"; Text[100])
        {
            Caption = 'Participant Organization';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                CheckEmployeeMandatory();
            end;
        }
        field(10; "Participant Country/Region"; Code[10])
        {
            Caption = 'Participant Country/Region';
            TableRelation = "Country/Region".Code;

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                CheckEmployeeMandatory();
            end;
        }
        field(11; "Participant Title"; Text[30])
        {
            Caption = 'Participant Title';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                CheckEmployeeMandatory();
            end;
        }
        field(12; "Participant Email"; Text[80])
        {
            Caption = 'Participant Email';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                CheckEmployeeMandatory();
            end;
        }
    }

    keys
    {
        key(PK; "Expense No.", "Line No.")
        {
        }
    }

    trigger OnDelete()
    begin
        TestStatusOpenOfExpense();
    end;

    trigger OnInsert()
    begin
        TestStatusOpenOfExpense();
    end;

    var
        Expense: Record Expense;
        ExpenseHelper: Codeunit "Expense Currency";

    local procedure UpdateExpenseInformation(ExpenseNo: Code[20])
    begin
        Expense := ExpenseHelper.GetExpense(ExpenseNo);
        Expense.CheckExpensePrerequisitesBeforeUsing();

        Rec.Validate("Expense Category Code", Expense."Expense Category");
        Rec.Validate("Expense Subcategory Code", Expense."Expense Subcategory");
    end;

    local procedure ClearParticipantsInformation()
    begin
        Rec."Participant Name" := '';
        Rec."Participant Title" := '';
        Rec."Participant Organization" := '';
        Rec."Participant Email" := '';
        Rec."Participant Country/Region" := '';
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

    local procedure TestStatusOpenOfExpense()
    var
        ExpenseRecord: Record Expense;
    begin
        ExpenseRecord.SetLoadFields(Status);
        ExpenseRecord.Get("Expense No.");

        ExpenseRecord.TestStatusOpen();
    end;
}