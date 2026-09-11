// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

page 7103 "Travelers API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Traveler';
    EntitySetCaption = 'Travelers';
    DelayedInsert = true;
    EntityName = 'traveler';
    EntitySetName = 'travelers';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = Traveler;
    AboutText = 'Provides access to data from the Traveler table';
    AutoSplitKey = true;
    Permissions = tabledata "Spend Request" = r,
                  tabledata Traveler = rimd;

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
                field(spendRequestNo; Rec."Spend Request No.")
                {
                    Caption = 'Travel Request No.';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(employeeNumber; EmployeeNumber)
                {
                    Caption = 'Employee Number';
                    ToolTip = 'Specifies the employee number of the traveler.';

                    trigger OnValidate()
                    var
                        ExpenseUser: Record "Expense User";
                    begin
                        ExpenseUser.SetLoadFields("No.");
                        ExpenseUser.SetRange("Employee No.", EmployeeNumber);
                        if not ExpenseUser.FindFirst() then
                            Error(ExpenseUserNotFoundErr, EmployeeNumber);

                        Rec.Validate("Expense User No.", ExpenseUser."No.");
                    end;
                }
                field(expenseUserNo; Rec."Expense User No.")
                {
                    Caption = 'Expense User No.';
                    ObsoleteReason = 'Use employeeNumber instead. Expense User identifiers are an internal implementation detail.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '30.0';
                }
                field(expenseUserName; Rec."Expense User Name")
                {
                    Caption = 'Expense User Name';
                    ObsoleteReason = 'Use employeeNumber and the employees navigation instead.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '30.0';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
        Rec.SetAutoCalcFields("Employee No.");
    end;

    trigger OnAfterGetRecord()
    begin
        EmployeeNumber := Rec."Employee No.";
    end;

    var
        EmployeeNumber: Code[20];
        ExpenseUserNotFoundErr: Label 'No expense user is linked to employee %1.', Comment = '%1 = Employee No.';
}
