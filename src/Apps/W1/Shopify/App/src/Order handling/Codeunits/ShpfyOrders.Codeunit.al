// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Provides functionality for managing Shopify orders.
/// </summary>
codeunit 30409 "Shpfy Orders"
{
    Access = Public;

    var
        OrdersAPI: Codeunit "Shpfy Orders API";

    /// <summary>
    /// Marks the specified order as paid in Shopify.
    /// </summary>
    /// <param name="OrderId">The ID of the order to mark as paid.</param>
    /// <param name="ShopCode">The code of the Shopify shop record.</param>
    /// <returns>True if the operation was successful; otherwise, false.</returns>
    procedure MarkAsPaid(OrderId: BigInteger; ShopCode: Code[20]): Boolean
    begin
        exit(OrdersAPI.MarkAsPaid(OrderId, ShopCode));
    end;

    /// <summary>
    /// Cancels the specified order in Shopify with the given options.
    /// </summary>
    /// <param name="OrderId">The ID of the order to cancel.</param>
    /// <param name="ShopCode">The code of the Shopify shop record.</param>
    /// <param name="NotifyCustomer">Indicates whether to notify the customer about the cancellation.</param>
    /// <param name="CancelReason">The reason for cancelling the order.</param>
    /// <param name="Refund">Indicates whether to refund the amount paid by the customer.</param>
    /// <param name="Restock">Indicates whether to restock the inventory committed to the order.</param>
    /// <returns>True if the operation was successful; otherwise, false.</returns>
    procedure CancelOrder(OrderId: BigInteger; ShopCode: Code[20]; NotifyCustomer: Boolean; CancelReason: Enum "Shpfy Cancel Reason"; Refund: Boolean; Restock: Boolean): Boolean
    begin
        exit(OrdersAPI.CancelOrder(OrderId, ShopCode, NotifyCustomer, CancelReason, Refund, Restock));
    end;
}
