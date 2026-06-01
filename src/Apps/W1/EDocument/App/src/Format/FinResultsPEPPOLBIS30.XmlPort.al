namespace Microsoft.EServices.EDocument.IO.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Peppol;
using Microsoft.Sales.Reminder;
using System.Utilities;

xmlport 6100 "Fin. Results - PEPPOL BIS 3.0"
{

    Caption = 'Reminder PEPPOL BIS 3.0';
    Direction = Export;
    Encoding = UTF8;
    Namespaces = "" = 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', cac = 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', cbc = 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', ccts = 'urn:un:unece:uncefact:documentation:2', qdt = 'urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2', udt = 'urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2';

    schema
    {
        tableelement(HeaderLoop; Integer)
        {
            MaxOccurs = Once;
            XmlName = 'Invoice';
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
            textelement(DueDate)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    DueDate := Format(GlobalSalesHeader."Due Date", 0, 9);
                    if DueDate = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(InvoiceTypeCode)
            {
                NamespacePrefix = 'cbc';
            }
            textelement(DocumentCurrencyCode)
            {
                NamespacePrefix = 'cbc';
            }
            textelement(BuyerReference)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    BuyerReference := this.GlobalSalesHeader."Your Reference";
                    if BuyerReference = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(AccountingSupplierParty)
            {
                NamespacePrefix = 'cac';
                textelement(SupplierParty)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Party';
                    textelement(SupplierEndpointID)
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
                        textelement(PartyIdentificationID)
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
                            this.PEPPOLMgt.GetAccountingSupplierPartyIdentificationID(this.GlobalSalesHeader, PartyIdentificationID);
                            if PartyIdentificationID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(SupplierPartyName)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyName';
                        textelement(SupplierName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                    }
                    textelement(SupplierPostalAddress)
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
                        textelement(SupplierAdditionalStreetName)
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
                        textelement(SupplierTaxScheme)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(TaxSchemeID)
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
                        textelement(PartylLegalEntityRegName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'RegistrationName';

                            trigger OnBeforePassVariable()
                            begin
                                if PartylLegalEntityRegName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(PartyLegalEntityCompanyID)
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
                        textelement(ContactName)
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
                    this.PEPPOLMgt.GetAccountingSupplierPartyInfoBIS(
                      SupplierEndpointID,
                      SupplierSchemeID,
                      SupplierName);

                    this.PEPPOLMgt.GetAccountingSupplierPartyPostalAddr(
                      this.GlobalSalesHeader,
                      StreetName,
                      SupplierAdditionalStreetName,
                      CityName,
                      PostalZone,
                      CountrySubentity,
                      IdentificationCode,
                      this.DummyVar);

                    this.PEPPOLMgt.GetAccountingSupplierPartyTaxSchemeBIS(
                      this.TempVATAmtLine,
                      CompanyID,
                      CompanyIDSchemeID,
                      TaxSchemeID);

                    this.PEPPOLMgt.GetAccountingSupplierPartyLegalEntityBIS(
                      PartylLegalEntityRegName,
                      PartyLegalEntityCompanyID,
                      PartyLegalEntitySchemeID,
                      SupplierRegAddrCityName,
                      SupplierRegAddrCountryIdCode,
                      SupplRegAddrCountryIdListId);

                    this.PEPPOLMgt.GetAccountingSupplierPartyContact(
                      this.GlobalSalesHeader,
                      this.DummyVar,
                      ContactName,
                      Telephone,
                      Telefax,
                      ElectronicMail);
                end;
            }
            textelement(AccountingCustomerParty)
            {
                NamespacePrefix = 'cac';
                textelement(CustomerParty)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Party';
                    textelement(CustomerEndpointID)
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
                    textelement(CustomerPartyIdentification)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(CustomerPartyIdentificationID)
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
                    textelement(CustomerPartyName)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyName';
                        textelement(CustomerName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                    }
                    textelement(CustomerPostalAddress)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PostalAddress';
                        textelement(CustomerStreetName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'StreetName';
                        }
                        textelement(CustomerAdditionalStreetName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'AdditionalStreetName';

                            trigger OnBeforePassVariable()
                            begin
                                if CustomerAdditionalStreetName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(CustomerCityName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CityName';
                        }
                        textelement(CustomerPostalZone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'PostalZone';
                        }
                        textelement(CustomerCountrySubentity)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CountrySubentity';

                            trigger OnBeforePassVariable()
                            begin
                                if CustomerCountrySubentity = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(CustomerCountry)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'Country';
                            textelement(CustomerIdentificationCode)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'IdentificationCode';
                            }
                        }
                    }
                    textelement(CustomerPartyTaxScheme)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyTaxScheme';
                        textelement(CustPartyTaxSchemeCompanyID)
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
                        textelement(CustTaxScheme)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(CustTaxSchemeID)
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
                    textelement(CustPartyLegalEntity)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyLegalEntity';
                        textelement(CustPartyLegalEntityRegName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'RegistrationName';

                            trigger OnBeforePassVariable()
                            begin
                                if CustPartyLegalEntityRegName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(CustPartyLegalEntityCompanyID)
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
                    textelement(CustContact)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'Contact';
                        textelement(CustContactName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Name';
                        }
                        textelement(CustContactTelephone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Telephone';

                            trigger OnBeforePassVariable()
                            begin
                                if CustContactTelephone = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(CustContactTelefax)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Telefax';

                            trigger OnBeforePassVariable()
                            begin
                                if CustContactTelefax = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(CustContactElectronicMail)
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
                    this.PEPPOLMgt.GetAccountingCustomerPartyInfoBIS(
                      this.GlobalSalesHeader,
                      CustomerEndpointID,
                      CustomerSchemeID,
                      CustomerPartyIdentificationID,
                      CustomerPartyIDSchemeID,
                      CustomerName);

                    this.PEPPOLMgt.GetAccountingCustomerPartyPostalAddr(
                      this.GlobalSalesHeader,
                      CustomerStreetName,
                      CustomerAdditionalStreetName,
                      CustomerCityName,
                      CustomerPostalZone,
                      CustomerCountrySubentity,
                      CustomerIdentificationCode,
                      this.DummyVar);

                    this.PEPPOLMgt.GetAccountingCustomerPartyTaxSchemeBIS(
                      this.GlobalSalesHeader,
                      CustPartyTaxSchemeCompanyID,
                      CustPartyTaxSchemeCompIDSchID,
                      CustTaxSchemeID);

                    this.PEPPOLMgt.GetAccountingCustomerPartyLegalEntityBIS(
                      this.GlobalSalesHeader,
                      CustPartyLegalEntityRegName,
                      CustPartyLegalEntityCompanyID,
                      CustPartyLegalEntityIDSchemeID);

                    this.PEPPOLMgt.GetAccountingCustomerPartyContact(
                      this.GlobalSalesHeader,
                      this.DummyVar,
                      CustContactName,
                      CustContactTelephone,
                      CustContactTelefax,
                      CustContactElectronicMail);
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
                    textelement(PayeeFinancialAccountID)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ID';
                    }
                    textelement(FinancialInstitutionBranch)
                    {
                        NamespacePrefix = 'cac';
                        textelement(FinancialInstitutionBranchID)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                    }
                }

                trigger OnBeforePassVariable()
                begin
                    this.PEPPOLMgt.GetPaymentMeansInfo(
                      this.GlobalSalesHeader,
                      PaymentMeansCode,
                      this.DummyVar,
                      this.DummyVar,
                      PaymentChannelCode,
                      PaymentID,
                      PrimaryAccountNumberID,
                      NetworkID);

                    this.PEPPOLMgt.GetPaymentMeansPayeeFinancialAccBIS(
                        this.GlobalSalesHeader,
                        PayeeFinancialAccountID,
                        FinancialInstitutionBranchID);
                end;
            }
            tableelement(PmtTermsLoop; Integer)
            {
                NamespacePrefix = 'cac';
                XmlName = 'PaymentTerms';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(PaymentTermsNote)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'Note';
                }

                trigger OnAfterGetRecord()
                begin
                    this.PEPPOLMgt.GetPaymentTermsInfo(
                      this.GlobalSalesHeader,
                      PaymentTermsNote);

                    if PaymentTermsNote = '' then
                        currXMLport.Skip();
                end;

                trigger OnPreXmlItem()
                begin
                    PmtTermsLoop.SetRange(Number, 1, 1);
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
                tableelement(TaxSubtotalLoop; Integer)
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
                    textelement(SubtotalTaxAmount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'TaxAmount';
                        textattribute(taxamountcurrencyid)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    textelement(SubtotalTaxCategory)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'TaxCategory';
                        textelement(TaxTotalTaxCategoryID)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                        textelement(TaxCategoryPercent)
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
                        textelement(TaxSubtotalTaxScheme)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(TaxTotalTaxSchemeID)
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
                        if not this.FindNextVATAmtRec(this.TempVATAmtLine, TaxSubtotalLoop.Number) then
                            currXMLport.Break();

                        this.PEPPOLMgt.GetTaxSubtotalInfo(
                          this.TempVATAmtLine,
                          this.GlobalSalesHeader,
                          TaxableAmount,
                          TaxAmountCurrencyID,
                          SubtotalTaxAmount,
                          TaxSubtotalCurrencyID,
                          TransactionCurrencyTaxAmount,
                          TransCurrTaxAmtCurrencyID,
                          TaxTotalTaxCategoryID,
                          this.DummyVar,
                          TaxCategoryPercent,
                          TaxTotalTaxSchemeID);

                        this.PEPPOLMgt.GetTaxExemptionReason(this.TempVATProductPostingGroup, TaxExemptionReason, TaxTotalTaxCategoryID);
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    this.PEPPOLMgt.GetTaxTotalInfo(
                      this.GlobalSalesHeader,
                      this.TempVATAmtLine,
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
                    this.PEPPOLMgt.GetLegalMonetaryInfo(
                      this.GlobalSalesHeader,
                      this.TempSalesLineRounding,
                      this.TempVATAmtLine,
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
            tableelement(InvoiceLineLoop; Integer)
            {
                NamespacePrefix = 'cac';
                XmlName = 'InvoiceLine';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(InvoiceLineID)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }
                textelement(InvoicedQuantity)
                {
                    NamespacePrefix = 'cbc';
                    textattribute(unitCode)
                    {
                    }
                }
                textelement(InvoiceLineExtensionAmount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'LineExtensionAmount';
                    textattribute(LineExtensionAmountCurrencyID)
                    {
                        XmlName = 'currencyID';
                    }
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
                    textelement(ClassifiedTaxCategory)
                    {
                        NamespacePrefix = 'cac';
                        textelement(ClassifiedTaxCategoryID)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                        }
                        textelement(InvoiceLineTaxPercent)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Percent';

                            trigger OnBeforePassVariable()
                            begin
                                if InvoiceLineTaxPercent = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(ClassifiedTaxCategoryTaxScheme)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(ClassifiedTaxCategorySchemeID)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'ID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            this.PEPPOLMgt.GetLineItemClassfiedTaxCategoryBIS(
                              this.GlobalSalesLine,
                              ClassifiedTaxCategoryID,
                              this.DummyVar,
                              InvoiceLineTaxPercent,
                              ClassifiedTaxCategorySchemeID);
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        this.PEPPOLMgt.GetLineItemInfo(
                          this.GlobalSalesLine,
                          Description,
                          Name,
                          this.DummyVar,
                          this.DummyVar,
                          this.DummyVar,
                          this.DummyVar,
                          this.DummyVar);
                    end;
                }
                textelement(InvoiceLinePrice)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Price';
                    textelement(InvoiceLinePriceAmount)
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

                    trigger OnBeforePassVariable()
                    begin
                        this.PEPPOLMgt.GetLinePriceInfo(
                          this.GlobalSalesLine,
                          this.GlobalSalesHeader,
                          InvoiceLinePriceAmount,
                          InvLinePriceAmountCurrencyID,
                          BaseQuantity,
                          UnitCodeBaseQty);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if this.IsReminder then
                        if not this.FindNextReminderLineRec(InvoiceLineLoop.Number) then
                            currXMLport.Break();

                    if this.IsFinChargeMemo then
                        if not this.FindNextFinChargeMemoLineRec(InvoiceLineLoop.Number) then
                            currXMLport.Break();

                    this.PEPPOLMgt.GetLineGeneralInfo(
                      this.GlobalSalesLine,
                      this.GlobalSalesHeader,
                      InvoiceLineID,
                      this.DummyVar,
                      InvoicedQuantity,
                      InvoiceLineExtensionAmount,
                      LineExtensionAmountCurrencyID,
                      this.DummyVar);

                    this.PEPPOLMgt.GetLineUnitCodeInfo(this.GlobalSalesLine, unitCode, this.DummyVar);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if this.IsReminder then
                    if not this.FindNextIssuedReminderRec(this.GlobalIssuedReminderHeader, this.GlobalSalesHeader, HeaderLoop.Number) then
                        currXMLport.Break();

                if this.IsFinChargeMemo then
                    if not this.FindNextIssuedFinChargeMemoRec(this.GlobalIssuedFinChargeMemoHeader, this.GlobalSalesHeader, HeaderLoop.Number) then
                        currXMLport.Break();

                this.GetTotals();

                this.PEPPOLMgt.GetGeneralInfoBIS(
                  this.GlobalSalesHeader,
                  ID,
                  IssueDate,
                  InvoiceTypeCode,
                  this.DummyVar,
                  this.DummyVar,
                  DocumentCurrencyCode,
                  this.DummyVar);

                CustomizationID := this.GetCustomizationID();
                ProfileID := this.GetProfileID();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    ShowCaption = false;
#pragma warning disable AA0100
                    field("IssuedReminderHeader.""No."""; GlobalIssuedReminderHeader."No.")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Issued Reminder No.';
                        ToolTip = 'Specifies the issued reminder number to export.';
                        TableRelation = "Issued Reminder Header";
                    }
                }
            }
        }
    }

    var
