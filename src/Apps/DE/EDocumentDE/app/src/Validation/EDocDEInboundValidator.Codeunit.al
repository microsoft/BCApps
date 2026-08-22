// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

codeunit 11042 "E-Doc. DE Inbound Validator"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        InconsistentValuesErr: Label '%1 is violated. %2', Comment = '%1 = EN 16931 rule identifier, %2 = rule description';
        InvalidBusinessTermErr: Label '%1 has an invalid value. %2', Comment = '%1 = EN 16931 business term identifier, %2 = field description';
        MissingBusinessTermErr: Label '%1 is mandatory. %2', Comment = '%1 = EN 16931 business term identifier, %2 = field description';

    internal procedure ValidateUBL(var EDocument: Record "E-Document"; UBLDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPrefix: Text)
    var
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        DocumentPath: Text;
        LineElement: Text;
        QuantityElement: Text;
    begin
        DocumentPath := '/' + DocumentPrefix;

        RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cbc:CustomizationID', 'BT-24', 'Specification identifier');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cbc:ID', 'BT-1', 'Invoice number');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cbc:IssueDate', 'BT-2', 'Invoice issue date');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cbc:DocumentCurrencyCode', 'BT-5', 'Invoice currency code');

        case DocumentPrefix of
            'inv:Invoice':
                begin
                    RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cbc:InvoiceTypeCode', 'BT-3', 'Invoice type code');
                    LineElement := 'cac:InvoiceLine';
                    QuantityElement := 'cbc:InvoicedQuantity';
                end;
            'cn:CreditNote':
                begin
                    RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cbc:CreditNoteTypeCode', 'BT-3', 'Invoice type code');
                    LineElement := 'cac:CreditNoteLine';
                    QuantityElement := 'cbc:CreditedQuantity';
                end;
        end;

        ValidateUBLParties(EDocument, UBLDocument, XmlNamespaces, DocumentPath);
        ValidateUBLLines(EDocument, UBLDocument, XmlNamespaces, DocumentPath, LineElement, QuantityElement);
        ValidateUBLVATAndTotals(EDocument, UBLDocument, XmlNamespaces, DocumentPath);
        ValidateUBLArithmetic(EDocument, UBLDocument, XmlNamespaces, DocumentPath, LineElement);
        ValidateXRechnungFields(EDocument, UBLDocument, XmlNamespaces, DocumentPath);

        EDocumentErrorHelper.ThrowIfHasErrors(EDocument);
    end;

    internal procedure ValidateCII(var EDocument: Record "E-Document"; CIIDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager)
    var
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        AgreementPath: Text;
        SettlementPath: Text;
    begin
        AgreementPath := '//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement';
        SettlementPath := '//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement';

        RequireValue(EDocument, CIIDocument, XmlNamespaces, '//rsm:ExchangedDocumentContext/ram:GuidelineSpecifiedDocumentContextParameter/ram:ID', 'BT-24', 'Specification identifier');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, '//rsm:ExchangedDocument/ram:ID', 'BT-1', 'Invoice number');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString', 'BT-2', 'Invoice issue date');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, '//rsm:ExchangedDocument/ram:TypeCode', 'BT-3', 'Invoice type code');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, SettlementPath + '/ram:InvoiceCurrencyCode', 'BT-5', 'Invoice currency code');

        ValidateCIIParties(EDocument, CIIDocument, XmlNamespaces, AgreementPath);
        ValidateCIILines(EDocument, CIIDocument, XmlNamespaces);
        ValidateCIIVATAndTotals(EDocument, CIIDocument, XmlNamespaces, SettlementPath);
        ValidateCIIArithmetic(EDocument, CIIDocument, XmlNamespaces, SettlementPath);
        ValidateXRechnungCIIFields(EDocument, CIIDocument, XmlNamespaces, AgreementPath);

        EDocumentErrorHelper.ThrowIfHasErrors(EDocument);
    end;

    local procedure ValidateCIIArithmetic(var EDocument: Record "E-Document"; CIIDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; SettlementPath: Text)
    var
        SummationPath: Text;
        Amount: Decimal;
        Charges: Decimal;
        InvoiceTotalVAT: Decimal;
        InvoiceTotalWithVAT: Decimal;
        InvoiceTotalWithoutVAT: Decimal;
        InvoiceLineNetTotal: Decimal;
        Allowances: Decimal;
        PaidAmount: Decimal;
        PayableAmount: Decimal;
        RoundingAmount: Decimal;
        VATBreakdownTotal: Decimal;
    begin
        SummationPath := SettlementPath + '/ram:SpecifiedTradeSettlementHeaderMonetarySummation';
        if TrySumDecimals(CIIDocument, XmlNamespaces, '//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount', InvoiceLineNetTotal) and
           TryGetDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:LineTotalAmount', Amount)
        then
            CheckEqual(EDocument, InvoiceLineNetTotal, Amount, 'BR-CO-10', 'The invoice line net total must equal the sum of invoice line net amounts.');

        if TryGetDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:LineTotalAmount', InvoiceLineNetTotal) and
           TrySumOptionalDecimals(CIIDocument, XmlNamespaces, SettlementPath + '/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator = ''false'']/ram:ActualAmount', Allowances) and
           TrySumOptionalDecimals(CIIDocument, XmlNamespaces, SettlementPath + '/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator = ''true'']/ram:ActualAmount', Charges) and
           TryGetDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:TaxBasisTotalAmount', InvoiceTotalWithoutVAT)
        then
            CheckEqual(EDocument, InvoiceLineNetTotal - Allowances + Charges, InvoiceTotalWithoutVAT, 'BR-CO-13', 'The invoice total without VAT must equal line net total minus allowances plus charges.');

        if TrySumDecimals(CIIDocument, XmlNamespaces, SettlementPath + '/ram:ApplicableTradeTax/ram:CalculatedAmount', VATBreakdownTotal) and
           TryGetDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:TaxTotalAmount', InvoiceTotalVAT)
        then
            CheckEqual(EDocument, VATBreakdownTotal, InvoiceTotalVAT, 'BR-CO-14', 'The invoice VAT total must equal the sum of VAT breakdown amounts.');

        if TryGetDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:TaxBasisTotalAmount', InvoiceTotalWithoutVAT) and
           TryGetDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:TaxTotalAmount', InvoiceTotalVAT) and
           TryGetDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:GrandTotalAmount', InvoiceTotalWithVAT)
        then
            CheckEqual(EDocument, InvoiceTotalWithoutVAT + InvoiceTotalVAT, InvoiceTotalWithVAT, 'BR-CO-15', 'The invoice total with VAT must equal the invoice total without VAT plus VAT.');

        if TryGetDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:GrandTotalAmount', InvoiceTotalWithVAT) and
           TryGetOptionalDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:TotalPrepaidAmount', PaidAmount) and
           TryGetOptionalDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:RoundingAmount', RoundingAmount) and
           TryGetDecimal(CIIDocument, XmlNamespaces, SummationPath + '/ram:DuePayableAmount', PayableAmount)
        then
            CheckEqual(EDocument, InvoiceTotalWithVAT - PaidAmount + RoundingAmount, PayableAmount, 'BR-CO-16', 'The amount due must equal the invoice total with VAT minus paid amount plus rounding.');
    end;

    local procedure ValidateCIIParties(var EDocument: Record "E-Document"; CIIDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; AgreementPath: Text)
    var
        BuyerPath: Text;
        SellerPath: Text;
    begin
        SellerPath := AgreementPath + '/ram:SellerTradeParty';
        BuyerPath := AgreementPath + '/ram:BuyerTradeParty';

        RequireValue(EDocument, CIIDocument, XmlNamespaces, SellerPath + '/ram:Name', 'BT-27', 'Seller name');
        RequireAnyValue(EDocument, CIIDocument, XmlNamespaces, SellerPath + '/ram:ID', SellerPath + '/ram:SpecifiedLegalOrganization/ram:ID', SellerPath + '/ram:SpecifiedTaxRegistration/ram:ID', 'BT-29/BT-30/BT-31', 'Seller identifier');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, SellerPath + '/ram:PostalTradeAddress/ram:CityName', 'BT-37', 'Seller city');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, SellerPath + '/ram:PostalTradeAddress/ram:PostcodeCode', 'BT-38', 'Seller post code');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, SellerPath + '/ram:PostalTradeAddress/ram:CountryID', 'BT-40', 'Seller country code');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, BuyerPath + '/ram:Name', 'BT-44', 'Buyer name');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, BuyerPath + '/ram:PostalTradeAddress/ram:CityName', 'BT-52', 'Buyer city');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, BuyerPath + '/ram:PostalTradeAddress/ram:PostcodeCode', 'BT-53', 'Buyer post code');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, BuyerPath + '/ram:PostalTradeAddress/ram:CountryID', 'BT-55', 'Buyer country code');
    end;

    local procedure ValidateCIILines(var EDocument: Record "E-Document"; CIIDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager)
    var
        LineNodes: XmlNodeList;
        IndexedLinePath: Text;
        LinePath: Text;
        LineIndex: Integer;
    begin
        LinePath := '//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem';
        if not CIIDocument.SelectNodes(LinePath, XmlNamespaces, LineNodes) or (LineNodes.Count() = 0) then begin
            LogMissingBusinessTerm(EDocument, 'BG-25', 'At least one invoice line');
            exit;
        end;

        for LineIndex := 1 to LineNodes.Count() do begin
            IndexedLinePath := '(' + LinePath + ')[' + Format(LineIndex, 0, 9) + ']';
            RequireValue(EDocument, CIIDocument, XmlNamespaces, IndexedLinePath + '/ram:AssociatedDocumentLineDocument/ram:LineID', 'BT-126', 'Invoice line identifier');
            RequireDecimal(EDocument, CIIDocument, XmlNamespaces, IndexedLinePath + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity', 'BT-129', 'Invoiced quantity');
            RequireAttribute(EDocument, CIIDocument, XmlNamespaces, IndexedLinePath + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode', 'BT-130', 'Invoiced quantity unit of measure');
            RequireDecimal(EDocument, CIIDocument, XmlNamespaces, IndexedLinePath + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount', 'BT-131', 'Invoice line net amount');
            RequireDecimal(EDocument, CIIDocument, XmlNamespaces, IndexedLinePath + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount', 'BT-146', 'Item net price');
            RequireValue(EDocument, CIIDocument, XmlNamespaces, IndexedLinePath + '/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode', 'BT-151', 'Invoiced item VAT category code');
            RequireValue(EDocument, CIIDocument, XmlNamespaces, IndexedLinePath + '/ram:SpecifiedTradeProduct/ram:Name', 'BT-153', 'Item name');
        end;
    end;

    local procedure ValidateCIIVATAndTotals(var EDocument: Record "E-Document"; CIIDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; SettlementPath: Text)
    var
        SummationPath: Text;
        VATBreakdownNodes: XmlNodeList;
        VATBreakdownPath: Text;
        IndexedVATBreakdownPath: Text;
        VATBreakdownIndex: Integer;
    begin
        VATBreakdownPath := SettlementPath + '/ram:ApplicableTradeTax';
        SummationPath := SettlementPath + '/ram:SpecifiedTradeSettlementHeaderMonetarySummation';
        if not CIIDocument.SelectNodes(VATBreakdownPath, XmlNamespaces, VATBreakdownNodes) or (VATBreakdownNodes.Count() = 0) then
            LogMissingBusinessTerm(EDocument, 'BG-23', 'VAT breakdown')
        else
            for VATBreakdownIndex := 1 to VATBreakdownNodes.Count() do begin
                IndexedVATBreakdownPath := '(' + VATBreakdownPath + ')[' + Format(VATBreakdownIndex, 0, 9) + ']';
                RequireDecimal(EDocument, CIIDocument, XmlNamespaces, IndexedVATBreakdownPath + '/ram:BasisAmount', 'BT-116', 'VAT category taxable amount');
                RequireDecimal(EDocument, CIIDocument, XmlNamespaces, IndexedVATBreakdownPath + '/ram:CalculatedAmount', 'BT-117', 'VAT category tax amount');
                RequireValue(EDocument, CIIDocument, XmlNamespaces, IndexedVATBreakdownPath + '/ram:CategoryCode', 'BT-118', 'VAT category code');
                RequireDecimal(EDocument, CIIDocument, XmlNamespaces, IndexedVATBreakdownPath + '/ram:RateApplicablePercent', 'BT-119', 'VAT category rate');
            end;
        RequireDecimal(EDocument, CIIDocument, XmlNamespaces, SummationPath + '/ram:LineTotalAmount', 'BT-106', 'Sum of invoice line net amounts');
        RequireDecimal(EDocument, CIIDocument, XmlNamespaces, SummationPath + '/ram:TaxBasisTotalAmount', 'BT-109', 'Invoice total amount without VAT');
        RequireDecimal(EDocument, CIIDocument, XmlNamespaces, SummationPath + '/ram:TaxTotalAmount', 'BT-110', 'Invoice total VAT amount');
        RequireDecimal(EDocument, CIIDocument, XmlNamespaces, SummationPath + '/ram:GrandTotalAmount', 'BT-112', 'Invoice total amount with VAT');
        RequireDecimal(EDocument, CIIDocument, XmlNamespaces, SummationPath + '/ram:DuePayableAmount', 'BT-115', 'Amount due for payment');
    end;

    local procedure ValidateXRechnungCIIFields(var EDocument: Record "E-Document"; CIIDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; AgreementPath: Text)
    var
        GuidelineID: Text;
    begin
        GuidelineID := GetValue(CIIDocument, XmlNamespaces, '//rsm:ExchangedDocumentContext/ram:GuidelineSpecifiedDocumentContextParameter/ram:ID');
        if not LowerCase(GuidelineID).Contains('xrechnung') then
            exit;

        RequireValue(EDocument, CIIDocument, XmlNamespaces, AgreementPath + '/ram:BuyerReference', 'BT-10', 'Buyer reference');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, '//rsm:ExchangedDocumentContext/ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID', 'BT-23', 'Business process identifier');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, AgreementPath + '/ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID', 'BT-34', 'Seller electronic address');
        RequireAttribute(EDocument, CIIDocument, XmlNamespaces, AgreementPath + '/ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID', 'BT-34', 'Seller electronic address scheme');
        RequireValue(EDocument, CIIDocument, XmlNamespaces, AgreementPath + '/ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID', 'BT-49', 'Buyer electronic address');
        RequireAttribute(EDocument, CIIDocument, XmlNamespaces, AgreementPath + '/ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID', 'BT-49', 'Buyer electronic address scheme');
    end;

    local procedure ValidateUBLParties(var EDocument: Record "E-Document"; UBLDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPath: Text)
    var
        BuyerPath: Text;
        SellerPath: Text;
    begin
        SellerPath := DocumentPath + '/cac:AccountingSupplierParty/cac:Party';
        BuyerPath := DocumentPath + '/cac:AccountingCustomerParty/cac:Party';

        RequireValue(EDocument, UBLDocument, XmlNamespaces, SellerPath + '/cac:PartyName/cbc:Name', 'BT-27', 'Seller name');
        RequireAnyValue(EDocument, UBLDocument, XmlNamespaces, SellerPath + '/cac:PartyIdentification/cbc:ID', SellerPath + '/cac:PartyLegalEntity/cbc:CompanyID', SellerPath + '/cac:PartyTaxScheme/cbc:CompanyID', 'BT-29/BT-30/BT-31', 'Seller identifier');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, SellerPath + '/cac:PostalAddress/cbc:CityName', 'BT-37', 'Seller city');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, SellerPath + '/cac:PostalAddress/cbc:PostalZone', 'BT-38', 'Seller post code');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, SellerPath + '/cac:PostalAddress/cac:Country/cbc:IdentificationCode', 'BT-40', 'Seller country code');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, BuyerPath + '/cac:PartyName/cbc:Name', 'BT-44', 'Buyer name');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, BuyerPath + '/cac:PostalAddress/cbc:CityName', 'BT-52', 'Buyer city');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, BuyerPath + '/cac:PostalAddress/cbc:PostalZone', 'BT-53', 'Buyer post code');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, BuyerPath + '/cac:PostalAddress/cac:Country/cbc:IdentificationCode', 'BT-55', 'Buyer country code');
    end;

    local procedure ValidateUBLLines(var EDocument: Record "E-Document"; UBLDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPath: Text; LineElement: Text; QuantityElement: Text)
    var
        LineNodes: XmlNodeList;
        LinePath: Text;
        IndexedLinePath: Text;
        LineIndex: Integer;
    begin
        LinePath := DocumentPath + '/' + LineElement;
        if not UBLDocument.SelectNodes(LinePath, XmlNamespaces, LineNodes) or (LineNodes.Count() = 0) then begin
            LogMissingBusinessTerm(EDocument, 'BG-25', 'At least one invoice line');
            exit;
        end;

        for LineIndex := 1 to LineNodes.Count() do begin
            IndexedLinePath := '(' + LinePath + ')[' + Format(LineIndex, 0, 9) + ']';
            RequireValue(EDocument, UBLDocument, XmlNamespaces, IndexedLinePath + '/cbc:ID', 'BT-126', 'Invoice line identifier');
            RequireDecimal(EDocument, UBLDocument, XmlNamespaces, IndexedLinePath + '/' + QuantityElement, 'BT-129', 'Invoiced quantity');
            RequireAttribute(EDocument, UBLDocument, XmlNamespaces, IndexedLinePath + '/' + QuantityElement + '/@unitCode', 'BT-130', 'Invoiced quantity unit of measure');
            RequireDecimal(EDocument, UBLDocument, XmlNamespaces, IndexedLinePath + '/cbc:LineExtensionAmount', 'BT-131', 'Invoice line net amount');
            RequireDecimal(EDocument, UBLDocument, XmlNamespaces, IndexedLinePath + '/cac:Price/cbc:PriceAmount', 'BT-146', 'Item net price');
            RequireValue(EDocument, UBLDocument, XmlNamespaces, IndexedLinePath + '/cac:Item/cac:ClassifiedTaxCategory/cbc:ID', 'BT-151', 'Invoiced item VAT category code');
            RequireValue(EDocument, UBLDocument, XmlNamespaces, IndexedLinePath + '/cac:Item/cbc:Name', 'BT-153', 'Item name');
        end;
    end;

    local procedure ValidateUBLVATAndTotals(var EDocument: Record "E-Document"; UBLDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPath: Text)
    var
        VATBreakdownNodes: XmlNodeList;
        VATBreakdownPath: Text;
        IndexedVATBreakdownPath: Text;
        VATBreakdownIndex: Integer;
    begin
        VATBreakdownPath := DocumentPath + '/cac:TaxTotal/cac:TaxSubtotal';
        if not UBLDocument.SelectNodes(VATBreakdownPath, XmlNamespaces, VATBreakdownNodes) or (VATBreakdownNodes.Count() = 0) then
            LogMissingBusinessTerm(EDocument, 'BG-23', 'VAT breakdown')
        else
            for VATBreakdownIndex := 1 to VATBreakdownNodes.Count() do begin
                IndexedVATBreakdownPath := '(' + VATBreakdownPath + ')[' + Format(VATBreakdownIndex, 0, 9) + ']';
                RequireDecimal(EDocument, UBLDocument, XmlNamespaces, IndexedVATBreakdownPath + '/cbc:TaxableAmount', 'BT-116', 'VAT category taxable amount');
                RequireDecimal(EDocument, UBLDocument, XmlNamespaces, IndexedVATBreakdownPath + '/cbc:TaxAmount', 'BT-117', 'VAT category tax amount');
                RequireValue(EDocument, UBLDocument, XmlNamespaces, IndexedVATBreakdownPath + '/cac:TaxCategory/cbc:ID', 'BT-118', 'VAT category code');
                RequireDecimal(EDocument, UBLDocument, XmlNamespaces, IndexedVATBreakdownPath + '/cac:TaxCategory/cbc:Percent', 'BT-119', 'VAT category rate');
            end;
        RequireDecimal(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cac:LegalMonetaryTotal/cbc:LineExtensionAmount', 'BT-106', 'Sum of invoice line net amounts');
        RequireDecimal(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', 'BT-109', 'Invoice total amount without VAT');
        RequireDecimal(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cac:TaxTotal/cbc:TaxAmount', 'BT-110', 'Invoice total VAT amount');
        RequireDecimal(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount', 'BT-112', 'Invoice total amount with VAT');
        RequireDecimal(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cac:LegalMonetaryTotal/cbc:PayableAmount', 'BT-115', 'Amount due for payment');
    end;

    local procedure ValidateUBLArithmetic(var EDocument: Record "E-Document"; UBLDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPath: Text; LineElement: Text)
    var
        MonetaryTotalPath: Text;
        Amount: Decimal;
        Charges: Decimal;
        InvoiceTotalVAT: Decimal;
        InvoiceTotalWithVAT: Decimal;
        InvoiceTotalWithoutVAT: Decimal;
        InvoiceLineNetTotal: Decimal;
        Allowances: Decimal;
        PaidAmount: Decimal;
        PayableAmount: Decimal;
        RoundingAmount: Decimal;
        VATBreakdownTotal: Decimal;
    begin
        MonetaryTotalPath := DocumentPath + '/cac:LegalMonetaryTotal';
        if TrySumDecimals(UBLDocument, XmlNamespaces, DocumentPath + '/' + LineElement + '/cbc:LineExtensionAmount', InvoiceLineNetTotal) and
           TryGetDecimal(UBLDocument, XmlNamespaces, MonetaryTotalPath + '/cbc:LineExtensionAmount', Amount)
        then
            CheckEqual(EDocument, InvoiceLineNetTotal, Amount, 'BR-CO-10', 'The invoice line net total must equal the sum of invoice line net amounts.');

        if TryGetDecimal(UBLDocument, XmlNamespaces, MonetaryTotalPath + '/cbc:LineExtensionAmount', InvoiceLineNetTotal) and
           TrySumOptionalDecimals(UBLDocument, XmlNamespaces, DocumentPath + '/cac:AllowanceCharge[cbc:ChargeIndicator = ''false'']/cbc:Amount', Allowances) and
           TrySumOptionalDecimals(UBLDocument, XmlNamespaces, DocumentPath + '/cac:AllowanceCharge[cbc:ChargeIndicator = ''true'']/cbc:Amount', Charges) and
           TryGetDecimal(UBLDocument, XmlNamespaces, MonetaryTotalPath + '/cbc:TaxExclusiveAmount', InvoiceTotalWithoutVAT)
        then
            CheckEqual(EDocument, InvoiceLineNetTotal - Allowances + Charges, InvoiceTotalWithoutVAT, 'BR-CO-13', 'The invoice total without VAT must equal line net total minus allowances plus charges.');

        if TrySumDecimals(UBLDocument, XmlNamespaces, DocumentPath + '/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount', VATBreakdownTotal) and
           TryGetDecimal(UBLDocument, XmlNamespaces, DocumentPath + '/cac:TaxTotal/cbc:TaxAmount', InvoiceTotalVAT)
        then
            CheckEqual(EDocument, VATBreakdownTotal, InvoiceTotalVAT, 'BR-CO-14', 'The invoice VAT total must equal the sum of VAT breakdown amounts.');

        if TryGetDecimal(UBLDocument, XmlNamespaces, MonetaryTotalPath + '/cbc:TaxExclusiveAmount', InvoiceTotalWithoutVAT) and
           TryGetDecimal(UBLDocument, XmlNamespaces, DocumentPath + '/cac:TaxTotal/cbc:TaxAmount', InvoiceTotalVAT) and
           TryGetDecimal(UBLDocument, XmlNamespaces, MonetaryTotalPath + '/cbc:TaxInclusiveAmount', InvoiceTotalWithVAT)
        then
            CheckEqual(EDocument, InvoiceTotalWithoutVAT + InvoiceTotalVAT, InvoiceTotalWithVAT, 'BR-CO-15', 'The invoice total with VAT must equal the invoice total without VAT plus VAT.');

        if TryGetDecimal(UBLDocument, XmlNamespaces, MonetaryTotalPath + '/cbc:TaxInclusiveAmount', InvoiceTotalWithVAT) and
           TryGetOptionalDecimal(UBLDocument, XmlNamespaces, MonetaryTotalPath + '/cbc:PrepaidAmount', PaidAmount) and
           TryGetOptionalDecimal(UBLDocument, XmlNamespaces, MonetaryTotalPath + '/cbc:PayableRoundingAmount', RoundingAmount) and
           TryGetDecimal(UBLDocument, XmlNamespaces, MonetaryTotalPath + '/cbc:PayableAmount', PayableAmount)
        then
            CheckEqual(EDocument, InvoiceTotalWithVAT - PaidAmount + RoundingAmount, PayableAmount, 'BR-CO-16', 'The amount due must equal the invoice total with VAT minus paid amount plus rounding.');
    end;

    local procedure ValidateXRechnungFields(var EDocument: Record "E-Document"; UBLDocument: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPath: Text)
    var
        CustomizationID: Text;
    begin
        CustomizationID := GetValue(UBLDocument, XmlNamespaces, DocumentPath + '/cbc:CustomizationID');
        if not LowerCase(CustomizationID).Contains('xrechnung') then
            exit;

        RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cbc:BuyerReference', 'BT-10', 'Buyer reference');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cbc:ProfileID', 'BT-23', 'Business process identifier');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID', 'BT-34', 'Seller electronic address');
        RequireAttribute(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID', 'BT-34', 'Seller electronic address scheme');
        RequireValue(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID', 'BT-49', 'Buyer electronic address');
        RequireAttribute(EDocument, UBLDocument, XmlNamespaces, DocumentPath + '/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID', 'BT-49', 'Buyer electronic address scheme');
    end;

    local procedure RequireValue(var EDocument: Record "E-Document"; XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text; BusinessTerm: Text; Description: Text)
    begin
        if GetValue(XmlDoc, XmlNamespaces, XPath) <> '' then
            exit;

        LogMissingBusinessTerm(EDocument, BusinessTerm, Description);
    end;

    local procedure RequireDecimal(var EDocument: Record "E-Document"; XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text; BusinessTerm: Text; Description: Text)
    var
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        Value: Decimal;
        TextValue: Text;
    begin
        TextValue := GetValue(XmlDoc, XmlNamespaces, XPath);
        if TextValue = '' then begin
            LogMissingBusinessTerm(EDocument, BusinessTerm, Description);
            exit;
        end;
        if Evaluate(Value, TextValue, 9) then
            exit;

        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo(InvalidBusinessTermErr, BusinessTerm, Description));
    end;

    local procedure RequireAttribute(var EDocument: Record "E-Document"; XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text; BusinessTerm: Text; Description: Text)
    var
        XmlNode: XmlNode;
    begin
        if XmlDoc.SelectSingleNode(XPath, XmlNamespaces, XmlNode) then
            if XmlNode.AsXmlAttribute().Value().Trim() <> '' then
                exit;

        LogMissingBusinessTerm(EDocument, BusinessTerm, Description);
    end;

    local procedure RequireAnyValue(var EDocument: Record "E-Document"; XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; FirstXPath: Text; SecondXPath: Text; ThirdXPath: Text; BusinessTerm: Text; Description: Text)
    begin
        if (GetValue(XmlDoc, XmlNamespaces, FirstXPath) <> '') or
           (GetValue(XmlDoc, XmlNamespaces, SecondXPath) <> '') or
           (GetValue(XmlDoc, XmlNamespaces, ThirdXPath) <> '')
        then
            exit;

        LogMissingBusinessTerm(EDocument, BusinessTerm, Description);
    end;

    local procedure GetValue(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text): Text
    var
        XmlNode: XmlNode;
    begin
        if XmlDoc.SelectSingleNode(XPath, XmlNamespaces, XmlNode) then
            exit(XmlNode.AsXmlElement().InnerText().Trim());
    end;

    local procedure TryGetDecimal(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text; var Value: Decimal): Boolean
    var
        TextValue: Text;
    begin
        TextValue := GetValue(XmlDoc, XmlNamespaces, XPath);
        exit((TextValue <> '') and Evaluate(Value, TextValue, 9));
    end;

    local procedure TryGetOptionalDecimal(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text; var Value: Decimal): Boolean
    var
        TextValue: Text;
    begin
        TextValue := GetValue(XmlDoc, XmlNamespaces, XPath);
        if TextValue = '' then begin
            Value := 0;
            exit(true);
        end;

        exit(Evaluate(Value, TextValue, 9));
    end;

    local procedure TrySumDecimals(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text; var Total: Decimal): Boolean
    var
        XmlNode: XmlNode;
        XmlNodes: XmlNodeList;
        Value: Decimal;
        NodeIndex: Integer;
    begin
        Total := 0;
        if not XmlDoc.SelectNodes(XPath, XmlNamespaces, XmlNodes) or (XmlNodes.Count() = 0) then
            exit(false);

        for NodeIndex := 1 to XmlNodes.Count() do begin
            XmlNodes.Get(NodeIndex, XmlNode);
            if not Evaluate(Value, XmlNode.AsXmlElement().InnerText().Trim(), 9) then
                exit(false);
            Total += Value;
        end;

        exit(true);
    end;

    local procedure TrySumOptionalDecimals(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text; var Total: Decimal): Boolean
    var
        XmlNodes: XmlNodeList;
    begin
        if not XmlDoc.SelectNodes(XPath, XmlNamespaces, XmlNodes) or (XmlNodes.Count() = 0) then begin
            Total := 0;
            exit(true);
        end;

        exit(TrySumDecimals(XmlDoc, XmlNamespaces, XPath, Total));
    end;

    local procedure CheckEqual(var EDocument: Record "E-Document"; ExpectedValue: Decimal; ActualValue: Decimal; RuleID: Text; Description: Text)
    var
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin
        if Abs(ExpectedValue - ActualValue) <= 0.01 then
            exit;

        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo(InconsistentValuesErr, RuleID, Description));
    end;

    local procedure LogMissingBusinessTerm(var EDocument: Record "E-Document"; BusinessTerm: Text; Description: Text)
    var
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin

        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo(MissingBusinessTermErr, BusinessTerm, Description));
    end;
}