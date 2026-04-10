codeunit 132563 "XML DOM Management UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [XML DOM Management] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        AttributeContentNotFoundErr: Label 'The InnertText for XML Attribute %1 of XML Node %2 was not found.';
        AttributeNotFoundErr: Label 'The XML Attribute %1 of XML Node %2 was not found.';
        NodeContentNotFoundErr: Label 'The InnertText for XML Node %1 was not found.';
        NodeNotFoundErr: Label 'The XML Node %1 was not found.';
        EmptyPrefixErr: Label 'Retrieval of an XML element cannot be done with an empty prefix.';
        NamespacePrefixResolveErr: Label 'Namespace manager contains wrong namespace with prefix %1.';
        XMLWithNamesacesTxt: Label '<Document xmlns="%1" xmlns:%2="%3" xmlns:%4="%5"/>', Locked = true;
        XmlFileHeaderTok: Label '<?xml version="1.0" encoding="utf-8"?>';
        XmlFileDoctypeTok: Label '<!DOCTYPE rootNode>';
        XmlFileRootNodeTok: Label '<rootNode></rootNode>', Locked = true;
        DoctypeElementErr: Label 'Wrong <!DOCTYPE> element in XML file.';
        LoadXmlDocErr: Label 'Xml Document has not been loaded.';

    [Test]
    [Scope('OnPrem')]
    procedure AddElement()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        CreatedXmlNode: DotNet XmlNode;
        RootXmlNode: DotNet XmlNode;
        ActualNodeText: Text;
        NodeName: Text;
        NodeText: Text;
    begin
        // [SCENARIO 1] Add an XML element to an XML document.
        // [GIVEN] XML document.
        // [WHEN] Run the AddElement function.
        // [THEN] Element is added to the document.

        // Setup
        XMLDOMMgt.LoadXMLNodeFromText('<root />', RootXmlNode);

        // Pre-Exercise
        NodeName := LibraryUtility.GenerateGUID();
        NodeText := LibraryUtility.GenerateRandomText(1024);

        // Exercise
        XMLDOMMgt.AddElement(RootXmlNode, NodeName, NodeText, '', CreatedXmlNode);

        // Pre-Verify
        ActualNodeText := XMLDOMMgt.FindNodeText(RootXmlNode, '/root/' + NodeName);

        // Verify
        Assert.AreEqual(NodeText, ActualNodeText, StrSubstNo(NodeContentNotFoundErr, NodeName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddElementWithPrefix()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        CreatedXmlNode: DotNet XmlNode;
        RootXmlNode: DotNet XmlNode;
        Namespace: Text;
        NodeName: Text;
        ActualNodeText: Text;
        NodePath: Text;
        NodeText: Text;
        Prefix: Text;
    begin
        // [SCENARIO 2] Add an XML element that belongs to a custom namespace to an XML document.
        // [GIVEN] XML document.
        // [WHEN] Run the AddElementWithPrefix function.
        // [THEN] Element is added to the document.

        // Setup
        XMLDOMMgt.LoadXMLNodeFromText('<root />', RootXmlNode);

        // Pre-Exercise
        NodeName := LibraryUtility.GenerateGUID();
        NodeText := LibraryUtility.GenerateRandomText(1024);
        Prefix := LibraryUtility.GenerateGUID();
        Namespace := 'http://www.contoso.com/';

        // Exercise
        XMLDOMMgt.AddElementWithPrefix(RootXmlNode, NodeName, NodeText, Prefix, Namespace, CreatedXmlNode);

        // Pre-Verify
        NodePath := '/root/' + Prefix + ':' + NodeName;
        ActualNodeText := XMLDOMMgt.FindNodeTextWithNamespace(RootXmlNode, NodePath, Prefix, Namespace);

        // Verify
        Assert.AreEqual(NodeText, ActualNodeText, StrSubstNo(NodeContentNotFoundErr, NodeName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddAttribute()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        CreatedXmlNode: DotNet XmlNode;
        FoundXmlAttribute: DotNet XmlAttribute;
        FoundXmlNode: DotNet XmlNode;
        RootXmlNode: DotNet XmlNode;
        AttributeName: Text;
        AttributeValue: Text;
        NodeName: Text;
        NodeText: Text;
    begin
        // [SCENARIO 3] Add an XML attribute to an XML element in an XML document.
        // [GIVEN] XML document.
        // [WHEN] Run the AddAttribute function.
        // [THEN] Attribute is added to the element in the document.

        // Pre-Setup
        XMLDOMMgt.LoadXMLNodeFromText('<root />', RootXmlNode);

        // Setup
        NodeName := LibraryUtility.GenerateGUID();
        NodeText := LibraryUtility.GenerateRandomText(1024);
        XMLDOMMgt.AddElement(RootXmlNode, NodeName, NodeText, '', CreatedXmlNode);

        // Pre-Exercise
        AttributeName := LibraryUtility.GenerateGUID();
        AttributeValue := LibraryUtility.GenerateRandomText(1024);

        // Exercise
        XMLDOMMgt.AddAttribute(CreatedXmlNode, AttributeName, AttributeValue);

        // Pre-Verify
        Assert.IsTrue(XMLDOMMgt.FindNode(RootXmlNode, '/root/' + NodeName, FoundXmlNode), StrSubstNo(NodeNotFoundErr, NodeName));
        FoundXmlAttribute := FoundXmlNode.Attributes.Item(0);

        // Verify
        Assert.IsFalse(IsNull(FoundXmlAttribute), StrSubstNo(AttributeNotFoundErr, AttributeName, NodeName));
        Assert.AreEqual(AttributeValue, FoundXmlAttribute.Value, StrSubstNo(AttributeContentNotFoundErr, AttributeName, NodeName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddAttributeWithPrefix()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        CreatedXmlNode: DotNet XmlNode;
        FoundXmlAttribute: DotNet XmlAttribute;
        FoundXmlNode: DotNet XmlNode;
        RootXmlNode: DotNet XmlNode;
        AttributeName: Text;
        AttributeNamespace: Text;
        AttributePrefix: Text;
        AttributeValue: Text;
        Namespace: Text;
        NodeName: Text;
        NodePath: Text;
        NodeText: Text;
        Prefix: Text;
    begin
        // [SCENARIO 4] Add an XML attribute that belongs to a custom namespace to an XML element in an XML document.
        // [GIVEN] XML document.
        // [WHEN] Run the AddAttributeWithPrefix function.
        // [THEN] Attribute is added to the element in the document.

        // Pre-Setup
        XMLDOMMgt.LoadXMLNodeFromText('<root />', RootXmlNode);

        // Setup
        NodeName := LibraryUtility.GenerateGUID();
        NodeText := LibraryUtility.GenerateRandomText(1024);
        Prefix := LibraryUtility.GenerateGUID();
        Namespace := 'http://www.contoso.com/';
        XMLDOMMgt.AddElementWithPrefix(RootXmlNode, NodeName, NodeText, Prefix, Namespace, CreatedXmlNode);

        // Pre-Exercise
        AttributeName := LibraryUtility.GenerateGUID();
        AttributeValue := LibraryUtility.GenerateRandomText(1024);
        AttributePrefix := LibraryUtility.GenerateGUID();
        AttributeNamespace := 'http://www.contoso.net/';

        // Exercise
        XMLDOMMgt.AddAttributeWithPrefix(CreatedXmlNode, AttributeName, AttributePrefix, AttributeNamespace, AttributeValue);

        // Pre-Verify
        NodePath := '/root/' + Prefix + ':' + NodeName;
        Assert.IsTrue(
          XMLDOMMgt.FindNodeWithNamespace(RootXmlNode, NodePath, Prefix, Namespace, FoundXmlNode),
          StrSubstNo(NodeNotFoundErr, NodeName));
        FoundXmlAttribute := FoundXmlNode.Attributes.Item(0);

        // Verify
        Assert.IsFalse(IsNull(FoundXmlAttribute), StrSubstNo(AttributeNotFoundErr, AttributeName, NodeName));
        Assert.AreEqual(AttributeValue, FoundXmlAttribute.Value, StrSubstNo(AttributeContentNotFoundErr, AttributeName, NodeName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMissingElement()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        RootXmlNode: DotNet XmlNode;
        ActualNodeText: Text;
    begin
        // [SCENARIO 5] Check that the value returned from a non-existing element is the empty string.
        // [GIVEN] XML document
        // [WHEN] Run the FindNodeTextWithNamespace function
        // [THEN] The returned body of the searched element is an empty string.

        // Setup
        XMLDOMMgt.LoadXMLNodeFromText('<root />', RootXmlNode);

        // Exercise
        ActualNodeText := XMLDOMMgt.FindNodeTextWithNamespace(RootXmlNode, '/root/' + LibraryUtility.GenerateGUID(), 'Prefix', '');

        // Verify
        Assert.AreEqual('', ActualNodeText, StrSubstNo(NodeContentNotFoundErr, ''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckElementTextWithEmptyNamespace()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        CreatedXmlNode: DotNet XmlNode;
        RootXmlNode: DotNet XmlNode;
        Namespace: Text;
        NodeName: Text;
        ActualNodeText: Text;
        NodePath: Text;
        NodeText: Text;
        Prefix: Text;
    begin
        // [SCENARIO 6] Add an XML element that belongs to a custom empty namespace to an XML document.
        // [GIVEN] XML document.
        // [WHEN] Run the FindNodeTextWithNamespace function.
        // [THEN] Element is retrieved from the document and the text of the element is the same.

        // Setup
        XMLDOMMgt.LoadXMLNodeFromText('<root />', RootXmlNode);

        NodeName := LibraryUtility.GenerateGUID();
        NodeText := LibraryUtility.GenerateRandomText(1024);
        Prefix := LibraryUtility.GenerateGUID();
        Namespace := '';
        XMLDOMMgt.AddElementWithPrefix(RootXmlNode, NodeName, NodeText, Prefix, Namespace, CreatedXmlNode);

        // Exercise
        NodePath := '/root/' + Prefix + ':' + NodeName;
        ActualNodeText := XMLDOMMgt.FindNodeTextWithNamespace(RootXmlNode, NodePath, Prefix, Namespace);

        // Verify
        Assert.AreEqual(NodeText, ActualNodeText, StrSubstNo(NodeContentNotFoundErr, NodeName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckElementTextWithEmptyPrefix()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        CreatedXmlNode: DotNet XmlNode;
        RootXmlNode: DotNet XmlNode;
        Namespace: Text;
        NodeName: Text;
        NodePath: Text;
        NodeText: Text;
        Prefix: Text;
    begin
        // [SCENARIO 7] Add an XML element that belongs to a custom namespace and an empty prefix to an XML document.
        // [GIVEN] XML document.
        // [WHEN] Run the FindNodeTextWithNamespace function.
        // [THEN] Element is retrieved from the document and the text of the element is the same.

        // Setup
        XMLDOMMgt.LoadXMLNodeFromText('<root />', RootXmlNode);
        NodeName := LibraryUtility.GenerateGUID();
        NodeText := LibraryUtility.GenerateRandomText(1024);
        Prefix := '';
        Namespace := 'http://www.contoso.net/';
        XMLDOMMgt.AddElementWithPrefix(RootXmlNode, NodeName, NodeText, Prefix, Namespace, CreatedXmlNode);
        // The path of the node should not contain the prefix and colon as this is not added to the XML when this is empty
        NodePath := '/root/' + NodeName;

        // Exercise
        asserterror XMLDOMMgt.FindNodeTextWithNamespace(RootXmlNode, NodePath, Prefix, Namespace);
        Assert.ExpectedError(EmptyPrefixErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAddNamespaceWithMultipleNamespaces()
    var
        TempBlobUTF8: Codeunit "Temp Blob";
        XMLDOMMgt: Codeunit "XML DOM Management";
        XmlDoc: DotNet XmlDocument;
        RootXmlNode: DotNet XmlNode;
        XmlNamespaceManager: DotNet XmlNamespaceManager;
        OutStream: OutStream;
        RootNamespace: Text[250];
        Namespace1: Text[250];
        Namespace2: Text[250];
        Namespace1Prefix: Text[20];
        Namespace2Prefix: Text[20];
    begin
        // [SCENARIO 8] Extract multiple namespaces of an XML document to NamespaceManager
        // [GIVEN] XML document with multiple namespace.
        // [WHEN] Run the AddNamespaces function.
        // [THEN] NamespaceManager is filled out with all the namespaces of the document

        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        RootNamespace := LibraryUtility.GenerateGUID();
        Namespace1 := LibraryUtility.GenerateGUID();
        Namespace2 := LibraryUtility.GenerateGUID();
        Namespace1Prefix := LibraryUtility.GenerateGUID();
        Namespace2Prefix := LibraryUtility.GenerateGUID();

        XMLDOMMgt.LoadXMLNodeFromText(
          WriteXMLFileWithNamespaces(RootNamespace, Namespace1Prefix, Namespace1, Namespace2Prefix, Namespace2),
          RootXmlNode);
        XmlDoc := RootXmlNode.OwnerDocument;

        XMLDOMMgt.AddNamespaces(XmlNamespaceManager, XmlDoc);
        Assert.AreEqual(
          RootNamespace,
          XmlNamespaceManager.LookupNamespace(''),
          StrSubstNo(NamespacePrefixResolveErr, ''));
        Assert.AreEqual(
          Namespace1,
          XmlNamespaceManager.LookupNamespace(Namespace1Prefix),
          StrSubstNo(NamespacePrefixResolveErr, Namespace1Prefix));
        Assert.AreEqual(
          Namespace2,
          XmlNamespaceManager.LookupNamespace(Namespace2Prefix),
          StrSubstNo(NamespacePrefixResolveErr, Namespace2Prefix));
    end;

    local procedure WriteXMLFileWithNamespaces(RootNS: Text[250]; NS1Prefix: Text[20]; NS1: Text[250]; NS2Prefix: Text[20]; NS2: Text[250]): Text
    begin
        // Write a document with multiple namespaces
        exit(StrSubstNo(XMLWithNamesacesTxt, RootNS, NS1Prefix, NS1, NS2Prefix, NS2))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDoctypeElementWithEmptyInternalSubset()
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        FileManagement: Codeunit "File Management";
        File: File;
        XmlDocument: DotNet XmlDocument;
        XmlReaderSettings: DotNet XmlReaderSettings;
        FileName: Text;
        FileText: Text[1024];
        NewFileName: Text;
    begin
        // [SCENARIO 381033] Doctype tag contains only name of root object when other options are not set in loaded document

        // [GIVEN] Text of XML with '<!DOCTYPE rootNode>'
        CreateXmlFile(FileName, XmlFileHeaderTok, XmlFileDoctypeTok, XmlFileRootNodeTok);

        // [GIVEN] Load the text to XmlDocument
        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings();
        XmlReaderSettings.DtdProcessing := 2; // Value of DtdProcessing.Parse has been assigned as integer because DtdProcessing has method Parse.
        XMLDOMManagement.LoadXMLDocumentFromFileWithXmlReaderSettings(FileName, XmlDocument, XmlReaderSettings);

        // [WHEN] Save XmlDocument to file
        NewFileName := FileManagement.ServerTempFileName('xml');
        XmlDocument.Save(NewFileName);

        // [THEN] String '<!DOCTYPE rootNode>' exists in file
        File.Open(NewFileName);
        File.Read(FileText);
        Assert.IsTrue(StrPos(FileText, XmlFileDoctypeTok) <> 0, DoctypeElementErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLoadXmlDocumentWithoutDoctype()
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
        XmlReaderSettings: DotNet XmlReaderSettings;
        FileName: Text;
    begin
        // [SCENARIO 381033] Xml document loads without <DOCTYPE> and with XmlReaderSettings

        // [GIVEN] Text of XML without '<!DOCTYPE rootNode>'
        CreateXmlFile(FileName, XmlFileHeaderTok, '', XmlFileRootNodeTok);

        // [GIVEN] Instance of XmlReaderSettings
        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings();

        // [WHEN] Invoke "XML DOM Management".LoadXMLDocumentFromFileWithXmlReaderSettings
        XMLDOMManagement.LoadXMLDocumentFromFileWithXmlReaderSettings(FileName, XmlDocument, XmlReaderSettings);

        // [THEN] XmlDocument has child nodes
        Assert.IsTrue(XmlDocument.HasChildNodes, LoadXmlDocErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadXmlDocumentFromBlankText()
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
    begin
        // [SCENARIO 223425] COD6224.LoadXMLDocumentFromText returns empty Xml Document when blank text is passed
        XMLDOMManagement.LoadXMLDocumentFromText('', XmlDocument);
        Assert.IsFalse(IsNull(XmlDocument), 'Xml Document is null');
        Assert.IsTrue(IsNull(XmlDocument.DocumentElement), 'Document element is not null');
    end;

    local procedure CreateXmlFile(var FileName: Text; XmlHeader: Text; XmlDoctype: Text; XmlRootNode: Text)
    var
        FileManagement: Codeunit "File Management";
        File: File;
    begin
        FileName := FileManagement.ServerTempFileName('xml');
        File.TextMode(true);
        File.Create(FileName);
        File.Write(XmlHeader);
        File.Write(XmlDoctype);
        File.Write(XmlRootNode);
        File.Close();
    end;
}

