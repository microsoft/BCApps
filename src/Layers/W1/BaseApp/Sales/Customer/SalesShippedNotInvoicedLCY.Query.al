#if not CLEAN28
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;

query 115 "Sales Shipped Not Invoiced LCY"
{
    Caption = 'Sales Shipped Not Invoiced (LCY)';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    ObsoleteReason = 'Not used, as Customer.GetShippedFromOrderLCYAmountLCY() procedure is no longer used in GetTotalAmountLCYCommon procedure.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    elements
    {
        dataitem(SalesShipmentLine; "Sales Shipment Line")
        {
            column(BillToCustomerNo; "Bill-to Customer No.") { }
            column(OrderNo; "Order No.") { }
            column(OrderLineNo; "Order Line No.") { }
            filter(BillToCustomerNoFilter; "Bill-to Customer No.") { }
            filter(OrderNoFilter; "Order No.") { }
            filter(OrderLineNoFilter; "Order Line No.") { }
            dataitem(SalesLine; "Sales Line")
            {
                DataItemTableFilter = "Document Type" = const(Order);
                DataItemLink = "Document No." = SalesShipmentLine."Order No.",
                               "Line No." = SalesShipmentLine."Order Line No.";
                column(ShippedNotInvoicedLCY; "Shipped Not Invoiced (LCY)") { }
            }
        }
    }
}
#endif