#pragma warning disable AL0432
        TempVATAmtLine: Record "VAT Amount Line" temporary;
#pragma warning restore AL0432
        GlobalSalesHeader: Record "Sales Header";
        GlobalSalesLine: Record "Sales Line";
        TempSalesLineRounding: Record "Sales Line" temporary;
        GlobalIssuedReminderHeader: Record "Issued Reminder Header";
        GlobalIssuedReminderLine: Record "Issued Reminder Line";
        GlobalIssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        GlobalIssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary;
        PEPPOLMgt: Codeunit "PEPPOL Management";
        SourceRecRef: RecordRef;
        DummyVar: Text;
        IsReminder: Boolean;
        IsFinChargeMemo: Boolean;
        SpecifyAReminderNoErr: Label 'You must specify an issued reminder number.';
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';

    local procedure GetTotals()
    begin
        if this.IsReminder then begin
            this.GlobalIssuedReminderLine.SetRange("Reminder No.", this.GlobalIssuedReminderHeader."No.");
            if this.GlobalIssuedReminderLine.FindSet() then
                repeat
                    this.CopyReminderLineToSalesLine(this.GlobalSalesLine, this.GlobalIssuedReminderHeader, this.GlobalIssuedReminderLine);
                    this.PEPPOLMgt.GetTotals(this.GlobalSalesLine, this.TempVATAmtLine);
                    this.PEPPOLMgt.GetTaxCategories(this.GlobalSalesLine, this.TempVATProductPostingGroup);
                until this.GlobalIssuedReminderLine.Next() = 0;
        end;

        if this.IsFinChargeMemo then begin
            this.GlobalIssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", this.GlobalIssuedFinChargeMemoHeader."No.");
            if this.GlobalIssuedFinChargeMemoLine.FindSet() then
                repeat
                    this.CopyFinChargeMemoLineToSalesLine(this.GlobalSalesLine, this.GlobalIssuedFinChargeMemoHeader, this.GlobalIssuedFinChargeMemoLine);
                    this.PEPPOLMgt.GetTotals(this.GlobalSalesLine, this.TempVATAmtLine);
                    this.PEPPOLMgt.GetTaxCategories(this.GlobalSalesLine, this.TempVATProductPostingGroup);
                until this.GlobalIssuedFinChargeMemoLine.Next() = 0;
        end;
    end;

