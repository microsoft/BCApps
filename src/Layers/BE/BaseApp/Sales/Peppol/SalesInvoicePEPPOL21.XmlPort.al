// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#if not CLEAN26
namespace Microsoft.Sales.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;

xmlport 1600 "Sales Invoice - PEPPOL 2.1"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'PEPPOL 2.1 is no longer supported.';
    ObsoleteTag = '26.0';
    Caption = 'Sales Invoice - PEPPOL 2.1';
    Direction = Export;
    Encoding = UTF8;
    Namespaces = "" = 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', cac = 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', cbc = 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', ccts = 'urn:un:unece:uncefact:documentation:2', qdt = 'urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2', udt = 'urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2';

    schema
    {
        tableelement(invoiceheaderloop; Integer)
        {
            MaxOccurs = Once;
            XmlName = 'Invoice';
            SourceTableView = sorting(Number) where(Number = filter(1 ..));
            textelement(UBLVersionID)
            {
                NamespacePrefix = 'cbc';
            }
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
            textelement(InvoiceTypeCode)
            {
                NamespacePrefix = 'cbc';
                textattribute(invoicetypecodelistid)
                {
                    XmlName = 'listID';
                }
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
                textattribute(documentcurrencycodelistid)
                {
                    XmlName = 'listID';
                }
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
                begin
                    PEPPOLMgt.GetInvoicePeriodInfo(
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
                begin
                    PEPPOLMgt.GetOrderReferenceInfo(
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
                textelement(DocumentType)
                {
                    NamespacePrefix = 'cbc';
                }

                trigger OnBeforePassVariable()
                var
                    DocumentTypeCode: Text;
                    ContractRefDocTypeCodeListID: Text;
                begin
                    PEPPOLMgt.GetContractDocRefInfo(
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
                XmlName = 'AdditionalDocumentReference';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(additionaldocumentreferenceid)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }
                textelement(additionaldocrefdocumenttype)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'DocumentType';
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
                        }
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    PEPPOLMgt.GetAdditionalDocRefInfo(
                        SalesHeader,
                        AdditionalDocumentReferenceID,
                        AdditionalDocRefDocumentType,
                        URI,
                        mimeCode,
                        EmbeddedDocumentBinaryObject,
                        ProcessedDocType.AsInteger());

                    if AdditionalDocumentReferenceID = '' then
                        currXMLport.Skip();
                end;

                trigger OnPreXmlItem()
                begin
                    AdditionalDocRefLoop.SetRange(Number, 1, 1);
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
                        begin
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
                        }
                        textelement(supplieradditionalstreetname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'AdditionalStreetName';
                        }
                        textelement(CityName)
                        {
                            NamespacePrefix = 'cbc';
                        }
                        textelement(PostalZone)
                        {
                            NamespacePrefix = 'cbc';
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
                                textattribute(listid)
                                {
                                    XmlName = 'listID';
                                }
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
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if CompanyID = '' then
                                    currXMLport.Skip();
                            end;
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
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if PartyLegalEntityCompanyID = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(RegistrationAddress)
                        {
                            NamespacePrefix = 'cac';
                            textelement(supplierregaddrcityname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'CityName';
                            }
                            textelement(supplierregaddrcountry)
                            {
                                NamespacePrefix = 'cac';
                                XmlName = 'Country';
                                textelement(supplierregaddrcountryidcode)
                                {
                                    NamespacePrefix = 'cbc';
                                    XmlName = 'IdentificationCode';
                                    textattribute(supplregaddrcountryidlistid)
                                    {
                                        XmlName = 'listID';
                                    }
                                }
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if (SupplierRegAddrCityName = '') and (SupplierRegAddrCountry = '') then
                                    currXMLport.Skip();
                            end;
                        }
                    }
                    textelement(Contact)
                    {
                        NamespacePrefix = 'cac';
                        textelement(contactid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                        textelement(contactname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                        textelement(Telephone)
                        {
                            NamespacePrefix = 'cbc';
                        }
                        textelement(Telefax)
                        {
                            NamespacePrefix = 'cbc';
                        }
                        textelement(ElectronicMail)
                        {
                            NamespacePrefix = 'cbc';
                        }
                    }
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetAccountingSupplierPartyInfo(
                      SupplierEndpointID,
                      SupplierSchemeID,
                      SupplierName);

                    PEPPOLMgt.GetAccountingSupplierPartyPostalAddr(
                      SalesHeader,
                      StreetName,
                      SupplierAdditionalStreetName,
                      CityName,
                      PostalZone,
                      CountrySubentity,
                      IdentificationCode,
                      ListID);

                    PEPPOLMgt.GetAccountingSupplierPartyTaxScheme(
                      CompanyID,
                      CompanyIDSchemeID,
                      TaxSchemeID);

                    PEPPOLMgt.GetAccountingSupplierPartyLegalEntity(
                      PartyLegalEntityRegName,
                      PartyLegalEntityCompanyID,
                      PartyLegalEntitySchemeID,
                      SupplierRegAddrCityName,
                      SupplierRegAddrCountryIdCode,
                      SupplRegAddrCountryIdListId);

                    PEPPOLMgt.GetAccountingSupplierPartyContact(
                      SalesHeader,
                      ContactID,
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
                                textattribute(customerlistid)
                                {
                                    XmlName = 'listID';
                                }
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
                        textelement(custcontactid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                        textelement(custcontactname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                        textelement(custcontacttelephone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Telephone';
                        }
                        textelement(custcontacttelefax)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Telefax';
                        }
                        textelement(custcontactelectronicmail)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ElectronicMail';
                        }
                    }
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetAccountingCustomerPartyInfo(
                      SalesHeader,
                      CustomerEndpointID,
                      CustomerSchemeID,
                      CustomerPartyIdentificationID,
                      CustomerPartyIDSchemeID,
                      CustomerName);

                    PEPPOLMgt.GetAccountingCustomerPartyPostalAddr(
                      SalesHeader,
                      CustomerStreetName,
                      CustomerAdditionalStreetName,
                      CustomerCityName,
                      CustomerPostalZone,
                      CustomerCountrySubentity,
                      CustomerIdentificationCode,
                      CustomerListID);

                    PEPPOLMgt.GetAccountingCustomerPartyTaxScheme(
                      SalesHeader,
                      CustPartyTaxSchemeCompanyID,
                      CustPartyTaxSchemeCompIDSchID,
                      CustTaxSchemeID);

                    PEPPOLMgt.GetAccountingCustomerPartyLegalEntity(
                      SalesHeader,
                      CustPartyLegalEntityRegName,
                      CustPartyLegalEntityCompanyID,
                      CustPartyLegalEntityIDSchemeID);

                    PEPPOLMgt.GetAccountingCustomerPartyContact(
                      SalesHeader,
                      CustContactID,
                      CustContactName,
                      CustContactTelephone,
                      CustContactTelefax,
                      CustContactElectronicMail);
                end;
            }
            textelement(PayeeParty)
            {
                NamespacePrefix = 'cac';
                textelement(payeepartyidentification)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'PartyIdentification';
                    textelement(payeepartyid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ID';
                        textattribute(payeepartyidschemeid)
                        {
                            XmlName = 'schemeID';
                        }
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if PayeePartyID = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(payeepartyname)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'PartyName';
                    textelement(payeepartynamename)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'Name';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if PayeePartyNameName = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(payeepartylegalentity)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'PartyLegalEntity';
                    textelement(payeepartylegalentitycompanyid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'CompanyID';
                        textattribute(payeepartylegalcompidschemeid)
                        {
                            XmlName = 'schemeID';
                        }
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if PayeePartyLegalEntityCompanyID = '' then
                            currXMLport.Skip();
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetPayeePartyInfo(
                      PayeePartyID,
                      PayeePartyIDSchemeID,
                      PayeePartyNameName,
                      PayeePartyLegalEntityCompanyID,
                      PayeePartyLegalCompIDSchemeID)
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
                begin
                    PEPPOLMgt.GetTaxRepresentativePartyInfo(
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
                        }
                        textelement(deliverycityname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CityName';
                        }
                        textelement(deliverypostalzone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'PostalZone';
                        }
                        textelement(deliverycountrysubentity)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CountrySubentity';
                        }
                        textelement(deliverycountry)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'Country';
                            textelement(deliverycountryidcode)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'IdentificationCode';
                                textattribute(deliverycountrylistid)
                                {
                                    XmlName = 'listID';
                                }
                            }
                        }
                    }
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetGLNDeliveryInfo(
                      SalesHeader,
                      ActualDeliveryDate,
                      DeliveryID,
                      DeliveryIDSchemeID);

                    PEPPOLMgt.GetDeliveryAddress(
                      SalesHeader,
                      DeliveryStreetName,
                      DeliveryAdditionalStreetName,
                      DeliveryCityName,
                      DeliveryPostalZone,
                      DeliveryCountrySubentity,
                      DeliveryCountryIdCode,
                      DeliveryCountryListID);
                end;
            }
            textelement(PaymentMeans)
            {
                NamespacePrefix = 'cac';
                textelement(PaymentMeansCode)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(paymentmeanslistid)
                    {
                        XmlName = 'listID';
                    }
                }
                textelement(PaymentDueDate)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(PaymentChannelCode)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(PaymentID)
                {
                    NamespacePrefix = 'cbc';
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
                        textattribute(paymentmeansschemeid)
                        {
                            XmlName = 'schemeID';
                        }
                    }
                    textelement(FinancialInstitutionBranch)
                    {
                        NamespacePrefix = 'cac';
                        textelement(financialinstitutionbranchid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                        textelement(FinancialInstitution)
                        {
                            NamespacePrefix = 'cac';
                            textelement(financialinstitutionid)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'ID';
                                textattribute(financialinstitutionschemeid)
                                {
                                    XmlName = 'schemeID';
                                }
                            }
                            textelement(financialinstitutionname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'Name';
                            }
                            textelement(Address)
                            {
                                NamespacePrefix = 'cac';
                                textelement(financialinstitutionstreetname)
                                {
                                    NamespacePrefix = 'cbc';
                                    XmlName = 'StreetName';
                                }
                                textelement(AdditionalStreetName)
                                {
                                    NamespacePrefix = 'cbc';
                                }
                                textelement(financialinstitutioncityname)
                                {
                                    NamespacePrefix = 'cbc';
                                    XmlName = 'CityName';
                                }
                                textelement(financialinstitutionpostalzone)
                                {
                                    NamespacePrefix = 'cbc';
                                    XmlName = 'PostalZone';
                                }
                                textelement(financialinstcountrysubentity)
                                {
                                    NamespacePrefix = 'cbc';
                                    XmlName = 'CountrySubentity';
                                }
                                textelement(financialinstitutioncountry)
                                {
                                    NamespacePrefix = 'cac';
                                    XmlName = 'Country';
                                    textelement(financialinstcountryidcode)
                                    {
                                        NamespacePrefix = 'cbc';
                                        XmlName = 'IdentificationCode';
                                        textattribute(financialinstcountrylistid)
                                        {
                                            XmlName = 'listID';
                                        }
                                    }
                                }

                                trigger OnBeforePassVariable()
                                begin
                                    if FinancialInstCountryIdCode = '' then
                                        currXMLport.Skip();
                                end;
                            }
                        }
                    }
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetPaymentMeansInfo(
                      SalesHeader,
                      PaymentMeansCode,
                      PaymentMeansListID,
                      PaymentDueDate,
                      PaymentChannelCode,
                      PaymentID,
                      PrimaryAccountNumberID,
                      NetworkID);

                    PEPPOLMgt.GetPaymentMeansPayeeFinancialAcc(
                      PayeeFinancialAccountID,
                      PaymentMeansSchemeID,
                      FinancialInstitutionBranchID,
                      FinancialInstitutionID,
                      FinancialInstitutionSchemeID,
                      FinancialInstitutionName);

                    PEPPOLMgt.GetPaymentMeansFinancialInstitutionAddr(
                      FinancialInstitutionStreetName,
                      AdditionalStreetName,
                      FinancialInstitutionCityName,
                      FinancialInstitutionPostalZone,
                      FinancialInstCountrySubentity,
                      FinancialInstCountryIdCode,
                      FinancialInstCountryListID);
                end;
            }
            tableelement(pmttermsloop; Integer)
            {
                NamespacePrefix = 'cac';
                XmlName = 'PaymentTerms';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(paymenttermsnote)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'Note';
                }

                trigger OnAfterGetRecord()
                begin
                    PEPPOLMgt.GetPaymentTermsInfo(
                      SalesHeader,
                      PaymentTermsNote);
                end;

                trigger OnPreXmlItem()
                begin
                    PmtTermsLoop.SetRange(Number, 1, 1);
                end;
            }
            tableelement(allowancechargeloop; Integer)
            {
                NamespacePrefix = 'cac';
                XmlName = 'AllowanceCharge';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(ChargeIndicator)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(AllowanceChargeReasonCode)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(allowancechargelistid)
                    {
                        XmlName = 'listID';
                    }
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
                        textattribute(taxcategoryschemeid)
                        {
                            XmlName = 'schemeID';
                        }
                    }
                    textelement(Percent)
                    {
                        NamespacePrefix = 'cbc';
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
                begin
                    if not FindNextVATAmtRec(TempVATAmtLine, AllowanceChargeLoop.Number) then
                        currXMLport.Break();

                    PEPPOLMgt.GetAllowanceChargeInfo(
                      TempVATAmtLine,
                      SalesHeader,
                      ChargeIndicator,
                      AllowanceChargeReasonCode,
                      AllowanceChargeListID,
                      AllowanceChargeReason,
                      Amount,
                      AllowanceChargeCurrencyID,
                      TaxCategoryID,
                      TaxCategorySchemeID,
                      Percent,
                      AllowanceChargeTaxSchemeID);

                    if ChargeIndicator = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(TaxExchangeRate)
            {
                NamespacePrefix = 'cac';
                textelement(SourceCurrencyCode)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(sourcecurrencycodelistid)
                    {
                        XmlName = 'listID';
                    }
                }
                textelement(TargetCurrencyCode)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(targetcurrencycodelistid)
                    {
                        XmlName = 'listID';
                    }
                }
                textelement(CalculationRate)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(MathematicOperatorCode)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(Date)
                {
                    NamespacePrefix = 'cbc';
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetTaxExchangeRateInfo(
                      SalesHeader,
                      SourceCurrencyCode,
                      SourceCurrencyCodeListID,
                      TargetCurrencyCode,
                      TargetCurrencyCodeListID,
                      CalculationRate,
                      MathematicOperatorCode,
                      Date);

                    if (SourceCurrencyCode = '') and (TargetCurrencyCode = '') then
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
                    XmlName = 'TaxSubtotal';
                    SourceTableView = sorting(Number) where(Number = filter(1 ..));
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
                    textelement(TransactionCurrencyTaxAmount)
                    {
                        NamespacePrefix = 'cbc';
                        textattribute(transcurrtaxamtcurrencyid)
                        {
                            XmlName = 'currencyID';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if TransactionCurrencyTaxAmount = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(subtotaltaxcategory)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'TaxCategory';
                        textelement(taxtotaltaxcategoryid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(schemeID)
                            {
                            }
                        }
                        textelement(taxcategorypercent)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Percent';
                        }
                        textelement(TaxExemptionReason)
                        {
                            NamespacePrefix = 'cbc';
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
                    begin
                        if not FindNextVATAmtRec(TempVATAmtLine, TaxSubtotalLoop.Number) then
                            currXMLport.Break();

                        PEPPOLMgt.GetTaxSubtotalInfo(
                          TempVATAmtLine,
                          SalesHeader,
                          TaxableAmount,
                          TaxAmountCurrencyID,
                          SubtotalTaxAmount,
                          TaxSubtotalCurrencyID,
                          TransactionCurrencyTaxAmount,
                          TransCurrTaxAmtCurrencyID,
                          TaxTotalTaxCategoryID,
                          schemeID,
                          TaxCategoryPercent,
                          TaxTotalTaxSchemeID);
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetTaxTotalInfo(
                      SalesHeader,
                      TempVATAmtLine,
                      TaxAmount,
                      TaxTotalCurrencyID);
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
                begin
                    PEPPOLMgt.GetLegalMonetaryInfo(
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
                XmlName = 'InvoiceLine';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
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
                    textattribute(unitCodeListID)
                    {

                        trigger OnBeforePassVariable()
                        begin
                            unitCodeListID := DefaultUnitCostListID;
                        end;
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
                    begin
                        PEPPOLMgt.GetLineInvoicePeriodInfo(
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
                                    textattribute(invlinedeliverycountrylistid)
                                    {
                                        XmlName = 'listID';
                                    }
                                }
                            }
                        }
                    }

                    trigger OnBeforePassVariable()
                    begin
                        PEPPOLMgt.GetLineDeliveryInfo(
                          InvoiceLineActualDeliveryDate,
                          InvoiceLineDeliveryID,
                          InvoiceLineDeliveryIDSchemeID);

                        PEPPOLMgt.GetLineDeliveryPostalAddr(
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
                    XmlName = 'AllowanceCharge';
                    SourceTableView = sorting(Number) where(Number = filter(1 ..));
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
                    begin
                        PEPPOLMgt.GetLineAllowanceChargeInfo(
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
                textelement(invoicelinetaxtotal)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'TaxTotal';
                    textelement(invoicelinetaxamount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'TaxAmount';
                        textattribute(currencyID)
                        {
                        }
                    }

                    trigger OnBeforePassVariable()
                    begin
                        PEPPOLMgt.GetLineTaxTotal(
                          SalesLine,
                          SalesHeader,
                          InvoiceLineTaxAmount,
                          currencyID);
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
                        XmlName = 'CommodityClassification';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
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
                        begin
                            PEPPOLMgt.GetLineItemCommodityClassficationInfo(
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
                            textattribute(itemschemeid)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        textelement(invoicelinetaxpercent)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Percent';
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
                        begin
                            PEPPOLMgt.GetLineItemClassfiedTaxCategory(
                              SalesLine,
                              ClassifiedTaxCategoryID,
                              ItemSchemeID,
                              InvoiceLineTaxPercent,
                              ClassifiedTaxCategorySchemeID);
                        end;
                    }
                    tableelement(additionalitempropertyloop; Integer)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'AdditionalItemProperty';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
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
                        begin
                            PEPPOLMgt.GetLineAdditionalItemPropertyInfo(
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
                    begin
                        PEPPOLMgt.GetLineItemInfo(
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
                        textattribute(codelistidbaseqty)
                        {
                            XmlName = 'unitCodeListID';

                            trigger OnBeforePassVariable()
                            begin
                                CodeListIDBaseQty := DefaultUnitCostListID;
                            end;
                        }
                    }
                    tableelement(priceallowancechargeloop; Integer)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'AllowanceCharge';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
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
                        begin
                            PEPPOLMgt.GetLinePriceAllowanceChargeInfo(
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
                    begin
                        PEPPOLMgt.GetLinePriceInfo(
                          SalesLine,
                          SalesHeader,
                          InvoiceLinePriceAmount,
                          InvLinePriceAmountCurrencyID,
                          BaseQuantity,
                          UnitCodeBaseQty);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not FindNextInvoiceLineRec(InvoiceLineLoop.Number) then
                        currXMLport.Break();

                    PEPPOLMgt.GetLineGeneralInfo(
                      SalesLine,
                      SalesHeader,
                      InvoiceLineID,
                      InvoiceLineNote,
                      InvoicedQuantity,
                      InvoiceLineExtensionAmount,
                      LineExtensionAmountCurrencyID,
                      InvoiceLineAccountingCost);

                    PEPPOLMgt.GetLineUnitCodeInfo(SalesLine, unitCode, DefaultUnitCostListID);
                end;
            }

            trigger OnAfterGetRecord()
            var
                TaxCurrencyCode: Text;
                TaxCurrencyCodeListID: Text;
            begin
                if not FindNextInvoiceRec(InvoiceHeaderLoop.Number) then
                    currXMLport.Break();

                GetTotals();

                PEPPOLMgt.GetGeneralInfo(
                  SalesHeader,
                  ID,
                  IssueDate,
                  InvoiceTypeCode,
                  InvoiceTypeCodeListID,
                  Note,
                  TaxPointDate,
                  DocumentCurrencyCode,
                  DocumentCurrencyCodeListID,
                  TaxCurrencyCode,
                  TaxCurrencyCodeListID,
                  AccountingCost);

                UBLVersionID := GetUBLVersionID();
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
                    }
                }
            }
        }

        actions
        {
        }
    }

    var
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLineRounding: Record "Sales Line" temporary;
        PEPPOLMgt: Codeunit "PEPPOL Management";
        SourceRecRef: RecordRef;

        SpecifyASalesInvoiceNoErr: Label 'You must specify a sales invoice number.';
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';
        ProcessedDocType: Enum "PEPPOL Processing Type";
        DefaultUnitCostListID: Text;

    procedure GetTotals()
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                begin
                    SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(SalesInvoiceLine);
                            SalesLine."Amount Including VAT" +=
                              Round(SalesInvoiceLine."Pmt. Discount Amount" * SalesInvoiceLine."VAT %" / 100);
                            PEPPOLMgt.GetTotals(SalesLine, TempVATAmtLine);
                        until SalesInvoiceLine.Next() = 0;
                end;
            else
                OnGetTotals(SourceRecRef, SalesLine, TempVATAmtLine, ProcessedDocType);
        end;
    end;

    local procedure FindNextInvoiceRec(Position: Integer) Found: Boolean
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                exit(PEPPOLMgt.FindNextSalesInvoiceRec(SalesInvoiceHeader, SalesHeader, Position));
            else
                OnFindNextInvoiceRec(Position, SalesHeader, Found);
        end;
    end;

    local procedure FindNextInvoiceLineRec(Position: Integer) Found: Boolean
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                exit(PEPPOLMgt.FindNextSalesInvoiceLineRec(SalesInvoiceLine, SalesLine, Position));
            else
                OnFindNextInvoiceLineRec(Position, SalesLine, Found);
        end;
    end;

    local procedure FindNextVATAmtRec(var VATAmtLine: Record "VAT Amount Line"; Position: Integer): Boolean
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
            DATABASE::"Sales Invoice Header":
                begin
                    SourceRecRef.SetTable(SalesInvoiceHeader);
                    if SalesInvoiceHeader."No." = '' then
                        Error(SpecifyASalesInvoiceNoErr);
                    SalesInvoiceHeader.SetRecFilter();
                    SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");

                    ProcessedDocType := ProcessedDocType::Sale;
                end;
            else begin
                IsHandled := false;
                OnInitialize(SourceRecRef, ProcessedDocType, IsHandled);
                if not IsHandled then
                    Error(UnSupportedTableTypeErr, SourceRecRef.Number);
            end;
        end;
    end;

    local procedure GetUBLVersionID(): Text
    begin
        exit('2.1')
    end;

    local procedure GetCustomizationID(): Text
    begin
        exit('urn:www.cenbii.eu:transaction:biitrns010:ver2.0:extended:urn:www.peppol.eu:bis:peppol4a:ver2.0')
    end;

    local procedure GetProfileID(): Text
    begin
        exit('urn:www.cenbii.eu:profile:bii04:ver2.0');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTotals(SourceRecRef: RecordRef; var SalesLine: Record "Sales Line"; var TempVATAmtLine: Record "VAT Amount Line" temporary; ProcessedDocType: Enum "PEPPOL Processing Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitialize(SourceRecRef: RecordRef; var ProcessedDocType: Enum "PEPPOL Processing Type"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindNextInvoiceRec(Position: Integer; var SalesHeader: Record "Sales Header"; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindNextInvoiceLineRec(Position: Integer; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
    end;
}
#endif
