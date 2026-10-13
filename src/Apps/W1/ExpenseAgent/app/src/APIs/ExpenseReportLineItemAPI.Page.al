// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6905 "Expense Report Line Item API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Report Line Itemization';
    EntitySetCaption = 'Expense Report Line Itemizations';
    DelayedInsert = true;
    EntityName = 'expenseReportLineItemization';
    EntitySetName = 'expenseReportLineItemizations';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Report Line Item";
    AboutText = 'Provides access to the data from the Expense Report Line Itemization table';
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
                field(expenseReportNo; Rec."Expense Report No.")
                {
                    Caption = 'Expense Report No.';
                }
                field(expenseReportLineNo; Rec."Expense Report Line No.")
                {
                    Caption = 'Expense Report Line No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(expenseNo; Rec."Expense No.")
                {
                    Caption = 'Expense No.';
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
                field(startDate; Rec."Start Date")
                {
                    Caption = 'Start Date';
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
    procedure ValidateExpenseReportRule(var ActionContext: WebServiceActionContext)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        if ExpenseReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.") then
            ExpenseReportLine.ApplyRule(false, true);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Report Line Item API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ApplyExpenseReportRule(var ActionContext: WebServiceActionContext)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        if ExpenseReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.") then begin
            ExpenseReportLine.ApplyRule();
#pragma warning disable AA0214
            ExpenseReportLine.Modify(true);
#pragma warning restore AA0214
        end;

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Report Line Item API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}