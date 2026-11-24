// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7424 "EA Card Receipt VAT Spec. API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'cardReceiptVATSpecification';
    EntitySetName = 'cardReceiptVATSpecifications';
    EntityCaption = 'Card Receipt VAT Specification';
    EntitySetCaption = 'Card Receipt VAT Specifications';
    SourceTable = "EA Card Receipt VAT Spec.";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

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
                field(receiptDataId; Rec."Receipt Data Id")
                {
                    Caption = 'Receipt Data Id';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(vatPercent; Rec."VAT %")
                {
                    Caption = 'VAT %';
                }
                field(vatBaseAmount; Rec."VAT Base Amount")
                {
                    Caption = 'VAT Base Amount';
                }
                field(vatAmount; Rec."VAT Amount")
                {
                    Caption = 'VAT Amount';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(vatAmountLCY; Rec."VAT Amount (LCY)")
                {
                    Caption = 'VAT Amount (LCY)';
                }
                field(vatBaseAmountLCY; Rec."VAT Base Amount (LCY)")
                {
                    Caption = 'VAT Base Amount (LCY)';
                }
                field(amountLCY; Rec."Amount (LCY)")
                {
                    Caption = 'Amount (LCY)';
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Group")
                {
                    Caption = 'VAT Bus. Posting Group';
                }
                field(vatProdPostingGroup; Rec."VAT Prod. Posting Group")
                {
                    Caption = 'VAT Prod. Posting Group';
                }
                field(confidence; Rec.Confidence)
                {
                    Caption = 'Confidence';
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
        CardReceiptData: Record "EA Card Receipt Data";
        CardReceiptVATSpec: Record "EA Card Receipt VAT Spec.";
        ReceiptDataFilter: Text;
        OriginalFilterGroup: Integer;
    begin
        if IsNullGuid(Rec."Receipt Data Id") then begin
            OriginalFilterGroup := Rec.FilterGroup();
            Rec.FilterGroup(4);
            ReceiptDataFilter := Rec.GetFilter("Receipt Data Id");
            Rec.FilterGroup(OriginalFilterGroup);
            if ReceiptDataFilter <> '' then
                if Evaluate(Rec."Receipt Data Id", ReceiptDataFilter) then;
        end;
        CardReceiptData.Get(Rec."Receipt Data Id");
        if Rec."Line No." = 0 then begin
            CardReceiptVATSpec.SetRange("Receipt Data Id", Rec."Receipt Data Id");
            if CardReceiptVATSpec.FindLast() then;
            Rec."Line No." := CardReceiptVATSpec."Line No." + 10000;
        end;
        exit(true);
    end;
}
