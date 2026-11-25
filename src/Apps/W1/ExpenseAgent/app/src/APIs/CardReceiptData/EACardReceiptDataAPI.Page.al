// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7421 "EA Card Receipt Data API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'cardReceiptData';
    EntitySetName = 'cardReceiptData';
    EntityCaption = 'Card Receipt Data';
    EntitySetCaption = 'Card Receipt Data';
    SourceTable = "EA Card Receipt Data";
    ODataKeyFields = Id;
    DelayedInsert = true;
    Extensible = false;
    AboutTitle = 'Card Receipt Data';
    AboutText = 'Stages a missing receipt and its extracted data for a corporate card expense that is waiting for a receipt. The apply action attaches the receipt and fills only empty fields on the expense and its expense report line, preserving the expense status. Amount, currency, date, merchant and card always come from the card transaction. Subsequent attachment changes follow the normal expense status and expense report restrictions.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.Id)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(expenseId; Rec."Expense SystemId")
                {
                    Caption = 'Expense Id';
                }
                field(expenseNo; Rec."Expense No.")
                {
                    Caption = 'Expense No.';
                    Editable = false;
                }
                field(fileName; Rec."File Name")
                {
                    Caption = 'File Name';
                }
                field(attachmentContent; Rec."Attachment Content")
                {
                    Caption = 'Attachment Content';
                }
                field(expenseCategory; Rec."Expense Category")
                {
                    Caption = 'Expense Category';
                }
                field(expenseSubcategory; Rec."Expense Subcategory")
                {
                    Caption = 'Expense Subcategory';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(justification; Rec.Justification)
                {
                    Caption = 'Justification';
                }
                field(expenseTime; Rec."Expense Time")
                {
                    Caption = 'Expense Time';
                }
                field(merchantRegistrationNo; Rec."Merchant Registration No.")
                {
                    Caption = 'Merchant Registration No.';
                }
                field(merchantVATRegistrationNo; Rec."Merchant VAT Registration No.")
                {
                    Caption = 'Merchant VAT Registration No.';
                }
                field(expenseExtDocNo; Rec."Expense Ext. Doc. No.")
                {
                    Caption = 'Expense External Document No.';
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Group")
                {
                    Caption = 'VAT Bus. Posting Group';
                }
                field(vatProdPostingGroup; Rec."VAT Prod. Posting Group")
                {
                    Caption = 'VAT Prod. Posting Group';
                }
                field(projectNo; Rec."Job No.")
                {
                    Caption = 'Project No.';
                }
                field(projectTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Project Task No.';
                }
                field(billable; Rec.Billable)
                {
                    Caption = 'Billable';
                }
                field(billableToCustomer; Rec."Billable to Customer")
                {
                    Caption = 'Billable to Customer';
                }
                part(cardReceiptParticipants; "EA Card Receipt Particip. API")
                {
                    Caption = 'Card Receipt Participants';
                    EntityName = 'cardReceiptParticipant';
                    EntitySetName = 'cardReceiptParticipants';
                    SubPageLink = "Receipt Data Id" = field(Id);
                }
                part(cardReceiptItems; "EA Card Receipt Items API")
                {
                    Caption = 'Card Receipt Items';
                    EntityName = 'cardReceiptItem';
                    EntitySetName = 'cardReceiptItems';
                    SubPageLink = "Receipt Data Id" = field(Id);
                }
                part(cardReceiptVATSpecifications; "EA Card Receipt VAT Spec. API")
                {
                    Caption = 'Card Receipt VAT Specifications';
                    EntityName = 'cardReceiptVATSpecification';
                    EntitySetName = 'cardReceiptVATSpecifications';
                    SubPageLink = "Receipt Data Id" = field(Id);
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Expense: Record Expense;
        CardReceiptDataApply: Codeunit "EA Card Receipt Data Apply";
        ExpenseFilter: Text;
        OriginalFilterGroup: Integer;
    begin
        if IsNullGuid(Rec."Expense SystemId") then begin
            OriginalFilterGroup := Rec.FilterGroup();
            Rec.FilterGroup(4);
            ExpenseFilter := Rec.GetFilter("Expense SystemId");
            Rec.FilterGroup(OriginalFilterGroup);
            if ExpenseFilter <> '' then
                if Evaluate(Rec."Expense SystemId", ExpenseFilter) then;
        end;
        CardReceiptDataApply.GetCardExpense(Rec."Expense SystemId", Expense);
        Rec."Expense No." := Expense."No.";
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec."Expense SystemId" <> xRec."Expense SystemId" then
            Error(CannotChangeExpenseErr);
        exit(true);
    end;

    [ServiceEnabled]
    procedure Apply(var ActionContext: WebServiceActionContext)
    var
        Expense: Record Expense;
        CardReceiptDataApply: Codeunit "EA Card Receipt Data Apply";
        ExpenseSystemId: Guid;
    begin
        ExpenseSystemId := Rec."Expense SystemId";
        CardReceiptDataApply.Apply(Rec);
        Expense.GetBySystemId(ExpenseSystemId);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expenses API");
        ActionContext.AddEntityKey(Expense.FieldNo(SystemId), Expense.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    var
        CannotChangeExpenseErr: Label 'You cannot change the expense of card receipt data. Delete it and create new receipt data for the other expense.';
}
