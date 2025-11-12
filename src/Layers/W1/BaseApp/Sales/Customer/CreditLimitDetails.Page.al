// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;

page 1871 "Credit Limit Details"
{
    Caption = 'Details';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            field("Balance (LCY)"; Rec."Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                trigger OnDrillDown()
                begin
                    Rec.OpenCustomerLedgerEntries(false);
                end;
            }
            field(OutstandingAmtLCY; OrderAmountTotalLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Outstanding Amt. (LCY)';
                Editable = false;
                ToolTip = 'Specifies the amount on sales to the customer that remains to be shipped. The amount is calculated as Amount x Outstanding Quantity / Quantity.';
            }
            field(ShippedRetRcdNotIndLCY; ShippedRetRcdNotIndLCY)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Shipped/Ret. Rcd. Not Invd. (LCY)';
                Editable = false;
                ToolTip = 'Specifies the amount on sales returns from the customer that are not yet refunded';
            }
            field(OrderAmountThisOrderLCY; OrderAmountThisOrderLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Current Amount (LCY)';
                Editable = false;
                ToolTip = 'Specifies the total amount the whole sales document.';
            }
            field(TotalAmountLCY; CustCreditAmountLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Total Amount (LCY)';
                Editable = false;
                ToolTip = 'Specifies the sum of the amounts in all of the preceding fields in the window.';
            }
            field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            field(OverdueBalance; Rec.CalcOverdueBalance())
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = OverdueAmountsTxt;
                Editable = false;
                ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';

                trigger OnDrillDown()
                var
                    DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                    CustLedgEntry: Record "Cust. Ledger Entry";
                begin
                    DtldCustLedgEntry.SetFilter("Customer No.", Rec."No.");
                    Rec.CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                    CustLedgEntry.DrillDownOnOverdueEntries(DtldCustLedgEntry);
                end;
            }
            field(GetInvoicedPrepmtAmountLCY; Rec.GetInvoicedPrepmtAmountLCY())
            {
                ApplicationArea = Prepayments;
                Caption = 'Invoiced Prepayment Amount (LCY)';
                Editable = false;
                ToolTip = 'Specifies your sales income from the customer based on invoiced prepayments.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if Rec.GetFilter("Date Filter") = '' then
            Rec.SetFilter("Date Filter", '..%1', WorkDate());
        Rec.CalcFields("Balance (LCY)", "Shipped Not Invoiced (LCY)");
    end;

    var
        OrderAmountTotalLCY: Decimal;
        ShippedRetRcdNotIndLCY: Decimal;
        OrderAmountThisOrderLCY: Decimal;
        CustCreditAmountLCY: Decimal;
        ExtensionAmountsDic: Dictionary of [Guid, Decimal];
        OverdueAmountsTxt: Label 'Overdue Amounts (LCY)';

    procedure PopulateDataOnNotification(var CreditLimitNotification: Notification)
    begin
        CreditLimitNotification.SetData(Rec.FieldName("No."), Format(Rec."No."));
        CreditLimitNotification.SetData('OrderAmountTotalLCY', Format(OrderAmountTotalLCY));
        CreditLimitNotification.SetData('ShippedRetRcdNotIndLCY', Format(ShippedRetRcdNotIndLCY));
        CreditLimitNotification.SetData('OrderAmountThisOrderLCY', Format(OrderAmountThisOrderLCY));
        CreditLimitNotification.SetData('CustCreditAmountLCY', Format(CustCreditAmountLCY));

        OnAfterPopulateDataOnNotificationProcedure(CreditLimitNotification, ExtensionAmountsDic);
    end;

    procedure InitializeFromNotificationVar(CreditLimitNotification: Notification)
    var
        Customer: Record Customer;
    begin
        Rec.Get(CreditLimitNotification.GetData(Customer.FieldName("No.")));
        Rec.SetRange("No.", Rec."No.");

        if Rec.GetFilter("Date Filter") = '' then
            Rec.SetFilter("Date Filter", '..%1', WorkDate());
        Rec.CalcFields("Balance (LCY)", "Shipped Not Invoiced (LCY)");

        Evaluate(OrderAmountTotalLCY, CreditLimitNotification.GetData('OrderAmountTotalLCY'));
        Evaluate(ShippedRetRcdNotIndLCY, CreditLimitNotification.GetData('ShippedRetRcdNotIndLCY'));
        Evaluate(OrderAmountThisOrderLCY, CreditLimitNotification.GetData('OrderAmountThisOrderLCY'));
        Evaluate(CustCreditAmountLCY, CreditLimitNotification.GetData('CustCreditAmountLCY'));

        OnAfterInitializeFromNotificationVarProcedure(CreditLimitNotification, ExtensionAmountsDic);
    end;

    procedure SetCustomerNumber(Value: Code[20])
    begin
        Rec.Get(Value);
    end;

    procedure SetOrderAmountTotalLCY(Value: Decimal)
    begin
        OrderAmountTotalLCY := Value;
    end;

    procedure SetShippedRetRcdNotIndLCY(Value: Decimal)
    begin
        ShippedRetRcdNotIndLCY := Value;
    end;

    procedure SetOrderAmountThisOrderLCY(Value: Decimal)
    begin
        OrderAmountThisOrderLCY := Value;
    end;

    procedure SetCustCreditAmountLCY(Value: Decimal)
    begin
        CustCreditAmountLCY := Value;
    end;

    procedure SetExtensionAmounts(FromExtensionAmounts: Dictionary of [Guid, Decimal])
    begin
        ExtensionAmountsDic := FromExtensionAmounts;
    end;

    procedure GetExtensionAmounts(var ToExtensionAmounts: Dictionary of [Guid, Decimal])
    begin
        ToExtensionAmounts := ExtensionAmountsDic;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateDataOnNotificationProcedure(CreditLimitNotification: Notification; var ExtensionAmountsDic: Dictionary of [Guid, Decimal])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeFromNotificationVarProcedure(CreditLimitNotification: Notification; var ExtensionAmountsDic: Dictionary of [Guid, Decimal])
    begin
    end;
}

