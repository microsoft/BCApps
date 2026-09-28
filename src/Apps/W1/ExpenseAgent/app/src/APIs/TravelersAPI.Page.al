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
                    begin
                        Rec.ValidateEmployeeNo(EmployeeNumber);
                    end;
                }
#if not CLEAN30
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
#endif
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
        // The variable-backed API control does not automatically calculate its source FlowField.
        Rec.CalcFields("Employee No.");
        EmployeeNumber := Rec."Employee No.";
    end;

    var
        EmployeeNumber: Code[20];
}
