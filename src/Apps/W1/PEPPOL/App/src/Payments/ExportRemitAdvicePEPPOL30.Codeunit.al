namespace Microsoft.Peppol;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Utilities;
using System.Xml;

/// <summary>
/// Builds a UBL 2.1 RemittanceAdvice XML document from a "Remit. Advice Buffer" (header row
/// "Line No." = 0 plus one row per applied document). DOM-based, modeled on
/// Codeunit "Export Purchase Order PEPPOL30": localization-variable data (party endpoints,
/// payment means) is resolved through provider interfaces bound to the "PEPPOL 3.0 Purchase"
/// format enum, so localizations override data semantics by adding an enum value.
/// </summary>
codeunit 37208 "Export Remit. Advice PEPPOL30"
{
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        PEPPOL30PurchaseFormat: Enum "PEPPOL 3.0 Purchase";
        RemittanceAdviceXml: XmlDocument;
        RootNode: XmlNode;
        IsFormatSet: Boolean;
        UblNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:RemittanceAdvice-2', Locked = true;
        CacNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        CbcNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        PmtDiscountNoteMsg: Label 'Payment discount: %1', Comment = '%1 = formatted payment discount amount';

    /// <summary>
    /// Generates the UBL 2.1 RemittanceAdvice XML for the given buffer into TempBlob.
    /// </summary>
    /// <param name="TempBuffer">The remittance advice buffer: header row ("Line No." = 0) and applied-document line rows.</param>
    /// <param name="TempBlob">Return value: Temp Blob codeunit containing the XML document.</param>
    procedure GenerateXml(var TempBuffer: Record "Remit. Advice Buffer" temporary; var TempBlob: Codeunit "Temp Blob")
    begin
        TempBuffer.Reset();
        TempBuffer.SetRange("Line No.", 0);
        TempBuffer.FindFirst();

        this.InitializeXmlDocument();
        this.AddHeaderElements(TempBuffer);
        this.OnBeforeAddHeaderElements(TempBuffer, this.RootNode);
        this.AddAccountingCustomerParty();
        this.AddAccountingSupplierParty(TempBuffer);
        this.AddPaymentMeans(TempBuffer);

        TempBuffer.Reset();
        TempBuffer.SetFilter("Line No.", '>%1', 0);
        this.AddRemittanceAdviceLines(TempBuffer);

        this.RemittanceAdviceXml.WriteTo(TempBlob.CreateOutStream());
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

    local procedure InitializeXmlDocument()
    var
        RootElement: XmlElement;
    begin
        this.RemittanceAdviceXml := XmlDocument.Create();
        RootElement := XmlElement.Create('RemittanceAdvice', this.UblNamespaceTok);
        this.RootNode := RootElement.AsXmlNode();
        this.RemittanceAdviceXml.Add(this.RootNode);
        this.XMLDOMManagement.AddNamespaceDeclaration(this.RootNode, 'cac', this.CacNamespaceTok);
        this.XMLDOMManagement.AddNamespaceDeclaration(this.RootNode, 'cbc', this.CbcNamespaceTok);
    end;

    local procedure AddHeaderElements(HeaderBuffer: Record "Remit. Advice Buffer" temporary)
    var
        ChildNode: XmlNode;
        DocumentCurrencyCode: Code[10];
    begin
        DocumentCurrencyCode := this.GetDocumentCurrencyCode(HeaderBuffer."Currency Code");

        this.AddCbcElement(this.RootNode, 'UBLVersionID', '2.1', ChildNode);
        this.AddCbcElement(this.RootNode, 'ID', HeaderBuffer."Payment Document No.", ChildNode);
        this.AddCbcElement(this.RootNode, 'IssueDate', Format(HeaderBuffer."Payment Date", 0, 9), ChildNode);
        this.AddCbcElement(this.RootNode, 'DocumentCurrencyCode', DocumentCurrencyCode, ChildNode);
        this.AddMoneyElement(this.RootNode, 'TotalPaymentAmount', HeaderBuffer."Total Paid Amount", DocumentCurrencyCode, ChildNode);
        this.AddCbcElement(this.RootNode, 'PaymentOrderReference', HeaderBuffer."Payment Document No.", ChildNode);
        this.AddCbcElement(this.RootNode, 'LineCountNumeric', Format(this.CountLines(HeaderBuffer)), ChildNode);
    end;

    local procedure CountLines(HeaderBuffer: Record "Remit. Advice Buffer" temporary) LineCount: Integer
    var
        TempLineBuffer: Record "Remit. Advice Buffer" temporary;
    begin
        TempLineBuffer.Copy(HeaderBuffer, true);
        TempLineBuffer.Reset();
        TempLineBuffer.SetFilter("Line No.", '>%1', 0);
        LineCount := TempLineBuffer.Count();
    end;

    local procedure AddAccountingCustomerParty()
    var
        CompanyInfo: Record "Company Information";
        PEPPOLPartyInfo: Interface "PEPPOL Purchase Party Info Provider";
        PartyNode: XmlNode;
        EndpointID: Text;
        SchemeID: Text;
        PartyName: Text;
        TaxSchemeCompanyID: Text;
        TaxSchemeCompanyIDSchemeID: Text;
        TaxSchemeID: Text;
        LegalEntityRegName: Text;
        LegalEntityCompanyID: Text;
        LegalEntitySchemeID: Text;
        RegAddrCityName: Text;
        RegAddrCountryIdCode: Text;
        RegAddrCountryIdListId: Text;
    begin
        CompanyInfo.Get();
        PEPPOLPartyInfo := this.GetFormat();

        this.AddCacElement(this.RootNode, 'AccountingCustomerParty', PartyNode);
        this.AddCacElement(PartyNode, 'Party', PartyNode);

        // The provider's "accounting supplier party" methods return OUR company's identification
        // (naming reflects the company's role in the sales context); Export Purchase Order PEPPOL30
        // reuses them for BuyerCustomerParty the same way.
        PEPPOLPartyInfo.GetAccountingSupplierPartyInfoBIS(EndpointID, SchemeID, PartyName);
        this.AddEndpointID(PartyNode, EndpointID, SchemeID);
        this.AddPartyName(PartyNode, PartyName);
        this.AddPostalAddress(PartyNode, CompanyInfo.Address, CompanyInfo.City, CompanyInfo."Post Code", CompanyInfo."Country/Region Code");

        PEPPOLPartyInfo.GetAccountingSupplierPartyTaxScheme(TaxSchemeCompanyID, TaxSchemeCompanyIDSchemeID, TaxSchemeID);
        this.AddPartyTaxScheme(PartyNode, TaxSchemeCompanyID, TaxSchemeID);

        PEPPOLPartyInfo.GetAccountingSupplierPartyLegalEntityBIS(LegalEntityRegName, LegalEntityCompanyID, LegalEntitySchemeID, RegAddrCityName, RegAddrCountryIdCode, RegAddrCountryIdListId);
        this.AddPartyLegalEntity(PartyNode, LegalEntityRegName, LegalEntityCompanyID, LegalEntitySchemeID);
    end;

    local procedure AddAccountingSupplierParty(HeaderBuffer: Record "Remit. Advice Buffer" temporary)
    var
        Vendor: Record Vendor;
        PEPPOLRemitAdviceInfo: Interface "PEPPOL Remit. Advice Info Provider";
        PartyNode: XmlNode;
        EndpointID: Text;
        SchemeID: Text;
        PartyName: Text;
    begin
        Vendor.Get(HeaderBuffer."Vendor No.");
        PEPPOLRemitAdviceInfo := this.GetFormat();

        this.AddCacElement(this.RootNode, 'AccountingSupplierParty', PartyNode);
        this.AddCacElement(PartyNode, 'Party', PartyNode);

        PEPPOLRemitAdviceInfo.GetPayeePartyInfo(Vendor, EndpointID, SchemeID, PartyName);
        this.AddEndpointID(PartyNode, EndpointID, SchemeID);
        this.AddPartyName(PartyNode, PartyName);
        this.AddPostalAddress(PartyNode, Vendor.Address, Vendor.City, Vendor."Post Code", Vendor."Country/Region Code");
        this.AddPartyLegalEntity(PartyNode, PartyName, EndpointID, SchemeID);
    end;

    local procedure AddEndpointID(PartyNode: XmlNode; EndpointID: Text; SchemeID: Text)
    var
        ChildNode: XmlNode;
    begin
        if EndpointID = '' then
            exit;

        this.AddCbcElement(PartyNode, 'EndpointID', EndpointID, ChildNode);
        if SchemeID <> '' then
            this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', SchemeID);
    end;

    local procedure AddPartyName(PartyNode: XmlNode; PartyNameValue: Text)
    var
        PartyNameNode: XmlNode;
        ChildNode: XmlNode;
    begin
        this.AddCacElement(PartyNode, 'PartyName', PartyNameNode);
        this.AddCbcElement(PartyNameNode, 'Name', PartyNameValue, ChildNode);
    end;

    local procedure AddPostalAddress(PartyNode: XmlNode; StreetName: Text; CityName: Text; PostalZone: Code[20]; CountryRegionCode: Code[10])
    var
        AddressNode: XmlNode;
        CountryNode: XmlNode;
        ChildNode: XmlNode;
    begin
        this.AddCacElement(PartyNode, 'PostalAddress', AddressNode);
        this.AddNonEmptyCbcElement(AddressNode, 'StreetName', StreetName, ChildNode);
        this.AddNonEmptyCbcElement(AddressNode, 'CityName', CityName, ChildNode);
        this.AddNonEmptyCbcElement(AddressNode, 'PostalZone', PostalZone, ChildNode);

        if CountryRegionCode <> '' then begin
            this.AddCacElement(AddressNode, 'Country', CountryNode);
            this.AddCbcElement(CountryNode, 'IdentificationCode', CountryRegionCode, ChildNode);
        end;
    end;

    local procedure AddPartyTaxScheme(PartyNode: XmlNode; CompanyID: Text; TaxSchemeID: Text)
    var
        TaxSchemeNode: XmlNode;
        ChildNode: XmlNode;
    begin
        if CompanyID = '' then
            exit;

        this.AddCacElement(PartyNode, 'PartyTaxScheme', TaxSchemeNode);
        this.AddCbcElement(TaxSchemeNode, 'CompanyID', CompanyID, ChildNode);
        this.AddCacElement(TaxSchemeNode, 'TaxScheme', TaxSchemeNode);
        this.AddCbcElement(TaxSchemeNode, 'ID', TaxSchemeID, ChildNode);
    end;

    local procedure AddPartyLegalEntity(PartyNode: XmlNode; RegistrationName: Text; CompanyID: Text; SchemeID: Text)
    var
        LegalEntityNode: XmlNode;
        ChildNode: XmlNode;
    begin
        this.AddCacElement(PartyNode, 'PartyLegalEntity', LegalEntityNode);
        this.AddNonEmptyCbcElement(LegalEntityNode, 'RegistrationName', RegistrationName, ChildNode);

        if CompanyID = '' then
            exit;
        this.AddCbcElement(LegalEntityNode, 'CompanyID', CompanyID, ChildNode);
        if SchemeID <> '' then
            this.XMLDOMManagement.AddAttribute(ChildNode, 'schemeID', SchemeID);
    end;

    local procedure AddPaymentMeans(HeaderBuffer: Record "Remit. Advice Buffer" temporary)
    var
        PEPPOLRemitAdviceInfo: Interface "PEPPOL Remit. Advice Info Provider";
        PaymentMeansNode: XmlNode;
        AccountNode: XmlNode;
        ChildNode: XmlNode;
        PaymentMeansCode: Text;
        PayeeFinancialAccountID: Text;
    begin
        PEPPOLRemitAdviceInfo := this.GetFormat();
        PEPPOLRemitAdviceInfo.GetPaymentMeansInfo(HeaderBuffer, PaymentMeansCode, PayeeFinancialAccountID);
        if PaymentMeansCode = '' then
            exit;

        this.AddCacElement(this.RootNode, 'PaymentMeans', PaymentMeansNode);
        this.AddCbcElement(PaymentMeansNode, 'PaymentMeansCode', PaymentMeansCode, ChildNode);
        this.AddCbcElement(PaymentMeansNode, 'PaymentID', HeaderBuffer."Payment Document No.", ChildNode);

        if PayeeFinancialAccountID <> '' then begin
            this.AddCacElement(PaymentMeansNode, 'PayeeFinancialAccount', AccountNode);
            this.AddCbcElement(AccountNode, 'ID', PayeeFinancialAccountID, ChildNode);
        end;
    end;

    local procedure AddRemittanceAdviceLines(var LineBuffer: Record "Remit. Advice Buffer" temporary)
    var
        LineNode: XmlNode;
        BillingRefNode: XmlNode;
        DocRefNode: XmlNode;
        ChildNode: XmlNode;
        LineCurrencyCode: Code[10];
        SeqNo: Integer;
    begin
        if not LineBuffer.FindSet() then
            exit;

        repeat
            SeqNo += 1;
            LineCurrencyCode := this.GetDocumentCurrencyCode(LineBuffer."Line Currency Code");

            this.AddCacElement(this.RootNode, 'RemittanceAdviceLine', LineNode);
            this.AddCbcElement(LineNode, 'ID', Format(SeqNo), ChildNode);

            if LineBuffer."Applied Doc. Type" = LineBuffer."Applied Doc. Type"::"Credit Memo" then
                this.AddMoneyElement(LineNode, 'CreditLineAmount', LineBuffer."Paid Amount", LineCurrencyCode, ChildNode)
            else
                this.AddMoneyElement(LineNode, 'DebitLineAmount', LineBuffer."Paid Amount", LineCurrencyCode, ChildNode);

            this.AddMoneyElement(LineNode, 'BalanceAmount', LineBuffer."Remaining Amount", LineCurrencyCode, ChildNode);
            this.AddNonEmptyCbcElement(LineNode, 'InvoicingPartyReference', LineBuffer."External Document No.", ChildNode);

            if LineBuffer."Pmt. Discount Amount" <> 0 then
                this.AddCbcElement(LineNode, 'Note', StrSubstNo(this.PmtDiscountNoteMsg, this.FormatAmount(LineBuffer."Pmt. Discount Amount")), ChildNode);

            this.AddCacElement(LineNode, 'BillingReference', BillingRefNode);
            if LineBuffer."Applied Doc. Type" = LineBuffer."Applied Doc. Type"::"Credit Memo" then
                this.AddCacElement(BillingRefNode, 'CreditNoteDocumentReference', DocRefNode)
            else
                this.AddCacElement(BillingRefNode, 'InvoiceDocumentReference', DocRefNode);

            this.AddCbcElement(DocRefNode, 'ID', LineBuffer."Our Document No.", ChildNode);
            this.AddCbcElement(DocRefNode, 'IssueDate', Format(LineBuffer."Document Date", 0, 9), ChildNode);
        until LineBuffer.Next() = 0;
    end;

    local procedure GetDocumentCurrencyCode(CurrencyCode: Code[10]) DocumentCurrencyCode: Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        GLSetup.Get();
        exit(GLSetup."LCY Code");
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(Format(Round(Amount, 0.01), 0, 9));
    end;

    local procedure AddCbcElement(ParentNode: XmlNode; NodeName: Text; NodeValue: Text; var ChildNode: XmlNode)
    begin
        this.XMLDOMManagement.AddElement(ParentNode, NodeName, NodeValue, this.CbcNamespaceTok, ChildNode);
    end;

    local procedure AddNonEmptyCbcElement(ParentNode: XmlNode; NodeName: Text; NodeValue: Text; var ChildNode: XmlNode)
    begin
        if NodeValue <> '' then
            this.AddCbcElement(ParentNode, NodeName, NodeValue, ChildNode);
    end;

    local procedure AddCacElement(ParentNode: XmlNode; NodeName: Text; var ChildNode: XmlNode)
    begin
        this.XMLDOMManagement.AddElement(ParentNode, NodeName, '', this.CacNamespaceTok, ChildNode);
    end;

    local procedure AddMoneyElement(ParentNode: XmlNode; NodeName: Text; Amount: Decimal; CurrencyCode: Code[10]; var ChildNode: XmlNode)
    begin
        this.AddCbcElement(ParentNode, NodeName, this.FormatAmount(Amount), ChildNode);
        this.XMLDOMManagement.AddAttribute(ChildNode, 'currencyID', CurrencyCode);
    end;

    /// <summary>
    /// Raised right after the RemittanceAdvice header-level elements (UBLVersionID .. LineCountNumeric) have been
    /// added, before AccountingCustomerParty/AccountingSupplierParty/PaymentMeans/lines. Lets downstream apps
    /// inject elements such as CustomizationID/ProfileID (no PEPPOL BIS profile exists for remittance advice yet).
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddHeaderElements(var TempBuffer: Record "Remit. Advice Buffer" temporary; RootNode: XmlNode)
    begin
    end;
}
