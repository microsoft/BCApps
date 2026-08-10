// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7104 "Expense Policies API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Policy';
    EntitySetCaption = 'Expense Policies';
    DelayedInsert = true;
    EntityName = 'expensePolicy';
    EntitySetName = 'expensePolicies';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Policy";
    AboutText = 'Provides access to data from the Expense Policy table';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;

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
                field(expenseCategoryCode; Rec."Expense Category Code")
                {
                    Caption = 'Expense Category Code';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(policyText; Rec."Policy Text")
                {
                    Caption = 'Policy Text';
                }
                field(enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
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
}
