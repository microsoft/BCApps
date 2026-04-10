codeunit 139200 "XML Buffer Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [XML Buffer]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        FileManagement: Codeunit "File Management";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        WrongNamespaceUriErr: Label 'Wrong namespace uri.';

    [Test]
    [Scope('OnPrem')]
    procedure CreateTempRootNodeWithoutNamespace()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [GIVEN] A temporary XML Buffer
        // [WHEN] Creating a root element with no namespace
        // [THEN] Only this one root element is added
        // [THEN] Node has correct values
        CreateAndVerifyRootNode(TempXMLBuffer, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTempRootNodeWithNamespace()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [GIVEN] A temporary XML Buffer
        // [WHEN] Creating a root element with one namespace
        // [THEN] A root element is added
        // [THEN] A namespace attribute is added
        // [THEN] Node and namespace has correct values
        CreateAndVerifyRootNode(TempXMLBuffer, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTempRootNodeWithMultipleNamespaces()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [GIVEN] A temporary XML Buffer
        // [WHEN] Creating a root element with two namespaces
        // [THEN] A root element is added
        // [THEN] Two namespace attributes are added
        // [THEN] Node and namespaces have correct values
        CreateAndVerifyRootNode(TempXMLBuffer, 2, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTempRootNodeWithDefaultNamespace()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [GIVEN] A temporary XML Buffer
        // [WHEN] Creating a root element with a default namespace (no prefix)
        // [THEN] A root element is added
        // [THEN] One namespace attributes is added
        // [THEN] Node and namespace has correct values
        CreateAndVerifyRootNode(TempXMLBuffer, 1, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempRootNodeWithoutNamespace()
    begin
        // [GIVEN] A temporary XML Buffer
        // [GIVEN] A root element with no namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyTempXmlBuffer(0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempRootNodeWithNamespace()
    begin
        // [GIVEN] A temporary XML Buffer
        // [GIVEN] A root element with one namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyTempXmlBuffer(1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempRootNodeWithMultipleNamespaces()
    begin
        // [GIVEN] A temporary XML Buffer
        // [GIVEN] A root element with two namespaces
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyTempXmlBuffer(2, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempRootNodeWithDefaultNamespace()
    begin
        // [GIVEN] A temporary XML Buffer
        // [GIVEN] A root element with default namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyTempXmlBuffer(1, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempElementsWithoutNamespace()
    begin
        // [GIVEN] A temporary XML Buffer
        // [GIVEN] A root element and subelements with no namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyTempXmlBufferWithNodes(0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempElementsWithNamespace()
    begin
        // [GIVEN] A temporary XML Buffer
        // [GIVEN] A root element and subelements with one namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyTempXmlBufferWithNodes(1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempElementsWithMultipleNamespaces()
    begin
        // [GIVEN] A temporary XML Buffer
        // [GIVEN] A root element and subelements with two namespaces
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyTempXmlBufferWithNodes(2, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempElementsWithDefaultNamespace()
    begin
        // [GIVEN] A temporary XML Buffer
        // [GIVEN] A root element and subelements with default namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyTempXmlBufferWithNodes(1, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TempElementsWithSpecialCharacters()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        RootNodeName: Text[250];
        ElementName: Text[250];
        ElementValue: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        // [GIVEN] An XML Buffer root element
        CreateRootNode(TempXMLBuffer, 2, false, RootNodeName, NamespacePrefix, NamespacePath);
        // [WHEN] Adding an XML element with special characters
        ElementName := 'A-._ÔÇÿÔÇ‡ÔÇáÔÇÖØÅ';
        ElementValue := 'ŽÁ!"#ŽÅ%&/()=?`Ž»½@ô${[]}|+/*-,.-;:_<>\ÔÇÿÔÇ‡ÔÇáÔÇÖØÅŽ†^''';
        TempXMLBuffer.AddElement(ElementName, ElementValue);

        // [THEN] The XML Buffer root node has one child with the same name and value
        Assert.IsTrue(TempXMLBuffer.HasChildNodes(), 'root element should have children.');
        Assert.AreEqual(1, TempXMLBuffer.CountChildElements(), 'Incorrect number of child nodes');
        Assert.IsTrue(TempXMLBuffer.FindChildElements(TempChildXMLBuffer), 'root element should have children.');
        Assert.AreEqual(ElementName, TempChildXMLBuffer.Name, 'Child name mismatch.');
        Assert.AreEqual(ElementValue, TempChildXMLBuffer.GetValue(), 'Child value mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TempElementProcessingInstructionsWithSpecialCharacters()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        RootNodeName: Text[250];
        ElementName: Text[250];
        ElementValue: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
        PIInstructionName: Text[250];
        PIInstructionValue: Text;
    begin
        // [GIVEN] An XML Buffer root element
        CreateRootNode(TempXMLBuffer, 2, false, RootNodeName, NamespacePrefix, NamespacePath);

        // [GIVEN] Adding an XML element with special characters
        ElementName := 'A-._ÔÇÿÔÇ‡ÔÇáÔÇÖØÅ';
        ElementValue := 'ŽÁ!"#ŽÅ%&/()=?`Ž»½@ô${[]}|+/*-,.-;:_<>\ÔÇÿÔÇ‡ÔÇáÔÇÖØÅŽ†^''';
        TempXMLBuffer.AddElement(ElementName, ElementValue);

        // [WHEN] Adding an XML Processing instructions with special characters
        ElementName := 'A-._ÔÇÿÔÇ‡ÔÇáÔÇÖØÅ';
        ElementValue := 'ŽÁ!"#ŽÅ%&/()=?`Ž»½@ô${[]}|+/*-,.-;:_<>\ÔÇÿÔÇ‡ÔÇáÔÇÖØÅŽ†^''';
        TempXMLBuffer.AddProcessingInstruction(PIInstructionName, PIInstructionValue);

        // [THEN] The XML Buffer root node has one processing instruction with the same name and value
        Assert.AreEqual(1, TempXMLBuffer.CountProcessingInstructions(), 'Incorrect number of child processing instructions');
        Assert.IsTrue(TempXMLBuffer.FindProcessingInstructions(TempChildXMLBuffer), 'element should have processing instructions.');
        Assert.AreEqual(PIInstructionName, TempChildXMLBuffer.Name, 'Processing Instruction name mismatch.');
        Assert.AreEqual(PIInstructionValue, TempChildXMLBuffer.GetValue(), 'Processing Instruction value mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateValueWithLengthOver250Characters()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        LibraryRandom: Codeunit "Library - Random";
        RootNodeName: Text[250];
        ElementName: Text[250];
        ElementValue: Text;
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        // [GIVEN] An XML Buffer root element
        CreateRootNode(TempXMLBuffer, 2, false, RootNodeName, NamespacePrefix, NamespacePath);
        // [WHEN] Adding an XML element with value longer than 250 characters
        ElementName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250);
        ElementValue := LibraryRandom.RandText(300);
        TempXMLBuffer.AddElement(ElementName, ElementValue);

        // [THEN] The XML Buffer root node has one child with the same name and value
        Assert.IsTrue(TempXMLBuffer.HasChildNodes(), 'root element should have children.');
        Assert.AreEqual(1, TempXMLBuffer.CountChildElements(), 'Incorrect number of child nodes');
        Assert.IsTrue(TempXMLBuffer.FindChildElements(TempChildXMLBuffer), 'root element should have children.');
        Assert.AreEqual(ElementName, TempChildXMLBuffer.Name, 'Child name mismatch.');
        Assert.AreEqual(ElementValue, TempChildXMLBuffer.GetValue(), 'Child value mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAttributeValueWithLengthOver250Characters()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        LibraryRandom: Codeunit "Library - Random";
        RootNodeName: Text[250];
        AttributeName: Text[250];
        AttributeValue: Text;
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        // [GIVEN] An XML Buffer root element
        CreateRootNode(TempXMLBuffer, 2, false, RootNodeName, NamespacePrefix, NamespacePath);
        // [WHEN] Adding an XML element with value longer than 250 characters
        AttributeName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250);
        AttributeValue := LibraryRandom.RandText(300);
        TempXMLBuffer.AddAttribute(AttributeName, AttributeValue);

        // [THEN] The XML Buffer root node has one child with the same name and value
        Assert.AreEqual(3, TempXMLBuffer.CountAttributes(), 'Incorrect number of child nodes');

        // Assert.AreEqual(ElementName, TempChildXMLBuffer.Name, 'Child name mismatch.');
        Assert.AreEqual(AttributeValue, TempXMLBuffer.GetAttributeValueAsText(AttributeName), 'Attribute value mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateElementProcessingInstructionValueWithLengthOver250Characters()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        LibraryRandom: Codeunit "Library - Random";
        RootNodeName: Text[250];
        ElementName: Text[250];
        ElementValue: Text;
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
        PIInstructionName: Text[250];
        PIInstructionValue: Text;
    begin
        // [GIVEN] An XML Buffer root element
        CreateRootNode(TempXMLBuffer, 2, false, RootNodeName, NamespacePrefix, NamespacePath);

        // [WHEN] Adding an XML element
        ElementName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250);
        ElementValue := LibraryRandom.RandText(300);
        TempXMLBuffer.AddElement(ElementName, ElementValue);

        // [WHEN] Adding an XML element processing instruction longer than 250 characters
        PIInstructionName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250);
        PIInstructionValue := LibraryRandom.RandText(300);
        TempXMLBuffer.AddProcessingInstruction(PIInstructionName, PIInstructionValue);

        // [THEN] The XML Buffer root node has one processing instruction with the same name and value
        Assert.AreEqual(1, TempXMLBuffer.CountProcessingInstructions(), 'Incorrect number of child processing instructions');
        Assert.IsTrue(TempXMLBuffer.FindProcessingInstructions(TempChildXMLBuffer), 'element should have processing instructions.');
        Assert.AreEqual(PIInstructionName, TempChildXMLBuffer.Name, 'Processing Instruction name mismatch.');
        Assert.AreEqual(PIInstructionValue, TempChildXMLBuffer.GetValue(), 'Processing Instruction value mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempElementsWithSpecialCharacters()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        RootNodeName: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        // [GIVEN] An XML Buffer root element
        // [GIVEN] A subelement containing special characters
        CreateRootNode(TempXMLBuffer, 2, false, RootNodeName, NamespacePrefix, NamespacePath);
        TempXMLBuffer.AddAttribute('_', 'ŽÁ!#ŽÅ%/()=?`Ž»@ô${[]}|+/*½-,.-;:_\Ž†^''');
        TempXMLBuffer.AddElement('A-._', 'ŽÁ!"#ŽÅ%&/()=?`Ž»½@ô${[]}|+/*-,.-;:_<>\Ž†^''');

        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        SaveLoadAndVerifyTempXmlBuffer(TempXMLBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadTempElementsAndProcessingInstructionsWithSpecialCharacters()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        RootNodeName: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        // [GIVEN] An XML Buffer root element
        // [GIVEN] A subelement containing special characters
        CreateRootNode(TempXMLBuffer, 2, false, RootNodeName, NamespacePrefix, NamespacePath);
        TempXMLBuffer.AddAttribute('_', 'ŽÁ!#ŽÅ%/()=?`Ž»@ô${[]}|+/*½-,.-;:_\Ž†^''');
        TempXMLBuffer.AddElement('A-._', 'ŽÁ!"#ŽÅ%&/()=?`Ž»½@ô${[]}|+/*-,.-;:_<>\Ž†^''');
        TempXMLBuffer.AddProcessingInstruction('A-._', 'ŽÁ!"#ŽÅ%&/()=?`Ž»½@ô${[]}|+/*-,.-;:_<>\Ž†^''');

        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        SaveLoadAndVerifyTempXmlBuffer(TempXMLBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TempFindNodesByXPath()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        RootNodeName: Text[250];
        ElementName: Text[250];
        ElementValue: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        // [GIVEN] A temporary XML Buffer structure containing three elements with the same name
        // [GIVEN] One of these elements contains an attribute
        CreateRootNode(TempXMLBuffer, 2, false, RootNodeName, NamespacePrefix, NamespacePath);
        ElementName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250);
        ElementValue := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250);
        TempXMLBuffer.AddGroupElement(ElementName);
        TempXMLBuffer.AddAttribute(
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250),
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250));
        TempXMLBuffer.GetParent();
        TempXMLBuffer.AddElement(ElementName, ElementValue);
        TempXMLBuffer.AddElement(ElementName, ElementValue);
        // [WHEN] XMLBuffer.FindNodesByXPath is called with the name of these elements
        // [THEN] Only the three elements are found
        // [THEN] The entire subtree is not returned I.E. the attribute
        Assert.IsTrue(
          TempXMLBuffer.FindNodesByXPath(TempChildXMLBuffer, '/' + ElementName),
          'root element should have children.');

        Assert.AreEqual(ElementName, TempChildXMLBuffer.Name, 'First child name is incorrect.');
        TempChildXMLBuffer.Next();
        Assert.AreEqual(ElementName, TempChildXMLBuffer.Name, 'Second child name is incorrect.');
        Assert.AreEqual(ElementValue, TempChildXMLBuffer.GetValue(), 'Second child value is incorrect.');
        TempChildXMLBuffer.Next();
        Assert.AreEqual(ElementName, TempChildXMLBuffer.Name, 'Third child name is incorrect.');
        Assert.AreEqual(ElementValue, TempChildXMLBuffer.GetValue(), 'Third child value is incorrect.');
        TempChildXMLBuffer.Next();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindNodesByXPath()
    var
        XMLBuffer: Record "XML Buffer";
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        RootNodeName: Text[250];
        ElementName: Text[250];
        ElementValue: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        CreateRootNode(XMLBuffer, 2, false, RootNodeName, NamespacePrefix, NamespacePath);
        ElementName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250);
        ElementValue := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250);
        XMLBuffer.AddGroupElement(ElementName);
        XMLBuffer.AddAttribute(
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250),
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250));
        XMLBuffer.GetParent();
        XMLBuffer.AddElement(ElementName, ElementValue);
        XMLBuffer.AddElement(ElementName, ElementValue);
        Assert.IsTrue(
          XMLBuffer.FindNodesByXPath(TempChildXMLBuffer, '/' + ElementName),
          'root element should have children.');

        Assert.AreEqual(ElementName, TempChildXMLBuffer.Name, 'First child name is incorrect.');
        TempChildXMLBuffer.Next();
        Assert.AreEqual(ElementName, TempChildXMLBuffer.Name, 'Second child name is incorrect.');
        Assert.AreEqual(ElementValue, TempChildXMLBuffer.GetValue(), 'Second child value is incorrect.');
        TempChildXMLBuffer.Next();
        Assert.AreEqual(ElementName, TempChildXMLBuffer.Name, 'Third child name is incorrect.');
        Assert.AreEqual(ElementValue, TempChildXMLBuffer.GetValue(), 'Third child value is incorrect.');
        TempChildXMLBuffer.Next();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRootNodeWithoutNamespace()
    var
        XMLBuffer: Record "XML Buffer";
    begin
        // [GIVEN] A permanent XML Buffer
        // [WHEN] Creating a root element with no namespace
        // [THEN] Only this one root element is added
        // [THEN] Node has correct values
        CreateAndVerifyRootNode(XMLBuffer, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRootNodeWithNamespace()
    var
        XMLBuffer: Record "XML Buffer";
    begin
        // [GIVEN] A permanent XML Buffer
        // [WHEN] Creating a root element with one namespace
        // [THEN] A root element is added
        // [THEN] A namespace attribute is added
        // [THEN] Node and namespace has correct values
        CreateAndVerifyRootNode(XMLBuffer, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRootNodeWithMultipleNamespaces()
    var
        XMLBuffer: Record "XML Buffer";
    begin
        // [GIVEN] A permanent XML Buffer
        // [WHEN] Creating a root element with two namespaces
        // [THEN] A root element is added
        // [THEN] Two namespace attributes are added
        // [THEN] Node and namespaces have correct values
        CreateAndVerifyRootNode(XMLBuffer, 2, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRootNodeWithDefaultNamespace()
    var
        XMLBuffer: Record "XML Buffer";
    begin
        // [GIVEN] A permanent XML Buffer
        // [WHEN] Creating a root element with a default namespace (no prefix)
        // [THEN] A root element is added
        // [THEN] One namespace attributes is added
        // [THEN] Node and namespace has correct values
        CreateAndVerifyRootNode(XMLBuffer, 1, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadRootNodeWithoutNamespace()
    begin
        // [GIVEN] A permanent XML Buffer
        // [GIVEN] A root element with no namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyXmlBuffer(0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadRootNodeWithNamespace()
    begin
        // [GIVEN] A permanent XML Buffer
        // [GIVEN] A root element with one namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyXmlBuffer(1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadRootNodeWithMultipleNamespaces()
    begin
        // [GIVEN] A permanent XML Buffer
        // [GIVEN] A root element with two namespaces
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyXmlBuffer(2, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadRootNodeWithDefaultNamespace()
    begin
        // [GIVEN] A permanent XML Buffer
        // [GIVEN] A root element with default namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyXmlBuffer(1, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadNodesWithoutNamespace()
    begin
        // [GIVEN] A permanent XML Buffer
        // [GIVEN] A root element and subelements with no namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyXmlBufferWithNodes(0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadNodesWithNamespace()
    begin
        // [GIVEN] A permanent XML Buffer
        // [GIVEN] A root element and subelements with one namespace
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyXmlBufferWithNodes(1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadNodesWithMultipleNamespaces()
    begin
        // [GIVEN] A permanent XML Buffer
        // [GIVEN] A root element and subelements with two namespaces
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyXmlBufferWithNodes(2, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadNodesWithDefaultNamespace()
    begin
        // [GIVEN] A permanent XML Buffer
        // [GIVEN] A root element and subelements with two namespaces
        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        CreateSaveLoadAndVerifyXmlBufferWithNodes(1, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadAndSaveFile()
    var
        XMLBuffer: Record "XML Buffer";
        ServerFileName: Text;
        ResultServerFileName: Text;
    begin
        // [GIVEN] An XML file
        ServerFileName := CreateXmlFile();
        // [WHEN] The XML file is loaded into NAV using permanent XML Buffer and saved again to disk
        XMLBuffer.Load(ServerFileName);
        ResultServerFileName := FileManagement.ServerTempFileName('.xml');
        XMLBuffer.Save(ResultServerFileName);
        // [THEN] The XML file loaded into NAV is identical to the XML file exported from NAV
        VerifyIdenticalFiles(ServerFileName, ResultServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadAndSaveFileUsingTemporaryRecords()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        ServerFileName: Text;
        ResultServerFileName: Text;
    begin
        // [GIVEN] An XML file
        ServerFileName := CreateXmlFile();
        // [WHEN] The XML file is loaded into NAV using permanent XML Buffer and saved again to disk
        TempXMLBuffer.Load(ServerFileName);
        ResultServerFileName := FileManagement.ServerTempFileName('.xml');
        TempXMLBuffer.Save(ResultServerFileName);
        // [THEN] The XML file loaded into NAV is identical to the XML file exported from NAV
        VerifyIdenticalFiles(ServerFileName, ResultServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadFromInstream()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        File: File;
        InStream: InStream;
    begin
        // [GIVEN] An input stream
        File.Open(CreateXmlFile(), TEXTENCODING::UTF8);
        File.CreateInStream(InStream);

        // [WHEN] Loading the input stream
        TempXMLBuffer.Load(InStream);

        // [THEN] The XML Buffer table is not empty
        Assert.IsFalse(TempXMLBuffer.IsEmpty, 'Load from stream failed, the resulting XML Buffer is empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadFromText()
    var
        XMLBuffer: Record "XML Buffer";
        XmlText: Text;
    begin
        // [GIVEN] Xml text
        XmlText := '<?xml version="1.0" encoding="UTF-8"?>' +
          '<RootElement xmlns="namespaceURI">' +
          '  <SelfClosingElement attribute="attributeValue" />' +
          '</RootElement>';

        // [WHEN] Loading the xml text
        XMLBuffer.LoadFromText(XmlText);

        // [THEN] The xml text elements and attributes have been inserted into proper XML Buffer records
        Assert.AreEqual('RootElement', XMLBuffer.Name, '');
        Assert.AreEqual('namespaceURI', XMLBuffer.GetAttributeValueAsText('xmlns'), '');
        Assert.AreEqual(1, XMLBuffer.CountChildElements(), 'There should be exactly one child element.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateNonEmptyElements()
    var
        XMLBuffer: Record "XML Buffer";
        GroupNodeXMLBuffer: Record "XML Buffer";
        GroupNode2XMLBuffer: Record "XML Buffer";
    begin
        // [GIVEN] An xml buffer has been created with add NonEmpty elements
        XMLBuffer.CreateRootElement('RootNode');
        XMLBuffer.AddElement('emptyElement', '');
        XMLBuffer.AddNonEmptyElement('ignoredElement', '');
        XMLBuffer.AddNonEmptyElement('nonEmptyElement', 'value');
        // [GIVEN] A group node has been added with a nonempty last node, with blank value
        XMLBuffer.AddGroupElement('groupNode');
        GroupNodeXMLBuffer := XMLBuffer;
        XMLBuffer.AddNonEmptyLastElement('ignoredElement', '');
        // [GIVEN] A group node has been added with a nonempty last node, with a value
        XMLBuffer.AddGroupElement('groupNode2');
        GroupNode2XMLBuffer := XMLBuffer;
        XMLBuffer.AddNonEmptyLastElement('nonEmptyElement', 'value2');

        // [THEN] The root node contains four children
        Assert.AreEqual(4, XMLBuffer.CountChildElements(), 'Incorrect number of child elements of the root element.');
        // [THEN] The first group node does not contain any child nodes
        Assert.IsFalse(GroupNodeXMLBuffer.HasChildNodes(), 'The group node should not have any child elements.');
        // [THEN] The second group node has exactly one child element
        Assert.IsTrue(GroupNode2XMLBuffer.HasChildNodes(), 'The second group node should have children.');
        Assert.AreEqual(1, GroupNode2XMLBuffer.CountChildElements(), 'Incorrect number of child elements of the root element.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertElementAtSpecificPosition()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildElementsXMLBuffer: Record "XML Buffer" temporary;
        TempChildElementsPiXMLBuffer: Record "XML Buffer" temporary;
        Element2Position: Integer;
    begin
        // [GIVEN] An XML Buffer with a root element and two child elements A and B
        TempXMLBuffer.CreateRootElement('RootNode');
        TempXMLBuffer.AddElement('Element1', 'value1');
        TempXMLBuffer.AddProcessingInstruction('PIName1', 'PIValue1');
        Element2Position := TempXMLBuffer.AddElement('Element2', 'value2');

        // [GIVEN] The XML buffer is sorted after "Parent Entry No.","Node Number"
        TempXMLBuffer.SetCurrentKey("Parent Entry No.", Type, "Node Number");

        // [WHEN] A group node C is added between child element 1 and 2
        TempXMLBuffer.AddGroupElementAt('newGroupBetweenElement1and2', Element2Position);
        TempXMLBuffer.GetParent();

        // [THEN] In order, the child elements of the root node are A, C, B
        Assert.IsTrue(TempXMLBuffer.FindChildElements(TempChildElementsXMLBuffer), 'No child elements were found.');
        Assert.AreEqual('Element1', TempChildElementsXMLBuffer.Name, '');
        Assert.IsTrue(TempXMLBuffer.FindProcessingInstructions(TempChildElementsPiXMLBuffer),
          'No child elements processing instructions were found.');
        Assert.AreEqual('PIName1', TempChildElementsPiXMLBuffer.Name, '');
        TempChildElementsXMLBuffer.Next();
        Assert.AreEqual('newGroupBetweenElement1and2', TempChildElementsXMLBuffer.Name, '');
        TempChildElementsXMLBuffer.Next();
        Assert.AreEqual('Element2', TempChildElementsXMLBuffer.Name, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertElementAtSaveAndLoad()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [GIVEN] An XML Buffer with a root element and two child elements A and B
        TempXMLBuffer.CreateRootElement('RootNode');
        TempXMLBuffer.AddElement('Element1', 'value1');
        TempXMLBuffer.AddProcessingInstruction('PIName1', 'PIValue1');
        TempXMLBuffer.AddElement('Element2', 'value2');

        // [GIVEN] A group node C is added between child element 1 and 2
        TempXMLBuffer.AddGroupElementAt('newGroupBetweenElement1and2', 2);
        TempXMLBuffer.GetParent();

        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        SaveLoadAndVerifyXmlBuffer(TempXMLBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetParentFunctionNotFailedWhenNoXMLBufferExists()
    var
        XMLBuffer: Record "XML Buffer";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263386] When function GetParent of XML Buffer table invokes it is not fail if record does not exist

        XMLBuffer.DeleteAll();
        XMLBuffer."Parent Entry No." := 1;
        XMLBuffer.GetParent();
        XMLBuffer.TestField("Entry No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSaveAndVerifyXMLDocumentWithMultipleNamespaces()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 332187] Create and save XML file with child nodes of different namespaces using XML Buffer table
        // [GIVEN] A temporary XML Buffer with a root element with definitions of 2 namespaces
        TempXMLBuffer.CreateRootElement('Message');
        TempXMLBuffer.AddNamespace('s1', 'http://someschema/');
        TempXMLBuffer.AddNamespace('s2', 'http://someotherschema/');

        // [GIVEN] Child nodes of that namespaces
        TempXMLBuffer.AddElement('s1:FirstName', LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        TempXMLBuffer.AddElement('s1:LastName', LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        TempXMLBuffer.AddGroupElement('s1:Address');
        TempXMLBuffer.AddElement('s2:Street', LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        TempXMLBuffer.AddElement('s2:HouseNumber', LibraryUtility.GenerateRandomNumericText(3));
        TempXMLBuffer.AddElement('s2:PostalCode', LibraryUtility.GenerateRandomAlphabeticText(6, 0));
        TempXMLBuffer.GetParent();

        // [WHEN] Saving and then loading the XML Buffer
        // [THEN] The two XML Buffer lists are identical
        SaveLoadAndVerifyXmlBuffer(TempXMLBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNamespaceUriUndependParentID()
    var
        XMLBuffer: Record "XML Buffer";
        Namespace: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 374587] The "XML Buffer".GetNamespaceUriByPrefixAsText must return the uri independs of "Parent Entry No."

        // [GIVEN] Namespace with prefix 'namespace1' and uri = 'uri1'
        XMLBuffer.AddNamespace('namespace1', 'uri1');

        // [GIVEN] Set filter on XMLBuffer by "Parent Entry No."
        XMLBuffer.SetRange("Parent Entry No.", LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Invoke GetNamespaceUriByPrefixAsText for 'namespace1'
        Namespace := XMLBuffer.GetNamespaceUriByPrefixAsText('namespace1');

        // [THEN] Result must be equal 'uri1'
        Assert.AreEqual('uri1', Namespace, WrongNamespaceUriErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertAttributeWithNameSpace()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        XmlNodeDotNet: DotNet XmlNode;
        FileName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 374587] Stan can export xml element's attribute with specified namespace.

        TempXMLBuffer.AddGroupElement('soapenv:Envelope');
        TempXMLBuffer.AddNamespace('soapenv', 'http://schemas.xmlsoap.org/soap/envelope/');
        TempXMLBuffer.AddNamespace('web', 'http://www.MEScontrol.net/WebServices');
        TempXMLBuffer.AddNamespace('i', 'http://www.w3.org/2001/XMLSchema-instance');

        TempXMLBuffer.AddGroupElement('soapenv:Header');
        TempXMLBuffer.GetParent();
        TempXMLBuffer.AddGroupElement('soapenv:Body');
        TempXMLBuffer.AddGroupElement('web:CreateOrUpdateProduct');
        TempXMLBuffer.AddGroupElement('web:productDTO');
        TempXMLBuffer.AddGroupElement('web:Recipe');
        TempXMLBuffer.AddAttributeWithNamespace('i:nil', 'true');
        TempXMLBuffer.GetParent();

        TempXMLBuffer.GetParent();
        TempXMLBuffer.GetParent();
        TempXMLBuffer.GetParent();

        FileName := FileManagement.ServerTempFileName('xml');
        if not TempXMLBuffer.Save(FileName) then
            Assert.Fail(GetLastErrorText());

        LibraryXPathXMLReader.Initialize(FileName, 'xxx');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('soapenv', 'http://schemas.xmlsoap.org/soap/envelope/');
        LibraryXPathXMLReader.AddAdditionalNamespace('web', 'http://www.MEScontrol.net/WebServices');
        LibraryXPathXMLReader.AddAdditionalNamespace('i', 'http://www.w3.org/2001/XMLSchema-instance');
        LibraryXPathXMLReader.GetNodeByXPath(
            '//soapenv:Envelope/soapenv:Body/web:CreateOrUpdateProduct/web:productDTO/web:Recipe', XmlNodeDotNet);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XmlNodeDotNet, 'i:nil', 'true');
    end;

    [Test]
    procedure SaveXmlBufferWithNamespaces_Incident_250724617()
    var
        TempBlob: Codeunit "Temp Blob";
        TempXMLBuffer: Record "XML Buffer" temporary;
        XmlBufferReader: Codeunit "XML Buffer Reader";
    begin
        // [FEAUTE] [UT]
        // [SCENARIO 405913] Stan can save Xml Buffer with an attribute entry having blank namespace. 
        TempXMLBuffer.DeleteAll();
        TempXMLBuffer.CreateRootElement('soap:Envelope');
        TempXMLBuffer.AddNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        TempXMLBuffer.AddNamespace('xsd', 'http://www.w3.org/2001/XMLSchema');
        TempXMLBuffer.AddNamespace('soap', 'http://schemas.xmlsoap.org/soap/envelope/');

        TempXMLBuffer.AddGroupElement('soap:Body');
        TempXMLBuffer.AddGroupElement('GetCompanyByVat');
        TempXMLBuffer.AddNamespace('', 'http://connect.companyweb.be/');
        TempXMLBuffer.AddGroupElement('request');
        TempXMLBuffer.AddElement('VatNumber', 'ABC-111');
        TempXMLBuffer.AddElement('Language', 'EN');
        TempXMLBuffer.AddElement('CompanyWebLogin', 'sdetest');
        TempXMLBuffer.AddElement('CompanyWebPassword', 'example');

        TempXMLBuffer.FindSet();

        XmlBufferReader.SaveToTempBlob(TempBlob, TempXMLBuffer);
    end;

    local procedure CreateAndVerifyRootNode(var TempXMLBuffer: Record "XML Buffer" temporary; NumNamespaces: Integer; DefaultNamespace: Boolean)
    var
        TempChildrenXMLBuffer: Record "XML Buffer" temporary;
        TempIgnoredXMLBuffer: Record "XML Buffer" temporary;
        RootNodeName: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        CreateRootNode(TempXMLBuffer, NumNamespaces, DefaultNamespace, RootNodeName, NamespacePrefix, NamespacePath);

        Assert.IsFalse(TempXMLBuffer.FindChildElements(TempIgnoredXMLBuffer), 'root element should not have child elements.');
        if NumNamespaces = 0 then
            Assert.IsFalse(TempXMLBuffer.HasChildNodes(), 'root element should not have children.')
        else
            Assert.IsTrue(TempXMLBuffer.HasChildNodes(), 'root element should have children.');

        Assert.AreEqual(RootNodeName, TempXMLBuffer.Name, 'root element name is wrong');
        Assert.AreEqual(0, TempXMLBuffer.CountChildElements(), 'root element has an incorrect number of child nodes');
        Assert.AreEqual(NumNamespaces, TempXMLBuffer.CountAttributes(), 'root element has incorrect number of attributes');

        if NumNamespaces > 0 then begin
            Assert.IsTrue(TempXMLBuffer.FindAttributes(TempChildrenXMLBuffer), '');
            if DefaultNamespace then
                Assert.AreEqual(TempChildrenXMLBuffer.Name, 'xmlns', '')
            else
                Assert.AreEqual(TempChildrenXMLBuffer.Name, 'xmlns:' + NamespacePrefix[1], '');
            Assert.AreEqual(TempChildrenXMLBuffer.Value, NamespacePath[1], '');

            if NumNamespaces = 2 then begin
                TempChildrenXMLBuffer.Next();
                Assert.AreEqual('xmlns:' + NamespacePrefix[2], TempChildrenXMLBuffer.Name, '');
                Assert.AreEqual(NamespacePath[2], TempChildrenXMLBuffer.Value, '');
                Assert.AreEqual(NamespacePath[2], TempXMLBuffer.GetAttributeValueAsText('xmlns:' + NamespacePrefix[2]), '');
            end;
        end;
    end;

    local procedure AddElements(var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        NamespacePrefix: Text;
        PICount: Integer;
        i: Integer;
    begin
        NamespacePrefix := TempXMLBuffer.Namespace;
        if NamespacePrefix <> '' then
            NamespacePrefix += ':';

        TempXMLBuffer.AddElement(NamespacePrefix + 'Element1', 'Value1');
        TempXMLBuffer.AddElement(
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(TempXMLBuffer.Name), 0), 1, 250), '');
        TempXMLBuffer.AddGroupElement(NamespacePrefix + 'Element2');
        TempXMLBuffer.AddAttribute('attribute1', 'attributeValue1');
        TempXMLBuffer.AddAttribute('EmptyAttribute', '');

        PICount := LibraryRandom.RandInt(3);
        for i := 1 to PICount do
            TempXMLBuffer.AddProcessingInstruction('PIName' + Format(i), 'PIValue' + Format(i));

        TempXMLBuffer.AddElement(NamespacePrefix + 'Element3', 'Value3');
        TempXMLBuffer.AddLastElement(NamespacePrefix + 'Element4', 'Value4');
        TempXMLBuffer.AddGroupElement('emptyGroupnodeWithoutNamespace');
        TempXMLBuffer.GetParent();
        TempXMLBuffer.AddElement(NamespacePrefix + 'Element5', '');
        TempXMLBuffer.AddElement('DuplicateElementName', 'Value6');
        TempXMLBuffer.AddElement('DuplicateElementName', 'Value7');
        TempXMLBuffer.AddElement('DuplicateElementName', 'Value8');
    end;

    local procedure CreateRootNode(var TempXMLBuffer: Record "XML Buffer" temporary; NumNamespaces: Integer; DefaultNamespace: Boolean; var RootNodeName: Text[250]; var NamespacePrefix: array[2] of Text[250]; var NamespacePath: array[2] of Text[250])
    begin
        RootNodeName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, 250);
        TempXMLBuffer.CreateRootElement(RootNodeName);
        if NumNamespaces > 0 then begin
            NamespacePath[1] := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(50, 0), 1, 250);
            if not DefaultNamespace then
                NamespacePrefix[1] := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(1, 0), 1, 250);
            TempXMLBuffer.AddNamespace(NamespacePrefix[1], NamespacePath[1]);

            if NumNamespaces = 2 then begin
                NamespacePath[2] := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(TempXMLBuffer.Value), 0), 1, 250);
                NamespacePrefix[2] := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(TempXMLBuffer.Name) - 6, 0), 1, 250); // STRLEN('XMLNS:') = 6
                TempXMLBuffer.AddNamespace(NamespacePrefix[2], NamespacePath[2]);
            end
        end;
    end;

    local procedure CreateSaveLoadAndVerifyTempXmlBuffer(NumNamespaces: Integer; DefaultNamespace: Boolean)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        RootNodeName: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        CreateRootNode(TempXMLBuffer, NumNamespaces, DefaultNamespace, RootNodeName, NamespacePrefix, NamespacePath);
        SaveLoadAndVerifyTempXmlBuffer(TempXMLBuffer);
    end;

    local procedure CreateSaveLoadAndVerifyTempXmlBufferWithNodes(NumNamespaces: Integer; DefaultNamespace: Boolean)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        RootNodeName: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        CreateRootNode(TempXMLBuffer, NumNamespaces, DefaultNamespace, RootNodeName, NamespacePrefix, NamespacePath);
        AddElements(TempXMLBuffer);
        SaveLoadAndVerifyTempXmlBuffer(TempXMLBuffer);
    end;

    local procedure CreateSaveLoadAndVerifyXmlBuffer(NumNamespaces: Integer; DefaultNamespace: Boolean)
    var
        XMLBuffer: Record "XML Buffer";
        RootNodeName: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        CreateRootNode(XMLBuffer, NumNamespaces, DefaultNamespace, RootNodeName, NamespacePrefix, NamespacePath);
        SaveLoadAndVerifyXmlBuffer(XMLBuffer);
    end;

    local procedure CreateSaveLoadAndVerifyXmlBufferWithNodes(NumNamespaces: Integer; DefaultNamespace: Boolean)
    var
        XMLBuffer: Record "XML Buffer";
        RootNodeName: Text[250];
        NamespacePrefix: array[2] of Text[250];
        NamespacePath: array[2] of Text[250];
    begin
        CreateRootNode(XMLBuffer, NumNamespaces, DefaultNamespace, RootNodeName, NamespacePrefix, NamespacePath);
        AddElements(XMLBuffer);
        SaveLoadAndVerifyXmlBuffer(XMLBuffer);
    end;

    local procedure CreateXmlFile() ServerFileName: Text
    var
        OutStream: OutStream;
        File: File;
    begin
        ServerFileName := FileManagement.ServerTempFileName('.xml');
        File.Create(ServerFileName);
        File.TextMode(true);
        File.CreateOutStream(OutStream);

        WriteLineToOutstream(OutStream, '<?xml version="1.0" encoding="UTF-8"?>');
        WriteLineToOutstream(OutStream, '<RootElement xmlns="namespaceURI">');
        WriteLineToOutstream(OutStream, '  <SelfClosingElement attribute="attributeValue" />');
        WriteLineToOutstream(OutStream, '  <Element1>');
        WriteLineToOutstream(OutStream, '    <Element11 attribute="" Attribute2="test">');
        WriteLineToOutstream(OutStream, '      <?PIName11 PIValue="PIValue11"?>');
        WriteLineToOutstream(OutStream, '      <Element111 attribute="" Attribute2="test" />');
        WriteLineToOutstream(OutStream, '      <Element112>Value</Element112>');
        WriteLineToOutstream(OutStream, '    </Element11>');
        WriteLineToOutstream(OutStream, '  </Element1>');
        WriteLineToOutstream(OutStream, '  <Element2>');
        WriteLineToOutstream(OutStream, '    <Element21 Currency="DK">1253.53</Element21>');
        WriteLineToOutstream(OutStream, '    <Element21 Currency="EUR">092,5310</Element21>');
        WriteLineToOutstream(OutStream, '  </Element2>');
        WriteLineToOutstream(OutStream, '</RootElement>');
        File.Close();
    end;

    local procedure SaveLoadAndVerifyTempXmlBuffer(var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        TempXMLBufferLoaded: Record "XML Buffer" temporary;
        ServerFilePath: Text;
    begin
        ServerFilePath := FileManagement.ServerTempFileName('.xml');
        TempXMLBuffer.Save(ServerFilePath);
        TempXMLBufferLoaded.Load(ServerFilePath);
        VerifyIdenticalStructures(TempXMLBuffer, TempXMLBufferLoaded);
    end;

    local procedure SaveLoadAndVerifyXmlBuffer(var XMLBuffer: Record "XML Buffer")
    var
        XMLBufferLoaded: Record "XML Buffer";
        ServerFilePath: Text;
    begin
        ServerFilePath := FileManagement.ServerTempFileName('.xml');
        XMLBuffer.Save(ServerFilePath);
        XMLBuffer.SetCurrentKey("Parent Entry No.", Type, "Node Number");
        XMLBufferLoaded.Load(ServerFilePath);
        XMLBufferLoaded.SetCurrentKey("Parent Entry No.", Type, "Node Number");
        VerifyIdenticalStructures(XMLBuffer, XMLBufferLoaded);
    end;

    local procedure VerifyIdenticalFiles(ExpectedFileName: Text; ActualFileName: Text)
    var
        ExpectedFile: File;
        ActualFile: File;
        ExpectedInStream: InStream;
        ActualInstream: InStream;
        ExpectedLine: Text;
        ActualLine: Text;
    begin
        ExpectedFile.Open(ExpectedFileName, TEXTENCODING::UTF8);
        ExpectedFile.TextMode(true);
        ExpectedFile.CreateInStream(ExpectedInStream);
        ActualFile.Open(ActualFileName, TEXTENCODING::UTF8);
        ActualFile.TextMode(true);
        ActualFile.CreateInStream(ActualInstream);

        while not (ExpectedInStream.EOS and ActualInstream.EOS) do begin
            ExpectedInStream.ReadText(ExpectedLine);
            ActualInstream.ReadText(ActualLine);
            Assert.AreEqual(ExpectedLine, ActualLine, 'Loaded and saved XML files are not identical.');
        end;
    end;

    local procedure VerifyIdenticalStructures(var ExpectedTempXMLBuffer: Record "XML Buffer" temporary; var ActualTempXMLBuffer: Record "XML Buffer" temporary)
    begin
        // Since nodes are be imported in the same order as they are exported, we can just loop through each node:
        ExpectedTempXMLBuffer.SetRange("Import ID", ExpectedTempXMLBuffer."Import ID");
        ExpectedTempXMLBuffer.FindSet();
        ActualTempXMLBuffer.SetRange("Import ID", ActualTempXMLBuffer."Import ID");
        ActualTempXMLBuffer.FindSet();
        repeat
            Assert.AreEqual(ExpectedTempXMLBuffer.Type, ActualTempXMLBuffer.Type, 'Type');
            Assert.AreEqual(ExpectedTempXMLBuffer.Name, ActualTempXMLBuffer.Name, 'Name');
            Assert.AreEqual(ExpectedTempXMLBuffer.Path, ActualTempXMLBuffer.Path, 'Path');
            Assert.AreEqual(ExpectedTempXMLBuffer.Value, ActualTempXMLBuffer.Value, 'Value');
            Assert.AreEqual(ExpectedTempXMLBuffer.Depth, ActualTempXMLBuffer.Depth, 'Depth');
            Assert.AreEqual(
              ExpectedTempXMLBuffer."Node Number", ActualTempXMLBuffer."Node Number", 'Node Number ' + ActualTempXMLBuffer.Name);
            Assert.AreEqual(ExpectedTempXMLBuffer.Namespace, ActualTempXMLBuffer.Namespace, 'Namespace');
        until (ExpectedTempXMLBuffer.Next() = 0) or (ActualTempXMLBuffer.Next() = 0);
    end;

    local procedure WriteLineToOutstream(var OutStream: OutStream; Line: Text)
    begin
        OutStream.WriteText(Line);
        OutStream.WriteText();
    end;
}

