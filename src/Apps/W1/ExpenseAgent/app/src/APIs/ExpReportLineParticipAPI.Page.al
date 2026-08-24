// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6909 "Exp. Report Line Particip. API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Report Line Participant';
    EntitySetCaption = 'Expense Report Line Participants';
    DelayedInsert = true;
    EntityName = 'expenseReportLineParticipant';
    EntitySetName = 'expenseReportLineParticipants';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Report Line Particip.";
    AboutText = 'Provides access to data from the Expense Report Line Participant table';
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
    procedure ValidateExpenseReportRule(var ActionContext: WebServiceActionContext)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        if ExpenseReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.") then
            ExpenseReportLine.ApplyRule(false, true);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Exp. Report Line Particip. API");
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
        ActionContext.SetObjectId(Page::"Exp. Report Line Particip. API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}