#pragma warning disable AL0432
    local procedure FindNextVATAmtRec(var TempVATAmountLine: Record "VAT Amount Line" temporary; Position: Integer): Boolean
    begin
        if Position = 1 then
            exit(TempVATAmountLine.FindSet());
        exit(TempVATAmountLine.Next() <> 0);
    end;
#pragma warning restore AL0432

    procedure Initialize(DocVariant: Variant)
    begin
        this.SourceRecRef.GetTable(DocVariant);
        case this.SourceRecRef.Number of
            Database::"Issued Reminder Header":
                begin
                    this.SourceRecRef.SetTable(this.GlobalIssuedReminderHeader);
                    if this.GlobalIssuedReminderHeader."No." = '' then
                        Error(this.SpecifyAReminderNoErr);
                    this.GlobalIssuedReminderHeader.SetRecFilter();
                    this.GlobalIssuedReminderLine.SetRange("Reminder No.", this.GlobalIssuedReminderHeader."No.");
                    this.GlobalIssuedReminderLine.SetFilter(Type, '<>%1', this.GlobalIssuedReminderLine.Type::" ");

                    if this.GlobalIssuedReminderLine.FindSet() then
                        repeat
                            this.CopyReminderLineToSalesLine(this.GlobalSalesLine, this.GlobalIssuedReminderHeader, this.GlobalIssuedReminderLine);
                        until this.GlobalIssuedReminderLine.Next() = 0;

                    this.IsReminder := true;
                end;
            Database::"Issued Fin. Charge Memo Header":
                begin
                    this.SourceRecRef.SetTable(this.GlobalIssuedFinChargeMemoHeader);
                    if this.GlobalIssuedFinChargeMemoHeader."No." = '' then
                        Error(this.SpecifyAReminderNoErr);
                    this.GlobalIssuedFinChargeMemoHeader.SetRecFilter();
                    this.GlobalIssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", this.GlobalIssuedFinChargeMemoHeader."No.");
                    this.GlobalIssuedFinChargeMemoLine.SetFilter(Type, '<>%1', this.GlobalIssuedFinChargeMemoLine.Type::" ");

                    if this.GlobalIssuedFinChargeMemoLine.FindSet() then
                        repeat
                            this.CopyFinChargeMemoLineToSalesLine(this.GlobalSalesLine, this.GlobalIssuedFinChargeMemoHeader, this.GlobalIssuedFinChargeMemoLine);
                        until this.GlobalIssuedFinChargeMemoLine.Next() = 0;

                    this.IsFinChargeMemo := true;
                end;
            else
                Error(this.UnSupportedTableTypeErr, this.SourceRecRef.Number);
        end;
    end;

    local procedure CopyReminderToSalesHeader(var SalesHeader: Record "Sales Header"; IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        Clear(SalesHeader);
        SalesHeader."No." := IssuedReminderHeader."No.";
        SalesHeader."Document Date" := IssuedReminderHeader."Document Date";
        SalesHeader."Due Date" := IssuedReminderHeader."Due Date";
        SalesHeader."Posting Date" := IssuedReminderHeader."Posting Date";
        SalesHeader."Currency Code" := IssuedReminderHeader."Currency Code";
        SalesHeader.Validate("Sell-to Customer No.", IssuedReminderHeader."Customer No.");
        if IssuedReminderHeader.Contact <> '' then
            SalesHeader.Validate("Sell-to Contact", IssuedReminderHeader.Contact);
        SalesHeader."Your Reference" := IssuedReminderHeader."Your Reference";
        SalesHeader."Customer Posting Group" := IssuedReminderHeader."Customer Posting Group";
        SalesHeader."Gen. Bus. Posting Group" := IssuedReminderHeader."Gen. Bus. Posting Group";
        SalesHeader."VAT Bus. Posting Group" := IssuedReminderHeader."VAT Bus. Posting Group";
        SalesHeader."Reason Code" := IssuedReminderHeader."Reason Code";
        SalesHeader."Company Bank Account Code" := IssuedReminderHeader."Company Bank Account Code";
    end;

    local procedure CopyFinChargeMemoToSalesHeader(var SalesHeader: Record "Sales Header"; IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        Clear(SalesHeader);
        SalesHeader."No." := IssuedFinChargeMemoHeader."No.";
        SalesHeader."Document Date" := IssuedFinChargeMemoHeader."Document Date";
        SalesHeader."Due Date" := IssuedFinChargeMemoHeader."Due Date";
        SalesHeader."Posting Date" := IssuedFinChargeMemoHeader."Posting Date";
        SalesHeader."Currency Code" := IssuedFinChargeMemoHeader."Currency Code";
        SalesHeader.Validate("Sell-to Customer No.", IssuedFinChargeMemoHeader."Customer No.");
        if IssuedFinChargeMemoHeader.Contact <> '' then
            SalesHeader.Validate("Sell-to Contact", IssuedFinChargeMemoHeader.Contact);
        SalesHeader."Your Reference" := IssuedFinChargeMemoHeader."Your Reference";
        SalesHeader."Customer Posting Group" := IssuedFinChargeMemoHeader."Customer Posting Group";
        SalesHeader."Gen. Bus. Posting Group" := IssuedFinChargeMemoHeader."Gen. Bus. Posting Group";
        SalesHeader."VAT Bus. Posting Group" := IssuedFinChargeMemoHeader."VAT Bus. Posting Group";
        SalesHeader."Reason Code" := IssuedFinChargeMemoHeader."Reason Code";
        SalesHeader."Company Bank Account Code" := IssuedFinChargeMemoHeader."Company Bank Account Code";
    end;

    local procedure CopyReminderLineToSalesLine(var SalesLine: Record "Sales Line"; IssuedReminderHeader: Record "Issued Reminder Header"; IssuedReminderLine: Record "Issued Reminder Line")
    begin
        Clear(SalesLine);
        SalesLine."Document No." := IssuedReminderLine."Reminder No.";
        SalesLine."Line No." := IssuedReminderLine."Line No.";
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := IssuedReminderLine."No.";
        SalesLine."VAT %" := IssuedReminderLine."VAT %";
        SalesLine.Quantity := 1;
        SalesLine.Validate(Amount, IssuedReminderLine.Amount);
        SalesLine.Description := IssuedReminderLine.Description;
        SalesLine."Unit Price" := IssuedReminderLine.Amount;
        SalesLine."VAT Prod. Posting Group" := IssuedReminderLine."VAT Prod. Posting Group";
        SalesLine."VAT Bus. Posting Group" := IssuedReminderHeader."VAT Bus. Posting Group";
    end;

    local procedure CopyFinChargeMemoLineToSalesLine(var SalesLine: Record "Sales Line"; IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line")
    begin
        Clear(SalesLine);
        SalesLine."Document No." := IssuedFinChargeMemoLine."Finance Charge Memo No.";
        SalesLine."Line No." := IssuedFinChargeMemoLine."Line No.";
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := IssuedFinChargeMemoLine."No.";
        SalesLine."VAT %" := IssuedFinChargeMemoLine."VAT %";
        SalesLine.Quantity := 1;
        SalesLine.Validate(Amount, IssuedFinChargeMemoLine.Amount);
        SalesLine.Description := IssuedFinChargeMemoLine.Description;
        SalesLine."Unit Price" := IssuedFinChargeMemoLine.Amount;
        SalesLine."VAT Prod. Posting Group" := IssuedFinChargeMemoLine."VAT Prod. Posting Group";
        SalesLine."VAT Bus. Posting Group" := IssuedFinChargeMemoHeader."VAT Bus. Posting Group";
    end;

    local procedure FindNextIssuedReminderRec(var IssuedReminderHeader: Record "Issued Reminder Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := IssuedReminderHeader.FindSet()
        else
            Found := IssuedReminderHeader.Next() <> 0;
        if Found then
            this.CopyReminderToSalesHeader(SalesHeader, IssuedReminderHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
    end;

    local procedure FindNextReminderLineRec(Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := this.GlobalIssuedReminderLine.FindSet()
        else
            Found := this.GlobalIssuedReminderLine.Next() <> 0;
        if Found then
            this.CopyReminderLineToSalesLine(this.GlobalSalesLine, this.GlobalIssuedReminderHeader, this.GlobalIssuedReminderLine);
    end;

    local procedure FindNextIssuedFinChargeMemoRec(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := IssuedFinChargeMemoHeader.Find('-')
        else
            Found := IssuedFinChargeMemoHeader.Next() <> 0;
        if Found then
            this.CopyFinChargeMemoToSalesHeader(SalesHeader, IssuedFinChargeMemoHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
    end;

    local procedure FindNextFinChargeMemoLineRec(Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := this.GlobalIssuedFinChargeMemoLine.Find('-')
        else
            Found := this.GlobalIssuedFinChargeMemoLine.Next() <> 0;
        if Found then
            this.CopyFinChargeMemoLineToSalesLine(this.GlobalSalesLine, this.GlobalIssuedFinChargeMemoHeader, this.GlobalIssuedFinChargeMemoLine);
    end;

    local procedure GetCustomizationID(): Text
    begin
        exit('urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0')
    end;

    local procedure GetProfileID(): Text
    begin
        exit('urn:fdc:peppol.eu:2017:poacc:billing:01:1.0');
    end;
}
