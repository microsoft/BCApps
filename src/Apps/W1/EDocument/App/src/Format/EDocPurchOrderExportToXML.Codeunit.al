namespace Microsoft.EServices.EDocument.Format;

using Microsoft.Purchases.Document;
using Microsoft.Peppol;
using Microsoft.Finance.VAT.Calculation;
using System.Utilities;
using System.Xml;
using Microsoft.Finance.VAT.Setup;

codeunit 50000 "E-Doc. Purchase Order To XML"
{
    TableNo = "Purchase Header";

    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        PEPPOL30PurchaseFormat: Enum "PEPPOL 3.0 Purchase Format";
        PurchaseOrderXML: XmlDocument;
        RootNode: XmlNode;
        GeneratePDF, IsFormatSet : Boolean;
        CbcNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        CacNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        OrderNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:Order-2', Locked = true;
        CustomizationIDTok: Label 'urn:fdc:peppol.eu:poacc:trns:order:3', Locked = true;
        ProfileIDTok: Label 'urn:fdc:peppol.eu:poacc:bis:ordering:3', Locked = true;
        DocumentCurrencyCode: Text;

    trigger OnRun()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        this.AddHeaderDataToXML(Rec);

        PurchaseLine.SetRange("Document Type", Rec."Document Type");
        PurchaseLine.SetRange("Document No.", Rec."No.");
        if PurchaseLine.FindSet() then
            repeat
                this.AddOrderLineToXML(Rec, PurchaseLine);
            until PurchaseLine.Next() = 0;
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
        PEPPOLDocumentInfo := GetFormat();
        PEPPOLDocumentInfo.GetGeneralInfoBIS(PurchaseHeader, ID, SalesOrderID, IssueDate, OrderTypeCode, Note, DocumentCurrencyCode, AccountingCost, CustomerReference);

        this.InitializeXMLDocument();
        this.XMLDOMManagement.AddElement(this.RootNode, 'CustomizationID', CustomizationIDTok, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'ProfileID', ProfileIDTok, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'ID', ID, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'SalesOrderID', SalesOrderID, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'IssueDate', IssueDate, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'OrderTypeCode', OrderTypeCode, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'Note', Note, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'DocumentCurrencyCode', DocumentCurrencyCode, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'CustomerReference', CustomerReference, CbcNamespaceTok, ChildNode);

        if this.GeneratePDF then
            this.AddAdditionalDocumentReference(PurchaseHeader);

        this.AddBuyerCustomerParty(PurchaseHeader);
        this.AddSellerSupplierParty(PurchaseHeader);
        this.AddDelivery(PurchaseHeader);
        this.AddPaymentTerms(PurchaseHeader);
        this.AddAnticipatedMonetaryTotal(PurchaseHeader);
    end;

    local procedure InitializeXMLDocument()
    var
        RootElement: XmlElement;
        XmlNsAttr: XmlAttribute;
    begin
        this.PurchaseOrderXML := XmlDocument.Create();

        RootElement := XmlElement.Create('Order', OrderNamespaceTok);
        XmlNsAttr := XmlAttribute.CreateNamespaceDeclaration('cac', CacNamespaceTok);
        RootElement.Add(XmlNsAttr);
        XmlNsAttr := XmlAttribute.CreateNamespaceDeclaration('cbc', CbcNamespaceTok);
        RootElement.Add(XmlNsAttr);

        this.PurchaseOrderXML.Add(RootElement);
        this.RootNode := RootElement.AsXmlNode();
    end;

    local procedure AddBuyerCustomerParty(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLPartyInfo: Interface "PEPPOL Purchase Party Info Provider";
        BuyerNode: XmlNode;
        PartyNode: XmlNode;
        PartyNameNode: XmlNode;
        PostalAddressNode: XmlNode;
        CountryNode: XmlNode;
        PartyLegalEntityNode: XmlNode;
        PartyIdentificationNode: XmlNode;
        RegistrationAddressNode: XmlNode;
        ContactNode: XmlNode;
        ChildNode: XmlNode;
        BuyerCustomerPartyEndpointId: Text;
        BuyerCustomerPartySchemeID: Text;
        BuyerCustomerPartySupplierName: Text;
        BuyerCustomerPartyStreetName: Text;
        BuyerCustomerAdditionalStreetName: Text;
        BuyerCustomerPartyCityName: Text;
        BuyerCustomerPartyPostalZone: Text;
        BuyerCustomerPartyCountrySubentity: Text;
        BuyerCustomerPartyIdentificationCode: Text;
        ListID: Text;
        BuyerCustomerPartyPartyLegalEntityRegName: Text;
        BuyerCustomerPartyPartyLegalEntityCompanyID: Text;
        BuyerCustomerPartyPartyLegalEntitySchemeID: Text;
        BuyerCustomerPartySupplierRegAddrCityName: Text;
        BuyerCustomerPartySupplierRegAddrCountryIdCode: Text;
        BuyerCustomerPartySupplRegAddrCountryIdListId: Text;
        BuyerCustomerPartyContactName: Text;
        BuyerCustomerPartyContactTelephone: Text;
        BuyerCustomerPartyContactElectronicMail: Text;
    begin
        this.XMLDOMManagement.AddElement(this.RootNode, 'BuyerCustomerParty', '', CacNamespaceTok, BuyerNode);
        this.XMLDOMManagement.AddElement(BuyerNode, 'Party', '', CacNamespaceTok, PartyNode);

        PEPPOLPartyInfo := GetFormat();
        PEPPOLPartyInfo.GetAccountingSupplierPartyInfoBIS(BuyerCustomerPartyEndpointId, BuyerCustomerPartySchemeID, BuyerCustomerPartySupplierName);

        this.XMLDOMManagement.AddElement(PartyNode, 'EndpointID', BuyerCustomerPartyEndpointId, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', BuyerCustomerPartySchemeID);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyIdentification', '', CacNamespaceTok, PartyIdentificationNode);
        this.XMLDOMManagement.AddElement(PartyIdentificationNode, 'ID', BuyerCustomerPartyEndpointId, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyName', '', CacNamespaceTok, PartyNameNode);
        this.XMLDOMManagement.AddElement(PartyNameNode, 'Name', BuyerCustomerPartySupplierName, CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetBuyerCustomerPartyPostalAddr(PurchaseHeader, BuyerCustomerPartyStreetName, BuyerCustomerAdditionalStreetName, BuyerCustomerPartyCityName, BuyerCustomerPartyPostalZone, BuyerCustomerPartyCountrySubentity, BuyerCustomerPartyIdentificationCode, ListID);

        this.XMLDOMManagement.AddElement(PartyNode, 'PostalAddress', '', CacNamespaceTok, PostalAddressNode);
        this.AddNonEmptyNode(PostalAddressNode, 'StreetName', BuyerCustomerPartyStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'AdditionalStreetName', BuyerCustomerAdditionalStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CityName', BuyerCustomerPartyCityName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'PostalZone', BuyerCustomerPartyPostalZone, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CountrySubentity', BuyerCustomerPartyCountrySubentity, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PostalAddressNode, 'Country', '', CacNamespaceTok, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', BuyerCustomerPartyIdentificationCode, CbcNamespaceTok, ChildNode);
        this.AddPartyTaxScheme(PartyNode);

        PEPPOLPartyInfo.GetAccountingSupplierPartyLegalEntityBIS(BuyerCustomerPartyPartyLegalEntityRegName, BuyerCustomerPartyPartyLegalEntityCompanyID, BuyerCustomerPartyPartyLegalEntitySchemeID, BuyerCustomerPartySupplierRegAddrCityName, BuyerCustomerPartySupplierRegAddrCountryIdCode, BuyerCustomerPartySupplRegAddrCountryIdListId);

        this.XMLDOMManagement.AddElement(PartyNode, 'PartyLegalEntity', '', CacNamespaceTok, PartyLegalEntityNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'RegistrationName', BuyerCustomerPartyPartyLegalEntityRegName, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'CompanyID', BuyerCustomerPartyPartyLegalEntityCompanyID, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'RegistrationAddress', '', CacNamespaceTok, RegistrationAddressNode);
        this.AddNonEmptyNode(RegistrationAddressNode, 'CityName', BuyerCustomerPartySupplierRegAddrCityName, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(RegistrationAddressNode, 'Country', '', CacNamespaceTok, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', BuyerCustomerPartySupplierRegAddrCountryIdCode, CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetBuyerCustomerPartyContact(PurchaseHeader, BuyerCustomerPartyContactName, BuyerCustomerPartyContactTelephone, BuyerCustomerPartyContactElectronicMail);
        if (BuyerCustomerPartyContactName <> '') or (BuyerCustomerPartyContactTelephone <> '') or (BuyerCustomerPartyContactElectronicMail <> '') then begin
            this.XMLDOMManagement.AddElement(PartyNode, 'Contact', '', CacNamespaceTok, ContactNode);
            this.AddNonEmptyNode(ContactNode, 'Name', BuyerCustomerPartyContactName, CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telephone', BuyerCustomerPartyContactTelephone, CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'ElectronicMail', BuyerCustomerPartyContactElectronicMail, CbcNamespaceTok, ChildNode);
        end;
    end;

    local procedure AddSellerSupplierParty(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLPartyInfo: Interface "PEPPOL Purchase Party Info Provider";
        SellerNode: XmlNode;
        PartyNode: XmlNode;
        PartyNameNode: XmlNode;
        PostalAddressNode: XmlNode;
        CountryNode: XmlNode;
        PartyLegalEntityNode: XmlNode;
        PartyIdentificationNode: XmlNode;
        ContactNode: XmlNode;
        ChildNode: XmlNode;
        SellerSupplierPartyEndpointId: Text;
        SellerSupplierPartySchemeID: Text;
        SellerSupplierPartySupplierName: Text;
        SellerSupplierStreetName: Text;
        SellerSupplierAdditionalStreetName: Text;
        SellerSupplierPartyCityName: Text;
        SellerSupplierPartyPostalZone: Text;
        SellerSupplierPartyCountrySubentity: Text;
        SellerSupplierPartyIdentificationCode: Text;
        ListID: Text;
        SellerSupplierPartyContactName: Text;
        SellerSupplierPartyContactTelephone: Text;
        SellerSupplierPartyContactTelefax: Text;
        SellerSupplierPartyContactElectronicMail: Text;
    begin
        this.XMLDOMManagement.AddElement(this.RootNode, 'SellerSupplierParty', '', CacNamespaceTok, SellerNode);
        this.XMLDOMManagement.AddElement(SellerNode, 'Party', '', CacNamespaceTok, PartyNode);

        PEPPOLPartyInfo := GetFormat();
        PEPPOLPartyInfo.GetSellerSupplierPartyInfoBIS(PurchaseHeader, SellerSupplierPartyEndpointId, SellerSupplierPartySchemeID, SellerSupplierPartySupplierName);

        this.XMLDOMManagement.AddElement(PartyNode, 'EndpointID', SellerSupplierPartyEndpointId, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', SellerSupplierPartySchemeID);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyIdentification', '', CacNamespaceTok, PartyIdentificationNode);
        this.XMLDOMManagement.AddElement(PartyIdentificationNode, 'ID', PurchaseHeader."Buy-from Vendor No.", CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyName', '', CacNamespaceTok, PartyNameNode);
        this.XMLDOMManagement.AddElement(PartyNameNode, 'Name', SellerSupplierPartySupplierName, CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetSellerSupplierPartyPostalAddr(PurchaseHeader, SellerSupplierStreetName, SellerSupplierAdditionalStreetName, SellerSupplierPartyCityName, SellerSupplierPartyPostalZone, SellerSupplierPartyCountrySubentity, SellerSupplierPartyIdentificationCode, ListID);

        this.XMLDOMManagement.AddElement(PartyNode, 'PostalAddress', '', CacNamespaceTok, PostalAddressNode);
        this.AddNonEmptyNode(PostalAddressNode, 'StreetName', SellerSupplierStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'AdditionalStreetName', SellerSupplierAdditionalStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CityName', SellerSupplierPartyCityName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'PostalZone', SellerSupplierPartyPostalZone, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CountrySubentity', SellerSupplierPartyCountrySubentity, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PostalAddressNode, 'Country', '', CacNamespaceTok, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', SellerSupplierPartyIdentificationCode, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyLegalEntity', '', CacNamespaceTok, PartyLegalEntityNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'RegistrationName', SellerSupplierPartySupplierName, CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetSellerSupplierPartyContact(PurchaseHeader, SellerSupplierPartyContactName, SellerSupplierPartyContactTelephone, SellerSupplierPartyContactTelefax, SellerSupplierPartyContactElectronicMail);

        if (SellerSupplierPartyContactName <> '') or (SellerSupplierPartyContactTelephone <> '') or (SellerSupplierPartyContactTelefax <> '') or (SellerSupplierPartyContactElectronicMail <> '') then begin
            this.XMLDOMManagement.AddElement(PartyNode, 'Contact', '', CacNamespaceTok, ContactNode);
            this.AddNonEmptyNode(ContactNode, 'Name', SellerSupplierPartyContactName, CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telephone', SellerSupplierPartyContactTelephone, CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telefax', SellerSupplierPartyContactTelefax, CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'ElectronicMail', SellerSupplierPartyContactElectronicMail, CbcNamespaceTok, ChildNode);
        end;
    end;

    local procedure AddDelivery(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLDeliveryInfo: Interface "PEPPOL Purchase Delivery Info Provider";
        DeliveryNode: XmlNode;
        DeliveryLocationNode: XmlNode;
        AddressNode: XmlNode;
        CountryNode: XmlNode;
        RequestedPeriodNode: XmlNode;
        ChildNode: XmlNode;
        StreetName: Text;
        AdditionalStreetName: Text;
        CityName: Text;
        PostalZone: Text;
        CountrySubentity: Text;
        IdentificationCode: Text;
        ListID: Text;
    begin
        PEPPOLDeliveryInfo := GetFormat();
        PEPPOLDeliveryInfo.GetDeliveryAddress(PurchaseHeader, StreetName, AdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);

        this.XMLDOMManagement.AddElement(this.RootNode, 'Delivery', '', CacNamespaceTok, DeliveryNode);
        this.XMLDOMManagement.AddElement(DeliveryNode, 'DeliveryLocation', '', CacNamespaceTok, DeliveryLocationNode);
        this.XMLDOMManagement.AddElement(DeliveryLocationNode, 'Address', '', CacNamespaceTok, AddressNode);
        this.AddNonEmptyNode(AddressNode, 'StreetName', StreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'AdditionalStreetName', AdditionalStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'CityName', CityName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'PostalZone', PostalZone, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'CountrySubentity', CountrySubentity, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(AddressNode, 'Country', '', CacNamespaceTok, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', IdentificationCode, CbcNamespaceTok, ChildNode);
    end;

    local procedure AddPaymentTerms(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLPaymentInfo: Interface "PEPPOL Purchase Payment Info Provider";
        PaymentTermsNode: XmlNode;
        ChildNode: XmlNode;
        PaymentTermsNote: Text;
    begin
        PEPPOLPaymentInfo := GetFormat();
        PEPPOLPaymentInfo.GetPaymentTermsInfo(PurchaseHeader, PaymentTermsNote);

        this.XMLDOMManagement.AddElement(this.RootNode, 'PaymentTerms', '', CacNamespaceTok, PaymentTermsNode);
        this.AddNonEmptyNode(PaymentTermsNode, 'Note', PaymentTermsNote, CbcNamespaceTok, ChildNode);
    end;

    local procedure AddAnticipatedMonetaryTotal(PurchaseHeader: Record "Purchase Header")
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary;
        PurchaseHeaderRecRef, PurchaseLineRecRef : RecordRef;
        PEPPOL30Common: Codeunit "PEPPOL30 Common";
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
        PurchaseHeaderRecRef.GetTable(PurchaseHeader);
        PEPPOLMonetaryInfo := GetFormat();
        PEPPOL30Common.GetInvoiceRoundingLine(PurchaseHeaderRecRef, TempPurchaseLine, GetFormat());
        PEPPOL30Common.SetFilters(PurchaseHeaderRecRef, PurchaseLineRecRef, TempPurchaseLine);
        PEPPOL30Common.GetTotals(PurchaseHeaderRecRef, PurchaseLineRecRef, TempVATAmtLine, TempVATProductPostingGroup, GetFormat());
        PEPPOLMonetaryInfo.GetLegalMonetaryInfo(PurchaseHeader, TempPurchaseLine, TempVATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID, PrepaidAmount, PrepaidCurrencyID, PayableRoundingAmount, PayableRndingAmountCurrencyID, PayableAmount, PayableAmountCurrencyID);

        this.XMLDOMManagement.AddElement(this.RootNode, 'AnticipatedMonetaryTotal', '', CacNamespaceTok, MonetaryTotalNode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'LineExtensionAmount', LineExtensionAmount, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'TaxExclusiveAmount', TaxExclusiveAmount, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'TaxInclusiveAmount', TaxInclusiveAmount, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'PayableAmount', PayableAmount, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
    end;

    local procedure AddOrderLineToXML(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        PEPPOLLineInfo: Interface "PEPPOL Purchase Line Info Provider";
        OrderLineNode: XmlNode;
        LineItemNode: XmlNode;
        ItemNode: XmlNode;
        SellersItemIdNode: XmlNode;
        StandardItemIdNode: XmlNode;
        ClassifiedTaxCategoryNode: XmlNode;
        TaxSchemeNode: XmlNode;
        PriceNode: XmlNode;
        ChildNode: XmlNode;
        InvoiceLineID: Text;
        InvoiceLineNote: Text;
        InvoicedQuantity: Text;
        InvoiceLineExtensionAmount: Text;
        LineExtensionAmountCurrencyID: Text;
        InvoiceLineAccountingCost: Text;
        InvoiceLinePriceAmount: Text;
        InvLinePriceAmountCurrencyID: Text;
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
        InvoiceLineTaxPercent: Text;
        ClassifiedTaxCategorySchemeID: Text;
    begin
        PEPPOLLineInfo := GetFormat();
        PEPPOLLineInfo.GetLineGeneralInfo(PurchaseLine, PurchaseHeader, InvoiceLineID, InvoiceLineNote, InvoicedQuantity, InvoiceLineExtensionAmount, LineExtensionAmountCurrencyID, InvoiceLineAccountingCost);

        this.XMLDOMManagement.AddElement(this.RootNode, 'OrderLine', '', CacNamespaceTok, OrderLineNode);
        this.XMLDOMManagement.AddElement(OrderLineNode, 'LineItem', '', CacNamespaceTok, LineItemNode);
        this.XMLDOMManagement.AddElement(LineItemNode, 'ID', InvoiceLineID, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(LineItemNode, 'Quantity', InvoicedQuantity, CbcNamespaceTok, ChildNode);

        PEPPOLLineInfo.GetLinePriceInfo(PurchaseLine, PurchaseHeader, InvoiceLinePriceAmount, InvLinePriceAmountCurrencyID, BaseQuantity, UnitCode);

        this.XMLDOMManagement.AddAttribute(ChildNode, 'unitCode', UnitCode);
        this.XMLDOMManagement.AddElement(LineItemNode, 'LineExtensionAmount', InvoiceLineExtensionAmount, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', InvLinePriceAmountCurrencyID);
        this.XMLDOMManagement.AddElement(LineItemNode, 'Price', '', CacNamespaceTok, PriceNode);
        this.XMLDOMManagement.AddElement(PriceNode, 'PriceAmount', InvoiceLinePriceAmount, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', InvLinePriceAmountCurrencyID);

        PEPPOLLineInfo.GetLineItemInfo(PurchaseLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID, OriginCountryIdCode, OriginCountryIdCodeListID);

        this.XMLDOMManagement.AddElement(LineItemNode, 'Item', '', CacNamespaceTok, ItemNode);
        this.AddNonEmptyNode(ItemNode, 'Description', Description, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(ItemNode, 'Name', Name, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(ItemNode, 'SellersItemIdentification', '', CacNamespaceTok, SellersItemIdNode);
        this.XMLDOMManagement.AddElement(SellersItemIdNode, 'ID', SellersItemIdentificationID, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(ItemNode, 'StandardItemIdentification', '', CacNamespaceTok, StandardItemIdNode);
        this.XMLDOMManagement.AddElement(StandardItemIdNode, 'ID', StandardItemIdentificationID, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', StdItemIdIDSchemeID);

        PEPPOLLineInfo.GetLineItemClassifiedTaxCategory(PurchaseLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);

        this.XMLDOMManagement.AddElement(ItemNode, 'ClassifiedTaxCategory', '', CacNamespaceTok, ClassifiedTaxCategoryNode);
        this.XMLDOMManagement.AddElement(ClassifiedTaxCategoryNode, 'ID', ClassifiedTaxCategoryID, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(ClassifiedTaxCategoryNode, 'Percent', InvoiceLineTaxPercent, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(ClassifiedTaxCategoryNode, 'TaxScheme', '', CacNamespaceTok, TaxSchemeNode);
        this.XMLDOMManagement.AddElement(TaxSchemeNode, 'ID', ClassifiedTaxCategorySchemeID, CbcNamespaceTok, ChildNode);
    end;

    local procedure AddPartyTaxScheme(PartyNode: XmlNode)
    var
        PEPPOLPartyInfo: Interface "PEPPOL Purchase Party Info Provider";
        PartyTaxSchemeNode: XmlNode;
        TaxSchemeNode: XmlNode;
        ChildNode: XmlNode;
        CompanyID: Text;
        CompanyIDSchemeID: Text;
        TaxSchemeID: Text;
    begin
        PEPPOLPartyInfo := GetFormat();
        PEPPOLPartyInfo.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);

        this.XMLDOMManagement.AddElement(PartyNode, 'PartyTaxScheme', '', CacNamespaceTok, PartyTaxSchemeNode);
        this.XMLDOMManagement.AddElement(PartyTaxSchemeNode, 'CompanyID', CompanyID, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(PartyTaxSchemeNode, 'TaxScheme', '', CacNamespaceTok, TaxSchemeNode);
        this.XMLDOMManagement.AddElement(TaxSchemeNode, 'ID', TaxSchemeID, CbcNamespaceTok, ChildNode);
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
        PEPPOLAttachment := GetFormat();
        PEPPOLAttachment.GeneratePDFAttachmentAsAdditionalDocRef(PurchaseHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, Filename, MimeCode, EmbeddedDocumentBinaryObject);
        if EmbeddedDocumentBinaryObject = '' then
            exit;

        this.XMLDOMManagement.AddElement(this.RootNode, 'AdditionalDocumentReference', '', CacNamespaceTok, AdditionalDocRefNode);
        this.XMLDOMManagement.AddElement(AdditionalDocRefNode, 'ID', AdditionalDocumentReferenceID, CbcNamespaceTok, ChildNode);
        this.XMLDOMManagement.AddElement(AdditionalDocRefNode, 'Attachment', '', CacNamespaceTok, AttachmentNode);
        this.XMLDOMManagement.AddElement(AttachmentNode, 'EmbeddedDocumentBinaryObject', EmbeddedDocumentBinaryObject, CbcNamespaceTok, EmbeddedDocNode);
        this.XMLDOMManagement.AddAttribute(EmbeddedDocNode, 'filename', Filename);
        this.XMLDOMManagement.AddAttribute(EmbeddedDocNode, 'mimeCode', MimeCode);
    end;

    local procedure AddNonEmptyNode(Node: XmlNode; NodeName: Text; NodeValue: Text; Namespace: Text; var ChildNode: XmlNode)
    begin
        if NodeValue <> '' then
            this.XMLDOMManagement.AddElement(Node, NodeName, NodeValue, Namespace, ChildNode);
    end;

    local procedure GetFormat(): Enum "PEPPOL 3.0 Purchase Format"
    var
        PeppolSetup: Record "PEPPOL 3.0 Setup";
    begin
        if not IsFormatSet then begin
            PeppolSetup.GetSetup();
            PEPPOL30PurchaseFormat := PeppolSetup."PEPPOL 3.0 Purchase Format";
            IsFormatSet := true;
        end;
        exit(PEPPOL30PurchaseFormat);
    end;

    /// <summary>
    /// Gets the XML document as a temporary blob.
    /// </summary>
    /// <param name="TempBlob">Return value: Temp Blob codeunit containing the document.</param>
    internal procedure GetPurchaseOrderXML(var TempBlob: Codeunit "Temp Blob")
    begin
        this.PurchaseOrderXML.WriteTo(TempBlob.CreateOutStream());
    end;

    /// <summary>
    /// Controls whether a PDF document should be generated and included as an additional document reference.
    /// </summary>
    /// <param name="GeneratePDFValue">If true, generates a PDF based on Report Selection settings.</param>
    internal procedure SetGeneratePDF(GeneratePDFValue: Boolean)
    begin
        this.GeneratePDF := GeneratePDFValue;
    end;

    /// <summary>
    /// Sets the PEPPOL 3.0 Purchase Format to use when exporting the document.
    /// </summary>
    /// <param name="Format">The PEPPOL 3.0 Purchase Format to use.</param>
    procedure SetFormat(Format: Enum "PEPPOL 3.0 Purchase Format")
    begin
        PEPPOL30PurchaseFormat := Format;
        IsFormatSet := true;
    end;
}
