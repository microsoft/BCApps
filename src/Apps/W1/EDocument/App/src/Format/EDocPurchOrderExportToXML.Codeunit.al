namespace Microsoft.EServices.EDocument.Format;

using Microsoft.Purchases.Document;
using Microsoft.Peppol;
using Microsoft.Finance.VAT.Calculation;
using System.Utilities;
using System.Xml;

codeunit 50000 "E-Doc. Purchase Order To XML"
{
    TableNo = "Purchase Header";

    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        PurchaseOrderXML: XmlDocument;
        RootNode: XmlNode;
        GeneratePDF: Boolean;
        CbcNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        CacNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        OrderNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:Order-2', Locked = true;
        CustomizationIDTxt: Label 'urn:fdc:peppol.eu:poacc:trns:order:3', Locked = true;
        ProfileIDTxt: Label 'urn:fdc:peppol.eu:poacc:bis:ordering:3', Locked = true;
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
        PEPPOL30: Codeunit PEPPOL30;
        ChildNode: XmlNode;
        ID: Text;
        SalesOrderID: Text;
        IssueDate: Text;
        OrderTypeCode: Text;
        Note: Text;
        AccountingCost: Text;
        CustomerReference: Text;
    begin
        PEPPOL30.GetGeneralInfoBIS(PurchaseHeader, ID, SalesOrderID, IssueDate, OrderTypeCode, Note, DocumentCurrencyCode, AccountingCost, CustomerReference);

        this.InitializeXMLDocument();
        this.XMLDOMManagement.AddElement(this.RootNode, 'CustomizationID', CustomizationIDTxt, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'ProfileID', ProfileIDTxt, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'ID', ID, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'SalesOrderID', SalesOrderID, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'IssueDate', IssueDate, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'OrderTypeCode', OrderTypeCode, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'Note', Note, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(this.RootNode, 'DocumentCurrencyCode', DocumentCurrencyCode, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'CustomerReference', CustomerReference, CbcNamespaceTxt, ChildNode);

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
        XmlDec: XmlDeclaration;
        RootElement: XmlElement;
        XmlNsAttr: XmlAttribute;
    begin
        this.PurchaseOrderXML := XmlDocument.Create();

        RootElement := XmlElement.Create('Order', OrderNamespaceTxt);
        XmlNsAttr := XmlAttribute.CreateNamespaceDeclaration('cac', CacNamespaceTxt);
        RootElement.Add(XmlNsAttr);
        XmlNsAttr := XmlAttribute.CreateNamespaceDeclaration('cbc', CbcNamespaceTxt);
        RootElement.Add(XmlNsAttr);

        this.PurchaseOrderXML.Add(RootElement);
        this.RootNode := RootElement.AsXmlNode();
    end;

    local procedure AddBuyerCustomerParty(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOL30: Codeunit PEPPOL30;
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
        this.XMLDOMManagement.AddElement(this.RootNode, 'BuyerCustomerParty', '', CacNamespaceTxt, BuyerNode);
        this.XMLDOMManagement.AddElement(BuyerNode, 'Party', '', CacNamespaceTxt, PartyNode);

        PEPPOL30.GetAccountingSupplierPartyInfoBIS(BuyerCustomerPartyEndpointId, BuyerCustomerPartySchemeID, BuyerCustomerPartySupplierName);
        
        this.XMLDOMManagement.AddElement(PartyNode, 'EndpointID', BuyerCustomerPartyEndpointId, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', BuyerCustomerPartySchemeID);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyIdentification', '', CacNamespaceTxt, PartyIdentificationNode);
        this.XMLDOMManagement.AddElement(PartyIdentificationNode, 'ID', BuyerCustomerPartyEndpointId, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyName', '', CacNamespaceTxt, PartyNameNode);
        this.XMLDOMManagement.AddElement(PartyNameNode, 'Name', BuyerCustomerPartySupplierName, CbcNamespaceTxt, ChildNode);

        PEPPOL30.GetBuyerCustomerPartyPostalAddr(PurchaseHeader, BuyerCustomerPartyStreetName, BuyerCustomerAdditionalStreetName, BuyerCustomerPartyCityName, BuyerCustomerPartyPostalZone, BuyerCustomerPartyCountrySubentity, BuyerCustomerPartyIdentificationCode, ListID);
        
        this.XMLDOMManagement.AddElement(PartyNode, 'PostalAddress', '', CacNamespaceTxt, PostalAddressNode);
        this.AddNonEmptyNode(PostalAddressNode, 'StreetName', BuyerCustomerPartyStreetName, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'AdditionalStreetName', BuyerCustomerAdditionalStreetName, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CityName', BuyerCustomerPartyCityName, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'PostalZone', BuyerCustomerPartyPostalZone, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CountrySubentity', BuyerCustomerPartyCountrySubentity, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(PostalAddressNode, 'Country', '', CacNamespaceTxt, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', BuyerCustomerPartyIdentificationCode, CbcNamespaceTxt, ChildNode);
        this.AddPartyTaxScheme(PartyNode);

        PEPPOL30.GetAccountingSupplierPartyLegalEntityBIS(BuyerCustomerPartyPartyLegalEntityRegName, BuyerCustomerPartyPartyLegalEntityCompanyID, BuyerCustomerPartyPartyLegalEntitySchemeID, BuyerCustomerPartySupplierRegAddrCityName, BuyerCustomerPartySupplierRegAddrCountryIdCode, BuyerCustomerPartySupplRegAddrCountryIdListId);
        
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyLegalEntity', '', CacNamespaceTxt, PartyLegalEntityNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'RegistrationName', BuyerCustomerPartyPartyLegalEntityRegName, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'CompanyID', BuyerCustomerPartyPartyLegalEntityCompanyID, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'RegistrationAddress', '', CacNamespaceTxt, RegistrationAddressNode);
        this.AddNonEmptyNode(RegistrationAddressNode, 'CityName', BuyerCustomerPartySupplierRegAddrCityName, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(RegistrationAddressNode, 'Country', '', CacNamespaceTxt, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', BuyerCustomerPartySupplierRegAddrCountryIdCode, CbcNamespaceTxt, ChildNode);

        PEPPOL30.GetBuyerCustomerPartyContact(PurchaseHeader, BuyerCustomerPartyContactName, BuyerCustomerPartyContactTelephone, BuyerCustomerPartyContactElectronicMail);
        if (BuyerCustomerPartyContactName <> '') or (BuyerCustomerPartyContactTelephone <> '') or (BuyerCustomerPartyContactElectronicMail <> '') then begin
            this.XMLDOMManagement.AddElement(PartyNode, 'Contact', '', CacNamespaceTxt, ContactNode);
            this.AddNonEmptyNode(ContactNode, 'Name', BuyerCustomerPartyContactName, CbcNamespaceTxt, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telephone', BuyerCustomerPartyContactTelephone, CbcNamespaceTxt, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'ElectronicMail', BuyerCustomerPartyContactElectronicMail, CbcNamespaceTxt, ChildNode);
        end;
    end;

    local procedure AddSellerSupplierParty(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOL30: Codeunit PEPPOL30;
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
        this.XMLDOMManagement.AddElement(this.RootNode, 'SellerSupplierParty', '', CacNamespaceTxt, SellerNode);
        this.XMLDOMManagement.AddElement(SellerNode, 'Party', '', CacNamespaceTxt, PartyNode);

        PEPPOL30.GetSellerSupplierPartyInfoBIS(PurchaseHeader, SellerSupplierPartyEndpointId, SellerSupplierPartySchemeID, SellerSupplierPartySupplierName);
        
        this.XMLDOMManagement.AddElement(PartyNode, 'EndpointID', SellerSupplierPartyEndpointId, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', SellerSupplierPartySchemeID);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyIdentification', '', CacNamespaceTxt, PartyIdentificationNode);
        this.XMLDOMManagement.AddElement(PartyIdentificationNode, 'ID', PurchaseHeader."Buy-from Vendor No.", CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyName', '', CacNamespaceTxt, PartyNameNode);
        this.XMLDOMManagement.AddElement(PartyNameNode, 'Name', SellerSupplierPartySupplierName, CbcNamespaceTxt, ChildNode);

        PEPPOL30.GetSellerSupplierPartyPostalAddr(PurchaseHeader, SellerSupplierStreetName, SellerSupplierAdditionalStreetName, SellerSupplierPartyCityName, SellerSupplierPartyPostalZone, SellerSupplierPartyCountrySubentity, SellerSupplierPartyIdentificationCode, ListID);
        
        this.XMLDOMManagement.AddElement(PartyNode, 'PostalAddress', '', CacNamespaceTxt, PostalAddressNode);
        this.AddNonEmptyNode(PostalAddressNode, 'StreetName', SellerSupplierStreetName, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'AdditionalStreetName', SellerSupplierAdditionalStreetName, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CityName', SellerSupplierPartyCityName, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'PostalZone', SellerSupplierPartyPostalZone, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CountrySubentity', SellerSupplierPartyCountrySubentity, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(PostalAddressNode, 'Country', '', CacNamespaceTxt, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', SellerSupplierPartyIdentificationCode, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyLegalEntity', '', CacNamespaceTxt, PartyLegalEntityNode);
        this.XMLDOMManagement.AddElement(PartyLegalEntityNode, 'RegistrationName', SellerSupplierPartySupplierName, CbcNamespaceTxt, ChildNode);

        PEPPOL30.GetSellerSupplierPartyContact(PurchaseHeader, SellerSupplierPartyContactName, SellerSupplierPartyContactTelephone, SellerSupplierPartyContactTelefax, SellerSupplierPartyContactElectronicMail);
        
        if (SellerSupplierPartyContactName <> '') or (SellerSupplierPartyContactTelephone <> '') or (SellerSupplierPartyContactTelefax <> '') or (SellerSupplierPartyContactElectronicMail <> '') then begin
            this.XMLDOMManagement.AddElement(PartyNode, 'Contact', '', CacNamespaceTxt, ContactNode);
            this.AddNonEmptyNode(ContactNode, 'Name', SellerSupplierPartyContactName, CbcNamespaceTxt, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telephone', SellerSupplierPartyContactTelephone, CbcNamespaceTxt, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telefax', SellerSupplierPartyContactTelefax, CbcNamespaceTxt, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'ElectronicMail', SellerSupplierPartyContactElectronicMail, CbcNamespaceTxt, ChildNode);
        end;
    end;

    local procedure AddDelivery(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOL30: Codeunit PEPPOL30;
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
        PEPPOL30.GetDeliveryAddress(PurchaseHeader, StreetName, AdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);

        this.XMLDOMManagement.AddElement(this.RootNode, 'Delivery', '', CacNamespaceTxt, DeliveryNode);
        this.XMLDOMManagement.AddElement(DeliveryNode, 'DeliveryLocation', '', CacNamespaceTxt, DeliveryLocationNode);
        this.XMLDOMManagement.AddElement(DeliveryLocationNode, 'Address', '', CacNamespaceTxt, AddressNode);
        this.AddNonEmptyNode(AddressNode, 'StreetName', StreetName, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'AdditionalStreetName', AdditionalStreetName, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'CityName', CityName, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'PostalZone', PostalZone, CbcNamespaceTxt, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'CountrySubentity', CountrySubentity, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(AddressNode, 'Country', '', CacNamespaceTxt, CountryNode);
        this.XMLDOMManagement.AddElement(CountryNode, 'IdentificationCode', IdentificationCode, CbcNamespaceTxt, ChildNode);
    end;

    local procedure AddPaymentTerms(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOL30: Codeunit PEPPOL30;
        PaymentTermsNode: XmlNode;
        ChildNode: XmlNode;
        PaymentTermsNote: Text;
    begin
        PEPPOL30.GetPaymentTermsInfo(PurchaseHeader, PaymentTermsNote);

        this.XMLDOMManagement.AddElement(this.RootNode, 'PaymentTerms', '', CacNamespaceTxt, PaymentTermsNode);
        this.AddNonEmptyNode(PaymentTermsNode, 'Note', PaymentTermsNote, CbcNamespaceTxt, ChildNode);
    end;

    local procedure AddAnticipatedMonetaryTotal(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        VATAmtLine: Record "VAT Amount Line";
        PEPPOL30: Codeunit PEPPOL30;
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
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PEPPOL30.GetLegalMonetaryInfo(PurchaseHeader, PurchaseLine, VATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID, PrepaidAmount, PrepaidCurrencyID, PayableRoundingAmount, PayableRndingAmountCurrencyID, PayableAmount, PayableAmountCurrencyID);

        this.XMLDOMManagement.AddElement(this.RootNode, 'AnticipatedMonetaryTotal', '', CacNamespaceTxt, MonetaryTotalNode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'LineExtensionAmount', LineExtensionAmount, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'TaxExclusiveAmount', TaxExclusiveAmount, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'TaxInclusiveAmount', TaxInclusiveAmount, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
        this.XMLDOMManagement.AddElement(MonetaryTotalNode, 'PayableAmount', PayableAmount, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
    end;

    local procedure AddOrderLineToXML(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        PEPPOL30: Codeunit PEPPOL30;
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
        PEPPOL30.GetLineGeneralInfo(PurchaseLine, PurchaseHeader, InvoiceLineID, InvoiceLineNote, InvoicedQuantity, InvoiceLineExtensionAmount, LineExtensionAmountCurrencyID, InvoiceLineAccountingCost);
        
        this.XMLDOMManagement.AddElement(this.RootNode, 'OrderLine', '', CacNamespaceTxt, OrderLineNode);
        this.XMLDOMManagement.AddElement(OrderLineNode, 'LineItem', '', CacNamespaceTxt, LineItemNode);
        this.XMLDOMManagement.AddElement(LineItemNode, 'ID', InvoiceLineID, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(LineItemNode, 'Quantity', InvoicedQuantity, CbcNamespaceTxt, ChildNode);

        PEPPOL30.GetLinePriceInfo(PurchaseLine, PurchaseHeader, InvoiceLinePriceAmount, InvLinePriceAmountCurrencyID, BaseQuantity, UnitCode);

        this.XMLDOMManagement.AddAttribute(ChildNode, 'unitCode', UnitCode);
        this.XMLDOMManagement.AddElement(LineItemNode, 'LineExtensionAmount', InvoiceLineExtensionAmount, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', InvLinePriceAmountCurrencyID);
        this.XMLDOMManagement.AddElement(LineItemNode, 'Price', '', CacNamespaceTxt, PriceNode);
        this.XMLDOMManagement.AddElement(PriceNode, 'PriceAmount', InvoiceLinePriceAmount, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', InvLinePriceAmountCurrencyID);

        PEPPOL30.GetLineItemInfo(PurchaseLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID, OriginCountryIdCode, OriginCountryIdCodeListID);

        this.XMLDOMManagement.AddElement(LineItemNode, 'Item', '', CacNamespaceTxt, ItemNode);
        this.AddNonEmptyNode(ItemNode, 'Description', Description, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(ItemNode, 'Name', Name, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(ItemNode, 'SellersItemIdentification', '', CacNamespaceTxt, SellersItemIdNode);
        this.XMLDOMManagement.AddElement(SellersItemIdNode, 'ID', SellersItemIdentificationID, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(ItemNode, 'StandardItemIdentification', '', CacNamespaceTxt, StandardItemIdNode);
        this.XMLDOMManagement.AddElement(StandardItemIdNode, 'ID', StandardItemIdentificationID, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', StdItemIdIDSchemeID);

        PEPPOL30.GetLineItemClassifiedTaxCategory(PurchaseLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);
        
        this.XMLDOMManagement.AddElement(ItemNode, 'ClassifiedTaxCategory', '', CacNamespaceTxt, ClassifiedTaxCategoryNode);
        this.XMLDOMManagement.AddElement(ClassifiedTaxCategoryNode, 'ID', ClassifiedTaxCategoryID, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(ClassifiedTaxCategoryNode, 'Percent', InvoiceLineTaxPercent, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(ClassifiedTaxCategoryNode, 'TaxScheme', '', CacNamespaceTxt, TaxSchemeNode);
        this.XMLDOMManagement.AddElement(TaxSchemeNode, 'ID', ClassifiedTaxCategorySchemeID, CbcNamespaceTxt, ChildNode);
    end;

    local procedure AddPartyTaxScheme(PartyNode: XmlNode)
    var
        PEPPOL30: Codeunit PEPPOL30;
        PartyTaxSchemeNode: XmlNode;
        TaxSchemeNode: XmlNode;
        ChildNode: XmlNode;
        CompanyID: Text;
        CompanyIDSchemeID: Text;
        TaxSchemeID: Text;
    begin
        PEPPOL30.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
        
        this.XMLDOMManagement.AddElement(PartyNode, 'PartyTaxScheme', '', CacNamespaceTxt, PartyTaxSchemeNode);
        this.XMLDOMManagement.AddElement(PartyTaxSchemeNode, 'CompanyID', CompanyID, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(PartyTaxSchemeNode, 'TaxScheme', '', CacNamespaceTxt, TaxSchemeNode);
        this.XMLDOMManagement.AddElement(TaxSchemeNode, 'ID', TaxSchemeID, CbcNamespaceTxt, ChildNode);
    end;

    local procedure AddAdditionalDocumentReference(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOL30: Codeunit PEPPOL30;
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
        PEPPOL30.GeneratePDFAttachmentAsAdditionalDocRef(PurchaseHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, Filename, MimeCode, EmbeddedDocumentBinaryObject);
        if EmbeddedDocumentBinaryObject = '' then
            exit;

        this.XMLDOMManagement.AddElement(this.RootNode, 'AdditionalDocumentReference', '', CacNamespaceTxt, AdditionalDocRefNode);
        this.XMLDOMManagement.AddElement(AdditionalDocRefNode, 'ID', AdditionalDocumentReferenceID, CbcNamespaceTxt, ChildNode);
        this.XMLDOMManagement.AddElement(AdditionalDocRefNode, 'Attachment', '', CacNamespaceTxt, AttachmentNode);
        this.XMLDOMManagement.AddElement(AttachmentNode, 'EmbeddedDocumentBinaryObject', EmbeddedDocumentBinaryObject, CbcNamespaceTxt, EmbeddedDocNode);
        this.XMLDOMManagement.AddAttribute(EmbeddedDocNode, 'filename', Filename);
        this.XMLDOMManagement.AddAttribute(EmbeddedDocNode, 'mimeCode', MimeCode);
    end;

    local procedure AddNonEmptyNode(Node: XmlNode; NodeName: Text; NodeValue: Text; Namespace: Text; var ChildNode: XmlNode)
    begin
        if NodeValue <> '' then
            this.XMLDOMManagement.AddElement(Node, NodeName, NodeValue, Namespace, ChildNode);
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
}
