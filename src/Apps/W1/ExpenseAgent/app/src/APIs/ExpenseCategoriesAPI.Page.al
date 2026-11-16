// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6914 "Expense Categories API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Category';
    EntitySetCaption = 'Expense Categories';
    EntityName = 'expenseCategory';
    EntitySetName = 'expenseCategories';
    PageType = API;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = "Expense Category";
    AboutText = 'Provides access to the data from the Expense Category table';

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
                field(code; Rec."Code")
                {
                    Caption = 'Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(postingDescription; Rec."Posting Description")
                {
                    Caption = 'Posting Description';
                }
                field(postingGroup; Rec."Posting Group")
                {
                    Caption = 'Posting Group';
                }
                field(attachmentEnforcement; Rec."Attachment Enforcement")
                {
                    Caption = 'Attachment Enforcement';
                }
                field(defaultPaymentMethod; Rec."Default Payment Method")
                {
                    Caption = 'Default Payment Method';
                }
                field(paymentMethodDescription; PaymentMethodDescription)
                {
                    Caption = 'Payment Method Description';
                    Editable = false;
                }
                field(prepaymentCashAdvance; Rec."Prepayment-Cash Advance")
                {
                    Caption = 'Prepayment-Cash Advance';
                }
                field(inactive; Rec.Inactive)
                {
                    Caption = 'Inactive';
                }
                field(expenseGroup; Rec."Expense Group")
                {
                    Caption = 'Expense Group';
                }
                field(refundable; Rec.Refundable)
                {
                    Caption = 'Refundable';
                }
                field(reimbursementType; Rec."Reimbursement Type")
                {
                    Caption = 'Reimbursement Type';
                }
                field(expenseDetailRequired; Rec."Expense Detail Required")
                {
                    Caption = 'Expense Detail Required';
                }

                part(expenseSubcategories; "Expense Subcategories API")
                {
                    Caption = 'Expense Subcategories';
                    EntityName = 'expenseSubcategory';
                    EntitySetName = 'expenseSubcategories';
                    SubPageLink = "Expense Category Code" = field("Code");
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

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields();
    end;

    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        PaymentMethodDescription: Text[100];

    local procedure SetCalculatedFields()
    begin
        PaymentMethodDescription := '';
        if ExpensePaymentMethod.Get(Rec."Default Payment Method") then
            PaymentMethodDescription := ExpensePaymentMethod.Description;
    end;
}