// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Document;

interface "PEPPOL Party Info Provider"
{
    /// <summary>
    /// Gets accounting supplier party information for PEPPOL documents.
    /// </summary>
    /// <param name="SupplierEndpointID">Return value: Supplier endpoint ID.</param>
    /// <param name="SupplierSchemeID">Return value: Supplier scheme ID.</param>
    /// <param name="SupplierName">Return value: Supplier name.</param>
    procedure GetAccountingSupplierPartyInfo(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)

    /// <summary>
    /// Gets accounting supplier party information for PEPPOL BIS format.
    /// </summary>
    /// <param name="SupplierEndpointID">Return value: Supplier endpoint ID.</param>
    /// <param name="SupplierSchemeID">Return value: Supplier scheme ID.</param>
    /// <param name="SupplierName">Return value: Supplier name.</param>
    procedure GetAccountingSupplierPartyInfoBIS(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)

    /// <summary>
    /// Gets accounting supplier party postal address information.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="StreetName">Return value: Street name.</param>
    /// <param name="SupplierAdditionalStreetName">Return value: Additional street name.</param>
    /// <param name="CityName">Return value: City name.</param>
    /// <param name="PostalZone">Return value: Postal zone.</param>
    /// <param name="CountrySubentity">Return value: Country subentity.</param>
    /// <param name="IdentificationCode">Return value: Country identification code.</param>
    /// <param name="ListID">Return value: Country list ID.</param>
    procedure GetAccountingSupplierPartyPostalAddr(SalesHeader: Record "Sales Header"; var StreetName: Text; var SupplierAdditionalStreetName: Text; var CityName: Text; var PostalZone: Text; var CountrySubentity: Text; var IdentificationCode: Text; var ListID: Text)

    /// <summary>
    /// Gets accounting supplier party tax scheme information.
    /// </summary>
    /// <param name="CompanyID">Return value: Company ID.</param>
    /// <param name="CompanyIDSchemeID">Return value: Company ID scheme ID.</param>
    /// <param name="TaxSchemeID">Return value: Tax scheme ID.</param>
    procedure GetAccountingSupplierPartyTaxScheme(var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)

/// <summary>
/// Gets accounting supplier party tax scheme information for PEPPOL BIS format.
/// </summary>
/// <param name="VATAmtLine">The VAT amount line record.</param>
/// <param name="CompanyID">Return value: Company ID.</param>
/// <param name="CompanyIDSchemeID">Return value: Company ID scheme ID.</param>
/// <param name="TaxSchemeID">Return value: Tax scheme ID.</param>
procedure GetAccountingSupplierPartyTaxSchemeBIS(var VATAmtLine: Record "VAT Amount Line"; var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)

    /// <summary>
    /// Gets accounting supplier party legal entity information.
    /// </summary>
    /// <param name="PartyLegalEntityRegName">Return value: Legal entity registration name.</param>
    /// <param name="PartyLegalEntityCompanyID">Return value: Legal entity company ID.</param>
    /// <param name="PartyLegalEntitySchemeID">Return value: Legal entity scheme ID.</param>
    /// <param name="SupplierRegAddrCityName">Return value: Supplier registration address city name.</param>
    /// <param name="SupplierRegAddrCountryIdCode">Return value: Supplier registration address country code.</param>
    /// <param name="SupplRegAddrCountryIdListId">Return value: Supplier registration address country list ID.</param>
    procedure GetAccountingSupplierPartyLegalEntity(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)

    /// <summary>
    /// Gets accounting supplier party legal entity information for PEPPOL BIS format.
    /// </summary>
    /// <param name="PartyLegalEntityRegName">Return value: Legal entity registration name.</param>
    /// <param name="PartyLegalEntityCompanyID">Return value: Legal entity company ID.</param>
    /// <param name="PartyLegalEntitySchemeID">Return value: Legal entity scheme ID.</param>
    /// <param name="SupplierRegAddrCityName">Return value: Supplier registration address city name.</param>
    /// <param name="SupplierRegAddrCountryIdCode">Return value: Supplier registration address country code.</param>
    /// <param name="SupplRegAddrCountryIdListId">Return value: Supplier registration address country list ID.</param>
    procedure GetAccountingSupplierPartyLegalEntityBIS(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)

