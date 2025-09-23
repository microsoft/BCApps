codeunit 37200 "PEPPOL30 Management" implements "PEPPOL Attachment Handler"
                                            , "PEPPOL Delivery Info Provider"
                                            , "PEPPOL Document Info Provider"
                                            , "PEPPOL Format Provider"
                                            , "PEPPOL Line Info Provider"
                                            , "PEPPOL Monetary Info Provider"
                                            , "PEPPOL Party Info Provider"
                                            , "PEPPOL Payment Info Provider"
                                            , "PEPPOL Posted Document Iterator"
                                            , "PEPPOL Tax Info Provider"
{
    var
        PEPPOLManagementImpl: Codeunit "PEPPOL30 Management Impl.";

    procedure GetGeneralInfo(SalesHeader: Record "Sales Header"; FormatProvider: Interface "PEPPOL Format Provider"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var InvoiceTypeCodeListID: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var DocumentCurrencyCodeListID: Text; var TaxCurrencyCode: Text; var TaxCurrencyCodeListID: Text; var AccountingCost: Text)
    begin
        PEPPOLManagementImpl.GetGeneralInfo(SalesHeader, ID, IssueDate, InvoiceTypeCode, InvoiceTypeCodeListID, Note, TaxPointDate, DocumentCurrencyCode, DocumentCurrencyCodeListID, TaxCurrencyCode, TaxCurrencyCodeListID, AccountingCost);
    end;

    procedure GetGeneralInfoBIS(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)
    begin
        PEPPOLManagementImpl.GetGeneralInfoBIS(SalesHeader, ID, IssueDate, InvoiceTypeCode, Note, TaxPointDate, DocumentCurrencyCode, AccountingCost);
    end;

    procedure GetInvoicePeriodInfo(var StartDate: Text; var EndDate: Text)
    begin
        PEPPOLManagementImpl.GetInvoicePeriodInfo(StartDate, EndDate);
    end;

    procedure GetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        PEPPOLManagementImpl.GetOrderReferenceInfo(SalesHeader, OrderReferenceID);
    end;

    procedure GetOrderReferenceInfoBIS(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        PEPPOLManagementImpl.GetOrderReferenceInfoBIS(SalesHeader, OrderReferenceID);
    end;

    procedure GetContractDocRefInfo(SalesHeader: Record "Sales Header"; var ContractDocumentReferenceID: Text; var DocumentTypeCode: Text; var ContractRefDocTypeCodeListID: Text; var DocumentType: Text)
    begin
        PEPPOLManagementImpl.GetContractDocRefInfo(SalesHeader, ContractDocumentReferenceID, DocumentTypeCode, ContractRefDocTypeCodeListID, DocumentType);
    end;

    procedure GetAdditionalDocRefInfo(AttachmentNumber: Integer; var DocumentAttachments: Record "Document Attachment"; Salesheader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; NewProcessedDocType: Option Sale,Service)
    begin
        PEPPOLManagementImpl.GetAdditionalDocRefInfo(AttachmentNumber, DocumentAttachments, Salesheader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, Filename, MimeCode, EmbeddedDocumentBinaryObject, NewProcessedDocType);
    end;

    procedure GetAdditionalDocRefInfo(Salesheader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; NewProcessedDocType: Option Sale,Service)
    begin
        PEPPOLManagementImpl.GetAdditionalDocRefInfo(Salesheader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, MimeCode, EmbeddedDocumentBinaryObject, NewProcessedDocType);
    end;

    procedure GetBuyerReference(SalesHeader: Record "Sales Header") BuyerReference: Text
    begin
        BuyerReference := PEPPOLManagementImpl.GetBuyerReference(SalesHeader);
    end;

    procedure GeneratePDFAttachmentAsAdditionalDocRef(SalesHeader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text)
    begin
        PEPPOLManagementImpl.GeneratePDFAttachmentAsAdditionalDocRef(SalesHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, Filename, MimeCode, EmbeddedDocumentBinaryObject);
    end;

    procedure GetAccountingSupplierPartyInfo(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);
    end;

    procedure GetAccountingSupplierPartyInfoBIS(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyInfoBIS(SupplierEndpointID, SupplierSchemeID, SupplierName);
    end;

    procedure GetAccountingSupplierPartyPostalAddr(SalesHeader: Record "Sales Header"; var StreetName: Text; var SupplierAdditionalStreetName: Text; var CityName: Text; var PostalZone: Text; var CountrySubentity: Text; var IdentificationCode: Text; var ListID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyPostalAddr(SalesHeader, StreetName, SupplierAdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);
    end;

    procedure GetAccountingSupplierPartyTaxScheme(var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
    end;

    procedure GetAccountingSupplierPartyTaxSchemeBIS(var VATAmtLine: Record "VAT Amount Line"; var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyTaxSchemeBIS(VATAmtLine, CompanyID, CompanyIDSchemeID, TaxSchemeID);
    end;

    procedure GetAccountingSupplierPartyLegalEntity(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyLegalEntity(PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);
    end;

    procedure GetAccountingSupplierPartyLegalEntityBIS(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyLegalEntityBIS(PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);
    end;

    procedure GetAccountingSupplierPartyContact(SalesHeader: Record "Sales Header"; var ContactID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyContact(SalesHeader, ContactID, ContactName, Telephone, Telefax, ElectronicMail);
    end;

    procedure GetAccountingSupplierPartyIdentificationID(SalesHeader: Record "Sales Header"; var PartyIdentificationID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingSupplierPartyIdentificationID(SalesHeader, PartyIdentificationID);
    end;

    procedure GetAccountingCustomerPartyInfo(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyInfo(SalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName);
    end;

    procedure GetAccountingCustomerPartyInfoBIS(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyInfoBIS(SalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName);
    end;

    procedure GetAccountingCustomerPartyPostalAddr(SalesHeader: Record "Sales Header"; var CustomerStreetName: Text; var CustomerAdditionalStreetName: Text; var CustomerCityName: Text; var CustomerPostalZone: Text; var CustomerCountrySubentity: Text; var CustomerIdentificationCode: Text; var CustomerListID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyPostalAddr(SalesHeader, CustomerStreetName, CustomerAdditionalStreetName, CustomerCityName, CustomerPostalZone, CustomerCountrySubentity, CustomerIdentificationCode, CustomerListID);
    end;

    procedure GetAccountingCustomerPartyTaxScheme(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyTaxScheme(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);
    end;

    procedure GetAccountingCustomerPartyTaxSchemeBIS(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyTaxSchemeBIS(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);
    end;

    procedure GetAccountingCustomerPartyTaxSchemeBIS30(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyTaxSchemeBIS30(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, TempVATAmountLine);
    end;

    procedure GetAccountingCustomerPartyLegalEntity(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyLegalEntity(SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);
    end;

    procedure GetAccountingCustomerPartyLegalEntityBIS(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyLegalEntityBIS(SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);
    end;

    procedure GetAccountingCustomerPartyContact(SalesHeader: Record "Sales Header"; var CustContactID: Text; var CustContactName: Text; var CustContactTelephone: Text; var CustContactTelefax: Text; var CustContactElectronicMail: Text)
    begin
        PEPPOLManagementImpl.GetAccountingCustomerPartyContact(SalesHeader, CustContactID, CustContactName, CustContactTelephone, CustContactTelefax, CustContactElectronicMail);
    end;

    procedure GetPayeePartyInfo(var PayeePartyID: Text; var PayeePartyIDSchemeID: Text; var PayeePartyNameName: Text; var PayeePartyLegalEntityCompanyID: Text; var PayeePartyLegalCompIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetPayeePartyInfo(PayeePartyID, PayeePartyIDSchemeID, PayeePartyNameName, PayeePartyLegalEntityCompanyID, PayeePartyLegalCompIDSchemeID);
    end;

    procedure GetTaxRepresentativePartyInfo(var TaxRepPartyNameName: Text; var PayeePartyTaxSchemeCompanyID: Text; var PayeePartyTaxSchCompIDSchemeID: Text; var PayeePartyTaxSchemeTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetTaxRepresentativePartyInfo(TaxRepPartyNameName, PayeePartyTaxSchemeCompanyID, PayeePartyTaxSchCompIDSchemeID, PayeePartyTaxSchemeTaxSchemeID);
    end;

    procedure GetDeliveryInfo(var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetDeliveryInfo(ActualDeliveryDate, DeliveryID, DeliveryIDSchemeID);
    end;

    procedure GetGLNDeliveryInfo(SalesHeader: Record "Sales Header"; var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetGLNDeliveryInfo(SalesHeader, ActualDeliveryDate, DeliveryID, DeliveryIDSchemeID);
    end;

    procedure GetGLNForHeader(SalesHeader: Record "Sales Header"): Code[13]
    begin
        PEPPOLManagementImpl.GetGLNForHeader(SalesHeader);
    end;

    procedure GetDeliveryAddress(SalesHeader: Record "Sales Header"; var DeliveryStreetName: Text; var DeliveryAdditionalStreetName: Text; var DeliveryCityName: Text; var DeliveryPostalZone: Text; var DeliveryCountrySubentity: Text; var DeliveryCountryIdCode: Text; var DeliveryCountryListID: Text)
    begin
        PEPPOLManagementImpl.GetDeliveryAddress(SalesHeader, DeliveryStreetName, DeliveryAdditionalStreetName, DeliveryCityName, DeliveryPostalZone, DeliveryCountrySubentity, DeliveryCountryIdCode, DeliveryCountryListID);
    end;

    procedure GetPaymentMeansInfo(SalesHeader: Record "Sales Header"; var PaymentMeansCode: Text; var PaymentMeansListID: Text; var PaymentDueDate: Text; var PaymentChannelCode: Text; var PaymentID: Text; var PrimaryAccountNumberID: Text; var NetworkID: Text)
    begin
        PEPPOLManagementImpl.GetPaymentMeansInfo(SalesHeader, PaymentMeansCode, PaymentMeansListID, PaymentDueDate, PaymentChannelCode, PaymentID, PrimaryAccountNumberID, NetworkID);
    end;

    procedure GetPaymentMeansPayeeFinancialAcc(var PayeeFinancialAccountID: Text; var PaymentMeansSchemeID: Text; var FinancialInstitutionBranchID: Text; var FinancialInstitutionID: Text; var FinancialInstitutionSchemeID: Text; var FinancialInstitutionName: Text)
    begin
        PEPPOLManagementImpl.GetPaymentMeansPayeeFinancialAcc(PayeeFinancialAccountID, PaymentMeansSchemeID, FinancialInstitutionBranchID, FinancialInstitutionID, FinancialInstitutionSchemeID, FinancialInstitutionName);
    end;

    procedure GetPaymentMeansPayeeFinancialAccBIS(SalesHeader: Record "Sales Header"; var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)
    begin
        PEPPOLManagementImpl.GetPaymentMeansPayeeFinancialAccBIS(SalesHeader, PayeeFinancialAccountID, FinancialInstitutionBranchID);
    end;

    procedure GetPaymentMeansFinancialInstitutionAddr(var FinancialInstitutionStreetName: Text; var AdditionalStreetName: Text; var FinancialInstitutionCityName: Text; var FinancialInstitutionPostalZone: Text; var FinancialInstCountrySubentity: Text; var FinancialInstCountryIdCode: Text; var FinancialInstCountryListID: Text)
    begin
        PEPPOLManagementImpl.GetPaymentMeansFinancialInstitutionAddr(FinancialInstitutionStreetName, AdditionalStreetName, FinancialInstitutionCityName, FinancialInstitutionPostalZone, FinancialInstCountrySubentity, FinancialInstCountryIdCode, FinancialInstCountryListID);
    end;

    procedure GetPaymentTermsInfo(SalesHeader: Record "Sales Header"; var PaymentTermsNote: Text)
    begin
        PEPPOLManagementImpl.GetPaymentTermsInfo(SalesHeader, PaymentTermsNote);
    end;

    procedure GetAllowanceChargeInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAllowanceChargeInfo(VATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID, AllowanceChargeReason, Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID, Percent, AllowanceChargeTaxSchemeID);
    end;

    procedure GetAllowanceChargeInfoBIS(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetAllowanceChargeInfoBIS(VATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID, AllowanceChargeReason, Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID, Percent, AllowanceChargeTaxSchemeID);
    end;

    procedure GetTaxExchangeRateInfo(SalesHeader: Record "Sales Header"; var SourceCurrencyCode: Text; var SourceCurrencyCodeListID: Text; var TargetCurrencyCode: Text; var TargetCurrencyCodeListID: Text; var CalculationRate: Text; var MathematicOperatorCode: Text; var Date: Text)
    begin
        PEPPOLManagementImpl.GetTaxExchangeRateInfo(SalesHeader, SourceCurrencyCode, SourceCurrencyCodeListID, TargetCurrencyCode, TargetCurrencyCodeListID, CalculationRate, MathematicOperatorCode, Date);
    end;

    procedure GetTaxTotalInfo(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var TaxAmount: Text; var TaxTotalCurrencyID: Text)
    begin
        PEPPOLManagementImpl.GetTaxTotalInfo(SalesHeader, VATAmtLine, TaxAmount, TaxTotalCurrencyID);
    end;

    procedure GetTaxSubtotalInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var TaxableAmount: Text; var TaxAmountCurrencyID: Text; var SubtotalTaxAmount: Text; var TaxSubtotalCurrencyID: Text; var TransactionCurrencyTaxAmount: Text; var TransCurrTaxAmtCurrencyID: Text; var TaxTotalTaxCategoryID: Text; var schemeID: Text; var TaxCategoryPercent: Text; var TaxTotalTaxSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetTaxSubtotalInfo(VATAmtLine, SalesHeader, TaxableAmount, TaxAmountCurrencyID, SubtotalTaxAmount, TaxSubtotalCurrencyID, TransactionCurrencyTaxAmount, TransCurrTaxAmtCurrencyID, TaxTotalTaxCategoryID, schemeID, TaxCategoryPercent, TaxTotalTaxSchemeID);
    end;

    procedure GetTaxTotalInfoLCY(SalesHeader: Record "Sales Header"; var TaxAmount: Text; var TaxCurrencyID: Text; var TaxTotalCurrencyID: Text)
    begin
        PEPPOLManagementImpl.GetTaxTotalInfoLCY(SalesHeader, TaxAmount, TaxCurrencyID, TaxTotalCurrencyID);
    end;

    procedure GetLegalMonetaryInfo(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text; var PrepaidAmount: Text; var PrepaidCurrencyID: Text; var PayableRoundingAmount: Text; var PayableRndingAmountCurrencyID: Text; var PayableAmount: Text; var PayableAmountCurrencyID: Text)
    begin
        PEPPOLManagementImpl.GetLegalMonetaryInfo(SalesHeader, TempSalesLine, VATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID, PrepaidAmount, PrepaidCurrencyID, PayableRoundingAmount, PayableRndingAmountCurrencyID, PayableAmount, PayableAmountCurrencyID);
    end;


    procedure GetLegalMonetaryDocAmounts(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text)
    begin
        PEPPOLManagementImpl.GetLegalMonetaryDocAmounts(SalesHeader, VATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID);
    end;

    procedure GetLineGeneralInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineID: Text; var InvoiceLineNote: Text; var InvoicedQuantity: Text; var InvoiceLineExtensionAmount: Text; var LineExtensionAmountCurrencyID: Text; var InvoiceLineAccountingCost: Text)
    begin
        PEPPOLManagementImpl.GetLineGeneralInfo(SalesLine, SalesHeader, InvoiceLineID, InvoiceLineNote, InvoicedQuantity, InvoiceLineExtensionAmount, LineExtensionAmountCurrencyID, InvoiceLineAccountingCost);
    end;

    procedure GetLineUnitCodeInfo(SalesLine: Record "Sales Line"; var unitCode: Text; var unitCodeListID: Text)
    begin
        PEPPOLManagementImpl.GetLineUnitCodeInfo(SalesLine, unitCode, unitCodeListID);
    end;

    procedure GetLineInvoicePeriodInfo(var InvLineInvoicePeriodStartDate: Text; var InvLineInvoicePeriodEndDate: Text)
    begin
        PEPPOLManagementImpl.GetLineInvoicePeriodInfo(InvLineInvoicePeriodStartDate, InvLineInvoicePeriodEndDate);
    end;

    procedure GetLineOrderLineRefInfo()
    begin
        PEPPOLManagementImpl.GetLineOrderLineRefInfo();
    end;

    procedure GetLineDeliveryInfo(var InvoiceLineActualDeliveryDate: Text; var InvoiceLineDeliveryID: Text; var InvoiceLineDeliveryIDSchemeID: Text)
    begin
        PEPPOLManagementImpl.GetLineDeliveryInfo(InvoiceLineActualDeliveryDate, InvoiceLineDeliveryID, InvoiceLineDeliveryIDSchemeID);
    end;

    procedure GetLineDeliveryPostalAddr(var InvoiceLineDeliveryStreetName: Text; var InvLineDeliveryAddStreetName: Text; var InvoiceLineDeliveryCityName: Text; var InvoiceLineDeliveryPostalZone: Text; var InvLnDeliveryCountrySubentity: Text; var InvLnDeliveryCountryIdCode: Text; var InvLineDeliveryCountryListID: Text)
    begin
        PEPPOLManagementImpl.GetLineDeliveryPostalAddr(InvoiceLineDeliveryStreetName, InvLineDeliveryAddStreetName, InvoiceLineDeliveryCityName, InvoiceLineDeliveryPostalZone, InvLnDeliveryCountrySubentity, InvLnDeliveryCountryIdCode, InvLineDeliveryCountryListID);
    end;

    procedure GetDeliveryPartyName(SalesHeader: Record "Sales Header"; var DeliveryPartyName: Text)
    begin
        PEPPOLManagementImpl.GetDeliveryPartyName(SalesHeader, DeliveryPartyName);
    end;

    procedure GetLineAllowanceChargeInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvLnAllowanceChargeIndicator: Text; var InvLnAllowanceChargeReason: Text; var InvLnAllowanceChargeAmount: Text; var InvLnAllowanceChargeAmtCurrID: Text)
    begin
        PEPPOLManagementImpl.GetLineAllowanceChargeInfo(SalesLine, SalesHeader, InvLnAllowanceChargeIndicator, InvLnAllowanceChargeReason, InvLnAllowanceChargeAmount, InvLnAllowanceChargeAmtCurrID);
    end;

    procedure GetLineTaxTotal(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineTaxAmount: Text; var currencyID: Text)
    begin
        PEPPOLManagementImpl.GetLineTaxTotal(SalesLine, SalesHeader, InvoiceLineTaxAmount, currencyID);
    end;

    procedure GetLineItemInfo(SalesLine: Record "Sales Line"; var Description: Text; var Name: Text; var SellersItemIdentificationID: Text; var StandardItemIdentificationID: Text; var StdItemIdIDSchemeID: Text; var OriginCountryIdCode: Text; var OriginCountryIdCodeListID: Text)
    begin
        PEPPOLManagementImpl.GetLineItemInfo(SalesLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID, OriginCountryIdCode, OriginCountryIdCodeListID);
    end;

    procedure GetLineItemCommodityClassficationInfo(var CommodityCode: Text; var CommodityCodeListID: Text; var ItemClassificationCode: Text; var ItemClassificationCodeListID: Text)
    begin
        PEPPOLManagementImpl.GetLineItemCommodityClassficationInfo(CommodityCode, CommodityCodeListID, ItemClassificationCode, ItemClassificationCodeListID);
    end;

    procedure GetLineItemClassfiedTaxCategory(SalesLine: Record "Sales Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)
    begin
        PEPPOLManagementImpl.GetLineItemClassfiedTaxCategory(SalesLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);
    end;

    procedure GetLineItemClassfiedTaxCategoryBIS(SalesLine: Record "Sales Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)
    begin
        PEPPOLManagementImpl.GetLineItemClassfiedTaxCategoryBIS(SalesLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);
    end;

    procedure GetLineAdditionalItemPropertyInfo(SalesLine: Record "Sales Line"; var AdditionalItemPropertyName: Text; var AdditionalItemPropertyValue: Text)
    begin
        PEPPOLManagementImpl.GetLineAdditionalItemPropertyInfo(SalesLine, AdditionalItemPropertyName, AdditionalItemPropertyValue);
    end;

    procedure GetLinePriceInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLinePriceAmount: Text; var InvLinePriceAmountCurrencyID: Text; var BaseQuantity: Text; var UnitCode: Text)
    begin
        PEPPOLManagementImpl.GetLinePriceInfo(SalesLine, SalesHeader, InvoiceLinePriceAmount, InvLinePriceAmountCurrencyID, BaseQuantity, UnitCode);
    end;

    procedure GetLinePriceAllowanceChargeInfo(var PriceChargeIndicator: Text; var PriceAllowanceChargeAmount: Text; var PriceAllowanceAmountCurrencyID: Text; var PriceAllowanceChargeBaseAmount: Text; var PriceAllowChargeBaseAmtCurrID: Text)
    begin
        PEPPOLManagementImpl.GetLinePriceAllowanceChargeInfo(PriceChargeIndicator, PriceAllowanceChargeAmount, PriceAllowanceAmountCurrencyID, PriceAllowanceChargeBaseAmount, PriceAllowChargeBaseAmtCurrID);
    end;

    procedure GetCrMemoBillingReferenceInfo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var InvoiceDocRefID: Text; var InvoiceDocRefIssueDate: Text)
    begin
        PEPPOLManagementImpl.GetCrMemoBillingReferenceInfo(SalesCrMemoHeader, InvoiceDocRefID, InvoiceDocRefIssueDate);
    end;

    procedure GetTotals(SalesLine: Record "Sales Line"; var VATAmtLine: Record "VAT Amount Line")
    begin
        // case
        // sales
        PEPPOLManagementImpl.GetTotals(SalesLine, VATAmtLine);
        // service
        // 
    end;

    procedure GetTaxCategories(SalesLine: Record "Sales Line"; var VATProductPostingGroupCategory: Record "VAT Product Posting Group")
    begin
        PEPPOLManagementImpl.GetTaxCategories(SalesLine, VATProductPostingGroupCategory);
    end;

    procedure GetInvoiceRoundingLine(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
        PEPPOLManagementImpl.GetInvoiceRoundingLine(TempSalesLine, SalesLine);
    end;

    procedure GetTaxExemptionReason(var VATProductPostingGroupCategory: Record "VAT Product Posting Group"; var TaxExemptionReasonTxt: Text; TaxCategoryID: Text)
    begin
        PEPPOLManagementImpl.GetTaxExemptionReason(VATProductPostingGroupCategory, TaxExemptionReasonTxt, TaxCategoryID);
    end;

    procedure GetPeppolTelemetryTok(): Text
    begin
        exit(PEPPOLManagementImpl.GetPeppolTelemetryTok());
    end;

    procedure GetUoMforPieceINUNECERec20ListID(): Code[10]
    begin
        exit(PEPPOLManagementImpl.GetUoMforPieceINUNECERec20ListID());
    end;

    procedure GetVATScheme(CountryRegionCode: Code[10]): Text
    begin
        exit(PEPPOLManagementImpl.GetVATScheme(CountryRegionCode));
    end;

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

    procedure IsStandardVATCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(TaxCategory = PEPPOLManagementImpl.GetTaxCategoryS());
    end;

    procedure IsOutsideScopeVATCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(TaxCategory = PEPPOLManagementImpl.GetTaxCategoryO());
    end;

    internal procedure FormatVATRegistrationNo(VATRegistrationNo: Text; CountryCode: Code[10]; IsBISBilling: Boolean; IsPartyTaxScheme: Boolean): Text
    begin
        exit(PEPPOLManagementImpl.FormatVATRegistrationNo(VATRegistrationNo, CountryCode, IsBISBilling, IsPartyTaxScheme));
    end;

    procedure IsRoundingLine(SalesLine: Record "Sales Line"; CustomerNo: Code[20]): Boolean;
    begin
        exit(PEPPOLManagementImpl.IsRoundingLine(SalesLine, CustomerNo));
    end;

    procedure TransferHeaderToSalesHeader(FromRecord: Variant; var ToSalesHeader: Record "Sales Header")
    begin
        PEPPOLManagementImpl.TransferHeaderToSalesHeader(FromRecord, ToSalesHeader);
    end;

    procedure TransferLineToSalesLine(FromRecord: Variant; var ToSalesLine: Record "Sales Line")
    begin
        PEPPOLManagementImpl.TransferLineToSalesLine(FromRecord, ToSalesLine);
    end;

    procedure RecRefTransferFields(FromRecord: Variant; var ToRecord: Variant)
    begin
        PEPPOLManagementImpl.RecRefTransferFields(FromRecord, ToRecord);
    end;

    procedure FindNextSalesInvoiceRec(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer) : Boolean
    begin
        PEPPOLManagementImpl.FindNextSalesInvoiceRec(SalesInvoiceHeader, SalesHeader, Position);
    end;

    procedure FindNextSalesInvoiceLineRec(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesLine: Record "Sales Line"; Position: Integer): Boolean
    begin
        exit(PEPPOLManagementImpl.FindNextSalesInvoiceLineRec(SalesInvoiceLine, SalesLine, Position));
    end;

    procedure FindNextSalesCreditMemoRec(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer) : Boolean
    begin
        exit(PEPPOLManagementImpl.FindNextSalesCreditMemoRec(SalesCrMemoHeader, SalesHeader, Position));
    end;

    procedure FindNextSalesCreditMemoLineRec(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesLine: Record "Sales Line"; Position: Integer) : Boolean
    begin
        exit(PEPPOLManagementImpl.FindNextSalesCreditMemoLineRec(SalesCrMemoLine, SalesLine, Position));
    end;

    procedure FindNextServiceInvoiceRec(var ServiceInvoiceHeader: Record "Service Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer) : Boolean
    begin
        exit(PEPPOLManagementImpl.FindNextServiceInvoiceRec(ServiceInvoiceHeader, SalesHeader, Position));
    end;

    procedure FindNextServiceInvoiceLineRec(var ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line"; var SalesLine: Record "Sales Line"; Position: Integer): Boolean
    begin
        exit(PEPPOLManagementImpl.FindNextServiceInvoiceLineRec(ServiceInvoiceLine, SalesLine, Position));
    end;

    procedure FindNextServiceCreditMemoRec(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer) : Boolean
    begin
        exit(PEPPOLManagementImpl.FindNextServiceCreditMemoRec(ServiceCrMemoHeader, SalesHeader, Position));
    end;
    procedure FindNextServiceCreditMemoLineRec(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var SalesLine: Record "Sales Line"; Position: Integer) : Boolean
    begin
        exit(PEPPOLManagementImpl.FindNextServiceCreditMemoLineRec(ServiceCrMemoLine, SalesLine, Position));
    end;
}