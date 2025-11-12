codeunit 131337 "Library - XPath XML Reader"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        XMLDocOut: DotNet XmlDocument;
        XmlDocumentNative: XmlDocument;
        XMLNode: DotNet XmlNode;
        XmlNodeNative: XmlNode;
        XMLNsMgr: DotNet XmlNamespaceManager;
        XmlNamespaceManagerNative: XmlNamespaceManager;
        DefaultNamespacePrefixTxt: Label 'ns';
        UnexpectedValueErr: Label 'Unexpected value!. Expected: %1''. In XML file: %2.';
        NodeCountErr: Label 'Count is wrong. Node: %1';
        NodeCountWithValueErr: Label 'Count is wrong for value %1 in nodes %2';
        NodeNotFoundErr: Label 'The selected node %1 was not found.';
        UnexpectedNodeValueErr: Label 'Unexpected node %1 value. Expected: %2, actual %3.';
        MissingAttributeErr: Label '%1 attribute is missing from the node %2.';
        UnexpectedAttributeValueErr: Label 'Unexpected attribute %1 value.';
        UnexpectedAttributeErr: Label 'Unepexted %1 attribute in the node %2.';
        SkipDefaultNamespace: Boolean;
        NodeIndexOutOfBoundsErr: Label 'Node <%1> index %2  is out of bounds (%3 total nodes exist).';
        NodeShouldNotExistInSubtreeErr: Label 'Node %1 should not exist in the subtree', Comment = '%1 - node name to search for';
        DeclarationEncodingErr: Label 'XMLDeclaration: Wrong Encoding property.';
        DeclarationStandaloneErr: Label 'XMLDeclaration: Wrong Standalone property.';
        DeclarationVersionErr: Label 'XMLDeclaration: Wrong Version property.';

    procedure Initialize(FullFilePath: Text; NameSpace: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(FullFilePath, XMLDocOut);

        XMLNsMgr := XMLNsMgr.XmlNamespaceManager(XMLDocOut.NameTable);
        XMLNsMgr.AddNamespace(DefaultNamespacePrefixTxt, NameSpace);
    end;

    procedure InitializeWithPrefix(FullFilePath: Text; Prefix: Text; NameSpace: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(FullFilePath, XMLDocOut);

        XMLNsMgr := XMLNsMgr.XmlNamespaceManager(XMLDocOut.NameTable);
        XMLNsMgr.AddNamespace(Prefix, NameSpace);
    end;

    procedure InitializeWithBlob(TempBlob: Codeunit "Temp Blob"; NameSpace: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStream, XMLDocOut);

        XMLNsMgr := XMLNsMgr.XmlNamespaceManager(XMLDocOut.NameTable);
        XMLNsMgr.AddNamespace(DefaultNamespacePrefixTxt, NameSpace);
    end;

    procedure InitializeWithText(Content: Text; NameSpace: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDocumentNode: DotNet XmlNode;
    begin
        XMLDOMManagement.LoadXMLNodeFromText(Content, XmlDocumentNode);
        XMLDocOut := XmlDocumentNode.OwnerDocument;

        XMLNsMgr := XMLNsMgr.XmlNamespaceManager(XMLDocOut.NameTable);
        XMLNsMgr.AddNamespace(DefaultNamespacePrefixTxt, NameSpace);
    end;

    procedure InitializeXml(InStreamXml: InStream; Namespace: Text)
    begin
        InitializeXml(InStreamXml, DefaultNamespacePrefixTxt, Namespace);
    end;

    procedure InitializeXml(InStreamXml: InStream; Prefix: Text; Namespace: Text)
    begin
        XmlDocument.ReadFrom(InStreamXml, XmlDocumentNative);
        InitializeXmlNamespaceManager(Prefix, Namespace);
    end;

    procedure InitializeXml(Content: Text; Namespace: Text)
    begin
        InitializeXml(Content, DefaultNamespacePrefixTxt, Namespace);
    end;

    procedure InitializeXml(Content: Text; Prefix: Text; Namespace: Text)
    begin
        XmlDocument.ReadFrom(Content, XmlDocumentNative);
        InitializeXmlNamespaceManager(Prefix, Namespace);
    end;

    procedure InitializeXml(TempBlob: Codeunit "Temp Blob"; Namespace: Text)
    begin
        InitializeXml(TempBlob, DefaultNamespacePrefixTxt, Namespace);
    end;

    procedure InitializeXml(TempBlob: Codeunit "Temp Blob"; Prefix: Text; Namespace: Text)
    var
        XmlInStream: InStream;
    begin
        if TempBlob.HasValue() then begin
            TempBlob.CreateInStream(XmlInStream);
            InitializeXml(XmlInStream, Prefix, Namespace);
        end;
    end;

    local procedure InitializeXmlNamespaceManager(Prefix: Text; Namespace: Text)
    begin
        XmlNamespaceManagerNative.NameTable(XmlDocumentNative.NameTable);
        XmlNamespaceManagerNative.AddNamespace(Prefix, Namespace);
    end;

    procedure GetElementValue(ElementName: Text): Text
    begin
        GetNodeByElementName(ElementName, XMLNode);
        exit(XMLNode.Value);
    end;

    procedure GetXmlElementValue(ElementName: Text): Text
    begin
        XmlDocumentNative.SelectSingleNode(ElementName, XmlNamespaceManagerNative, XmlNodeNative);
        exit(XmlNodeNative.AsXmlElement().InnerText())
    end;

    procedure VerifyNodeAbsence(ElementName: Text)
    var
        Node: DotNet XmlNode;
    begin
        asserterror GetNodeByElementName(ElementName, Node);
        Assert.ExpectedError('Element is missing!');
    end;

    procedure VerifyNodeAbsenceInSubtree(ParentNodeXPath: Text; NodeName: Text)
    var
        ParentNode: XmlNode;
        ChildNode: XmlNode;
        NodeXPath: Text;
        ParentNodeFound: Boolean;
        ChildNodeFound: Boolean;
    begin
        ParentNodeXPath := AddPrefixToXPath(ParentNodeXPath, DefaultNamespacePrefixTxt);
        NodeXPath := AddPrefixToXPath(NodeName, DefaultNamespacePrefixTxt);

        ParentNodeFound := XmlDocumentNative.SelectSingleNode(ParentNodeXPath, XmlNamespaceManagerNative, ParentNode);
        Assert.IsTrue(ParentNodeFound, StrSubstNo(NodeNotFoundErr, ParentNodeXPath));

        ChildNodeFound := ParentNode.SelectSingleNode(NodeXPath, XmlNamespaceManagerNative, ChildNode);
        Assert.IsFalse(ChildNodeFound, StrSubstNo(NodeShouldNotExistInSubtreeErr, NodeName));
    end;

    procedure VerifyNodeValue(ElementName: Text; Expected: Text)
    var
        Actual: Text;
    begin
        GetNodeByElementName(ElementName, XMLNode);
        Actual := XMLNode.InnerText;
        Assert.AreEqual(Expected, Actual,
          StrSubstNo('Unexpected value in xml file for element <%1>', ElementName));
    end;

    procedure VerifyAttributeAbsence(ElementName: Text; AttributeName: Text)
    var
        Attribute: DotNet XmlAttribute;
    begin
        GetAttributeFromElement(ElementName, AttributeName, Attribute);
        Assert.IsTrue(IsNull(Attribute), StrSubstNo(UnexpectedAttributeErr, AttributeName, ElementName));
    end;

    procedure VerifyAttributeValue(ElementName: Text; AttributeName: Text; Expected: Text)
    var
        Attribute: DotNet XmlAttribute;
        Actual: Text;
    begin
        GetAttributeFromElement(ElementName, AttributeName, Attribute);
        Actual := Attribute.Value();
        Assert.AreEqual(Expected, Actual,
          StrSubstNo('Unexpected value in xml file for Attribute <%1>', AttributeName));
    end;

    procedure VerifyAttributeValueByNodeIndex(ElementName: Text; AttributeName: Text; Expected: Text; Index: Integer)
    var
        Attribute: DotNet XmlAttribute;
        Actual: Text;
    begin
        GetAttributeFromElementByIndex(ElementName, AttributeName, Attribute, Index);
        Actual := Attribute.Value();
        Assert.AreEqual(Expected, Actual,
          StrSubstNo('Unexpected value in xml file for Attribute <%1>', AttributeName));
    end;

    [Scope('OnPrem')]
    procedure GetNodeListByElementName(ElementName: Text; var NodeList: DotNet XmlNodeList): Integer
    begin
        GetNodeList(ElementName, NodeList);
        if NodeList.Count = 0 then
            Assert.Fail('Element is missing! ' + ElementName);
        exit(NodeList.Count);
    end;

    [Scope('OnPrem')]
    procedure GetAttributeFromElement(ElementName: Text; AttributeName: Text; var Attribute: DotNet XmlAttribute)
    var
        Node: DotNet XmlNode;
    begin
        GetNodeByElementName(ElementName, Node);
        if Node.Attributes.Count = 0 then
            Assert.Fail('Attribute is missing! ' + ElementName);
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
    end;

    [Scope('OnPrem')]
    procedure GetAttributeFromElementByIndex(ElementName: Text; AttributeName: Text; var Attribute: DotNet XmlAttribute; Index: Integer)
    var
        Node: DotNet XmlNode;
    begin
        GetNodeByElementNameByIndex(ElementName, Node, Index);
        if Node.Attributes.Count = 0 then
            Assert.Fail('Attribute is missing! ' + ElementName);
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
    end;

    [Scope('OnPrem')]
    procedure GetRootAttributeValue(AttributeName: Text): Text
    var
        Attribute: DotNet XmlAttribute;
    begin
        Attribute := XMLDocOut.DocumentElement.Attributes.GetNamedItem(AttributeName);
        exit(Attribute.Value);
    end;

    [Scope('OnPrem')]
    procedure GetNodeByXPath(xPath: Text; var Node: DotNet XmlNode)
    var
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeList(xPath, NodeList);
        Assert.AreNotEqual(0, NodeList.Count, StrSubstNo(NodeNotFoundErr, xPath));
        Node := NodeList.Item(0);
    end;

    [Scope('OnPrem')]
    procedure GetNodeByElementName(ElementName: Text; var Node: DotNet XmlNode)
    var
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeListByElementName(ElementName, NodeList);
        Node := NodeList.Item(0);
    end;

    [Scope('OnPrem')]
    procedure GetNodeByElementNameByIndex(ElementName: Text; var Node: DotNet XmlNode; Index: Integer)
    var
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeListByElementName(ElementName, NodeList);
        if (Index < 0) or (Index >= NodeList.Count) then
            Error(NodeIndexOutOfBoundsErr, ElementName, Index, NodeList.Count);
        Node := NodeList.Item(Index);
    end;

    [Scope('OnPrem')]
    procedure GetElementInCurrNode(CurrNode: DotNet XmlNode; ElementName: Text; var ElementNode: DotNet XmlNode)
    begin
        ElementNode := CurrNode.SelectSingleNode(ElementName, XMLNsMgr);
    end;

    [Scope('OnPrem')]
    procedure GetElementValueInCurrNode(CurrNode: DotNet XmlNode; ElementName: Text): Text
    var
        Node: DotNet XmlNode;
    begin
        GetElementInCurrNode(CurrNode, ElementName, Node);
        exit(Node.InnerText);
    end;

    [Scope('OnPrem')]
    procedure GetNodeList(xPath: Text; var nodeList: DotNet XmlNodeList)
    begin
        if SkipDefaultNamespace then
            nodeList := XMLDocOut.DocumentElement.SelectNodes(xPath, XMLNsMgr)
        else
            nodeList := XMLDocOut.DocumentElement.SelectNodes(Replace(xPath, '/', '/ns:'), XMLNsMgr);
    end;

    [Scope('OnPrem')]
    procedure GetNodeListInCurrNode(CurrNode: DotNet XmlNode; xPath: Text; var nodeList: DotNet XmlNodeList)
    begin
        if SkipDefaultNamespace then
            nodeList := CurrNode.SelectNodes(xPath, XMLNsMgr)
        else
            nodeList := CurrNode.SelectNodes(Replace(xPath, '/', '/ns:'), XMLNsMgr);
    end;

    [Scope('OnPrem')]
    procedure GetAttributeValueFromNode(Node: DotNet XmlNode; AttributeName: Text): Text
    var
        Attribute: DotNet XmlAttribute;
        Actual: Text;
    begin
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
        Assert.IsFalse(IsNull(Attribute), StrSubstNo(MissingAttributeErr, AttributeName, Node.Name));
        Actual := Attribute.Value();
        exit(Actual);
    end;

    [Scope('OnPrem')]
    procedure GetNodeInnerTextByXPathWithIndex(xPath: Text; Index: Integer): Text
    var
        NodeList: DotNet XmlNodeList;
        Node: DotNet XmlNode;
    begin
        GetNodeList(xPath, NodeList);
        Assert.AreNotEqual(0, NodeList.Count, StrSubstNo(NodeNotFoundErr, xPath));
        Node := NodeList.Item(Index);
        exit(Node.InnerText);
    end;

    [Scope('OnPrem')]
    procedure GetNodeIndexInSubtree(RootNodeName: Text; NodeName: Text) Index: Integer
    var
        Node: DotNet XmlNode;
        Enumerator: DotNet IEnumerator;
        OtherNode: DotNet XmlNode;
    begin
        // If multiple nodes with the same name exist in the subtree, the index of the first one will be returned.
        GetNodeByElementName(RootNodeName, Node);
        Enumerator := Node.GetEnumerator();

        while Enumerator.MoveNext() do begin
            OtherNode := Enumerator.Current;
            if OtherNode.Name = NodeName then
                exit(Index);
            Index += 1;
        end;
        Index := -1;
    end;

    procedure CompareTextWithInteger(TextValue: Text; ExpectedValue: Integer)
    var
        Value: Integer;
    begin
        if Evaluate(Value, TextValue) then
            if Value = ExpectedValue then
                exit;

        Error(UnexpectedValueErr, ExpectedValue, TextValue);
    end;

    procedure VerifyNodeCountByXPath(xPath: Text; NodeCount: Integer)
    var
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeList(xPath, NodeList);
        Assert.AreEqual(NodeCount, NodeList.Count, StrSubstNo(NodeCountErr, xPath));
    end;

    procedure VerifyNodeCountWithValueByXPath(xPath: Text; Value: Text; NodeCount: Integer)
    var
        NodeList: DotNet XmlNodeList;
        ActualNodeCount: Integer;
        i: Integer;
    begin
        GetNodeList(xPath, NodeList);
        ActualNodeCount := 0;
        for i := 0 to NodeList.Count - 1 do
            if DelChr(NodeList.Item(i).InnerText, '<>', ' ') = Value then
                ActualNodeCount += 1;
        Assert.AreEqual(NodeCount, ActualNodeCount, StrSubstNo(NodeCountWithValueErr, Value, xPath));
    end;

    procedure VerifyNodeValueByXPath(xPath: Text; NodeValue: Text)
    begin
        VerifyNodeValueByXPathWithIndex(xPath, NodeValue, 0);
    end;

    procedure VerifyNodeValueByXPathWithIndex(xPath: Text; NodeValue: Text; Index: Integer)
    var
        NodeList: DotNet XmlNodeList;
        Node: DotNet XmlNode;
        ActualNodeValue: Text;
        NodeCount: Integer;
    begin
        GetNodeList(xPath, NodeList);
        NodeCount := NodeList.Count();
        Assert.AreNotEqual(0, NodeCount, StrSubstNo(NodeNotFoundErr, xPath));
        Node := NodeList.Item(Index);
        if IsNull(Node) then
            Assert.Fail(StrSubstNo('Node is not found by path: %1, index: %2, value: %3', xPath, Index, NodeValue));
        ActualNodeValue := Node.InnerText;
        Assert.AreEqual(NodeValue, ActualNodeValue, StrSubstNo(UnexpectedNodeValueErr, xPath, NodeValue, ActualNodeValue));
    end;

    [Scope('OnPrem')]
    procedure VerifyAttributeFromNode(Node: DotNet XmlNode; AttributeName: Text; AttributeExpectedValue: Text)
    var
        Actual: Text;
    begin
        Actual := GetAttributeValueFromNode(Node, AttributeName);
        Assert.AreEqual(AttributeExpectedValue, Actual, StrSubstNo(UnexpectedAttributeValueErr, AttributeName));
    end;

    [Scope('OnPrem')]
    procedure VerityAttributeFromRootNode(AttributeName: Text; AttributeExpectedValue: Text)
    var
        Actual: Text;
    begin
        Actual := GetRootAttributeValue(AttributeName);
        Assert.AreEqual(AttributeExpectedValue, Actual, StrSubstNo(UnexpectedAttributeValueErr, AttributeName));
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeValueFromParentNode(ParentXmlNode: DotNet XmlNode; ElementName: Text; ExpectedValue: Text)
    var
        ChildXmlNode: DotNet XmlNode;
        Actual: Text;
    begin
        GetElementInCurrNode(ParentXmlNode, ElementName, ChildXmlNode);
        Assert.IsFalse(IsNull(ChildXmlNode), StrSubstNo(NodeNotFoundErr, ElementName));
        Actual := ChildXmlNode.InnerText;
        Assert.AreEqual(ExpectedValue, Actual, StrSubstNo(UnexpectedNodeValueErr, ElementName, ExpectedValue, Actual));
    end;

    [Scope('OnPrem')]
    procedure VerifyOptionalAttributeFromNode(Node: DotNet XmlNode; AttributeName: Text; AttributeExpectedValue: Text)
    var
        AttributeActualValue: Text;
        AttributeValueDecimal: Decimal;
        IsNumber: Boolean;
    begin
        if Evaluate(AttributeValueDecimal, AttributeExpectedValue) then
            IsNumber := true;

        if (IsNumber and (AttributeValueDecimal = 0)) or (AttributeExpectedValue = '') then
            VerifyAttributeAbsenceFromNode(Node, AttributeName)
        else begin
            AttributeActualValue := GetAttributeValueFromNode(Node, AttributeName);
            Assert.AreEqual(AttributeExpectedValue, AttributeActualValue, StrSubstNo(UnexpectedAttributeValueErr, AttributeName));
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyAttributeAbsenceFromNode(Node: DotNet XmlNode; AttributeName: Text)
    var
        Attribute: DotNet XmlAttribute;
    begin
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
        Assert.IsTrue(IsNull(Attribute), StrSubstNo(UnexpectedAttributeErr, AttributeName, Node.Name));
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeValueIsGuid(ElementName: Text)
    var
        Actual: Text;
        InstrId: Guid;
    begin
        GetNodeByElementName(ElementName, XMLNode);
        Actual := XMLNode.InnerText;
        Assert.AreNotEqual('', Actual,
          StrSubstNo('Unexpected empty value in xml file for element <%1>', ElementName));
        Assert.IsTrue(Evaluate(InstrId, Actual),
          StrSubstNo('Unexpected value type in xml file for element <%1>. Expecting GUID.', ElementName));
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLDeclaration(Version: Text; Encoding: Text; Standalone: Text)
    var
        XMLDeclaration: DotNet XmlDeclaration;
    begin
        XMLDeclaration := XMLDocOut.FirstChild;
        Assert.AreEqual(Version, XMLDeclaration.Version, DeclarationVersionErr);
        Assert.AreEqual(Encoding, XMLDeclaration.Encoding, DeclarationEncodingErr);
        Assert.AreEqual(Standalone, XMLDeclaration.Standalone, DeclarationStandaloneErr);
    end;

    local procedure Replace(SourceText: Text; FindText: Text; ReplaceText: Text): Text
    var
        NewText: Text;
        pos: Integer;
    begin
        while StrPos(SourceText, FindText) > 0 do begin
            pos := StrPos(SourceText, FindText);
            if (SourceText[pos + 1] <> '@') and (SourceText[pos + 1] <> '/') then
                NewText := NewText + CopyStr(SourceText, 1, StrPos(SourceText, FindText) - 1) + ReplaceText
            else
                NewText := NewText + CopyStr(SourceText, 1, StrPos(SourceText, FindText));
            SourceText := DelStr(SourceText, 1, StrPos(SourceText, FindText));
        end;

        exit(NewText + SourceText);
    end;

    procedure SetDefaultNamespaceUsage(UseDefaultNamespace: Boolean)
    begin
        SkipDefaultNamespace := not UseDefaultNamespace;
    end;

    procedure AddAdditionalNamespace(Prefix: Text; Namespace: Text)
    begin
        XMLNsMgr.AddNamespace(Prefix, Namespace);
    end;

    local procedure AddPrefixToXPath(XPath: Text; Prefix: Text): Text
    var
        TB: TextBuilder;
        PrevChar: Char;
        CurrChar: Char;
    begin
        if IsLatinLetter(XPath[1]) then
            PrevChar := '/';        // to add prefix before the first element

        foreach CurrChar in XPath do begin
            if PrevChar = '/' then
                if IsLatinLetter(CurrChar) then begin
                    TB.Append(Prefix);
                    TB.Append(':');
                end;
            TB.Append(CurrChar);
            PrevChar := CurrChar;
        end;

        exit(TB.ToText());
    end;

    local procedure IsLatinLetter(ch: Char): Boolean
    begin
        exit(((ch >= 'A') and (ch <= 'Z')) or ((ch >= 'a') and (ch <= 'z')));
    end;
}