    /// <summary>
    /// Gets accounting supplier party contact information.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ContactID">Return value: Contact ID.</param>
    /// <param name="ContactName">Return value: Contact name.</param>
    /// <param name="Telephone">Return value: Telephone number.</param>
    /// <param name="Telefax">Return value: Telefax number.</param>
    /// <param name="ElectronicMail">Return value: Electronic mail address.</param>
    procedure GetAccountingSupplierPartyContact(SalesHeader: Record "Sales Header"; var ContactID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)

    /// <summary>
    /// Gets accounting supplier party identification ID.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="PartyIdentificationID">Return value: Party identification ID.</param>
    procedure GetAccountingSupplierPartyIdentificationID(SalesHeader: Record "Sales Header"; var PartyIdentificationID: Text)

    /// <summary>
    /// Gets accounting customer party information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="CustomerEndpointID">Return value: Customer endpoint ID.</param>
    /// <param name="CustomerSchemeID">Return value: Customer scheme ID.</param>
    /// <param name="CustomerPartyIdentificationID">Return value: Customer party identification ID.</param>
    /// <param name="CustomerPartyIDSchemeID">Return value: Customer party ID scheme ID.</param>
    /// <param name="CustomerName">Return value: Customer name.</param>
    procedure GetAccountingCustomerPartyInfo(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)

    /// <summary>
    /// Gets accounting customer party information for PEPPOL BIS format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="CustomerEndpointID">Return value: Customer endpoint ID.</param>
    /// <param name="CustomerSchemeID">Return value: Customer scheme ID.</param>
    /// <param name="CustomerPartyIdentificationID">Return value: Customer party identification ID.</param>
    /// <param name="CustomerPartyIDSchemeID">Return value: Customer party ID scheme ID.</param>
    /// <param name="CustomerName">Return value: Customer name.</param>
    procedure GetAccountingCustomerPartyInfoBIS(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)

    /// <summary>
    /// Gets accounting customer party postal address information.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="CustomerStreetName">Return value: Customer street name.</param>
    /// <param name="CustomerAdditionalStreetName">Return value: Customer additional street name.</param>
    /// <param name="CustomerCityName">Return value: Customer city name.</param>
    /// <param name="CustomerPostalZone">Return value: Customer postal zone.</param>
    /// <param name="CustomerCountrySubentity">Return value: Customer country subentity.</param>
    /// <param name="CustomerIdentificationCode">Return value: Customer country identification code.</param>
    /// <param name="CustomerListID">Return value: Customer country list ID.</param>
    procedure GetAccountingCustomerPartyPostalAddr(SalesHeader: Record "Sales Header"; var CustomerStreetName: Text; var CustomerAdditionalStreetName: Text; var CustomerCityName: Text; var CustomerPostalZone: Text; var CustomerCountrySubentity: Text; var CustomerIdentificationCode: Text; var CustomerListID: Text)

    /// <summary>
    /// Gets accounting customer party tax scheme information.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="CustPartyTaxSchemeCompanyID">Return value: Customer party tax scheme company ID.</param>
    /// <param name="CustPartyTaxSchemeCompIDSchID">Return value: Customer party tax scheme company ID scheme ID.</param>
    /// <param name="CustTaxSchemeID">Return value: Customer tax scheme ID.</param>
    procedure GetAccountingCustomerPartyTaxScheme(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)

