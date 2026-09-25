// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;
using System.Utilities;

/// <summary>
/// Reusable PEPPOL BIS 3.0 extraction helpers for reading UBL XML into staging tables.
/// Contains generic UBL party, amounts, line, attachment, and currency logic
/// shared across Invoice and CreditNote document types.
/// </summary>
codeunit 6401 "E-Document PEPPOL Utility"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Namespace Initialization

    procedure InitializePEPPOL3Namespaces(var XmlNamespaces: XmlNamespaceManager)
    var
        CommonAggregateComponentsLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2';
        CommonBasicComponentsLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2';
        DocumentationLbl: Label 'urn:un:unece:uncefact:documentation:2';
        QualifiedDatatypesLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2';
        UnqualifiedDataTypesSchemaModuleLbl: Label 'urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2';
        DefaultInvoiceLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2';
        DefaultCreditNoteLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2';
    begin
        XmlNamespaces.AddNamespace('cac', CommonAggregateComponentsLbl);
        XmlNamespaces.AddNamespace('cbc', CommonBasicComponentsLbl);
        XmlNamespaces.AddNamespace('ccts', DocumentationLbl);
        XmlNamespaces.AddNamespace('qdt', QualifiedDatatypesLbl);
        XmlNamespaces.AddNamespace('udt', UnqualifiedDataTypesSchemaModuleLbl);
        XmlNamespaces.AddNamespace('inv', DefaultInvoiceLbl);
        XmlNamespaces.AddNamespace('cre', DefaultCreditNoteLbl);
    end;

    #endregion Namespace Initialization

    #region XML Value Extraction

    procedure TryGetStringValue(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; var Value: Text): Boolean
    var
        XMLNode: XmlNode;
    begin
        if not XMLDocument.SelectSingleNode(Path, XMLNamespaces, XMLNode) then
            exit(false);

        if XMLNode.IsXmlElement() then begin
            Value := XMLNode.AsXmlElement().InnerText();
            exit(true);
        end;

        if XMLNode.IsXmlAttribute() then begin
            Value := XMLNode.AsXmlAttribute().Value();
            exit(true);
        end;

        exit(false);
    end;

    procedure SetNumberValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; var DecimalValue: Decimal)
    var
        XMLNode: XmlNode;
    begin
        if not XMLDocument.SelectSingleNode(Path, XMLNamespaces, XMLNode) then
            exit;

        if not XMLNode.IsXmlElement() then
            exit;

        if XMLNode.AsXmlElement().InnerText() <> '' then
            Evaluate(DecimalValue, XMLNode.AsXmlElement().InnerText(), 9);
    end;

    procedure SetDateValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; var DateValue: Date)
    var
        XMLNode: XmlNode;
    begin
        if not XMLDocument.SelectSingleNode(Path, XMLNamespaces, XMLNode) then
            exit;

        if not XMLNode.IsXmlElement() then
            exit;

        if XMLNode.AsXmlElement().InnerText() <> '' then
            Evaluate(DateValue, XMLNode.AsXmlElement().InnerText(), 9);
    end;

    #endregion XML Value Extraction

    #region Header Field Extraction

    /// <summary>
    /// Extracts AccountingSupplierParty and PayeeParty fields from a UBL document.
    /// Per PEPPOL BIS 3.0: PartyName is optional; RegistrationName is mandatory fallback.
    /// PayeeParty, when present, overrides vendor name and VAT ID.
    /// SchemeID 0088 on EndpointID = GLN.
    /// </summary>
    internal procedure PopulateSupplierInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    var
        XmlNode: XmlNode;
        Value: Text;
    begin
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name', Value) then
            Header."Vendor Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Company Name"));
        if Header."Vendor Company Name" = '' then
            if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName', Value) then
                Header."Vendor Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Company Name"));
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:PayeeParty/cac:PartyName/cbc:Name', Value) then
            Header."Vendor Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Company Name"));
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:Contact/cbc:Name', Value) then
            Header."Vendor Contact Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Contact Name"));
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Vendor Address" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Address"));
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Vendor VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Vendor VAT Id"));
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:PayeeParty/cac:PartyLegalEntity/cbc:CompanyID', Value) then
            Header."Vendor VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Vendor VAT Id"));

        if PeppolXML.SelectSingleNode(RootPath + '/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID', XmlNamespaces, XmlNode) then
            if XmlNode.AsXmlAttribute().Value() = '0088' then
                if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID', Value) then
                    Header."Vendor GLN" := CopyStr(Value, 1, MaxStrLen(Header."Vendor GLN"));
    end;

    /// <summary>
    /// Extracts AccountingCustomerParty fields from a UBL document.
    /// Per PEPPOL BIS 3.0: PartyName is optional; RegistrationName is mandatory fallback.
    /// SchemeID 0088 on EndpointID = GLN. Customer Company Id stores schemeID:value.
    /// </summary>
    internal procedure PopulateCustomerInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    var
        XmlNode: XmlNode;
        SchemeID: Text;
        EndpointValue: Text;
        Value: Text;
    begin
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name', Value) then
            Header."Customer Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Customer Company Name"));
        if Header."Customer Company Name" = '' then
            if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName', Value) then
                Header."Customer Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Customer Company Name"));
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', Value) then
            Header."Customer VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer VAT Id"));
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Customer VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer VAT Id"));
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Customer Address" := CopyStr(Value, 1, MaxStrLen(Header."Customer Address"));

        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID', EndpointValue) then begin
            if PeppolXML.SelectSingleNode(RootPath + '/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID', XmlNamespaces, XmlNode) then
                SchemeID := XmlNode.AsXmlAttribute().Value();

            if SchemeID = '0088' then
                Header."Customer GLN" := CopyStr(EndpointValue, 1, MaxStrLen(Header."Customer GLN"));

            Header."Customer Company Id" := CopyStr(SchemeID + ':' + EndpointValue, 1, MaxStrLen(Header."Customer Company Id"));
        end;
    end;

    /// <summary>
    /// Extracts LegalMonetaryTotal amounts, IssueDate, and DueDate from a UBL document.
    /// DueDatePath is parameterized because Invoice uses /cbc:DueDate while
    /// CreditNote uses /cac:PaymentMeans/cbc:PaymentDueDate.
    /// </summary>
    internal procedure PopulateAmountsAndDates(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; DueDatePath: Text; var Header: Record "E-Document Purchase Header")
    begin
        SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:LegalMonetaryTotal/cbc:PayableAmount', Header.Total);
        SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', Header."Sub Total");
        SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount', Header."Total Discount");
        Header."Total VAT" := Header."Total" - Header."Sub Total" - Header."Total Discount";

        SetDateValueInField(PeppolXML, XmlNamespaces, DueDatePath, Header."Due Date");
        SetDateValueInField(PeppolXML, XmlNamespaces, RootPath + '/cbc:IssueDate', Header."Document Date");
    end;

    /// <summary>
    /// Extracts DocumentCurrencyCode and applies the BC LCY-blank convention.
    /// </summary>
    internal procedure PopulateCurrency(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    var
        DocumentCurrencyCode: Text;
    begin
        if TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cbc:DocumentCurrencyCode', DocumentCurrencyCode) then
            SetCurrencyIfForeign(DocumentCurrencyCode, Header."Currency Code");
    end;

    #endregion Header Field Extraction

    #region Line Field Extraction

    /// <summary>
    /// Populates a staging line record from a UBL InvoiceLine or CreditNoteLine element.
    /// LineElementName and QuantityElementName are parameterized to handle both document types.
    /// </summary>
    internal procedure PopulatePurchaseLine(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Purchase Line"; LineElementName: Text; QuantityElementName: Text)
    var
        Value: Text;
    begin
        SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/' + QuantityElementName, Line.Quantity);
        if TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/' + QuantityElementName + '/@unitCode', Value) then
            Line."Unit of Measure" := CopyStr(Value, 1, MaxStrLen(Line."Unit of Measure"));
        SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount', Line."Sub Total");
        SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:AllowanceCharge/cbc:Amount', Line."Total Discount");

        // Per PEPPOL BIS 3.0: Item Name (1..1, mandatory) is the primary short product description.
        // Item Description (0..1) is an optional longer description that may exceed field capacity.
        // Priority: Name (always present per spec), fallback to Description if Name is absent.
        if TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cbc:Name', Value) then
            Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));
        if Line.Description = '' then
            if TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cbc:Description', Value) then
                Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));

        // Per PEPPOL BIS 3.0: SellersItemIdentification is the seller's internal product code.
        // StandardItemIdentification is a registered standard (e.g., GTIN via schemeID 0160).
        // StandardItemIdentification takes priority as the more universally recognized identifier.
        if TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:SellersItemIdentification/cbc:ID', Value) then
            if Value <> '' then
                Line."Product Code" := CopyStr(Value, 1, MaxStrLen(Line."Product Code"));
        if TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:StandardItemIdentification/cbc:ID', Value) then
            if Value <> '' then
                Line."Product Code" := CopyStr(Value, 1, MaxStrLen(Line."Product Code"));

        SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent', Line."VAT Rate");
        SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Price/cbc:PriceAmount', Line."Unit Price");

        PopulateLineCurrency(LineXML, XmlNamespaces, Line, LineElementName);
    end;

    local procedure PopulateLineCurrency(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Purchase Line"; LineElementName: Text)
    var
        LineCurrencyCode: Text;
    begin
        if TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount/@currencyID', LineCurrencyCode) then
            SetCurrencyIfForeign(LineCurrencyCode, Line."Currency Code");
    end;

    #endregion Line Field Extraction

    #region Attachment Extraction

    /// <summary>
    /// Extracts a single embedded base64 attachment from an AdditionalDocumentReference element.
    /// Skips external URI references and bare references without embedded content.
    /// Per PEPPOL BIS 3.0: @filename and @mimeCode are mandatory on EmbeddedDocumentBinaryObject.
    /// </summary>
    internal procedure ExtractAttachment(EDocument: Record "E-Document"; AttachmentXML: XmlDocument; XmlNamespaces: XmlNamespaceManager)
    var
        EDocAttachmentProcessor: Codeunit "E-Doc. Attachment Processor";
        Base64Convert: Codeunit "Base64 Convert";
        AttachmentBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        Base64Content: Text;
        FileName: Text;
        MimeCode: Text;
        FileExtension: Text;
        ElementName: Text;
    begin
        ElementName := 'cac:AdditionalDocumentReference';

        if not TryGetStringValue(AttachmentXML, XmlNamespaces, ElementName + '/cac:Attachment/cbc:EmbeddedDocumentBinaryObject', Base64Content) then
            exit;

        if Base64Content = '' then
            exit;

        if not TryGetStringValue(AttachmentXML, XmlNamespaces, ElementName + '/cac:Attachment/cbc:EmbeddedDocumentBinaryObject/@filename', FileName) then
            TryGetStringValue(AttachmentXML, XmlNamespaces, ElementName + '/cbc:ID', FileName);

        if FileName = '' then
            exit;

        if not FileName.Contains('.') then
            if TryGetStringValue(AttachmentXML, XmlNamespaces, ElementName + '/cac:Attachment/cbc:EmbeddedDocumentBinaryObject/@mimeCode', MimeCode) then begin
                FileExtension := MimeToFileExtension(MimeCode);
                if FileExtension <> '' then
                    FileName := FileName + '.' + FileExtension;
            end;

        AttachmentBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(Base64Content, OutStream);
        AttachmentBlob.CreateInStream(InStream);
        EDocAttachmentProcessor.Insert(EDocument, InStream, FileName);
    end;

    local procedure MimeToFileExtension(MimeCode: Text): Text
    begin
        case MimeCode of
            'image/jpeg':
                exit('jpeg');
            'image/png':
                exit('png');
            'application/pdf':
                exit('pdf');
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
                exit('xlsx');
            'application/vnd.oasis.opendocument.spreadsheet':
                exit('ods');
            'text/csv':
                exit('csv');
            else
                exit('');
        end;
    end;

    #endregion Attachment Extraction

    #region Currency

    /// <summary>
    /// BC convention: blank Currency Code means LCY. Sets the field to the currency code
    /// only if it differs from LCY. Explicitly blanks the field when it matches LCY.
    /// </summary>
    procedure SetCurrencyIfForeign(CurrencyFromXml: Text; var CurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrencyFromXml = '' then
            exit;

        GLSetup.GetRecordOnce();
        if GLSetup."LCY Code" = CopyStr(CurrencyFromXml, 1, MaxStrLen(CurrencyCode)) then
            CurrencyCode := ''
        else
            CurrencyCode := CopyStr(CurrencyFromXml, 1, MaxStrLen(CurrencyCode));
    end;

    #endregion Currency
}
