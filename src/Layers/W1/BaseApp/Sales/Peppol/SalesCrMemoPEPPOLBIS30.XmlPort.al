// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Sales.Peppol;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;
using Microsoft.Foundation.Attachment;

xmlport 1611 "Sales Cr.Memo - PEPPOL BIS 3.0"
{
    Caption = 'Sales Cr.Memo - PEPPOL BIS 3.0';
    Direction = Export;
    Encoding = UTF8;
    Namespaces = "" = 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2', cac = 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', cbc = 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', ccts = 'urn:un:unece:uncefact:documentation:2', qdt = 'urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2', udt = 'urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2';

    schema
    {
        tableelement(crmemoheaderloop; Integer)
        {
            MaxOccurs = Once;
            XmlName = 'CreditNote';
            SourceTableView = sorting(Number) where(Number = filter(1 ..));
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
            textelement(CreditNoteTypeCode)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    CreditNoteTypeCode := '381';
                end;
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
                begin
                    PEPPOLMgt.GetTaxTotalInfoLCY(SalesHeader, TaxAmountLCY, TaxCurrencyCodeLCY, TaxTotalCurrencyIDLCY);
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
                begin
                    BuyerReference := PEPPOLMgt.GetBuyerReference(SalesHeader);
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
            textelement(BillingReference)
            {
                MinOccurs = Zero;
                NamespacePrefix = 'cac';
                textelement(InvoiceDocumentReference)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    NamespacePrefix = 'cac';
                    textelement(invoicedocrefid)
                    {
                        MaxOccurs = Once;
                        NamespacePrefix = 'cbc';
                        XmlName = 'ID';
                    }
                    textelement(invoicedocrefissuedate)
                    {
                        MaxOccurs = Once;
                        MinOccurs = Zero;
                        NamespacePrefix = 'cbc';
                        XmlName = 'IssueDate';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if InvoiceDocRefID = '' then
                            currXMLport.Skip();
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetCrMemoBillingReferenceInfo(
                      SalesCrMemoHeader,
                      InvoiceDocRefID,
                      InvoiceDocRefIssueDate);

                    if InvoiceDocRefID = '' then
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

                    trigger OnBeforePassVariable()
                    begin
                        if DocumentType = '' then
                            currXMLport.Skip();
                    end;
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
                begin
                    if (AdditionalDocRefLoop.Number <= DocumentAttachments.Count()) then
                        PEPPOLMgt.GetAdditionalDocRefInfo(
                           additionaldocrefloop.Number,
                           DocumentAttachments,
                           SalesHeader,
                           AdditionalDocumentReferenceID,
                           AdditionalDocRefDocumentType,
                           URI,
                           filename,
                           mimeCode,
                           EmbeddedDocumentBinaryObject,
                           ProcessedDocType.AsInteger())
                    else
                        if GeneratePDF then
                            PEPPOLMgt.GeneratePDFAttachmentAsAdditionalDocRef(
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

                                trigger OnBeforePassVariable()
                                begin
                                    if SupplierPartyIDSchemeID = '' then
                                        currXMLport.Skip();
                                end;
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            PEPPOLMgt.GetAccountingSupplierPartyIdentificationID(SalesHeader, PartyIdentificationID);
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
                begin
                    PEPPOLMgt.GetAccountingSupplierPartyInfoBIS(
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
                      DummyVar);

                    PEPPOLMgt.GetAccountingSupplierPartyTaxSchemeBIS(
                      TempVATAmtLine,
                      CompanyID,
                      CompanyIDSchemeID,
                      TaxSchemeID);

                    PEPPOLMgt.GetAccountingSupplierPartyLegalEntityBIS(
                      PartyLegalEntityRegName,
                      PartyLegalEntityCompanyID,
                      PartyLegalEntitySchemeID,
                      SupplierRegAddrCityName,
                      SupplierRegAddrCountryIdCode,
                      SupplRegAddrCountryIdListId);

                    PEPPOLMgt.GetAccountingSupplierPartyContact(
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

                            trigger OnBeforePassVariable()
                            begin
                                if CustContactName = '' then
                                    currXMLport.Skip();
                            end;
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
                    }
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetAccountingCustomerPartyInfoBIS(
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
                      DummyVar);

                    PEPPOLMgt.GetAccountingCustomerPartyTaxSchemeBIS(
                      SalesHeader,
                      CustPartyTaxSchemeCompanyID,
                      CustPartyTaxSchemeCompIDSchID,
                      CustTaxSchemeID);

                    PEPPOLMgt.GetAccountingCustomerPartyLegalEntityBIS(
                      SalesHeader,
                      CustPartyLegalEntityRegName,
                      CustPartyLegalEntityCompanyID,
                      CustPartyLegalEntityIDSchemeID);

                    PEPPOLMgt.GetAccountingCustomerPartyContact(
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
                      DummyVar);

                    PEPPOLMgt.GetDeliveryPartyName(SalesHeader, DeliveryPartyNameValue);
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
                begin
                    PEPPOLMgt.GetPaymentMeansInfo(
                      SalesHeader,
                      PaymentMeansCode,
                      DummyVar,
                      DummyVar,
                      PaymentChannelCode,
                      PaymentID,
                      PrimaryAccountNumberID,
                      NetworkID);

                    PEPPOLMgt.GetPaymentMeansPayeeFinancialAccBIS(
                        SalesHeader,
                        PayeeFinancialAccountID,
                        FinancialInstitutionBranchID);
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
                XmlName = 'AllowanceCharge';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
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
                begin
                    if not FindNextVATAmtRec(TempVATAmtLine, AllowanceChargeLoop.Number) then
                        currXMLport.Break();

                    PEPPOLMgt.GetAllowanceChargeInfo(
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
                          DummyVar,
                          TaxCategoryPercent,
                          TaxTotalTaxSchemeID);

                        PEPPOLMgt.GetTaxExemptionReason(TempVATProductPostingGroup, TaxExemptionReason, TaxTotalTaxCategoryID);
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
            tableelement(creditmemolineloop; Integer)
            {
                NamespacePrefix = 'cac';
                XmlName = 'CreditNoteLine';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(salescrmemolineid)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }
                textelement(salescrmemolinenote)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'Note';

                    trigger OnBeforePassVariable()
                    begin
                        if SalesCrMemoLineNote = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(CreditedQuantity)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(unitCode)
                    {
                    }
                }
                textelement(salescrmemolineextensionamount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'LineExtensionAmount';
                    textattribute(lineextensionamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(salescrmemolineaccountingcost)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'AccountingCost';

                    trigger OnBeforePassVariable()
                    begin
                        if SalesCrMemoLineAccountingCost = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(salescrmemolineinvoiceperiod)
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

                    trigger OnBeforePassVariable()
                    begin
                        if OrderLineReferenceLineID = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(salescrmemolnbillingreference)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'BillingReference';
                    textelement(crmelninvoicedocumentreference)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'InvoiceDocumentReference';
                        textelement(crmemolninvdocrefid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                    }
                    textelement(crcreditnotedocumentreference)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'CreditNoteDocumentReference';
                        textelement(crmemolncreditnotedocrefid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                    }
                    textelement("crmemolnbillingreferenceline>")
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'BillingReferenceLine';
                        textelement(salescrmemolnbillingreflineid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if SalesCrMemoLnBillingRefLineID = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(salescrmemolinedelivery)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Delivery';
                    textelement(crmemolineactualdeliverydate)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ActualDeliveryDate';
                    }
                    textelement(crmemolinedeliverylocation)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'DeliveryLocation';
                        textelement(salescrmemolinedeliveryid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(crmemolinedeliveryidschemeid)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        textelement(crmemolinedeliveryaddress)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'Address';
                            textelement(crmemolinedeliverystreetname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'StreetName';
                            }
                            textelement(crmemlinedeliveryaddstreetname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'AdditionalStreetName';
                            }
                            textelement(crmemolinedeliverycityname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'CityName';
                            }
                            textelement(crmemolinedeliverypostalzone)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'PostalZone';
                            }
                            textelement(crmelndeliverycountrysubentity)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'CountrySubentity';
                            }
                            textelement(creditmemolinedeliverycountry)
                            {
                                NamespacePrefix = 'cac';
                                XmlName = 'Country';
                                textelement(crmemlndeliverycountryidcode)
                                {
                                    NamespacePrefix = 'cbc';
                                    XmlName = 'IdentificationCode';
                                }
                            }
                        }
                    }

                    trigger OnBeforePassVariable()
                    begin
                        PEPPOLMgt.GetLineDeliveryInfo(
                          CrMemoLineActualDeliveryDate,
                          SalesCrMemoLineDeliveryID,
                          CrMemoLineDeliveryIDSchemeID);

                        PEPPOLMgt.GetLineDeliveryPostalAddr(
                          CrMemoLineDeliveryStreetName,
                          CrMemLineDeliveryAddStreetName,
                          CrMemoLineDeliveryCityName,
                          CrMemoLineDeliveryPostalZone,
                          CrMeLnDeliveryCountrySubentity,
                          CreditMemoLineDeliveryCountry,
                          CrMemLnDeliveryCountryIdCode);

                        if (SalesCrMemoLineDeliveryID = '') and
                           (CrMemoLineDeliveryStreetName = '') and
                           (CrMemoLineActualDeliveryDate = '')
                        then
                            currXMLport.Skip();
                    end;
                }
                tableelement(crmemlnallowancechargeloop; Integer)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'AllowanceCharge';
                    SourceTableView = sorting(Number) where(Number = filter(1 ..));
                    textelement(crmelnallowancechargeindicator)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ChargeIndicator';
                    }
                    textelement(crmemlnallowancechargereason)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'AllowanceChargeReason';
                    }
                    textelement(crmemlnallowancechargeamount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'Amount';
                        textattribute(crmelnallowancechargeamtcurrid)
                        {
                            XmlName = 'currencyID';
                        }
                    }

                    trigger OnAfterGetRecord()
                    begin
                        PEPPOLMgt.GetLineAllowanceChargeInfo(
                          SalesLine,
                          SalesHeader,
                          CrMeLnAllowanceChargeIndicator,
                          CrMemLnAllowanceChargeReason,
                          CrMemLnAllowanceChargeAmount,
                          CrMeLnAllowanceChargeAmtCurrID);

                        if CrMeLnAllowanceChargeIndicator = '' then
                            currXMLport.Skip();
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CrMemLnAllowanceChargeLoop.SetRange(Number, 1, 1);
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
                        }
                        textelement(salescreditmemolinetaxpercent)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Percent';

                            trigger OnBeforePassVariable()
                            begin
                                if SalesCreditMemoLineTaxPercent = '' then
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
                        begin
                            PEPPOLMgt.GetLineItemClassfiedTaxCategoryBIS(
                              SalesLine,
                              ClassifiedTaxCategoryID,
                              DummyVar,
                              SalesCreditMemoLineTaxPercent,
                              ClassifiedTaxCategorySchemeID);

                            if ClassifiedTaxCategoryID = '' then
                                currXMLport.Skip();
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
                textelement(salescreditmemolineprice)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Price';
                    textelement(salescreditmemolinepriceamount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'PriceAmount';
                        textattribute(crmemlinepriceamountcurrencyid)
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
                          SalesCreditMemoLinePriceAmount,
                          CrMemLinePriceAmountCurrencyID,
                          BaseQuantity,
                          UnitCodeBaseQty);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not FindNextCreditMemoLineRec(CreditMemoLineLoop.Number) then
                        currXMLport.Break();

                    OnCreditMemoLineLoopOnAfterGetRecordOnBeforeGetLineGeneralInfo(SalesCrMemoLine, SalesLine);
                    PEPPOLMgt.GetLineGeneralInfo(
                      SalesLine,
                      SalesHeader,
                      SalesCrMemoLineID,
                      SalesCrMemoLineNote,
                      CreditedQuantity,
                      SalesCrMemoLineExtensionAmount,
                      LineExtensionAmountCurrencyID,
                      SalesCrMemoLineAccountingCost);
                    PEPPOLMgt.GetLineUnitCodeInfo(SalesLine, unitCode, DummyVar);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not FindNextCreditMemoRec(CrMemoHeaderLoop.Number) then
                    currXMLport.Break();

                GetTotals();

                PEPPOLMgt.GetGeneralInfoBIS(
                  SalesHeader,
                  ID,
                  IssueDate,
                  DummyVar,
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
                    field("SalesCrMemoHeader.""No."""; SalesCrMemoHeader."No.")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Credit Memo No.';
                        TableRelation = "Sales Cr.Memo Header";
                    }
                }
            }
        }

        actions
        {
        }
    }

    trigger OnPreXmlPort()
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");
    end;

    var
        GLSetup: Record "General Ledger Setup";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary;
        TempSalesLineRounding: Record "Sales Line" temporary;
        DocumentAttachments: Record "Document Attachment";
        PEPPOLMgt: Codeunit "PEPPOL Management";
        SourceRecRef: RecordRef;
        DummyVar: Text;

        SpecifyASalesCreditMemoNoErr: Label 'You must specify a sales credit memo number.';
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';
        ProcessedDocType: Enum "PEPPOL Processing Type";
        GeneratePDF: Boolean;

    local procedure GetTotals()
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                begin
                    SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(SalesCrMemoLine);
                            OnGetTotalsOnBeforeGetSalesLineTotals(SalesCrMemoLine, SalesLine);
                            PEPPOLMgt.GetTotals(SalesLine, TempVATAmtLine);
                            PEPPOLMgt.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until SalesCrMemoLine.Next() = 0;
                end;
            else
                OnGetTotals(SourceRecRef, SalesLine, TempVATAmtLine, TempVATProductPostingGroup, ProcessedDocType);
        end;
    end;

    local procedure FindNextCreditMemoRec(Position: Integer) Found: Boolean
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                exit(PEPPOLMgt.FindNextSalesCreditMemoRec(SalesCrMemoHeader, SalesHeader, Position));
            else
                OnFindNextCreditMemoRec(Position, SalesHeader, Found);
        end;
    end;

    local procedure FindNextCreditMemoLineRec(Position: Integer) Found: Boolean
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                exit(PEPPOLMgt.FindNextSalesCreditMemoLineRec(SalesCrMemoLine, SalesLine, Position));
            else
                OnFindNextCreditMemoLineRec(Position, SalesLine, Found);
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
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SourceRecRef.SetTable(SalesCrMemoHeader);
                    if SalesCrMemoHeader."No." = '' then
                        Error(SpecifyASalesCreditMemoNoErr);
                    SalesCrMemoHeader.SetRecFilter();
                    SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
                    SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");

                    OnBeforeFindSalesCrMemoLine(SalesCrMemoLine);
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(SalesCrMemoLine);
                            OnInitializeOnBeforeGetInvoiceRoundingLine(SalesCrMemoLine, SalesLine);
                            PEPPOLMgt.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
                        until SalesCrMemoLine.Next() = 0;
                    if TempSalesLineRounding."Line No." <> 0 then
                        SalesCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

                    DocumentAttachments.SetRange("Table ID", Database::"Sales Cr.Memo Header");
                    DocumentAttachments.SetRange("No.", SalesCrMemoHeader."No.");

                    ProcessedDocType := ProcessedDocType::Sale;
                end;
            else begin
                IsHandled := false;
                OnInitialize(SourceRecRef, TempSalesLineRounding, DocumentAttachments, ProcessedDocType, IsHandled);
                if not IsHandled then
                    Error(UnSupportedTableTypeErr, SourceRecRef.Number);
            end;
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
        exit('urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0');
    end;

    local procedure GetProfileID(): Text
    begin
        exit('urn:fdc:peppol.eu:2017:poacc:billing:01:1.0');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTotals(SourceRecRef: RecordRef; var SalesLine: Record "Sales Line"; var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary; ProcessedDocType: Enum "PEPPOL Processing Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitialize(SourceRecRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment"; var ProcessedDocType: Enum "PEPPOL Processing Type"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindNextCreditMemoRec(Position: Integer; var SalesHeader: Record "Sales Header"; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindNextCreditMemoLineRec(Position: Integer; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTotalsOnBeforeGetSalesLineTotals(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeOnBeforeGetInvoiceRoundingLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreditMemoLineLoopOnAfterGetRecordOnBeforeGetLineGeneralInfo(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesLine: Record "Sales Line")
    begin
    end;
}
