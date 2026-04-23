// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;

/// <summary>
/// Codeunit Shpfy Cust. Mapping Filter Sub. (ID 139700).
/// Helper subscriber used by Shpfy Customer Mapping Test to verify that
/// filters set on the Customer record via OnBeforeFindMapping are respected.
/// </summary>
codeunit 139700 "Shpfy Cust. Mapping Filter Sub"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        CustomerNoFilter: Code[20];

    internal procedure SetCustomerNoFilter(CustomerNo: Code[20])
    begin
        CustomerNoFilter := CustomerNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Customer Events", 'OnBeforeFindMapping', '', false, false)]
    local procedure OnBeforeFindMapping(Direction: Enum "Shpfy Mapping Direction"; var ShopifyCustomer: Record "Shpfy Customer"; var Customer: Record Customer; var Handled: Boolean)
    begin
        if CustomerNoFilter <> '' then
            Customer.SetRange("No.", CustomerNoFilter);
    end;
}
