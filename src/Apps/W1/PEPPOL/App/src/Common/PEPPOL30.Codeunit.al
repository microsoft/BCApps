// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;

codeunit 37200 "PEPPOL30" implements "PEPPOL Attachment Provider"
                                            , "PEPPOL Delivery Info Provider"
                                            , "PEPPOL Document Info Provider"
                                            , "PEPPOL Line Info Provider"
                                            , "PEPPOL Monetary Info Provider"
                                            , "PEPPOL Party Info Provider"
                                            , "PEPPOL Payment Info Provider"
                                            , "PEPPOL Tax Info Provider"
{

    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PEPPOLManagementImpl: Codeunit "PEPPOL30 Impl.";

    /// <summary>
    /// Gets general invoice information including ID, issue date, invoice type, currency codes, and accounting cost.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the document information.</param>
    /// <param name="FormatProvider">The format provider interface for PEPPOL formatting.</param>
    /// <param name="ID">Returns the invoice ID.</param>
    /// <param name="IssueDate">Returns the invoice issue date.</param>
    /// <param name="InvoiceTypeCode">Returns the invoice type code.</param>
    /// <param name="InvoiceTypeCodeListID">Returns the invoice type code list ID.</param>
    /// <param name="Note">Returns any additional notes.</param>
    /// <param name="TaxPointDate">Returns the tax point date.</param>
    /// <param name="DocumentCurrencyCode">Returns the document currency code.</param>
    /// <param name="DocumentCurrencyCodeListID">Returns the document currency code list ID.</param>
    /// <param name="TaxCurrencyCode">Returns the tax currency code.</param>
    /// <param name="TaxCurrencyCodeListID">Returns the tax currency code list ID.</param>
    /// <param name="AccountingCost">Returns the accounting cost reference.</param>
    procedure GetGeneralInfo(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var InvoiceTypeCodeListID: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var DocumentCurrencyCodeListID: Text; var TaxCurrencyCode: Text; var TaxCurrencyCodeListID: Text; var AccountingCost: Text)
    begin
        PEPPOLManagementImpl.GetGeneralInfo(SalesHeader, ID, IssueDate, InvoiceTypeCode, InvoiceTypeCodeListID, Note, TaxPointDate, DocumentCurrencyCode, DocumentCurrencyCodeListID, TaxCurrencyCode, TaxCurrencyCodeListID, AccountingCost);
    end;

    /// <summary>
    /// Gets general invoice information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the document information.</param>
    /// <param name="ID">Returns the invoice ID.</param>
    /// <param name="IssueDate">Returns the invoice issue date.</param>
    /// <param name="InvoiceTypeCode">Returns the invoice type code.</param>
    /// <param name="Note">Returns any additional notes.</param>
    /// <param name="TaxPointDate">Returns the tax point date.</param>
    /// <param name="DocumentCurrencyCode">Returns the document currency code.</param>
    /// <param name="AccountingCost">Returns the accounting cost reference.</param>
    procedure GetGeneralInfoBIS(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)
    begin
        PEPPOLManagementImpl.GetGeneralInfoBIS(SalesHeader, ID, IssueDate, InvoiceTypeCode, Note, TaxPointDate, DocumentCurrencyCode, AccountingCost);
    end;

    /// <summary>
    /// Gets the invoice period information including start and end dates.
    /// </summary>
    /// <param name="StartDate">Returns the invoice period start date.</param>
    /// <param name="EndDate">Returns the invoice period end date.</param>
    procedure GetInvoicePeriodInfo(var StartDate: Text; var EndDate: Text)
    begin
        PEPPOLManagementImpl.GetInvoicePeriodInfo(StartDate, EndDate);
    end;

    /// <summary>
    /// Gets the order reference information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the order reference.</param>
    /// <param name="OrderReferenceID">Returns the order reference ID.</param>
    procedure GetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        PEPPOLManagementImpl.GetOrderReferenceInfo(SalesHeader, OrderReferenceID);
    end;

    /// <summary>
    /// Gets the order reference information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the order reference.</param>
    /// <param name="OrderReferenceID">Returns the order reference ID.</param>
    procedure GetOrderReferenceInfoBIS(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        PEPPOLManagementImpl.GetOrderReferenceInfoBIS(SalesHeader, OrderReferenceID);
    end;

    /// <summary>
    /// Gets contract document reference information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the contract reference.</param>
    /// <param name="ContractDocumentReferenceID">Returns the contract document reference ID.</param>
    /// <param name="DocumentTypeCode">Returns the document type code.</param>
    /// <param name="ContractRefDocTypeCodeListID">Returns the contract reference document type code list ID.</param>
    /// <param name="DocumentType">Returns the document type.</param>
    procedure GetContractDocRefInfo(SalesHeader: Record "Sales Header"; var ContractDocumentReferenceID: Text; var DocumentTypeCode: Text; var ContractRefDocTypeCodeListID: Text; var DocumentType: Text)
    begin
        PEPPOLManagementImpl.GetContractDocRefInfo(SalesHeader, ContractDocumentReferenceID, DocumentTypeCode, ContractRefDocTypeCodeListID, DocumentType);
    end;

    /// <summary>
    /// Gets additional document reference information from a specific attachment number.
    /// </summary>
    /// <param name="AttachmentNumber">The attachment number to process.</param>
    /// <param name="DocumentAttachments">The document attachments record.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="AdditionalDocumentReferenceID">Returns the additional document reference ID.</param>
    /// <param name="AdditionalDocRefDocumentType">Returns the additional document reference document type.</param>
    /// <param name="URI">Returns the document URI.</param>
    /// <param name="Filename">Returns the document filename.</param>
    /// <param name="MimeCode">Returns the document MIME code.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Returns the embedded document binary object.</param>
    /// <param name="NewProcessedDocType">The document type being processed (Sale or Service).</param>
    procedure GetAdditionalDocRefInfo(AttachmentNumber: Integer; var DocumentAttachments: Record "Document Attachment"; SalesHeader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; NewProcessedDocType: Option Sale,Service)
    begin
        PEPPOLManagementImpl.GetAdditionalDocRefInfo(AttachmentNumber, DocumentAttachments, SalesHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, Filename, MimeCode, EmbeddedDocumentBinaryObject, NewProcessedDocType);
    end;

    /// <summary>
    /// Gets additional document reference information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="AdditionalDocumentReferenceID">Returns the additional document reference ID.</param>
    /// <param name="AdditionalDocRefDocumentType">Returns the additional document reference document type.</param>
    /// <param name="URI">Returns the document URI.</param>
    /// <param name="MimeCode">Returns the document MIME code.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Returns the embedded document binary object.</param>
    /// <param name="NewProcessedDocType">The document type being processed (Sale or Service).</param>
    procedure GetAdditionalDocRefInfo(SalesHeader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; NewProcessedDocType: Option Sale,Service)
    begin
        PEPPOLManagementImpl.GetAdditionalDocRefInfo(SalesHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, MimeCode, EmbeddedDocumentBinaryObject, NewProcessedDocType);
    end;

    /// <summary>
    /// Gets the buyer reference from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the buyer reference.</param>
    /// <returns>The buyer reference text.</returns>
    procedure GetBuyerReference(SalesHeader: Record "Sales Header") BuyerReference: Text
    begin
        BuyerReference := PEPPOLManagementImpl.GetBuyerReference(SalesHeader);
    end;

    /// <summary>
    /// Generates a PDF attachment as an additional document reference.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="AdditionalDocumentReferenceID">Returns the additional document reference ID.</param>
    /// <param name="AdditionalDocRefDocumentType">Returns the additional document reference document type.</param>
    /// <param name="URI">Returns the document URI.</param>
    /// <param name="Filename">Returns the PDF filename.</param>
    /// <param name="MimeCode">Returns the PDF MIME code.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Returns the embedded PDF binary object.</param>
    procedure GeneratePDFAttachmentAsAdditionalDocRef(SalesHeader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text)
    begin
        PEPPOLManagementImpl.GeneratePDFAttachmentAsAdditionalDocRef(SalesHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, Filename, MimeCode, EmbeddedDocumentBinaryObject);
    end;

    /// <summary>
    /// Gets accounting supplier party information including endpoint ID, scheme ID, and supplier name.
    /// </summary>
    /// <param name="SupplierEndpointID">Returns the supplier endpoint ID.</param>
    /// <param name="SupplierSchemeID">Returns the supplier scheme ID.</param>
    /// <param name="SupplierName">Returns the supplier name.</param>
    procedure GetAccountingSupplierPartyInfo(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);
    end;

    /// <summary>
    /// Gets accounting supplier party information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="SupplierEndpointID">Returns the supplier endpoint ID.</param>
    /// <param name="SupplierSchemeID">Returns the supplier scheme ID.</param>
    /// <param name="SupplierName">Returns the supplier name.</param>
    procedure GetAccountingSupplierPartyInfoBIS(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyInfoBIS(SupplierEndpointID, SupplierSchemeID, SupplierName);
    end;

    /// <summary>
    /// Gets the supplier party postal address information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the supplier address information.</param>
    /// <param name="StreetName">Returns the street name.</param>
    /// <param name="SupplierAdditionalStreetName">Returns the additional street name.</param>
    /// <param name="CityName">Returns the city name.</param>
    /// <param name="PostalZone">Returns the postal zone/zip code.</param>
    /// <param name="CountrySubentity">Returns the country subentity (state/province).</param>
    /// <param name="IdentificationCode">Returns the country identification code.</param>
    /// <param name="ListID">Returns the country list ID.</param>
    procedure GetAccountingSupplierPartyPostalAddr(SalesHeader: Record "Sales Header"; var StreetName: Text; var SupplierAdditionalStreetName: Text; var CityName: Text; var PostalZone: Text; var CountrySubentity: Text; var IdentificationCode: Text; var ListID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyPostalAddr(SalesHeader, StreetName, SupplierAdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);
    end;

    /// <summary>
    /// Gets the supplier party tax scheme information.
    /// </summary>
    /// <param name="CompanyID">Returns the company VAT registration ID.</param>
    /// <param name="CompanyIDSchemeID">Returns the company ID scheme ID.</param>
    /// <param name="TaxSchemeID">Returns the tax scheme ID (e.g., VAT).</param>
    procedure GetAccountingSupplierPartyTaxScheme(var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
    end;

    /// <summary>
    /// Gets the supplier party tax scheme information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="VATAmtLine">The VAT amount line record.</param>
    /// <param name="CompanyID">Returns the company VAT registration ID.</param>
    /// <param name="CompanyIDSchemeID">Returns the company ID scheme ID.</param>
    /// <param name="TaxSchemeID">Returns the tax scheme ID (e.g., VAT).</param>
    procedure GetAccountingSupplierPartyTaxSchemeBIS(var VATAmtLine: Record "VAT Amount Line"; var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyTaxSchemeBIS(VATAmtLine, CompanyID, CompanyIDSchemeID, TaxSchemeID);
    end;

    /// <summary>
    /// Gets the supplier party legal entity information including registration details.
    /// </summary>
    /// <param name="PartyLegalEntityRegName">Returns the party legal entity registration name.</param>
    /// <param name="PartyLegalEntityCompanyID">Returns the party legal entity company ID.</param>
    /// <param name="PartyLegalEntitySchemeID">Returns the party legal entity scheme ID.</param>
    /// <param name="SupplierRegAddrCityName">Returns the supplier registration address city name.</param>
    /// <param name="SupplierRegAddrCountryIdCode">Returns the supplier registration address country ID code.</param>
    /// <param name="SupplRegAddrCountryIdListId">Returns the supplier registration address country ID list ID.</param>
    procedure GetAccountingSupplierPartyLegalEntity(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyLegalEntity(PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);
    end;

    /// <summary>
    /// Gets the supplier party legal entity information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="PartyLegalEntityRegName">Returns the party legal entity registration name.</param>
    /// <param name="PartyLegalEntityCompanyID">Returns the party legal entity company ID.</param>
    /// <param name="PartyLegalEntitySchemeID">Returns the party legal entity scheme ID.</param>
    /// <param name="SupplierRegAddrCityName">Returns the supplier registration address city name.</param>
    /// <param name="SupplierRegAddrCountryIdCode">Returns the supplier registration address country ID code.</param>
    /// <param name="SupplRegAddrCountryIdListId">Returns the supplier registration address country ID list ID.</param>
    procedure GetAccountingSupplierPartyLegalEntityBIS(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyLegalEntityBIS(PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);
    end;

    /// <summary>
    /// Gets the supplier party contact information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the contact information.</param>
    /// <param name="ContactID">Returns the contact ID.</param>
    /// <param name="ContactName">Returns the contact name.</param>
    /// <param name="Telephone">Returns the telephone number.</param>
    /// <param name="Telefax">Returns the telefax number.</param>
    /// <param name="ElectronicMail">Returns the electronic mail address.</param>
    procedure GetAccountingSupplierPartyContact(SalesHeader: Record "Sales Header"; var ContactID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyContact(SalesHeader, ContactID, ContactName, Telephone, Telefax, ElectronicMail);
    end;

    /// <summary>
    /// Gets the supplier party identification ID from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the party identification.</param>
    /// <param name="PartyIdentificationID">Returns the party identification ID.</param>
    procedure GetAccountingSupplierPartyIdentificationID(SalesHeader: Record "Sales Header"; var PartyIdentificationID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyIdentificationID(SalesHeader, PartyIdentificationID);
    end;

    /// <summary>
    /// Gets accounting customer party information including endpoint ID, scheme ID, party identification, and customer name.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the customer information.</param>
    /// <param name="CustomerEndpointID">Returns the customer endpoint ID.</param>
    /// <param name="CustomerSchemeID">Returns the customer scheme ID.</param>
    /// <param name="CustomerPartyIdentificationID">Returns the customer party identification ID.</param>
    /// <param name="CustomerPartyIDSchemeID">Returns the customer party ID scheme ID.</param>
    /// <param name="CustomerName">Returns the customer name.</param>
    procedure GetAccountingCustomerPartyInfo(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyInfo(SalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName);
    end;

    /// <summary>
    /// Gets accounting customer party information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the customer information.</param>
    /// <param name="CustomerEndpointID">Returns the customer endpoint ID.</param>
    /// <param name="CustomerSchemeID">Returns the customer scheme ID.</param>
    /// <param name="CustomerPartyIdentificationID">Returns the customer party identification ID.</param>
    /// <param name="CustomerPartyIDSchemeID">Returns the customer party ID scheme ID.</param>
    /// <param name="CustomerName">Returns the customer name.</param>
    procedure GetAccountingCustomerPartyInfoBIS(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyInfoBIS(SalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName);
    end;

    /// <summary>
    /// Gets the customer party postal address information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the customer address information.</param>
    /// <param name="CustomerStreetName">Returns the customer street name.</param>
    /// <param name="CustomerAdditionalStreetName">Returns the customer additional street name.</param>
    /// <param name="CustomerCityName">Returns the customer city name.</param>
    /// <param name="CustomerPostalZone">Returns the customer postal zone/zip code.</param>
    /// <param name="CustomerCountrySubentity">Returns the customer country subentity (state/province).</param>
    /// <param name="CustomerIdentificationCode">Returns the customer country identification code.</param>
    /// <param name="CustomerListID">Returns the customer country list ID.</param>
    procedure GetAccountingCustomerPartyPostalAddr(SalesHeader: Record "Sales Header"; var CustomerStreetName: Text; var CustomerAdditionalStreetName: Text; var CustomerCityName: Text; var CustomerPostalZone: Text; var CustomerCountrySubentity: Text; var CustomerIdentificationCode: Text; var CustomerListID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyPostalAddr(SalesHeader, CustomerStreetName, CustomerAdditionalStreetName, CustomerCityName, CustomerPostalZone, CustomerCountrySubentity, CustomerIdentificationCode, CustomerListID);
    end;

    /// <summary>
    /// Gets the customer party tax scheme information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the customer tax information.</param>
    /// <param name="CustPartyTaxSchemeCompanyID">Returns the customer party tax scheme company ID.</param>
    /// <param name="CustPartyTaxSchemeCompIDSchID">Returns the customer party tax scheme company ID scheme ID.</param>
    /// <param name="CustTaxSchemeID">Returns the customer tax scheme ID.</param>
    procedure GetAccountingCustomerPartyTaxScheme(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyTaxScheme(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);
    end;

    /// <summary>
    /// Gets the customer party tax scheme information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the customer tax information.</param>
    /// <param name="CustPartyTaxSchemeCompanyID">Returns the customer party tax scheme company ID.</param>
    /// <param name="CustPartyTaxSchemeCompIDSchID">Returns the customer party tax scheme company ID scheme ID.</param>
    /// <param name="CustTaxSchemeID">Returns the customer tax scheme ID.</param>
    procedure GetAccountingCustomerPartyTaxSchemeBIS(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyTaxSchemeBIS(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);
    end;

    /// <summary>
    /// Gets the customer party tax scheme information for BIS 3.0 (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the customer tax information.</param>
    /// <param name="CustPartyTaxSchemeCompanyID">Returns the customer party tax scheme company ID.</param>
    /// <param name="CustPartyTaxSchemeCompIDSchID">Returns the customer party tax scheme company ID scheme ID.</param>
    /// <param name="CustTaxSchemeID">Returns the customer tax scheme ID.</param>
    /// <param name="TempVATAmountLine">The temporary VAT amount line record.</param>
    procedure GetAccountingCustomerPartyTaxSchemeBIS30(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyTaxSchemeBIS30(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, TempVATAmountLine);
    end;

    /// <summary>
    /// Gets the customer party legal entity information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the customer legal entity information.</param>
    /// <param name="CustPartyLegalEntityRegName">Returns the customer party legal entity registration name.</param>
    /// <param name="CustPartyLegalEntityCompanyID">Returns the customer party legal entity company ID.</param>
    /// <param name="CustPartyLegalEntityIDSchemeID">Returns the customer party legal entity ID scheme ID.</param>
    procedure GetAccountingCustomerPartyLegalEntity(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyLegalEntity(SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);
    end;

    /// <summary>
    /// Gets the customer party legal entity information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the customer legal entity information.</param>
    /// <param name="CustPartyLegalEntityRegName">Returns the customer party legal entity registration name.</param>
    /// <param name="CustPartyLegalEntityCompanyID">Returns the customer party legal entity company ID.</param>
    /// <param name="CustPartyLegalEntityIDSchemeID">Returns the customer party legal entity ID scheme ID.</param>
    procedure GetAccountingCustomerPartyLegalEntityBIS(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyLegalEntityBIS(SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);
    end;

    /// <summary>
    /// Gets the customer party contact information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the customer contact information.</param>
    /// <param name="CustContactID">Returns the customer contact ID.</param>
    /// <param name="CustContactName">Returns the customer contact name.</param>
    /// <param name="CustContactTelephone">Returns the customer contact telephone number.</param>
    /// <param name="CustContactTelefax">Returns the customer contact telefax number.</param>
    /// <param name="CustContactElectronicMail">Returns the customer contact electronic mail address.</param>
    procedure GetAccountingCustomerPartyContact(SalesHeader: Record "Sales Header"; var CustContactID: Text; var CustContactName: Text; var CustContactTelephone: Text; var CustContactTelefax: Text; var CustContactElectronicMail: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyContact(SalesHeader, CustContactID, CustContactName, CustContactTelephone, CustContactTelefax, CustContactElectronicMail);
    end;

    /// <summary>
    /// Gets payee party information including party ID, scheme ID, name, and legal entity details.
    /// </summary>
    /// <param name="PayeePartyID">Returns the payee party ID.</param>
    /// <param name="PayeePartyIDSchemeID">Returns the payee party ID scheme ID.</param>
    /// <param name="PayeePartyNameName">Returns the payee party name.</param>
    /// <param name="PayeePartyLegalEntityCompanyID">Returns the payee party legal entity company ID.</param>
    /// <param name="PayeePartyLegalCompIDSchemeID">Returns the payee party legal entity company ID scheme ID.</param>
    procedure GetPayeePartyInfo(var PayeePartyID: Text; var PayeePartyIDSchemeID: Text; var PayeePartyNameName: Text; var PayeePartyLegalEntityCompanyID: Text; var PayeePartyLegalCompIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetPayeePartyInfo(PayeePartyID, PayeePartyIDSchemeID, PayeePartyNameName, PayeePartyLegalEntityCompanyID, PayeePartyLegalCompIDSchemeID);
    end;

    /// <summary>
    /// Gets tax representative party information including name and tax scheme details.
    /// </summary>
    /// <param name="TaxRepPartyNameName">Returns the tax representative party name.</param>
    /// <param name="PayeePartyTaxSchemeCompanyID">Returns the payee party tax scheme company ID.</param>
    /// <param name="PayeePartyTaxSchCompIDSchemeID">Returns the payee party tax scheme company ID scheme ID.</param>
    /// <param name="PayeePartyTaxSchemeTaxSchemeID">Returns the payee party tax scheme tax scheme ID.</param>
    procedure GetTaxRepresentativePartyInfo(var TaxRepPartyNameName: Text; var PayeePartyTaxSchemeCompanyID: Text; var PayeePartyTaxSchCompIDSchemeID: Text; var PayeePartyTaxSchemeTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetTaxRepresentativePartyInfo(TaxRepPartyNameName, PayeePartyTaxSchemeCompanyID, PayeePartyTaxSchCompIDSchemeID, PayeePartyTaxSchemeTaxSchemeID);
    end;

    /// <summary>
    /// Gets delivery information including actual delivery date and delivery ID details.
    /// </summary>
    /// <param name="ActualDeliveryDate">Returns the actual delivery date.</param>
    /// <param name="DeliveryID">Returns the delivery ID.</param>
    /// <param name="DeliveryIDSchemeID">Returns the delivery ID scheme ID.</param>
    procedure GetDeliveryInfo(var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetDeliveryInfo(ActualDeliveryDate, DeliveryID, DeliveryIDSchemeID);
    end;

    /// <summary>
    /// Gets GLN (Global Location Number) delivery information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the GLN delivery information.</param>
    /// <param name="ActualDeliveryDate">Returns the actual delivery date.</param>
    /// <param name="DeliveryID">Returns the delivery GLN ID.</param>
    /// <param name="DeliveryIDSchemeID">Returns the delivery ID scheme ID.</param>
    procedure GetGLNDeliveryInfo(SalesHeader: Record "Sales Header"; var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetGLNDeliveryInfo(SalesHeader, ActualDeliveryDate, DeliveryID, DeliveryIDSchemeID);
    end;

    /// <summary>
    /// Gets the GLN (Global Location Number) for the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record to get the GLN from.</param>
    /// <returns>The GLN code for the header.</returns>
    procedure GetGLNForHeader(SalesHeader: Record "Sales Header"): Code[13]
    begin
        exit(PEPPOLManagementImpl.GetGLNForHeader(SalesHeader));
    end;

    /// <summary>
    /// Gets the delivery address information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the delivery address information.</param>
    /// <param name="DeliveryStreetName">Returns the delivery street name.</param>
    /// <param name="DeliveryAdditionalStreetName">Returns the delivery additional street name.</param>
    /// <param name="DeliveryCityName">Returns the delivery city name.</param>
    /// <param name="DeliveryPostalZone">Returns the delivery postal zone/zip code.</param>
    /// <param name="DeliveryCountrySubentity">Returns the delivery country subentity (state/province).</param>
    /// <param name="DeliveryCountryIdCode">Returns the delivery country ID code.</param>
    /// <param name="DeliveryCountryListID">Returns the delivery country list ID.</param>
    procedure GetDeliveryAddress(SalesHeader: Record "Sales Header"; var DeliveryStreetName: Text; var DeliveryAdditionalStreetName: Text; var DeliveryCityName: Text; var DeliveryPostalZone: Text; var DeliveryCountrySubentity: Text; var DeliveryCountryIdCode: Text; var DeliveryCountryListID: Text)
    begin
        PEPPOLManagementImpl.GetDeliveryAddress(SalesHeader, DeliveryStreetName, DeliveryAdditionalStreetName, DeliveryCityName, DeliveryPostalZone, DeliveryCountrySubentity, DeliveryCountryIdCode, DeliveryCountryListID);
    end;

    /// <summary>
    /// Gets payment means information from the sales header including payment code, due date, and account details.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the payment information.</param>
    /// <param name="PaymentMeansCode">Returns the payment means code.</param>
    /// <param name="PaymentMeansListID">Returns the payment means list ID.</param>
    /// <param name="PaymentDueDate">Returns the payment due date.</param>
    /// <param name="PaymentChannelCode">Returns the payment channel code.</param>
    /// <param name="PaymentID">Returns the payment ID.</param>
    /// <param name="PrimaryAccountNumberID">Returns the primary account number ID.</param>
    /// <param name="NetworkID">Returns the network ID.</param>
    procedure GetPaymentMeansInfo(SalesHeader: Record "Sales Header"; var PaymentMeansCode: Text; var PaymentMeansListID: Text; var PaymentDueDate: Text; var PaymentChannelCode: Text; var PaymentID: Text; var PrimaryAccountNumberID: Text; var NetworkID: Text)
    begin
        PEPPOLManagementImpl.GetPaymentMeansInfo(SalesHeader, PaymentMeansCode, PaymentMeansListID, PaymentDueDate, PaymentChannelCode, PaymentID, PrimaryAccountNumberID, NetworkID);
    end;

    /// <summary>
    /// Gets payment means payee financial account information including account ID and financial institution details.
    /// </summary>
    /// <param name="PayeeFinancialAccountID">Returns the payee financial account ID.</param>
    /// <param name="PaymentMeansSchemeID">Returns the payment means scheme ID.</param>
    /// <param name="FinancialInstitutionBranchID">Returns the financial institution branch ID.</param>
    /// <param name="FinancialInstitutionID">Returns the financial institution ID.</param>
    /// <param name="FinancialInstitutionSchemeID">Returns the financial institution scheme ID.</param>
    /// <param name="FinancialInstitutionName">Returns the financial institution name.</param>
    procedure GetPaymentMeansPayeeFinancialAcc(var PayeeFinancialAccountID: Text; var PaymentMeansSchemeID: Text; var FinancialInstitutionBranchID: Text; var FinancialInstitutionID: Text; var FinancialInstitutionSchemeID: Text; var FinancialInstitutionName: Text)
    begin
        PEPPOLManagementImpl.GetPaymentMeansPayeeFinancialAcc(PayeeFinancialAccountID, PaymentMeansSchemeID, FinancialInstitutionBranchID, FinancialInstitutionID, FinancialInstitutionSchemeID, FinancialInstitutionName);
    end;

    /// <summary>
    /// Gets payment means payee financial account information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the payment account information.</param>
    /// <param name="PayeeFinancialAccountID">Returns the payee financial account ID.</param>
    /// <param name="FinancialInstitutionBranchID">Returns the financial institution branch ID.</param>
    procedure GetPaymentMeansPayeeFinancialAccBIS(SalesHeader: Record "Sales Header"; var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)
    begin
        PEPPOLManagementImpl.GetPaymentMeansPayeeFinancialAccBIS(SalesHeader, PayeeFinancialAccountID, FinancialInstitutionBranchID);
    end;

    /// <summary>
    /// Gets the financial institution address information for payment means.
    /// </summary>
    /// <param name="FinancialInstitutionStreetName">Returns the financial institution street name.</param>
    /// <param name="AdditionalStreetName">Returns the additional street name.</param>
    /// <param name="FinancialInstitutionCityName">Returns the financial institution city name.</param>
    /// <param name="FinancialInstitutionPostalZone">Returns the financial institution postal zone.</param>
    /// <param name="FinancialInstCountrySubentity">Returns the financial institution country subentity.</param>
    /// <param name="FinancialInstCountryIdCode">Returns the financial institution country ID code.</param>
    /// <param name="FinancialInstCountryListID">Returns the financial institution country list ID.</param>
    procedure GetPaymentMeansFinancialInstitutionAddr(var FinancialInstitutionStreetName: Text; var AdditionalStreetName: Text; var FinancialInstitutionCityName: Text; var FinancialInstitutionPostalZone: Text; var FinancialInstCountrySubentity: Text; var FinancialInstCountryIdCode: Text; var FinancialInstCountryListID: Text)
    begin
        PEPPOLManagementImpl.GetPaymentMeansFinancialInstitutionAddr(FinancialInstitutionStreetName, AdditionalStreetName, FinancialInstitutionCityName, FinancialInstitutionPostalZone, FinancialInstCountrySubentity, FinancialInstCountryIdCode, FinancialInstCountryListID);
    end;

    /// <summary>
    /// Gets payment terms information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the payment terms.</param>
    /// <param name="PaymentTermsNote">Returns the payment terms note.</param>
    procedure GetPaymentTermsInfo(SalesHeader: Record "Sales Header"; var PaymentTermsNote: Text)
    begin
        PEPPOLManagementImpl.GetPaymentTermsInfo(SalesHeader, PaymentTermsNote);
    end;

    /// <summary>
    /// Gets allowance or charge information from the VAT amount line and sales header.
    /// </summary>
    /// <param name="VATAmtLine">The VAT amount line record containing allowance/charge details.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ChargeIndicator">Returns whether this is a charge (true) or allowance (false).</param>
    /// <param name="AllowanceChargeReasonCode">Returns the allowance/charge reason code.</param>
    /// <param name="AllowanceChargeListID">Returns the allowance/charge list ID.</param>
    /// <param name="AllowanceChargeReason">Returns the allowance/charge reason description.</param>
    /// <param name="Amount">Returns the allowance/charge amount.</param>
    /// <param name="AllowanceChargeCurrencyID">Returns the allowance/charge currency ID.</param>
    /// <param name="TaxCategoryID">Returns the tax category ID.</param>
    /// <param name="TaxCategorySchemeID">Returns the tax category scheme ID.</param>
    /// <param name="Percent">Returns the tax percentage.</param>
    /// <param name="AllowanceChargeTaxSchemeID">Returns the allowance/charge tax scheme ID.</param>
    procedure GetAllowanceChargeInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAllowanceChargeInfo(VATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID, AllowanceChargeReason, Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID, Percent, AllowanceChargeTaxSchemeID);
    end;

    /// <summary>
    /// Gets allowance or charge information for BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="VATAmtLine">The VAT amount line record containing allowance/charge details.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ChargeIndicator">Returns whether this is a charge (true) or allowance (false).</param>
    /// <param name="AllowanceChargeReasonCode">Returns the allowance/charge reason code.</param>
    /// <param name="AllowanceChargeListID">Returns the allowance/charge list ID.</param>
    /// <param name="AllowanceChargeReason">Returns the allowance/charge reason description.</param>
    /// <param name="Amount">Returns the allowance/charge amount.</param>
    /// <param name="AllowanceChargeCurrencyID">Returns the allowance/charge currency ID.</param>
    /// <param name="TaxCategoryID">Returns the tax category ID.</param>
    /// <param name="TaxCategorySchemeID">Returns the tax category scheme ID.</param>
    /// <param name="Percent">Returns the tax percentage.</param>
    /// <param name="AllowanceChargeTaxSchemeID">Returns the allowance/charge tax scheme ID.</param>
    procedure GetAllowanceChargeInfoBIS(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAllowanceChargeInfoBIS(VATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID, AllowanceChargeReason, Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID, Percent, AllowanceChargeTaxSchemeID);
    end;

    /// <summary>
    /// Gets tax exchange rate information from the sales header when dealing with foreign currencies.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing exchange rate information.</param>
    /// <param name="SourceCurrencyCode">Returns the source currency code.</param>
    /// <param name="SourceCurrencyCodeListID">Returns the source currency code list ID.</param>
    /// <param name="TargetCurrencyCode">Returns the target currency code.</param>
    /// <param name="TargetCurrencyCodeListID">Returns the target currency code list ID.</param>
    /// <param name="CalculationRate">Returns the exchange rate calculation rate.</param>
    /// <param name="MathematicOperatorCode">Returns the mathematic operator code for the calculation.</param>
    /// <param name="Date">Returns the exchange rate date.</param>
    procedure GetTaxExchangeRateInfo(SalesHeader: Record "Sales Header"; var SourceCurrencyCode: Text; var SourceCurrencyCodeListID: Text; var TargetCurrencyCode: Text; var TargetCurrencyCodeListID: Text; var CalculationRate: Text; var MathematicOperatorCode: Text; var Date: Text)
    begin
        PEPPOLManagementImpl.GetTaxExchangeRateInfo(SalesHeader, SourceCurrencyCode, SourceCurrencyCodeListID, TargetCurrencyCode, TargetCurrencyCodeListID, CalculationRate, MathematicOperatorCode, Date);
    end;

    /// <summary>
    /// Gets the total tax amount information from the sales header and VAT amount lines.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing tax information.</param>
    /// <param name="VATAmtLine">The VAT amount line record containing tax totals.</param>
    /// <param name="TaxAmount">Returns the total tax amount.</param>
    /// <param name="TaxTotalCurrencyID">Returns the tax total currency ID.</param>
    procedure GetTaxTotalInfo(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var TaxAmount: Text; var TaxTotalCurrencyID: Text)
    begin
        PEPPOLManagementImpl.GetTaxTotalInfo(SalesHeader, VATAmtLine, TaxAmount, TaxTotalCurrencyID);
    end;

    /// <summary>
    /// Gets tax subtotal information for a specific VAT amount line including taxable amount, tax amount, and tax category details.
    /// </summary>
    /// <param name="VATAmtLine">The VAT amount line record containing tax subtotal details.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="TaxableAmount">Returns the taxable amount (base amount for tax calculation).</param>
    /// <param name="TaxAmountCurrencyID">Returns the tax amount currency ID.</param>
    /// <param name="SubtotalTaxAmount">Returns the subtotal tax amount.</param>
    /// <param name="TaxSubtotalCurrencyID">Returns the tax subtotal currency ID.</param>
    /// <param name="TransactionCurrencyTaxAmount">Returns the transaction currency tax amount.</param>
    /// <param name="TransCurrTaxAmtCurrencyID">Returns the transaction currency tax amount currency ID.</param>
    /// <param name="TaxTotalTaxCategoryID">Returns the tax total tax category ID.</param>
    /// <param name="schemeID">Returns the scheme ID.</param>
    /// <param name="TaxCategoryPercent">Returns the tax category percentage.</param>
    /// <param name="TaxTotalTaxSchemeID">Returns the tax total tax scheme ID.</param>
    procedure GetTaxSubtotalInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var TaxableAmount: Text; var TaxAmountCurrencyID: Text; var SubtotalTaxAmount: Text; var TaxSubtotalCurrencyID: Text; var TransactionCurrencyTaxAmount: Text; var TransCurrTaxAmtCurrencyID: Text; var TaxTotalTaxCategoryID: Text; var schemeID: Text; var TaxCategoryPercent: Text; var TaxTotalTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetTaxSubtotalInfo(VATAmtLine, SalesHeader, TaxableAmount, TaxAmountCurrencyID, SubtotalTaxAmount, TaxSubtotalCurrencyID, TransactionCurrencyTaxAmount, TransCurrTaxAmtCurrencyID, TaxTotalTaxCategoryID, schemeID, TaxCategoryPercent, TaxTotalTaxSchemeID);
    end;

    /// <summary>
    /// Gets tax total information in local currency (LCY) from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing tax information.</param>
    /// <param name="TaxAmount">Returns the tax amount in local currency.</param>
    /// <param name="TaxCurrencyID">Returns the tax currency ID.</param>
    /// <param name="TaxTotalCurrencyID">Returns the tax total currency ID.</param>
    procedure GetTaxTotalInfoLCY(SalesHeader: Record "Sales Header"; var TaxAmount: Text; var TaxCurrencyID: Text; var TaxTotalCurrencyID: Text)
    begin
        PEPPOLManagementImpl.GetTaxTotalInfoLCY(SalesHeader, TaxAmount, TaxCurrencyID, TaxTotalCurrencyID);
    end;

    /// <summary>
    /// Gets comprehensive legal monetary information including line extension amounts, tax amounts, allowances, charges, and payable amounts.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing monetary information.</param>
    /// <param name="TempSalesLine">The temporary sales line record containing line details.</param>
    /// <param name="VATAmtLine">The VAT amount line record containing tax totals.</param>
    /// <param name="LineExtensionAmount">Returns the total line extension amount.</param>
    /// <param name="LegalMonetaryTotalCurrencyID">Returns the legal monetary total currency ID.</param>
    /// <param name="TaxExclusiveAmount">Returns the tax exclusive amount.</param>
    /// <param name="TaxExclusiveAmountCurrencyID">Returns the tax exclusive amount currency ID.</param>
    /// <param name="TaxInclusiveAmount">Returns the tax inclusive amount.</param>
    /// <param name="TaxInclusiveAmountCurrencyID">Returns the tax inclusive amount currency ID.</param>
    /// <param name="AllowanceTotalAmount">Returns the total allowance amount.</param>
    /// <param name="AllowanceTotalAmountCurrencyID">Returns the allowance total amount currency ID.</param>
    /// <param name="ChargeTotalAmount">Returns the total charge amount.</param>
    /// <param name="ChargeTotalAmountCurrencyID">Returns the charge total amount currency ID.</param>
    /// <param name="PrepaidAmount">Returns the prepaid amount.</param>
    /// <param name="PrepaidCurrencyID">Returns the prepaid currency ID.</param>
    /// <param name="PayableRoundingAmount">Returns the payable rounding amount.</param>
    /// <param name="PayableRndingAmountCurrencyID">Returns the payable rounding amount currency ID.</param>
    /// <param name="PayableAmount">Returns the final payable amount.</param>
    /// <param name="PayableAmountCurrencyID">Returns the payable amount currency ID.</param>
    procedure GetLegalMonetaryInfo(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text; var PrepaidAmount: Text; var PrepaidCurrencyID: Text; var PayableRoundingAmount: Text; var PayableRndingAmountCurrencyID: Text; var PayableAmount: Text; var PayableAmountCurrencyID: Text)
    begin
        PEPPOLManagementImpl.GetLegalMonetaryInfo(SalesHeader, TempSalesLine, VATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID, PrepaidAmount, PrepaidCurrencyID, PayableRoundingAmount, PayableRndingAmountCurrencyID, PayableAmount, PayableAmountCurrencyID);
    end;

    /// <summary>
    /// Gets legal monetary document amounts including line extension, tax amounts, allowances, and charges.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing document monetary information.</param>
    /// <param name="VATAmtLine">The VAT amount line record containing tax totals.</param>
    /// <param name="LineExtensionAmount">Returns the total line extension amount.</param>
    /// <param name="LegalMonetaryTotalCurrencyID">Returns the legal monetary total currency ID.</param>
    /// <param name="TaxExclusiveAmount">Returns the tax exclusive amount.</param>
    /// <param name="TaxExclusiveAmountCurrencyID">Returns the tax exclusive amount currency ID.</param>
    /// <param name="TaxInclusiveAmount">Returns the tax inclusive amount.</param>
    /// <param name="TaxInclusiveAmountCurrencyID">Returns the tax inclusive amount currency ID.</param>
    /// <param name="AllowanceTotalAmount">Returns the total allowance amount.</param>
    /// <param name="AllowanceTotalAmountCurrencyID">Returns the allowance total amount currency ID.</param>
    /// <param name="ChargeTotalAmount">Returns the total charge amount.</param>
    /// <param name="ChargeTotalAmountCurrencyID">Returns the charge total amount currency ID.</param>
    procedure GetLegalMonetaryDocAmounts(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text)
    begin
        PEPPOLManagementImpl.GetLegalMonetaryDocAmounts(SalesHeader, VATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID);
    end;

    /// <summary>
    /// Gets general line information including invoice line ID, note, quantity, extension amount, and accounting cost.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing line information.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="InvoiceLineID">Returns the invoice line ID.</param>
    /// <param name="InvoiceLineNote">Returns the invoice line note.</param>
    /// <param name="InvoicedQuantity">Returns the invoiced quantity.</param>
    /// <param name="InvoiceLineExtensionAmount">Returns the invoice line extension amount.</param>
    /// <param name="LineExtensionAmountCurrencyID">Returns the line extension amount currency ID.</param>
    /// <param name="InvoiceLineAccountingCost">Returns the invoice line accounting cost.</param>
    procedure GetLineGeneralInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineID: Text; var InvoiceLineNote: Text; var InvoicedQuantity: Text; var InvoiceLineExtensionAmount: Text; var LineExtensionAmountCurrencyID: Text; var InvoiceLineAccountingCost: Text)
    begin
        PEPPOLManagementImpl.GetLineGeneralInfo(SalesLine, SalesHeader, InvoiceLineID, InvoiceLineNote, InvoicedQuantity, InvoiceLineExtensionAmount, LineExtensionAmountCurrencyID, InvoiceLineAccountingCost);
    end;

    /// <summary>
    /// Gets unit code information for the sales line including unit code and list ID.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing unit information.</param>
    /// <param name="unitCode">Returns the unit code (e.g., piece, kg, etc.).</param>
    /// <param name="unitCodeListID">Returns the unit code list ID.</param>
    procedure GetLineUnitCodeInfo(SalesLine: Record "Sales Line"; var unitCode: Text; var unitCodeListID: Text)
    begin
        PEPPOLManagementImpl.GetLineUnitCodeInfo(SalesLine, unitCode, unitCodeListID);
    end;

    /// <summary>
    /// Gets invoice period information for the line level including start and end dates.
    /// </summary>
    /// <param name="InvLineInvoicePeriodStartDate">Returns the invoice line period start date.</param>
    /// <param name="InvLineInvoicePeriodEndDate">Returns the invoice line period end date.</param>
    procedure GetLineInvoicePeriodInfo(var InvLineInvoicePeriodStartDate: Text; var InvLineInvoicePeriodEndDate: Text)
    begin
        PEPPOLManagementImpl.GetLineInvoicePeriodInfo(InvLineInvoicePeriodStartDate, InvLineInvoicePeriodEndDate);
    end;

    /// <summary>
    /// Gets delivery information for the invoice line including delivery date and delivery ID.
    /// </summary>
    /// <param name="InvoiceLineActualDeliveryDate">Returns the invoice line actual delivery date.</param>
    /// <param name="InvoiceLineDeliveryID">Returns the invoice line delivery ID.</param>
    /// <param name="InvoiceLineDeliveryIDSchemeID">Returns the invoice line delivery ID scheme ID.</param>
    procedure GetLineDeliveryInfo(var InvoiceLineActualDeliveryDate: Text; var InvoiceLineDeliveryID: Text; var InvoiceLineDeliveryIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetLineDeliveryInfo(InvoiceLineActualDeliveryDate, InvoiceLineDeliveryID, InvoiceLineDeliveryIDSchemeID);
    end;

    /// <summary>
    /// Gets postal address information for the invoice line delivery.
    /// </summary>
    /// <param name="InvoiceLineDeliveryStreetName">Returns the invoice line delivery street name.</param>
    /// <param name="InvLineDeliveryAddStreetName">Returns the invoice line delivery additional street name.</param>
    /// <param name="InvoiceLineDeliveryCityName">Returns the invoice line delivery city name.</param>
    /// <param name="InvoiceLineDeliveryPostalZone">Returns the invoice line delivery postal zone.</param>
    /// <param name="InvLnDeliveryCountrySubentity">Returns the invoice line delivery country subentity.</param>
    /// <param name="InvLnDeliveryCountryIdCode">Returns the invoice line delivery country ID code.</param>
    /// <param name="InvLineDeliveryCountryListID">Returns the invoice line delivery country list ID.</param>
    procedure GetLineDeliveryPostalAddr(var InvoiceLineDeliveryStreetName: Text; var InvLineDeliveryAddStreetName: Text; var InvoiceLineDeliveryCityName: Text; var InvoiceLineDeliveryPostalZone: Text; var InvLnDeliveryCountrySubentity: Text; var InvLnDeliveryCountryIdCode: Text; var InvLineDeliveryCountryListID: Text)
    begin
        PEPPOLManagementImpl.GetLineDeliveryPostalAddr(InvoiceLineDeliveryStreetName, InvLineDeliveryAddStreetName, InvoiceLineDeliveryCityName, InvoiceLineDeliveryPostalZone, InvLnDeliveryCountrySubentity, InvLnDeliveryCountryIdCode, InvLineDeliveryCountryListID);
    end;

    /// <summary>
    /// Gets the delivery party name from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing the delivery party information.</param>
    /// <param name="DeliveryPartyName">Returns the delivery party name.</param>
    procedure GetDeliveryPartyName(SalesHeader: Record "Sales Header"; var DeliveryPartyName: Text)
    begin
        PEPPOLManagementImpl.GetDeliveryPartyName(SalesHeader, DeliveryPartyName);
    end;

    /// <summary>
    /// Gets allowance or charge information for the invoice line.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing allowance/charge information.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="InvLnAllowanceChargeIndicator">Returns whether this is an allowance or charge indicator.</param>
    /// <param name="InvLnAllowanceChargeReason">Returns the invoice line allowance/charge reason.</param>
    /// <param name="InvLnAllowanceChargeAmount">Returns the invoice line allowance/charge amount.</param>
    /// <param name="InvLnAllowanceChargeAmtCurrID">Returns the invoice line allowance/charge amount currency ID.</param>
    procedure GetLineAllowanceChargeInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvLnAllowanceChargeIndicator: Text; var InvLnAllowanceChargeReason: Text; var InvLnAllowanceChargeAmount: Text; var InvLnAllowanceChargeAmtCurrID: Text)
    begin
        PEPPOLManagementImpl.GetLineAllowanceChargeInfo(SalesLine, SalesHeader, InvLnAllowanceChargeIndicator, InvLnAllowanceChargeReason, InvLnAllowanceChargeAmount, InvLnAllowanceChargeAmtCurrID);
    end;

    /// <summary>
    /// Gets tax total information for the invoice line.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing tax information.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="InvoiceLineTaxAmount">Returns the invoice line tax amount.</param>
    /// <param name="currencyID">Returns the currency ID for the tax amount.</param>
    procedure GetLineTaxTotal(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineTaxAmount: Text; var currencyID: Text)
    begin
        PEPPOLManagementImpl.GetLineTaxTotal(SalesLine, SalesHeader, InvoiceLineTaxAmount, currencyID);
    end;

    /// <summary>
    /// Gets item information for the invoice line including description, name, item identification codes, and origin country.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing item information.</param>
    /// <param name="Description">Returns the item description.</param>
    /// <param name="Name">Returns the item name.</param>
    /// <param name="SellersItemIdentificationID">Returns the seller's item identification ID.</param>
    /// <param name="StandardItemIdentificationID">Returns the standard item identification ID (e.g., GTIN).</param>
    /// <param name="StdItemIdIDSchemeID">Returns the standard item ID scheme ID.</param>
    /// <param name="OriginCountryIdCode">Returns the origin country ID code.</param>
    /// <param name="OriginCountryIdCodeListID">Returns the origin country ID code list ID.</param>
    procedure GetLineItemInfo(SalesLine: Record "Sales Line"; var Description: Text; var Name: Text; var SellersItemIdentificationID: Text; var StandardItemIdentificationID: Text; var StdItemIdIDSchemeID: Text; var OriginCountryIdCode: Text; var OriginCountryIdCodeListID: Text)
    begin
        PEPPOLManagementImpl.GetLineItemInfo(SalesLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID, OriginCountryIdCode, OriginCountryIdCodeListID);
    end;

    /// <summary>
    /// Gets commodity classification information for the line item.
    /// </summary>
    /// <param name="CommodityCode">Returns the commodity code.</param>
    /// <param name="CommodityCodeListID">Returns the commodity code list ID.</param>
    /// <param name="ItemClassificationCode">Returns the item classification code.</param>
    /// <param name="ItemClassificationCodeListID">Returns the item classification code list ID.</param>
    procedure GetLineItemCommodityClassificationInfo(var CommodityCode: Text; var CommodityCodeListID: Text; var ItemClassificationCode: Text; var ItemClassificationCodeListID: Text)
    begin
        PEPPOLManagementImpl.GetLineItemCommodityClassificationInfo(CommodityCode, CommodityCodeListID, ItemClassificationCode, ItemClassificationCodeListID);
    end;

    /// <summary>
    /// Gets classified tax category information for the line item.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing tax category information.</param>
    /// <param name="ClassifiedTaxCategoryID">Returns the classified tax category ID.</param>
    /// <param name="ItemSchemeID">Returns the item scheme ID.</param>
    /// <param name="InvoiceLineTaxPercent">Returns the invoice line tax percentage.</param>
    /// <param name="ClassifiedTaxCategorySchemeID">Returns the classified tax category scheme ID.</param>
    procedure GetLineItemClassifiedTaxCategory(SalesLine: Record "Sales Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)
    begin
        PEPPOLManagementImpl.GetLineItemClassifiedTaxCategory(SalesLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);
    end;

    /// <summary>
    /// Gets classified tax category information for the line item in BIS (Business Interoperability Specification) format.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing tax category information.</param>
    /// <param name="ClassifiedTaxCategoryID">Returns the classified tax category ID.</param>
    /// <param name="ItemSchemeID">Returns the item scheme ID.</param>
    /// <param name="InvoiceLineTaxPercent">Returns the invoice line tax percentage.</param>
    /// <param name="ClassifiedTaxCategorySchemeID">Returns the classified tax category scheme ID.</param>
    procedure GetLineItemClassifiedTaxCategoryBIS(SalesLine: Record "Sales Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)
    begin
        PEPPOLManagementImpl.GetLineItemClassifiedTaxCategoryBIS(SalesLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);
    end;

    /// <summary>
    /// Gets additional item property information for the line item.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing additional item properties.</param>
    /// <param name="AdditionalItemPropertyName">Returns the additional item property name.</param>
    /// <param name="AdditionalItemPropertyValue">Returns the additional item property value.</param>
    procedure GetLineAdditionalItemPropertyInfo(SalesLine: Record "Sales Line"; var AdditionalItemPropertyName: Text; var AdditionalItemPropertyValue: Text)
    begin
        PEPPOLManagementImpl.GetLineAdditionalItemPropertyInfo(SalesLine, AdditionalItemPropertyName, AdditionalItemPropertyValue);
    end;

    /// <summary>
    /// Gets price information for the invoice line including price amount, base quantity, and unit code.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing price information.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="InvoiceLinePriceAmount">Returns the invoice line price amount.</param>
    /// <param name="InvLinePriceAmountCurrencyID">Returns the invoice line price amount currency ID.</param>
    /// <param name="BaseQuantity">Returns the base quantity for price calculation.</param>
    /// <param name="UnitCode">Returns the unit code for the base quantity.</param>
    procedure GetLinePriceInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLinePriceAmount: Text; var InvLinePriceAmountCurrencyID: Text; var BaseQuantity: Text; var UnitCode: Text)
    begin
        PEPPOLManagementImpl.GetLinePriceInfo(SalesLine, SalesHeader, InvoiceLinePriceAmount, InvLinePriceAmountCurrencyID, BaseQuantity, UnitCode);
    end;

    /// <summary>
    /// Gets price allowance or charge information for the invoice line.
    /// </summary>
    /// <param name="PriceChargeIndicator">Returns the price charge indicator.</param>
    /// <param name="PriceAllowanceChargeAmount">Returns the price allowance/charge amount.</param>
    /// <param name="PriceAllowanceAmountCurrencyID">Returns the price allowance amount currency ID.</param>
    /// <param name="PriceAllowanceChargeBaseAmount">Returns the price allowance/charge base amount.</param>
    /// <param name="PriceAllowChargeBaseAmtCurrID">Returns the price allowance/charge base amount currency ID.</param>
    procedure GetLinePriceAllowanceChargeInfo(var PriceChargeIndicator: Text; var PriceAllowanceChargeAmount: Text; var PriceAllowanceAmountCurrencyID: Text; var PriceAllowanceChargeBaseAmount: Text; var PriceAllowChargeBaseAmtCurrID: Text)
    begin
        PEPPOLManagementImpl.GetLinePriceAllowanceChargeInfo(PriceChargeIndicator, PriceAllowanceChargeAmount, PriceAllowanceAmountCurrencyID, PriceAllowanceChargeBaseAmount, PriceAllowChargeBaseAmtCurrID);
    end;

    /// <summary>
    /// Gets billing reference information from a sales credit memo header for credit note scenarios.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The sales credit memo header record containing billing reference information.</param>
    /// <param name="InvoiceDocRefID">Returns the invoice document reference ID.</param>
    /// <param name="InvoiceDocRefIssueDate">Returns the invoice document reference issue date.</param>
    procedure GetCrMemoBillingReferenceInfo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var InvoiceDocRefID: Text; var InvoiceDocRefIssueDate: Text)
    begin
        PEPPOLManagementImpl.GetCrMemoBillingReferenceInfo(SalesCrMemoHeader, InvoiceDocRefID, InvoiceDocRefIssueDate);
    end;

    /// <summary>
    /// Gets totals and calculates VAT amount lines from the sales line information.
    /// </summary>
    /// <param name="SalesLine">The sales line record to calculate totals from.</param>
    /// <param name="VATAmtLine">Returns the calculated VAT amount line totals.</param>
    procedure GetTaxTotals(SalesLine: Record "Sales Line"; var VATAmtLine: Record "VAT Amount Line")
    begin
        PEPPOLManagementImpl.GetTaxTotals(SalesLine, VATAmtLine);
    end;

    /// <summary>
    /// Gets tax categories from the sales line and populates VAT product posting group category information.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing tax category information.</param>
    /// <param name="VATProductPostingGroupCategory">Returns the VAT product posting group category information.</param>
    procedure GetTaxCategories(SalesLine: Record "Sales Line"; var VATProductPostingGroupCategory: Record "VAT Product Posting Group")
    begin
        PEPPOLManagementImpl.GetTaxCategories(SalesLine, VATProductPostingGroupCategory);
    end;

    /// <summary>
    /// Gets the invoice rounding line from sales line data.
    /// </summary>
    /// <param name="TempSalesLine">Returns the temporary sales line containing rounding information.</param>
    /// <param name="SalesLine">The source sales line record.</param>
    procedure GetInvoiceRoundingLine(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
        PEPPOLManagementImpl.GetInvoiceRoundingLine(TempSalesLine, SalesLine);
    end;

    /// <summary>
    /// Gets the tax exemption reason text based on VAT product posting group category and tax category ID.
    /// </summary>
    /// <param name="VATProductPostingGroupCategory">The VAT product posting group category record.</param>
    /// <param name="TaxExemptionReasonTxt">Returns the tax exemption reason text.</param>
    /// <param name="TaxCategoryID">The tax category ID to get exemption reason for.</param>
    procedure GetTaxExemptionReason(var VATProductPostingGroupCategory: Record "VAT Product Posting Group"; var TaxExemptionReasonTxt: Text; TaxCategoryID: Text)
    begin
        PEPPOLManagementImpl.GetTaxExemptionReason(VATProductPostingGroupCategory, TaxExemptionReasonTxt, TaxCategoryID);
    end;

    /// <summary>
    /// Gets the PEPPOL telemetry token for logging and tracking purposes.
    /// </summary>
    /// <returns>The PEPPOL telemetry token text.</returns>
    procedure GetPeppolTelemetryTok(): Text
    begin
        exit(PEPPOLManagementImpl.GetPeppolTelemetryTok());
    end;

    /// <summary>
    /// Gets the Unit of Measure code for 'piece' in UN/ECE Recommendation 20 list ID format.
    /// </summary>
    /// <returns>The UoM code for piece in UN/ECE Rec 20 format.</returns>
    procedure GetUoMforPieceINUNECERec20ListID(): Code[10]
    begin
        exit(PEPPOLManagementImpl.GetUoMforPieceINUNECERec20ListID());
    end;

    /// <summary>
    /// Gets the VAT scheme identifier based on the country/region code.
    /// </summary>
    /// <param name="CountryRegionCode">The country/region code to get the VAT scheme for.</param>
    /// <returns>The VAT scheme identifier text.</returns>
    procedure GetVATScheme(CountryRegionCode: Code[10]): Text
    begin
        exit(PEPPOLManagementImpl.GetVATScheme(CountryRegionCode));
    end;

    /// <summary>
    /// Checks if the given tax category represents a zero VAT rate category.
    /// Includes categories: Z (Zero rated), E (Exempt), AE (VAT reverse charge), K (EEA intra-community), G (Free export), O (Outside VAT scope).
    /// </summary>
    /// <param name="TaxCategory">The tax category code to check.</param>
    /// <returns>True if the tax category represents zero VAT, false otherwise.</returns>
    procedure IsZeroVatCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(TaxCategory in [
            PEPPOLManagementImpl.GetTaxCategoryZ(),  // Zero rated goods
            PEPPOLManagementImpl.GetTaxCategoryE(),  // Exempt from tax
            PEPPOLManagementImpl.GetTaxCategoryAE(), // VAT reverse charge
            PEPPOLManagementImpl.GetTaxCategoryK(),  // VAT exempt for EEA intra-community supply of goods and services
            PEPPOLManagementImpl.GetTaxCategoryG(),  // Free export item, tax not charged
            PEPPOLManagementImpl.GetTaxCategoryO()   // Outside the scope of VAT
        ]);
    end;

    /// <summary>
    /// Checks if the given tax category represents a standard VAT category (S - Standard rate).
    /// </summary>
    /// <param name="TaxCategory">The tax category code to check.</param>
    /// <returns>True if the tax category is standard VAT, false otherwise.</returns>
    procedure IsStandardVATCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(TaxCategory = PEPPOLManagementImpl.GetTaxCategoryS());
    end;

    /// <summary>
    /// Checks if the given tax category represents outside the scope of VAT (O - Outside the scope of VAT).
    /// </summary>
    /// <param name="TaxCategory">The tax category code to check.</param>
    /// <returns>True if the tax category is outside VAT scope, false otherwise.</returns>
    procedure IsOutsideScopeVATCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(TaxCategory = PEPPOLManagementImpl.GetTaxCategoryO());
    end;

    /// <summary>
    /// Formats a VAT registration number according to PEPPOL standards based on country code and format requirements.
    /// </summary>
    /// <param name="VATRegistrationNo">The VAT registration number to format.</param>
    /// <param name="CountryCode">The country code for the VAT registration.</param>
    /// <param name="IsBISBilling">Whether this is BIS billing format.</param>
    /// <param name="IsPartyTaxScheme">Whether this is for party tax scheme.</param>
    /// <returns>The formatted VAT registration number.</returns>
    procedure FormatVATRegistrationNo(VATRegistrationNo: Text; CountryCode: Code[10]; IsBISBilling: Boolean; IsPartyTaxScheme: Boolean): Text
    begin
        exit(PEPPOLManagementImpl.FormatVATRegistrationNo(VATRegistrationNo, CountryCode, IsBISBilling, IsPartyTaxScheme));
    end;

    /// <summary>
    /// Checks if the given sales line represents an invoice rounding line.
    /// </summary>
    /// <param name="SalesLine">The sales line record to check.</param>
    /// <param name="CustomerNo">The customer number for context.</param>
    /// <returns>True if the line is a rounding line, false otherwise.</returns>
    procedure IsRoundingLine(SalesLine: Record "Sales Line"; CustomerNo: Code[20]): Boolean;
    begin
        exit(PEPPOLManagementImpl.IsRoundingLine(SalesLine, CustomerNo));
    end;

    /// <summary>
    /// Transfers header information from a variant record to a sales header record.
    /// </summary>
    /// <param name="FromRecord">The source record (variant) to transfer from.</param>
    /// <param name="ToSalesHeader">The target sales header record to transfer to.</param>
    procedure TransferHeaderToSalesHeader(FromRecord: Variant; var ToSalesHeader: Record "Sales Header")
    begin
        PEPPOLManagementImpl.TransferHeaderToSalesHeader(FromRecord, ToSalesHeader);
    end;

    /// <summary>
    /// Transfers line information from a variant record to a sales line record.
    /// </summary>
    /// <param name="FromRecord">The source record (variant) to transfer from.</param>
    /// <param name="ToSalesLine">The target sales line record to transfer to.</param>
    procedure TransferLineToSalesLine(FromRecord: Variant; var ToSalesLine: Record "Sales Line")
    begin
        PEPPOLManagementImpl.TransferLineToSalesLine(FromRecord, ToSalesLine);
    end;

    /// <summary>
    /// Transfers fields between two variant records using RecordRef functionality.
    /// </summary>
    /// <param name="FromRecord">The source record (variant) to transfer from.</param>
    /// <param name="ToRecord">The target record (variant) to transfer to.</param>
    procedure RecRefTransferFields(FromRecord: Variant; var ToRecord: Variant)
    begin
        PEPPOLManagementImpl.RecRefTransferFields(FromRecord, ToRecord);
    end;

    /// <summary>
    /// Maps service line types to corresponding sales line types for PEPPOL export.
    /// </summary>
    /// <param name="ServiceLineType">The service line type to map.</param>
    /// <returns>The corresponding sales line type.</returns>
    procedure MapServiceLineTypeToSalesLineType(ServiceLineType: Enum "Service Line Type"): Enum "Sales Line Type"
    begin
        exit(PEPPOLManagementImpl.MapServiceLineTypeToSalesLineType(ServiceLineType));
    end;

    /// <summary>
    /// Gets allowance charge information for payment discounts from VAT amount line and sales header.
    /// </summary>
    /// <param name="VATAmtLine">The VAT amount line record containing allowance charge information.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ChargeIndicator">Returns the charge indicator.</param>
    /// <param name="AllowanceChargeReasonCode">Returns the allowance charge reason code.</param>
    /// <param name="AllowanceChargeListID">Returns the allowance charge list ID.</param>
    /// <param name="AllowanceChargeReason">Returns the allowance charge reason.</param>
    /// <param name="Amount">Returns the amount.</param>
    /// <param name="AllowanceChargeCurrencyID">Returns the allowance charge currency ID.</param>
    /// <param name="TaxCategoryID">Returns the tax category ID.</param>
    /// <param name="TaxCategorySchemeID">Returns the tax category scheme ID.</param>
    /// <param name="Percent">Returns the percent.</param>
    /// <param name="AllowanceChargeTaxSchemeID">Returns the allowance charge tax scheme ID.</param>
    procedure GetAllowanceChargeInfoPaymentDiscount(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAllowanceChargeInfoPaymentDiscount(VATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID, AllowanceChargeReason, Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID, Percent, AllowanceChargeTaxSchemeID);
    end;
}
