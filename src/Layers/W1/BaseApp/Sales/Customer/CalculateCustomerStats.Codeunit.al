// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Document;

/// <summary>
/// Calculates customer statistics as a background task for the Customer Statistics FactBox.
/// </summary>
codeunit 9082 "Calculate Customer Stats."
{
    trigger OnRun()
    var
        Results: Dictionary of [Text, Text];
    begin
        CalculateFieldValues(Page.GetBackgroundParameters(), Results);
        Page.SetBackgroundTaskResult(Results);
    end;

    internal procedure CalculateFieldValues(Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    var
        Customer: record Customer;
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        BalanceAsVendor: Decimal;
        LinkedVendorNo: Code[20];
    begin
        Clear(Results);
        CustomerNo := CopyStr(Params.Get(GetCustomerNoLabel()), 1, MaxStrLen(CustomerNo));
        if not Customer.Get(CustomerNo) then
            exit;

        BalanceAsVendor := Customer.GetBalanceAsVendor(LinkedVendorNo);

        CalcLastPaymentDate(CustomerNo, Results);
        Results.Add(GetBalanceAsVendorLabel(), Format(BalanceAsVendor));
        Results.Add(GetLinkedVendorNoLabel(), Format(LinkedVendorNo));
        Results.Add(GetTotalAmountLCYLabel(), Format(Customer.GetTotalAmountLCY()));
        Results.Add(GetInvoicedShipmentAmountLCYLabel(), Format(SalesLine.OutstandingInvoiceAmountFromShipment(CustomerNo)));
        Results.Add(GetReturnRcdNotInvAmountLCYLabel(), Format(Customer.GetReturnRcdNotInvAmountLCY()));
        Results.Add(GetOverdueBalanceLabel(), Format(Customer.CalcOverdueBalance()));
        Results.Add(GetSalesLCYLabel(), Format(Customer.GetSalesLCY()));
        Results.Add(GetInvoicedPrepmtAmountLCYLabel(), Format(Customer.GetInvoicedPrepmtAmountLCY()));

        OnCalculateCustomerStatistics(Params, Results);
    end;

    var
        TotalAmountLCYLbl: label 'Total Amount LCY', Locked = true;
        OverdueBalanceLbl: label 'Overdue Balance', Locked = true;
        SalesLCYLbl: label 'Sales LCY', Locked = true;
        InvoicedPrepmtAmountLCYLbl: label 'Invoiced Prepmt Amount LCY', Locked = true;
        CustomerNoLbl: label 'Customer No.', Locked = true;
        BalanceAsVendorLbl: Label 'BalanceAsVendor', Locked = true;
        LinkedVendorNoLbl: Label 'LinkedVendorNo', Locked = true;
        InvoicedShipmentAmountLCYLbl: Label 'Invoiced Shipment Amount LCY', Locked = true;
        ReturnRcdNotInvAmountLCYLbl: Label 'Return Received Not Invoiced Amount LCY', Locked = true;

    local procedure CalcLastPaymentDate(CustomerNo: code[20]; var Results: Dictionary of [Text, Text])
    var
        CustomerMgt: Codeunit "Customer Mgt.";
    begin
        CustomerMgt.CalcLastPaymentInfo(CustomerNo, Results);
    end;

    internal procedure GetLastPaymentDateLabel(): Text
    var
        CustomerCardCalculations: Codeunit "Customer Card Calculations";
    begin
        exit(CustomerCardCalculations.GetLastPaymentDateLabel());
    end;

    internal procedure GetTotalAmountLCYLabel(): Text
    begin
        exit(TotalAmountLCYLbl);
    end;

    internal procedure GetOverdueBalanceLabel(): Text
    begin
        exit(OverdueBalanceLbl);
    end;

    internal procedure GetSalesLCYLabel(): Text
    begin
        exit(SalesLCYLbl);
    end;

    internal procedure GetInvoicedPrepmtAmountLCYLabel(): Text
    begin
        exit(InvoicedPrepmtAmountLCYLbl);
    end;

    internal procedure GetCustomerNoLabel(): Text
    begin
        exit(CustomerNoLbl);
    end;

    internal procedure GetBalanceAsVendorLabel(): Text
    begin
        exit(BalanceAsVendorLbl);
    end;

    internal procedure GetLinkedVendorNoLabel(): Text
    begin
        exit(LinkedVendorNoLbl);
    end;

    internal procedure GetInvoicedShipmentAmountLCYLabel(): Text
    begin
        exit(InvoicedShipmentAmountLCYLbl);
    end;

    internal procedure GetReturnRcdNotInvAmountLCYLabel(): Text
    begin
        exit(ReturnRcdNotInvAmountLCYLbl);
    end;

    /// <summary>
    /// Raised to allow calculation of custom customer statistics.
    /// </summary>
    /// <param name="Params">The input parameters for the calculation.</param>
    /// <param name="Results">The dictionary to populate with calculated statistics.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalculateCustomerStatistics(Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
    end;
}
