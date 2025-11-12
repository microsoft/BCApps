// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Customer;

page 437 "Reminder Statistics"
{
    Caption = 'Reminder Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Reminder Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total of the remaining amounts on the reminder lines.';
                }
                field(Interest; Interest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Interest Amount';
                    DrillDown = false;
                    ToolTip = 'Specifies the amount of interest due on the amount remaining.';
                }
                field("Additional Fee"; Rec."Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total of the additional fee amounts on the reminder lines.';
                }
                field(VatAmount; VatAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount';
                    DrillDown = false;
                    ToolTip = 'Specifies the VAT amount that has been calculated, on the reminder amount.';
                }
                field("Add. Fee per Line"; Rec."Add. Fee per Line")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies that the fee is distributed on individual reminder lines.';
                }
                field(ReminderTotal; ReminderTotal)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount due on the reminder, including interest, VAT, and additional fee.';
                }
                field(InvoiceRoundingAmount; InvoiceRoundingAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoice Rounding Amount';
                    ToolTip = 'Specifies the amount that must be added to the reminder when it is posted according to invoice rounding setup.';
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
        ReminderLevel: Record "Reminder Level";
        VATInterest: Decimal;
    begin
        Rec.CalcFields("Interest Amount", "VAT Amount", "Add. Fee per Line");
        ReminderTotal := Rec."Remaining Amount" + Rec."Additional Fee" + Rec."Interest Amount" + Rec."VAT Amount" + Rec."Add. Fee per Line";
        VatAmount := Rec."VAT Amount";
        CustPostingGr.Get(Rec."Customer Posting Group");
        VATInterest := 0;
        InvoiceRoundingAmount := Rec.GetInvoiceRoundingAmount();
        if ReminderLevel.Get(Rec."Reminder Terms Code", Rec."Reminder Level") then
            if ReminderLevel."Calculate Interest" and (Rec."VAT Amount" <> 0) then begin
                GLAcc.Get(CustPostingGr."Interest Account");
                VATPostingSetup.Get(Rec."VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                OnAfterGetVATPostingSetup(VATPostingSetup);
                VATInterest := VATPostingSetup."VAT %";
                if GLAcc.Get(CustPostingGr."Additional Fee Account") then begin
                    VATPostingSetup.Get(Rec."VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                    OnAfterGetVATPostingSetup(VATPostingSetup);
                end;
                Interest :=
                  (ReminderTotal -
                   Rec."Remaining Amount" - (Rec."Additional Fee" + Rec."Add. Fee per Line") * (VATPostingSetup."VAT %" / 100 + 1)) /
                  (VATInterest / 100 + 1);
                VatAmount := Interest * VATInterest / 100 + Rec."Additional Fee" * VATPostingSetup."VAT %" / 100 + Rec.CalculateLineFeeVATAmount();
            end else
                Interest := Rec."Interest Amount";

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
        ReminderTotal: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        Interest: Decimal;
        VatAmount: Decimal;
        InvoiceRoundingAmount: Decimal;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;
}
