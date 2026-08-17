// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6964 "Exp. Rep. Rule Violations API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Report Rule Violation';
    EntitySetCaption = 'Expense Report Rule Violations';
    DelayedInsert = true;
    EntityName = 'expenseReportRuleViolation';
    EntitySetName = 'expenseReportRuleViolations';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Report Rule Violation";
    AboutText = 'Provides access to data from the Expense Report Rule Violation table';

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
                field(expenseReportNo; Rec."Expense Report No.")
                {
                    Caption = 'Expense Report No.';
                }
                field(reportLineNo; Rec."Report Line No.")
                {
                    Caption = 'Report Line No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
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
