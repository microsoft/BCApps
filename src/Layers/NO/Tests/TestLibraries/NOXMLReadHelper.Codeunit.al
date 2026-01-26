codeunit 143001 "NO XML Read Helper"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        XMLDocOut: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        XMLNsMgr: DotNet XmlNamespaceManager;
        MissingAttributeErr: Label '%1 attribute is missing from the node %2.';
        MissingElementErr: Label 'The element %1 is missing.';
        MissingCurrNodeErr: Label 'Cannot GetElementInCurrNode because CurrNode is NULL.';
        NodeNotFoundErr: Label 'The selected node %1 was not found.';
        SubNodeNotFoundErr: Label 'Requested subnode %1 of node %2 was not found in the E-Invoice file.';
        UnexpectedAttributeValueErr: Label 'Unexpected attribute %1 value.';
        UnexpectedAttributeErr: Label 'Unepexted %1 attribute in the node %2.';
        UnexpectedNodeErr: Label 'Node %1 should not exist.';
        UnexpectedNodeValueErr: Label 'Unexpected node %1 value. Expected: %2, actual %3.';
        UnexpectedSubnodeValueErr: Label 'Unexpected value in parent node %1, subnode %2. Expected: %3, actual %4.';
        UnexpectedValueErr: Label 'Unexpected value!. Expected: %1''. In XML file: %2.';
        WrongValueErr: Label 'Element does not contain the value %1.';

    [Scope('OnPrem')]
    procedure Initialize(FullFilePath: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(FullFilePath, XMLDocOut);

        XMLNsMgr := XMLNsMgr.XmlNamespaceManager(XMLDocOut.NameTable);
        XMLNsMgr.AddNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        XMLNsMgr.AddNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
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
        Assert.ExpectedError(StrSubstNo(MissingElementErr, ElementName));
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeAbsenceByXPath(xPath: Text)
    var
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeList(xPath, NodeList);
        Assert.AreEqual(0, NodeList.Count, StrSubstNo(UnexpectedNodeErr, xPath));
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
    procedure VerifyNextNodeValue(ElementName: Text; Expected: Text; NodeNo: Integer)
    var
        Actual: Text;
    begin
        GetNextNodeByElementName(ElementName, XMLNode, NodeNo);
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
    procedure VerifyNodeExists(xPath: Text): Boolean
    var
        NodeList: DotNet XmlNodeList;
    begin
        if xPath <> ' ' then begin
            GetNodeList(xPath, NodeList);
            if NodeList.Count > 0 then
                exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeContainsValue(ElementName: Text; Value: Text)
    begin
        GetNodeByElementName(ElementName, XMLNode);
        Assert.IsTrue(
          StrPos(XMLNode.InnerText, Value) > 0, StrSubstNo(WrongValueErr, Value));
    end;

    [Scope('OnPrem')]
    procedure GetNodeListByElementName(ElementName: Text; var NodeList: DotNet XmlNodeList): Integer
    begin
        GetNodeList(ElementName, NodeList);
        if NodeList.Count = 0 then
            Error(MissingElementErr, ElementName);
        exit(NodeList.Count);
    end;

    [Scope('OnPrem')]
    procedure GetAttributeFromElement(ElementName: Text; AttributeName: Text; var Attribute: DotNet XmlAttribute)
    var
        Node: DotNet XmlNode;
    begin
        GetNodeByElementName(ElementName, Node);
        if Node.Attributes.Count = 0 then
            Error(MissingAttributeErr, AttributeName, ElementName);
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
    end;

    [Scope('OnPrem')]
    procedure GetNodeByXPath(xPath: Text; var Node: DotNet XmlNode)
    var
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeList(xPath, NodeList);
        Assert.AreEqual(NodeList.Count, 1, StrSubstNo(NodeNotFoundErr, xPath));
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
    procedure GetNextNodeByElementName(ElementName: Text; var Node: DotNet XmlNode; ItemNo: Integer)
    var
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeListByElementName(ElementName, NodeList);
        Assert.IsTrue(ItemNo >= 0, '');
        Assert.IsTrue(NodeList.Count > ItemNo, 'Node count is wrong');
        Node := NodeList.Item(ItemNo);
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
        if IsNull(CurrNode) then
            Error(MissingCurrNodeErr);

        GetElementInCurrNode(CurrNode, ElementName, Node);

        if IsNull(Node) then
            Error(SubNodeNotFoundErr, ElementName, CurrNode.Name);

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

        Error(UnexpectedValueErr, ExpectedValue, TextValue);
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
        Assert.AreEqual(NodeCount, 1, StrSubstNo(NodeNotFoundErr, xPath));
        Node := NodeList.Item(0);
        ActualNodeValue := Node.InnerText;

        Assert.AreEqual(NodeValue, ActualNodeValue, StrSubstNo(UnexpectedNodeValueErr, xPath, NodeValue, ActualNodeValue));
    end;

    [Scope('OnPrem')]
    procedure VerifyAttributeFromNode(Node: DotNet XmlNode; AttributeName: Text; AttributeExpectedValue: Text)
    var
        Attribute: DotNet XmlAttribute;
        Actual: Text;
    begin
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
        Assert.IsFalse(IsNull(Attribute), StrSubstNo(MissingAttributeErr, AttributeName, Node.Name));
        Actual := Attribute.Value();
        Assert.AreEqual(AttributeExpectedValue, Actual, StrSubstNo(UnexpectedAttributeValueErr, AttributeName));
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
    procedure VerifySubnodeValueInCurrNode(ParentNode: DotNet XmlNode; SubnodeName: Text; ExpectedSubnodeValue: Text)
    var
        Subnode: DotNet XmlNode;
        ActualSubnodeValue: Text;
    begin
        Subnode := ParentNode.SelectSingleNode(SubnodeName, XMLNsMgr);
        if ExpectedSubnodeValue = '' then begin
            Assert.IsTrue(IsNull(Subnode), StrSubstNo(UnexpectedNodeErr, SubnodeName));
            exit;
        end;
        ActualSubnodeValue := Subnode.InnerText;
        Assert.AreEqual(
          ExpectedSubnodeValue, ActualSubnodeValue,
          StrSubstNo(UnexpectedSubnodeValueErr, ParentNode.Name, SubnodeName, ExpectedSubnodeValue, ActualSubnodeValue));
    end;

    [Scope('OnPrem')]
    procedure VerifySubnodeValueInParentNode(ParentNodeXPath: Text; SubnodeName: Text; ExpectedSubnodeValue: Text)
    var
        ParentNode: DotNet XmlNode;
    begin
        GetNodeByXPath(ParentNodeXPath, ParentNode);
        VerifySubnodeValueInCurrNode(ParentNode, SubnodeName, ExpectedSubnodeValue);
    end;
}

