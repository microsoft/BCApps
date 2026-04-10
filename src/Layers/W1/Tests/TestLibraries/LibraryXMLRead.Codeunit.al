codeunit 131335 "Library - XML Read"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        [RunOnClient]
        XMLDocOut: DotNet XmlDocument;
        NodeMatchCriteria: Option FindByName,FindByNameAndValue;
        AttributeNodeValueErr: Label 'Wrong value for attribute <%1> of node <%2> in subtree <%3>.';
        AttributeNotFoundErr: Label 'Node <%1> in subtree <%2> has no attributes with value <%3>.';
        AttributeValueErr: Label 'Unexpected value in xml file for Attribute <%1>.';
        AttributeExistsErr: Label 'Attribute %1 exists.', Comment = '%1 = attribute name';
        CountErr: Label 'Incorrect count for <%1>.';
        DeclarationEncodingErr: Label 'XMLDeclaration: Wrong Encoding property.';
        DeclarationStandaloneErr: Label 'XMLDeclaration: Wrong Standalone property.';
        DeclarationVersionErr: Label 'XMLDeclaration: Wrong Version property.';
        ElementValueErr: Label 'Unexpected value in xml file for Element <%1>.';
        IncorrectUseOfFunctionErr: Label 'Incorrect use of function.';
        MissingElementErr: Label 'Element <%1> is missing.';
        MissingNodeErr: Label 'Node <%1> is missing.';
        NodeHasNoAttributesErr: Label 'Node <%1> in subtree <%2> has no attributes.';
        NotFoundAnyInSubtreeErr: Label 'Node <%1> was not found in subtree <%2>.';
        NotFoundInSubtreeErr: Label 'Node <%1> with value <%2> was not found in subtree <%3>.';
        NodeIndexOutOfBoundsErr: Label 'Node <%1> index %2  is out of bounds (%3 total nodes exist).';

    procedure Initialize(FullFilePath: Text)
    begin
        Clear(XMLDocOut);
        XMLDocOut := XMLDocOut.XmlDocument();
        // TFS 379960 - We keep XmlDocument.Load, because the library intended to be ran on client
        XMLDocOut.Load(FullFilePath);
    end;

    procedure InitializeFromXmlText(XmlText: Text)
    begin
        CLEAR(XMLDocOut);
        XMLDocOut := XMLDocOut.XmlDocument();
        XMLDocOut.LoadXml(XmlText);
    end;

    procedure InitializeFromStream(XmlStream: InStream)
    begin
        CLEAR(XMLDocOut);
        XMLDocOut := XMLDocOut.XmlDocument();
        XMLDocOut.Load(XmlStream);
    end;

    local procedure Equal(ExpectedValue: Variant; ActualValue: Text): Boolean
    var
        ActualDateValue: Date;
        ActualDecimalValue: Decimal;
    begin
        if IsDate(ExpectedValue) then begin
            if not Evaluate(ActualDateValue, ActualValue, 9) then
                exit(false);
            exit(EqualDates(ExpectedValue, ActualDateValue));
        end;

        if IsNumber(ExpectedValue) then begin
            if not Evaluate(ActualDecimalValue, ActualValue, 9) then
                exit(false);
            exit(EqualNumbers(ExpectedValue, ActualDecimalValue));
        end;

        exit(Format(ExpectedValue, 0, 9) = ActualValue);
    end;

    local procedure EqualDates(Left: Date; Right: Date): Boolean
    begin
        exit(Left = Right)
    end;

    local procedure EqualNumbers(Left: Decimal; Right: Decimal): Boolean
    begin
        exit(Left = Right)
    end;

    procedure GetAttributeValueInSubtree(RootNodeName: Text; NodeName: Text; AttributeName: Text): Text
    var
        [RunOnClient]
        Node: DotNet XmlNode;
        [RunOnClient]
        AttributeCollection: DotNet XmlAttributeCollection;
        [RunOnClient]
        Attribute: DotNet XmlAttribute;
    begin
        LocateNodeInSubtree(Node, RootNodeName, NodeName, '', NodeMatchCriteria::FindByName);

        AttributeCollection := Node.Attributes;
        if IsNull(AttributeCollection) then
            Assert.Fail(StrSubstNo(NodeHasNoAttributesErr, NodeName, RootNodeName));

        Attribute := AttributeCollection.ItemOf(AttributeName);
        if IsNull(Attribute) then
            Assert.Fail(StrSubstNo(AttributeNotFoundErr, NodeName, RootNodeName, AttributeName));

        exit(Attribute.Value);
    end;

    procedure GetElementValue(ElementName: Text): Text[1024]
    var
        [RunOnClient]
        XMLNode: DotNet XmlNode;
    begin
        GetNodeByElementName(ElementName, XMLNode);
        exit(CopyStr(XMLNode.InnerText, 1, 1024));
    end;

    procedure GetNodesCount(NodeName: Text): Integer
    var
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
    begin
        exit(GetNodeListByElementName(NodeName, NodeList));
    end;

    procedure GetNodeValueAtIndex(NodeName: Text; Index: Integer): Text[1024]
    var
        [RunOnClient]
        XMLNode: DotNet XmlNode;
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
        NodesCount: Integer;
    begin
        NodesCount := GetNodeListByElementName(NodeName, NodeList);
        if (Index < 0) or (Index >= NodesCount) then
            Error(NodeIndexOutOfBoundsErr, NodeName, Index, NodesCount);
        XMLNode := NodeList.Item(Index);
        exit(CopyStr(XMLNode.InnerText, 1, 1024));
    end;

    procedure GetNodeValueInSubtree(RootNodeName: Text; NodeName: Text): Text
    var
        [RunOnClient]
        Node: DotNet XmlNode;
    begin
        LocateNodeInSubtree(Node, RootNodeName, NodeName, '', NodeMatchCriteria::FindByName);
        exit(Node.InnerText);
    end;

    local procedure IsDate(Value: Variant): Boolean
    begin
        exit(Value.IsDate);
    end;

    local procedure IsNumber(Value: Variant): Boolean
    begin
        exit(Value.IsDecimal or Value.IsInteger or Value.IsChar)
    end;

    [Scope('OnPrem')]
    procedure LocateNodeInSubtree(var Node: DotNet XmlNode; RootNodeName: Text; NodeName: Text; ExpectedNodeValue: Variant; MatchCriteria: Option)
    var
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
        NodeCount: Integer;
        Index: Integer;
        Found: Boolean;
    begin
        // If multiple nodes with the same name exist in the subtree, only the first one encountered will be verified.
        if (MatchCriteria = NodeMatchCriteria::FindByNameAndValue) and Equal(ExpectedNodeValue, '') then
            Error(IncorrectUseOfFunctionErr);
        if not (MatchCriteria in [NodeMatchCriteria::FindByName, NodeMatchCriteria::FindByNameAndValue]) then
            Error(IncorrectUseOfFunctionErr);

        NodeCount := GetNodeListByElementName(NodeName, NodeList);

        if NodeCount < 1 then
            Assert.Fail(StrSubstNo(MissingNodeErr, NodeName));

        Index := 0;
        Found := false;
        repeat
            Node := NodeList.Item(Index);
            if HasIndirectParent(Node, RootNodeName) and
               ((MatchCriteria = NodeMatchCriteria::FindByName) or Equal(ExpectedNodeValue, Node.InnerText))
            then
                Found := true
            else
                Index += 1;
        until (Found or (Index = NodeCount));

        if not Found then
            if MatchCriteria = NodeMatchCriteria::FindByName then
                Assert.Fail(StrSubstNo(NotFoundAnyInSubtreeErr, NodeName, RootNodeName))
            else
                Assert.Fail(StrSubstNo(NotFoundInSubtreeErr, NodeName, ExpectedNodeValue, RootNodeName));
    end;

    procedure VerifyNodeValue(ElementName: Text; Expected: Variant)
    var
        [RunOnClient]
        XMLNode: DotNet XmlNode;
    begin
        GetNodeByElementName(ElementName, XMLNode);
        Assert.AreEqual(Format(Expected, 0, 9), XMLNode.InnerText,
          StrSubstNo(ElementValueErr, ElementName));
    end;

    procedure VerifyNodeValueInSubtree(RootNodeName: Text; NodeName: Text; ExpectedNodeValue: Variant)
    var
        [RunOnClient]
        Node: DotNet XmlNode;
    begin
        LocateNodeInSubtree(Node, RootNodeName, NodeName, ExpectedNodeValue, NodeMatchCriteria::FindByNameAndValue);
    end;

    procedure VerifyNodeAbsence(NodeName: Text)
    var
        [RunOnClient]
        XMLNode: DotNet XmlNode;
    begin
        asserterror GetNodeByElementName(NodeName, XMLNode);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(MissingElementErr, NodeName));
    end;

    procedure VerifyNodeAbsenceInSubtree(RootNodeName: Text; NodeName: Text)
    var
        [RunOnClient]
        Node: DotNet XmlNode;
    begin
        asserterror LocateNodeInSubtree(Node, RootNodeName, NodeName, '', NodeMatchCriteria::FindByName);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(NotFoundAnyInSubtreeErr, NodeName, RootNodeName));
    end;

    procedure VerifyElementAbsenceInSubtree(RootNodeName: Text; NodeName: Text)
    var
        [RunOnClient]
        Node: DotNet XmlNode;
    begin
        asserterror LocateNodeInSubtree(Node, RootNodeName, NodeName, '', NodeMatchCriteria::FindByName);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(MissingElementErr, NodeName));
    end;

    procedure VerifyAttributeValue(ElementName: Text; AttributeName: Text; Expected: Variant)
    var
        [RunOnClient]
        Attribute: DotNet XmlAttribute;
    begin
        GetAttributeFromElement(ElementName, AttributeName, Attribute);
        Assert.AreEqual(Format(Expected, 0, 9), Attribute.Value,
          StrSubstNo(AttributeValueErr, AttributeName));
    end;

    procedure VerifyAttributeValueInSubtree(RootNodeName: Text; NodeName: Text; AttributeName: Text; ExpectedAttributeValue: Text)
    var
        ActualAttributeValue: Text;
    begin
        ActualAttributeValue := GetAttributeValueInSubtree(RootNodeName, NodeName, AttributeName);
        Assert.AreEqual(
          ExpectedAttributeValue, ActualAttributeValue,
          StrSubstNo(AttributeNodeValueErr, AttributeName, NodeName, RootNodeName));
    end;

    procedure VerifyAttributeAbsenceInSubtree(RootNodeName: Text; NodeName: Text; AttributeName: Text)
    begin
        asserterror GetAttributeValueInSubtree(RootNodeName, NodeName, AttributeName);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(AttributeNotFoundErr, NodeName, RootNodeName, AttributeName));
    end;

    procedure VerifyXMLDeclaration(Version: Text; Encoding: Text; Standalone: Text)
    var
        [RunOnClient]
        XMLDeclaration: DotNet XmlDeclaration;
    begin
        XMLDeclaration := XMLDocOut.FirstChild;
        Assert.AreEqual(Version, XMLDeclaration.Version, DeclarationVersionErr);
        Assert.AreEqual(Encoding, XMLDeclaration.Encoding, DeclarationEncodingErr);
        Assert.AreEqual(Standalone, XMLDeclaration.Standalone, DeclarationStandaloneErr);
    end;

    procedure VerifyAttributeAbsence(ElementName: Text; AttributeName: Text)
    var
        [RunOnClient]
        Attribute: DotNet XmlAttribute;
    begin
        GetAttributeFromElement(ElementName, AttributeName, Attribute);
        Assert.IsTrue(IsNull(Attribute), StrSubstNo(AttributeExistsErr, AttributeName));
    end;

    [Scope('OnPrem')]
    procedure GetNodeListByElementName(ElementName: Text; var NodeList: DotNet XmlNodeList): Integer
    begin
        NodeList := XMLDocOut.GetElementsByTagName(ElementName);
        if NodeList.Count = 0 then
            Error(MissingElementErr, ElementName);
        exit(NodeList.Count);
    end;

    [Scope('OnPrem')]
    procedure GetAttributeFromElement(ElementName: Text; AttributeName: Text; var Attribute: DotNet XmlAttribute)
    var
        [RunOnClient]
        Node: DotNet XmlNode;
    begin
        GetNodeByElementName(ElementName, Node);
        Attribute := Node.Attributes.GetNamedItem(AttributeName);
    end;

    [Scope('OnPrem')]
    procedure GetNodeByElementName(ElementName: Text; var Node: DotNet XmlNode)
    var
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
    begin
        GetNodeListByElementName(ElementName, NodeList);
        Node := NodeList.Item(0);
    end;

    procedure GetFirstElementValueFromNode(ElementName: Text; NodeName: Text): Text
    var
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
        [RunOnClient]
        Node: DotNet XmlNode;
        Msg: Text[1024];
    begin
        GetNodeListByElementName(NodeName, NodeList);
        Msg := CopyStr(StrSubstNo(CountErr, NodeName), 1, MaxStrLen(Msg));
        Assert.AreNotEqual(0, NodeList.Count, Msg);
        Node := NodeList.Item(0).SelectSingleNode(ElementName);

        exit(Node.InnerText);
    end;

    local procedure HasIndirectParent(Node: DotNet XmlNode; RootNodeName: Text) Found: Boolean
    var
        [RunOnClient]
        RootNode: DotNet XmlNode;
    begin
        RootNode := Node.ParentNode;
        while not IsNull(RootNode) and not Found do
            if RootNode.Name = RootNodeName then
                Found := true
            else
                RootNode := RootNode.ParentNode;
    end;
}

