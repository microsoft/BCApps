// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

#pragma warning disable AS0088
pageextension 10749 "Posted Purch. Credit Memo ES" extends "Posted Purchase Credit Memo"
{
    layout
    {
        addafter("Currency Code")
        {
            field("Autocredit Memo No."; Rec."Autocredit Memo No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number series that is used to generate autocredit memos for purchases.';
            }
        }
        addbefore("Applies-to Doc. Type")
        {
            field("Vendor Bank Acc. Code"; Rec."Vendor Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the vendor''s bank code that was on the purchase header when this credit memo was created.';
            }
        }
        addafter("Invoice Details")
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Standard fields are in Invoice Details. The vendor bank account field is added by the Posted Purch. Credit Memo ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
        addafter("No. Printed")
        {
            field("Correction Type"; Rec."Correction Type")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the Correction Type.';
            }
            field("Corrected Invoice No."; Rec."Corrected Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the number of the posted invoice that you need to correct.';
            }
        }
    }

    actions
    {
        addafter(AttachAsPDF)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("Print &Autocredit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print &Autocredit Memo';
                    Image = CreateDocument;
                    ToolTip = 'Print the automatically created credit memo.';

                    trigger OnAction()
                    var
                        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
                    begin
                        CurrPage.SetSelectionFilter(PurchCrMemoHeader);
                        PurchCrMemoHeader.PrintRecordsAutoCrMemo(true);
                    end;
                }
            }
        }
    }
}
