// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Bank.BankAccount;
using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Service.History;
using System.Reflection;
using System.Utilities;

codeunit 10978 "CII XML Builder"
{
    Access = Internal;

    procedure CreateInvoiceXml(var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
        BuildCIIDocument(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob, '380');
    end;

    procedure CreateCreditMemoXml(var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
        BuildCIIDocument(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob, '381');
    end;

    local procedure BuildCIIDocument(var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob"; TypeCode: Text)
    var
        CompanyInformation: Record "Company Information";
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        OutStr: OutStream;
    begin
        CompanyInformation.Get();

        XmlDoc := XmlDocument.Create();

        RootElement := XmlElement.Create('CrossIndustryInvoice', RsmNamespaceTok);
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('ram', RamNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('udt', UdtNamespaceTok));

        AddExchangedDocumentContext(RootElement);
        AddExchangedDocument(RootElement, EDocument, TypeCode);
        AddSupplyChainTradeTransaction(RootElement, EDocument, SourceDocumentHeader, SourceDocumentLines, CompanyInformation);

        XmlDoc.Add(RootElement);

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStr);
    end;

    local procedure AddExchangedDocumentContext(var RootElement: XmlElement)
    var
        ContextElement: XmlElement;
        GuidelineElement: XmlElement;
        IdElement: XmlElement;
    begin
        ContextElement := XmlElement.Create('ExchangedDocumentContext', RsmNamespaceTok);

        GuidelineElement := XmlElement.Create('GuidelineSpecifiedDocumentContextParameter', RamNamespaceTok);
        IdElement := XmlElement.Create('ID', RamNamespaceTok, FacturXProfileIdTok);
        GuidelineElement.Add(IdElement);
        ContextElement.Add(GuidelineElement);

        RootElement.Add(ContextElement);
    end;

    local procedure AddExchangedDocument(var RootElement: XmlElement; var EDocument: Record "E-Document"; TypeCode: Text)
    var
        DocElement: XmlElement;
        IdElement: XmlElement;
        TypeCodeElement: XmlElement;
        IssueDateElement: XmlElement;
        DateStringElement: XmlElement;
    begin
        DocElement := XmlElement.Create('ExchangedDocument', RsmNamespaceTok);

        IdElement := XmlElement.Create('ID', RamNamespaceTok, EDocument."Document No.");
        DocElement.Add(IdElement);

        TypeCodeElement := XmlElement.Create('TypeCode', RamNamespaceTok, TypeCode);
        DocElement.Add(TypeCodeElement);

        IssueDateElement := XmlElement.Create('IssueDateTime', RamNamespaceTok);
        DateStringElement := XmlElement.Create('DateTimeString', UdtNamespaceTok, FormatDate(EDocument."Document Date"));
        DateStringElement.SetAttribute('format', '102');
        IssueDateElement.Add(DateStringElement);
        DocElement.Add(IssueDateElement);

        // BR-FR-05: Mandatory French legal mentions
        AddIncludedNote(DocElement, RecoveryCostNoteTok, 'PMT');
        AddIncludedNote(DocElement, LatePaymentPenaltyNoteTok, 'PMD');
        AddIncludedNote(DocElement, EarlyPaymentDiscountNoteTok, 'AAB');

        RootElement.Add(DocElement);
    end;

    local procedure AddIncludedNote(var DocElement: XmlElement; NoteContent: Text; SubjectCode: Text)
    var
        NoteElement: XmlElement;
    begin
        NoteElement := XmlElement.Create('IncludedNote', RamNamespaceTok);
        NoteElement.Add(XmlElement.Create('Content', RamNamespaceTok, NoteContent));
        NoteElement.Add(XmlElement.Create('SubjectCode', RamNamespaceTok, SubjectCode));
        DocElement.Add(NoteElement);
    end;

    local procedure AddSupplyChainTradeTransaction(var RootElement: XmlElement; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; CompanyInformation: Record "Company Information")
    var
        TransactionElement: XmlElement;
    begin
        TransactionElement := XmlElement.Create('SupplyChainTradeTransaction', RsmNamespaceTok);

        AddLineItems(TransactionElement, SourceDocumentLines);
        AddTradeAgreement(TransactionElement, SourceDocumentHeader, CompanyInformation);
        AddTradeDelivery(TransactionElement, EDocument, SourceDocumentHeader);
        AddTradeSettlement(TransactionElement, EDocument, SourceDocumentHeader, SourceDocumentLines);

        RootElement.Add(TransactionElement);
    end;

    local procedure AddTradeAgreement(var TransactionElement: XmlElement; var SourceDocumentHeader: RecordRef; CompanyInformation: Record "Company Information")
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        FieldRefVar: FieldRef;
        AgreementElement: XmlElement;
        OrderRefElement: XmlElement;
        OrderRefIdElement: XmlElement;
        OrderRef: Text;
    begin
        AgreementElement := XmlElement.Create('ApplicableHeaderTradeAgreement', RamNamespaceTok);

        AddSellerTradeParty(AgreementElement, CompanyInformation);
        AddBuyerTradeParty(AgreementElement, SourceDocumentHeader);

        // BT-13 Purchase order reference
        if FREDocHelpers.FindFieldByName(SourceDocumentHeader, 'Order No.', FieldRefVar) then
            OrderRef := FieldRefVar.Value();
        if OrderRef = '' then
            if FREDocHelpers.FindFieldByName(SourceDocumentHeader, 'External Document No.', FieldRefVar) then
                OrderRef := FieldRefVar.Value();
        if OrderRef <> '' then begin
            OrderRefElement := XmlElement.Create('BuyerOrderReferencedDocument', RamNamespaceTok);
            OrderRefIdElement := XmlElement.Create('IssuerAssignedID', RamNamespaceTok, OrderRef);
            OrderRefElement.Add(OrderRefIdElement);
            AgreementElement.Add(OrderRefElement);
        end;

        TransactionElement.Add(AgreementElement);
    end;

    local procedure AddSellerTradeParty(var AgreementElement: XmlElement; CompanyInformation: Record "Company Information")
    var
        SellerElement: XmlElement;
        IdElement: XmlElement;
        NameElement: XmlElement;
        LegalOrgElement: XmlElement;
        LegalOrgIdElement: XmlElement;
    begin
        SellerElement := XmlElement.Create('SellerTradeParty', RamNamespaceTok);

        // SIRET as ID (BT-29)
        if CompanyInformation."SIRET No." <> '' then begin
            IdElement := XmlElement.Create('ID', RamNamespaceTok, CompanyInformation."SIRET No.");
            SellerElement.Add(IdElement);
        end;

        NameElement := XmlElement.Create('Name', RamNamespaceTok, CompanyInformation.Name);
        SellerElement.Add(NameElement);

        // SIREN as legal organization ID (BT-30) - must be exactly 9 digits
        if CompanyInformation."Registration No." <> '' then begin
            LegalOrgElement := XmlElement.Create('SpecifiedLegalOrganization', RamNamespaceTok);
            LegalOrgIdElement := XmlElement.Create('ID', RamNamespaceTok, CopyStr(CompanyInformation."Registration No.", 1, 9));
            LegalOrgIdElement.SetAttribute('schemeID', '0002');
            LegalOrgElement.Add(LegalOrgIdElement);
            SellerElement.Add(LegalOrgElement);
        end;

        AddPostalTradeAddress(
            SellerElement,
            CompanyInformation."Post Code",
            CompanyInformation.Address,
            CompanyInformation."Address 2",
            CompanyInformation.City,
            CompanyInformation."Country/Region Code");

        // BT-34 Seller electronic address
        if CompanyInformation."SIRET No." <> '' then
            AddElectronicAddress(SellerElement, CompanyInformation."SIRET No.", '0009');

        // VAT registration
        if CompanyInformation."VAT Registration No." <> '' then
            AddVATRegistration(SellerElement, CompanyInformation."VAT Registration No.");

        AgreementElement.Add(SellerElement);
    end;

    local procedure AddBuyerTradeParty(var AgreementElement: XmlElement; var SourceDocumentHeader: RecordRef)
    var
        Customer: Record Customer;
        CustomerNoFieldRef: FieldRef;
        BuyerElement: XmlElement;
        NameElement: XmlElement;
        CustomerNo: Code[20];
        VATRegistrationNo: Text;
        BuyerElectronicAddressEmitted: Boolean;
    begin
        BuyerElement := XmlElement.Create('BuyerTradeParty', RamNamespaceTok);

        if TryGetCustomerNoFieldRef(SourceDocumentHeader, CustomerNoFieldRef) then
            CustomerNo := CustomerNoFieldRef.Value();

        // Buyer name and postal address are taken from the posted document snapshot so that a later
        // edit to the customer master record does not change an already-issued legal document.
        NameElement := XmlElement.Create('Name', RamNamespaceTok, GetHeaderFieldText(SourceDocumentHeader, 'Sell-to Customer Name', 'Name'));
        BuyerElement.Add(NameElement);

        AddPostalTradeAddress(
            BuyerElement,
            GetHeaderFieldText(SourceDocumentHeader, 'Sell-to Post Code', 'Post Code'),
            GetHeaderFieldText(SourceDocumentHeader, 'Sell-to Address', 'Address'),
            GetHeaderFieldText(SourceDocumentHeader, 'Sell-to Address 2', 'Address 2'),
            GetHeaderFieldText(SourceDocumentHeader, 'Sell-to City', 'City'),
            GetHeaderFieldText(SourceDocumentHeader, 'Sell-to Country/Region Code', 'Country/Region Code'));

        // BT-49 Buyer electronic routing address is held only on the live customer master record.
        // BR-FR-12: BT-49 is mandatory in French e-invoicing.
        Customer.SetLoadFields("FR Electronic Address", "FR Elec. Address Scheme", "Registration Number");
        if (CustomerNo <> '') and Customer.Get(CustomerNo) then
            if Customer."FR Electronic Address" <> '' then begin
                AddElectronicAddress(BuyerElement, Customer."FR Electronic Address", GetElecAddressSchemeCode(Customer."FR Elec. Address Scheme"));
                BuyerElectronicAddressEmitted := true;
            end else
                if Customer."Registration Number" <> '' then begin
                    AddElectronicAddress(BuyerElement, CopyStr(Customer."Registration Number", 1, 14), '0009');
                    BuyerElectronicAddressEmitted := true;
                end;

        VATRegistrationNo := GetHeaderFieldText(SourceDocumentHeader, 'VAT Registration No.', '');

        // BR-FR-12 fallback: if no electronic address was emitted yet, use the VAT registration number
        if (not BuyerElectronicAddressEmitted) and (VATRegistrationNo <> '') then
            AddElectronicAddress(BuyerElement, VATRegistrationNo, '9957');

        if VATRegistrationNo <> '' then
            AddVATRegistration(BuyerElement, VATRegistrationNo);

        AgreementElement.Add(BuyerElement);
    end;

    local procedure GetHeaderFieldText(var SourceDocumentHeader: RecordRef; PrimaryFieldName: Text; FallbackFieldName: Text): Text
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        FieldRefVar: FieldRef;
    begin
        if FREDocHelpers.FindFieldByName(SourceDocumentHeader, PrimaryFieldName, FieldRefVar) then
            exit(Format(FieldRefVar.Value()));
        if (FallbackFieldName <> '') and FREDocHelpers.FindFieldByName(SourceDocumentHeader, FallbackFieldName, FieldRefVar) then
            exit(Format(FieldRefVar.Value()));
        exit('');
    end;

    local procedure AddPostalTradeAddress(var PartyElement: XmlElement; PostCode: Text; AddressLine1: Text; AddressLine2: Text; City: Text; CountryCode: Text)
    var
        PostalElement: XmlElement;
    begin
        PostalElement := XmlElement.Create('PostalTradeAddress', RamNamespaceTok);
        AddElementIfNotEmpty(PostalElement, 'PostcodeCode', PostCode);
        AddElementIfNotEmpty(PostalElement, 'LineOne', AddressLine1);
        AddElementIfNotEmpty(PostalElement, 'LineTwo', AddressLine2);
        AddElementIfNotEmpty(PostalElement, 'CityName', City);
        PostalElement.Add(XmlElement.Create('CountryID', RamNamespaceTok, CountryCode));
        PartyElement.Add(PostalElement);
    end;

    local procedure AddElectronicAddress(var PartyElement: XmlElement; ElectronicAddress: Text; SchemeId: Text)
    var
        ElecCommElement: XmlElement;
        UriIdElement: XmlElement;
    begin
        ElecCommElement := XmlElement.Create('URIUniversalCommunication', RamNamespaceTok);
        UriIdElement := XmlElement.Create('URIID', RamNamespaceTok, ElectronicAddress);
        UriIdElement.SetAttribute('schemeID', SchemeId);
        ElecCommElement.Add(UriIdElement);
        PartyElement.Add(ElecCommElement);
    end;

    local procedure GetElecAddressSchemeCode(ElecAddressScheme: Enum "Electronic Address Scheme"): Text
    begin
        case ElecAddressScheme of
            ElecAddressScheme::"EM":
                exit('EM');
            ElecAddressScheme::"0009":
                exit('0009');
            ElecAddressScheme::"0002":
                exit('0002');
            else
                exit(Format(ElecAddressScheme));
        end;
    end;

    local procedure AddVATRegistration(var PartyElement: XmlElement; VATRegistrationNo: Text)
    var
        TaxRegElement: XmlElement;
        TaxRegIdElement: XmlElement;
    begin
        TaxRegElement := XmlElement.Create('SpecifiedTaxRegistration', RamNamespaceTok);
        TaxRegIdElement := XmlElement.Create('ID', RamNamespaceTok, VATRegistrationNo);
        TaxRegIdElement.SetAttribute('schemeID', 'VA');
        TaxRegElement.Add(TaxRegIdElement);
        PartyElement.Add(TaxRegElement);
    end;

    procedure TryGetCustomerNoFieldRef(SourceDocumentHeader: RecordRef; var CustomerNoFieldRef: FieldRef): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        case SourceDocumentHeader.Number() of
            Database::"Sales Invoice Header", Database::"Sales Cr.Memo Header":
                begin
                    CustomerNoFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Sell-to Customer No."));
                    exit(true);
                end;
            Database::"Service Invoice Header",
            Database::"Service Cr.Memo Header",
            Database::"Issued Reminder Header",
            Database::"Issued Fin. Charge Memo Header":
                begin
                    CustomerNoFieldRef := SourceDocumentHeader.Field(ServiceInvoiceHeader.FieldNo("Customer No."));
                    exit(true);
                end;
            else
                exit(false);
        end;
    end;

    local procedure AddTradeDelivery(var TransactionElement: XmlElement; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef)
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        FieldRefVar: FieldRef;
        DeliveryElement: XmlElement;
        DeliveryEventElement: XmlElement;
        OccurrenceDateElement: XmlElement;
        DateStringElement: XmlElement;
        DeliveryDate: Date;
    begin
        DeliveryElement := XmlElement.Create('ApplicableHeaderTradeDelivery', RamNamespaceTok);

        // BT-72 Actual delivery date (fallback to document date to avoid empty element)
        if FREDocHelpers.FindFieldByName(SourceDocumentHeader, 'Shipment Date', FieldRefVar) then
            DeliveryDate := FieldRefVar.Value();
        if DeliveryDate = 0D then
            DeliveryDate := EDocument."Document Date";

        DeliveryEventElement := XmlElement.Create('ActualDeliverySupplyChainEvent', RamNamespaceTok);
        OccurrenceDateElement := XmlElement.Create('OccurrenceDateTime', RamNamespaceTok);
        DateStringElement := XmlElement.Create('DateTimeString', UdtNamespaceTok, FormatDate(DeliveryDate));
        DateStringElement.SetAttribute('format', '102');
        OccurrenceDateElement.Add(DateStringElement);
        DeliveryEventElement.Add(OccurrenceDateElement);
        DeliveryElement.Add(DeliveryEventElement);

        TransactionElement.Add(DeliveryElement);
    end;

    local procedure AddTradeSettlement(var TransactionElement: XmlElement; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef)
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        FieldRefVar: FieldRef;
        SettlementElement: XmlElement;
        CurrencyCodeElement: XmlElement;
        PaymentTermsElement: XmlElement;
        DueDateElement: XmlElement;
        DateStringElement: XmlElement;
        MonetarySummationElement: XmlElement;
        TaxTotalAmountElement: XmlElement;
        LineVATAmounts: Dictionary of [Text, Decimal];
        LineBaseAmounts: Dictionary of [Text, Decimal];
        VATRateByKey: Dictionary of [Text, Decimal];
        VATCategoryByKey: Dictionary of [Text, Text];
        CompanyBankAccountCode: Code[20];
        PaymentTermsCode: Code[10];
        InvoiceDiscountAmount: Decimal;
        LineTotalAmount: Decimal;
        TaxBasisTotalAmount: Decimal;
        InvoiceCurrencyCode: Code[10];
        DueDate: Date;
    begin
        SettlementElement := XmlElement.Create('ApplicableHeaderTradeSettlement', RamNamespaceTok);

        InvoiceCurrencyCode := GetInvoiceCurrencyCode(EDocument);
        CurrencyCodeElement := XmlElement.Create('InvoiceCurrencyCode', RamNamespaceTok, InvoiceCurrencyCode);
        SettlementElement.Add(CurrencyCodeElement);

        TaxBasisTotalAmount := EDocument."Amount Excl. VAT";
        LineTotalAmount := GetLineTotalAmountBeforeInvoiceDiscount(SourceDocumentLines);
        if LineTotalAmount = 0 then
            LineTotalAmount := TaxBasisTotalAmount;

        InvoiceDiscountAmount := GetInvoiceDiscountAmount(SourceDocumentHeader, SourceDocumentLines, TaxBasisTotalAmount, LineTotalAmount);
        if InvoiceDiscountAmount = 0 then
            InvoiceDiscountAmount := Round(LineTotalAmount - TaxBasisTotalAmount, 0.01);

        // BG-16 Payment means (BT-81 TypeCode + BT-84 IBAN + BT-86 BIC)
        if FREDocHelpers.FindFieldByName(SourceDocumentHeader, 'Company Bank Account Code', FieldRefVar) then
            CompanyBankAccountCode := FieldRefVar.Value();
        InsertPaymentMeans(SettlementElement, CompanyBankAccountCode);

        BuildVATAggregationData(SourceDocumentLines, LineBaseAmounts, LineVATAmounts, VATRateByKey, VATCategoryByKey);
        AddTaxBreakdown(SettlementElement, LineBaseAmounts, LineVATAmounts, VATRateByKey, VATCategoryByKey, InvoiceDiscountAmount);
        AddDocumentLevelAllowances(SettlementElement, LineBaseAmounts, VATRateByKey, VATCategoryByKey, InvoiceDiscountAmount);

        // BG-20 Payment terms (BT-20 Description + BT-9 Due date)
        if FREDocHelpers.FindFieldByName(SourceDocumentHeader, 'Payment Terms Code', FieldRefVar) then
            PaymentTermsCode := FieldRefVar.Value();
        if FREDocHelpers.FindFieldByName(SourceDocumentHeader, 'Due Date', FieldRefVar) then
            DueDate := FieldRefVar.Value();
        if (PaymentTermsCode <> '') or (DueDate <> 0D) then begin
            PaymentTermsElement := XmlElement.Create('SpecifiedTradePaymentTerms', RamNamespaceTok);
            AddPaymentTermsDescription(PaymentTermsElement, PaymentTermsCode);
            if DueDate <> 0D then begin
                DueDateElement := XmlElement.Create('DueDateDateTime', RamNamespaceTok);
                DateStringElement := XmlElement.Create('DateTimeString', UdtNamespaceTok, FormatDate(DueDate));
                DateStringElement.SetAttribute('format', '102');
                DueDateElement.Add(DateStringElement);
                PaymentTermsElement.Add(DueDateElement);
            end;
            SettlementElement.Add(PaymentTermsElement);
        end;

        // Monetary summation
        MonetarySummationElement := XmlElement.Create('SpecifiedTradeSettlementHeaderMonetarySummation', RamNamespaceTok);
        AddAmountElement(MonetarySummationElement, 'LineTotalAmount', LineTotalAmount);
        if InvoiceDiscountAmount <> 0 then
            AddAmountElement(MonetarySummationElement, 'AllowanceTotalAmount', InvoiceDiscountAmount);
        AddAmountElement(MonetarySummationElement, 'TaxBasisTotalAmount', TaxBasisTotalAmount);
        TaxTotalAmountElement := XmlElement.Create('TaxTotalAmount', RamNamespaceTok,
            FormatDecimalValue(EDocument."Amount Incl. VAT" - TaxBasisTotalAmount));
        TaxTotalAmountElement.SetAttribute('currencyID', InvoiceCurrencyCode);
        MonetarySummationElement.Add(TaxTotalAmountElement);
        AddAmountElement(MonetarySummationElement, 'GrandTotalAmount', EDocument."Amount Incl. VAT");
        AddAmountElement(MonetarySummationElement, 'DuePayableAmount', EDocument."Amount Incl. VAT");
        SettlementElement.Add(MonetarySummationElement);

        TransactionElement.Add(SettlementElement);
    end;

    local procedure AddTaxBreakdown(var SettlementElement: XmlElement; var LineBaseAmounts: Dictionary of [Text, Decimal]; var LineVATAmounts: Dictionary of [Text, Decimal]; var VATRateByKey: Dictionary of [Text, Decimal]; var VATCategoryByKey: Dictionary of [Text, Text]; InvoiceDiscountAmount: Decimal)
    var
        VATAggregationKeys: List of [Text];
        AllocatedDiscountByKey: Dictionary of [Text, Decimal];
        VATKey: Text;
        DiscountedBaseAmount: Decimal;
        DiscountedVATAmount: Decimal;
    begin
        AllocateInvoiceDiscountByVATKey(InvoiceDiscountAmount, LineBaseAmounts, AllocatedDiscountByKey);

        VATAggregationKeys := LineBaseAmounts.Keys();

        foreach VATKey in VATAggregationKeys do
            if AllocatedDiscountByKey.ContainsKey(VATKey) then begin
                DiscountedBaseAmount := LineBaseAmounts.Get(VATKey) - AllocatedDiscountByKey.Get(VATKey);
                DiscountedVATAmount := LineVATAmounts.Get(VATKey) - Round(AllocatedDiscountByKey.Get(VATKey) * VATRateByKey.Get(VATKey) / 100, 0.01);

                InsertTaxElement(
                  SettlementElement, FormatDecimalValue(DiscountedVATAmount),
                  FormatDecimalValue(DiscountedBaseAmount), VATCategoryByKey.Get(VATKey), FormatVATRate(VATRateByKey.Get(VATKey)),
                  VATRateByKey.Get(VATKey) = 0);
            end else
                InsertTaxElement(
                  SettlementElement, FormatDecimalValue(LineVATAmounts.Get(VATKey)),
                  FormatDecimalValue(LineBaseAmounts.Get(VATKey)), VATCategoryByKey.Get(VATKey), FormatVATRate(VATRateByKey.Get(VATKey)),
                  VATRateByKey.Get(VATKey) = 0);
    end;

    local procedure AddDocumentLevelAllowances(var SettlementElement: XmlElement; var LineBaseAmounts: Dictionary of [Text, Decimal]; var VATRateByKey: Dictionary of [Text, Decimal]; var VATCategoryByKey: Dictionary of [Text, Text]; InvoiceDiscountAmount: Decimal)
    var
        AllocatedDiscountByKey: Dictionary of [Text, Decimal];
        VATAggregationKeys: List of [Text];
        VATKey: Text;
    begin
        if InvoiceDiscountAmount = 0 then
            exit;

        AllocateInvoiceDiscountByVATKey(InvoiceDiscountAmount, LineBaseAmounts, AllocatedDiscountByKey);

        VATAggregationKeys := LineBaseAmounts.Keys();
        foreach VATKey in VATAggregationKeys do
            if AllocatedDiscountByKey.ContainsKey(VATKey) then
                if AllocatedDiscountByKey.Get(VATKey) <> 0 then
                    InsertAllowanceElement(
                      SettlementElement,
                      AllocatedDiscountByKey.Get(VATKey),
                      VATCategoryByKey.Get(VATKey),
                      FormatVATRate(VATRateByKey.Get(VATKey)));
    end;

    local procedure BuildVATAggregationData(var SourceDocumentLines: RecordRef; var LineBaseAmounts: Dictionary of [Text, Decimal]; var LineVATAmounts: Dictionary of [Text, Decimal]; var VATRateByKey: Dictionary of [Text, Decimal]; var VATCategoryByKey: Dictionary of [Text, Text])
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        VATPercentFieldRef: FieldRef;
        TaxCategoryFieldRef: FieldRef;
        VATBusPostingGroupFieldRef: FieldRef;
        VATProdPostingGroupFieldRef: FieldRef;
        VATAggregationKey: Text;
        VATCategoryCode: Text;
        TaxCategory: Code[10];
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
        VATPercent: Decimal;
        VATAmount: Decimal;
        BaseAmount: Decimal;
    begin
        if SourceDocumentLines.FindSet() then
            repeat
                if FREDocHelpers.FindFieldByName(SourceDocumentLines, 'VAT %', VATPercentFieldRef) then begin
                    VATPercent := VATPercentFieldRef.Value();
                    BaseAmount := GetLineAmountBeforeInvoiceDiscount(SourceDocumentLines);

                    if FREDocHelpers.FindFieldByName(SourceDocumentLines, 'Tax Category', TaxCategoryFieldRef) then
                        TaxCategory := TaxCategoryFieldRef.Value()
                    else
                        Clear(TaxCategory);

                    if FREDocHelpers.FindFieldByName(SourceDocumentLines, 'VAT Bus. Posting Group', VATBusPostingGroupFieldRef) then
                        VATBusPostingGroup := VATBusPostingGroupFieldRef.Value()
                    else
                        Clear(VATBusPostingGroup);

                    if FREDocHelpers.FindFieldByName(SourceDocumentLines, 'VAT Prod. Posting Group', VATProdPostingGroupFieldRef) then
                        VATProdPostingGroup := VATProdPostingGroupFieldRef.Value()
                    else
                        Clear(VATProdPostingGroup);

                    VATCategoryCode := GetVATCategoryCode(TaxCategory, VATBusPostingGroup, VATProdPostingGroup);
                    VATAggregationKey := GetVATAggregationKey(VATPercent, VATCategoryCode);
                    VATAmount := Round(BaseAmount * VATPercent / 100, 0.01);

                    AddAmountForVATKey(VATAggregationKey, BaseAmount, LineBaseAmounts);
                    AddAmountForVATKey(VATAggregationKey, VATAmount, LineVATAmounts);

                    if not VATRateByKey.ContainsKey(VATAggregationKey) then
                        VATRateByKey.Add(VATAggregationKey, VATPercent);
                    if not VATCategoryByKey.ContainsKey(VATAggregationKey) then
                        VATCategoryByKey.Add(VATAggregationKey, VATCategoryCode);
                end;
            until SourceDocumentLines.Next() = 0;
    end;

    local procedure AllocateInvoiceDiscountByVATKey(InvoiceDiscountAmount: Decimal; var LineBaseAmounts: Dictionary of [Text, Decimal]; var AllocatedDiscountByKey: Dictionary of [Text, Decimal])
    var
        VATAggregationKeys: List of [Text];
        VATKey: Text;
        TotalBaseAmount: Decimal;
        TotalAllocatedDiscountAmount: Decimal;
        LargestBaseAmount: Decimal;
        LargestBaseKey: Text;
        AllocatedDiscountAmount: Decimal;
    begin
        if InvoiceDiscountAmount = 0 then
            exit;

        VATAggregationKeys := LineBaseAmounts.Keys();
        foreach VATKey in VATAggregationKeys do begin
            TotalBaseAmount += LineBaseAmounts.Get(VATKey);
            if LargestBaseKey = '' then begin
                LargestBaseAmount := LineBaseAmounts.Get(VATKey);
                LargestBaseKey := VATKey;
            end else
                if (LineBaseAmounts.Get(VATKey) > LargestBaseAmount) or
                   ((LineBaseAmounts.Get(VATKey) = LargestBaseAmount) and (VATKey < LargestBaseKey))
                then begin
                    LargestBaseAmount := LineBaseAmounts.Get(VATKey);
                    LargestBaseKey := VATKey;
                end;
        end;

        if TotalBaseAmount = 0 then
            exit;

        foreach VATKey in VATAggregationKeys do begin
            AllocatedDiscountAmount := Round(InvoiceDiscountAmount * LineBaseAmounts.Get(VATKey) / TotalBaseAmount, 0.01);
            AllocatedDiscountByKey.Add(VATKey, AllocatedDiscountAmount);
            TotalAllocatedDiscountAmount += AllocatedDiscountAmount;
        end;

        if LargestBaseKey <> '' then
            AllocatedDiscountByKey.Set(
              LargestBaseKey,
              AllocatedDiscountByKey.Get(LargestBaseKey) + (InvoiceDiscountAmount - TotalAllocatedDiscountAmount));
    end;

    local procedure InsertAllowanceElement(var SettlementElement: XmlElement; AllowanceAmount: Decimal; CategoryCode: Text; RateApplicablePercent: Text)
    var
        AllowanceChargeElement: XmlElement;
        ChargeIndicatorElement: XmlElement;
        CategoryTradeTaxElement: XmlElement;
        AllowanceReasonLbl: Label 'Invoice discount', Locked = true;
    begin
        AllowanceChargeElement := XmlElement.Create('SpecifiedTradeAllowanceCharge', RamNamespaceTok);

        ChargeIndicatorElement := XmlElement.Create('ChargeIndicator', RamNamespaceTok);
        ChargeIndicatorElement.Add(XmlElement.Create('Indicator', UdtNamespaceTok, 'false'));
        AllowanceChargeElement.Add(ChargeIndicatorElement);

        // In CII, amount terms must be emitted before reason metadata.
        AddAmountElement(AllowanceChargeElement, 'ActualAmount', AllowanceAmount);

        AllowanceChargeElement.Add(XmlElement.Create('Reason', RamNamespaceTok, AllowanceReasonLbl));

        CategoryTradeTaxElement := XmlElement.Create('CategoryTradeTax', RamNamespaceTok);
        CategoryTradeTaxElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, 'VAT'));
        CategoryTradeTaxElement.Add(XmlElement.Create('CategoryCode', RamNamespaceTok, CategoryCode));
        CategoryTradeTaxElement.Add(XmlElement.Create('RateApplicablePercent', RamNamespaceTok, RateApplicablePercent));
        AllowanceChargeElement.Add(CategoryTradeTaxElement);

        SettlementElement.Add(AllowanceChargeElement);
    end;

    local procedure InsertLineAllowanceElement(var LineSettlementElement: XmlElement; AllowanceAmount: Decimal)
    var
        AllowanceChargeElement: XmlElement;
        ChargeIndicatorElement: XmlElement;
        LineDiscountLbl: Label 'Line Discount', Locked = true;
    begin
        AllowanceChargeElement := XmlElement.Create('SpecifiedTradeAllowanceCharge', RamNamespaceTok);

        ChargeIndicatorElement := XmlElement.Create('ChargeIndicator', RamNamespaceTok);
        ChargeIndicatorElement.Add(XmlElement.Create('Indicator', UdtNamespaceTok, 'false'));
        AllowanceChargeElement.Add(ChargeIndicatorElement);

        AddAmountElement(AllowanceChargeElement, 'ActualAmount', AllowanceAmount);
        AllowanceChargeElement.Add(XmlElement.Create('Reason', RamNamespaceTok, LineDiscountLbl));

        LineSettlementElement.Add(AllowanceChargeElement);
    end;

    local procedure InsertTaxElement(var SettlementElement: XmlElement; CalculatedAmount: Text; BasisAmount: Text; CategoryCode: Text; RateApplicablePercent: Text; ZeroVAT: Boolean)
    var
        TradeTaxElement: XmlElement;
    begin
        TradeTaxElement := XmlElement.Create('ApplicableTradeTax', RamNamespaceTok);
        TradeTaxElement.Add(XmlElement.Create('CalculatedAmount', RamNamespaceTok, CalculatedAmount));
        TradeTaxElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, 'VAT'));
        if ZeroVAT then
            TradeTaxElement.Add(XmlElement.Create('ExemptionReason', RamNamespaceTok, 'VATEX-EU-O'));
        TradeTaxElement.Add(XmlElement.Create('BasisAmount', RamNamespaceTok, BasisAmount));
        TradeTaxElement.Add(XmlElement.Create('CategoryCode', RamNamespaceTok, CategoryCode));
        TradeTaxElement.Add(XmlElement.Create('RateApplicablePercent', RamNamespaceTok, RateApplicablePercent));
        SettlementElement.Add(TradeTaxElement);
    end;

    local procedure AddLineItems(var TransactionElement: XmlElement; var SourceDocumentLines: RecordRef)
    var
        LineCounter: Integer;
    begin
        LineCounter := 0;
        if SourceDocumentLines.FindSet() then
            repeat
                LineCounter += 1;
                AddLineItem(TransactionElement, SourceDocumentLines, LineCounter);
            until SourceDocumentLines.Next() = 0;
    end;

    local procedure AddLineItem(var TransactionElement: XmlElement; var SourceDocumentLine: RecordRef; LineCounter: Integer)
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        FieldRefVar: FieldRef;
        LineItemElement: XmlElement;
        LineDocElement: XmlElement;
        ProductElement: XmlElement;
        LineAgreementElement: XmlElement;
        GrossPriceElement: XmlElement;
        NetPriceElement: XmlElement;
        LineDeliveryElement: XmlElement;
        BilledQtyElement: XmlElement;
        LineSettlementElement: XmlElement;
        LineTaxElement: XmlElement;
        LineSummationElement: XmlElement;
        Description: Text;
        UnitOfMeasure: Text;
        VATCategoryCode: Text;
        TaxCategory: Code[10];
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
        Quantity: Decimal;
        GrossUnitPrice: Decimal;
        NetUnitPrice: Decimal;
        LineAmount: Decimal;
        LineDiscountAmount: Decimal;
        VATPercent: Decimal;
    begin
        // BT-153 Item name
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Description', FieldRefVar) then
            Description := FieldRefVar.Value();
        if Description = '' then
            exit;

        // BT-131 Line net amount
        LineAmount := GetLineAmountBeforeInvoiceDiscount(SourceDocumentLine);

        if IsNonFinancialTextLine(SourceDocumentLine, LineAmount) then
            exit;

        // BT-129 Invoiced quantity - defaults to 1 for Reminder/FinCharge lines
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Quantity', FieldRefVar) then
            Quantity := FieldRefVar.Value()
        else
            Quantity := 1;

        // BT-146 Item net price
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Unit Price', FieldRefVar) then
            GrossUnitPrice := FieldRefVar.Value()
        else
            if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Direct Unit Cost', FieldRefVar) then
                GrossUnitPrice := FieldRefVar.Value()
            else
                GrossUnitPrice := LineAmount;

        if Quantity <> 0 then
            NetUnitPrice := LineAmount / Quantity
        else
            NetUnitPrice := LineAmount;

        // BT-130 Unit of measure code
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Unit of Measure Code', FieldRefVar) then
            UnitOfMeasure := GetUnitOfMeasureCode(FieldRefVar.Value());

        // Get VAT information
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'VAT %', FieldRefVar) then
            VATPercent := FieldRefVar.Value();
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Tax Category', FieldRefVar) then
            TaxCategory := FieldRefVar.Value();
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'VAT Bus. Posting Group', FieldRefVar) then
            VATBusPostingGroup := FieldRefVar.Value();
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'VAT Prod. Posting Group', FieldRefVar) then
            VATProdPostingGroup := FieldRefVar.Value();
        VATCategoryCode := GetVATCategoryCode(TaxCategory, VATBusPostingGroup, VATProdPostingGroup);

        // BT-136 Line discount amount
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Line Discount Amount', FieldRefVar) then
            LineDiscountAmount := FieldRefVar.Value();

        // Build line item element
        LineItemElement := XmlElement.Create('IncludedSupplyChainTradeLineItem', RamNamespaceTok);

        // BT-126 Invoice line identifier
        LineDocElement := XmlElement.Create('AssociatedDocumentLineDocument', RamNamespaceTok);
        LineDocElement.Add(XmlElement.Create('LineID', RamNamespaceTok, Format(LineCounter)));
        LineItemElement.Add(LineDocElement);

        // BT-153 Item name
        ProductElement := XmlElement.Create('SpecifiedTradeProduct', RamNamespaceTok);
        ProductElement.Add(XmlElement.Create('Name', RamNamespaceTok, Description));
        LineItemElement.Add(ProductElement);

        // BT-146 Item net price
        LineAgreementElement := XmlElement.Create('SpecifiedLineTradeAgreement', RamNamespaceTok);
        GrossPriceElement := XmlElement.Create('GrossPriceProductTradePrice', RamNamespaceTok);
        AddUnitPriceElement(GrossPriceElement, 'ChargeAmount', GrossUnitPrice);
        LineAgreementElement.Add(GrossPriceElement);
        NetPriceElement := XmlElement.Create('NetPriceProductTradePrice', RamNamespaceTok);
        AddUnitPriceElement(NetPriceElement, 'ChargeAmount', NetUnitPrice);
        LineAgreementElement.Add(NetPriceElement);
        LineItemElement.Add(LineAgreementElement);

        // BT-129/BT-130 Invoiced quantity with unit of measure
        LineDeliveryElement := XmlElement.Create('SpecifiedLineTradeDelivery', RamNamespaceTok);
        BilledQtyElement := XmlElement.Create('BilledQuantity', RamNamespaceTok, Format(Quantity, 0, 9));
        BilledQtyElement.SetAttribute('unitCode', UnitOfMeasure);
        LineDeliveryElement.Add(BilledQtyElement);
        LineItemElement.Add(LineDeliveryElement);

        // Line-level tax and monetary summation
        LineSettlementElement := XmlElement.Create('SpecifiedLineTradeSettlement', RamNamespaceTok);

        LineTaxElement := XmlElement.Create('ApplicableTradeTax', RamNamespaceTok);
        LineTaxElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, 'VAT'));
        LineTaxElement.Add(XmlElement.Create('CategoryCode', RamNamespaceTok, VATCategoryCode));
        LineTaxElement.Add(XmlElement.Create('RateApplicablePercent', RamNamespaceTok, FormatVATRate(VATPercent)));
        LineSettlementElement.Add(LineTaxElement);

        // BG-27 Line allowances (line discount)
        if LineDiscountAmount <> 0 then
            InsertLineAllowanceElement(LineSettlementElement, LineDiscountAmount);

        // BT-131 Invoice line net amount
        LineSummationElement := XmlElement.Create('SpecifiedTradeSettlementLineMonetarySummation', RamNamespaceTok);
        AddAmountElement(LineSummationElement, 'LineTotalAmount', LineAmount);
        LineSettlementElement.Add(LineSummationElement);

        LineItemElement.Add(LineSettlementElement);

        TransactionElement.Add(LineItemElement);
    end;

    local procedure InsertPaymentMeans(var ParentElement: XmlElement; CompanyBankAccountCode: Code[20])
    var
        PaymentMeansElement: XmlElement;
        PayeeAccountElement: XmlElement;
        PayeeInstitutionElement: XmlElement;
        IBAN: Text[50];
        SWIFTCode: Code[20];
    begin
        GetBankAccountPaymentDetails(CompanyBankAccountCode, IBAN, SWIFTCode);
        PaymentMeansElement := XmlElement.Create('SpecifiedTradeSettlementPaymentMeans', RamNamespaceTok);
        PaymentMeansElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, '58'));

        if IBAN <> '' then begin
            PayeeAccountElement := XmlElement.Create('PayeePartyCreditorFinancialAccount', RamNamespaceTok);
            PayeeAccountElement.Add(XmlElement.Create('IBANID', RamNamespaceTok, FormatIBAN(IBAN)));
            PaymentMeansElement.Add(PayeeAccountElement);
        end;

        if SWIFTCode <> '' then begin
            PayeeInstitutionElement := XmlElement.Create('PayeeSpecifiedCreditorFinancialInstitution', RamNamespaceTok);
            PayeeInstitutionElement.Add(XmlElement.Create('BICID', RamNamespaceTok, FormatIBAN(SWIFTCode)));
            PaymentMeansElement.Add(PayeeInstitutionElement);
        end;

        ParentElement.Add(PaymentMeansElement);
    end;

    local procedure GetBankAccountPaymentDetails(CompanyBankAccountCode: Code[20]; var IBAN: Text[50]; var SWIFTCode: Code[20])
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
    begin
        if CompanyBankAccountCode <> '' then
            BankAccount.SetLoadFields(IBAN, "SWIFT Code");
        if BankAccount.Get(CompanyBankAccountCode) then begin
            IBAN := BankAccount.IBAN;
            SWIFTCode := BankAccount."SWIFT Code";
            exit;
        end;

        CompanyInformation.Get();
        IBAN := CompanyInformation.IBAN;
        SWIFTCode := CompanyInformation."SWIFT Code";
    end;

    local procedure FormatIBAN(IBAN: Text[50]): Text[50]
    begin
        if IBAN = '' then
            exit('');
        exit(CopyStr(UpperCase(DelChr(IBAN, '=', ' ')), 1, 50));
    end;

    local procedure AddPaymentTermsDescription(var PaymentTermsElement: XmlElement; PaymentTermsCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTermsCode = '' then
            exit;
        if not PaymentTerms.Get(PaymentTermsCode) then
            exit;
        if PaymentTerms.Description <> '' then
            PaymentTermsElement.Add(XmlElement.Create('Description', RamNamespaceTok, PaymentTerms.Description));
    end;

    local procedure AddAmountForVATKey(VATAggregationKey: Text; NewAmount: Decimal; var TotalAmounts: Dictionary of [Text, Decimal])
    begin
        if not TotalAmounts.ContainsKey(VATAggregationKey) then
            TotalAmounts.Add(VATAggregationKey, NewAmount)
        else
            TotalAmounts.Set(VATAggregationKey, TotalAmounts.Get(VATAggregationKey) + NewAmount);
    end;

    local procedure GetLineAmountBeforeInvoiceDiscount(var SourceDocumentLine: RecordRef): Decimal
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        FieldRefVar: FieldRef;
    begin
        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Line Amount', FieldRefVar) then
            exit(FieldRefVar.Value());

        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Amount', FieldRefVar) then
            exit(FieldRefVar.Value());

        exit(0);
    end;

    local procedure GetLineTotalAmountBeforeInvoiceDiscount(var SourceDocumentLines: RecordRef) TotalLineAmount: Decimal
    begin
        if SourceDocumentLines.FindSet() then
            repeat
                TotalLineAmount += GetLineAmountBeforeInvoiceDiscount(SourceDocumentLines);
            until SourceDocumentLines.Next() = 0;
    end;

    local procedure IsNonFinancialTextLine(var SourceDocumentLine: RecordRef; LineAmount: Decimal): Boolean
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        FieldRefVar: FieldRef;
        LineTypeTxt: Text;
        Quantity: Decimal;
    begin
        if not FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Type', FieldRefVar) then
            exit(false);

        LineTypeTxt := DelChr(Format(FieldRefVar.Value()), '=', ' ');
        if LineTypeTxt <> '' then
            exit(false);

        if FREDocHelpers.FindFieldByName(SourceDocumentLine, 'Quantity', FieldRefVar) then
            Quantity := FieldRefVar.Value();

        exit((LineAmount = 0) and (Quantity = 0));
    end;

    local procedure GetInvoiceDiscountAmount(var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; AmountExclVAT: Decimal; LineTotalAmount: Decimal) InvoiceDiscountAmount: Decimal
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        FieldRefVar: FieldRef;
        LineDiscountAmount: Decimal;
    begin
        if FREDocHelpers.FindFieldByName(SourceDocumentHeader, 'Invoice Discount Amount', FieldRefVar) then begin
            InvoiceDiscountAmount := FieldRefVar.Value();
            if InvoiceDiscountAmount <> 0 then
                exit(InvoiceDiscountAmount);
        end;

        if FREDocHelpers.FindFieldByName(SourceDocumentHeader, 'Inv. Discount Amount', FieldRefVar) then begin
            InvoiceDiscountAmount := FieldRefVar.Value();
            if InvoiceDiscountAmount <> 0 then
                exit(InvoiceDiscountAmount);
        end;

        if LineTotalAmount <> 0 then begin
            InvoiceDiscountAmount := Round(LineTotalAmount - AmountExclVAT, 0.01);
            if InvoiceDiscountAmount <> 0 then
                exit(InvoiceDiscountAmount);
        end;

        if SourceDocumentLines.FindSet() then
            repeat
                if FREDocHelpers.FindFieldByName(SourceDocumentLines, 'Inv. Discount Amount', FieldRefVar) then begin
                    LineDiscountAmount := FieldRefVar.Value();
                    InvoiceDiscountAmount += LineDiscountAmount;
                end;
            until SourceDocumentLines.Next() = 0;

        exit(InvoiceDiscountAmount);
    end;

    local procedure GetVATAggregationKey(VATPercent: Decimal; VATCategoryCode: Text): Text
    begin
        exit(FormatVATRate(VATPercent) + '|' + VATCategoryCode);
    end;

    local procedure FormatDate(DateValue: Date): Text
    begin
        exit(Format(DateValue, 0, '<Year4><Month,2><Day,2>'));
    end;

    local procedure FormatDecimalValue(Value: Decimal): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(Format(Value, 0, TypeHelper.GetXMLAmountFormatWithTwoDecimalPlaces()));
    end;

    local procedure FormatDecimalUnlimited(Value: Decimal): Text
    begin
        exit(Format(Value, 0, 9));
    end;

    local procedure FormatVATRate(VATPercent: Decimal): Text
    begin
        exit(Format(Round(VATPercent, 0.00001), 0, 9));
    end;

    local procedure GetVATCategoryCode(TaxCategory: Code[10]; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Text
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if TaxCategory <> '' then
            exit(TaxCategory);

        VATPostingSetup.SetLoadFields("Tax Category");
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            exit('');

        exit(VATPostingSetup."Tax Category");
    end;

    local procedure AddAmountElement(var ParentElement: XmlElement; ElementName: Text; Amount: Decimal)
    var
        AmountElement: XmlElement;
    begin
        AmountElement := XmlElement.Create(ElementName, RamNamespaceTok, FormatDecimalValue(Amount));
        ParentElement.Add(AmountElement);
    end;

    local procedure AddUnitPriceElement(var ParentElement: XmlElement; ElementName: Text; UnitPrice: Decimal)
    var
        UnitPriceElement: XmlElement;
    begin
        UnitPriceElement := XmlElement.Create(ElementName, RamNamespaceTok, FormatDecimalUnlimited(UnitPrice));
        ParentElement.Add(UnitPriceElement);
    end;

    local procedure AddElementIfNotEmpty(var ParentElement: XmlElement; ElementName: Text; Value: Text)
    var
        ChildElement: XmlElement;
    begin
        if Value = '' then
            exit;

        ChildElement := XmlElement.Create(ElementName, RamNamespaceTok, Value);
        ParentElement.Add(ChildElement);
    end;

    local procedure GetInvoiceCurrencyCode(EDocument: Record "E-Document"): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if EDocument."Currency Code" <> '' then
            exit(EDocument."Currency Code");

        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure GetUnitOfMeasureCode(UnitOfMeasureCode: Code[20]): Text
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not UnitOfMeasure.Get(UnitOfMeasureCode) then
            exit(Format(UnitOfMeasureCode));
        if UnitOfMeasure."International Standard Code" <> '' then
            exit(UnitOfMeasure."International Standard Code");
        exit(UnitOfMeasureCode);
    end;

    var
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100', Locked = true;
        RamNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        UdtNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100', Locked = true;
        FacturXProfileIdTok: Label 'urn:cen.eu:en16931:2017', Locked = true;
        RecoveryCostNoteTok: Label 'Indemnité forfaitaire pour frais de recouvrement en cas de retard de paiement : 40 €', Locked = true;
        LatePaymentPenaltyNoteTok: Label 'Taux des pénalités de retard : taux directeur (BCE) majoré de 10 points', Locked = true;
        EarlyPaymentDiscountNoteTok: Label 'Pas d''escompte pour paiement anticipé', Locked = true;
}
