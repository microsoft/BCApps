// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6954 "Expense Per Diem API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Per Diem';
    EntitySetCaption = 'Expense Per Diem';
    DelayedInsert = true;
    EntityName = 'expenseperdiem';
    EntitySetName = 'expenseperdiems';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Per Diem";
    AboutText = 'Provides access to data from the Expense Per Diem table';

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
                    Caption = 'Expense No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(expenseCategoryCode; Rec."Expense Category Code")
                {
                    Caption = 'Expense Category Code';
                }
                field(expenseSubcategoryCode; Rec."Expense Subcategory Code")
                {
                    Caption = 'Expense Subcategory Code';
                }
                field(expenseLocation; Rec."Expense Location")
                {
                    Caption = 'Expense Location';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(date; Rec.Date)
                {
                    Caption = 'Date';
                }
                field(breakfast; Rec.Breakfast)
                {
                    Caption = 'Breakfast';
                }
                field(lunch; Rec.Lunch)
                {
                    Caption = 'Lunch';
                }
                field(dinner; Rec.Dinner)
                {
                    Caption = 'Dinner';
                }
                field(perDiemAmount; Rec."Per Diem Amount")
                {
                    Caption = 'Per Diem Amount';
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
        ActionContext.SetObjectId(Page::"Expense Per Diem API");
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
        ActionContext.SetObjectId(Page::"Expense Per Diem API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}