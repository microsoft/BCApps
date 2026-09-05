// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;

pageextension 12100 "WHT Payment Journal IT" extends "Payment Journal"
{
    actions
    {
        addbefore(SuggestVendorPayments)
        {
            action(WithhTaxSocSec)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Withh.Ta&x-Soc.Sec.';
                Image = SocialSecurityTax;
                ToolTip = 'Show the calculated withholding tax contributions for social security.';

                trigger OnAction()
                begin
                    WithholdingSocSecMgt.CreateTmpWithhSocSec(Rec);
                    PaymentToleranceMgt.SetIncludeWHT();
                    PaymentToleranceMgt.PmtTolGenJnl(Rec);
                end;
            }
            separator(Action1130000)
            {
            }
        }
    }

    var
        WithholdingSocSecMgt: Codeunit "Withholding - Contribution";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
}
