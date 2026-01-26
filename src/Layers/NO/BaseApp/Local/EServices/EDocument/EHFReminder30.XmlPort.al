// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Peppol;
using Microsoft.Sales.Reminder;
using System.Utilities;

xmlport 10601 "EHF Reminder 3.0"
{
    Direction = Export;
    Encoding = UTF8;
    Namespaces = "" = 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', cac = 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', cbc = 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', ccts = 'urn:un:unece:uncefact:documentation:2', qdt = 'urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2', udt = 'urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2';

    schema
    {
        tableelement(reminderheaderloop; Integer)
        {
            MaxOccurs = Once;
            XmlName = 'Invoice';
            SourceTableView = sorting(Number) where(Number = filter(1));
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
                    DueDate := Format(TempSalesHeader."Due Date", 0, 9);
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
                    BuyerReference := TempSalesHeader."Your Reference";
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
            textelement(BillingReference)
            {
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

                    trigger OnBeforePassVariable()
                    begin
                        if InvoiceDocRefID = '' then
                            currXMLport.Skip();
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetBillingReferenceInfo(TempSalesLine, InvoiceDocRefID);
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
                    textelement(partytaxschemeno)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyTaxScheme';
                        textelement(companyidno)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CompanyID';
                            textattribute(companyidschemeidno)
                            {
                                XmlName = 'schemeID';

                                trigger OnBeforePassVariable()
                                begin
                                    if CompanyIDSchemeID = '' then
                                        currXMLport.Skip();
                                end;
                            }
                        }
                        textelement(exemptionreasonno)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ExemptionReason';

                            trigger OnBeforePassVariable()
                            begin
                                if ExemptionReason = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(suppliertaxschemeno)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(taxschemeidno)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'ID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if CompanyIDNO = '' then
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
                      TempSalesHeader,
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

                    PEPPOLMgt.GetAccountingSupplierPartyTaxSchemeNO(
                      CompanyIDNO,
                      CompanyIDSchemeIDNO,
                      TaxSchemeIDNO);

                    PEPPOLMgt.GetAccountingSupplierPartyLegalEntityBIS(
                      PartyLegalEntityRegName,
                      PartyLegalEntityCompanyID,
                      PartyLegalEntitySchemeID,
                      SupplierRegAddrCityName,
                      SupplierRegAddrCountryIdCode,
                      SupplRegAddrCountryIdListId);

                    PEPPOLMgt.GetAccountingSupplierPartyContact(
                      TempSalesHeader,
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
                                    if schemeID = '' then
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
                begin
                    PEPPOLMgt.GetAccountingCustomerPartyInfoBIS(
                      TempSalesHeader,
                      CustomerEndpointID,
                      CustomerSchemeID,
                      CustomerPartyIdentificationID,
                      CustomerPartyIDSchemeID,
                      CustomerName);

                    PEPPOLMgt.GetAccountingCustomerPartyPostalAddr(
                      TempSalesHeader,
                      CustomerStreetName,
                      CustomerAdditionalStreetName,
                      CustomerCityName,
                      CustomerPostalZone,
                      CustomerCountrySubentity,
                      CustomerIdentificationCode,
                      DummyVar);

                    PEPPOLMgt.GetAccountingCustomerPartyTaxSchemeBIS(
                      TempSalesHeader,
                      CustPartyTaxSchemeCompanyID,
                      CustPartyTaxSchemeCompIDSchID,
                      CustTaxSchemeID);

                    PEPPOLMgt.GetAccountingCustomerPartyLegalEntityBIS(
                      TempSalesHeader,
                      CustPartyLegalEntityRegName,
                      CustPartyLegalEntityCompanyID,
                      CustPartyLegalEntityIDSchemeID);

                    PEPPOLMgt.GetAccountingCustomerPartyContact(
                      TempSalesHeader,
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
                    PEPPOLMgt.GetPaymentMeansInfoReminder(
                      TempSalesHeader,
                      PaymentMeansCode,
                      PaymentChannelCode,
                      PaymentID,
                      PrimaryAccountNumberID,
                      NetworkID);

                    PEPPOLMgt.GetPaymentMeansPayeeFinancialAcc(
                      PayeeFinancialAccountID,
                      DummyVar,
                      FinancialInstitutionBranchID,
                      DummyVar,
                      DummyVar,
                      DummyVar);
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
                      TempSalesHeader,
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

                    trigger OnBeforePassVariable()
                    begin
                        if AllowanceChargeReasonCode = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(AllowanceChargeReason)
                {
                    NamespacePrefix = 'cbc';

                    trigger OnBeforePassVariable()
                    begin
                        if AllowanceChargeReason = '' then
                            currXMLport.Skip();
                    end;
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

                    PEPPOLMgt.GetAllowanceChargeInfoReminder(
                      TempVATAmtLine,
                      TempSalesHeader,
                      ChargeIndicator,
                      AllowanceChargeReasonCode,
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
                          TempSalesHeader,
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

                        PEPPOLMgt.GetTaxExemptionReason(TempVATProductPostingGroup, TaxExemptionReason, TaxTotalTaxCategoryID);
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    PEPPOLMgt.GetTaxTotalInfo(
                      TempSalesHeader,
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
                      TempSalesHeader,
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

                    ChargeTotalAmount := LineExtensionAmount;
                    ChargeTotalAmountCurrencyID := LegalMonetaryTotalCurrencyID;
                    LineExtensionAmount := '0';
                end;
            }
            tableelement(reminderlineloop; Integer)
            {
                NamespacePrefix = 'cac';
                XmlName = 'InvoiceLine';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(reminderlineid)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }
                textelement(reminderlinenote)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'Note';

                    trigger OnBeforePassVariable()
                    begin
                        ReminderLineNote := TempSalesLine."Description 2";
                        if ReminderLineNote = '' then
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
                        InvLineDeliveryCountryListID: Text;
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
                          TempSalesLine,
                          TempSalesHeader,
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
                    textelement(Name)
                    {
                        NamespacePrefix = 'cbc';
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
                        begin
                            PEPPOLMgt.GetLineItemClassfiedTaxCategoryBIS(
                              TempSalesLine,
                              ClassifiedTaxCategoryID,
                              ItemSchemeID,
                              InvoiceLineTaxPercent,
                              ClassifiedTaxCategorySchemeID);
                        end;
                    }

                    trigger OnBeforePassVariable()
                    var
                        Description: Text;
                        SellersItemIdentificationID: Text;
                        StandardItemIdentificationID: Text;
                        StdItemIdIDSchemeID: Text;
                        OriginCountryIdCode: Text;
                        OriginCountryIdCodeListID: Text;
                    begin
                        PEPPOLMgt.GetLineItemInfo(
                          TempSalesLine,
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
                          TempSalesLine,
                          TempSalesHeader,
                          InvoiceLinePriceAmount,
                          InvLinePriceAmountCurrencyID,
                          BaseQuantity,
                          UnitCodeBaseQty);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if ReminderLineLoop.Number = 1 then
                        TempSalesLine.FindFirst()
                    else
                        if TempSalesLine.Next() = 0 then
                            currXMLport.Break();

                    PEPPOLMgt.GetLineGeneralInfo(
                      TempSalesLine,
                      TempSalesHeader,
                      ReminderLineID,
                      ReminderLineNote,
                      InvoicedQuantity,
                      InvoiceLineExtensionAmount,
                      LineExtensionAmountCurrencyID,
                      InvoiceLineAccountingCost);

                    PEPPOLMgt.GetLineUnitCodeInfo(TempSalesLine, unitCode, DefaultUnitCostListID);
                end;
            }

            trigger OnAfterGetRecord()
            var
                TaxCurrencyCode: Text;
                TaxCurrencyCodeListID: Text;
            begin
                if not TempSalesHeader.FindFirst() then
                    currXMLport.Break();

                GetTotals();

                PEPPOLMgt.GetGeneralInfo(
                  TempSalesHeader,
                  ID,
                  IssueDate,
                  DummyVar,
                  DummyVar,
                  Note,
                  TaxPointDate,
                  DocumentCurrencyCode,
                  DummyVar,
                  TaxCurrencyCode,
                  TaxCurrencyCodeListID,
                  AccountingCost);

                CustomizationID := CustomizationIDTxt;
                ProfileID := ProfileIDTxt;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
            }
        }

        actions
        {
        }
    }

    var
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary;
        TempSalesLineRounding: Record "Sales Line" temporary;
        PEPPOLMgt: Codeunit "PEPPOL Management";
        DummyVar: Text;
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';
        DefaultUnitCostListID: Text;
        CustomizationIDTxt: Label 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0#conformant#urn:fdc:anskaffelser.no:2019:ehf:reminder:3.0', Comment = 'Locked';
        ProfileIDTxt: Label 'urn:fdc:anskaffelser.no:2019:ehf:postaward:g3:06:1.0', Locked = true;

    local procedure GetTotals()
    begin
        if TempSalesLine.FindSet() then
            repeat
                PEPPOLMgt.GetTotals(TempSalesLine, TempVATAmtLine);
                PEPPOLMgt.GetTaxCategories(TempSalesLine, TempVATProductPostingGroup);
            until TempSalesLine.Next() = 0;
    end;

    local procedure FindNextVATAmtRec(var VATAmtLine: Record "VAT Amount Line"; Position: Integer): Boolean
    begin
        if Position = 1 then
            exit(VATAmtLine.FindFirst());
        exit(VATAmtLine.Next() <> 0);
    end;

    procedure Initialize(DocVariant: Variant)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DocVariant);
        case RecRef.Number() of
            DATABASE::"Issued Reminder Header":
                begin
                    RecRef.SetTable(IssuedReminderHeader);
                    PEPPOLMgt.CopyIssuedReminder(TempSalesHeader, TempSalesLine, TempSalesLineRounding, IssuedReminderHeader."No.");
                end;
            DATABASE::"Issued Fin. Charge Memo Header":
                begin
                    RecRef.SetTable(IssuedFinChargeMemoHeader);
                    PEPPOLMgt.CopyIssuedFinCharge(TempSalesHeader, TempSalesLine, TempSalesLineRounding, IssuedFinChargeMemoHeader."No.");
                end;
            else
                Error(UnSupportedTableTypeErr, RecRef.Number());
        end;
    end;
}

