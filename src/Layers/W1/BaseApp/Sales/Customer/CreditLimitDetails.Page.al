// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;

/// <summary>
/// Displays credit limit details in notifications when credit limits are exceeded.
/// </summary>
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
                AutoFormatExpression = '';
                Caption = 'Outstanding Amt. (LCY)';
                Editable = false;
                ToolTip = 'Specifies the amount on sales to the customer that remains to be shipped. The amount is calculated as Amount x Outstanding Quantity / Quantity.';
            }
            field(ShippedRetRcdNotIndLCY; ShippedRetRcdNotIndLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                AutoFormatExpression = '';
                Caption = 'Shipped/Ret. Rcd. Not Invd. (LCY)';
                Editable = false;
                ToolTip = 'Specifies the amount on sales returns from the customer that are not yet refunded';
            }
            field(OrderAmountThisOrderLCY; OrderAmountThisOrderLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                AutoFormatExpression = '';
                Caption = 'Current Amount (LCY)';
                Editable = false;
                ToolTip = 'Specifies the total amount the whole sales document.';
            }
            field(TotalAmountLCY; CustCreditAmountLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                AutoFormatExpression = '';
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
                AutoFormatType = 1;
                AutoFormatExpression = '';
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
                AutoFormatType = 1;
                AutoFormatExpression = '';
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

    /// <summary>
    /// Populates the credit limit notification with current customer and order amount data.
    /// </summary>
    /// <param name="CreditLimitNotification">The notification to populate with data.</param>
    procedure PopulateDataOnNotification(var CreditLimitNotification: Notification)
    begin
        CreditLimitNotification.SetData(Rec.FieldName("No."), Format(Rec."No."));
        CreditLimitNotification.SetData('OrderAmountTotalLCY', Format(OrderAmountTotalLCY));
        CreditLimitNotification.SetData('ShippedRetRcdNotIndLCY', Format(ShippedRetRcdNotIndLCY));
        CreditLimitNotification.SetData('OrderAmountThisOrderLCY', Format(OrderAmountThisOrderLCY));
        CreditLimitNotification.SetData('CustCreditAmountLCY', Format(CustCreditAmountLCY));

        OnAfterPopulateDataOnNotificationProcedure(CreditLimitNotification, ExtensionAmountsDic);
    end;

    /// <summary>
    /// Initializes the page with data from a credit limit notification.
    /// </summary>
    /// <param name="CreditLimitNotification">The notification containing the credit limit data.</param>
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

    /// <summary>
    /// Sets the customer record by customer number.
    /// </summary>
    /// <param name="Value">The customer number to retrieve.</param>
    procedure SetCustomerNumber(Value: Code[20])
    begin
        Rec.Get(Value);
    end;

    /// <summary>
    /// Sets the total order amount in local currency.
    /// </summary>
    /// <param name="Value">The total order amount in LCY.</param>
    procedure SetOrderAmountTotalLCY(Value: Decimal)
    begin
        OrderAmountTotalLCY := Value;
    end;

    /// <summary>
    /// Sets the shipped or return received but not invoiced amount in local currency.
    /// </summary>
    /// <param name="Value">The shipped or return received not invoiced amount in LCY.</param>
    procedure SetShippedRetRcdNotIndLCY(Value: Decimal)
    begin
        ShippedRetRcdNotIndLCY := Value;
    end;

    /// <summary>
    /// Sets the order amount for the current order in local currency.
    /// </summary>
    /// <param name="Value">The order amount for the current order in LCY.</param>
    procedure SetOrderAmountThisOrderLCY(Value: Decimal)
    begin
        OrderAmountThisOrderLCY := Value;
    end;

    /// <summary>
    /// Sets the customer credit amount in local currency.
    /// </summary>
    /// <param name="Value">The customer credit amount in LCY.</param>
    procedure SetCustCreditAmountLCY(Value: Decimal)
    begin
        CustCreditAmountLCY := Value;
    end;

    /// <summary>
    /// Sets the extension amounts dictionary from an external source.
    /// </summary>
    /// <param name="FromExtensionAmounts">Dictionary of extension amounts keyed by GUID.</param>
    procedure SetExtensionAmounts(FromExtensionAmounts: Dictionary of [Guid, Decimal])
    begin
        ExtensionAmountsDic := FromExtensionAmounts;
    end;

    /// <summary>
    /// Gets the extension amounts dictionary.
    /// </summary>
    /// <param name="ToExtensionAmounts">Variable to receive the dictionary of extension amounts.</param>
    procedure GetExtensionAmounts(var ToExtensionAmounts: Dictionary of [Guid, Decimal])
    begin
        ToExtensionAmounts := ExtensionAmountsDic;
    end;

    /// <summary>
    /// Raised after populating data on the credit limit notification.
    /// </summary>
    /// <param name="CreditLimitNotification">The notification being populated.</param>
    /// <param name="ExtensionAmountsDic">Dictionary of extension amounts by GUID.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateDataOnNotificationProcedure(CreditLimitNotification: Notification; var ExtensionAmountsDic: Dictionary of [Guid, Decimal])
    begin
    end;

    /// <summary>
    /// Raised after initializing the credit limit details from a notification.
    /// </summary>
    /// <param name="CreditLimitNotification">The notification providing the data.</param>
    /// <param name="ExtensionAmountsDic">Dictionary of extension amounts by GUID.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeFromNotificationVarProcedure(CreditLimitNotification: Notification; var ExtensionAmountsDic: Dictionary of [Guid, Decimal])
    begin
    end;
}

