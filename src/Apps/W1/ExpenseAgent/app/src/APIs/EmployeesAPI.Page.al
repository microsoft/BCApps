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

    trigger OnAfterGetRecord()
    begin
        CompanyInformation.Get();

        OrganizationName := CompanyInformation.Name;
    end;

    var
        CompanyInformation: Record "Company Information";
        OrganizationName: Text[100];
}