// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.History;
using System.Utilities;

/// <summary>
/// XMLPort for exporting Sales Invoices in PEPPOL BIS 3.0 format.
/// Generates UBL-compliant XML documents for electronic invoicing according to PEPPOL standards.
/// </summary>
xmlport 37201 "Sales Invoice - PEPPOL30"
{
    Caption = 'Sales Invoice - PEPPOL BIS 3.0';
    Direction = Export;
    Encoding = UTF8;
    Namespaces = "" = 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', cac = 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', cbc = 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', ccts = 'urn:un:unece:uncefact:documentation:2', qdt = 'urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2', udt = 'urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2';

    schema
    {
        tableelement(invoiceheaderloop; Integer)
        {
            MaxOccurs = Once;
            SourceTableView = sorting(Number) where(Number = filter(1 ..));
            XmlName = 'Invoice';
            textelement(CustomizationID)
            {
                NamespacePrefix = 'cbc';
            }
            textelement(ProfileID)
            {
                NamespacePrefix = 'cbc';
            }
            textelement(ID)
            {
                NamespacePrefix = 'cbc';
            }
            textelement(IssueDate)
            {
                NamespacePrefix = 'cbc';
            }
            textelement(DueDate)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    DueDate := Format(SalesHeader."Due Date", 0, 9);
                    if DueDate = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(InvoiceTypeCode)
            {
                NamespacePrefix = 'cbc';
            }
            textelement(Note)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    if Note = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(TaxPointDate)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    if TaxPointDate = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(DocumentCurrencyCode)
            {
                NamespacePrefix = 'cbc';
            }
            textelement(taxcurrencycodelcy)
            {
                NamespacePrefix = 'cbc';
                XmlName = 'TaxCurrencyCode';

                trigger OnBeforePassVariable()
                var
                    PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
                begin
                    PEPPOLTaxInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLTaxInfoProvider.GetTaxTotalInfoLCY(SalesHeader, TaxAmountLCY, TaxCurrencyCodeLCY, TaxTotalCurrencyIDLCY);
                    if TaxCurrencyCodeLCY = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(AccountingCost)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    if AccountingCost = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(BuyerReference)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                var
                    PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
                begin
                    PEPPOLDocumentInfoProvider := CompanyInformation."E-Document Format";
                    BuyerReference := PEPPOLDocumentInfoProvider.GetBuyerReference(SalesHeader);
                    if BuyerReference = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(InvoicePeriod)
            {
                NamespacePrefix = 'cac';
                textelement(StartDate)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(EndDate)
                {
                    NamespacePrefix = 'cbc';
                }

                trigger OnBeforePassVariable()
                var
                    PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
                begin
                    PEPPOLDocumentInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLDocumentInfoProvider.GetInvoicePeriodInfo(
                      StartDate,
                      EndDate);

                    if (StartDate = '') and (EndDate = '') then
                        currXMLport.Skip();
                end;
            }
            textelement(OrderReference)
            {
                NamespacePrefix = 'cac';
                textelement(orderreferenceid)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }

                trigger OnBeforePassVariable()
                var
                    PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
                begin
                    PEPPOLDocumentInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLDocumentInfoProvider.GetOrderReferenceInfo(
                      SalesHeader,
                      OrderReferenceID);

                    if OrderReferenceID = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(ContractDocumentReference)
            {
                NamespacePrefix = 'cac';
                textelement(contractdocumentreferenceid)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }

                trigger OnBeforePassVariable()
                var
                    ContractRefDocTypeCodeListID: Text;
                    DocumentType: Text;
                    DocumentTypeCode: Text;
                    PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
                begin
                    PEPPOLDocumentInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLDocumentInfoProvider.GetContractDocRefInfo(
                      SalesHeader,
                      ContractDocumentReferenceID,
                      DocumentTypeCode,
                      ContractRefDocTypeCodeListID,
                      DocumentType);

                    if ContractDocumentReferenceID = '' then
                        currXMLport.Skip();
                end;
            }
            tableelement(additionaldocrefloop; Integer)
            {
                NamespacePrefix = 'cac';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                XmlName = 'AdditionalDocumentReference';
                textelement(additionaldocumentreferenceid)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }
                textelement(additionaldocrefdocumenttype)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'DocumentType';

                    trigger OnBeforePassVariable()
                    begin
                        if additionaldocrefdocumenttype = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(Attachment)
                {
                    NamespacePrefix = 'cac';
                    textelement(EmbeddedDocumentBinaryObject)
                    {
                        NamespacePrefix = 'cbc';
                        textattribute(mimeCode)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                if mimeCode = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textattribute(filename)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                if filename = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if EmbeddedDocumentBinaryObject = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(ExternalReference)
                    {
                        NamespacePrefix = 'cac';
                        textelement(URI)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if URI = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if URI = '' then
                                currXMLport.Skip();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                var
                    PEPPOLAttachmentHandler: Interface "PEPPOL Attachment Handler";
                begin
                    PEPPOLAttachmentHandler := CompanyInformation."E-Document Format";
                    if (AdditionalDocRefLoop.Number <= DocumentAttachments.Count()) then
                        PEPPOLAttachmentHandler.GetAdditionalDocRefInfo(
                            additionaldocrefloop.Number,
                            DocumentAttachments,
                            SalesHeader,
                            AdditionalDocumentReferenceID,
                            AdditionalDocRefDocumentType,
                            URI,
                            filename,
                            mimeCode,
                            EmbeddedDocumentBinaryObject,
                            PEPPOL30ProcessingType.AsInteger())
                    else
                        if GeneratePDF then
                            PEPPOLAttachmentHandler.GeneratePDFAttachmentAsAdditionalDocRef(
                            SalesHeader,
                            AdditionalDocumentReferenceID,
                            AdditionalDocRefDocumentType,
                            URI,
                            filename,
                            mimeCode,
                            EmbeddedDocumentBinaryObject);

                    if AdditionalDocumentReferenceID = '' then
                        currXMLport.Skip();
                end;

                trigger OnPreXmlItem()
                var
                    NumberRangeEnd: Integer;
                begin
                    NumberRangeEnd := DocumentAttachments.Count();

                    if GeneratePDF then
                        NumberRangeEnd += 1;

                    // Make sure range end is never 0
                    if NumberRangeEnd = 0 then
                        NumberRangeEnd := 1;
                    AdditionalDocRefLoop.SetRange(Number, 1, NumberRangeEnd);
                end;
            }
            textelement(AccountingSupplierParty)
            {
                NamespacePrefix = 'cac';
                textelement(supplierparty)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Party';
                    textelement(supplierendpointid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'EndpointID';
                        textattribute(supplierschemeid)
                        {
                            XmlName = 'schemeID';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if SupplierEndpointID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(PartyIdentification)
                    {
                        NamespacePrefix = 'cac';
                        textelement(partyidentificationid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(supplierpartyidschemeid)
                            {
                                XmlName = 'schemeID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        var
                            PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
                        begin
                            PEPPOLPartyInfoProvider := CompanyInformation."E-Document Format";
                            PEPPOLPartyInfoProvider.GetAccountingSupplierPartyIdentificationID(SalesHeader, PartyIdentificationID);
                            if PartyIdentificationID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(supplierpartyname)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyName';
                        textelement(suppliername)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                    }
                    textelement(supplierpostaladdress)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PostalAddress';
                        textelement(StreetName)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if StreetName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(supplieradditionalstreetname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'AdditionalStreetName';

                            trigger OnBeforePassVariable()
                            begin
                                if SupplierAdditionalStreetName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(CityName)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if CityName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(PostalZone)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if PostalZone = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(CountrySubentity)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if CountrySubentity = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(Country)
                        {
                            NamespacePrefix = 'cac';
                            textelement(IdentificationCode)
                            {
                                NamespacePrefix = 'cbc';
                            }
                        }
                    }
                    textelement(PartyTaxScheme)
                    {
                        NamespacePrefix = 'cac';
                        textelement(CompanyID)
                        {
                            NamespacePrefix = 'cbc';
                            textattribute(companyidschemeid)
                            {
                                XmlName = 'schemeID';

                                trigger OnBeforePassVariable()
                                begin
                                    if CompanyIDSchemeID = '' then
                                        currXMLport.Skip();
                                end;
                            }
                        }
                        textelement(ExemptionReason)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if ExemptionReason = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(suppliertaxscheme)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(taxschemeid)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'ID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if CompanyID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(PartyLegalEntity)
                    {
                        NamespacePrefix = 'cac';
                        textelement(partylegalentityregname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'RegistrationName';

                            trigger OnBeforePassVariable()
                            begin
                                if PartyLegalEntityRegName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(partylegalentitycompanyid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CompanyID';
                            textattribute(partylegalentityschemeid)
                            {
                                XmlName = 'schemeID';

                                trigger OnBeforePassVariable()
                                begin
                                    if PartyLegalEntitySchemeID = '' then
                                        currXMLport.Skip();
                                end;
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if PartyLegalEntityCompanyID = '' then
                                    currXMLport.Skip();
                            end;
                        }
                    }
                    textelement(Contact)
                    {
                        NamespacePrefix = 'cac';
                        textelement(contactname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';

                            trigger OnBeforePassVariable()
                            begin
                                if ContactName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(Telephone)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if Telephone = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(Telefax)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if Telefax = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(ElectronicMail)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if ElectronicMail = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if (ContactName = '') and (Telephone = '') and (Telefax = '') and (ElectronicMail = '') then
                                currXMLport.Skip();
                        end;
                    }
                }

                trigger OnBeforePassVariable()
                var
                    SupplierRegAddrCityName: Text;
                    SupplierRegAddrCountryIdCode: Text;
                    SupplRegAddrCountryIdListId: Text;
                    PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
                begin
                    PEPPOLPartyInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLPartyInfoProvider.GetAccountingSupplierPartyInfoBIS(
                      SupplierEndpointID,
                      SupplierSchemeID,
                      SupplierName);

                    PEPPOLPartyInfoProvider.GetAccountingSupplierPartyPostalAddr(
                      SalesHeader,
                      StreetName,
                      SupplierAdditionalStreetName,
                      CityName,
                      PostalZone,
                      CountrySubentity,
                      IdentificationCode,
                      DummyVar);

                    PEPPOLPartyInfoProvider.GetAccountingSupplierPartyTaxSchemeBIS(
                      TempVATAmtLine,
                      CompanyID,
                      CompanyIDSchemeID,
                      TaxSchemeID);

                    PEPPOLPartyInfoProvider.GetAccountingSupplierPartyLegalEntityBIS(
                      PartyLegalEntityRegName,
                      PartyLegalEntityCompanyID,
                      PartyLegalEntitySchemeID,
                      SupplierRegAddrCityName,
                      SupplierRegAddrCountryIdCode,
                      SupplRegAddrCountryIdListId);

                    PEPPOLPartyInfoProvider.GetAccountingSupplierPartyContact(
                      SalesHeader,
                      DummyVar,
                      ContactName,
                      Telephone,
                      Telefax,
                      ElectronicMail);
                end;
            }
            textelement(AccountingCustomerParty)
            {
                NamespacePrefix = 'cac';
                textelement(customerparty)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Party';
                    textelement(customerendpointid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'EndpointID';
                        textattribute(customerschemeid)
                        {
                            XmlName = 'schemeID';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if CustomerEndpointID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(customerpartyidentification)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(customerpartyidentificationid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(customerpartyidschemeid)
                            {
                                XmlName = 'schemeID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if CustomerPartyIdentificationID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(custoemerpartyname)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyName';
                        textelement(customername)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                    }
                    textelement(customerpostaladdress)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PostalAddress';
                        textelement(customerstreetname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'StreetName';
                        }
                        textelement(customeradditionalstreetname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'AdditionalStreetName';

                            trigger OnBeforePassVariable()
                            begin
                                if CustomerAdditionalStreetName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(customercityname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CityName';
                        }
                        textelement(customerpostalzone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'PostalZone';
                        }
                        textelement(customercountrysubentity)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CountrySubentity';

                            trigger OnBeforePassVariable()
                            begin
                                if CustomerCountrySubentity = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(customercountry)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'Country';
                            textelement(customeridentificationcode)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'IdentificationCode';
                            }
                        }
                    }
                    textelement(customerpartytaxscheme)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyTaxScheme';
                        textelement(custpartytaxschemecompanyid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CompanyID';
                            textattribute(custpartytaxschemecompidschid)
                            {
                                XmlName = 'schemeID';

                                trigger OnBeforePassVariable()
                                begin
                                    if CustPartyTaxSchemeCompIDSchID = '' then
                                        currXMLport.Skip();
                                end;
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if CustPartyTaxSchemeCompanyID = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(custtaxscheme)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(custtaxschemeid)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'ID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if CustTaxSchemeID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(custpartylegalentity)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyLegalEntity';
                        textelement(custpartylegalentityregname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'RegistrationName';

                            trigger OnBeforePassVariable()
                            begin
                                if CustPartyLegalEntityRegName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(custpartylegalentitycompanyid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CompanyID';
                            textattribute(custpartylegalentityidschemeid)
                            {
                                XmlName = 'schemeID';

                                trigger OnBeforePassVariable()
                                begin
                                    if CustPartyLegalEntityIDSchemeID = '' then
                                        currXMLport.Skip();
                                end;
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if CustPartyLegalEntityCompanyID = '' then
                                    currXMLport.Skip();
                            end;
                        }
                    }
                    textelement(custcontact)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'Contact';
                        textelement(custcontactname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                        textelement(custcontacttelephone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Telephone';

                            trigger OnBeforePassVariable()
                            begin
                                if CustContactTelephone = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(custcontacttelefax)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Telefax';

                            trigger OnBeforePassVariable()
                            begin
                                if CustContactTelefax = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(custcontactelectronicmail)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ElectronicMail';

                            trigger OnBeforePassVariable()
                            begin
                                if CustContactElectronicMail = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if (CustContactName = '') and (CustContactElectronicMail = '') and
                               (CustContactTelephone = '') and (CustContactTelefax = '')
                            then
                                currXMLport.Skip();
                        end;
                    }
                }

                trigger OnBeforePassVariable()
                var
                    PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
                begin
                    PEPPOLPartyInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLPartyInfoProvider.GetAccountingCustomerPartyInfoBIS(
                      SalesHeader,
                      CustomerEndpointID,
                      CustomerSchemeID,
                      CustomerPartyIdentificationID,
                      CustomerPartyIDSchemeID,
                      CustomerName);

                    PEPPOLPartyInfoProvider.GetAccountingCustomerPartyPostalAddr(
                      SalesHeader,
                      CustomerStreetName,
                      CustomerAdditionalStreetName,
                      CustomerCityName,
                      CustomerPostalZone,
                      CustomerCountrySubentity,
                      CustomerIdentificationCode,
                      DummyVar);

                    PEPPOLPartyInfoProvider.GetAccountingCustomerPartyTaxSchemeBIS30(
                      SalesHeader,
                      CustPartyTaxSchemeCompanyID,
                      CustPartyTaxSchemeCompIDSchID,
                      CustTaxSchemeID,
                      TempVATAmtLine);

                    PEPPOLPartyInfoProvider.GetAccountingCustomerPartyLegalEntityBIS(
                      SalesHeader,
                      CustPartyLegalEntityRegName,
                      CustPartyLegalEntityCompanyID,
                      CustPartyLegalEntityIDSchemeID);

                    PEPPOLPartyInfoProvider.GetAccountingCustomerPartyContact(
                      SalesHeader,
                      DummyVar,
                      CustContactName,
                      CustContactTelephone,
                      CustContactTelefax,
                      CustContactElectronicMail);
                end;
            }
            textelement(TaxRepresentativeParty)
            {
                NamespacePrefix = 'cac';
                textelement(taxreppartypartyname)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'PartyName';
                    textelement(taxreppartynamename)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'Name';
                    }
                }
                textelement(payeepartytaxscheme)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'PartyTaxScheme';
                    textelement(payeepartytaxschemecompanyid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'CompanyID';
                        textattribute(payeepartytaxschcompidschemeid)
                        {
                            XmlName = 'schemeID';
                        }
                    }
                    textelement(payeepartytaxschemetaxscheme)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'TaxScheme';
                        textelement(payeepartytaxschemetaxschemeid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if PayeePartyTaxScheme = '' then
                            currXMLport.Skip();
                    end;
                }

                trigger OnBeforePassVariable()
                var
                    PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
                begin
                    PEPPOLPartyInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLPartyInfoProvider.GetTaxRepresentativePartyInfo(
                      TaxRepPartyNameName,
                      PayeePartyTaxSchemeCompanyID,
                      PayeePartyTaxSchCompIDSchemeID,
                      PayeePartyTaxSchemeTaxSchemeID);

                    if TaxRepPartyPartyName = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(Delivery)
            {
                NamespacePrefix = 'cac';
                textelement(ActualDeliveryDate)
                {
                    NamespacePrefix = 'cbc';

                    trigger OnBeforePassVariable()
                    begin
                        if ActualDeliveryDate = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(DeliveryLocation)
                {
                    NamespacePrefix = 'cac';
                    textelement(deliveryid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ID';
                        textattribute(deliveryidschemeid)
                        {
                            XmlName = 'schemeID';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if DeliveryID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(deliveryaddress)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'Address';
                        textelement(deliverystreetname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'StreetName';
                        }
                        textelement(deliveryadditionalstreetname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'AdditionalStreetName';

                            trigger OnBeforePassVariable()
                            begin
                                if DeliveryAdditionalStreetName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(deliverycityname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CityName';

                            trigger OnBeforePassVariable()
                            begin
                                if DeliveryCityName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(deliverypostalzone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'PostalZone';

                            trigger OnBeforePassVariable()
                            begin
                                if DeliveryPostalZone = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(deliverycountrysubentity)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CountrySubentity';

                            trigger OnBeforePassVariable()
                            begin
                                if DeliveryCountrySubentity = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(deliverycountry)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'Country';
                            textelement(deliverycountryidcode)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'IdentificationCode';
                            }
                        }
                    }
                }
                textelement(DeliveryParty)
                {
                    NamespacePrefix = 'cac';
                    XMLName = 'DeliveryParty';
                    textelement(DeliveryPartyName)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyName';
                        textelement(DeliveryPartyNameValue)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                    }
                    trigger OnBeforePassVariable()
                    begin
                        if DeliveryPartyNameValue = '' then
                            currXMLport.Skip();
                    end;
                }

                trigger OnBeforePassVariable()
                var
                    PEPPOLDeliveryInfoProvider: Interface "PEPPOL Delivery Info Provider";
                begin
                    PEPPOLDeliveryInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLDeliveryInfoProvider.GetGLNDeliveryInfo(
                      SalesHeader,
                      ActualDeliveryDate,
                      DeliveryID,
                      DeliveryIDSchemeID);

                    PEPPOLDeliveryInfoProvider.GetDeliveryAddress(
                      SalesHeader,
                      DeliveryStreetName,
                      DeliveryAdditionalStreetName,
                      DeliveryCityName,
                      DeliveryPostalZone,
                      DeliveryCountrySubentity,
                      DeliveryCountryIdCode,
                      DummyVar);

                    PEPPOLDeliveryInfoProvider.GetDeliveryPartyName(SalesHeader, DeliveryPartyNameValue);
                end;
            }
            textelement(PaymentMeans)
            {
                NamespacePrefix = 'cac';
                textelement(PaymentMeansCode)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(PaymentChannelCode)
                {
                    NamespacePrefix = 'cbc';

                    trigger OnBeforePassVariable()
                    begin
                        if PaymentChannelCode = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(PaymentID)
                {
                    NamespacePrefix = 'cbc';

                    trigger OnBeforePassVariable()
                    begin
                        if PaymentID = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(CardAccount)
                {
                    NamespacePrefix = 'cac';
                    textelement(PrimaryAccountNumberID)
                    {
                        NamespacePrefix = 'cbc';
                    }
                    textelement(NetworkID)
                    {
                        NamespacePrefix = 'cbc';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if PrimaryAccountNumberID = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(PayeeFinancialAccount)
                {
                    NamespacePrefix = 'cac';
                    textelement(payeefinancialaccountid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ID';
                    }
                    textelement(FinancialInstitutionBranch)
                    {
                        NamespacePrefix = 'cac';
                        textelement(financialinstitutionbranchid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                    }
                }

                trigger OnBeforePassVariable()
                var
                    PEPPOLPaymentInfoProvider: Interface "PEPPOL Payment Info Provider";
                begin
                    PEPPOLPaymentInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLPaymentInfoProvider.GetPaymentMeansInfo(
                      SalesHeader,
                      PaymentMeansCode,
                      DummyVar,
                      DummyVar,
                      PaymentChannelCode,
                      PaymentID,
                      PrimaryAccountNumberID,
                      NetworkID);

                    PEPPOLPaymentInfoProvider.GetPaymentMeansPayeeFinancialAccBIS(
                        SalesHeader,
                        PayeeFinancialAccountID,
                        FinancialInstitutionBranchID);
                end;
            }
            tableelement(pmttermsloop; Integer)
            {
                NamespacePrefix = 'cac';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                XmlName = 'PaymentTerms';
                textelement(paymenttermsnote)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'Note';
                }

                trigger OnAfterGetRecord()
                var
                    PEPPOLPaymentInfoProvider: Interface "PEPPOL Payment Info Provider";
                begin
                    PEPPOLPaymentInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLPaymentInfoProvider.GetPaymentTermsInfo(
                      SalesHeader,
                      PaymentTermsNote);

                    if PaymentTermsNote = '' then
                        currXMLport.Skip();
                end;

                trigger OnPreXmlItem()
                begin
                    PmtTermsLoop.SetRange(Number, 1, 1);
                end;
            }
            tableelement(allowancechargeloop; Integer)
            {
                NamespacePrefix = 'cac';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                XmlName = 'AllowanceCharge';
                textelement(ChargeIndicator)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(AllowanceChargeReasonCode)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(AllowanceChargeReason)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(Amount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(allowancechargecurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(TaxCategory)
                {
                    NamespacePrefix = 'cac';
                    textelement(taxcategoryid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ID';
                    }
                    textelement(Percent)
                    {
                        NamespacePrefix = 'cbc';

                        trigger OnBeforePassVariable()
                        begin
                            if Percent = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(TaxScheme)
                    {
                        NamespacePrefix = 'cac';
                        textelement(allowancechargetaxschemeid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                    }
                }

                trigger OnAfterGetRecord()
                var
                    PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
                begin
                    if not FindNextVATAmtRec(TempVATAmtLine, AllowanceChargeLoop.Number) then
                        currXMLport.Break();

                    PEPPOLTaxInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLTaxInfoProvider.GetAllowanceChargeInfo(
                      TempVATAmtLine,
                      SalesHeader,
                      ChargeIndicator,
                      AllowanceChargeReasonCode,
                      DummyVar,
                      AllowanceChargeReason,
                      Amount,
                      AllowanceChargeCurrencyID,
                      TaxCategoryID,
                      DummyVar,
                      Percent,
                      AllowanceChargeTaxSchemeID);

                    if ChargeIndicator = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(TaxTotal)
            {
                NamespacePrefix = 'cac';
                textelement(TaxAmount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(taxtotalcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                tableelement(taxsubtotalloop; Integer)
                {
                    NamespacePrefix = 'cac';
                    SourceTableView = sorting(Number) where(Number = filter(1 ..));
                    XmlName = 'TaxSubtotal';
                    textelement(TaxableAmount)
                    {
                        NamespacePrefix = 'cbc';
                        textattribute(taxsubtotalcurrencyid)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    textelement(subtotaltaxamount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'TaxAmount';
                        textattribute(taxamountcurrencyid)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    textelement(subtotaltaxcategory)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'TaxCategory';
                        textelement(taxtotaltaxcategoryid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                        textelement(taxcategorypercent)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Percent';
                        }
                        textelement(TaxExemptionReason)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if TaxExemptionReason = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(taxsubtotaltaxscheme)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(taxtotaltaxschemeid)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'ID';
                            }
                        }
                    }

                    trigger OnAfterGetRecord()
                    var
                        TransactionCurrencyTaxAmount: Text;
                        TransCurrTaxAmtCurrencyID: Text;
                        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
                    begin
                        if (not FindNextVATAmtRec(TempVATAmtLine, TaxSubtotalLoop.Number)) and (TaxSubtotalLoop.Number > 1) then
                            currXMLport.Break();

                        PEPPOLTaxInfoProvider := CompanyInformation."E-Document Format";
                        PEPPOLTaxInfoProvider.GetTaxSubtotalInfo(
                          TempVATAmtLine,
                          SalesHeader,
                          TaxableAmount,
                          TaxAmountCurrencyID,
                          SubtotalTaxAmount,
                          TaxSubtotalCurrencyID,
                          TransactionCurrencyTaxAmount,
                          TransCurrTaxAmtCurrencyID,
                          TaxTotalTaxCategoryID,
                          DummyVar,
                          TaxCategoryPercent,
                          TaxTotalTaxSchemeID);

                        PEPPOLTaxInfoProvider.GetTaxExemptionReason(TempVATProductPostingGroup, TaxExemptionReason, TaxTotalTaxCategoryID);
                    end;
                }

                trigger OnBeforePassVariable()
                var
                    PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
                begin
                    PEPPOLTaxInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLTaxInfoProvider.GetTaxTotalInfo(
                      SalesHeader,
                      TempVATAmtLine,
                      TaxAmount,
                      TaxTotalCurrencyID);
                end;
            }
            textelement(taxtotallcy)
            {
                NamespacePrefix = 'cac';
                XmlName = 'TaxTotal';
                textelement(taxamountlcy)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'TaxAmount';
                    textattribute(taxtotalcurrencyidlcy)
                    {
                        XmlName = 'currencyID';
                    }
                }

                trigger OnBeforePassVariable()
                begin
                    if TaxTotalCurrencyIDLCY = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(LegalMonetaryTotal)
            {
                NamespacePrefix = 'cac';
                textelement(LineExtensionAmount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(legalmonetarytotalcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(TaxExclusiveAmount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(taxexclusiveamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(TaxInclusiveAmount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(taxinclusiveamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(AllowanceTotalAmount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(allowancetotalamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if AllowanceTotalAmount = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(ChargeTotalAmount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(chargetotalamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if ChargeTotalAmount = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(PrepaidAmount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(prepaidcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(PayableRoundingAmount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(payablerndingamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if PayableRoundingAmount = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(PayableAmount)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(payableamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }

                trigger OnBeforePassVariable()
                var
                    PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
                begin
                    PEPPOLMonetaryInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLMonetaryInfoProvider.GetLegalMonetaryInfo(
                      SalesHeader,
                      TempSalesLineRounding,
                      TempVATAmtLine,
                      LineExtensionAmount,
                      LegalMonetaryTotalCurrencyID,
                      TaxExclusiveAmount,
                      TaxExclusiveAmountCurrencyID,
                      TaxInclusiveAmount,
                      TaxInclusiveAmountCurrencyID,
                      AllowanceTotalAmount,
                      AllowanceTotalAmountCurrencyID,
                      ChargeTotalAmount,
                      ChargeTotalAmountCurrencyID,
                      PrepaidAmount,
                      PrepaidCurrencyID,
                      PayableRoundingAmount,
                      PayableRndingAmountCurrencyID,
                      PayableAmount,
                      PayableAmountCurrencyID);
                end;
            }
            tableelement(invoicelineloop; Integer)
            {
                NamespacePrefix = 'cac';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                XmlName = 'InvoiceLine';
                textelement(invoicelineid)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }
                textelement(invoicelinenote)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'Note';

                    trigger OnBeforePassVariable()
                    begin
                        if InvoiceLineNote = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(InvoicedQuantity)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(unitCode)
                    {
                    }
                }
                textelement(invoicelineextensionamount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'LineExtensionAmount';
                    textattribute(lineextensionamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(invoicelineaccountingcost)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'AccountingCost';

                    trigger OnBeforePassVariable()
                    begin
                        if InvoiceLineAccountingCost = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(invoicelineinvoiceperiod)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'InvoicePeriod';
                    textelement(invlineinvoiceperiodstartdate)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'StartDate';
                    }
                    textelement(invlineinvoiceperiodenddate)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'EndDate';
                    }

                    trigger OnBeforePassVariable()
                    var
                        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                    begin
                        PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                        PEPPOLLineInfoProvider.GetLineInvoicePeriodInfo(
                          InvLineInvoicePeriodStartDate,
                          InvLineInvoicePeriodEndDate);

                        if (InvLineInvoicePeriodStartDate = '') and (InvLineInvoicePeriodEndDate = '') then
                            currXMLport.Skip();
                    end;
                }
                textelement(OrderLineReference)
                {
                    NamespacePrefix = 'cac';
                    textelement(orderlinereferencelineid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'LineID';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if OrderLineReferenceLineID = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(invoicelinedelivery)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Delivery';
                    textelement(invoicelineactualdeliverydate)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ActualDeliveryDate';
                    }
                    textelement(invoicelinedeliverylocation)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'DeliveryLocation';
                        textelement(invoicelinedeliveryid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(invoicelinedeliveryidschemeid)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        textelement(invoicelinedeliveryaddress)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'Address';
                            textelement(invoicelinedeliverystreetname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'StreetName';
                            }
                            textelement(invlinedeliveryaddstreetname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'AdditionalStreetName';
                            }
                            textelement(invoicelinedeliverycityname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'CityName';
                            }
                            textelement(invoicelinedeliverypostalzone)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'PostalZone';
                            }
                            textelement(invlndeliverycountrysubentity)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'CountrySubentity';
                            }
                            textelement(invoicelinedeliverycountry)
                            {
                                NamespacePrefix = 'cac';
                                XmlName = 'Country';
                                textelement(invlndeliverycountryidcode)
                                {
                                    NamespacePrefix = 'cbc';
                                    XmlName = 'IdentificationCode';
                                }
                            }
                        }
                    }

                    trigger OnBeforePassVariable()
                    var
                        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                        InvLineDeliveryCountryListID: Text;
                    begin
                        PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                        PEPPOLLineInfoProvider.GetLineDeliveryInfo(
                          InvoiceLineActualDeliveryDate,
                          InvoiceLineDeliveryID,
                          InvoiceLineDeliveryIDSchemeID);

                        PEPPOLLineInfoProvider.GetLineDeliveryPostalAddr(
                          InvoiceLineDeliveryStreetName,
                          InvLineDeliveryAddStreetName,
                          InvoiceLineDeliveryCityName,
                          InvoiceLineDeliveryPostalZone,
                          InvLnDeliveryCountrySubentity,
                          InvLnDeliveryCountryIdCode,
                          InvLineDeliveryCountryListID);

                        if (InvoiceLineDeliveryID = '') and
                           (InvoiceLineDeliveryStreetName = '') and
                           (InvoiceLineActualDeliveryDate = '')
                        then
                            currXMLport.Skip();
                    end;
                }
                tableelement(invlnallowancechargeloop; Integer)
                {
                    NamespacePrefix = 'cac';
                    SourceTableView = sorting(Number) where(Number = filter(1 ..));
                    XmlName = 'AllowanceCharge';
                    textelement(invlnallowancechargeindicator)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ChargeIndicator';
                    }
                    textelement(invlnallowancechargereason)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'AllowanceChargeReason';
                    }
                    textelement(invlnallowancechargeamount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'Amount';
                        textattribute(invlnallowancechargeamtcurrid)
                        {
                            XmlName = 'currencyID';
                        }
                    }

                    trigger OnAfterGetRecord()
                    var
                        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                    begin
                        PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                        PEPPOLLineInfoProvider.GetLineAllowanceChargeInfo(
                          SalesLine,
                          SalesHeader,
                          InvLnAllowanceChargeIndicator,
                          InvLnAllowanceChargeReason,
                          InvLnAllowanceChargeAmount,
                          InvLnAllowanceChargeAmtCurrID);

                        if InvLnAllowanceChargeIndicator = '' then
                            currXMLport.Skip();
                    end;

                    trigger OnPreXmlItem()
                    begin
                        InvLnAllowanceChargeLoop.SetRange(Number, 1, 1);
                    end;
                }
                textelement(Item)
                {
                    NamespacePrefix = 'cac';
                    textelement(Description)
                    {
                        NamespacePrefix = 'cbc';

                        trigger OnBeforePassVariable()
                        begin
                            if Description = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(Name)
                    {
                        NamespacePrefix = 'cbc';
                    }
                    textelement(SellersItemIdentification)
                    {
                        NamespacePrefix = 'cac';
                        textelement(sellersitemidentificationid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if SellersItemIdentificationID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(StandardItemIdentification)
                    {
                        NamespacePrefix = 'cac';
                        textelement(standarditemidentificationid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(stditemididschemeid)
                            {
                                XmlName = 'schemeID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if StandardItemIdentificationID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(OriginCountry)
                    {
                        NamespacePrefix = 'cac';
                        textelement(origincountryidcode)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'IdentificationCode';
                            textattribute(origincountryidcodelistid)
                            {
                                XmlName = 'listID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if OriginCountryIdCode = '' then
                                currXMLport.Skip();
                        end;
                    }
                    tableelement(commodityclassificationloop; Integer)
                    {
                        NamespacePrefix = 'cac';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
                        XmlName = 'CommodityClassification';
                        textelement(CommodityCode)
                        {
                            NamespacePrefix = 'cbc';
                            textattribute(commoditycodelistid)
                            {
                                XmlName = 'listID';
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if CommodityCode = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(ItemClassificationCode)
                        {
                            NamespacePrefix = 'cbc';
                            textattribute(itemclassificationcodelistid)
                            {
                                XmlName = 'listID';
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if ItemClassificationCode = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnAfterGetRecord()
                        var
                            PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                        begin
                            PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                            PEPPOLLineInfoProvider.GetLineItemCommodityClassificationInfo(
                              CommodityCode,
                              CommodityCodeListID,
                              ItemClassificationCode,
                              ItemClassificationCodeListID);

                            if (CommodityCode = '') and (ItemClassificationCode = '') then
                                currXMLport.Skip();
                        end;

                        trigger OnPreXmlItem()
                        begin
                            CommodityClassificationLoop.SetRange(Number, 1, 1);
                        end;
                    }
                    textelement(ClassifiedTaxCategory)
                    {
                        NamespacePrefix = 'cac';
                        textelement(classifiedtaxcategoryid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                        textelement(invoicelinetaxpercent)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Percent';

                            trigger OnBeforePassVariable()
                            begin
                                if InvoiceLineTaxPercent = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(classifiedtaxcategorytaxscheme)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(classifiedtaxcategoryschemeid)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'ID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        var
                            PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                        begin
                            PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                            PEPPOLLineInfoProvider.GetLineItemClassifiedTaxCategoryBIS(
                              SalesLine,
                              ClassifiedTaxCategoryID,
                              DummyVar,
                              InvoiceLineTaxPercent,
                              ClassifiedTaxCategorySchemeID);
                        end;
                    }
                    tableelement(additionalitempropertyloop; Integer)
                    {
                        NamespacePrefix = 'cac';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
                        XmlName = 'AdditionalItemProperty';
                        textelement(additionalitempropertyname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                        textelement(additionalitempropertyvalue)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Value';
                        }

                        trigger OnAfterGetRecord()
                        var
                            PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                        begin
                            PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                            PEPPOLLineInfoProvider.GetLineAdditionalItemPropertyInfo(
                              SalesLine,
                              AdditionalItemPropertyName,
                              AdditionalItemPropertyValue);

                            if AdditionalItemPropertyName = '' then
                                currXMLport.Skip();
                        end;

                        trigger OnPreXmlItem()
                        begin
                            AdditionalItemPropertyLoop.SetRange(Number, 1, 1);
                        end;
                    }

                    trigger OnBeforePassVariable()
                    var
                        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                    begin
                        PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                        PEPPOLLineInfoProvider.GetLineItemInfo(
                          SalesLine,
                          Description,
                          Name,
                          SellersItemIdentificationID,
                          StandardItemIdentificationID,
                          StdItemIdIDSchemeID,
                          OriginCountryIdCode,
                          OriginCountryIdCodeListID);
                    end;
                }
                textelement(invoicelineprice)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Price';
                    textelement(invoicelinepriceamount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'PriceAmount';
                        textattribute(invlinepriceamountcurrencyid)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    textelement(BaseQuantity)
                    {
                        NamespacePrefix = 'cbc';
                        textattribute(unitcodebaseqty)
                        {
                            XmlName = 'unitCode';
                        }
                    }
                    tableelement(priceallowancechargeloop; Integer)
                    {
                        NamespacePrefix = 'cac';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
                        XmlName = 'AllowanceCharge';
                        textelement(pricechargeindicator)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ChargeIndicator';
                        }
                        textelement(priceallowancechargeamount)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Amount';
                            textattribute(priceallowanceamountcurrencyid)
                            {
                                XmlName = 'currencyID';
                            }
                        }
                        textelement(priceallowancechargebaseamount)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'BaseAmount';
                            textattribute(priceallowchargebaseamtcurrid)
                            {
                                XmlName = 'currencyID';
                            }
                        }

                        trigger OnAfterGetRecord()
                        var
                            PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                        begin
                            PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                            PEPPOLLineInfoProvider.GetLinePriceAllowanceChargeInfo(
                              PriceChargeIndicator,
                              PriceAllowanceChargeAmount,
                              PriceAllowanceAmountCurrencyID,
                              PriceAllowanceChargeBaseAmount,
                              PriceAllowChargeBaseAmtCurrID);

                            if PriceChargeIndicator = '' then
                                currXMLport.Skip();
                        end;

                        trigger OnPreXmlItem()
                        begin
                            PriceAllowanceChargeLoop.SetRange(Number, 1, 1);
                        end;
                    }

                    trigger OnBeforePassVariable()
                    var
                        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                    begin
                        PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                        PEPPOLLineInfoProvider.GetLinePriceInfo(
                          SalesLine,
                          SalesHeader,
                          InvoiceLinePriceAmount,
                          InvLinePriceAmountCurrencyID,
                          BaseQuantity,
                          UnitCodeBaseQty);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
                begin
                    if not FindNextInvoiceLineRec(InvoiceLineLoop.Number) then
                        currXMLport.Break();

                    PEPPOLLineInfoProvider := CompanyInformation."E-Document Format";
                    PEPPOLLineInfoProvider.GetLineGeneralInfo(
                      SalesLine,
                      SalesHeader,
                      InvoiceLineID,
                      InvoiceLineNote,
                      InvoicedQuantity,
                      InvoiceLineExtensionAmount,
                      LineExtensionAmountCurrencyID,
                      InvoiceLineAccountingCost);

                    PEPPOLLineInfoProvider.GetLineUnitCodeInfo(SalesLine, unitCode, DummyVar);
                end;
            }

            trigger OnAfterGetRecord()
            var
                PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
            begin
                if not FindNextInvoiceRec(InvoiceHeaderLoop.Number) then
                    currXMLport.Break();

                GetTotals();

                PEPPOLDocumentInfoProvider := CompanyInformation."E-Document Format";
                PEPPOLDocumentInfoProvider.GetGeneralInfoBIS(
                  SalesHeader,
                  ID,
                  IssueDate,
                  InvoiceTypeCode,
                  Note,
                  TaxPointDate,
                  DocumentCurrencyCode,
                  AccountingCost);

                CustomizationID := GetCustomizationID();
                ProfileID := GetProfileID();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Control2)
                {
                    ShowCaption = false;
#pragma warning disable AA0100
                    field("SalesInvoiceHeader.""No."""; SalesInvoiceHeader."No.")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Invoice No.';
                        TableRelation = "Sales Invoice Header";
                        ToolTip = 'Specifies the sales invoice to be exported as a PEPPOL 3.0 document.';
                    }
                }
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CompanyInformation.Get();
    end;

    var
#if not CLEAN25
#pragma warning disable AL0432
#endif
        TempVATAmtLine: Record "VAT Amount Line" temporary;
#if not CLEAN25
#pragma warning restore AL0432
#endif
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary;
        TempSalesLineRounding: Record "Sales Line" temporary;
        DocumentAttachments: Record "Document Attachment";
        CompanyInformation: Record "Company Information";
        SourceRecRef: RecordRef;
        PEPPOL30ExportManagement: Interface "PEPPOL30 Export Management";
        PEPPOL30ProcessingType: Enum "PEPPOL30 Processing Type";
        DummyVar: Text;
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';
        GeneratePDF: Boolean;

    local procedure GetTotals()
    begin
        PEPPOL30ExportManagement.GetTotals(TempVATAmtLine, TempVATProductPostingGroup);
    end;

    local procedure FindNextInvoiceRec(Position: Integer): Boolean
    begin
        exit(PEPPOL30ExportManagement.FindNextRec(Position, CompanyInformation."E-Document Format"));
    end;

    local procedure FindNextInvoiceLineRec(Position: Integer): Boolean
    begin
        exit(PEPPOL30ExportManagement.FindNextLineRec(Position, CompanyInformation."E-Document Format"));
    end;

#if not CLEAN25
#pragma warning disable AL0432
#endif
    local procedure FindNextVATAmtRec(var VATAmtLine: Record "VAT Amount Line"; Position: Integer): Boolean
#if not CLEAN25
#pragma warning restore AL0432
#endif
    begin
        if Position = 1 then
            exit(VATAmtLine.Find('-'));
        exit(VATAmtLine.Next() <> 0);
    end;

    procedure Initialize(DocVariant: Variant)
    var
        IsHandled: Boolean;
    begin
        SourceRecRef.GetTable(DocVariant);
        case SourceRecRef.Number of
            Database::"Sales Invoice Header":
                PEPPOL30ProcessingType := PEPPOL30ProcessingType::Sale;
            Database::"Service Invoice Header":
                PEPPOL30ProcessingType := PEPPOL30ProcessingType::Service;
            else begin
                IsHandled := false;
                OnInitialize(SourceRecRef, TempSalesLineRounding, DocumentAttachments, PEPPOL30ProcessingType, IsHandled);
                if not IsHandled then
                    Error(UnSupportedTableTypeErr, SourceRecRef.Number);
            end;
        end;
        if SourceRecRef.Number <> 0 then begin
            PEPPOL30ExportManagement := PEPPOL30ProcessingType;
            PEPPOL30ExportManagement.Init(SourceRecRef, TempSalesLineRounding, DocumentAttachments);
        end;
    end;

    /// <summary>
    /// Controls whether a PDF document should be generated and included as an additional document reference.
    /// </summary>
    /// <param name="GeneratePDFValue">If true, generates a PDF based on Report Selection settings.</param>
    procedure SetGeneratePDF(GeneratePDFValue: Boolean)
    begin
        this.GeneratePDF := GeneratePDFValue;
    end;

    local procedure GetCustomizationID(): Text
    begin
        exit('urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0')
    end;

    local procedure GetProfileID(): Text
    begin
        exit('urn:fdc:peppol.eu:2017:poacc:billing:01:1.0');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitialize(SourceRecRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment"; var PEPPOL30ProcessingType: Enum "PEPPOL30 Processing Type"; var IsHandled: Boolean);
    begin
    end;
}
