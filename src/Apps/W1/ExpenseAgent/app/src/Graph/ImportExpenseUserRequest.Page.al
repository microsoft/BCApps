// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;

page 6948 "Import Expense User Request"
{
    Caption = 'Import Expense Users';
    PageType = StandardDialog;
    ApplicationArea = All;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Options)
            {
                Caption = 'Options';

                field(CreateEmployees; CreateEmployees)
                {
                    ApplicationArea = All;
                    Caption = 'Create Employee for Expense Users';
                    ToolTip = 'Specifies whether to create new employees for imported expense users with blank employee numbers.';

                    trigger OnValidate()
                    begin
                        if not CreateEmployees then
                            EmployeeTemplateCode := '';
                    end;
                }
                field(EmployeeTemplateCode; EmployeeTemplateCode)
                {
                    ApplicationArea = All;
                    Caption = 'Employee Template Code';
                    ToolTip = 'Specifies the employee template to use when creating new employees.';
                    TableRelation = "Employee Templ.".Code;
                    Enabled = CreateEmployees;
                    Editable = false;
                    AssistEdit = true;

                    trigger OnAssistEdit()
                    var
                        EmployeeTempl: Record "Employee Templ.";
                        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
                    begin
                        if not EmployeeTemplMgt.IsEnabled() then
                            exit;

                        if EmployeeTemplMgt.SelectEmployeeTemplateFromContact(EmployeeTempl) then begin
                            EmployeeTemplateCode := EmployeeTempl.Code;
                            exit;
                        end;

                        if EmployeeTemplMgt.TemplatesAreNotEmpty() then
                            Error('');
                    end;
                }
            }
        }
    }

    var
        CreateEmployees: Boolean;
        EmployeeTemplateCode: Code[20];

    internal procedure GetValues(var ShouldCreateEmployees: Boolean; var EmpTemplateCode: Code[20])
    begin
        ShouldCreateEmployees := CreateEmployees;
        EmpTemplateCode := EmployeeTemplateCode;
    end;
}