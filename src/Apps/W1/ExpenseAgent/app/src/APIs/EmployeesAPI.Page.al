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
    Permissions = tabledata Traveler = r,
                  tabledata "Expense User" = r;

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
                    ToolTip = 'Specifies whether the employee is linked to an expense user.';
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
        EmployeeFilterRecord: Record Employee;
        TravelRequestEmployees: Query "Travel Request Employees";
        EmployeeFilter: TextBuilder;
        TravelRequestSystemId: Guid;
        OriginalFilterGroup: Integer;
    begin
        OriginalFilterGroup := Rec.FilterGroup(4);
        if Rec.GetFilter("Travel Request SystemId Filter") <> '' then
            TravelRequestSystemId := Rec.GetRangeMin("Travel Request SystemId Filter");
        Rec.FilterGroup(OriginalFilterGroup);
        if IsNullGuid(TravelRequestSystemId) then
            exit;

        TravelRequestEmployees.SetRange(travelRequestSystemId, TravelRequestSystemId);
        TravelRequestEmployees.Open();
        while TravelRequestEmployees.Read() do
            if TravelRequestEmployees.employeeNo <> '' then begin
                if EmployeeFilter.Length > 0 then
                    EmployeeFilter.Append('|');
                EmployeeFilterRecord.SetRange("No.", TravelRequestEmployees.employeeNo);
                EmployeeFilter.Append(EmployeeFilterRecord.GetFilter("No."));
            end;
        TravelRequestEmployees.Close();

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