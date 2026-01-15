// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;

interface "PEPPOL Delivery Info Provider"
{
    /// <summary>
    /// Gets delivery information for PEPPOL documents.
    /// </summary>
    /// <param name="ActualDeliveryDate">Return value: Actual delivery date.</param>
    /// <param name="DeliveryID">Return value: Delivery ID.</param>
    /// <param name="DeliveryIDSchemeID">Return value: Delivery ID scheme ID.</param>
    procedure GetDeliveryInfo(var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)

    /// <summary>
    /// Gets GLN delivery information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ActualDeliveryDate">Return value: Actual delivery date.</param>
    /// <param name="DeliveryID">Return value: Delivery ID.</param>
    /// <param name="DeliveryIDSchemeID">Return value: Delivery ID scheme ID.</param>
    procedure GetGLNDeliveryInfo(SalesHeader: Record "Sales Header"; var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)

    /// <summary>
    /// Gets the GLN (Global Location Number) for the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <returns>The GLN code.</returns>
    procedure GetGLNForHeader(SalesHeader: Record "Sales Header"): Code[13]

    /// <summary>
    /// Gets delivery address information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="DeliveryStreetName">Return value: Delivery street name.</param>
    /// <param name="DeliveryAdditionalStreetName">Return value: Delivery additional street name.</param>
    /// <param name="DeliveryCityName">Return value: Delivery city name.</param>
    /// <param name="DeliveryPostalZone">Return value: Delivery postal zone.</param>
    /// <param name="DeliveryCountrySubentity">Return value: Delivery country subentity.</param>
    /// <param name="DeliveryCountryIdCode">Return value: Delivery country ID code.</param>
    /// <param name="DeliveryCountryListID">Return value: Delivery country list ID.</param>
    procedure GetDeliveryAddress(SalesHeader: Record "Sales Header"; var DeliveryStreetName: Text; var DeliveryAdditionalStreetName: Text; var DeliveryCityName: Text; var DeliveryPostalZone: Text; var DeliveryCountrySubentity: Text; var DeliveryCountryIdCode: Text; var DeliveryCountryListID: Text)

    /// <summary>
    /// Gets delivery party name information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="DeliveryPartyName">Return value: Delivery party name.</param>
    procedure GetDeliveryPartyName(SalesHeader: Record "Sales Header"; var DeliveryPartyName: Text)
}