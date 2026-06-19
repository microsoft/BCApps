// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Purchases.Document;

interface "PEPPOL Purchase Delivery Info Provider"
{
    /// <summary>
    /// Gets delivery address information from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="StreetName">Returns the delivery street name.</param>
    /// <param name="AdditionalStreetName">Returns the delivery additional street name.</param>
    /// <param name="CityName">Returns the delivery city name.</param>
    /// <param name="PostalZone">Returns the delivery postal zone.</param>
    /// <param name="CountrySubentity">Returns the delivery country subentity.</param>
    /// <param name="IdentificationCode">Returns the delivery country identification code.</param>
    /// <param name="ListID">Returns the delivery country list ID.</param>
    procedure GetDeliveryAddress(PurchaseHeader: Record "Purchase Header"; var StreetName: Text; var AdditionalStreetName: Text; var CityName: Text; var PostalZone: Text; var CountrySubentity: Text; var IdentificationCode: Text; var ListID: Text)
}
