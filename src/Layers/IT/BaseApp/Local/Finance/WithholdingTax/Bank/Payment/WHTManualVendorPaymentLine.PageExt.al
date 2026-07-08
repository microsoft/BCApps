// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Vendor;

pageextension 12188 "WHT Manual Vendor Payment Line" extends "Manual vendor Payment Line"
{
    layout
    {
        addafter(VendorName)
        {
            field(WithholdingTaxCode; WithholdingTaxCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Withholding Tax Code';
                TableRelation = "Withhold Code";
                ToolTip = 'Specifies the withholding tax code.';
            }
            field(SocialSecurityCode; SocialSecurityCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Social Security Code';
                TableRelation = "Contribution Code";
                ToolTip = 'Specifies the social security code.';
            }
        }
    }

    trigger OnOpenPage()
    var
        Vend: Record Vendor;
    begin
        if Vend.Get(VendorNo) then begin
            WithholdingTaxCode := Vend."Withholding Tax Code";
            SocialSecurityCode := Vend."Social Security Code";
        end;
    end;

    var
        WithholdingTaxCode: Code[20];
        SocialSecurityCode: Code[20];
}