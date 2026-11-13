codeunit 147564 "SII Event Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateXMLDocumentIsHandledBy3rdParty()
    var
        GLEntry: Record "G/L Entry";
        SIIEventTests: codeunit "SII Event Tests";
        SIIXMLCreator: codeunit "SII XML Creator";
        ResultXmlDocument, ExpectedXmlDocument : XmlDocument;
        ResultXML, ExpectedXML : text;
    begin
        BindSubscription(SIIEventTests);
        SIIXMLCreator.GenerateXml(GLEntry, ResultXmlDocument, 0, false);
        ResultXmlDocument.WriteTo(ResultXML);

        XmlDocument.ReadFrom(GetSampleXml(), ExpectedXmlDocument);
        ExpectedXmlDocument.WriteTo(ExpectedXML);

        Assert.AreEqual(ExpectedXML, ResultXML, 'Xml Document did not match.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NativeEventSubscriberAddsElement()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIEventTests: Codeunit "SII Event Tests";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: XmlDocument;
    begin
        // [SCENARIO] An element that a subscriber of OnAfterAddPurchTailV2 adds to the native node is in the SII XML
        Initialize();
        PostPurchaseInvoice(VendorLedgerEntry);

        SIIEventTests.SetScenario(TestScenario::NativeAfterAddPurchTail);
        BindSubscription(SIIEventTests);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, 0, false), IncorrectXMLDocErr);

        VerifyXPathCount(XMLDoc, '//*[name()=''siiLR:FacturaRecibida'']/*[name()=''siiLR:TestNative'']', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'siiLR:TestNative', TestValueTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchKeepsChangesToReloadedDocument()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SecondVendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: XmlDocument;
        BodyXmlNode: XmlNode;
        XmlText: Text;
    begin
        // [SCENARIO] A batch document that the caller reloaded with changes between two calls keeps the changes,
        // even when the caller inserted an element before the batch node
        Initialize();
        PostPurchaseInvoice(VendorLedgerEntry);
        PostPurchaseInvoice(SecondVendorLedgerEntry);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, 0, false), IncorrectXMLDocErr);
        XMLDoc.WriteTo(XmlText);
        XmlDocument.ReadFrom(XmlText, XMLDoc);
        XMLDoc.SelectSingleNode('//*[name()=''soapenv:Body'']', BodyXmlNode);
        BodyXmlNode.AsXmlElement().AddFirst(XmlElement.Create('CallerChange', TestNamespaceTxt, TestValueTxt));

        Assert.IsTrue(SIIXMLCreator.GenerateXml(SecondVendorLedgerEntry, XMLDoc, 0, false), IncorrectXMLDocErr);

        VerifyXPathCount(XMLDoc, '//*[local-name()=''CallerChange'']', 1);
        LibrarySII.VerifyXMLPurchDocHeaderCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLPurchDocCnt(XMLDoc, 2);
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [Test]
    [Scope('OnPrem')]
    procedure LegacyIsHandledEventSubscriberReplacesContent()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIEventTests: Codeunit "SII Event Tests";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: XmlDocument;
    begin
        // [SCENARIO] A subscriber of the obsolete DotNet event OnInitializePurchXmlBodyOnBeforeAssignExerciseAndPeriod
        // that adds its own Ejercicio and Periodo and sets IsHandled still decides the content of the SII XML
        Initialize();
        PostPurchaseInvoice(VendorLedgerEntry);

        SIIEventTests.SetScenario(TestScenario::LegacyExerciseAndPeriod);
        BindSubscription(SIIEventTests);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, 0, false), IncorrectXMLDocErr);

        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:Ejercicio', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:Ejercicio', LegacyYearTxt);
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:Periodo', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:Periodo', LegacyPeriodTxt);
        // The XML that follows the event is still added to the right elements
        VerifyXPathCount(XMLDoc, '//*[name()=''siiLR:RegistroLRFacturasRecibidas'']/*[name()=''siiLR:IDFactura'']', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LegacyEventSubscriberAddsElement()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIEventTests: Codeunit "SII Event Tests";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: XmlDocument;
    begin
        // [SCENARIO] An element that a subscriber of the obsolete DotNet event OnFillDetalleIVANodeOnBeforeExportTipoImpositivo
        // adds is in the SII XML, and the elements added after the event stay in the same DetalleIVA element
        Initialize();
        PostPurchaseInvoice(VendorLedgerEntry);

        SIIEventTests.SetScenario(TestScenario::LegacyDetalleIVAAddChild);
        BindSubscription(SIIEventTests);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, 0, false), IncorrectXMLDocErr);

        VerifyXPathCount(XMLDoc, '//*[name()=''sii:DetalleIVA'']/*[name()=''sii:TestLegacy'']', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:TestLegacy', TestValueTxt);
        VerifyXPathCount(XMLDoc, '//*[name()=''sii:DetalleIVA'']/*[name()=''sii:BaseImponible'']', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LegacyEventSubscriberMovesNode()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIEventTests: Codeunit "SII Event Tests";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: XmlDocument;
    begin
        // [SCENARIO] When a subscriber of the obsolete DotNet event points XMLNode to a new child element,
        // the elements added after the event go into that child, as with the DotNet document
        Initialize();
        PostPurchaseInvoice(VendorLedgerEntry);

        SIIEventTests.SetScenario(TestScenario::LegacyDetalleIVAMoveNode);
        BindSubscription(SIIEventTests);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, 0, false), IncorrectXMLDocErr);

        VerifyXPathCount(XMLDoc, '//*[name()=''sii:DetalleIVA'']/*[name()=''sii:TestLegacy'']/*[name()=''sii:BaseImponible'']', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LegacyGenerateXmlKeepsCallerChangesInBatch()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SecondVendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        BodyXmlNode: DotNet XmlNode;
        NewXmlNode: DotNet XmlNode;
        XmlText: Text;
        NativeXMLDoc: XmlDocument;
    begin
        // [SCENARIO] Changes that the caller makes to the DotNet document between two batch calls of the obsolete
        // DotNet GenerateXml are kept, as they were when the document was built with DotNet
        Initialize();
        PostPurchaseInvoice(VendorLedgerEntry);
        PostPurchaseInvoice(SecondVendorLedgerEntry);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, 0, false), IncorrectXMLDocErr);
        BodyXmlNode := XMLDoc.DocumentElement.LastChild;
        NewXmlNode := XMLDoc.CreateElement('CallerChange', TestNamespaceTxt);
        NewXmlNode.InnerText := TestValueTxt;
        BodyXmlNode.PrependChild(NewXmlNode);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(SecondVendorLedgerEntry, XMLDoc, 0, false), IncorrectXMLDocErr);

        XmlText := XMLDoc.OuterXml;
        XmlDocument.ReadFrom(XmlText, NativeXMLDoc);
        VerifyXPathCount(NativeXMLDoc, '//*[local-name()=''CallerChange'']', 1);
        LibrarySII.VerifyXMLPurchDocCnt(NativeXMLDoc, 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SII XML Creator", 'OnInitializePurchXmlBodyOnBeforeAssignExerciseAndPeriod', '', false, false)]
    local procedure LegacyAssignExerciseAndPeriod(var XMLNode: DotNet XmlNode; VendorLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    var
        NewXmlNode: DotNet XmlNode;
    begin
        if TestScenario <> TestScenario::LegacyExerciseAndPeriod then
            exit;
        AppendLegacyElement(XMLNode, 'Ejercicio', LegacyYearTxt, NewXmlNode);
        AppendLegacyElement(XMLNode, 'Periodo', LegacyPeriodTxt, NewXmlNode);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SII XML Creator", 'OnFillDetalleIVANodeOnBeforeExportTipoImpositivo', '', false, false)]
    local procedure LegacyBeforeExportTipoImpositivo(var XMLNode: DotNet XmlNode; var TempVATEntry: Record "VAT Entry" temporary)
    var
        NewXmlNode: DotNet XmlNode;
    begin
        case TestScenario of
            TestScenario::LegacyDetalleIVAAddChild:
                AppendLegacyElement(XMLNode, 'TestLegacy', TestValueTxt, NewXmlNode);
            TestScenario::LegacyDetalleIVAMoveNode:
                begin
                    AppendLegacyElement(XMLNode, 'TestLegacy', '', NewXmlNode);
                    XMLNode := NewXmlNode;
                end;
        end;
    end;

    local procedure AppendLegacyElement(ParentXmlNode: DotNet XmlNode; LocalName: Text; Value: Text; var NewXmlNode: DotNet XmlNode)
    begin
        NewXmlNode := ParentXmlNode.OwnerDocument.CreateElement('sii', LocalName, ParentXmlNode.NamespaceURI);
        if Value <> '' then
            NewXmlNode.InnerText := Value;
        ParentXmlNode.AppendChild(NewXmlNode);
    end;
#pragma warning restore AL0432
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SII XML Creator", 'OnAfterAddPurchTailV2', '', false, false)]
    local procedure NativeAfterAddPurchTail(var XMLNode: XmlNode; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        if TestScenario <> TestScenario::NativeAfterAddPurchTail then
            exit;
        XMLNode.AsXmlElement().Add(XmlElement.Create('TestNative', XMLNode.AsXmlElement().NamespaceUri(), TestValueTxt));
    end;

    procedure SetScenario(NewTestScenario: Option)
    begin
        TestScenario := NewTestScenario;
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        IsInitialized := true;
    end;

    local procedure PostPurchaseInvoice(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, 'ES', 'B80833593');
        DocumentNo := LibrarySII.CreatePurchDocumentWithDiffPayToVendor(true, Vendor."No.", Vendor."No.", 0, false);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
    end;

    local procedure VerifyXPathCount(XMLDoc: XmlDocument; XPath: Text; ExpectedCount: Integer)
    var
        XMLNodeList: XmlNodeList;
    begin
        XMLDoc.SelectNodes(XPath, XMLNodeList);
        Assert.AreEqual(ExpectedCount, XMLNodeList.Count(), StrSubstNo(WrongNodeCountErr, XPath));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SII XML Creator", 'OnBeforeGenerateXmlDocument', '', true, true)]
    local procedure GenerateXmlDocument(LedgerEntry: Variant; var XMLDocOut: XmlDocument; UploadType: Option; IsCreditMemoRemoval: Boolean; var ResultValue: Boolean; var IsHandled: Boolean; RetryAccepted: Boolean; SIIVersion: Option)
    begin
        if TestScenario <> TestScenario::ReplaceDocument then
            exit;
        XmlDocument.ReadFrom(GetSampleXml(), XMLDocOut);

        IsHandled := true;
        ResultValue := true;
    end;

    local procedure GetSampleXml() Xml: Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('<?xml version="1.0" encoding="utf-8" ?>');
        StringBuilder.Append('<bookstore xmlns="http://www.contoso.com/books">');
        StringBuilder.Append('    <book genre="autobiography" publicationdate="1981-03-22" ISBN="1-861003-11-0">');
        StringBuilder.Append('        <title>The Autobiography of Benjamin Franklin</title>');
        StringBuilder.Append('        <author>');
        StringBuilder.Append('            <first-name>Benjamin</first-name>');
        StringBuilder.Append('            <last-name>Franklin</last-name>');
        StringBuilder.Append('        </author>');
        StringBuilder.Append('        <price>8.99</price>');
        StringBuilder.Append('    </book>');
        StringBuilder.Append('</bookstore>');

        Xml := StringBuilder.ToText();
    end;

    var
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        TestScenario: Option ReplaceDocument,LegacyExerciseAndPeriod,LegacyDetalleIVAAddChild,LegacyDetalleIVAMoveNode,NativeAfterAddPurchTail;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        WrongNodeCountErr: Label 'Wrong number of nodes for XPath %1.', Comment = '%1 = XPath';
        TestValueTxt: Label 'TEST', Locked = true;
        TestNamespaceTxt: Label 'urn:test', Locked = true;
#if not CLEAN30
        LegacyYearTxt: Label '1999', Locked = true;
        LegacyPeriodTxt: Label '12', Locked = true;
#endif
}