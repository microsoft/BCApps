// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

page 690 "Payment Practice Pmt. Data"
{
    ApplicationArea = All;
    Caption = 'Payment Practice Payment Data';
    PageType = List;
    SourceTable = "Payment Practice Pmt. Data";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Source Type"; Rec."Source Type")
                {
                    Editable = false;
                }
                field("CV No."; Rec."CV No.")
                {
                    Editable = false;
                }
                field("Invoice Doc. No."; Rec."Invoice Doc. No.")
                {
                    Editable = false;
                }
                field("Payment Doc. No."; Rec."Payment Doc. No.")
                {
                    Editable = false;
                }
                field("Invoice Due Date"; Rec."Invoice Due Date")
                {
                    Editable = false;
                }
                field("Payment Posting Date"; Rec."Payment Posting Date")
                {
                    Editable = false;
                }
                field("Invoice Total Amount"; Rec."Invoice Total Amount")
                {
                    Editable = false;
                }
                field("Payment Total Amount"; Rec."Payment Total Amount")
                {
                    Editable = false;
                }
                field("Applied Amount"; Rec."Applied Amount")
                {
                    Editable = false;
                }
                field("Is Late"; Rec."Is Late")
                {
                    Editable = false;
                }
                field("Late Due to Dispute"; Rec."Late Due to Dispute")
                {
                    Editable = Rec."Is Late";

                    trigger OnValidate()
                    begin
                        LateDueToDisputeModified := true;
                    end;
                }
            }
        }
    }

    trigger OnClosePage()
    begin
        if LateDueToDisputeModified then
            UpdateHeaderPctLateDueToDispute();
    end;

    local procedure UpdateHeaderPctLateDueToDispute()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPracticeMath: Codeunit "Payment Practice Math";
    begin
        if not Rec.FindFirst() then
            exit;

        if not PaymentPracticeHeader.Get(Rec."Header No.") then
            exit;

        PaymentPracticeHeader."Pct Late Due to Dispute" := PaymentPracticeMath.GetPctLateDueToDispute(PaymentPracticeHeader."No.", PaymentPracticeHeader."Starting Date", PaymentPracticeHeader."Ending Date");
        PaymentPracticeHeader."Modified Manually" := true;
        PaymentPracticeHeader.Modify(true);
    end;

    var
        LateDueToDisputeModified: Boolean;
}
