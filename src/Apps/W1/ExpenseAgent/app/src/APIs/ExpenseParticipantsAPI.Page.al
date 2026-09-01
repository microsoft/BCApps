// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6936 "Expense Participants API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Participant';
    EntitySetCaption = 'Expense Participants';
    DelayedInsert = true;
    EntityName = 'expenseParticipant';
    EntitySetName = 'expenseParticipants';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Participant";
    AboutText = 'Provides access to data from the Expense Participant table';
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
                field(participantType; Rec."Participant Type")
                {
                    Caption = 'Participant Type';
                }
                field(participantEmployeeNumber; Rec."Participant Employee No.")
                {
                    Caption = 'Participant Employee Number';
                }
                field(participantName; Rec."Participant Name")
                {
                    Caption = 'Participant Name';
                }
                field(participantOrganization; Rec."Participant Organization")
                {
                    Caption = 'Participant Organization';
                }
                field(participantCountryRegion; Rec."Participant Country/Region")
                {
                    Caption = 'Participant Country/Region';
                }
                field(participantTitle; Rec."Participant Title")
                {
                    Caption = 'Participant Title';
                }
                field(participantEmail; Rec."Participant Email")
                {
                    Caption = 'Participant Email';
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
        ActionContext.SetObjectId(Page::"Expense Participants API");
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
        ActionContext.SetObjectId(Page::"Expense Participants API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}