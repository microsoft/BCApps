// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6922 "Expense Rule Conditions API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Rule Condition';
    EntitySetCaption = 'Expense Rule Conditions';
    EntityName = 'expenseRuleCondition';
    EntitySetName = 'expenseRuleConditions';
    PageType = API;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Rule Condition";
    AboutText = 'Provides access to the data from the Expense Rule Condition table';

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
                field(expenseLocation; Rec."Expense Location")
                {
                    Caption = 'Expense Location';
                }
                field(effectiveDate; Rec."Effective Date")
                {
                    Caption = 'Effective Date';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(conditionType; Rec."Condition Type")
                {
                    Caption = 'Condition Type';
                }
                field("value"; Rec."Value")
                {
                    Caption = 'Value';
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