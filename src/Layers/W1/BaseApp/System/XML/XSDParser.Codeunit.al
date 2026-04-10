namespace System.Xml;

using Microsoft.Bank.Statement;
using System;
using System.IO;

codeunit 9610 "XSD Parser"
{

    trigger OnRun()
    begin
    end;

    var
        TempAllXMLSchemaElement: Record "XML Schema Element" temporary;
        TempStackXMLSchemaElement: Record "XML Schema Element" temporary;
        TempXMLSchemaRestriction: Record "XML Schema Restriction" temporary;
        XMLDOMManagement: Codeunit "XML DOM Management";
        CouldNotFindAllSchemasMsg: Label 'Some required schemas are missing.\\Load the schemas one by one to include the required schemas.';
        GenerateDefinitionAgainQst: Label 'Do you want to generate the XML schema elements again?';
        OverrideExistingDataExchangeDefQst: Label 'A data exchange definition already exists. Do you want to replace the existing data exchange definition?';
        SEPACAMTDataLineTagTok: Label '/Document/BkToCstmrStmt/Stmt/Ntry', Locked = true;
        ReferenceElementTypeTok: Label 'Reference', Locked = true;
        ExtensionElementTypeTok: Label 'Extension', Locked = true;
        CouldNotFindRelatedSchema: Boolean;

    [Scope('OnPrem')]
    procedure LoadSchema(var XMLSchema: Record "XML Schema")
    begin
        if XMLSchema.Indentation = 0 then
            GenerateMainSchemaDefinition(XMLSchema)
        else
            LoadDependentSchemaSeparately(XMLSchema);
    end;

    local procedure GenerateMainSchemaDefinition(var XMLSchema: Record "XML Schema")
    var
        XMLSchemaElement: Record "XML Schema Element";
        DefinitionXMLSchema: Record "XML Schema";
        NamespaceMgr: DotNet XmlNamespaceManager;
        "Schema": DotNet XmlDocument;
        SchemaPrefix: Text;
        CurrentID: Integer;
    begin
        LoadSchemaXML(XMLSchema, NamespaceMgr, Schema, SchemaPrefix);

        DefinitionXMLSchema.Copy(XMLSchema);
        DefinitionXMLSchema.Code := StrSubstNo('%1:1000', XMLSchema.Code);
        DefinitionXMLSchema.Indentation := 1;
        DefinitionXMLSchema.Insert();

        ParseSchemaReferences(NamespaceMgr, XMLSchema, Schema, SchemaPrefix);

        CurrentID := 1;
        Clear(XMLSchemaElement);
        ParseChildXMLNodes(Schema.DocumentElement, SchemaPrefix, XMLSchemaElement, DefinitionXMLSchema, NamespaceMgr, 0, CurrentID);

        InitializeTempBuffers(XMLSchema);
        ExpandDefinitions(XMLSchema);
        UpdateXMLSchemaElementProperties(XMLSchema);

        if CouldNotFindRelatedSchema then
            Message(CouldNotFindAllSchemasMsg)
    end;

    local procedure LoadSchemaXML(var XMLSchema: Record "XML Schema"; var NamespaceMgr: DotNet XmlNamespaceManager; var "Schema": DotNet XmlDocument; var SchemaPrefix: Text)
    var
        InStr: InStream;
    begin
        XMLSchema.TestField(Code);
        XMLSchema.CalcFields(XSD);
        XMLSchema.TestField(XSD);
        XMLSchema.XSD.CreateInStream(InStr);

        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, Schema);

        NamespaceMgr := NamespaceMgr.XmlNamespaceManager(Schema.XmlDocument().NameTable);
        PopulateNamespaceManager(NamespaceMgr, Schema.DocumentElement, XMLSchema."Target Namespace", SchemaPrefix);
        UpdateTargetNamespaceAliases(XMLSchema, NamespaceMgr);
    end;

    procedure ExtendSelectedElement(var XMLSchemaElement: Record "XML Schema Element")
    var
        ChildXMLSchemaElement: Record "XML Schema Element";
        TempCurrentXMLSchemaElement: Record "XML Schema Element" temporary;
        LastXMLSchemaElement: Record "XML Schema Element";
        XMLSchema: Record "XML Schema";
        CurrentID: Integer;
        SchemaPrefix: Text;
    begin
        if (XMLSchemaElement."Defintion XML Schema Code" = '') or (XMLSchemaElement."Definition XML Schema ID" = 0) then
            exit;

        XMLSchema.Get(XMLSchemaElement."XML Schema Code");
        InitializeTempBuffers(XMLSchema);
        TempAllXMLSchemaElement.SetRange("XML Schema Code", XMLSchemaElement."Defintion XML Schema Code");
        TempAllXMLSchemaElement.SetRange(ID, XMLSchemaElement."Definition XML Schema ID");
        TempAllXMLSchemaElement.FindFirst();

        TempCurrentXMLSchemaElement.Copy(TempAllXMLSchemaElement);
        TempCurrentXMLSchemaElement.Insert();

        SchemaPrefix := '';

        LastXMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        LastXMLSchemaElement.FindLast();
        CurrentID := LastXMLSchemaElement.ID + 1;

        ExtendElementDefinitionType(TempCurrentXMLSchemaElement, XMLSchemaElement, 0, XMLSchema, CurrentID, SchemaPrefix);

        ChildXMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        ChildXMLSchemaElement.SetRange("Parent ID", XMLSchemaElement.ID);
        if ChildXMLSchemaElement.FindSet() then
            repeat
                UpdateSelectedProperty(ChildXMLSchemaElement, XMLSchemaElement."Sort Key", XMLSchema);
            until ChildXMLSchemaElement.Next() = 0;

        XMLSchemaElement."Defintion XML Schema Code" := '';
        XMLSchemaElement."Definition XML Schema ID" := 0;
        XMLSchemaElement.Modify();
    end;

    local procedure LoadDependentSchemaDefinition(var XMLSchema: Record "XML Schema")
    var
        XMLSchemaElement: Record "XML Schema Element";
        NamespaceMgr: DotNet XmlNamespaceManager;
        "Schema": DotNet XmlDocument;
        SchemaPrefix: Text;
        CurrentID: Integer;
    begin
        LoadSchemaXML(XMLSchema, NamespaceMgr, Schema, SchemaPrefix);
        ParseSchemaReferences(NamespaceMgr, XMLSchema, Schema, SchemaPrefix);

        CurrentID := 1;

        Clear(XMLSchemaElement);
        ParseChildXMLNodes(Schema.DocumentElement, SchemaPrefix, XMLSchemaElement, XMLSchema, NamespaceMgr, 0, CurrentID);
    end;

    local procedure ExpandDefinitions(XMLSchema: Record "XML Schema")
    var
        TempRootXMLSchemaElement: Record "XML Schema Element" temporary;
        ParentXMLSchemaElement: Record "XML Schema Element";
        CurrentID: Integer;
    begin
        TempRootXMLSchemaElement.Copy(TempAllXMLSchemaElement, true);
        TempRootXMLSchemaElement.SetRange("Parent ID", 0);
        TempRootXMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        TempRootXMLSchemaElement.SetRange("Node Type", TempRootXMLSchemaElement."Node Type"::Element);

        CurrentID := 1;
        if not TempRootXMLSchemaElement.FindSet() then
            exit;

        repeat
            Clear(ParentXMLSchemaElement);
            ParentXMLSchemaElement.Indentation := -1;
            ExtendElementDefinition(TempRootXMLSchemaElement, ParentXMLSchemaElement, 0, XMLSchema, CurrentID, '');
        until TempRootXMLSchemaElement.Next() = 0;
    end;

    local procedure ImportFile(var CurrentXMLSchema: Record "XML Schema"; FilePath: Text): Boolean
    var
        OutStream: OutStream;
        InStream: InStream;
        File: File;
    begin
        if not File.Open(FilePath) then
            exit(false);

        File.CreateInStream(InStream);
        CurrentXMLSchema.XSD.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);

        exit(true);
    end;

    local procedure PopulateNamespaceManager(var NamespaceMgr: DotNet XmlNamespaceManager; XmlNode: DotNet XmlNode; var TargetNamespace: Text; var SchemaPrefix: Text)
    var
        Attribute: DotNet XmlAttribute;
        Prefix: Text;
    begin
        if not IsNull(XmlNode) then
            foreach Attribute in XmlNode.Attributes do begin
                if StrPos(Attribute.Name, 'xmlns') = 1 then
                    if StrPos(Attribute.Name, ':') > 0 then begin
                        Prefix := CopyStr(Attribute.Name, StrPos(Attribute.Name, ':') + 1);
                        NamespaceMgr.AddNamespace(Prefix, Attribute.Value);
                        if Attribute.Value = 'http://www.w3.org/2001/XMLSchema' then
                            SchemaPrefix := Prefix;
                    end else
                        if Attribute.Value = 'http://www.w3.org/2001/XMLSchema' then begin
                            SchemaPrefix := 'unamedXSDSchemaNamespace';
                            NamespaceMgr.AddNamespace(SchemaPrefix, Attribute.Value);
                        end;

                if StrPos(Attribute.Name, 'targetNamespace') = 1 then
                    TargetNamespace := CopyStr(Attribute.Value, 1, MaxStrLen(TargetNamespace));
            end;
    end;

    local procedure UpdateTargetNamespaceAliases(var XMLSchema: Record "XML Schema"; NamespaceMgr: DotNet XmlNamespaceManager)
    var
        Prefix: Text;
    begin
        foreach Prefix in NamespaceMgr do begin
            if NamespaceMgr.LookupNamespace(Prefix) = XMLSchema."Target Namespace" then
                if XMLSchema."Target Namespace Aliases" = '' then
                    XMLSchema."Target Namespace Aliases" := CopyStr(Prefix, 1, MaxStrLen(XMLSchema."Target Namespace Aliases"))
                else
                    XMLSchema."Target Namespace Aliases" += CopyStr(' ' + Prefix, 1, MaxStrLen(XMLSchema."Target Namespace Aliases"));
            XMLSchema.Modify();
        end;
    end;

    local procedure ParseSchemaReferences(NamespaceMgr: DotNet XmlNamespaceManager; XMLSchema: Record "XML Schema"; "Schema": DotNet XmlDocument; SchemaPrefix: Text)
    begin
        ParseSchemaReferenceDefinition(StrSubstNo('./%1:include', SchemaPrefix), NamespaceMgr, XMLSchema, Schema);
        ParseSchemaReferenceDefinition(StrSubstNo('./%1:import', SchemaPrefix), NamespaceMgr, XMLSchema, Schema);
    end;

    local procedure ParseSchemaReferenceDefinition(XPath: Text; NamespaceMgr: DotNet XmlNamespaceManager; XMLSchema: Record "XML Schema"; "Schema": DotNet XmlDocument)
    var
        ImportXMLSchema: Record "XML Schema";
        ExistingXMLSchema: Record "XML Schema";
        LastXMLSchema: Record "XML Schema";
        ReferencedXMLSchema: Record "Referenced XML Schema";
        FileManagement: Codeunit "File Management";
        XmlNodeList: DotNet XmlNodeList;
        XmlNode: DotNet XmlNode;
        SchemaLocation: Text;
        DefinitionFileFound: Boolean;
        NameSpacePrefix: Text;
        TopElementCode: Text;
    begin
        if not XMLDOMManagement.FindNodesWithNamespaceManager(Schema.DocumentElement, XPath, NamespaceMgr, XmlNodeList) then
            exit;

        foreach XmlNode in XmlNodeList do begin
            SchemaLocation := GetSchemaLocation(XmlNode, XMLSchema);
            TopElementCode := XMLSchema.GetTopSchemaCode(XMLSchema);

            ExistingXMLSchema.SetRange(Path, SchemaLocation);
            ExistingXMLSchema.SetFilter(Code, StrSubstNo('%1*', TopElementCode));

            if not ExistingXMLSchema.FindFirst() then begin
                ImportXMLSchema.Init();
                ImportXMLSchema.Path := CopyStr(SchemaLocation, 1, MaxStrLen(ImportXMLSchema.Path));
                ImportXMLSchema."Target Namespace" := GetAttribute('namespace', XmlNode);

                // Include takes parents root namespace
                if (ImportXMLSchema."Target Namespace" = '') and (StrPos(XPath, 'include') > 0) then
                    ImportXMLSchema."Target Namespace" := XMLSchema."Target Namespace";

                LastXMLSchema.SetFilter(Code, StrSubstNo('%1:*', TopElementCode));
                LastXMLSchema.FindLast();
                ImportXMLSchema.Code := IncStr(LastXMLSchema.Code);

                ImportXMLSchema.Indentation := 2;
                ImportXMLSchema.Description := CopyStr(FileManagement.GetFileName(SchemaLocation), 1, MaxStrLen(ImportXMLSchema.Description));

                DefinitionFileFound := ImportFile(ImportXMLSchema, SchemaLocation);
                ImportXMLSchema.Insert();
                if DefinitionFileFound then
                    LoadDependentSchemaDefinition(ImportXMLSchema)
                else
                    CouldNotFindRelatedSchema := true;
            end else
                ImportXMLSchema := ExistingXMLSchema;

            NameSpacePrefix := NamespaceMgr.LookupPrefix(ImportXMLSchema."Target Namespace");
            ReferencedXMLSchema.Init();
            ReferencedXMLSchema.Code := XMLSchema.Code;
            ReferencedXMLSchema."Referenced Schema Code" := ImportXMLSchema.Code;
            ReferencedXMLSchema."Referenced Schema Namespace" :=
              CopyStr(NameSpacePrefix, 1, MaxStrLen(ReferencedXMLSchema."Referenced Schema Namespace"));
            if ReferencedXMLSchema.Insert(true) then;
        end;
    end;

    local procedure ParseChildXMLNodes(CurrentXMLNode: DotNet XmlNode; SchemaPrefix: Text; var ParentXMLSchemaElement: Record "XML Schema Element"; XMLSchema: Record "XML Schema"; NamespaceMgr: DotNet XmlNamespaceManager; NestingLevel: Integer; var CurrentID: Integer)
    var
        XMLNode: DotNet XmlNode;
        ListOfElements: DotNet GenericList1;
    begin
        if CurrentXMLNode.HasChildNodes then begin
            ListOfElements := ListOfElements.List();
            foreach XMLNode in CurrentXMLNode.ChildNodes() do
                if XMLNode.Name = StrSubstNo('%1:attribute', SchemaPrefix) then
                    ParseXMLNode(XMLNode, SchemaPrefix, ParentXMLSchemaElement, XMLSchema, NamespaceMgr, NestingLevel, CurrentID)
                else
                    ListOfElements.Add(XMLNode);
            foreach XMLNode in ListOfElements do
                ParseXMLNode(XMLNode, SchemaPrefix, ParentXMLSchemaElement, XMLSchema, NamespaceMgr, NestingLevel, CurrentID);
        end;
    end;

    local procedure ParseXMLNode(CurrentXMLNode: DotNet XmlNode; SchemaPrefix: Text; var ParentXMLSchemaElement: Record "XML Schema Element"; XMLSchema: Record "XML Schema"; NamespaceMgr: DotNet XmlNamespaceManager; NestingLevel: Integer; var CurrentID: Integer)
    var
        LastXMLSchemaElement: Record "XML Schema Element";
        XMLNodeType: DotNet XmlNodeType;
    begin
        if CurrentXMLNode.NodeType.Equals(XMLNodeType.Element) then
            case CurrentXMLNode.Name of
                StrSubstNo('%1:element', SchemaPrefix),
                StrSubstNo('%1:group', SchemaPrefix),
                StrSubstNo('%1:extension', SchemaPrefix):
                    begin
                        InsertElementDefinition(
                          LastXMLSchemaElement, CurrentXMLNode, ParentXMLSchemaElement.ID, XMLSchema, SchemaPrefix, CurrentID);
                        ParseChildXMLNodes(CurrentXMLNode, SchemaPrefix, LastXMLSchemaElement, XMLSchema, NamespaceMgr, NestingLevel + 1, CurrentID);
                    end;
                StrSubstNo('%1:attribute', SchemaPrefix):
                    begin
                        InsertAttributeDefinition(
                          LastXMLSchemaElement, CurrentXMLNode, ParentXMLSchemaElement.ID, XMLSchema, CurrentID);
                        ParseChildXMLNodes(CurrentXMLNode, SchemaPrefix, LastXMLSchemaElement, XMLSchema, NamespaceMgr, NestingLevel + 1, CurrentID);
                    end;
                StrSubstNo('%1:complexType', SchemaPrefix),
              StrSubstNo('%1:simpleType', SchemaPrefix):
                    if NestingLevel = 0 then begin
                        InsertElementDefinition(
                          LastXMLSchemaElement, CurrentXMLNode, ParentXMLSchemaElement.ID, XMLSchema, SchemaPrefix, CurrentID);
                        ParseChildXMLNodes(CurrentXMLNode, SchemaPrefix, LastXMLSchemaElement, XMLSchema, NamespaceMgr, NestingLevel + 1, CurrentID);
                    end else
                        ParseChildXMLNodes(CurrentXMLNode, SchemaPrefix, ParentXMLSchemaElement, XMLSchema, NamespaceMgr, NestingLevel + 1, CurrentID);
                StrSubstNo('%1:restriction', SchemaPrefix):
                    ParseRestrictions(CurrentXMLNode, ParentXMLSchemaElement, NamespaceMgr, XMLSchema, SchemaPrefix);
                StrSubstNo('%1:annotation', SchemaPrefix):
                    exit;
                else
                    ParseChildXMLNodes(CurrentXMLNode, SchemaPrefix, ParentXMLSchemaElement, XMLSchema, NamespaceMgr, NestingLevel + 1, CurrentID);
            end;
    end;

    local procedure ParseRestrictions(CurrentXmlNode: DotNet XmlNode; var TempXMLSchemaElement: Record "XML Schema Element" temporary; NamespaceMgr: DotNet XmlNamespaceManager; XMLSchema: Record "XML Schema"; SchemaPrefix: Text)
    var
        XMLSchemaRestriction: Record "XML Schema Restriction";
        LastIndex: Integer;
    begin
        XMLSchemaRestriction.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaRestriction.SetRange("Element ID", TempXMLSchemaElement.ID);
        if XMLSchemaRestriction.FindLast() then
            LastIndex := XMLSchemaRestriction.ID + 1
        else
            LastIndex := 1;

        XMLSchemaRestriction.Init();
        XMLSchemaRestriction."XML Schema Code" := XMLSchema.Code;
        XMLSchemaRestriction."Element ID" := TempXMLSchemaElement.ID;
        XMLSchemaRestriction.ID := LastIndex;
        LastIndex += 1;
        XMLSchemaRestriction.Value := GetAttribute('base', CurrentXmlNode);
        XMLSchemaRestriction.Type := XMLSchemaRestriction.Type::Base;
        XMLSchemaRestriction.Insert();

        ParseRestrictionDefinitions(
          TempXMLSchemaElement.ID, StrSubstNo('./%1:enumeration', SchemaPrefix), CurrentXmlNode, NamespaceMgr, XMLSchema, LastIndex);
        ParseRestrictionDefinitions(
          TempXMLSchemaElement.ID, StrSubstNo('./%1:pattern', SchemaPrefix), CurrentXmlNode, NamespaceMgr, XMLSchema, LastIndex);
    end;

    local procedure ParseRestrictionDefinitions(ID: Integer; XPath: Text; var CurrentXMLNode: DotNet XmlNode; NamespaceMgr: DotNet XmlNamespaceManager; XMLSchema: Record "XML Schema"; var LastIndex: Integer)
    var
        XMLSchemaRestriction: Record "XML Schema Restriction";
        XMLNode: DotNet XmlNode;
        XMLNodeList: DotNet XmlNodeList;
        i: Integer;
    begin
        if not XMLDOMManagement.FindNodesWithNamespaceManager(CurrentXMLNode, XPath, NamespaceMgr, XMLNodeList) then
            exit;

        for i := 1 to XMLNodeList.Count do begin
            XMLNode := XMLNodeList.Item(i - 1);
            if not IsNull(XMLNode) then begin
                XMLSchemaRestriction.Init();
                XMLSchemaRestriction."XML Schema Code" := XMLSchema.Code;
                XMLSchemaRestriction."Element ID" := ID;
                LastIndex += 1;
                XMLSchemaRestriction.ID := LastIndex;
                XMLSchemaRestriction.Type := XMLSchemaRestriction.Type::Value;
                XMLSchemaRestriction.Value := GetAttribute('name', XMLNode);
                if XMLSchemaRestriction.Value = '' then
                    XMLSchemaRestriction.Value := GetAttribute('value', XMLNode);
                XMLSchemaRestriction.Insert();
            end;
        end;
    end;

    local procedure ExtendElementDefinition(var CurrentDefinitionXMLSchemaElement: Record "XML Schema Element"; var ParentXMLSchemaElement: Record "XML Schema Element"; NestingLevel: Integer; XMLSchema: Record "XML Schema"; var CurrentID: Integer; SchemaPrefix: Text)
    var
        LastXMLSchemaElement: Record "XML Schema Element";
    begin
        case CurrentDefinitionXMLSchemaElement."Node Type" of
            CurrentDefinitionXMLSchemaElement."Node Type"::Element,
            CurrentDefinitionXMLSchemaElement."Node Type"::Attribute:
                begin
                    InsertXMLSchemaElementFromDefinition(
                      CurrentDefinitionXMLSchemaElement, ParentXMLSchemaElement, LastXMLSchemaElement, XMLSchema, CurrentID, SchemaPrefix);
                    InsertRestrictions(LastXMLSchemaElement, CurrentDefinitionXMLSchemaElement, XMLSchema);
                    ExtendElementDefinitionType(
                      CurrentDefinitionXMLSchemaElement, LastXMLSchemaElement, NestingLevel, XMLSchema, CurrentID, SchemaPrefix);
                end;
            CurrentDefinitionXMLSchemaElement."Node Type"::"Definition Node":
                begin
                    InsertRestrictions(ParentXMLSchemaElement, CurrentDefinitionXMLSchemaElement, XMLSchema);
                    ExtendElementDefinitionType(
                      CurrentDefinitionXMLSchemaElement, ParentXMLSchemaElement, NestingLevel, XMLSchema, CurrentID, SchemaPrefix);
                end;
        end;
    end;

    local procedure ExtendElementDefinitionType(var CurrentDefinitionXMLSchemaElement: Record "XML Schema Element"; var ParentXMLSchemaElement: Record "XML Schema Element"; NestingLevel: Integer; XMLSchema: Record "XML Schema"; var CurrentID: Integer; SchemaPrefix: Text)
    begin
        if not ParentXMLSchemaElement.Selected then
            if DetectDefinitionLoop(CurrentDefinitionXMLSchemaElement) or (ParentXMLSchemaElement.MinOccurs = 0)
            then begin
                ParentXMLSchemaElement."Defintion XML Schema Code" := CurrentDefinitionXMLSchemaElement."XML Schema Code";
                ParentXMLSchemaElement."Definition XML Schema ID" := CurrentDefinitionXMLSchemaElement.ID;
                ParentXMLSchemaElement.Modify();
                exit;
            end;

        PushDefinitionOnStack(CurrentDefinitionXMLSchemaElement);

        case CurrentDefinitionXMLSchemaElement."Data Type" of
            '':
                ExtendNestedElementDefinition(
                  CurrentDefinitionXMLSchemaElement, ParentXMLSchemaElement, NestingLevel, XMLSchema, CurrentID, SchemaPrefix);
            ReferenceElementTypeTok:
                ExtendReferenceElementDefinition(
                  CurrentDefinitionXMLSchemaElement, ParentXMLSchemaElement, NestingLevel, XMLSchema, CurrentID, SchemaPrefix);
            ExtensionElementTypeTok:
                ExtendExtensionElementDefinition(
                  CurrentDefinitionXMLSchemaElement, ParentXMLSchemaElement, NestingLevel, XMLSchema, CurrentID, SchemaPrefix);
            else
                ExtendTypeElementDefinition(
                  CurrentDefinitionXMLSchemaElement, ParentXMLSchemaElement, NestingLevel, XMLSchema, CurrentID, SchemaPrefix);
        end;

        PopDefinitionFromStack(CurrentDefinitionXMLSchemaElement);
    end;

    local procedure ExtendNestedElementDefinition(var CurrentDefinitionXMLSchemaElement: Record "XML Schema Element"; var ParentXMLSchemaElement: Record "XML Schema Element"; NestingLevel: Integer; XMLSchema: Record "XML Schema"; var CurrentID: Integer; SchemaPrefix: Text)
    var
        TempNextXMLSchemaElementDefintion: Record "XML Schema Element" temporary;
    begin
        if GetChildElementsForComplexType(CurrentDefinitionXMLSchemaElement, TempNextXMLSchemaElementDefintion) then
            repeat
                ExtendElementDefinition(
                  TempNextXMLSchemaElementDefintion, ParentXMLSchemaElement, NestingLevel + 1, XMLSchema, CurrentID, SchemaPrefix);
            until TempNextXMLSchemaElementDefintion.Next() = 0;
    end;

    local procedure ExtendReferenceElementDefinition(var CurrentDefinitionXMLSchemaElement: Record "XML Schema Element"; var ParentXMLSchemaElement: Record "XML Schema Element"; NestingLevel: Integer; XMLSchema: Record "XML Schema"; var CurrentID: Integer; SchemaPrefix: Text)
    var
        TempNextXMLSchemaElementDefintion: Record "XML Schema Element" temporary;
    begin
        if GetReferencedElementDefinition(CurrentDefinitionXMLSchemaElement, TempNextXMLSchemaElementDefintion, SchemaPrefix) then
            ExtendElementDefinitionType(
              TempNextXMLSchemaElementDefintion, ParentXMLSchemaElement, NestingLevel + 1, XMLSchema, CurrentID, SchemaPrefix);
    end;

    local procedure ExtendExtensionElementDefinition(var CurrentDefinitionXMLSchemaElement: Record "XML Schema Element"; var ParentXMLSchemaElement: Record "XML Schema Element"; NestingLevel: Integer; XMLSchema: Record "XML Schema"; var CurrentID: Integer; SchemaPrefix: Text)
    var
        TempNextXMLSchemaElementDefintion: Record "XML Schema Element" temporary;
        NewSchemaPrefix: Text;
    begin
        if GetReferencedElementDefinition(CurrentDefinitionXMLSchemaElement, TempNextXMLSchemaElementDefintion, NewSchemaPrefix) then
            ExtendElementDefinition(
              TempNextXMLSchemaElementDefintion, ParentXMLSchemaElement, NestingLevel + 1, XMLSchema, CurrentID, NewSchemaPrefix)
        else
            UpdateSimpleType(ParentXMLSchemaElement, CurrentDefinitionXMLSchemaElement."Node Name");

        if GetChildElementsForComplexType(CurrentDefinitionXMLSchemaElement, TempNextXMLSchemaElementDefintion) then
            repeat
                ExtendElementDefinition(
                  TempNextXMLSchemaElementDefintion, ParentXMLSchemaElement, NestingLevel + 1, XMLSchema, CurrentID, SchemaPrefix);
            until TempNextXMLSchemaElementDefintion.Next() = 0;
    end;

    local procedure ExtendTypeElementDefinition(var CurrentDefinitionXMLSchemaElement: Record "XML Schema Element"; var ParentXMLSchemaElement: Record "XML Schema Element"; NestingLevel: Integer; XMLSchema: Record "XML Schema"; var CurrentID: Integer; SchemaPrefix: Text)
    var
        TempNextXMLSchemaElementDefintion: Record "XML Schema Element" temporary;
    begin
        if GetTypeDefinition(CurrentDefinitionXMLSchemaElement, TempNextXMLSchemaElementDefintion) then
            repeat
                ExtendElementDefinition(
                  TempNextXMLSchemaElementDefintion, ParentXMLSchemaElement, NestingLevel + 1, XMLSchema, CurrentID, SchemaPrefix);
            until TempNextXMLSchemaElementDefintion.Next() = 0
        else
            UpdateSimpleType(ParentXMLSchemaElement, ParentXMLSchemaElement."Data Type");
    end;

    local procedure UpdateSimpleType(var XMLSchemaElement: Record "XML Schema Element"; NewSimpleType: Text)
    begin
        if XMLSchemaElement."Simple Data Type" = '' then begin
            XMLSchemaElement.Validate("Simple Data Type", CopyStr(NewSimpleType, 1, MaxStrLen(XMLSchemaElement."Simple Data Type")));
            XMLSchemaElement.Modify(true);
        end;
    end;

    local procedure InsertElementDefinition(var LastXMLSchemaElement: Record "XML Schema Element"; XmlNode: DotNet XmlNode; ParentID: Integer; XMLSchema: Record "XML Schema"; SchemaPrefix: Text; var CurrentID: Integer)
    var
        XMLSchemaElement: Record "XML Schema Element";
    begin
        XMLSchemaElement.Init();
        AssignKeyToXMLSchemaElement(XMLSchemaElement, XMLSchema, CurrentID);

        XMLSchemaElement."Node Name" := GetElementName(XmlNode);

        if XmlNode.Name = StrSubstNo('%1:element', SchemaPrefix) then
            XMLSchemaElement."Node Type" := XMLSchemaElement."Node Type"::Element
        else
            XMLSchemaElement."Node Type" := XMLSchemaElement."Node Type"::"Definition Node";

        XMLSchemaElement."Data Type" := GetElementType(XmlNode);
        XMLSchemaElement."Parent ID" := ParentID;
        XMLSchemaElement.Choice := StrPos(XmlNode.Name, 'choice') > 0;

        SetMinAndMaxOccurs(XMLSchemaElement, XmlNode);
        XMLSchemaElement.Insert();
        LastXMLSchemaElement := XMLSchemaElement;
    end;

    local procedure InsertAttributeDefinition(var LastXMLSchemaElement: Record "XML Schema Element"; XmlNode: DotNet XmlNode; ParentID: Integer; XMLSchema: Record "XML Schema"; var CurrentID: Integer)
    var
        XMLSchemaElement: Record "XML Schema Element";
    begin
        XMLSchemaElement.Init();
        AssignKeyToXMLSchemaElement(XMLSchemaElement, XMLSchema, CurrentID);
        XMLSchemaElement."Node Name" := GetElementName(XmlNode);
        XMLSchemaElement."Node Type" := XMLSchemaElement."Node Type"::Attribute;
        XMLSchemaElement."Data Type" := GetElementType(XmlNode);
        XMLSchemaElement."Parent ID" := ParentID;

        if GetAttribute('use', XmlNode) = 'required' then
            XMLSchemaElement.MinOccurs := 1;

        XMLSchemaElement.MaxOccurs := 1;
        XMLSchemaElement.Insert();

        LastXMLSchemaElement := XMLSchemaElement;
    end;

    local procedure GetAttribute(AttributeName: Text; var XMLNode: DotNet XmlNode): Text[250]
    var
        XMLAttributeNode: DotNet XmlNode;
    begin
        XMLAttributeNode := XMLNode.Attributes.GetNamedItem(AttributeName);
        if IsNull(XMLAttributeNode) then
            exit('');

        exit(CopyStr(Format(XMLAttributeNode.InnerText), 1, 250));
    end;

    local procedure SetMinAndMaxOccurs(var XMLSchemaElement: Record "XML Schema Element"; XmlNode: DotNet XmlNode)
    begin
        if GetAttribute('minOccurs', XmlNode) <> '' then
            Evaluate(XMLSchemaElement.MinOccurs, GetAttribute('minOccurs', XmlNode))
        else
            XMLSchemaElement.MinOccurs := 1;

        case GetAttribute('maxOccurs', XmlNode) of
            '':
                XMLSchemaElement.MaxOccurs := XMLSchemaElement.MinOccurs;
            'unbounded':
                XMLSchemaElement.MaxOccurs := 999999999;
            else
                Evaluate(XMLSchemaElement.MaxOccurs, GetAttribute('maxOccurs', XmlNode));
        end;
    end;

    local procedure UpdateXMLSchemaElementProperties(XMLSchema: Record "XML Schema")
    var
        XMLSchemaElement: Record "XML Schema Element";
    begin
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.SetRange("Parent ID", 0);

        if XMLSchemaElement.FindSet() then
            repeat
                UpdateSelectedProperty(XMLSchemaElement, '', XMLSchema);
            until XMLSchemaElement.Next() = 0;
    end;

    local procedure UpdateSelectedProperty(var CurrentXMLSchemaElement: Record "XML Schema Element"; ParentSortKey: Text[250]; XMLSchema: Record "XML Schema")
    var
        ChildXMLSchemaElement: Record "XML Schema Element";
    begin
        CurrentXMLSchemaElement."Sort Key" := StrSubstNo('%1 %2', ParentSortKey, Format(1000 + CurrentXMLSchemaElement.ID));
        CurrentXMLSchemaElement.Modify();

        if (CurrentXMLSchemaElement.MinOccurs > 0) and (CurrentXMLSchemaElement."Defintion XML Schema Code" = '') then begin
            CurrentXMLSchemaElement.Selected := true;
            CurrentXMLSchemaElement.Modify();

            ChildXMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
            ChildXMLSchemaElement.SetRange("Parent ID", CurrentXMLSchemaElement.ID);
            if ChildXMLSchemaElement.FindSet() then
                repeat
                    UpdateSelectedProperty(ChildXMLSchemaElement, CurrentXMLSchemaElement."Sort Key", XMLSchema);
                until ChildXMLSchemaElement.Next() = 0;
        end;
    end;

    local procedure GetElementName(var XMLNode: DotNet XmlNode): Text[250]
    var
        ElementName: Text;
    begin
        ElementName := GetAttribute('name', XMLNode);

        if ElementName = '' then
            ElementName := GetAttribute('ref', XMLNode);

        if ElementName = '' then
            ElementName := GetAttribute('base', XMLNode);

        exit(ElementName);
    end;

    local procedure GetElementType(var XMLNode: DotNet XmlNode): Text[250]
    var
        ElementType: Text;
    begin
        ElementType := GetAttribute('type', XMLNode);

        if (ElementType = '') and (GetAttribute('ref', XMLNode) <> '') then
            ElementType := ReferenceElementTypeTok;

        if (ElementType = '') and (GetAttribute('base', XMLNode) <> '') then
            ElementType := ExtensionElementTypeTok;

        exit(ElementType);
    end;

    local procedure GetChildElementsForComplexType(DefinitionXMLSchemaElement: Record "XML Schema Element"; var ReferenceXMLSchemaElement: Record "XML Schema Element"): Boolean
    begin
        TempAllXMLSchemaElement.Reset();

        // Get root definition
        TempAllXMLSchemaElement.SetRange("XML Schema Code", DefinitionXMLSchemaElement."XML Schema Code");
        TempAllXMLSchemaElement.SetRange("Parent ID", DefinitionXMLSchemaElement.ID);

        if not TempAllXMLSchemaElement.FindSet() then
            exit(false);

        repeat
            ReferenceXMLSchemaElement.Copy(TempAllXMLSchemaElement);
            ReferenceXMLSchemaElement.Insert();
        until TempAllXMLSchemaElement.Next() = 0;

        ReferenceXMLSchemaElement.FindFirst();
        exit(true);
    end;

    local procedure GetReferencedElementDefinition(DefinitionXMLSchemaElement: Record "XML Schema Element"; var ReferenceXMLSchemaElement: Record "XML Schema Element"; var SchemaPrefix: Text): Boolean
    var
        XMLSchema: Record "XML Schema";
        ReferencedXMLSchema: Record "Referenced XML Schema";
        NameWithoutNamespace: Text;
        NamespaceLength: Integer;
    begin
        NamespaceLength := StrPos(DefinitionXMLSchemaElement."Node Name", ':');

        if NamespaceLength > 0 then begin
            // Process Import Namespaces
            SchemaPrefix := CopyStr(DefinitionXMLSchemaElement."Node Name", 1, NamespaceLength - 1);
            NameWithoutNamespace := CopyStr(DefinitionXMLSchemaElement."Node Name", NamespaceLength + 1);
            XMLSchema.Get(DefinitionXMLSchemaElement."XML Schema Code");
            if XMLSchema."Target Namespace Aliases" <> SchemaPrefix then begin
                ReferencedXMLSchema.SetRange("Referenced Schema Namespace", SchemaPrefix);
                ReferencedXMLSchema.SetRange(Code, DefinitionXMLSchemaElement."XML Schema Code");
                if not ReferencedXMLSchema.FindSet() then
                    exit(false);
            end else begin
                if not (SchemaPrefix = 'cac') then
                    exit(false);
                TempAllXMLSchemaElement.Reset();
                TempAllXMLSchemaElement.SetRange("XML Schema Code", DefinitionXMLSchemaElement."XML Schema Code");
                TempAllXMLSchemaElement.SetRange("Parent ID", 0);
                TempAllXMLSchemaElement.SetRange("Node Name", NameWithoutNamespace);

                if TempAllXMLSchemaElement.FindFirst() then begin
                    ReferenceXMLSchemaElement.Copy(TempAllXMLSchemaElement);
                    ReferenceXMLSchemaElement.Insert();

                    exit(true);
                end;

                exit(false);
            end;
        end;

        if NamespaceLength = 0 then begin
            // Check part of the same schema
            if NameWithoutNamespace = '' then
                NameWithoutNamespace := DefinitionXMLSchemaElement."Node Name";

            TempAllXMLSchemaElement.Reset();
            TempAllXMLSchemaElement.SetRange("XML Schema Code", DefinitionXMLSchemaElement."XML Schema Code");
            TempAllXMLSchemaElement.SetRange("Parent ID", 0);
            TempAllXMLSchemaElement.SetRange("Node Name", NameWithoutNamespace);

            if TempAllXMLSchemaElement.FindFirst() then begin
                ReferenceXMLSchemaElement.Copy(TempAllXMLSchemaElement);
                ReferenceXMLSchemaElement.Insert();

                exit(true);
            end;

            // Process Include Statement
            ReferencedXMLSchema.SetRange(Code, DefinitionXMLSchemaElement."XML Schema Code");
            ReferencedXMLSchema.SetRange("Referenced Schema Namespace", '');

            if not ReferencedXMLSchema.FindSet() then
                exit(false);
        end;

        repeat
            TempAllXMLSchemaElement.Reset();
            TempAllXMLSchemaElement.SetRange("XML Schema Code", ReferencedXMLSchema."Referenced Schema Code");
            TempAllXMLSchemaElement.SetRange("Parent ID", 0);
            TempAllXMLSchemaElement.SetRange("Node Name", NameWithoutNamespace);

            if TempAllXMLSchemaElement.FindFirst() then begin
                ReferenceXMLSchemaElement.Copy(TempAllXMLSchemaElement);
                ReferenceXMLSchemaElement.Insert();
                exit(true);
            end;
        until ReferencedXMLSchema.Next() = 0;

        exit(false);
    end;

    local procedure GetTypeDefinition(DefinitionXMLSchemaElement: Record "XML Schema Element"; var ReferenceXMLSchemaElement: Record "XML Schema Element"): Boolean
    begin
        TempAllXMLSchemaElement.Reset();

        // Get Type Definition
        TempAllXMLSchemaElement.SetRange("XML Schema Code", DefinitionXMLSchemaElement."XML Schema Code");
        TempAllXMLSchemaElement.SetRange("Parent ID", 0);
        TempAllXMLSchemaElement.SetRange("Node Name", DefinitionXMLSchemaElement."Data Type");
        TempAllXMLSchemaElement.SetRange("Node Type", DefinitionXMLSchemaElement."Node Type"::"Definition Node");

        if not TempAllXMLSchemaElement.FindFirst() then
            exit(false);

        ReferenceXMLSchemaElement.Init();
        ReferenceXMLSchemaElement.Copy(TempAllXMLSchemaElement);
        ReferenceXMLSchemaElement.Insert();
        exit(true);
    end;

    local procedure InsertRestrictions(var ActualXMLSchemaElement: Record "XML Schema Element"; DefinitionXMLSchemaElement: Record "XML Schema Element"; XMLSchema: Record "XML Schema")
    var
        XMLSchemaRestriction: Record "XML Schema Restriction";
        XMLSchemaRestriction2: Record "XML Schema Restriction";
        LastRestrictionID: Integer;
    begin
        TempXMLSchemaRestriction.SetRange("XML Schema Code", XMLSchema.Code);
        TempXMLSchemaRestriction.SetRange("Element ID", DefinitionXMLSchemaElement.ID);
        TempXMLSchemaRestriction.SetRange(Type, TempXMLSchemaRestriction.Type::Base);

        if not TempXMLSchemaRestriction.FindFirst() then
            exit;

        ActualXMLSchemaElement.Validate(
          "Simple Data Type", CopyStr(TempXMLSchemaRestriction.Value, 1, MaxStrLen(ActualXMLSchemaElement."Simple Data Type")));
        ActualXMLSchemaElement.Modify();

        TempXMLSchemaRestriction.SetRange(Type, TempXMLSchemaRestriction.Type::Value);
        if not TempXMLSchemaRestriction.FindSet() then
            exit;

        XMLSchemaRestriction2.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaRestriction2.SetRange("Element ID", ActualXMLSchemaElement.ID);
        if XMLSchemaRestriction2.FindLast() then
            LastRestrictionID := XMLSchemaRestriction2.ID + 1
        else
            LastRestrictionID := 1;

        repeat
            XMLSchemaRestriction.Init();
            XMLSchemaRestriction.Copy(TempXMLSchemaRestriction);
            XMLSchemaRestriction.ID := LastRestrictionID;
            LastRestrictionID += 1;
            XMLSchemaRestriction."Element ID" := ActualXMLSchemaElement.ID;
            XMLSchemaRestriction.Insert();
        until TempXMLSchemaRestriction.Next() = 0;
    end;

    local procedure InsertXMLSchemaElementFromDefinition(DefinitionXMLSchemaElement: Record "XML Schema Element"; ParentXMLSchemaElement: Record "XML Schema Element"; var XMLSchemaElement: Record "XML Schema Element"; XMLSchema: Record "XML Schema"; var CurrentID: Integer; SchemaPrefix: Text)
    var
        PrefixLength: Integer;
    begin
        XMLSchemaElement.Copy(DefinitionXMLSchemaElement);
        AssignKeyToXMLSchemaElement(XMLSchemaElement, XMLSchema, CurrentID);
        XMLSchemaElement."Node Name" := DefinitionXMLSchemaElement."Node Name";

        PrefixLength := StrPos(XMLSchemaElement."Node Name", ':');

        if XMLSchemaElement."Node Type" = XMLSchemaElement."Node Type"::Element then
            if (SchemaPrefix <> '') and (PrefixLength = 0) then
                XMLSchemaElement."Node Name" := StrSubstNo('%1:%2', SchemaPrefix, XMLSchemaElement."Node Name");

        XMLSchemaElement."Parent ID" := ParentXMLSchemaElement.ID;
        XMLSchemaElement.Indentation := ParentXMLSchemaElement.Indentation + 1;
        XMLSchemaElement.Insert();
    end;

    local procedure AssignKeyToXMLSchemaElement(var XMLSchemaElement: Record "XML Schema Element"; XMLSchema: Record "XML Schema"; var CurrentID: Integer)
    begin
        XMLSchemaElement."XML Schema Code" := XMLSchema.Code;
        XMLSchemaElement.ID := CurrentID;
        CurrentID += 1;
    end;

    procedure ShowAll(var XMLSchemaElement: Record "XML Schema Element")
    begin
        XMLSchemaElement.ModifyAll(Visible, true);
        XMLSchemaElement.SetRange(Visible);
        XMLSchemaElement.SetRange(Selected);
    end;

    local procedure GetSchemaLocation(CurrentXmlNode: DotNet XmlNode; XMLSchema: Record "XML Schema"): Text
    var
        FileManagement: Codeunit "File Management";
        SchemaLocation: Text;
        FilePath: Text;
    begin
        SchemaLocation := ConvertStr(GetAttribute('schemaLocation', CurrentXmlNode), '/', '\');
        FilePath := FileManagement.CombinePath(FileManagement.GetDirectoryName(XMLSchema.Path), SchemaLocation);
        exit(FilePath);
    end;

    procedure SelectMandatory(XMLSchemaElement: Record "XML Schema Element")
    begin
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchemaElement."XML Schema Code");
        XMLSchemaElement.SetRange("Parent ID", 0);
        if XMLSchemaElement.FindFirst() then begin
            XMLSchemaElement.Validate(Selected, true);
            XMLSchemaElement.Modify();
        end;
    end;

    procedure DeselectAll(var XMLSchemaElement: Record "XML Schema Element")
    begin
        XMLSchemaElement.ModifyAll(Selected, false);
    end;

    procedure HideNotMandatory(var XMLSchemaElement: Record "XML Schema Element")
    var
        xXMLSchemaElementID: Integer;
        LevelVisible: array[100] of Boolean;
    begin
        xXMLSchemaElementID := XMLSchemaElement.ID;
        XMLSchemaElement.SetCurrentKey("Sort Key");
        LevelVisible[1] := true;
        if XMLSchemaElement.FindSet() then
            repeat
                XMLSchemaElement.Visible := (XMLSchemaElement.MinOccurs > 0);
                if XMLSchemaElement.Indentation > 0 then
                    if not LevelVisible[XMLSchemaElement.Indentation] then
                        XMLSchemaElement.Visible := false;
                LevelVisible[XMLSchemaElement.Indentation + 1] := XMLSchemaElement.Visible;
                XMLSchemaElement.Modify();
            until XMLSchemaElement.Next() = 0;

        XMLSchemaElement.SetRange(Visible, true);
        if XMLSchemaElement.Get(XMLSchemaElement."XML Schema Code", xXMLSchemaElementID) then;
    end;

    procedure HideNotSelected(var XMLSchemaElement: Record "XML Schema Element")
    begin
        XMLSchemaElement.SetRange(Selected, true);
    end;

    local procedure LoadDependentSchemaSeparately(var XMLSchema: Record "XML Schema")
    var
        XMLSchemaElement: Record "XML Schema Element";
        MainDocumentXMLSchema: Record "XML Schema";
        NamespaceMgr: DotNet XmlNamespaceManager;
        "Schema": DotNet XmlDocument;
        SchemaPrefix: Text;
        CurrentID: Integer;
    begin
        LoadSchemaXML(XMLSchema, NamespaceMgr, Schema, SchemaPrefix);
        ParseSchemaReferences(NamespaceMgr, XMLSchema, Schema, SchemaPrefix);

        CurrentID := 1;
        Clear(XMLSchemaElement);
        ParseChildXMLNodes(Schema.DocumentElement, SchemaPrefix, XMLSchemaElement, XMLSchema, NamespaceMgr, 0, CurrentID);

        if not Confirm(GenerateDefinitionAgainQst) then
            exit;

        MainDocumentXMLSchema.Get(XMLSchema.GetTopSchemaCode(XMLSchema));
        RemoveDefinitions(MainDocumentXMLSchema);

        InitializeTempBuffers(MainDocumentXMLSchema);
        ExpandDefinitions(MainDocumentXMLSchema);
        UpdateXMLSchemaElementProperties(MainDocumentXMLSchema);

        if CouldNotFindRelatedSchema then
            Message(CouldNotFindAllSchemasMsg)
    end;

    local procedure RemoveDefinitions(var XMLSchema: Record "XML Schema")
    var
        XMLSchemaElement: Record "XML Schema Element";
        XMLSchemaRestriction: Record "XML Schema Restriction";
    begin
        XMLSchemaRestriction.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaRestriction.DeleteAll(true);

        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.DeleteAll(true);

        CouldNotFindRelatedSchema := false;

        TempStackXMLSchemaElement.Reset();
        TempStackXMLSchemaElement.DeleteAll();

        TempAllXMLSchemaElement.Reset();
        TempXMLSchemaRestriction.Reset();

        TempAllXMLSchemaElement.DeleteAll();
        TempXMLSchemaRestriction.DeleteAll();
    end;

    procedure CreateDataExchDefForCAMT(var XMLSchemaElement: Record "XML Schema Element")
    var
        XMLSchema: Record "XML Schema";
        DataExchDef: Record "Data Exch. Def";
    begin
        XMLSchema.Get(XMLSchemaElement."XML Schema Code");

        if DataExchDef.Get(XMLSchema.Code) then begin
            if not Confirm(OverrideExistingDataExchangeDefQst) then
                exit;
            DataExchDef.Delete(true);
        end;

        DataExchDef.InsertRec(XMLSchema.Code, XMLSchema.Description,
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchDef."File Type" := DataExchDef."File Type"::Xml;
        DataExchDef."Reading/Writing Codeunit" := Codeunit::"Import Bank Statement";
        DataExchDef.Modify();

        CreateDataExchColumnDefinitions(XMLSchema, DataExchDef);

        Commit();
        PAGE.RunModal(PAGE::"Data Exch Def Card", DataExchDef);
    end;

    procedure CreateDataExchColumnDefinitions(XMLSchema: Record "XML Schema"; DataExchDef: Record "Data Exch. Def")
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        XMLSchemaElement: Record "XML Schema Element";
        DataExchLineDef: Record "Data Exch. Line Def";
        SchemaContext: Text;
        ColumnNo: Integer;
        FullPath: Text;
        ElementName: Text;
    begin
        XMLSchemaElement.SetRange("XML Schema Code", XMLSchema.Code);
        XMLSchemaElement.SetRange(Selected, true);
        XMLSchemaElement.FindSet();

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        if not DataExchLineDef.FindFirst() then begin
            DataExchLineDef.InsertRec(DataExchDef.Code, DataExchDef.Code, DataExchDef.Name, 0);
            DataExchLineDef."Data Line Tag" := SEPACAMTDataLineTagTok;
            DataExchLineDef.Modify();
        end;

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.DeleteAll(true);

        SchemaContext := XMLSchema.GetSchemaContext();
        repeat
            if XMLSchemaElement.IsLeaf() then begin
                ColumnNo += 1;
                FullPath := XMLSchemaElement.GetFullPath();
                ElementName := FullPath;
                if StrPos(FullPath, SchemaContext) > 0 then
                    ElementName := DelStr(FullPath, StrPos(FullPath, SchemaContext), StrLen(SchemaContext));
                DataExchColumnDef.InsertRecordForImport(
                    DataExchDef.Code, DataExchLineDef.Code,
                    ColumnNo, CopyStr(ElementName, 1, MaxStrLen(DataExchColumnDef.Name)),
                    CopyStr(XMLSchemaElement."Node Name", 1, MaxStrLen(DataExchColumnDef.Description)), true,
                    DataExchColumnDef."Data Type"::Text, '', '');
                DataExchColumnDef.SetXMLDataFormattingValues(XMLSchemaElement."Simple Data Type");
                DataExchColumnDef.Path := CopyStr(FullPath, 1, MaxStrLen(DataExchColumnDef.Path));
                DataExchColumnDef.Modify();
            end;
        until XMLSchemaElement.Next() = 0;
    end;

    local procedure PushDefinitionOnStack(var TempDefinitionXMLSchemaElement: Record "XML Schema Element" temporary)
    var
        LastID: Integer;
    begin
        TempStackXMLSchemaElement.Reset();
        TempStackXMLSchemaElement.SetCurrentKey(ID);
        if TempStackXMLSchemaElement.FindLast() then
            LastID := TempStackXMLSchemaElement.ID
        else
            LastID := 1;

        TempStackXMLSchemaElement.Copy(TempDefinitionXMLSchemaElement);
        TempStackXMLSchemaElement.ID := LastID + 1;
        TempStackXMLSchemaElement.Insert();
    end;

    local procedure PopDefinitionFromStack(var TempCurrentDefinitionXMLSchemaElement: Record "XML Schema Element" temporary)
    begin
        TempStackXMLSchemaElement.Reset();
        TempStackXMLSchemaElement.SetRange("XML Schema Code", TempCurrentDefinitionXMLSchemaElement."XML Schema Code");
        TempStackXMLSchemaElement.SetRange("Node Name", TempCurrentDefinitionXMLSchemaElement."Node Name");
        TempStackXMLSchemaElement.SetRange("Node Type", TempCurrentDefinitionXMLSchemaElement."Node Type");
        TempStackXMLSchemaElement.SetRange("Data Type", TempCurrentDefinitionXMLSchemaElement."Data Type");
        TempStackXMLSchemaElement.SetCurrentKey(ID);
        TempStackXMLSchemaElement.FindLast();
        TempStackXMLSchemaElement.Delete();
    end;

    local procedure DetectDefinitionLoop(var TempCurrentDefinitionXMLSchemaElement: Record "XML Schema Element" temporary): Boolean
    begin
        TempStackXMLSchemaElement.Reset();
        TempStackXMLSchemaElement.SetRange("XML Schema Code", TempCurrentDefinitionXMLSchemaElement."XML Schema Code");
        TempStackXMLSchemaElement.SetRange("Node Name", TempCurrentDefinitionXMLSchemaElement."Node Name");
        TempStackXMLSchemaElement.SetRange("Node Type", TempCurrentDefinitionXMLSchemaElement."Node Type");
        TempStackXMLSchemaElement.SetRange("Data Type", TempCurrentDefinitionXMLSchemaElement."Data Type");
        exit(TempStackXMLSchemaElement.FindFirst());
    end;

    local procedure InitializeTempBuffers(XMLSchema: Record "XML Schema")
    var
        XMLSchemaElement: Record "XML Schema Element";
        XMLSchemaRestriction: Record "XML Schema Restriction";
        MainDefinitionSchemaCode: Code[20];
    begin
        MainDefinitionSchemaCode := StrSubstNo('%1:1000', XMLSchema.Code);

        TempAllXMLSchemaElement.Reset();
        TempAllXMLSchemaElement.DeleteAll();

        TempStackXMLSchemaElement.Reset();
        TempStackXMLSchemaElement.DeleteAll();

        XMLSchemaElement.SetFilter("XML Schema Code", StrSubstNo('%1:*', XMLSchema.Code));

        if XMLSchemaElement.FindSet() then
            repeat
                TempAllXMLSchemaElement.Copy(XMLSchemaElement);
                if TempAllXMLSchemaElement."XML Schema Code" = MainDefinitionSchemaCode then
                    TempAllXMLSchemaElement."XML Schema Code" := XMLSchema.Code;
                TempAllXMLSchemaElement.Insert();
            until XMLSchemaElement.Next() = 0;

        TempXMLSchemaRestriction.Reset();
        TempXMLSchemaRestriction.DeleteAll();

        XMLSchemaRestriction.SetFilter("XML Schema Code", StrSubstNo('%1:*', XMLSchema.Code));

        if XMLSchemaRestriction.FindSet() then
            repeat
                TempXMLSchemaRestriction.Copy(XMLSchemaRestriction);
                if TempXMLSchemaRestriction."XML Schema Code" = MainDefinitionSchemaCode then
                    TempXMLSchemaRestriction."XML Schema Code" := XMLSchema.Code;
                TempXMLSchemaRestriction.Insert();
            until XMLSchemaRestriction.Next() = 0;
    end;
}

