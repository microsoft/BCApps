// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;

page 6917 "Employees API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Employee';
    EntitySetCaption = 'Employees';
    EntityName = 'employee';
    EntitySetName = 'employees';
    PageType = API;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = Employee;
    AboutText = 'Lists details about employees that can use the expense functionalities.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(isExpenseUser; Rec."Is Expense User")
                {
                    Caption = 'Is Expense User';
                    Editable = false;
                }
                field(name; Rec.FullName())
                {
                    Caption = 'Name';
                }
                field(companyEmail; Rec."Company E-Mail")
                {
                    Caption = 'Company E-Mail';
                }
                field(organizationName; OrganizationName)
                {
                    Caption = 'Organization Name';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnOpenPage()
    begin
        ApplyTravelRequestFilter();
    end;

    trigger OnAfterGetRecord()
    begin
        CompanyInformation.Get();

        OrganizationName := CompanyInformation.Name;
    end;

    local procedure ApplyTravelRequestFilter()
    var
        ExpenseUser: Record "Expense User";
        EmployeeFilterRecord: Record Employee;
        Traveler: Record Traveler;
        EmployeeFilter: TextBuilder;
        TravelRequestNo: Code[20];
        OriginalFilterGroup: Integer;
    begin
        OriginalFilterGroup := Rec.FilterGroup(4);
        TravelRequestNo := CopyStr(Rec.GetFilter("Travel Request No. Filter"), 1, MaxStrLen(TravelRequestNo));
        Rec.FilterGroup(OriginalFilterGroup);
        if TravelRequestNo = '' then
            exit;

        Traveler.SetRange("Spend Request No.", TravelRequestNo);
        Traveler.SetLoadFields("Expense User No.");
        ExpenseUser.SetLoadFields("Employee No.");
        if Traveler.FindSet() then
            repeat
                ExpenseUser.Get(Traveler."Expense User No.");
                ExpenseUser.TestField("Employee No.");
                if EmployeeFilter.Length > 0 then
                    EmployeeFilter.Append('|');
                EmployeeFilterRecord.SetRange("No.", ExpenseUser."Employee No.");
                EmployeeFilter.Append(EmployeeFilterRecord.GetFilter("No."));
            until Traveler.Next() = 0;

        OriginalFilterGroup := Rec.FilterGroup(2);
        if EmployeeFilter.Length = 0 then
            Rec.SetRange(SystemId, CreateGuid())
        else
            Rec.SetFilter("No.", EmployeeFilter.ToText());
        Rec.FilterGroup(OriginalFilterGroup);
    end;

    var
        CompanyInformation: Record "Company Information";
        OrganizationName: Text[100];
}