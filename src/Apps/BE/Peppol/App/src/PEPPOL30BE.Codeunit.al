// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.BE;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Peppol;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 37310 "PEPPOL30 BE" implements "PEPPOL Party Info Provider"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PEPPOL30: Codeunit "PEPPOL30";
        GLNTxt: Label 'GLN', Locked = true;
        VATTxt: Label 'VAT', Locked = true;

    procedure GetAccountingSupplierPartyInfo(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        GetAccountingSupplierPartyInfoByFormat(SupplierEndpointID, SupplierSchemeID, SupplierName, false);
    end;

    procedure GetAccountingSupplierPartyInfoBIS(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        GetAccountingSupplierPartyInfoByFormat(SupplierEndpointID, SupplierSchemeID, SupplierName, true);
    end;

    local procedure GetAccountingSupplierPartyInfoByFormat(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text; IsBISBilling: Boolean)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if (CompanyInfo.GLN <> '') and CompanyInfo."Use GLN in Electronic Document" then begin
            SupplierEndpointID := CompanyInfo.GLN;
            SupplierSchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
        end else begin
            SupplierEndpointID :=
              FormatVATRegistrationNo(CompanyInfo.GetVATRegistrationNumber(), CompanyInfo."Country/Region Code", IsBISBilling, false);
            SupplierSchemeID := PEPPOL30.GetVATScheme(CompanyInfo."Country/Region Code");
        end;

        SupplierName := CompanyInfo.Name;
    end;

    procedure GetAccountingSupplierPartyPostalAddr(SalesHeader: Record "Sales Header"; var StreetName: Text; var SupplierAdditionalStreetName: Text; var CityName: Text; var PostalZone: Text; var CountrySubentity: Text; var IdentificationCode: Text; var ListID: Text)
    begin
        PEPPOL30.GetAccountingSupplierPartyPostalAddr(SalesHeader, StreetName, SupplierAdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);
    end;

    procedure GetAccountingSupplierPartyTaxScheme(var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyID := FormatVATRegistrationNo(CompanyInfo.GetVATRegistrationNumber(), CompanyInfo."Country/Region Code", true, true);
        CompanyIDSchemeID := PEPPOL30.GetVATScheme(CompanyInfo."Country/Region Code");
        TaxSchemeID := VATTxt;
    end;

    procedure GetAccountingSupplierPartyTaxSchemeBIS(var VATAmtLine: Record "VAT Amount Line"; var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    begin
        VATAmtLine.SetFilter("Tax Category", '<>%1', GetTaxCategoryO());
        if not VATAmtLine.IsEmpty() then
            GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
        VATAmtLine.SetRange("Tax Category");
        CompanyID := DelChr(CompanyID);
        CompanyIDSchemeID := '';
    end;

    procedure GetAccountingSupplierPartyLegalEntity(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        GetAccountingSupplierPartyLegalEntityByFormat(
          PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID,
          SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId, false);
    end;

    procedure GetAccountingSupplierPartyLegalEntityBIS(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        GetAccountingSupplierPartyLegalEntityByFormat(
          PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID,
          SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId, true);
    end;

    local procedure GetAccountingSupplierPartyLegalEntityByFormat(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text; IsBISBilling: Boolean)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        PartyLegalEntityRegName := CompanyInfo.Name;
        if (CompanyInfo.GLN <> '') and CompanyInfo."Use GLN in Electronic Document" then begin
            PartyLegalEntityCompanyID := CompanyInfo.GLN;
            PartyLegalEntitySchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
        end else begin
            PartyLegalEntityCompanyID :=
              FormatVATRegistrationNo(CompanyInfo.GetVATRegistrationNumber(), CompanyInfo."Country/Region Code", IsBISBilling, false);
            PartyLegalEntitySchemeID := GetVATSchemeByFormat(CompanyInfo."Country/Region Code", IsBISBilling);
        end;

        SupplierRegAddrCityName := CompanyInfo.City;
        SupplierRegAddrCountryIdCode := GetCountryISOCode(CompanyInfo."Country/Region Code");
        SupplRegAddrCountryIdListId := GetISO3166_1Alpha2();
    end;

    procedure GetAccountingSupplierPartyContact(SalesHeader: Record "Sales Header"; var ContactID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)
    begin
        PEPPOL30.GetAccountingSupplierPartyContact(SalesHeader, ContactID, ContactName, Telephone, Telefax, ElectronicMail);
    end;

    procedure GetAccountingSupplierPartyIdentificationID(SalesHeader: Record "Sales Header"; var PartyIdentificationID: Text)
    begin
        PEPPOL30.GetAccountingSupplierPartyIdentificationID(SalesHeader, PartyIdentificationID);
    end;

    procedure GetAccountingCustomerPartyInfo(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        GetAccountingCustomerPartyInfoByFormat(
          SalesHeader, CustomerEndpointID, CustomerSchemeID,
          CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName, false);
    end;

    procedure GetAccountingCustomerPartyInfoBIS(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        GetAccountingCustomerPartyInfoByFormat(
          SalesHeader, CustomerEndpointID, CustomerSchemeID,
          CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName, true);
    end;

    local procedure GetAccountingCustomerPartyInfoByFormat(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text; IsBISBilling: Boolean)
    var
        Cust: Record Customer;
    begin
        Cust.Get(SalesHeader."Bill-to Customer No.");
        if (Cust.GLN <> '') and Cust."Use GLN in Electronic Document" then begin
            CustomerEndpointID := Cust.GLN;
            CustomerSchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
        end else begin
            CustomerEndpointID :=
              FormatVATRegistrationNo(
                SalesHeader.GetCustomerVATRegistrationNumber(), SalesHeader."Bill-to Country/Region Code", IsBISBilling, false);
            CustomerSchemeID := PEPPOL30.GetVATScheme(SalesHeader."Bill-to Country/Region Code");
        end;

        CustomerPartyIdentificationID := Cust.GLN;
        CustomerPartyIDSchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
        CustomerName := SalesHeader."Bill-to Name";
    end;

    procedure GetAccountingCustomerPartyPostalAddr(SalesHeader: Record "Sales Header"; var CustomerStreetName: Text; var CustomerAdditionalStreetName: Text; var CustomerCityName: Text; var CustomerPostalZone: Text; var CustomerCountrySubentity: Text; var CustomerIdentificationCode: Text; var CustomerListID: Text)
    begin
        PEPPOL30.GetAccountingCustomerPartyPostalAddr(SalesHeader, CustomerStreetName, CustomerAdditionalStreetName, CustomerCityName, CustomerPostalZone, CustomerCountrySubentity, CustomerIdentificationCode, CustomerListID);
    end;

    procedure GetAccountingCustomerPartyTaxScheme(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        GetAccountingCustomerPartyTaxSchemeByFormat(
          SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, false);
    end;

    procedure GetAccountingCustomerPartyTaxSchemeBIS(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        GetAccountingCustomerPartyTaxSchemeByFormat(
          SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, true);
    end;

    procedure GetAccountingCustomerPartyTaxSchemeBIS30(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        TempVATAmountLine.SetFilter("Tax Category", '<>%1', GetTaxCategoryO());
        if not TempVATAmountLine.IsEmpty() then
            GetAccountingCustomerPartyTaxSchemeByFormat(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, true);
        TempVATAmountLine.SetRange("Tax Category");
    end;

    local procedure GetAccountingCustomerPartyTaxSchemeByFormat(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text; IsBISBilling: Boolean)
    begin
        CustPartyTaxSchemeCompanyID :=
          FormatVATRegistrationNo(
            SalesHeader.GetCustomerVATRegistrationNumber(), SalesHeader."Bill-to Country/Region Code", IsBISBilling, true);
        if IsBISBilling then
            CustPartyTaxSchemeCompIDSchID := ''
        else
            CustPartyTaxSchemeCompIDSchID := GetVATSchemeByFormat(SalesHeader."Bill-to Country/Region Code", false);
        CustTaxSchemeID := VATTxt;
    end;

    procedure GetAccountingCustomerPartyLegalEntity(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        GetAccountingCustomerPartyLegalEntityByFormat(
          SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID, false);
    end;

    procedure GetAccountingCustomerPartyLegalEntityBIS(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        GetAccountingCustomerPartyLegalEntityByFormat(
          SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID, true);
    end;

    local procedure GetAccountingCustomerPartyLegalEntityByFormat(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text; IsBISBilling: Boolean)
    var
        Customer: Record Customer;
    begin
        if Customer.Get(SalesHeader."Bill-to Customer No.") then begin
            CustPartyLegalEntityRegName := Customer.Name;
            if (Customer.GLN <> '') and Customer."Use GLN in Electronic Document" then begin
                CustPartyLegalEntityCompanyID := Customer.GLN;
                CustPartyLegalEntityIDSchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
            end else begin
                CustPartyLegalEntityCompanyID :=
                  FormatVATRegistrationNo(
                    SalesHeader.GetCustomerVATRegistrationNumber(), SalesHeader."Bill-to Country/Region Code", IsBISBilling, false);
                CustPartyLegalEntityIDSchemeID := GetVATSchemeByFormat(SalesHeader."Bill-to Country/Region Code", IsBISBilling);
            end;
        end;
    end;

    procedure GetAccountingCustomerPartyContact(SalesHeader: Record "Sales Header"; var CustContactID: Text; var CustContactName: Text; var CustContactTelephone: Text; var CustContactTelefax: Text; var CustContactElectronicMail: Text)
    begin
        PEPPOL30.GetAccountingCustomerPartyContact(SalesHeader, CustContactID, CustContactName, CustContactTelephone, CustContactTelefax, CustContactElectronicMail);
    end;

    procedure GetPayeePartyInfo(var PayeePartyID: Text; var PayeePartyIDSchemeID: Text; var PayeePartyNameName: Text; var PayeePartyLegalEntityCompanyID: Text; var PayeePartyLegalCompIDSchemeID: Text)
    begin
        PEPPOL30.GetPayeePartyInfo(PayeePartyID, PayeePartyIDSchemeID, PayeePartyNameName, PayeePartyLegalEntityCompanyID, PayeePartyLegalCompIDSchemeID);
    end;

    procedure GetTaxRepresentativePartyInfo(var TaxRepPartyNameName: Text; var PayeePartyTaxSchemeCompanyID: Text; var PayeePartyTaxSchCompIDSchemeID: Text; var PayeePartyTaxSchemeTaxSchemeID: Text)
    begin
        PEPPOL30.GetTaxRepresentativePartyInfo(TaxRepPartyNameName, PayeePartyTaxSchemeCompanyID, PayeePartyTaxSchCompIDSchemeID, PayeePartyTaxSchemeTaxSchemeID);
    end;

    // BE-specific FormatVATRegistrationNo
    internal procedure FormatVATRegistrationNo(VATRegistrationNo: Text; CountryCode: Code[10]; IsBISBilling: Boolean; IsPartyTaxScheme: Boolean): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        if VATRegistrationNo = '' then
            exit;

        if IsBISBilling then begin
            VATRegistrationNo := DelChr(VATRegistrationNo);

            if IsPartyTaxScheme or (UseVATSchemeID(CountryCode)) then
                if IsBelgiumCountry(CountryCode) then
                    VATRegistrationNo := FormatEnterpriseNo(VATRegistrationNo, CountryCode)
                else
                    if CountryRegion.Get(CountryCode) and (CountryRegion."ISO Code" <> '') then
                        if StrPos(VATRegistrationNo, CountryRegion."ISO Code") <> 1 then
                            VATRegistrationNo := CountryRegion."ISO Code" + VATRegistrationNo;
        end;

        exit(VATRegistrationNo);
    end;

    local procedure UseVATSchemeID(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryCode) then
            exit(false);
        // Use ISO 3166 Country Codes
        exit(CountryRegion."ISO Code" = 'DK');
    end;

    local procedure IsBelgiumCountry(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryCode) then
            exit(false);
        exit(CountryRegion."ISO Code" = 'BE');
    end;

    local procedure FormatEnterpriseNo(EnterpriseNo: Text; CountryCode: Code[10]): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        // Remove all whitespace characters from the enterprise number
        EnterpriseNo := DelChr(EnterpriseNo);

        // Check if enterprise number already contains alphabetic characters (country prefix)
        // If it does, return as-is to avoid double-prefixing
        if DelChr(EnterpriseNo, '=', DelChr(UpperCase(EnterpriseNo), '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')) <> '' then
            exit(EnterpriseNo);

        // Prepend the ISO country code to the enterprise number
        if CountryRegion.Get(CountryCode) and (CountryRegion."ISO Code" <> '') then
            EnterpriseNo := CountryRegion."ISO Code" + EnterpriseNo;

        exit(EnterpriseNo);
    end;

    // Helper procedures (reimplemented from W1 since they are local there)
    local procedure GetGLNSchemeIDByFormat(IsBISBilling: Boolean): Text
    begin
        if IsBISBilling then
            exit('0088');
        exit(GLNTxt);
    end;

    local procedure GetVATSchemeByFormat(CountryRegionCode: Code[10]; IsBISBilling: Boolean): Text
    begin
        if IsBISBilling and not UseVATSchemeID(CountryRegionCode) then
            exit('');
        exit(PEPPOL30.GetVATScheme(CountryRegionCode));
    end;

    local procedure GetCountryISOCode(CountryRegionCode: Code[10]): Code[2]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        exit(CountryRegion."ISO Code");
    end;

    local procedure GetISO3166_1Alpha2(): Text
    begin
        exit('ISO3166-1:Alpha2');
    end;

    local procedure GetTaxCategoryO(): Text
    begin
        exit('O');
    end;
}
