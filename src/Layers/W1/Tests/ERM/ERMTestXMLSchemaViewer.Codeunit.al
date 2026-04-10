codeunit 134402 "ERM - Test XML Schema Viewer"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [XML Schema]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        XMLDateFormatTxt: Label 'YYYY-MM-DD', Locked = true;
        XMLDateTimeFormatTxt: Label 'YYYY-MM-DDThh:mm:ss', Locked = true;
        DefaultCultureTxt: Label 'en-US', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure ReadSchemaFile()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XMLSchemaRestriction: Record "XML Schema Restriction";
        OutStr: OutStream;
        ExportFileName: Text;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);
        XMLSchema.TestField("Target Namespace");
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        Assert.AreEqual(XMLSchemaElement.Count, 8, 'Schema was not parsed correctly. Wrong number of elements.');
        XMLSchemaRestriction.SetRange("XML Schema Code", XMLSchema.Code);
        Assert.AreEqual(16, XMLSchemaRestriction.Count, 'Schema was not parsed correctly. Wrong number of enumerations.');
        ExportFileName := XMLSchema.ExportSchema(false);
        Assert.AreNotEqual('', ExportFileName, 'No filename was retrieved from export schema.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelection()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.SetRange("Node Name", 'Test2');
        XMLSchemaElement.FindFirst();
        Assert.IsFalse(XMLSchemaElement.Selected, 'Test2 was expected to have Selected=No.');
        Assert.AreEqual(XMLSchemaElement.MinOccurs, 0, 'Test2 was expected to have MinOccures=0.');
        XMLSchemaElement.SetRange("Node Name");
        XMLSchemaElement.ModifyAll(Selected, false);
        XMLSchemaElement.Validate(Selected, true);
        XMLSchemaElement.TestField("Simple Data Type", 'string');
        XMLSchemaElement.FindFirst();
        Assert.IsTrue(XMLSchemaElement.Selected, 'Parent was expected to have Selected=Yes.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeselection()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XSDParser: Codeunit "XSD Parser";
        OutStr: OutStream;
        DefaultSelectedCount: Integer;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.SetRange(Selected, true);
        DefaultSelectedCount := XMLSchemaElement.Count;
        XSDParser.DeselectAll(XMLSchemaElement);
        Assert.AreEqual(XMLSchemaElement.Count, 0, 'Unexpected Selected elements.');
        XMLSchemaElement.SetRange(Selected);
        XMLSchemaElement.FindLast();
        XSDParser.SelectMandatory(XMLSchemaElement);
        XMLSchemaElement.SetRange(Selected, true);
        Assert.AreEqual(DefaultSelectedCount, XMLSchemaElement.Count, 'Wrong number of selected elements.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectMandatorySubnodes()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.ModifyAll(Selected, false);
        XMLSchemaElement.SetRange("Node Name", 'GrpHdr');
        XMLSchemaElement.FindFirst();
        XMLSchemaElement.Validate(Selected, true);
        XMLSchemaElement.Modify();
        XMLSchemaElement.SetRange("Node Name", 'MsgId');
        XMLSchemaElement.FindFirst();
        Assert.IsTrue(XMLSchemaElement.Selected, 'Child was expected to have Selected=Yes.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectMandatorySubnodesUsingAction()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XSDParser: Codeunit "XSD Parser";
        OutStr: OutStream;
    begin
        Initialize();

        // Setup.
        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.ModifyAll(Selected, true);
        XMLSchemaElement.SetRange("Node Name", 'GrpHdr');
        XMLSchemaElement.FindFirst();
        XMLSchemaElement.Validate(Selected, false);
        XMLSchemaElement.Modify();

        // Exercise.
        XSDParser.SelectMandatory(XMLSchemaElement);

        // Verify.
        XMLSchemaElement.SetRange("Node Name", 'MsgId');
        XMLSchemaElement.FindFirst();
        Assert.IsTrue(XMLSchemaElement.Selected, 'Child was expected to have Selected=Yes.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSchemaContext()
    var
        XMLSchema: Record "XML Schema";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);
        Assert.AreEqual('/Document/CstmrCdtTrfInitn', XMLSchema.GetSchemaContext(), 'Wrong common context for schema.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFiltering()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XSDParser: Codeunit "XSD Parser";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XSDParser.HideNotMandatory(XMLSchemaElement);
        Assert.AreEqual(XMLSchemaElement.Count, 7, 'Wrong number of mandatory elements.');
        XSDParser.ShowAll(XMLSchemaElement);
        Assert.AreEqual(XMLSchemaElement.Count, 8, 'Wrong number of elements.');
        XSDParser.HideNotSelected(XMLSchemaElement);
        Assert.AreEqual(XMLSchemaElement.Count, 7, 'Wrong number of selected elements.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletion()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XMLSchemaRestriction: Record "XML Schema Restriction";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);

        // Verify
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaRestriction.SetRange("XML Schema Code", XMLSchema.Code);
        Assert.IsFalse(XMLSchemaElement.IsEmpty, 'No tags were found.');
        Assert.IsFalse(XMLSchemaRestriction.IsEmpty, 'No enum. tags were found.');
        XMLSchema.Delete(true);
        Assert.IsTrue(XMLSchemaElement.IsEmpty, 'Tags were found.');
        Assert.IsTrue(XMLSchemaRestriction.IsEmpty, 'Enum. tags were found.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestParsingElementWithComplexTypeNested()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFileWithComplexTypeNestedFile(OutStr);
        LoadSchemaFile(XMLSchema);

        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);

        // Verify Nodes
        Assert.AreEqual(6, XMLSchemaElement.Count, 'Wrong number of nodes found');

        // Verify Paths
        VerifyFullPath(XMLSchema, 'Customer', '/Customer');
        VerifyFullPath(XMLSchema, 'Dob', '/Customer/Dob');
        VerifyFullPath(XMLSchema, 'Address', '/Customer/Address');
        VerifyFullPath(XMLSchema, 'Line1', '/Customer/Address/Line1');
        VerifyFullPath(XMLSchema, 'Line2', '/Customer/Address/Line2');
        VerifyFullPath(XMLSchema, 'NoOfInvoices', '/Customer/NoOfInvoices');

        // Verify Types
        VerifySimpleDataType(XMLSchema, 'Customer', '');
        VerifySimpleDataType(XMLSchema, 'Dob', 'date');
        VerifySimpleDataType(XMLSchema, 'Address', '');
        VerifySimpleDataType(XMLSchema, 'Line1', 'string');
        VerifySimpleDataType(XMLSchema, 'Line2', 'string');
        VerifySimpleDataType(XMLSchema, 'NoOfInvoices', 'integer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestParsingGlobalComplexType()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFileWithGlobalComplexType(OutStr);
        LoadSchemaFile(XMLSchema);

        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);

        // Verify Nodes
        Assert.AreEqual(11, XMLSchemaElement.Count, 'Wrong number of nodes found');

        // Verify Paths
        VerifyFullPath(XMLSchema, 'Customer', '/Customer');
        VerifyFullPath(XMLSchema, 'Dob', '/Customer/Dob');
        VerifyFullPath(XMLSchema, 'Address', '/Customer/Address');
        VerifyFullPath(XMLSchema, 'Line1', '/Customer/Address/Line1');
        VerifyFullPath(XMLSchema, 'Line2', '/Customer/Address/Line2');
        VerifyFullPath(XMLSchema, 'CompanyAddress', '/Customer/CompanyAddress');
        VerifyFullPath(XMLSchema, 'Line1', '/Customer/CompanyAddress/Line1');
        VerifyFullPath(XMLSchema, 'Line2', '/Customer/CompanyAddress/Line2');
        VerifyFullPath(XMLSchema, 'CompanyAddress', '/CompanyAddress');
        VerifyFullPath(XMLSchema, 'Line1', '/CompanyAddress/Line1');
        VerifyFullPath(XMLSchema, 'Line2', '/CompanyAddress/Line2');

        // Verify Types
        VerifySimpleDataType(XMLSchema, 'Customer', '');
        VerifySimpleDataType(XMLSchema, 'Dob', 'date');
        VerifySimpleDataType(XMLSchema, 'Address', '');
        VerifySimpleDataType(XMLSchema, 'Line1', 'string');
        VerifySimpleDataType(XMLSchema, 'Line2', 'string');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestParsingReferenceElements()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFileWithReferences(OutStr);
        LoadSchemaFile(XMLSchema);

        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);

        // Verify Nodes
        Assert.AreEqual(28, XMLSchemaElement.Count, 'Wrong number of nodes found');

        // Verify Paths
        VerifyFullPath(XMLSchema, 'purchaseOrder', '/purchaseOrder');
        VerifyFullPath(XMLSchema, 'orderDate', '/purchaseOrder[@orderDate]');
        VerifyFullPath(XMLSchema, 'shipTo', '/purchaseOrder/shipTo');
        VerifyFullPath(XMLSchema, 'name', '/purchaseOrder/shipTo/name');
        VerifyFullPath(XMLSchema, 'street', '/purchaseOrder/shipTo/street');
        VerifyFullPath(XMLSchema, 'country', '/purchaseOrder/shipTo[@country]');
        VerifyFullPath(XMLSchema, 'billTo', '/purchaseOrder/billTo');
        VerifyFullPath(XMLSchema, 'name', '/purchaseOrder/billTo/name');
        VerifyFullPath(XMLSchema, 'street', '/purchaseOrder/billTo/street');
        VerifyFullPath(XMLSchema, 'country', '/purchaseOrder/billTo[@country]');
        VerifyFullPath(XMLSchema, 'comment', '/purchaseOrder/comment');
        VerifyFullPath(XMLSchema, 'items', '/purchaseOrder/items');
        VerifyFullPath(XMLSchema, 'item', '/purchaseOrder/items/item');
        VerifyFullPath(XMLSchema, 'productName', '/purchaseOrder/items/item/productName');
        VerifyFullPath(XMLSchema, 'USPrice', '/purchaseOrder/items/item/USPrice');
        VerifyFullPath(XMLSchema, 'quantity', '/purchaseOrder/items/item/quantity');
        VerifyFullPath(XMLSchema, 'comment', '/purchaseOrder/items/item/comment');
        VerifyFullPath(XMLSchema, 'shipDate', '/purchaseOrder/items/item/shipDate');
        VerifyFullPath(XMLSchema, 'xs:decimal', '/purchaseOrder/items/item[@xs:decimal]');

        VerifyFullPath(XMLSchema, 'comment', '/comment');

        VerifyFullPath(XMLSchema, 'shipTo', '/shipTo');
        VerifyFullPath(XMLSchema, 'name', '/shipTo/name');
        VerifyFullPath(XMLSchema, 'street', '/shipTo/street');
        VerifyFullPath(XMLSchema, 'country', '/shipTo[@country]');

        VerifyFullPath(XMLSchema, 'billTo', '/billTo');
        VerifyFullPath(XMLSchema, 'name', '/billTo/name');
        VerifyFullPath(XMLSchema, 'street', '/billTo/street');
        VerifyFullPath(XMLSchema, 'country', '/billTo[@country]');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestParsingReferenceElementsWithAlternativeNamespace()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFileWithReferencesAlternativeNamespace(OutStr);
        LoadSchemaFile(XMLSchema);

        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);

        // Verify Nodes
        Assert.AreEqual(28, XMLSchemaElement.Count, 'Wrong number of nodes found');

        // Verify Paths
        VerifyFullPath(XMLSchema, 'purchaseOrder', '/purchaseOrder');
        VerifyFullPath(XMLSchema, 'orderDate', '/purchaseOrder[@orderDate]');
        VerifyFullPath(XMLSchema, 'cac:shipTo', '/purchaseOrder/cac:shipTo');
        VerifyFullPath(XMLSchema, 'cac:name', '/purchaseOrder/cac:shipTo/cac:name');
        VerifyFullPath(XMLSchema, 'cac:street', '/purchaseOrder/cac:shipTo/cac:street');
        VerifyFullPath(XMLSchema, 'country', '/purchaseOrder/cac:shipTo[@country]');
        VerifyFullPath(XMLSchema, 'cac:billTo', '/purchaseOrder/cac:billTo');
        VerifyFullPath(XMLSchema, 'cac:name', '/purchaseOrder/cac:billTo/cac:name');
        VerifyFullPath(XMLSchema, 'cac:street', '/purchaseOrder/cac:billTo/cac:street');
        VerifyFullPath(XMLSchema, 'country', '/purchaseOrder/cac:billTo[@country]');
        VerifyFullPath(XMLSchema, 'cac:comment', '/purchaseOrder/cac:comment');
        VerifyFullPath(XMLSchema, 'items', '/purchaseOrder/items');
        VerifyFullPath(XMLSchema, 'item', '/purchaseOrder/items/item');
        VerifyFullPath(XMLSchema, 'productName', '/purchaseOrder/items/item/productName');
        VerifyFullPath(XMLSchema, 'USPrice', '/purchaseOrder/items/item/USPrice');
        VerifyFullPath(XMLSchema, 'quantity', '/purchaseOrder/items/item/quantity');
        VerifyFullPath(XMLSchema, 'comment', '/purchaseOrder/items/item/comment');
        VerifyFullPath(XMLSchema, 'shipDate', '/purchaseOrder/items/item/shipDate');
        VerifyFullPath(XMLSchema, 'xs:decimal', '/purchaseOrder/items/item[@xs:decimal]');

        VerifyFullPath(XMLSchema, 'comment', '/comment');

        VerifyFullPath(XMLSchema, 'shipTo', '/shipTo');
        VerifyFullPath(XMLSchema, 'name', '/shipTo/name');
        VerifyFullPath(XMLSchema, 'street', '/shipTo/street');
        VerifyFullPath(XMLSchema, 'country', '/shipTo[@country]');

        VerifyFullPath(XMLSchema, 'billTo', '/billTo');
        VerifyFullPath(XMLSchema, 'name', '/billTo/name');
        VerifyFullPath(XMLSchema, 'street', '/billTo/street');
        VerifyFullPath(XMLSchema, 'country', '/billTo[@country]');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestParsingExtensions()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFileWithExtensions(OutStr);
        LoadSchemaFile(XMLSchema);

        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);

        // Verify Nodes
        Assert.AreEqual(6, XMLSchemaElement.Count, 'Wrong number of nodes found');

        // Verify Paths
        VerifyFullPath(XMLSchema, 'para', '/para');
        VerifyFullPath(XMLSchema, 'fname', '/para/fname');
        VerifyFullPath(XMLSchema, 'lname', '/para/lname');
        VerifyFullPath(XMLSchema, 'gen', '/para/gen');
        VerifyFullPath(XMLSchema, 'label', '/para/gen[@label]');
        VerifyFullPath(XMLSchema, 'description', '/para/description');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDetectingInfiniteLoops()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFileWithInfiniteLoops(OutStr);
        LoadSchemaFile(XMLSchema);

        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);

        // Verify Nodes
        Assert.AreEqual(18, XMLSchemaElement.Count, 'Wrong number of nodes found');

        // Verify Paths
        VerifyFullPath(XMLSchema, 'SelfReferencingNode', '/SelfReferencingNode');
        VerifyFullPath(XMLSchema, 'AdditionalInformationParty', '/AdditionalInformationParty');
        VerifyFullPath(XMLSchema, 'Contact', '/AdditionalInformationParty/Contact');
        VerifyFullPath(XMLSchema, 'address', '/AdditionalInformationParty/Contact/address');
        VerifyFullPath(XMLSchema, 'ContactParty', '/AdditionalInformationParty/Contact/ContactParty');
        VerifyFullPath(XMLSchema, 'contactName', '/AdditionalInformationParty/Contact/ContactParty/contactName');
        VerifyFullPath(XMLSchema, 'Contact', '/AdditionalInformationParty/Contact/ContactParty/Contact');
        VerifyFullPath(XMLSchema, 'ContactParty', '/AdditionalInformationParty/ContactParty');

        VerifyFullPath(XMLSchema, 'Contact', '/Contact');
        VerifyFullPath(XMLSchema, 'address', '/Contact/address');
        VerifyFullPath(XMLSchema, 'ContactParty', '/Contact/ContactParty');
        VerifyFullPath(XMLSchema, 'contactName', '/Contact/ContactParty/contactName');
        VerifyFullPath(XMLSchema, 'Contact', '/Contact/ContactParty/Contact');

        VerifyFullPath(XMLSchema, 'ContactParty', '/ContactParty');
        VerifyFullPath(XMLSchema, 'contactName', '/ContactParty/contactName');
        VerifyFullPath(XMLSchema, 'Contact', '/ContactParty/Contact');
        VerifyFullPath(XMLSchema, 'address', '/Contact/address');
        VerifyFullPath(XMLSchema, 'ContactParty', '/ContactParty/Contact/ContactParty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectedIsNotSetOnInfiniteLoop()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFileWithInfiniteLoops(OutStr);
        LoadSchemaFile(XMLSchema);

        // Verify Nodes
        GetElementByPath('Contact', '/Contact/ContactParty/Contact', XMLSchema, XMLSchemaElement);
        Assert.IsFalse(XMLSchemaElement.Selected, 'Infinite loop elements should not be marked as selected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExtendingNotSelectedElements()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFileWithInfiniteLoops(OutStr);
        LoadSchemaFile(XMLSchema);

        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);

        // Verify Nodes
        GetElementByPath('Contact', '/Contact/ContactParty/Contact', XMLSchema, XMLSchemaElement);
        XMLSchemaElement.Validate(Selected, true);
        XMLSchemaElement.Modify(true);

        Assert.AreEqual(22, XMLSchemaElement.Count, 'Wrong number of nodes found');

        // Verify Paths
        VerifyFullPath(XMLSchema, 'SelfReferencingNode', '/SelfReferencingNode');
        VerifyFullPath(XMLSchema, 'AdditionalInformationParty', '/AdditionalInformationParty');
        VerifyFullPath(XMLSchema, 'Contact', '/AdditionalInformationParty/Contact');
        VerifyFullPath(XMLSchema, 'address', '/AdditionalInformationParty/Contact/address');
        VerifyFullPath(XMLSchema, 'ContactParty', '/AdditionalInformationParty/Contact/ContactParty');
        VerifyFullPath(XMLSchema, 'contactName', '/AdditionalInformationParty/Contact/ContactParty/contactName');

        VerifyFullPath(XMLSchema, 'Contact', '/AdditionalInformationParty/Contact/ContactParty/Contact');
        VerifyFullPath(XMLSchema, 'ContactParty', '/AdditionalInformationParty/ContactParty');

        VerifyFullPath(XMLSchema, 'Contact', '/Contact');
        VerifyFullPath(XMLSchema, 'address', '/Contact/address');
        VerifyFullPath(XMLSchema, 'ContactParty', '/Contact/ContactParty');
        VerifyFullPath(XMLSchema, 'contactName', '/Contact/ContactParty/contactName');
        VerifyFullPath(XMLSchema, 'Contact', '/Contact/ContactParty/Contact');
        VerifyFullPath(XMLSchema, 'address', '/Contact/ContactParty/Contact/address');
        VerifyFullPath(XMLSchema, 'ContactParty', '/Contact/ContactParty/Contact/ContactParty');
        VerifyFullPath(XMLSchema, 'address', '/Contact/ContactParty/Contact/address');

        VerifyFullPath(XMLSchema, 'ContactParty', '/ContactParty');
        VerifyFullPath(XMLSchema, 'contactName', '/ContactParty/contactName');
        VerifyFullPath(XMLSchema, 'Contact', '/ContactParty/Contact');
        VerifyFullPath(XMLSchema, 'address', '/Contact/address');
        VerifyFullPath(XMLSchema, 'ContactParty', '/ContactParty/Contact/ContactParty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTriggeringSelectedDoesntExpandTwice()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFileWithInfiniteLoops(OutStr);
        LoadSchemaFile(XMLSchema);

        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);

        // Verify Nodes
        GetElementByPath('Contact', '/Contact/ContactParty/Contact', XMLSchema, XMLSchemaElement);
        XMLSchemaElement.Validate(Selected, true);
        XMLSchemaElement.Modify(true);

        Assert.AreEqual(22, XMLSchemaElement.Count, 'Wrong number of nodes found');

        XMLSchemaElement.Validate(Selected, false);
        XMLSchemaElement.Modify(true);

        XMLSchemaElement.Validate(Selected, true);
        XMLSchemaElement.Modify(true);

        Assert.AreEqual(22, XMLSchemaElement.Count, 'Element should not be expanded twice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestParseIncludeAndImportStatements()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XSDParser: Codeunit "XSD Parser";
        FileManagement: Codeunit "File Management";
        InfiniteLoopDefinitionFile: File;
        AlternativeNamespaceDefinitionFile: File;
        MainDefinitionFile: File;
        InfiniteLoopOutStr: OutStream;
        AlternativeNamespaceSchemaOutStr: OutStream;
        MainDefinitionOutStr: OutStream;
        OutStream: OutStream;
        InStream: InStream;
    begin
        Initialize();

        // Create Files
        InfiniteLoopDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        InfiniteLoopDefinitionFile.CreateOutStream(InfiniteLoopOutStr);
        CreateSchemaFileWithInfiniteLoops(InfiniteLoopOutStr);

        AlternativeNamespaceDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        AlternativeNamespaceDefinitionFile.CreateOutStream(AlternativeNamespaceSchemaOutStr);
        CreateSchemaFileWithReferencesAlternativeNamespace(AlternativeNamespaceSchemaOutStr);

        MainDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        MainDefinitionFile.CreateOutStream(MainDefinitionOutStr);
        CreateSchemaFileWithImportAndIncludeStatements(
          MainDefinitionOutStr, InfiniteLoopDefinitionFile.Name, AlternativeNamespaceDefinitionFile.Name);

        XMLSchema.Code := 'Test';
        XMLSchema.Path := MainDefinitionFile.Name;

        XMLSchema.XSD.CreateOutStream(OutStream);
        MainDefinitionFile.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        XMLSchema.Insert();

        MainDefinitionFile.Close();
        AlternativeNamespaceDefinitionFile.Close();
        InfiniteLoopDefinitionFile.Close();

        XSDParser.LoadSchema(XMLSchema);

        // Verify Nodes
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        Assert.AreEqual(27, XMLSchemaElement.Count, 'Wrong number of nodes found');

        // Verify Paths
        VerifyFullPath(XMLSchema, 'MainSchema', '/MainSchema');
        VerifyFullPath(XMLSchema, 'Contact', '/MainSchema/Contact');
        VerifyFullPath(XMLSchema, 'address', '/MainSchema/Contact/address');
        VerifyFullPath(XMLSchema, 'ContactParty', '/MainSchema/Contact/ContactParty');
        VerifyFullPath(XMLSchema, 'contactName', '/MainSchema/Contact/ContactParty/contactName');
        VerifyFullPath(XMLSchema, 'Contact', '/MainSchema/Contact/ContactParty/Contact');
        VerifyFullPath(XMLSchema, 'ContactParty', '/MainSchema/ContactParty');
        VerifyFullPath(XMLSchema, 'cac:shipTo', '/MainSchema/cac:shipTo');

        VerifyFullPath(XMLSchema, 'cac:purchaseOrder', '/MainSchema/cac:purchaseOrder');
        VerifyFullPath(XMLSchema, 'cac:comment', '/MainSchema/cac:purchaseOrder/cac:comment');
        VerifyFullPath(XMLSchema, 'orderDate', '/MainSchema/cac:purchaseOrder[@orderDate]');

        VerifyFullPath(XMLSchema, 'cac:shipTo', '/MainSchema/cac:purchaseOrder/cac:shipTo');
        VerifyFullPath(XMLSchema, 'cac:name', '/MainSchema/cac:purchaseOrder/cac:shipTo/cac:name');
        VerifyFullPath(XMLSchema, 'cac:street', '/MainSchema/cac:purchaseOrder/cac:shipTo/cac:street');
        VerifyFullPath(XMLSchema, 'country', '/MainSchema/cac:purchaseOrder/cac:shipTo[@country]');

        VerifyFullPath(XMLSchema, 'cac:billTo', '/MainSchema/cac:purchaseOrder/cac:billTo');
        VerifyFullPath(XMLSchema, 'cac:name', '/MainSchema/cac:purchaseOrder/cac:billTo/cac:name');
        VerifyFullPath(XMLSchema, 'cac:street', '/MainSchema/cac:purchaseOrder/cac:billTo/cac:street');
        VerifyFullPath(XMLSchema, 'country', '/MainSchema/cac:purchaseOrder/cac:billTo[@country]');

        VerifyFullPath(XMLSchema, 'cac:items', '/MainSchema/cac:purchaseOrder/cac:items');
        VerifyFullPath(XMLSchema, 'cac:item', '/MainSchema/cac:purchaseOrder/cac:items/cac:item');
        VerifyFullPath(XMLSchema, 'cac:productName', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:productName');
        VerifyFullPath(XMLSchema, 'cac:quantity', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:quantity');
        VerifyFullPath(XMLSchema, 'cac:USPrice', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:USPrice');
        VerifyFullPath(XMLSchema, 'cac:comment', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:comment');
        VerifyFullPath(XMLSchema, 'cac:shipDate', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:shipDate');
        VerifyFullPath(XMLSchema, 'xs:decimal', '/MainSchema/cac:purchaseOrder/cac:items/cac:item[@xs:decimal]');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestLoadingAMissingSchema()
    var
        XMLSchema: Record "XML Schema";
        AlternativeNamespaceXMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XSDParser: Codeunit "XSD Parser";
        FileManagement: Codeunit "File Management";
        InfiniteLoopDefinitionFile: File;
        AlternativeNamespaceDefinitionFile: File;
        MainDefinitionFile: File;
        InfiniteLoopOutStr: OutStream;
        AlternativeNamespaceSchemaOutStr: OutStream;
        MainDefinitionOutStr: OutStream;
        OutStream: OutStream;
        InStream: InStream;
    begin
        // [SCENARIO 397836] XMLSchema record is updated on call XSDParser.LoadSchema() in case of "Indentation" > 0
        Initialize();

        // Create Files
        InfiniteLoopDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        InfiniteLoopDefinitionFile.CreateOutStream(InfiniteLoopOutStr);
        CreateSchemaFileWithInfiniteLoops(InfiniteLoopOutStr);

        AlternativeNamespaceDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));

        MainDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        MainDefinitionFile.CreateOutStream(MainDefinitionOutStr);
        CreateSchemaFileWithImportAndIncludeStatements(
          MainDefinitionOutStr, InfiniteLoopDefinitionFile.Name, AlternativeNamespaceDefinitionFile.Name);

        XMLSchema.Code := 'Test';
        XMLSchema.Path := MainDefinitionFile.Name;

        XMLSchema.XSD.CreateOutStream(OutStream);
        MainDefinitionFile.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        XMLSchema.Insert();

        MainDefinitionFile.Close();
        InfiniteLoopDefinitionFile.Close();

        XSDParser.LoadSchema(XMLSchema);
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        Assert.AreEqual(9, XMLSchemaElement.Count, 'Wrong number of nodes found');

        AlternativeNamespaceDefinitionFile.CreateOutStream(AlternativeNamespaceSchemaOutStr);
        CreateSchemaFileWithReferencesAlternativeNamespace(AlternativeNamespaceSchemaOutStr);
        AlternativeNamespaceXMLSchema.SetRange(Path, AlternativeNamespaceDefinitionFile.Name);
        AlternativeNamespaceXMLSchema.FindFirst();

        AlternativeNamespaceXMLSchema.XSD.CreateOutStream(OutStream);
        AlternativeNamespaceDefinitionFile.CreateInStream(InStream);
        CopyStream(OutStream, InStream);

        AlternativeNamespaceXMLSchema.TestField(Indentation, 2);
        AlternativeNamespaceXMLSchema.TestField("Target Namespace Aliases", '');
        XSDParser.LoadSchema(AlternativeNamespaceXMLSchema);
        AlternativeNamespaceXMLSchema.TestField("Target Namespace Aliases", 'cac');
        AlternativeNamespaceDefinitionFile.Close();

        // Verify Nodes
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        Assert.AreEqual(27, XMLSchemaElement.Count, 'Wrong number of nodes found');

        // Verify Paths
        VerifyFullPath(XMLSchema, 'MainSchema', '/MainSchema');
        VerifyFullPath(XMLSchema, 'Contact', '/MainSchema/Contact');
        VerifyFullPath(XMLSchema, 'address', '/MainSchema/Contact/address');
        VerifyFullPath(XMLSchema, 'ContactParty', '/MainSchema/Contact/ContactParty');
        VerifyFullPath(XMLSchema, 'contactName', '/MainSchema/Contact/ContactParty/contactName');
        VerifyFullPath(XMLSchema, 'Contact', '/MainSchema/Contact/ContactParty/Contact');
        VerifyFullPath(XMLSchema, 'ContactParty', '/MainSchema/ContactParty');
        VerifyFullPath(XMLSchema, 'cac:shipTo', '/MainSchema/cac:shipTo');

        VerifyFullPath(XMLSchema, 'cac:purchaseOrder', '/MainSchema/cac:purchaseOrder');
        VerifyFullPath(XMLSchema, 'cac:comment', '/MainSchema/cac:purchaseOrder/cac:comment');
        VerifyFullPath(XMLSchema, 'orderDate', '/MainSchema/cac:purchaseOrder[@orderDate]');

        VerifyFullPath(XMLSchema, 'cac:shipTo', '/MainSchema/cac:purchaseOrder/cac:shipTo');
        VerifyFullPath(XMLSchema, 'cac:name', '/MainSchema/cac:purchaseOrder/cac:shipTo/cac:name');
        VerifyFullPath(XMLSchema, 'cac:street', '/MainSchema/cac:purchaseOrder/cac:shipTo/cac:street');
        VerifyFullPath(XMLSchema, 'country', '/MainSchema/cac:purchaseOrder/cac:shipTo[@country]');

        VerifyFullPath(XMLSchema, 'cac:billTo', '/MainSchema/cac:purchaseOrder/cac:billTo');
        VerifyFullPath(XMLSchema, 'cac:name', '/MainSchema/cac:purchaseOrder/cac:billTo/cac:name');
        VerifyFullPath(XMLSchema, 'cac:street', '/MainSchema/cac:purchaseOrder/cac:billTo/cac:street');
        VerifyFullPath(XMLSchema, 'country', '/MainSchema/cac:purchaseOrder/cac:billTo[@country]');

        VerifyFullPath(XMLSchema, 'cac:items', '/MainSchema/cac:purchaseOrder/cac:items');
        VerifyFullPath(XMLSchema, 'cac:item', '/MainSchema/cac:purchaseOrder/cac:items/cac:item');
        VerifyFullPath(XMLSchema, 'cac:productName', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:productName');
        VerifyFullPath(XMLSchema, 'cac:quantity', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:quantity');
        VerifyFullPath(XMLSchema, 'cac:USPrice', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:USPrice');
        VerifyFullPath(XMLSchema, 'cac:comment', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:comment');
        VerifyFullPath(XMLSchema, 'cac:shipDate', '/MainSchema/cac:purchaseOrder/cac:items/cac:item/cac:shipDate');
        VerifyFullPath(XMLSchema, 'xs:decimal', '/MainSchema/cac:purchaseOrder/cac:items/cac:item[@xs:decimal]');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteMainXSDSchema()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XMLSchemaRestriction: Record "XML Schema Restriction";
        ReferencedXMLSchema: Record "Referenced XML Schema";
        XSDParser: Codeunit "XSD Parser";
        FileManagement: Codeunit "File Management";
        InfiniteLoopDefinitionFile: File;
        AlternativeNamespaceDefinitionFile: File;
        MainDefinitionFile: File;
        InfiniteLoopOutStr: OutStream;
        AlternativeNamespaceSchemaOutStr: OutStream;
        MainDefinitionOutStr: OutStream;
        OutStream: OutStream;
        InStream: InStream;
        MainSchemaCode: Code[20];
    begin
        Initialize();

        // Create Files
        InfiniteLoopDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        InfiniteLoopDefinitionFile.CreateOutStream(InfiniteLoopOutStr);
        CreateSchemaFileWithInfiniteLoops(InfiniteLoopOutStr);

        AlternativeNamespaceDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        AlternativeNamespaceDefinitionFile.CreateOutStream(AlternativeNamespaceSchemaOutStr);
        CreateSchemaFileWithReferencesAlternativeNamespace(AlternativeNamespaceSchemaOutStr);

        MainDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        MainDefinitionFile.CreateOutStream(MainDefinitionOutStr);
        CreateSchemaFileWithImportAndIncludeStatements(
          MainDefinitionOutStr, InfiniteLoopDefinitionFile.Name, AlternativeNamespaceDefinitionFile.Name);

        XMLSchema.Code := 'Test';
        XMLSchema.Path := MainDefinitionFile.Name;

        XMLSchema.XSD.CreateOutStream(OutStream);
        MainDefinitionFile.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        XMLSchema.Insert();

        MainDefinitionFile.Close();
        AlternativeNamespaceDefinitionFile.Close();
        InfiniteLoopDefinitionFile.Close();

        XSDParser.LoadSchema(XMLSchema);
        MainSchemaCode := XMLSchema.Code;
        XMLSchema.Delete(true);

        XMLSchema.SetFilter(Code, StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(XMLSchema.IsEmpty, 'Not all schemas were removed');

        XMLSchemaElement.SetFilter("XML Schema Code", StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(XMLSchemaElement.IsEmpty, 'Not all schema elements were removed');

        XMLSchemaRestriction.SetFilter("XML Schema Code", StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(XMLSchemaRestriction.IsEmpty, 'Not all schema restrictions were removed');

        ReferencedXMLSchema.SetFilter(Code, StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(ReferencedXMLSchema.IsEmpty, 'Not all referenced schemas were removed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteMainXSDSchemaDefinition()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XMLSchemaRestriction: Record "XML Schema Restriction";
        DefinitionXMLSchema: Record "XML Schema";
        ReferencedXMLSchema: Record "Referenced XML Schema";
        XSDParser: Codeunit "XSD Parser";
        FileManagement: Codeunit "File Management";
        InfiniteLoopDefinitionFile: File;
        AlternativeNamespaceDefinitionFile: File;
        MainDefinitionFile: File;
        InfiniteLoopOutStr: OutStream;
        AlternativeNamespaceSchemaOutStr: OutStream;
        MainDefinitionOutStr: OutStream;
        OutStream: OutStream;
        InStream: InStream;
        MainSchemaCode: Code[20];
    begin
        Initialize();

        // Create Files
        InfiniteLoopDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        InfiniteLoopDefinitionFile.CreateOutStream(InfiniteLoopOutStr);
        CreateSchemaFileWithInfiniteLoops(InfiniteLoopOutStr);

        AlternativeNamespaceDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        AlternativeNamespaceDefinitionFile.CreateOutStream(AlternativeNamespaceSchemaOutStr);
        CreateSchemaFileWithReferencesAlternativeNamespace(AlternativeNamespaceSchemaOutStr);

        MainDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        MainDefinitionFile.CreateOutStream(MainDefinitionOutStr);
        CreateSchemaFileWithImportAndIncludeStatements(
          MainDefinitionOutStr, InfiniteLoopDefinitionFile.Name, AlternativeNamespaceDefinitionFile.Name);

        XMLSchema.Code := 'Test';
        XMLSchema.Path := MainDefinitionFile.Name;

        XMLSchema.XSD.CreateOutStream(OutStream);
        MainDefinitionFile.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        XMLSchema.Insert();

        MainDefinitionFile.Close();
        AlternativeNamespaceDefinitionFile.Close();
        InfiniteLoopDefinitionFile.Close();

        XSDParser.LoadSchema(XMLSchema);
        MainSchemaCode := XMLSchema.Code;

        DefinitionXMLSchema.SetRange(Code, StrSubstNo('%1:1000', MainSchemaCode));
        DefinitionXMLSchema.FindFirst();
        DefinitionXMLSchema.Delete(true);

        XMLSchema.SetFilter(Code, StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(XMLSchema.IsEmpty, 'Not all schemas were removed');

        XMLSchemaElement.SetFilter("XML Schema Code", StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(XMLSchemaElement.IsEmpty, 'Not all schema elements were removed');

        XMLSchemaRestriction.SetFilter("XML Schema Code", StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(XMLSchemaRestriction.IsEmpty, 'Not all schema restrictions were removed');

        ReferencedXMLSchema.SetFilter(Code, StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(ReferencedXMLSchema.IsEmpty, 'Not all referenced schemas were removed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteDependentXSDSchema()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        XMLSchemaRestriction: Record "XML Schema Restriction";
        ReferencedXMLSchema: Record "Referenced XML Schema";
        ChildXMLSchema: Record "XML Schema";
        XSDParser: Codeunit "XSD Parser";
        FileManagement: Codeunit "File Management";
        InfiniteLoopDefinitionFile: File;
        AlternativeNamespaceDefinitionFile: File;
        MainDefinitionFile: File;
        InfiniteLoopOutStr: OutStream;
        AlternativeNamespaceSchemaOutStr: OutStream;
        MainDefinitionOutStr: OutStream;
        OutStream: OutStream;
        InStream: InStream;
        MainSchemaCode: Code[20];
    begin
        Initialize();

        // Create Files
        InfiniteLoopDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        InfiniteLoopDefinitionFile.CreateOutStream(InfiniteLoopOutStr);
        CreateSchemaFileWithInfiniteLoops(InfiniteLoopOutStr);

        AlternativeNamespaceDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        AlternativeNamespaceDefinitionFile.CreateOutStream(AlternativeNamespaceSchemaOutStr);
        CreateSchemaFileWithReferencesAlternativeNamespace(AlternativeNamespaceSchemaOutStr);

        MainDefinitionFile.Create(FileManagement.ServerTempFileName('.xsd'));
        MainDefinitionFile.CreateOutStream(MainDefinitionOutStr);
        CreateSchemaFileWithImportAndIncludeStatements(
          MainDefinitionOutStr, InfiniteLoopDefinitionFile.Name, AlternativeNamespaceDefinitionFile.Name);

        XMLSchema.Code := 'Test';
        XMLSchema.Path := MainDefinitionFile.Name;

        XMLSchema.XSD.CreateOutStream(OutStream);
        MainDefinitionFile.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        XMLSchema.Insert();

        MainDefinitionFile.Close();
        AlternativeNamespaceDefinitionFile.Close();
        InfiniteLoopDefinitionFile.Close();

        XSDParser.LoadSchema(XMLSchema);
        MainSchemaCode := XMLSchema.Code;
        ChildXMLSchema.SetRange(Indentation, 2);
        ChildXMLSchema.FindLast();
        ChildXMLSchema.Delete(true);

        XMLSchema.SetFilter(Code, StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(XMLSchema.IsEmpty, 'Not all schemas were removed');

        XMLSchemaElement.SetFilter("XML Schema Code", StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(XMLSchemaElement.IsEmpty, 'Not all schema elements were removed');

        XMLSchemaRestriction.SetFilter("XML Schema Code", StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(XMLSchemaRestriction.IsEmpty, 'Not all schema restrictions were removed');

        ReferencedXMLSchema.SetFilter(Code, StrSubstNo('%1*', MainSchemaCode));
        Assert.IsTrue(ReferencedXMLSchema.IsEmpty, 'Not all referenced schemas were removed');
    end;

    [Test]
    [HandlerFunctions('DataExchDefModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateDataExchDef()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        DataExchDef: Record "Data Exch. Def";
        XSDParser: Codeunit "XSD Parser";
        OutStr: OutStream;
    begin
        Initialize();

        // Setup.
        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.ModifyAll(Selected, true);
        XMLSchemaElement.FindFirst();
        XMLSchemaElement.Validate(Selected, false);
        XMLSchemaElement.Modify();
        if DataExchDef.Get(XMLSchema.Code) then
            DataExchDef.Delete(true);

        // Exercise.
        XSDParser.CreateDataExchDefForCAMT(XMLSchemaElement);

        // Verify.
        VerifyDataExchDef(XMLSchema);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsLeaf()
    var
        XMLSchema: Record "XML Schema";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);

        // Verify.
        VerifyLeafStatus(XMLSchema, 'Document', false);
        VerifyLeafStatus(XMLSchema, 'CstmrCdtTrfInitn', false);
        VerifyLeafStatus(XMLSchema, 'GrpHdr', false);
        VerifyLeafStatus(XMLSchema, 'MsgId', true);
        VerifyLeafStatus(XMLSchema, 'Test1', true);
        VerifyLeafStatus(XMLSchema, 'Test2', true);
        VerifyLeafStatus(XMLSchema, 'LineAmt', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullPath()
    var
        XMLSchema: Record "XML Schema";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);

        // Verify.
        VerifyFullPath(XMLSchema, 'Document', '/Document');
        VerifyFullPath(XMLSchema, 'CstmrCdtTrfInitn', '/Document/CstmrCdtTrfInitn');
        VerifyFullPath(XMLSchema, 'GrpHdr', '/Document/CstmrCdtTrfInitn/GrpHdr');
        VerifyFullPath(XMLSchema, 'MsgId', '/Document/CstmrCdtTrfInitn/GrpHdr/MsgId');
        VerifyFullPath(XMLSchema, 'Test1', '/Document/CstmrCdtTrfInitn/Test1');
        VerifyFullPath(XMLSchema, 'Test2', '/Document/CstmrCdtTrfInitn/Test2');
        VerifyFullPath(XMLSchema, 'LineAmt', '/Document/CstmrCdtTrfInitn/LineAmt');
        VerifyFullPath(XMLSchema, 'Ccy', '/Document/CstmrCdtTrfInitn/LineAmt[@Ccy]');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleDataType()
    var
        XMLSchema: Record "XML Schema";
        OutStr: OutStream;
    begin
        Initialize();

        CreateXMLSchemaRecord(XMLSchema, OutStr);
        CreateSchemaFile(OutStr);
        LoadSchemaFile(XMLSchema);

        // Verify.
        VerifySimpleDataType(XMLSchema, 'Document', '');
        VerifySimpleDataType(XMLSchema, 'CstmrCdtTrfInitn', '');
        VerifySimpleDataType(XMLSchema, 'GrpHdr', '');
        VerifySimpleDataType(XMLSchema, 'MsgId', 'string');
        VerifySimpleDataType(XMLSchema, 'Test1', 'string');
        VerifySimpleDataType(XMLSchema, 'Test2', '');
        VerifySimpleDataType(XMLSchema, 'LineAmt', 'string');
        VerifySimpleDataType(XMLSchema, 'Ccy', 'string');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLSchemaCodeCannotBeBlank()
    var
        XMLSchemas: TestPage "XML Schemas";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 235022] You cannot create XML Schema with blank Code.
        Initialize();

        XMLSchemas.OpenNew();
        asserterror XMLSchemas.Code.SetValue('');

        Assert.ExpectedErrorCode('TestValidation');
    end;

    local procedure Initialize()
    var
        XMLSchema: Record "XML Schema";
        XMLSchemaElement: Record "XML Schema Element";
        ReferencedXMLSchema: Record "Referenced XML Schema";
        XMLSchemaRestriction: Record "XML Schema Restriction";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM - Test XML Schema Viewer");
        LibraryVariableStorage.Clear();
        XMLSchema.DeleteAll();
        XMLSchemaElement.DeleteAll();
        ReferencedXMLSchema.DeleteAll();
        XMLSchemaRestriction.DeleteAll();
    end;

    local procedure LoadSchemaFile(var XMLSchema: Record "XML Schema")
    var
        XSDParser: Codeunit "XSD Parser";
    begin
        XSDParser.LoadSchema(XMLSchema);
        XMLSchema.Modify();
    end;

    local procedure CreateXMLSchemaRecord(var XMLSchema: Record "XML Schema"; var OutStream: OutStream)
    begin
        XMLSchema.Init();
        XMLSchema.Code := 'TEST';
        XMLSchema.Description := 'Test schema';
        XMLSchema.XSD.CreateOutStream(OutStream);
        XMLSchema.Insert();
    end;

    local procedure CreateSchemaFile(var OutStr: OutStream)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<!--Generated by SWIFTStandards Workstation (build:R7.1.30.4) on 2012 Jun 07 20:47:19-->');
        OutStr.WriteText(
          '<xs:schema elementFormDefault="qualified" targetNamespace="urn:iso:std:iso:20022:tech:xsd:pain.001.001.04"' +
          ' xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.04" xmlns:xs="http://www.w3.org/2001/XMLSchema">');
        OutStr.WriteText('<xs:element name="Document" type="Document"/>');
        OutStr.WriteText('<xs:complexType name="CustomerCreditTransferInitiationV04">');
        OutStr.WriteText('<xs:sequence>');
        OutStr.WriteText('<xs:element name="GrpHdr" type="GroupHeader48"/>');
        OutStr.WriteText('<xs:element name="Test1" type="DocumentType5Code"/>');
        OutStr.WriteText('<xs:element name="Test2" type="IBAN2007Identifier" minOccurs="0" maxOccurs="1"/>');
        OutStr.WriteText('<xs:element name="LineAmt" type="Amount"/>');
        OutStr.WriteText('</xs:sequence>');
        OutStr.WriteText('</xs:complexType>');
        OutStr.WriteText('<xs:complexType name="Document">');
        OutStr.WriteText('<xs:sequence>');
        OutStr.WriteText('<xs:element name="CstmrCdtTrfInitn" type="CustomerCreditTransferInitiationV04"/>');
        OutStr.WriteText('</xs:sequence>');
        OutStr.WriteText('</xs:complexType>');
        OutStr.WriteText('<xs:simpleType name="DocumentType5Code">');
        OutStr.WriteText('<xs:restriction base="xs:string">');
        OutStr.WriteText('<xs:enumeration value="MSIN"/>');
        OutStr.WriteText('<xs:enumeration value="CNFA"/>');
        OutStr.WriteText('<xs:enumeration value="DNFA"/>');
        OutStr.WriteText('<xs:enumeration value="CINV"/>');
        OutStr.WriteText('<xs:enumeration value="CREN"/>');
        OutStr.WriteText('<xs:enumeration value="DEBN"/>');
        OutStr.WriteText('<xs:enumeration value="HIRI"/>');
        OutStr.WriteText('<xs:enumeration value="SBIN"/>');
        OutStr.WriteText('<xs:enumeration value="CMCN"/>');
        OutStr.WriteText('<xs:enumeration value="SOAC"/>');
        OutStr.WriteText('<xs:enumeration value="DISP"/>');
        OutStr.WriteText('<xs:enumeration value="BOLD"/>');
        OutStr.WriteText('<xs:enumeration value="VCHR"/>');
        OutStr.WriteText('<xs:enumeration value="AROI"/>');
        OutStr.WriteText('<xs:enumeration value="TSUT"/>');
        OutStr.WriteText('</xs:restriction>');
        OutStr.WriteText('</xs:simpleType>');
        OutStr.WriteText('<xs:complexType name="GroupHeader48">');
        OutStr.WriteText('<xs:sequence>');
        OutStr.WriteText('<xs:element name="MsgId" type="Max35Text" minOccurs="1"/>');
        OutStr.WriteText('</xs:sequence>');
        OutStr.WriteText('</xs:complexType>');
        OutStr.WriteText('<xs:complexType name="Amount">');
        OutStr.WriteText('<xs:simpleContent>');
        OutStr.WriteText('<xs:extension base="xs:string">');
        OutStr.WriteText('<xs:attribute type="CurrencyCode" name="Ccy" use="required"/>');
        OutStr.WriteText('</xs:extension>');
        OutStr.WriteText('</xs:simpleContent>');
        OutStr.WriteText('</xs:complexType>');
        OutStr.WriteText('<xs:simpleType name="CurrencyCode">');
        OutStr.WriteText('<xs:restriction base="xs:string">');
        OutStr.WriteText('<xs:pattern value="[A-Z]{3,3}"/>');
        OutStr.WriteText('</xs:restriction>');
        OutStr.WriteText('</xs:simpleType>');
        OutStr.WriteText('<xs:simpleType name="IBAN2007Identifier">');
        OutStr.WriteText('<xs:restriction base="xs:string">');
        OutStr.WriteText('<xs:pattern value="[A-Z]{2,2}[0-9]{2,2}[a-zA-Z0-9]{1,30}"/>');
        OutStr.WriteText('</xs:restriction>');
        OutStr.WriteText('</xs:simpleType>');
        OutStr.WriteText('<xs:simpleType name="Max35Text">');
        OutStr.WriteText('<xs:restriction base="xs:string">');
        OutStr.WriteText('<xs:minLength value="1"/>');
        OutStr.WriteText('<xs:maxLength value="35"/>');
        OutStr.WriteText('</xs:restriction>');
        OutStr.WriteText('</xs:simpleType>');
        OutStr.WriteText('</xs:schema>');
    end;

    local procedure CreateSchemaFileWithComplexTypeNestedFile(var OutStr: OutStream)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText(
          '<xs:schema elementFormDefault="qualified" targetNamespace="urn:iso:std:iso:20022:tech:xsd:pain.001.001.04"' +
          ' xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.04" xmlns:xs="http://www.w3.org/2001/XMLSchema">');
        OutStr.WriteText('<xs:element name="Customer">');
        OutStr.WriteText('<xs:complexType>');
        OutStr.WriteText('<xs:sequence>');
        OutStr.WriteText('<xs:element name="Dob" type="xs:date" />');
        OutStr.WriteText('<xs:element name="Address">');
        OutStr.WriteText('<xs:complexType>');
        OutStr.WriteText('<xs:sequence>');
        OutStr.WriteText('<xs:element name="Line1" type="xs:string"/>');
        OutStr.WriteText('<xs:element name="Line2" type="xs:string"/>');
        OutStr.WriteText('</xs:sequence>');
        OutStr.WriteText('</xs:complexType>');
        OutStr.WriteText('</xs:element>');
        OutStr.WriteText('<xs:element name="NoOfInvoices">');
        OutStr.WriteText('<xs:simpleType>');
        OutStr.WriteText('<xs:restriction base="xs:integer">');
        OutStr.WriteText('<xs:minInclusive value="0"/>');
        OutStr.WriteText('<xs:maxInclusive value="100"/>');
        OutStr.WriteText('</xs:restriction>');
        OutStr.WriteText('</xs:simpleType>');
        OutStr.WriteText('</xs:element>');
        OutStr.WriteText('</xs:sequence>');
        OutStr.WriteText('</xs:complexType>');
        OutStr.WriteText('</xs:element>');
        OutStr.WriteText('</xs:schema>');
    end;

    local procedure CreateSchemaFileWithGlobalComplexType(var OutStr: OutStream)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText(
          '<xs:schema elementFormDefault="qualified" targetNamespace="urn:iso:std:iso:20022:tech:xsd:pain.001.001.04"' +
          ' xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.04" xmlns:xs="http://www.w3.org/2001/XMLSchema">');
        OutStr.WriteText('<xs:complexType name="AddressType">');
        OutStr.WriteText('<xs:sequence>');
        OutStr.WriteText('<xs:element name="Line1" type="xs:string"/>');
        OutStr.WriteText('<xs:element name="Line2" type="xs:string"/>');
        OutStr.WriteText('</xs:sequence>');
        OutStr.WriteText('</xs:complexType>');
        OutStr.WriteText('<xs:element name="CompanyAddress" type="AddressType"/>');
        OutStr.WriteText('<xs:element name="Customer">');
        OutStr.WriteText('<xs:complexType>');
        OutStr.WriteText('<xs:sequence>');
        OutStr.WriteText('<xs:element name="Dob" type="xs:date" />');
        OutStr.WriteText('<xs:element name="Address" type="AddressType" />');
        OutStr.WriteText('<xs:element ref="CompanyAddress"/>');
        OutStr.WriteText('</xs:sequence>');
        OutStr.WriteText('</xs:complexType>');
        OutStr.WriteText('</xs:element>');

        OutStr.WriteText('</xs:schema>');
    end;

    local procedure CreateSchemaFileWithReferences(var OutStr: OutStream)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"');
        OutStr.WriteText('           targetNamespace="http://tempuri.org/po.xsd"');
        OutStr.WriteText('           xmlns="http://tempuri.org/po.xsd" elementFormDefault="qualified">');
        OutStr.WriteText('  <xs:annotation>');
        OutStr.WriteText('    <xs:documentation xml:lang="en">');
        OutStr.WriteText('      From MSDN');
        OutStr.WriteText('    </xs:documentation>');
        OutStr.WriteText('  </xs:annotation>');

        OutStr.WriteText('  <xs:element name="purchaseOrder" type="PurchaseOrderType"/>');

        OutStr.WriteText('  <xs:element name="comment" type="xs:string" minOccurs="0"/>');
        OutStr.WriteText('  <xs:element name="shipTo" type="USAddress"/>');
        OutStr.WriteText('  <xs:element name="billTo" type="USAddress"/>');

        OutStr.WriteText('  <xs:complexType name="PurchaseOrderType">');
        OutStr.WriteText('   <xs:sequence>                             ');
        OutStr.WriteText('     <xs:element ref="shipTo" />');
        OutStr.WriteText('     <xs:element ref="billTo" />');
        OutStr.WriteText('     <xs:element ref="comment" minOccurs="0"/>');
        OutStr.WriteText('     <xs:element name="items"  type="Items"/>  ');
        OutStr.WriteText('    </xs:sequence>');
        OutStr.WriteText('    <xs:attribute name="orderDate" type="xs:date"/>');
        OutStr.WriteText('  </xs:complexType>');

        OutStr.WriteText('  <xs:complexType name="USAddress"> ');
        OutStr.WriteText('    <xs:sequence>');
        OutStr.WriteText('      <xs:element name="name"   type="xs:string"/> ');
        OutStr.WriteText('      <xs:element name="street" type="xs:string"/>');
        OutStr.WriteText('    </xs:sequence>');
        OutStr.WriteText('    <xs:attribute name="country" type="xs:NMTOKEN" fixed="US"/>');
        OutStr.WriteText('  </xs:complexType>');

        OutStr.WriteText('  <xs:complexType name="Items">');
        OutStr.WriteText('    <xs:sequence>');
        OutStr.WriteText('      <xs:element name="item" maxOccurs="unbounded">');
        OutStr.WriteText('        <xs:complexType> ');
        OutStr.WriteText('          <xs:sequence> ');
        OutStr.WriteText('            <xs:element name="productName" type="xs:string"/>');
        OutStr.WriteText('            <xs:element name="quantity">');
        OutStr.WriteText('              <xs:simpleType>');
        OutStr.WriteText('                <xs:restriction base="xs:positiveInteger">');
        OutStr.WriteText('                  <xs:maxExclusive value="100"/>');
        OutStr.WriteText('                </xs:restriction>   ');
        OutStr.WriteText('              </xs:simpleType> ');
        OutStr.WriteText('            </xs:element>   ');
        OutStr.WriteText('            <xs:element name="USPrice" type="xs:decimal"/>');
        OutStr.WriteText('            <xs:element ref="comment" minOccurs="0"/>  ');
        OutStr.WriteText('            <xs:element name="shipDate" type="xs:date" minOccurs="0"/>');
        OutStr.WriteText('          </xs:sequence>');
        OutStr.WriteText('          <xs:attribute ref="xs:decimal"/>');
        OutStr.WriteText('        </xs:complexType>    ');
        OutStr.WriteText('      </xs:element>   ');
        OutStr.WriteText('    </xs:sequence>    ');
        OutStr.WriteText('  </xs:complexType>   ');
        OutStr.WriteText('</xs:schema>          ');
    end;

    local procedure CreateSchemaFileWithReferencesAlternativeNamespace(var OutStr: OutStream)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"');
        OutStr.WriteText('           targetNamespace="mytest:namespace"');
        OutStr.WriteText('           xmlns="mytest:namespace" xmlns:cac="mytest:namespace" elementFormDefault="qualified">');
        OutStr.WriteText('  <xs:annotation>');
        OutStr.WriteText('    <xs:documentation xml:lang="en">');
        OutStr.WriteText('      From MSDN');
        OutStr.WriteText('    </xs:documentation>');
        OutStr.WriteText('  </xs:annotation>');

        OutStr.WriteText('  <xs:element name="purchaseOrder" type="PurchaseOrderType"/>');

        OutStr.WriteText('  <xs:element name="comment" type="xs:string" minOccurs="0"/>');
        OutStr.WriteText('  <xs:element name="shipTo" type="USAddress"/>');
        OutStr.WriteText('  <xs:element name="billTo" type="USAddress"/>');

        OutStr.WriteText('  <xs:complexType name="PurchaseOrderType">');
        OutStr.WriteText('   <xs:sequence>                             ');
        OutStr.WriteText('     <xs:element ref="cac:shipTo" />');
        OutStr.WriteText('     <xs:element ref="cac:billTo" />');
        OutStr.WriteText('     <xs:element ref="cac:comment" minOccurs="0"/>');
        OutStr.WriteText('     <xs:element name="items"  type="Items"/>  ');
        OutStr.WriteText('    </xs:sequence>');
        OutStr.WriteText('    <xs:attribute name="orderDate" type="xs:date"/>');
        OutStr.WriteText('  </xs:complexType>');

        OutStr.WriteText('  <xs:complexType name="USAddress"> ');
        OutStr.WriteText('    <xs:sequence>');
        OutStr.WriteText('      <xs:element name="name"   type="xs:string"/> ');
        OutStr.WriteText('      <xs:element name="street" type="xs:string"/>');
        OutStr.WriteText('    </xs:sequence>');
        OutStr.WriteText('    <xs:attribute name="country" type="xs:NMTOKEN" fixed="US"/>');
        OutStr.WriteText('  </xs:complexType>');

        OutStr.WriteText('  <xs:complexType name="Items">');
        OutStr.WriteText('    <xs:sequence>');
        OutStr.WriteText('      <xs:element name="item" maxOccurs="unbounded">');
        OutStr.WriteText('        <xs:complexType> ');
        OutStr.WriteText('          <xs:sequence> ');
        OutStr.WriteText('            <xs:element name="productName" type="xs:string"/>');
        OutStr.WriteText('            <xs:element name="quantity">');
        OutStr.WriteText('              <xs:simpleType>');
        OutStr.WriteText('                <xs:restriction base="xs:positiveInteger">');
        OutStr.WriteText('                  <xs:maxExclusive value="100"/>');
        OutStr.WriteText('                </xs:restriction>   ');
        OutStr.WriteText('              </xs:simpleType> ');
        OutStr.WriteText('            </xs:element>   ');
        OutStr.WriteText('            <xs:element name="USPrice" type="xs:decimal"/>');
        OutStr.WriteText('            <xs:element ref="comment" minOccurs="0"/>  ');
        OutStr.WriteText('            <xs:element name="shipDate" type="xs:date" minOccurs="0"/>');
        OutStr.WriteText('          </xs:sequence>');
        OutStr.WriteText('          <xs:attribute ref="xs:decimal"/>');
        OutStr.WriteText('        </xs:complexType>    ');
        OutStr.WriteText('      </xs:element>   ');
        OutStr.WriteText('    </xs:sequence>    ');
        OutStr.WriteText('  </xs:complexType>   ');
        OutStr.WriteText('</xs:schema>          ');
    end;

    local procedure CreateSchemaFileWithExtensions(var OutStr: OutStream)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"');
        OutStr.WriteText('           targetNamespace="http://tempuri.org/po.xsd"');
        OutStr.WriteText(
          '           xmlns="http://tempuri.org/po.xsd" xmlns:cac="http://tempuri.org/po.xsd" elementFormDefault="qualified">');

        OutStr.WriteText('           <xs:element name="para" type="extendedNameType"/>');

        OutStr.WriteText('           <xs:complexType name="nameType">');
        OutStr.WriteText('             <xs:sequence>                 ');
        OutStr.WriteText('              <xs:element name="fname" type="xs:string"/>');
        OutStr.WriteText('              <xs:element name="lname" type="xs:string"/>');
        OutStr.WriteText('             </xs:sequence>                              ');
        OutStr.WriteText('           </xs:complexType>                             ');

        OutStr.WriteText('           <xs:complexType name="extendedNameType">      ');
        OutStr.WriteText('            <xs:complexContent>                          ');
        OutStr.WriteText('             <xs:extension base="nameType">              ');
        OutStr.WriteText('               <xs:sequence>                             ');
        OutStr.WriteText('                 <xs:element name="gen" type="genType"/> ');
        OutStr.WriteText('                 <xs:element name="description" type="xs:string"/>  ');
        OutStr.WriteText('               </xs:sequence>                                       ');
        OutStr.WriteText('             </xs:extension>                                        ');
        OutStr.WriteText('            </xs:complexContent>                                    ');
        OutStr.WriteText('           </xs:complexType>                                        ');

        OutStr.WriteText('           <xs:complexType name="genType">                          ');
        OutStr.WriteText('             <xs:simpleContent>                                     ');
        OutStr.WriteText('               <xs:extension base="xs:string">                      ');
        OutStr.WriteText('                 <xs:attribute name="label" type="xs:string"        ');
        OutStr.WriteText('                       use="required"/>                             ');
        OutStr.WriteText('               </xs:extension>                                      ');
        OutStr.WriteText('             </xs:simpleContent>                                    ');
        OutStr.WriteText('           </xs:complexType>                                        ');

        OutStr.WriteText('</xs:schema>');
    end;

    local procedure CreateSchemaFileWithInfiniteLoops(var OutStr: OutStream)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"');
        OutStr.WriteText('           targetNamespace="http://tempuri.org/po.xsd"');
        OutStr.WriteText(
          '           xmlns="http://tempuri.org/po.xsd" xmlns:cac="http://tempuri.org/po.xsd" elementFormDefault="qualified">');

        OutStr.WriteText('<xsd:element name="SelfReferencingNode" type="SelfReferencingNode"/>');
        OutStr.WriteText('<xsd:element name="AdditionalInformationParty" type="AdditionalInformationPartyType"/>');
        OutStr.WriteText('<xsd:element name="Contact" type="ContactType"/>');
        OutStr.WriteText('<xsd:element name="ContactParty" type="ContactPartyType"/>');

        OutStr.WriteText('<xsd:complexType name="ContactPartyType">');
        OutStr.WriteText('  <xsd:sequence>                          ');
        OutStr.WriteText('    <xsd:element name="contactName" minOccurs="0" maxOccurs="1" type="xsd:string"/>');
        OutStr.WriteText('    <xsd:element ref="Contact" minOccurs="1" maxOccurs="1" />');
        OutStr.WriteText('  </xsd:sequence>');
        OutStr.WriteText('</xsd:complexType>');

        OutStr.WriteText('<xsd:complexType name="ContactType">');
        OutStr.WriteText('  <xsd:sequence>                          ');
        OutStr.WriteText('    <xsd:element name="address" type="xsd:string"/>');
        OutStr.WriteText('    <xsd:element ref="ContactParty" minOccurs="1" maxOccurs="1" />');
        OutStr.WriteText('  </xsd:sequence>');
        OutStr.WriteText('</xsd:complexType>');

        OutStr.WriteText('<xsd:complexType name="AdditionalInformationPartyType">');
        OutStr.WriteText('  <xsd:sequence>                             ');
        OutStr.WriteText('    <xsd:element ref="Contact"/>  ');
        OutStr.WriteText('    <xsd:element ref="ContactParty" minOccurs="0" maxOccurs="1" />');
        OutStr.WriteText('  </xsd:sequence> ');
        OutStr.WriteText('</xsd:complexType>');

        OutStr.WriteText('</xsd:schema>');
    end;

    local procedure CreateSchemaFileWithImportAndIncludeStatements(var OutStr: OutStream; ImportFile1Path: Text; ImportFile2Path: Text)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"');
        OutStr.WriteText('           targetNamespace="http://tempuri.org/po.xsd"');
        OutStr.WriteText('           xmlns="http://tempuri.org/po.xsd" xmlns:cac="mytest:namespace" elementFormDefault="qualified">');

        OutStr.WriteText(StrSubstNo('<xsd:include schemaLocation="%1"/>', ImportFile1Path));
        OutStr.WriteText(StrSubstNo('<xsd:import namespace="mytest:namespace" schemaLocation="%1"/>', ImportFile2Path));

        OutStr.WriteText('<xsd:element name="MainSchema" type="MainSchemaType"/>');
        OutStr.WriteText('<xsd:complexType name="MainSchemaType">');
        OutStr.WriteText('  <xsd:sequence>                             ');
        OutStr.WriteText('    <xsd:element ref="Contact"/>  ');
        OutStr.WriteText('    <xsd:element ref="ContactParty" minOccurs="0" maxOccurs="1" />');
        OutStr.WriteText('    <xsd:element ref="cac:purchaseOrder" maxOccurs="1" />');
        OutStr.WriteText('    <xsd:element ref="cac:shipTo" minOccurs="0" />');
        OutStr.WriteText('  </xsd:sequence> ');
        OutStr.WriteText('</xsd:complexType>');

        OutStr.WriteText('</xsd:schema>');
    end;

    local procedure GetExpectedDataTypeAndFormat(SimpleDataType: Text; var DataType: Option; var DataFormat: Text; var DataFormattingCulture: Text)
    var
        DataExchColDef: Record "Data Exch. Column Def";
    begin
        case DelChr(LowerCase(SimpleDataType)) of
            'date':
                begin
                    DataType := DataExchColDef."Data Type"::Date;
                    DataFormat := XMLDateFormatTxt;
                    DataFormattingCulture := DefaultCultureTxt;
                end;
            'dateTime':
                begin
                    DataType := DataExchColDef."Data Type"::Text;
                    DataFormat := XMLDateTimeFormatTxt;
                    DataFormattingCulture := DefaultCultureTxt;
                end;
            'decimal':
                begin
                    DataType := DataExchColDef."Data Type"::Decimal;
                    DataFormattingCulture := DefaultCultureTxt;
                end;
            else
                DataType := DataExchColDef."Data Type"::Text;
        end;
    end;

    local procedure VerifyDataExchDef(XMLSchema: Record "XML Schema")
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchDef.SetRange(Code, XMLSchema.Code);
        Assert.AreEqual(1, DataExchDef.Count, 'Unexpected Data Exch. def.');
        DataExchDef.FindFirst();
        DataExchDef.TestField(Type, DataExchDef.Type::"Bank Statement Import");
        DataExchDef.TestField("File Type", DataExchDef."File Type"::Xml);

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange(Code, DataExchDef.Code);
        Assert.AreEqual(1, DataExchLineDef.Count, 'Unexpected Data Exch. line def.');
        DataExchLineDef.FindFirst();
        DataExchLineDef.TestField("Data Line Tag", '/Document/BkToCstmrStmt/Stmt/Ntry');

        VerifyDataExchColDef(XMLSchema);
    end;

    local procedure VerifyDataExchColDef(XMLSchema: Record "XML Schema")
    var
        XMLSchemaElement: Record "XML Schema Element";
        DataExchColDef: Record "Data Exch. Column Def";
        DataType: Option;
        DataFormat: Text;
        DataFormattingCulture: Text;
        FullPath: Text;
    begin
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.SetRange(Selected, true);

        DataExchColDef.SetRange("Data Exch. Def Code", XMLSchema.Code);
        DataExchColDef.SetRange("Data Exch. Line Def Code", XMLSchema.Code);

        XMLSchemaElement.FindSet();
        repeat
            FullPath := XMLSchemaElement.GetFullPath();
            DataExchColDef.SetRange(Path, FullPath);
            DataExchColDef.SetRange(Description, XMLSchemaElement."Node Name");

            if XMLSchemaElement.IsLeaf() then begin
                Assert.AreEqual(1, DataExchColDef.Count, 'Unexpected column def.:' + DataExchColDef.GetFilters);
                GetExpectedDataTypeAndFormat(XMLSchemaElement."Simple Data Type", DataType, DataFormat, DataFormattingCulture);
                DataExchColDef.FindFirst();
                DataExchColDef.TestField(Name, DelStr(FullPath, StrPos(FullPath, '/Document/CstmrCdtTrfInitn'), 26));
                DataExchColDef.TestField("Data Type", DataType);
                DataExchColDef.TestField("Data Format", DataFormat);
                DataExchColDef.TestField("Data Formatting Culture", DataFormattingCulture);
            end else
                Assert.AreEqual(0, DataExchColDef.Count, 'Unexpected column def.:' + DataExchColDef.GetFilters);
        until XMLSchemaElement.Next() = 0;
    end;

    local procedure VerifyLeafStatus(XMLSchema: Record "XML Schema"; NodeName: Text; IsLeafStatus: Boolean)
    var
        XMLSchemaElement: Record "XML Schema Element";
    begin
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.SetRange("Node Name", NodeName);
        XMLSchemaElement.FindFirst();

        Assert.AreEqual(IsLeafStatus, XMLSchemaElement.IsLeaf(), 'Wrong leaf status.');
    end;

    local procedure VerifyFullPath(XMLSchema: Record "XML Schema"; NodeName: Text; ExpFullPath: Text)
    var
        XMLSchemaElement: Record "XML Schema Element";
    begin
        Assert.IsTrue(GetElementByPath(NodeName, ExpFullPath, XMLSchema, XMLSchemaElement), 'Could not find path: ' + ExpFullPath);
    end;

    local procedure VerifySimpleDataType(XMLSchema: Record "XML Schema"; NodeName: Text; ExpSimpleDataType: Text)
    var
        XMLSchemaElement: Record "XML Schema Element";
    begin
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.SetRange("Node Name", NodeName);
        XMLSchemaElement.FindFirst();
        Assert.AreEqual(ExpSimpleDataType, XMLSchemaElement."Simple Data Type", 'Wrong data type.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DataExchDefModalPageHandler(var DataExchDefCard: TestPage "Data Exch Def Card")
    begin
        DataExchDefCard.Code.AssertEquals('TEST');
    end;

    local procedure GetElementByPath(NodeName: Text; ExpFullPath: Text; XMLSchema: Record "XML Schema"; var ElementFoundXMLSchemaElement: Record "XML Schema Element"): Boolean
    var
        XMLSchemaElement: Record "XML Schema Element";
    begin
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.SetRange("Node Name", NodeName);
        XMLSchemaElement.Find('-');

        repeat
            if ExpFullPath = XMLSchemaElement.GetFullPath() then begin
                ElementFoundXMLSchemaElement := XMLSchemaElement;
                exit(true);
            end;
        until XMLSchemaElement.Next() = 0;

        exit(false);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}
