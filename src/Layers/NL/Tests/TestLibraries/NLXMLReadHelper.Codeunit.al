codeunit 143001 "NL XML Read Helper"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        XMLDocOut: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        XMLNsMgr: DotNet XmlNamespaceManager;
        UnexpectedValue: Label 'Unexpected value!. Expected: %1''. In XML file: %2.';
        NodeCountErr: Label 'Count is wrong. Node: %1';
        NodeCountWithValueErr: Label 'Count is wrong for value %1 in nodes %2';
        NodeNotFoundError: Label 'The selected node %1 was not found.';
        UnexpectedNodeValue: Label 'Unexpected node %1 value. Expected: %2, actual %3.';
        MissingAttributeError: Label '%1 attribute is missing from the node %2.';
        UnexpectedAttributeValue: Label 'Unexpected attribute %1 value.';
        UnexpectedAttributeError: Label 'Unepexted %1 attribute in the node %2.';

    [Scope('OnPrem')]
    procedure Initialize(FullFilePath: Text; NameSpace: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDocElement: DotNet XmlElement;
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(FullFilePath, XMLDocOut);

        XMLNsMgr := XMLNsMgr.XmlNamespaceManager(XMLDocOut.NameTable);
        XMLNsMgr.AddNamespace('ns', NameSpace);

        XMLDocElement := XMLDocOut.DocumentElement;
        XMLNsMgr.AddNamespace('xsi', XMLDocElement.GetNamespaceOfPrefix('xsi'));
    end;

    [Scope('OnPrem')]
    procedure GetElementValue(ElementName: Text): Text
    begin
        GetNodeByElementName(ElementName, XMLNode);
        exit(XMLNode.Value);
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeAbsence(ElementName: Text)
    var
        Node: DotNet XmlNode;
    begin
        asserterror GetNodeByElementName(ElementName, Node);
        Assert.ExpectedError('Element is missing!');
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeValue(ElementName: Text; Expected: Text)
    var
        Actual: Text;
    begin
        GetNodeByElementName(ElementName, XMLNode);
        Actual := XMLNode.InnerText;
        Assert.AreEqual(Expected, Actual,
          StrSubstNo('Unexpected value in xml file for element <%1>', ElementName));
    end;

    [Scope('OnPrem')]
    procedure VerifyAttributeAbsence(ElementName: Text; AttributeName: Text)
    var
        Attribute: DotNet XmlAttribute;
    begin
        asserterror GetAttributeFromElement(ElementName, AttributeName, Attribute);
        Assert.ExpectedError('Attribute is missing!');
    end;

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
    procedure VerifyExists(ElementName: Text; Value: Text): Boolean
    var
        NodeList: DotNet XmlNodeList;
        i: Integer;
    begin
        NodeList := XMLDocOut.GetElementsByTagName(ElementName);

        for i := 0 to NodeList.Count - 1 do
            if NodeList.Item(i).Value = Value then
                exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetNodeListByElementName(ElementName: Text; var NodeList: DotNet XmlNodeList): Integer
    begin
        GetNodeList(ElementName, NodeList);
        if NodeList.Count = 0 then
            Error('Element is missing! ' + ElementName);
        exit(NodeList.Count);
    end;

    [Scope('OnPrem')]
    procedure GetAttributeFromElement(ElementName: Text; AttributeName: Text; var Attribute: DotNet XmlAttribute)
    var
        Node: DotNet XmlNode;
    begin
        GetNodeByElementName(ElementName, Node);
        if Node.Attributes.Count = 0 then
            Error('Attribute is missing! ' + ElementName);
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
    end;

    [Scope('OnPrem')]
    procedure GetNodeByXPath(xPath: Text; var Node: DotNet XmlNode)
    var
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeList(xPath, NodeList);
        Assert.AreNotEqual(0, NodeList.Count, StrSubstNo(NodeNotFoundError, xPath));
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
        nodeList := XMLDocOut.DocumentElement.SelectNodes(xPath, XMLNsMgr);
    end;

    [Scope('OnPrem')]
    procedure CompareTextWithInteger(TextValue: Text; ExpectedValue: Integer)
    var
        Value: Integer;
    begin
        if Evaluate(Value, TextValue) then
            if Value = ExpectedValue then
                exit;

        Error(UnexpectedValue, ExpectedValue, TextValue);
    end;

    [Scope('OnPrem')]
    procedure LookupNamespace(prefix: Text): Text
    begin
        exit(XMLNsMgr.LookupNamespace(prefix));
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeCountByXPath(xPath: Text; NodeCount: Integer)
    var
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeList(xPath, NodeList);
        Assert.AreEqual(NodeCount, NodeList.Count, StrSubstNo(NodeCountErr, xPath));
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeCountWithValueByXPath(xPath: Text; Value: Text; NodeCount: Integer)
    var
        NodeList: DotNet XmlNodeList;
        ActualNodeCount: Integer;
        i: Integer;
    begin
        GetNodeList(xPath, NodeList);
        ActualNodeCount := 0;
        for i := 0 to NodeList.Count - 1 do
            if NodeList.Item(i).InnerText = Value then
                ActualNodeCount += 1;
        Assert.AreEqual(NodeCount, ActualNodeCount, StrSubstNo(NodeCountWithValueErr, Value, xPath));
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeValueByXPath(xPath: Text; NodeValue: Text)
    var
        NodeList: DotNet XmlNodeList;
        Node: DotNet XmlNode;
        ActualNodeValue: Text;
        NodeCount: Integer;
    begin
        GetNodeList(xPath, NodeList);
        NodeCount := NodeList.Count();
        Assert.AreNotEqual(0, NodeCount, StrSubstNo(NodeNotFoundError, xPath));
        Node := NodeList.Item(0);
        ActualNodeValue := Node.InnerText;
        Assert.AreEqual(NodeValue, ActualNodeValue, StrSubstNo(UnexpectedNodeValue, xPath, NodeValue, ActualNodeValue));
    end;

    [Scope('OnPrem')]
    procedure VerifyAttributeFromNode(Node: DotNet XmlNode; AttributeName: Text; AttributeExpectedValue: Text)
    var
        Attribute: DotNet XmlAttribute;
        Actual: Text;
    begin
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
        Assert.IsFalse(IsNull(Attribute), StrSubstNo(MissingAttributeError, AttributeName, Node.Name));
        Actual := Attribute.Value();
        Assert.AreEqual(AttributeExpectedValue, Actual, StrSubstNo(UnexpectedAttributeValue, AttributeName));
    end;

    [Scope('OnPrem')]
    procedure VerifyAttributeAbsenceFromNode(Node: DotNet XmlNode; AttributeName: Text)
    var
        Attribute: DotNet XmlAttribute;
    begin
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
        Assert.IsTrue(IsNull(Attribute), StrSubstNo(UnexpectedAttributeError, AttributeName, Node.Name));
    end;
}

