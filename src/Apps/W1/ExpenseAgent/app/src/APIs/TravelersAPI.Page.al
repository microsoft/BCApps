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
    var
        ExpenseUser: Record "Expense User";
    begin
        Clear(EmployeeNumber);
        ExpenseUser.SetLoadFields("Employee No.");
        if ExpenseUser.Get(Rec."Expense User No.") then
            EmployeeNumber := ExpenseUser."Employee No.";
    end;

    var
        EmployeeNumber: Code[20];
        ExpenseUserNotFoundErr: Label 'No expense user is linked to employee %1.', Comment = '%1 = Employee No.';
}
