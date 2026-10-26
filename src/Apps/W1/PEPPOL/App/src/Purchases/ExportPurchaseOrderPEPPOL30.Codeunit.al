namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Document;
using System.Utilities;
using System.Xml;

codeunit 37202 "Export Purchase Order PEPPOL30"
{
    TableNo = "Purchase Header";

    var
        PEPPOL30PurchaseFormat: Enum "PEPPOL 3.0 Purchase";
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
        this.AddElement(this.RootNode, 'CustomizationID', CustomizationIDTok, CbcNamespaceTok, ChildNode);
        this.AddElement(this.RootNode, 'ProfileID', ProfileIDTok, CbcNamespaceTok, ChildNode);
        this.AddElement(this.RootNode, 'ID', ID, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'SalesOrderID', SalesOrderID, CbcNamespaceTok, ChildNode);
        this.AddElement(this.RootNode, 'IssueDate', IssueDate, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'OrderTypeCode', OrderTypeCode, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(this.RootNode, 'Note', Note, CbcNamespaceTok, ChildNode);
        this.AddElement(this.RootNode, 'DocumentCurrencyCode', DocumentCurrencyCode, CbcNamespaceTok, ChildNode);
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
        this.AddElement(this.RootNode, 'BuyerCustomerParty', '', CacNamespaceTok, BuyerNode);
        this.AddElement(BuyerNode, 'Party', '', CacNamespaceTok, PartyNode);

        PEPPOLPartyInfo := GetFormat();
        PEPPOLPartyInfo.GetAccountingSupplierPartyInfoBIS(BuyerCustomerPartyEndpointId, BuyerCustomerPartySchemeID, BuyerCustomerPartySupplierName);

        this.AddElement(PartyNode, 'EndpointID', BuyerCustomerPartyEndpointId, CbcNamespaceTok, ChildNode);
        this.AddAttribute(ChildNode, 'schemeID', BuyerCustomerPartySchemeID);
        this.AddElement(PartyNode, 'PartyIdentification', '', CacNamespaceTok, PartyIdentificationNode);
        this.AddElement(PartyIdentificationNode, 'ID', BuyerCustomerPartyEndpointId, CbcNamespaceTok, ChildNode);
        this.AddElement(PartyNode, 'PartyName', '', CacNamespaceTok, PartyNameNode);
        this.AddElement(PartyNameNode, 'Name', BuyerCustomerPartySupplierName, CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetBuyerCustomerPartyPostalAddr(PurchaseHeader, BuyerCustomerPartyStreetName, BuyerCustomerAdditionalStreetName, BuyerCustomerPartyCityName, BuyerCustomerPartyPostalZone, BuyerCustomerPartyCountrySubentity, BuyerCustomerPartyIdentificationCode, ListID);

        this.AddElement(PartyNode, 'PostalAddress', '', CacNamespaceTok, PostalAddressNode);
        this.AddNonEmptyNode(PostalAddressNode, 'StreetName', BuyerCustomerPartyStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'AdditionalStreetName', BuyerCustomerAdditionalStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CityName', BuyerCustomerPartyCityName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'PostalZone', BuyerCustomerPartyPostalZone, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CountrySubentity', BuyerCustomerPartyCountrySubentity, CbcNamespaceTok, ChildNode);
        this.AddElement(PostalAddressNode, 'Country', '', CacNamespaceTok, CountryNode);
        this.AddElement(CountryNode, 'IdentificationCode', BuyerCustomerPartyIdentificationCode, CbcNamespaceTok, ChildNode);
        this.AddPartyTaxScheme(PartyNode);

        PEPPOLPartyInfo.GetAccountingSupplierPartyLegalEntityBIS(BuyerCustomerPartyPartyLegalEntityRegName, BuyerCustomerPartyPartyLegalEntityCompanyID, BuyerCustomerPartyPartyLegalEntitySchemeID, BuyerCustomerPartySupplierRegAddrCityName, BuyerCustomerPartySupplierRegAddrCountryIdCode, BuyerCustomerPartySupplRegAddrCountryIdListId);

        this.AddElement(PartyNode, 'PartyLegalEntity', '', CacNamespaceTok, PartyLegalEntityNode);
        this.AddElement(PartyLegalEntityNode, 'RegistrationName', BuyerCustomerPartyPartyLegalEntityRegName, CbcNamespaceTok, ChildNode);
        this.AddElement(PartyLegalEntityNode, 'CompanyID', BuyerCustomerPartyPartyLegalEntityCompanyID, CbcNamespaceTok, ChildNode);
        this.AddElement(PartyLegalEntityNode, 'RegistrationAddress', '', CacNamespaceTok, RegistrationAddressNode);
        this.AddNonEmptyNode(RegistrationAddressNode, 'CityName', BuyerCustomerPartySupplierRegAddrCityName, CbcNamespaceTok, ChildNode);
        this.AddElement(RegistrationAddressNode, 'Country', '', CacNamespaceTok, CountryNode);
        this.AddElement(CountryNode, 'IdentificationCode', BuyerCustomerPartySupplierRegAddrCountryIdCode, CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetBuyerCustomerPartyContact(PurchaseHeader, BuyerCustomerPartyContactName, BuyerCustomerPartyContactTelephone, BuyerCustomerPartyContactElectronicMail);
        if (BuyerCustomerPartyContactName <> '') or (BuyerCustomerPartyContactTelephone <> '') or (BuyerCustomerPartyContactElectronicMail <> '') then begin
            this.AddElement(PartyNode, 'Contact', '', CacNamespaceTok, ContactNode);
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
        this.AddElement(this.RootNode, 'SellerSupplierParty', '', CacNamespaceTok, SellerNode);
        this.AddElement(SellerNode, 'Party', '', CacNamespaceTok, PartyNode);

        PEPPOLPartyInfo := GetFormat();
        PEPPOLPartyInfo.GetSellerSupplierPartyInfoBIS(PurchaseHeader, SellerSupplierPartyEndpointId, SellerSupplierPartySchemeID, SellerSupplierPartySupplierName);

        this.AddElement(PartyNode, 'EndpointID', SellerSupplierPartyEndpointId, CbcNamespaceTok, ChildNode);
        this.AddAttribute(ChildNode, 'schemeID', SellerSupplierPartySchemeID);
        this.AddElement(PartyNode, 'PartyIdentification', '', CacNamespaceTok, PartyIdentificationNode);
        this.AddElement(PartyIdentificationNode, 'ID', PurchaseHeader."Buy-from Vendor No.", CbcNamespaceTok, ChildNode);
        this.AddElement(PartyNode, 'PartyName', '', CacNamespaceTok, PartyNameNode);
        this.AddElement(PartyNameNode, 'Name', SellerSupplierPartySupplierName, CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetSellerSupplierPartyPostalAddr(PurchaseHeader, SellerSupplierStreetName, SellerSupplierAdditionalStreetName, SellerSupplierPartyCityName, SellerSupplierPartyPostalZone, SellerSupplierPartyCountrySubentity, SellerSupplierPartyIdentificationCode, ListID);

        this.AddElement(PartyNode, 'PostalAddress', '', CacNamespaceTok, PostalAddressNode);
        this.AddNonEmptyNode(PostalAddressNode, 'StreetName', SellerSupplierStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'AdditionalStreetName', SellerSupplierAdditionalStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CityName', SellerSupplierPartyCityName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'PostalZone', SellerSupplierPartyPostalZone, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(PostalAddressNode, 'CountrySubentity', SellerSupplierPartyCountrySubentity, CbcNamespaceTok, ChildNode);
        this.AddElement(PostalAddressNode, 'Country', '', CacNamespaceTok, CountryNode);
        this.AddElement(CountryNode, 'IdentificationCode', SellerSupplierPartyIdentificationCode, CbcNamespaceTok, ChildNode);
        this.AddElement(PartyNode, 'PartyLegalEntity', '', CacNamespaceTok, PartyLegalEntityNode);
        this.AddElement(PartyLegalEntityNode, 'RegistrationName', SellerSupplierPartySupplierName, CbcNamespaceTok, ChildNode);

        PEPPOLPartyInfo.GetSellerSupplierPartyContact(PurchaseHeader, SellerSupplierPartyContactName, SellerSupplierPartyContactTelephone, SellerSupplierPartyContactTelefax, SellerSupplierPartyContactElectronicMail);

        if (SellerSupplierPartyContactName <> '') or (SellerSupplierPartyContactTelephone <> '') or (SellerSupplierPartyContactTelefax <> '') or (SellerSupplierPartyContactElectronicMail <> '') then begin
            this.AddElement(PartyNode, 'Contact', '', CacNamespaceTok, ContactNode);
            this.AddNonEmptyNode(ContactNode, 'Name', SellerSupplierPartyContactName, CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telephone', SellerSupplierPartyContactTelephone, CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'Telefax', SellerSupplierPartyContactTelefax, CbcNamespaceTok, ChildNode);
            this.AddNonEmptyNode(ContactNode, 'ElectronicMail', SellerSupplierPartyContactElectronicMail, CbcNamespaceTok, ChildNode);
        end;
    end;

    local procedure AddDelivery(PurchaseHeader: Record "Purchase Header")
    var
        PEPPOLDeliveryInfo: Interface "PEPPOL Purchase Delivery Info Provider";
        PEPPOLDeliveryPeriodInfo: Interface "PEPPOL PO Delivery Period";
        DeliveryNode: XmlNode;
        DeliveryLocationNode: XmlNode;
        RequestedDeliveryPeriodNode: XmlNode;
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
        RequestedStartDate: Text;
        RequestedEndDate: Text;
    begin
        PEPPOLDeliveryInfo := GetFormat();
        PEPPOLDeliveryPeriodInfo := GetFormat();
        PEPPOLDeliveryInfo.GetDeliveryAddress(PurchaseHeader, StreetName, AdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);

        this.AddElement(this.RootNode, 'Delivery', '', CacNamespaceTok, DeliveryNode);
        this.AddElement(DeliveryNode, 'DeliveryLocation', '', CacNamespaceTok, DeliveryLocationNode);
        this.AddElement(DeliveryLocationNode, 'Address', '', CacNamespaceTok, AddressNode);
        this.AddNonEmptyNode(AddressNode, 'StreetName', StreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'AdditionalStreetName', AdditionalStreetName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'CityName', CityName, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'PostalZone', PostalZone, CbcNamespaceTok, ChildNode);
        this.AddNonEmptyNode(AddressNode, 'CountrySubentity', CountrySubentity, CbcNamespaceTok, ChildNode);
        this.AddElement(AddressNode, 'Country', '', CacNamespaceTok, CountryNode);
        this.AddElement(CountryNode, 'IdentificationCode', IdentificationCode, CbcNamespaceTok, ChildNode);

        PEPPOLDeliveryPeriodInfo.GetRequestedDeliveryPeriod(PurchaseHeader, RequestedStartDate, RequestedEndDate);
        if RequestedStartDate <> '' then begin
            this.AddElement(DeliveryNode, 'RequestedDeliveryPeriod', '', CacNamespaceTok, RequestedDeliveryPeriodNode);
            this.AddElement(RequestedDeliveryPeriodNode, 'StartDate', RequestedStartDate, CbcNamespaceTok, ChildNode);
            this.AddElement(RequestedDeliveryPeriodNode, 'EndDate', RequestedEndDate, CbcNamespaceTok, ChildNode);
        end;
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

        this.AddElement(this.RootNode, 'PaymentTerms', '', CacNamespaceTok, PaymentTermsNode);
        this.AddNonEmptyNode(PaymentTermsNode, 'Note', PaymentTermsNote, CbcNamespaceTok, ChildNode);
    end;

    local procedure AddAnticipatedMonetaryTotal(PurchaseHeader: Record "Purchase Header")
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary;
        PEPPOL30Common: Codeunit "PEPPOL30 Common";
        PurchaseHeaderRecRef, PurchaseLineRecRef : RecordRef;
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

        this.AddElement(this.RootNode, 'AnticipatedMonetaryTotal', '', CacNamespaceTok, MonetaryTotalNode);
        this.AddElement(MonetaryTotalNode, 'LineExtensionAmount', LineExtensionAmount, CbcNamespaceTok, ChildNode);
        this.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
        this.AddElement(MonetaryTotalNode, 'TaxExclusiveAmount', TaxExclusiveAmount, CbcNamespaceTok, ChildNode);
        this.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
        this.AddElement(MonetaryTotalNode, 'TaxInclusiveAmount', TaxInclusiveAmount, CbcNamespaceTok, ChildNode);
        this.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
        this.AddElement(MonetaryTotalNode, 'PayableAmount', PayableAmount, CbcNamespaceTok, ChildNode);
        this.AddAttribute(ChildNode, 'currencyID', DocumentCurrencyCode);
    end;

    local procedure AddOrderLineToXML(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        PEPPOLLineInfo: Interface "PEPPOL Purchase Line Info Provider";
        PEPPOLLineDeliveryPeriodInfo: Interface "PEPPOL PO Line Delivery Period";
        OrderLineNode: XmlNode;
        LineItemNode: XmlNode;
        ItemNode: XmlNode;
        SellersItemIdNode: XmlNode;
        StandardItemIdNode: XmlNode;
        ClassifiedTaxCategoryNode: XmlNode;
        TaxSchemeNode: XmlNode;
        PriceNode: XmlNode;
        LineDeliveryNode: XmlNode;
        LineRequestedDeliveryPeriodNode: XmlNode;
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
        LineRequestedStartDate: Text;
        LineRequestedEndDate: Text;
    begin
        PEPPOLLineInfo := GetFormat();
        PEPPOLLineDeliveryPeriodInfo := GetFormat();
        PEPPOLLineInfo.GetLineGeneralInfo(PurchaseLine, PurchaseHeader, InvoiceLineID, InvoiceLineNote, InvoicedQuantity, InvoiceLineExtensionAmount, LineExtensionAmountCurrencyID, InvoiceLineAccountingCost);

        this.AddElement(this.RootNode, 'OrderLine', '', CacNamespaceTok, OrderLineNode);
        this.AddElement(OrderLineNode, 'LineItem', '', CacNamespaceTok, LineItemNode);
        this.AddElement(LineItemNode, 'ID', InvoiceLineID, CbcNamespaceTok, ChildNode);
        this.AddElement(LineItemNode, 'Quantity', InvoicedQuantity, CbcNamespaceTok, ChildNode);

        PEPPOLLineInfo.GetLinePriceInfo(PurchaseLine, PurchaseHeader, InvoiceLinePriceAmount, InvLinePriceAmountCurrencyID, BaseQuantity, UnitCode);

        this.AddAttribute(ChildNode, 'unitCode', UnitCode);
        this.AddElement(LineItemNode, 'LineExtensionAmount', InvoiceLineExtensionAmount, CbcNamespaceTok, ChildNode);
        this.AddAttribute(ChildNode, 'currencyID', InvLinePriceAmountCurrencyID);

        PEPPOLLineDeliveryPeriodInfo.GetLineRequestedDeliveryPeriod(PurchaseLine, LineRequestedStartDate, LineRequestedEndDate);
        if LineRequestedStartDate <> '' then begin
            this.AddElement(LineItemNode, 'Delivery', '', CacNamespaceTok, LineDeliveryNode);
            this.AddElement(LineDeliveryNode, 'RequestedDeliveryPeriod', '', CacNamespaceTok, LineRequestedDeliveryPeriodNode);
            this.AddElement(LineRequestedDeliveryPeriodNode, 'StartDate', LineRequestedStartDate, CbcNamespaceTok, ChildNode);
            this.AddElement(LineRequestedDeliveryPeriodNode, 'EndDate', LineRequestedEndDate, CbcNamespaceTok, ChildNode);
        end;

        this.AddElement(LineItemNode, 'Price', '', CacNamespaceTok, PriceNode);
        this.AddElement(PriceNode, 'PriceAmount', InvoiceLinePriceAmount, CbcNamespaceTok, ChildNode);
        this.AddAttribute(ChildNode, 'currencyID', InvLinePriceAmountCurrencyID);

        PEPPOLLineInfo.GetLineItemInfo(PurchaseLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID, OriginCountryIdCode, OriginCountryIdCodeListID);

        this.AddElement(LineItemNode, 'Item', '', CacNamespaceTok, ItemNode);
        this.AddNonEmptyNode(ItemNode, 'Description', Description, CbcNamespaceTok, ChildNode);
        this.AddElement(ItemNode, 'Name', Name, CbcNamespaceTok, ChildNode);
        this.AddElement(ItemNode, 'SellersItemIdentification', '', CacNamespaceTok, SellersItemIdNode);
        this.AddElement(SellersItemIdNode, 'ID', SellersItemIdentificationID, CbcNamespaceTok, ChildNode);
        this.AddElement(ItemNode, 'StandardItemIdentification', '', CacNamespaceTok, StandardItemIdNode);
        this.AddElement(StandardItemIdNode, 'ID', StandardItemIdentificationID, CbcNamespaceTok, ChildNode);
        this.AddAttribute(ChildNode, 'schemeID', StdItemIdIDSchemeID);

        PEPPOLLineInfo.GetLineItemClassifiedTaxCategory(PurchaseLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);

        this.AddElement(ItemNode, 'ClassifiedTaxCategory', '', CacNamespaceTok, ClassifiedTaxCategoryNode);
        this.AddElement(ClassifiedTaxCategoryNode, 'ID', ClassifiedTaxCategoryID, CbcNamespaceTok, ChildNode);
        this.AddElement(ClassifiedTaxCategoryNode, 'Percent', InvoiceLineTaxPercent, CbcNamespaceTok, ChildNode);
        this.AddElement(ClassifiedTaxCategoryNode, 'TaxScheme', '', CacNamespaceTok, TaxSchemeNode);
        this.AddElement(TaxSchemeNode, 'ID', ClassifiedTaxCategorySchemeID, CbcNamespaceTok, ChildNode);
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

        if CompanyID = '' then
            exit;

        this.AddElement(PartyNode, 'PartyTaxScheme', '', CacNamespaceTok, PartyTaxSchemeNode);
        this.AddElement(PartyTaxSchemeNode, 'CompanyID', CompanyID, CbcNamespaceTok, ChildNode);
        this.AddElement(PartyTaxSchemeNode, 'TaxScheme', '', CacNamespaceTok, TaxSchemeNode);
        this.AddElement(TaxSchemeNode, 'ID', TaxSchemeID, CbcNamespaceTok, ChildNode);
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

        this.AddElement(this.RootNode, 'AdditionalDocumentReference', '', CacNamespaceTok, AdditionalDocRefNode);
        this.AddElement(AdditionalDocRefNode, 'ID', AdditionalDocumentReferenceID, CbcNamespaceTok, ChildNode);
        this.AddElement(AdditionalDocRefNode, 'Attachment', '', CacNamespaceTok, AttachmentNode);
        this.AddElement(AttachmentNode, 'EmbeddedDocumentBinaryObject', EmbeddedDocumentBinaryObject, CbcNamespaceTok, EmbeddedDocNode);
        this.AddAttribute(EmbeddedDocNode, 'filename', Filename);
        this.AddAttribute(EmbeddedDocNode, 'mimeCode', MimeCode);
    end;

    local procedure AddNonEmptyNode(Node: XmlNode; NodeName: Text; NodeValue: Text; Namespace: Text; var ChildNode: XmlNode)
    begin
        if NodeValue <> '' then
            this.AddElement(Node, NodeName, NodeValue, Namespace, ChildNode);
    end;

    local procedure GetFormat(): Enum "PEPPOL 3.0 Purchase"
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
    procedure GetPurchaseOrderXML(var TempBlob: Codeunit "Temp Blob")
    begin
        this.PurchaseOrderXML.WriteTo(TempBlob.CreateOutStream());
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
        PEPPOL30PurchaseFormat := Format;
        IsFormatSet := true;
    end;

    local procedure AddElement(ParentXmlNode: XmlNode; NodeName: Text; NodeText: Text; Namespace: Text; var CreatedXmlNode: XmlNode)
    begin
        CreatedXmlNode := XmlElement.Create(NodeName, Namespace, NodeText).AsXmlNode();
        ParentXmlNode.AsXmlElement().Add(CreatedXmlNode);
    end;

    local procedure AddAttribute(ParentXmlNode: XmlNode; Name: Text; Value: Text)
    begin
        ParentXmlNode.AsXmlElement().SetAttribute(Name, Value);
    end;
}
