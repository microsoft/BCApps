// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Purchases.Document;

interface "PEPPOL Purchase Party Info Provider"
{
    /// <summary>
    /// Gets accounting supplier (buyer) party information for PEPPOL BIS format from company information.
    /// </summary>
    /// <param name="SupplierEndpointID">Returns the supplier endpoint ID.</param>
    /// <param name="SupplierSchemeID">Returns the supplier scheme ID.</param>
    /// <param name="SupplierName">Returns the supplier name.</param>
    procedure GetAccountingSupplierPartyInfoBIS(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)

    /// <summary>
    /// Gets accounting supplier (buyer) party legal entity information for PEPPOL BIS format from company information.
    /// </summary>
    /// <param name="PartyLegalEntityRegName">Returns the party legal entity registration name.</param>
    /// <param name="PartyLegalEntityCompanyID">Returns the party legal entity company ID.</param>
    /// <param name="PartyLegalEntitySchemeID">Returns the party legal entity scheme ID.</param>
    /// <param name="SupplierRegAddrCityName">Returns the supplier registration address city name.</param>
    /// <param name="SupplierRegAddrCountryIdCode">Returns the supplier registration address country ID code.</param>
    /// <param name="SupplRegAddrCountryIdListId">Returns the supplier registration address country list ID.</param>
    procedure GetAccountingSupplierPartyLegalEntityBIS(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)

    /// <summary>
    /// Gets accounting supplier (buyer) party tax scheme information from company information.
    /// </summary>
    /// <param name="CompanyID">Returns the company VAT registration ID.</param>
    /// <param name="CompanyIDSchemeID">Returns the company ID scheme ID.</param>
    /// <param name="TaxSchemeID">Returns the tax scheme ID.</param>
    procedure GetAccountingSupplierPartyTaxScheme(var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)

    /// <summary>
    /// Gets seller supplier (vendor) party information for BIS format from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="SellerSupplierPartyEndpointId">Returns the seller supplier party endpoint ID.</param>
    /// <param name="SellerSupplierPartySchemeID">Returns the seller supplier party scheme ID.</param>
    /// <param name="SellerSupplierPartySupplierName">Returns the seller supplier party name.</param>
    procedure GetSellerSupplierPartyInfoBIS(PurchaseHeader: Record "Purchase Header"; var SellerSupplierPartyEndpointId: Text; var SellerSupplierPartySchemeID: Text; var SellerSupplierPartySupplierName: Text)

    /// <summary>
    /// Gets seller supplier (vendor) party postal address information from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="SellerSupplierStreetName">Returns the seller supplier street name.</param>
    /// <param name="SellerSupplierAdditionalStreetName">Returns the seller supplier additional street name.</param>
    /// <param name="SellerSupplierPartyCityName">Returns the seller supplier party city name.</param>
    /// <param name="SellerSupplierPartyPostalZone">Returns the seller supplier party postal zone.</param>
    /// <param name="SellerSupplierPartyCountrySubentity">Returns the seller supplier party country subentity.</param>
    /// <param name="SellerSupplierPartyIdentificationCode">Returns the seller supplier party country identification code.</param>
    /// <param name="ListID">Returns the country list ID.</param>
    procedure GetSellerSupplierPartyPostalAddr(PurchaseHeader: Record "Purchase Header"; var SellerSupplierStreetName: Text; var SellerSupplierAdditionalStreetName: Text; var SellerSupplierPartyCityName: Text; var SellerSupplierPartyPostalZone: Text; var SellerSupplierPartyCountrySubentity: Text; var SellerSupplierPartyIdentificationCode: Text; var ListID: Text)

    /// <summary>
    /// Gets seller supplier (vendor) party contact information from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="ContactName">Returns the contact name.</param>
    /// <param name="ContactPhone">Returns the contact phone number.</param>
    /// <param name="ContactTelefax">Returns the contact telefax number.</param>
    /// <param name="ContactEmail">Returns the contact email address.</param>
    procedure GetSellerSupplierPartyContact(PurchaseHeader: Record "Purchase Header"; var ContactName: Text; var ContactPhone: Text; var ContactTelefax: Text; var ContactEmail: Text)

    /// <summary>
    /// Gets buyer customer party postal address information from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="StreetName">Returns the customer street name.</param>
    /// <param name="BuyerCustomerAdditionalStreetName">Returns the customer additional street name.</param>
    /// <param name="CityName">Returns the customer city name.</param>
    /// <param name="PostalZone">Returns the customer postal zone.</param>
    /// <param name="CountrySubentity">Returns the customer country subentity.</param>
    /// <param name="IdentificationCode">Returns the customer country identification code.</param>
    /// <param name="ListID">Returns the country list ID.</param>
    procedure GetBuyerCustomerPartyPostalAddr(PurchaseHeader: Record "Purchase Header"; var StreetName: Text; var BuyerCustomerAdditionalStreetName: Text; var CityName: Text; var PostalZone: Text; var CountrySubentity: Text; var IdentificationCode: Text; var ListID: Text)

    /// <summary>
    /// Gets buyer customer party contact information from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="BuyerCustomerPartyContactName">Returns the buyer customer party contact name.</param>
    /// <param name="BuyerCustomerPartyContactPhone">Returns the buyer customer party contact phone number.</param>
    /// <param name="BuyerCustomerPartyContactEmail">Returns the buyer customer party contact email address.</param>
    procedure GetBuyerCustomerPartyContact(PurchaseHeader: Record "Purchase Header"; var BuyerCustomerPartyContactName: Text; var BuyerCustomerPartyContactPhone: Text; var BuyerCustomerPartyContactEmail: Text)
}
