// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Customer;

page 449 "Finance Charge Memo Statistics"
{
    Caption = 'Finance Charge Memo Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Finance Charge Memo Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Interest; Interest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Interest Amount';
                    DrillDown = false;
                    ToolTip = 'Specifies the interest amount that has been calculated on the finance charge memo.';
                }
                field("Additional Fee"; Rec."Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total of the additional fee amounts on the finance charge memo lines.';
                }
                field(VatAmount; VatAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount';
                    DrillDown = false;
                    ToolTip = 'Specifies the VAT amount that has been calculated on the finance charge memo.';
                }
                field(FinChrgMemoTotal; FinChrgMemoTotal)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount that has been calculated on the finance charge memo.';
                }
                field(InvoiceRoundingAmount; InvoiceRoundingAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoice Rounding Amount';
                    ToolTip = 'Specifies the amount that must be added to the finance charge memo when it is posted according to invoice rounding setup.';
                }
            }
            group(Customer)
            {
                Caption = 'Customer';
#pragma warning disable AA0100
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the balance in LCY on the customer''s account.';
                }
#pragma warning disable AA0100
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    ToolTip = 'Specifies the credit limit in local currency for the customer''s account. The value 0 represents unlimited credit.';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expended % of Credit Limit (LCY)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the expended percentage of the credit limit in (LCY).';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        CustPostingGr: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATInterest: Decimal;
    begin
        Rec.CalcFields("Interest Amount", "VAT Amount");
        FinChrgMemoTotal := Rec."Additional Fee" + Rec."Interest Amount" + Rec."VAT Amount";
        InvoiceRoundingAmount := Rec.GetInvoiceRoundingAmount();
        if Rec."Customer No." <> '' then begin
            CustPostingGr.Get(Rec."Customer Posting Group");
            GLAcc.Get(CustPostingGr.GetInterestAccount());
            VATPostingSetup.Get(Rec."VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
            OnAfterGetVATPostingSetup(VATPostingSetup);
            VATInterest := VATPostingSetup."VAT %";
            GLAcc.Get(CustPostingGr.GetAdditionalFeeAccount());
            VATPostingSetup.Get(Rec."VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
            OnAfterGetVATPostingSetup(VATPostingSetup);
            Interest := (FinChrgMemoTotal - Rec."Additional Fee" * (VATPostingSetup."VAT %" / 100 + 1)) /
              (VATInterest / 100 + 1);
            VatAmount := Interest * VATInterest / 100 +
              Rec."Additional Fee" * VATPostingSetup."VAT %" / 100;
        end;
        if Cust.Get(Rec."Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);
        if Cust."Credit Limit (LCY)" = 0 then
            CreditLimitLCYExpendedPct := 0
        else
            CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);
    end;

    var
        Cust: Record Customer;
        FinChrgMemoTotal: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        Interest: Decimal;
        VatAmount: Decimal;
        InvoiceRoundingAmount: Decimal;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;
}
