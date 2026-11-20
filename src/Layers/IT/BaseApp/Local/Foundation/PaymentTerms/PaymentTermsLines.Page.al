#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using System.Environment.Configuration;

page 12170 "Payment Terms Lines"
{
    AutoSplitKey = true;
    Caption = 'Payment Terms Lines';
    DataCaptionFields = "Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Payment Lines";
    ObsoleteReason = 'Replaced by global Payment Installments feature.';
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Payment %"; Rec."Payment %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the transaction amount that is issued as an installment payment.';
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the formula that is used to calculate the date that a payment must be made for a purchase or sales invoice.';
                }
                field("Discount Date Calculation"; Rec."Discount Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the formula that is used to calculate the date that a payment must be made in order to obtain a discount.';
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount percentage that is applied for early payment of an invoice amount.';
                }
            }
        }
    }

    actions
    {
    }
    trigger OnOpenPage()
    begin
        FeatureKeyManagement.CheckLegacyPaymentInstallmentsEnabled();
    end;

    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
}
#endif

