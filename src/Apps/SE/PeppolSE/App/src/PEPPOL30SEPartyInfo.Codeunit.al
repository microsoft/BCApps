// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.SE;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Company;
using Microsoft.Peppol;
using Microsoft.Sales.Document;

/// <summary>
/// SE-specific PEPPOL party info provider. Scheme 0007 (SE:ORGNR) requires the 10-digit Swedish
/// organisation number in endpoint and legal entity identifiers, so the full VAT registration
/// number (SE + organisation number + 01) is reduced to the organisation number wherever the
/// identifier is emitted under that scheme. The party tax scheme keeps the full VAT registration
/// number. All other methods pass through to the W1 standard implementation.
/// </summary>
codeunit 37451 "PEPPOL30 SE Party Info" implements "PEPPOL Party Info Provider"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        StandardProvider: Codeunit "PEPPOL30";

    procedure GetAccountingSupplierPartyInfo(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        StandardProvider.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);
    end;

    procedure GetAccountingSupplierPartyInfoBIS(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        // Run W1 first.
        StandardProvider.GetAccountingSupplierPartyInfoBIS(SupplierEndpointID, SupplierSchemeID, SupplierName);
        // SE override: an endpoint under scheme 0007 (SE:ORGNR) must carry the 10-digit organisation number.
        if SupplierSchemeID = GetSwedishOrgNoSchemeID() then
            SupplierEndpointID := GetSwedishOrgNo(SupplierEndpointID);
    end;

    procedure GetAccountingSupplierPartyPostalAddr(SalesHeader: Record "Sales Header"; var StreetName: Text; var SupplierAdditionalStreetName: Text; var CityName: Text; var PostalZone: Text; var CountrySubentity: Text; var IdentificationCode: Text; var ListID: Text)
    begin
        StandardProvider.GetAccountingSupplierPartyPostalAddr(SalesHeader, StreetName, SupplierAdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);
    end;

    procedure GetAccountingSupplierPartyTaxScheme(var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    begin
        StandardProvider.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
    end;

    procedure GetAccountingSupplierPartyTaxSchemeBIS(var VATAmtLine: Record "VAT Amount Line"; var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    begin
        StandardProvider.GetAccountingSupplierPartyTaxSchemeBIS(VATAmtLine, CompanyID, CompanyIDSchemeID, TaxSchemeID);
    end;

    procedure GetAccountingSupplierPartyLegalEntity(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        StandardProvider.GetAccountingSupplierPartyLegalEntity(PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);
    end;

    procedure GetAccountingSupplierPartyLegalEntityBIS(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        // Run W1 first.
        StandardProvider.GetAccountingSupplierPartyLegalEntityBIS(PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);
        // SE override: reduce the plain VAT registration number to the organisation number when the
        // company is registered under scheme 0007. A non-empty scheme means the GLN or DK path was taken.
        if PartyLegalEntitySchemeID <> '' then
            exit;
        CompanyInformation.SetLoadFields("Country/Region Code");
        CompanyInformation.Get();
        if StandardProvider.GetVATScheme(CompanyInformation."Country/Region Code") = GetSwedishOrgNoSchemeID() then
            PartyLegalEntityCompanyID := GetSwedishOrgNo(PartyLegalEntityCompanyID);
    end;

    procedure GetAccountingSupplierPartyContact(SalesHeader: Record "Sales Header"; var ContactID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)
    begin
        StandardProvider.GetAccountingSupplierPartyContact(SalesHeader, ContactID, ContactName, Telephone, Telefax, ElectronicMail);
    end;

    procedure GetAccountingSupplierPartyIdentificationID(SalesHeader: Record "Sales Header"; var PartyIdentificationID: Text)
    begin
        StandardProvider.GetAccountingSupplierPartyIdentificationID(SalesHeader, PartyIdentificationID);
    end;

    procedure GetAccountingCustomerPartyInfo(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        StandardProvider.GetAccountingCustomerPartyInfo(SalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName);
    end;

    procedure GetAccountingCustomerPartyInfoBIS(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        // Run W1 first.
        StandardProvider.GetAccountingCustomerPartyInfoBIS(SalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName);
        // SE override: an endpoint under scheme 0007 (SE:ORGNR) must carry the 10-digit organisation number.
        if CustomerSchemeID = GetSwedishOrgNoSchemeID() then
            CustomerEndpointID := GetSwedishOrgNo(CustomerEndpointID);
    end;

    procedure GetAccountingCustomerPartyPostalAddr(SalesHeader: Record "Sales Header"; var CustomerStreetName: Text; var CustomerAdditionalStreetName: Text; var CustomerCityName: Text; var CustomerPostalZone: Text; var CustomerCountrySubentity: Text; var CustomerIdentificationCode: Text; var CustomerListID: Text)
    begin
        StandardProvider.GetAccountingCustomerPartyPostalAddr(SalesHeader, CustomerStreetName, CustomerAdditionalStreetName, CustomerCityName, CustomerPostalZone, CustomerCountrySubentity, CustomerIdentificationCode, CustomerListID);
    end;

    procedure GetAccountingCustomerPartyTaxScheme(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        StandardProvider.GetAccountingCustomerPartyTaxScheme(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);
    end;

    procedure GetAccountingCustomerPartyTaxSchemeBIS(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        StandardProvider.GetAccountingCustomerPartyTaxSchemeBIS(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);
    end;

    procedure GetAccountingCustomerPartyTaxSchemeBIS30(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        StandardProvider.GetAccountingCustomerPartyTaxSchemeBIS30(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, TempVATAmountLine);
    end;

    procedure GetAccountingCustomerPartyLegalEntity(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        StandardProvider.GetAccountingCustomerPartyLegalEntity(SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);
    end;

    procedure GetAccountingCustomerPartyLegalEntityBIS(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        // Run W1 first.
        StandardProvider.GetAccountingCustomerPartyLegalEntityBIS(SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);
        // SE override: reduce the plain VAT registration number to the organisation number when the
        // customer is registered under scheme 0007. A non-empty scheme means the GLN or DK path was taken.
        if CustPartyLegalEntityIDSchemeID <> '' then
            exit;
        if StandardProvider.GetVATScheme(SalesHeader."Bill-to Country/Region Code") = GetSwedishOrgNoSchemeID() then
            CustPartyLegalEntityCompanyID := GetSwedishOrgNo(CustPartyLegalEntityCompanyID);
    end;

    procedure GetAccountingCustomerPartyContact(SalesHeader: Record "Sales Header"; var CustContactID: Text; var CustContactName: Text; var CustContactTelephone: Text; var CustContactTelefax: Text; var CustContactElectronicMail: Text)
    begin
        StandardProvider.GetAccountingCustomerPartyContact(SalesHeader, CustContactID, CustContactName, CustContactTelephone, CustContactTelefax, CustContactElectronicMail);
    end;

    procedure GetPayeePartyInfo(var PayeePartyID: Text; var PayeePartyIDSchemeID: Text; var PayeePartyNameName: Text; var PayeePartyLegalEntityCompanyID: Text; var PayeePartyLegalCompIDSchemeID: Text)
    begin
        StandardProvider.GetPayeePartyInfo(PayeePartyID, PayeePartyIDSchemeID, PayeePartyNameName, PayeePartyLegalEntityCompanyID, PayeePartyLegalCompIDSchemeID);
    end;

    procedure GetTaxRepresentativePartyInfo(var TaxRepPartyNameName: Text; var PayeePartyTaxSchemeCompanyID: Text; var PayeePartyTaxSchCompIDSchemeID: Text; var PayeePartyTaxSchemeTaxSchemeID: Text)
    begin
        StandardProvider.GetTaxRepresentativePartyInfo(TaxRepPartyNameName, PayeePartyTaxSchemeCompanyID, PayeePartyTaxSchCompIDSchemeID, PayeePartyTaxSchemeTaxSchemeID);
    end;

    local procedure GetSwedishOrgNoSchemeID(): Text
    begin
        exit('0007');
    end;

    local procedure GetSwedishOrgNo(VATRegistrationNo: Text): Text
    var
        DigitsOnly: Text;
    begin
        // Keep only digits: the inner DelChr removes all digits, leaving the non-digit characters as a mask;
        // the outer DelChr then removes that mask from the original, so only the digits remain.
        DigitsOnly := DelChr(VATRegistrationNo, '=', DelChr(VATRegistrationNo, '=', '0123456789'));
        if StrLen(DigitsOnly) >= 10 then
            exit(CopyStr(DigitsOnly, 1, 10));
        exit(VATRegistrationNo);
    end;
}
