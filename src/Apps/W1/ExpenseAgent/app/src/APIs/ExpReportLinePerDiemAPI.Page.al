// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6915 "Exp. Report Line Per Diem API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Report Line Per Diem';
    EntitySetCaption = 'Expense Report Line Per Diems';
    DelayedInsert = true;
    EntityName = 'expenseReportLinePerDiem';
    EntitySetName = 'expenseReportLinePerDiems';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Report Line Per Diem";
    AboutText = 'Provides access to data from the Expense Report Line Per Diem table';
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
    procedure ValidateExpenseReportRule(var ActionContext: WebServiceActionContext)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        if ExpenseReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.") then
            ExpenseReportLine.ApplyRule(false, true);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Exp. Report Line Per Diem API");
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
            ExpenseReportLine.Modify();
#pragma warning restore AA0214
        end;

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Exp. Report Line Per Diem API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}