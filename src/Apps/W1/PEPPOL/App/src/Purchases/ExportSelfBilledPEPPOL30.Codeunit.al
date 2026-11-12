namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Utilities;
using System.Xml;

/// <summary>
/// Exports a posted purchase invoice / purchase credit memo as a self-billed Peppol BIS
/// Self-Billing 3.0 UBL Invoice (389) / CreditNote (261). The party roles are swapped versus
/// a normal sales export: the vendor is AccountingSupplierParty, our company is
/// AccountingCustomerParty. One codeunit covers both document kinds — unlike the sales side's
/// two XMLports, a DOM builder passes every element name as a runtime string, so the ~95%
/// shared party/tax/monetary body stays single-sourced; only the root element/namespace,
/// type-code element, and line container differ by kind.
/// </summary>
codeunit 37230 "Export Self-Billed PEPPOL30"
{
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        PEPPOL30: Codeunit "PEPPOL30";
        PEPPOL30Common: Codeunit "PEPPOL30 Common";
        PostedDocumentHeaderRecRef: RecordRef;
        PEPPOL30PurchaseFormat: Enum "PEPPOL 3.0 Purchase";
        SelfBilledXML: XmlDocument;
        RootNode: XmlNode;
        GeneratePDF, IsFormatSet, IsCreditMemo : Boolean;
        DocumentCurrencyCode: Text;
        CbcNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        CacNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        InvoiceNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;
        CreditNoteNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2', Locked = true;
        SelfBilledCustomizationIDTok: Label 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:selfbilling:3.0', Locked = true;
        SelfBilledInvoiceProfileIDTok: Label 'urn:fdc:peppol.eu:poacc:bis:selfbilling:3.0', Locked = true;

    /// <summary>
    /// Generates the self-billed UBL XML for a posted purchase invoice or credit memo.
    /// </summary>
    /// <param name="SourceDocumentHeader">RecordRef for "Purch. Inv. Header" or "Purch. Cr. Memo Hdr.".</param>
    procedure GenerateXML(var SourceDocumentHeader: RecordRef)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineRecRef: RecordRef;
    begin
        this.IsCreditMemo := SourceDocumentHeader.Number() = Database::"Purch. Cr. Memo Hdr.";
        // Kept as the posted RecordRef (Purch. Inv. Header / Purch. Cr. Memo Hdr.) for later use by
        // AddTaxTotal/AddLegalMonetaryTotal — they must call PEPPOL30Common with a RecordRef typed
        // to the POSTED table, not one rebuilt from the projected "Purchase Header" shim below
        // (RecordRef.GetTable derives its table number from the record's type, not its data, so a
        // RecordRef opened on the shim resolves to the live Purchase Header/ORDERS branch instead
        // of the posted-purchase branch, which then fails on an unopened line RecordRef).
        this.PostedDocumentHeaderRecRef := SourceDocumentHeader;
        this.PEPPOL30Common.ConvertPostedHeaderToPurchaseHeader(SourceDocumentHeader, PurchaseHeader);

        this.AddHeaderDataToXML(PurchaseHeader);

        case SourceDocumentHeader.Number() of
            Database::"Purch. Inv. Header":
                begin
                    PurchInvLine.SetRange("Document No.", PurchaseHeader."No.");
                    if PurchInvLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(PurchInvLine);
                            this.PEPPOL30Common.ConvertPostedLineToPurchaseLine(LineRecRef, PurchaseLine);
                            this.AddInvoiceLineToXML(PurchaseHeader, PurchaseLine);
                        until PurchInvLine.Next() = 0;
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    PurchCrMemoLine.SetRange("Document No.", PurchaseHeader."No.");
                    if PurchCrMemoLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(PurchCrMemoLine);
                            this.PEPPOL30Common.ConvertPostedLineToPurchaseLine(LineRecRef, PurchaseLine);
                            this.AddInvoiceLineToXML(PurchaseHeader, PurchaseLine);
                        until PurchCrMemoLine.Next() = 0;
                end;
        end;
    end;

    local procedure AddHeaderDataToXML(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLDocumentInfo: Interface "PEPPOL Purchase Document Info Provider";
        ChildNode: XmlNode;
        ID: Text;
        SalesOrderID: Text;
        IssueDate: Text;
        OrderTypeCode: Text;
        Note: Text;
        AccountingCost: Text;
        CustomerReference: Text;
    begin
        PEPPOLDocumentInfo := this.GetFormat();
        PEPPOLDocumentInfo.GetGeneralInfoBIS(PurchaseHeader, ID, SalesOrderID, IssueDate, OrderTypeCode, Note, this.DocumentCurrencyCode, AccountingCost, CustomerReference);

        this.InitializeXMLDocument();
        this.XMLDOMManagement.AddElement(this.RootNode, 'CustomizationID', this.SelfBilledCustomizationIDTok, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'ProfileID', this.SelfBilledInvoiceProfileIDTok, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'ID', ID, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'IssueDate', IssueDate, this.CbcNamespaceTok, ChildNode);
        if this.IsCreditMemo then
            this.XMLDOMManagement.AddElement(this.RootNode, 'CreditNoteTypeCode', this.GetSelfBilledCreditNoteTypeCode(), this.CbcNamespaceTok, ChildNode)
        else
            this.XMLDOMManagement.AddElement(this.RootNode, 'InvoiceTypeCode', this.GetSelfBilledInvoiceTypeCode(), this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'Note', Note, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'DocumentCurrencyCode', this.DocumentCurrencyCode, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'AccountingCost', AccountingCost, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'BuyerReference', CustomerReference, this.CbcNamespaceTok, ChildNode);

        if this.GeneratePDF then
            this.AddAdditionalDocumentReference(PurchaseHeader);

        this.AddAccountingSupplierParty(PurchaseHeader);
        this.AddAccountingCustomerParty(PurchaseHeader);
        this.AddDelivery(PurchaseHeader);
        this.AddPaymentTerms(PurchaseHeader);
        this.AddTaxTotal(PurchaseHeader);
        this.AddLegalMonetaryTotal(PurchaseHeader);
    end;

    local procedure InitializeXMLDocument()
    var
        RootName: Text;
        RootNamespace: Text;
        XmlNsAttr: XmlAttribute;
        RootElement: XmlElement;
    begin
        this.SelfBilledXML := XmlDocument.Create();

        if this.IsCreditMemo then begin
            RootName := 'CreditNote';
            RootNamespace := this.CreditNoteNamespaceTok;
        end else begin
            RootName := 'Invoice';
            RootNamespace := this.InvoiceNamespaceTok;
        end;

        RootElement := XmlElement.Create(RootName, RootNamespace);
        XmlNsAttr := XmlAttribute.CreateNamespaceDeclaration('cac', this.CacNamespaceTok);
        RootElement.Add(XmlNsAttr);
        XmlNsAttr := XmlAttribute.CreateNamespaceDeclaration('cbc', this.CbcNamespaceTok);
        RootElement.Add(XmlNsAttr);

        this.SelfBilledXML.Add(RootElement);
        this.RootNode := RootElement.AsXmlNode();
    end;

    /// <summary>
    /// AccountingSupplierParty = the vendor (wired by data source, not by method name — these
    /// getters were written for ORDERS' SellerSupplierParty, which is the same underlying data).
    /// </summary>
    local procedure AddAccountingSupplierParty(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLPartyInfo: Interface "PEPPOL Purchase Party Info Provider";
        SupplierNode: XmlNode;
        PartyNode: XmlNode;
        PartyNameNode: XmlNode;
        PostalAddressNode: XmlNode;
        CountryNode: XmlNode;
        PartyTaxSchemeNode: XmlNode;
        TaxSchemeNode: XmlNode;
        PartyLegalEntityNode: XmlNode;
        PartyIdentificationNode: XmlNode;
        ContactNode: XmlNode;
        ChildNode: XmlNode;
        EndpointId: Text;
        SchemeID: Text;
        SupplierName: Text;
        StreetName: Text;
        AdditionalStreetName: Text;
        CityName: Text;
        PostalZone: Text;
        CountrySubentity: Text;
        IdentificationCode: Text;
        ListID: Text;
        CompanyID: Text;
        CompanyIDSchemeID: Text;
        TaxSchemeID: Text;
        ContactName: Text;
        ContactPhone: Text;
        ContactTelefax: Text;
        ContactEmail: Text;
    begin
        this.XMLDOMManagement.AddElement(this.RootNode, 'AccountingSupplierParty', '', this.CacNamespaceTok, SupplierNode);
        this.XMLDOMManagement.AddElement(SupplierNode, 'Party', '', this.CacNamespaceTok, PartyNode);

        PEPPOLPartyInfo := this.GetFormat();
        this.PEPPOL30.GetSelfBilledSellerSupplierPartyInfo(PurchaseHeader, EndpointId, SchemeID, SupplierName);

        this.XMLDOMManagement.AddElement(PartyNode, 'EndpointID', EndpointId, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', SchemeID);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyIdentification', '', this.CacNamespaceTok, PartyIdentificationNode);
        this.XMLDOMManagement.AddElement(PartyIdentificationNode, 'ID', PurchaseHeader."Buy-from Vendor No.", this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyName', '', this.CacNamespaceTok, PartyNameNode);
        this.XMLDOMManagement.AddElement(PartyNameNode, 'Name', SupplierName, this.CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetSellerSupplierPartyPostalAddr(PurchaseHeader, StreetName, AdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);

        this.XMLDOMManagement.AddElement(PartyNode, 'PostalAddress', '', this.CacNamespaceTok, PostalAddressNode);
        this.AddNonEmptyNode(PostalAddressNode, 'StreetName', StreetName, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'AdditionalStreetName', AdditionalStreetName, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CityName', CityName, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'PostalZone', PostalZone, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CountrySubentity', CountrySubentity, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PostalAddressNode, 'Country', '', this.CacNamespaceTok, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', IdentificationCode, this.CbcNamespaceTok, ChildNode);

        this.PEPPOL30.GetSellerSupplierPartyTaxScheme(PurchaseHeader, CompanyID, CompanyIDSchemeID, TaxSchemeID);
        if CompanyID <> '' then begin
            this.XMLDOMManagement.AddElement(PartyNode, 'PartyTaxScheme', '', this.CacNamespaceTok, PartyTaxSchemeNode);
            this.XMLDOMManagement.AddElement(PartyTaxSchemeNode, 'CompanyID', CompanyID, this.CbcNamespaceTok, ChildNode);
            this.XMLDOMManagement.AddElement(PartyTaxSchemeNode, 'TaxScheme', '', this.CacNamespaceTok, TaxSchemeNode);
            this.XMLDOMManagement.AddElement(TaxSchemeNode, 'ID', TaxSchemeID, this.CbcNamespaceTok, ChildNode);
        end;

        this.XMLDOMManagement.AddElement(PartyNode, 'PartyLegalEntity', '', this.CacNamespaceTok, PartyLegalEntityNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'RegistrationName', SupplierName, this.CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetSellerSupplierPartyContact(PurchaseHeader, ContactName, ContactPhone, ContactTelefax, ContactEmail);
        if (ContactName <> '') or (ContactPhone <> '') or (ContactTelefax <> '') or (ContactEmail <> '') then begin
            this.XMLDOMManagement.AddElement(PartyNode, 'Contact', '', this.CacNamespaceTok, ContactNode);
            this.AddNonEmptyNode(ContactNode, 'Name', ContactName, this.CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telephone', ContactPhone, this.CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telefax', ContactTelefax, this.CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'ElectronicMail', ContactEmail, this.CbcNamespaceTok, ChildNode);
        end;
    end;

    /// <summary>
    /// AccountingCustomerParty = our own company (wired by data source: these "AccountingSupplierParty*"
    /// -named getters read Company Information, and the "BuyerCustomerParty*" getters already
    /// project the company as customer — reused here for the same reason ORDERS uses them).
    /// </summary>
    local procedure AddAccountingCustomerParty(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLPartyInfo: Interface "PEPPOL Purchase Party Info Provider";
        CustomerNode: XmlNode;
        PartyNode: XmlNode;
        PartyNameNode: XmlNode;
        PostalAddressNode: XmlNode;
        CountryNode: XmlNode;
        PartyTaxSchemeNode: XmlNode;
        TaxSchemeNode: XmlNode;
        PartyLegalEntityNode: XmlNode;
        RegistrationAddressNode: XmlNode;
        PartyIdentificationNode: XmlNode;
        ContactNode: XmlNode;
        ChildNode: XmlNode;
        EndpointId: Text;
        SchemeID: Text;
        CompanyName: Text;
        StreetName: Text;
        AdditionalStreetName: Text;
        CityName: Text;
        PostalZone: Text;
        CountrySubentity: Text;
        IdentificationCode: Text;
        ListID: Text;
        CompanyID: Text;
        CompanyIDSchemeID: Text;
        TaxSchemeID: Text;
        PartyLegalEntityRegName: Text;
        PartyLegalEntityCompanyID: Text;
        PartyLegalEntitySchemeID: Text;
        RegAddrCityName: Text;
        RegAddrCountryIdCode: Text;
        RegAddrCountryIdListId: Text;
        ContactName: Text;
        ContactPhone: Text;
        ContactEmail: Text;
    begin
        this.XMLDOMManagement.AddElement(this.RootNode, 'AccountingCustomerParty', '', this.CacNamespaceTok, CustomerNode);
        this.XMLDOMManagement.AddElement(CustomerNode, 'Party', '', this.CacNamespaceTok, PartyNode);

        PEPPOLPartyInfo := this.GetFormat();
        PEPPOLPartyInfo.GetAccountingSupplierPartyInfoBIS(EndpointId, SchemeID, CompanyName);

        this.XMLDOMManagement.AddElement(PartyNode, 'EndpointID', EndpointId, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', SchemeID);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyIdentification', '', this.CacNamespaceTok, PartyIdentificationNode);
        this.XMLDOMManagement.AddElement(PartyIdentificationNode, 'ID', EndpointId, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyName', '', this.CacNamespaceTok, PartyNameNode);
        this.XMLDOMManagement.AddElement(PartyNameNode, 'Name', CompanyName, this.CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetBuyerCustomerPartyPostalAddr(PurchaseHeader, StreetName, AdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);

        this.XMLDOMManagement.AddElement(PartyNode, 'PostalAddress', '', this.CacNamespaceTok, PostalAddressNode);
        this.AddNonEmptyNode(PostalAddressNode, 'StreetName', StreetName, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'AdditionalStreetName', AdditionalStreetName, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CityName', CityName, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'PostalZone', PostalZone, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CountrySubentity', CountrySubentity, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PostalAddressNode, 'Country', '', this.CacNamespaceTok, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', IdentificationCode, this.CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
        if CompanyID <> '' then begin
            this.XMLDOMManagement.AddElement(PartyNode, 'PartyTaxScheme', '', this.CacNamespaceTok, PartyTaxSchemeNode);
            this.XMLDOMManagement.AddElement(PartyTaxSchemeNode, 'CompanyID', CompanyID, this.CbcNamespaceTok, ChildNode);
            this.XMLDOMManagement.AddElement(PartyTaxSchemeNode, 'TaxScheme', '', this.CacNamespaceTok, TaxSchemeNode);
            this.XMLDOMManagement.AddElement(TaxSchemeNode, 'ID', TaxSchemeID, this.CbcNamespaceTok, ChildNode);
        end;

        PEPPOLPartyInfo.GetAccountingSupplierPartyLegalEntityBIS(PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, RegAddrCityName, RegAddrCountryIdCode, RegAddrCountryIdListId);

        this.XMLDOMManagement.AddElement(PartyNode, 'PartyLegalEntity', '', this.CacNamespaceTok, PartyLegalEntityNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'RegistrationName', PartyLegalEntityRegName, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'CompanyID', PartyLegalEntityCompanyID, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'RegistrationAddress', '', this.CacNamespaceTok, RegistrationAddressNode);
        this.AddNonEmptyNode(RegistrationAddressNode, 'CityName', RegAddrCityName, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(RegistrationAddressNode, 'Country', '', this.CacNamespaceTok, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', RegAddrCountryIdCode, this.CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetBuyerCustomerPartyContact(PurchaseHeader, ContactName, ContactPhone, ContactEmail);
        if (ContactName <> '') or (ContactPhone <> '') or (ContactEmail <> '') then begin
            this.XMLDOMManagement.AddElement(PartyNode, 'Contact', '', this.CacNamespaceTok, ContactNode);
            this.AddNonEmptyNode(ContactNode, 'Name', ContactName, this.CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telephone', ContactPhone, this.CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'ElectronicMail', ContactEmail, this.CbcNamespaceTok, ChildNode);
        end;
    end;

    local procedure AddDelivery(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLDeliveryInfo: Interface "PEPPOL Purchase Delivery Info Provider";
        DeliveryNode: XmlNode;
        DeliveryLocationNode: XmlNode;
        AddressNode: XmlNode;
        CountryNode: XmlNode;
        ChildNode: XmlNode;
        StreetName: Text;
        AdditionalStreetName: Text;
        CityName: Text;
        PostalZone: Text;
        CountrySubentity: Text;
        IdentificationCode: Text;
        ListID: Text;
    begin
        PEPPOLDeliveryInfo := this.GetFormat();
        PEPPOLDeliveryInfo.GetDeliveryAddress(PurchaseHeader, StreetName, AdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);

        this.XMLDOMManagement.AddElement(this.RootNode, 'Delivery', '', this.CacNamespaceTok, DeliveryNode);
        this.XMLDOMManagement.AddElement(DeliveryNode, 'DeliveryLocation', '', this.CacNamespaceTok, DeliveryLocationNode);
        this.XMLDOMManagement.AddElement(DeliveryLocationNode, 'Address', '', this.CacNamespaceTok, AddressNode);
        this.AddNonEmptyNode(AddressNode, 'StreetName', StreetName, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'AdditionalStreetName', AdditionalStreetName, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'CityName', CityName, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'PostalZone', PostalZone, this.CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'CountrySubentity', CountrySubentity, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(AddressNode, 'Country', '', this.CacNamespaceTok, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', IdentificationCode, this.CbcNamespaceTok, ChildNode);
    end;

    local procedure AddPaymentTerms(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLPaymentInfo: Interface "PEPPOL Purchase Payment Info Provider";
        PaymentTermsNode: XmlNode;
        ChildNode: XmlNode;
        PaymentTermsNote: Text;
    begin
        PEPPOLPaymentInfo := this.GetFormat();
        PEPPOLPaymentInfo.GetPaymentTermsInfo(PurchaseHeader, PaymentTermsNote);

        if PaymentTermsNote = '' then
            exit;

        this.XMLDOMManagement.AddElement(this.RootNode, 'PaymentTerms', '', this.CacNamespaceTok, PaymentTermsNode);
        this.AddNonEmptyNode(PaymentTermsNode, 'Note', PaymentTermsNote, this.CbcNamespaceTok, ChildNode);
    end;

    /// <summary>
    /// cac:TaxTotal/cac:TaxSubtotal — mandatory for an EN16931 Invoice (Order export never needed
    /// a tax breakdown, so the Purchase Tax Info Provider interface only exposes GetTaxTotals/
    /// GetTaxCategories, which populate VATAmtLine/VATProductPostingGroup but don't render them).
    /// The rendering methods (GetTaxTotalInfo/GetTaxSubtotalInfo) originally existed only on the
    /// Sales-typed interface; rather than fake a Sales Header for a document that is genuinely a
    /// purchase document, PEPPOL30/PEPPOL30Impl now expose Purchase-Header-typed twins
    /// (GetTaxTotalInfo/GetTaxSubtotalInfo) as concrete, non-interface methods —
    /// same escape-hatch pattern as GetSellerSupplierPartyTaxScheme (avoids a breaking change to
    /// the Extensible=true interface — see docs/self-billing-development-plan.md).
    /// GetTaxExemptionReason takes no header parameter at all, so it's reused as-is.
    /// </summary>
    local procedure AddTaxTotal(PurchaseHeader: Record "Purchase Header")
    var
        TempPurchaseLineRounding: Record "Purchase Line" temporary;
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary;
        PurchaseLineRecRef: RecordRef;
        SchemeID: Text;
        SubtotalTaxAmount: Text;
        TaxableAmount: Text;
        TaxAmount: Text;
        TaxAmountCurrencyID: Text;
        TaxCategoryPercent: Text;
        TaxExemptionReason: Text;
        TaxSubtotalCurrencyID: Text;
        TaxTotalCurrencyID: Text;
        TaxTotalTaxCategoryID: Text;
        TaxTotalTaxSchemeID: Text;
        TransactionCurrencyTaxAmount: Text;
        TransCurrTaxAmtCurrencyID: Text;
        ChildNode: XmlNode;
        TaxCategoryNode: XmlNode;
        TaxSchemeNode: XmlNode;
        TaxSubtotalNode: XmlNode;
        TaxTotalNode: XmlNode;
    begin
        this.PEPPOL30Common.GetInvoiceRoundingLine(this.PostedDocumentHeaderRecRef, TempPurchaseLineRounding, this.GetFormat());
        this.PEPPOL30Common.SetFilters(this.PostedDocumentHeaderRecRef, PurchaseLineRecRef, TempPurchaseLineRounding);
        this.PEPPOL30Common.GetTotals(this.PostedDocumentHeaderRecRef, PurchaseLineRecRef, TempVATAmtLine, TempVATProductPostingGroup, this.GetFormat());

        this.PEPPOL30.GetTaxTotalInfo(PurchaseHeader, TempVATAmtLine, TaxAmount, TaxTotalCurrencyID);
        this.XMLDOMManagement.AddElement(this.RootNode, 'TaxTotal', '', this.CacNamespaceTok, TaxTotalNode);
        this.XMLDOMManagement.AddElement(TaxTotalNode, 'TaxAmount', TaxAmount, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', TaxTotalCurrencyID);

        TempVATAmtLine.Reset();
        if TempVATAmtLine.FindSet() then
            repeat
                this.PEPPOL30.GetTaxSubtotalInfo(TempVATAmtLine, PurchaseHeader, TaxableAmount, TaxAmountCurrencyID, SubtotalTaxAmount, TaxSubtotalCurrencyID, TransactionCurrencyTaxAmount, TransCurrTaxAmtCurrencyID, TaxTotalTaxCategoryID, SchemeID, TaxCategoryPercent, TaxTotalTaxSchemeID);

                this.XMLDOMManagement.AddElement(TaxTotalNode, 'TaxSubtotal', '', this.CacNamespaceTok, TaxSubtotalNode);
                this.XMLDOMManagement.AddElement(TaxSubtotalNode, 'TaxableAmount', TaxableAmount, this.CbcNamespaceTok, ChildNode);
                this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', TaxAmountCurrencyID);
                this.XMLDOMManagement.AddElement(TaxSubtotalNode, 'TaxAmount', SubtotalTaxAmount, this.CbcNamespaceTok, ChildNode);
                this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', TaxSubtotalCurrencyID);
                this.XMLDOMManagement.AddElement(TaxSubtotalNode, 'TaxCategory', '', this.CacNamespaceTok, TaxCategoryNode);
                this.XMLDOMManagement.AddElement(TaxCategoryNode, 'ID', TaxTotalTaxCategoryID, this.CbcNamespaceTok, ChildNode);
                if SchemeID <> '' then
                    this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', SchemeID);
                this.XMLDOMManagement.AddElement(TaxCategoryNode, 'Percent', TaxCategoryPercent, this.CbcNamespaceTok, ChildNode);

                this.PEPPOL30.GetTaxExemptionReason(TempVATProductPostingGroup, TaxExemptionReason, TaxTotalTaxCategoryID);
                this.AddNonEmptyNode(TaxCategoryNode, 'TaxExemptionReason', TaxExemptionReason, this.CbcNamespaceTok, ChildNode);

                this.XMLDOMManagement.AddElement(TaxCategoryNode, 'TaxScheme', '', this.CacNamespaceTok, TaxSchemeNode);
                this.XMLDOMManagement.AddElement(TaxSchemeNode, 'ID', TaxTotalTaxSchemeID, this.CbcNamespaceTok, ChildNode);
            until TempVATAmtLine.Next() = 0;
    end;

    local procedure AddLegalMonetaryTotal(PurchaseHeader: Record "Purchase Header")
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary;
        PurchaseLineRecRef: RecordRef;
        PEPPOLMonetaryInfo: Interface "PEPPOL Purchase Monetary Info Provider";
        MonetaryTotalNode: XmlNode;
        ChildNode: XmlNode;
        LineExtensionAmount: Text;
        LegalMonetaryTotalCurrencyID: Text;
        TaxExclusiveAmount: Text;
        TaxExclusiveAmountCurrencyID: Text;
        TaxInclusiveAmount: Text;
        TaxInclusiveAmountCurrencyID: Text;
        AllowanceTotalAmount: Text;
        AllowanceTotalAmountCurrencyID: Text;
        ChargeTotalAmount: Text;
        ChargeTotalAmountCurrencyID: Text;
        PrepaidAmount: Text;
        PrepaidCurrencyID: Text;
        PayableRoundingAmount: Text;
        PayableRndingAmountCurrencyID: Text;
        PayableAmount: Text;
        PayableAmountCurrencyID: Text;
    begin
        PEPPOLMonetaryInfo := this.GetFormat();
        this.PEPPOL30Common.GetInvoiceRoundingLine(this.PostedDocumentHeaderRecRef, TempPurchaseLine, this.GetFormat());
        this.PEPPOL30Common.SetFilters(this.PostedDocumentHeaderRecRef, PurchaseLineRecRef, TempPurchaseLine);
        this.PEPPOL30Common.GetTotals(this.PostedDocumentHeaderRecRef, PurchaseLineRecRef, TempVATAmtLine, TempVATProductPostingGroup, this.GetFormat());
        PEPPOLMonetaryInfo.GetLegalMonetaryInfo(PurchaseHeader, TempPurchaseLine, TempVATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID, PrepaidAmount, PrepaidCurrencyID, PayableRoundingAmount, PayableRndingAmountCurrencyID, PayableAmount, PayableAmountCurrencyID);

        this.XMLDOMManagement.AddElement(this.RootNode, 'LegalMonetaryTotal', '', this.CacNamespaceTok, MonetaryTotalNode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'LineExtensionAmount', LineExtensionAmount, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', this.DocumentCurrencyCode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'TaxExclusiveAmount', TaxExclusiveAmount, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', this.DocumentCurrencyCode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'TaxInclusiveAmount', TaxInclusiveAmount, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', this.DocumentCurrencyCode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'PayableAmount', PayableAmount, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', this.DocumentCurrencyCode);
    end;

    local procedure AddInvoiceLineToXML(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        PEPPOLLineInfo: Interface "PEPPOL Purchase Line Info Provider";
        LineNode: XmlNode;
        ItemNode: XmlNode;
        SellersItemIdNode: XmlNode;
        StandardItemIdNode: XmlNode;
        ClassifiedTaxCategoryNode: XmlNode;
        TaxSchemeNode: XmlNode;
        PriceNode: XmlNode;
        ChildNode: XmlNode;
        LineID: Text;
        LineNote: Text;
        InvoicedQuantity: Text;
        LineExtensionAmount: Text;
        LineExtensionAmountCurrencyID: Text;
        AccountingCost: Text;
        PriceAmount: Text;
        PriceAmountCurrencyID: Text;
        BaseQuantity: Text;
        UnitCode: Text;
        Description: Text;
        Name: Text;
        SellersItemIdentificationID: Text;
        StandardItemIdentificationID: Text;
        StdItemIdIDSchemeID: Text;
        OriginCountryIdCode: Text;
        OriginCountryIdCodeListID: Text;
        ClassifiedTaxCategoryID: Text;
        ItemSchemeID: Text;
        LineTaxPercent: Text;
        ClassifiedTaxCategorySchemeID: Text;
        LineContainerName: Text;
        QuantityElementName: Text;
    begin
        PEPPOLLineInfo := this.GetFormat();
        PEPPOLLineInfo.GetLineGeneralInfo(PurchaseLine, PurchaseHeader, LineID, LineNote, InvoicedQuantity, LineExtensionAmount, LineExtensionAmountCurrencyID, AccountingCost);

        if this.IsCreditMemo then begin
            LineContainerName := 'CreditNoteLine';
            QuantityElementName := 'CreditedQuantity';
        end else begin
            LineContainerName := 'InvoiceLine';
            QuantityElementName := 'InvoicedQuantity';
        end;

        this.XMLDOMManagement.AddElement(this.RootNode, LineContainerName, '', this.CacNamespaceTok, LineNode);
        this.XMLDOMManagement.AddElement(LineNode, 'ID', LineID, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(LineNode, QuantityElementName, InvoicedQuantity, this.CbcNamespaceTok, ChildNode);

        PEPPOLLineInfo.GetLinePriceInfo(PurchaseLine, PurchaseHeader, PriceAmount, PriceAmountCurrencyID, BaseQuantity, UnitCode);

        this.XMLDOMManagement.AddAttribute(ChildNode, 'unitCode', UnitCode);
        this.XMLDOMManagement.AddElement(LineNode, 'LineExtensionAmount', LineExtensionAmount, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', LineExtensionAmountCurrencyID);

        PEPPOLLineInfo.GetLineItemInfo(PurchaseLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID, OriginCountryIdCode, OriginCountryIdCodeListID);

        this.XMLDOMManagement.AddElement(LineNode, 'Item', '', this.CacNamespaceTok, ItemNode);
        this.AddNonEmptyNode(ItemNode, 'Description', Description, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(ItemNode, 'Name', Name, this.CbcNamespaceTok, ChildNode);
        if SellersItemIdentificationID <> '' then begin
            this.XMLDOMManagement.AddElement(ItemNode, 'SellersItemIdentification', '', this.CacNamespaceTok, SellersItemIdNode);
            this.XMLDOMManagement.AddElement(SellersItemIdNode, 'ID', SellersItemIdentificationID, this.CbcNamespaceTok, ChildNode);
        end;
        if StandardItemIdentificationID <> '' then begin
            this.XMLDOMManagement.AddElement(ItemNode, 'StandardItemIdentification', '', this.CacNamespaceTok, StandardItemIdNode);
            this.XMLDOMManagement.AddElement(StandardItemIdNode, 'ID', StandardItemIdentificationID, this.CbcNamespaceTok, ChildNode);
            this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', StdItemIdIDSchemeID);
        end;

        PEPPOLLineInfo.GetLineItemClassifiedTaxCategory(PurchaseLine, ClassifiedTaxCategoryID, ItemSchemeID, LineTaxPercent, ClassifiedTaxCategorySchemeID);

        this.XMLDOMManagement.AddElement(ItemNode, 'ClassifiedTaxCategory', '', this.CacNamespaceTok, ClassifiedTaxCategoryNode);
        this.XMLDOMManagement.AddElement(ClassifiedTaxCategoryNode, 'ID', ClassifiedTaxCategoryID, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(ClassifiedTaxCategoryNode, 'Percent', LineTaxPercent, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(ClassifiedTaxCategoryNode, 'TaxScheme', '', this.CacNamespaceTok, TaxSchemeNode);
        this.XMLDOMManagement.AddElement(TaxSchemeNode, 'ID', ClassifiedTaxCategorySchemeID, this.CbcNamespaceTok, ChildNode);

        this.XMLDOMManagement.AddElement(LineNode, 'Price', '', this.CacNamespaceTok, PriceNode);
        this.XMLDOMManagement.AddElement(PriceNode, 'PriceAmount', PriceAmount, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', PriceAmountCurrencyID);
    end;

    local procedure AddAdditionalDocumentReference(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLAttachment: Interface "PEPPOL Purchase Attachment Provider";
        AdditionalDocRefNode: XmlNode;
        AttachmentNode: XmlNode;
        EmbeddedDocNode: XmlNode;
        ChildNode: XmlNode;
        AdditionalDocumentReferenceID: Text;
        AdditionalDocRefDocumentType: Text;
        URI: Text;
        Filename: Text;
        MimeCode: Text;
        EmbeddedDocumentBinaryObject: Text;
    begin
        PEPPOLAttachment := this.GetFormat();
        PEPPOLAttachment.GeneratePDFAttachmentAsAdditionalDocRef(PurchaseHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, Filename, MimeCode, EmbeddedDocumentBinaryObject);
        if EmbeddedDocumentBinaryObject = '' then
            exit;

        this.XMLDOMManagement.AddElement(this.RootNode, 'AdditionalDocumentReference', '', this.CacNamespaceTok, AdditionalDocRefNode);
        this.XMLDOMManagement.AddElement(AdditionalDocRefNode, 'ID', AdditionalDocumentReferenceID, this.CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(AdditionalDocRefNode, 'Attachment', '', this.CacNamespaceTok, AttachmentNode);
        this.XMLDOMManagement.AddElement(AttachmentNode, 'EmbeddedDocumentBinaryObject', EmbeddedDocumentBinaryObject, this.CbcNamespaceTok, EmbeddedDocNode);
        this.XMLDOMManagement.AddAttribute(EmbeddedDocNode, 'filename', Filename);
        this.XMLDOMManagement.AddAttribute(EmbeddedDocNode, 'mimeCode', MimeCode);
    end;

    local procedure AddNonEmptyNode(Node: XmlNode; NodeName: Text; NodeValue: Text; Namespace: Text; var ChildNode: XmlNode)
    begin
        if NodeValue <> '' then
            this.XMLDOMManagement.AddElement(Node, NodeName, NodeValue, Namespace, ChildNode);
    end;

    local procedure GetFormat(): Enum "PEPPOL 3.0 Purchase"
    var
        PeppolSetup: Record "PEPPOL 3.0 Setup";
    begin
        if not this.IsFormatSet then begin
            PeppolSetup.GetSetup();
            this.PEPPOL30PurchaseFormat := PeppolSetup."PEPPOL 3.0 Purchase Format";
            this.IsFormatSet := true;
        end;
        exit(this.PEPPOL30PurchaseFormat);
    end;

    local procedure GetSelfBilledInvoiceTypeCode(): Text
    begin
        exit('389');
    end;

    local procedure GetSelfBilledCreditNoteTypeCode(): Text
    begin
        exit('261');
    end;

    /// <summary>
    /// Gets the XML document as a temporary blob.
    /// </summary>
    /// <param name="TempBlob">Return value: Temp Blob codeunit containing the document.</param>
    procedure GetXML(var TempBlob: Codeunit "Temp Blob")
    begin
        this.SelfBilledXML.WriteTo(TempBlob.CreateOutStream());
    end;

    /// <summary>
    /// Controls whether a PDF document should be generated and included as an additional document reference.
    /// </summary>
    /// <param name="GeneratePDFValue">If true, generates a PDF based on Report Selection settings.</param>
    procedure SetGeneratePDF(GeneratePDFValue: Boolean)
    begin
        this.GeneratePDF := GeneratePDFValue;
    end;

    /// <summary>
    /// Sets the PEPPOL 3.0 Purchase Format to use when exporting the document.
    /// </summary>
    /// <param name="Format">The PEPPOL 3.0 Purchase Format to use.</param>
    procedure SetFormat(Format: Enum "PEPPOL 3.0 Purchase")
    begin
        this.PEPPOL30PurchaseFormat := Format;
        this.IsFormatSet := true;
    end;
}
