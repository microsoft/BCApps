// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6935 "Expense Itemizations API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Itemization';
    EntitySetCaption = 'Expense Itemizations';
    DelayedInsert = true;
    EntityName = 'expenseItemization';
    EntitySetName = 'expenseItemizations';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Itemization";
    AboutText = 'Provides access to data from the Expense Itemization table';
    AutoSplitKey = true;

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
                field(expenseNo; Rec."Expense No.")
                {
                    Caption = 'Expense Report No.';
                }
                field(expenseCategoryCode; Rec."Expense Category Code")
                {
                    Caption = 'Expense Category Code';
                }
                field(expenseSubcategoryCode; Rec."Expense Subcategory Code")
                {
                    Caption = 'Expense Subcategory Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(dailyRate; Rec."Daily Rate")
                {
                    Caption = 'Daily Rate';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(startDate; Rec."Start Date")
                {
                    Caption = 'Start Date';
                }
                field(refundable; Rec.Refundable)
                {
                    Caption = 'Refundable';
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

    [ServiceEnabled]
    procedure ValidateExpenseRule(var ActionContext: WebServiceActionContext)
    var
        Expense: Record Expense;
    begin
        if Expense.Get(Rec."Expense No.") then
            Expense.ApplyRule(false, true);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Itemizations API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ApplyExpenseRule(var ActionContext: WebServiceActionContext)
    var
        Expense: Record Expense;
    begin
        if Expense.Get(Rec."Expense No.") then begin
            Expense.ApplyRule();
#pragma warning disable AA0214
            Expense.Modify();
#pragma warning restore AA0214
        end;

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Itemizations API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}