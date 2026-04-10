// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the printing options available for unposted sales orders.
/// </summary>
enum 229 "Sales Order Print Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies printing an order confirmation document to send to the customer.
    /// </summary>
    value(1; "Order Confirmation")
    {
        Caption = 'Order Confirmation';
    }
    /// <summary>
    /// Specifies printing a pro forma invoice to provide customers with a preliminary billing document.
    /// </summary>
    value(2; "Pro Forma Invoice")
    {
        Caption = 'Pro Forma Invoice';
    }
    /// <summary>
    /// Specifies printing a work order document for internal production or fulfillment operations.
    /// </summary>
    value(3; "Work Order")
    {
        Caption = 'Work Order';
    }
    /// <summary>
    /// Specifies printing pick instructions for warehouse staff to fulfill the sales order.
    /// </summary>
    value(4; "Pick Instruction")
    {
        Caption = 'Pick Instruction';
    }
}