    /// <summary>
    /// Gets accounting customer party tax scheme information for PEPPOL BIS format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="CustPartyTaxSchemeCompanyID">Return value: Customer party tax scheme company ID.</param>
    /// <param name="CustPartyTaxSchemeCompIDSchID">Return value: Customer party tax scheme company ID scheme ID.</param>
    /// <param name="CustTaxSchemeID">Return value: Customer tax scheme ID.</param>
    procedure GetAccountingCustomerPartyTaxSchemeBIS(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)

/// <summary>
/// Gets accounting customer party tax scheme information for PEPPOL BIS 3.0 format.
/// </summary>
/// <param name="SalesHeader">The sales header record.</param>
/// <param name="CustPartyTaxSchemeCompanyID">Return value: Customer party tax scheme company ID.</param>
/// <param name="CustPartyTaxSchemeCompIDSchID">Return value: Customer party tax scheme company ID scheme ID.</param>
/// <param name="CustTaxSchemeID">Return value: Customer tax scheme ID.</param>
/// <param name="TempVATAmountLine">The temporary VAT amount line record.</param>
procedure GetAccountingCustomerPartyTaxSchemeBIS30(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text; var TempVATAmountLine: Record "VAT Amount Line" temporary)

    /// <summary>
    /// Gets accounting customer party legal entity information.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="CustPartyLegalEntityRegName">Return value: Customer party legal entity registration name.</param>
    /// <param name="CustPartyLegalEntityCompanyID">Return value: Customer party legal entity company ID.</param>
    /// <param name="CustPartyLegalEntityIDSchemeID">Return value: Customer party legal entity ID scheme ID.</param>
    procedure GetAccountingCustomerPartyLegalEntity(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)

    /// <summary>
    /// Gets accounting customer party legal entity information for PEPPOL BIS format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="CustPartyLegalEntityRegName">Return value: Customer party legal entity registration name.</param>
    /// <param name="CustPartyLegalEntityCompanyID">Return value: Customer party legal entity company ID.</param>
    /// <param name="CustPartyLegalEntityIDSchemeID">Return value: Customer party legal entity ID scheme ID.</param>
    procedure GetAccountingCustomerPartyLegalEntityBIS(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)

    /// <summary>
    /// Gets accounting customer party contact information.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="CustContactID">Return value: Customer contact ID.</param>
    /// <param name="CustContactName">Return value: Customer contact name.</param>
    /// <param name="CustContactTelephone">Return value: Customer contact telephone.</param>
    /// <param name="CustContactTelefax">Return value: Customer contact telefax.</param>
    /// <param name="CustContactElectronicMail">Return value: Customer contact electronic mail.</param>
    procedure GetAccountingCustomerPartyContact(SalesHeader: Record "Sales Header"; var CustContactID: Text; var CustContactName: Text; var CustContactTelephone: Text; var CustContactTelefax: Text; var CustContactElectronicMail: Text)

    /// <summary>
    /// Gets payee party information for PEPPOL documents.
    /// </summary>
    /// <param name="PayeePartyID">Return value: Payee party ID.</param>
    /// <param name="PayeePartyIDSchemeID">Return value: Payee party ID scheme ID.</param>
    /// <param name="PayeePartyNameName">Return value: Payee party name.</param>
    /// <param name="PayeePartyLegalEntityCompanyID">Return value: Payee party legal entity company ID.</param>
    /// <param name="PayeePartyLegalCompIDSchemeID">Return value: Payee party legal company ID scheme ID.</param>
    procedure GetPayeePartyInfo(var PayeePartyID: Text; var PayeePartyIDSchemeID: Text; var PayeePartyNameName: Text; var PayeePartyLegalEntityCompanyID: Text; var PayeePartyLegalCompIDSchemeID: Text)

    /// <summary>
    /// Gets tax representative party information for PEPPOL documents.
    /// </summary>
    /// <param name="TaxRepPartyNameName">Return value: Tax representative party name.</param>
    /// <param name="PayeePartyTaxSchemeCompanyID">Return value: Tax representative party tax scheme company ID.</param>
    /// <param name="PayeePartyTaxSchCompIDSchemeID">Return value: Tax representative party tax scheme company ID scheme ID.</param>
    /// <param name="PayeePartyTaxSchemeTaxSchemeID">Return value: Tax representative party tax scheme ID.</param>
    procedure GetTaxRepresentativePartyInfo(var TaxRepPartyNameName: Text; var PayeePartyTaxSchemeCompanyID: Text; var PayeePartyTaxSchCompIDSchemeID: Text; var PayeePartyTaxSchemeTaxSchemeID: Text)
}