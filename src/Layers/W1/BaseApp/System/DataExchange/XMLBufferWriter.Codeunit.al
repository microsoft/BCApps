namespace System.IO;

using System;

codeunit 1235 "XML Buffer Writer"
{

    trigger OnRun()
    begin
    end;

    var
        GetJsonStructure: Codeunit "Get Json Structure";
        XmlReader: DotNet XmlReader;
        XmlReaderSettings: DotNet XmlReaderSettings;
        XmlUrlResolver: DotNet XmlUrlResolver;
        XmlDtdProcessing: DotNet DtdProcessing;
        XmlNodeType: DotNet XmlNodeType;
        NetCredentialCache: DotNet CredentialCache;
        StringReader: DotNet StringReader;
        OnlyGenerateStructure: Boolean;
        UnsupportedInputTypeErr: Label 'The supplied variable type is not supported.';

    [Scope('OnPrem')]
    procedure InitializeXMLBufferFrom(var XMLBuffer: Record "XML Buffer"; StreamOrServerFile: Variant)
    begin
        OnlyGenerateStructure := false;
        InitializeXMLReaderSettings();
        CreateXMLReaderFrom(StreamOrServerFile);
        ReadXmlReader();
        ParseXML(XMLBuffer);
    end;

    procedure InitializeXMLBufferFromStream(var XMLBuffer: Record "XML Buffer"; XmlStream: InStream)
    begin
        OnlyGenerateStructure := false;
        InitializeXMLReaderSettings();
        CreateXMLReaderFromInStream(XmlStream);
        ReadXmlReader();
        ParseXML(XMLBuffer);
    end;

    procedure InitializeXMLBufferFromText(var XMLBuffer: Record "XML Buffer"; XmlText: Text)
    begin
        InitializeXMLReaderSettings();
        CreateXmlReaderFromXmlText(XmlText);
        ReadXmlReader();
        ParseXML(XMLBuffer);
    end;

    [Scope('OnPrem')]
    procedure GenerateStructureFromPath(var XMLBuffer: Record "XML Buffer"; Path: Text)
    begin
        OnlyGenerateStructure := true;
        InitializeXMLReaderSettings();
        CreateXMLReaderFromPath(Path);
        if ReadXmlReader() then
            ParseXML(XMLBuffer)
        else
            GetJsonStructure.GenerateStructure(Path, XMLBuffer);
    end;

    procedure GenerateStructure(var XMLBuffer: Record "XML Buffer"; OutStream: OutStream)
    begin
        InitializeXMLReaderSettings();
        CreateXMLReaderFromOutStream(OutStream);
        ReadXmlReader();
        ParseXML(XMLBuffer);
    end;

    local procedure CreateXMLReaderFrom(StreamOrServerFile: Variant)
    begin
        case true of
            StreamOrServerFile.IsText:
                CreateXMLReaderFromPath(StreamOrServerFile);
            StreamOrServerFile.IsInStream:
                CreateXMLReaderFromInStream(StreamOrServerFile);
            StreamOrServerFile.IsOutStream:
                CreateXMLReaderFromOutStream(StreamOrServerFile);
            else
                Error(UnsupportedInputTypeErr);
        end;
    end;

    local procedure CreateXMLReaderFromPath(Path: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.IsAllowedPath(Path, false);
        XmlReader := XmlReader.Create(Path, XmlReaderSettings);
    end;

    local procedure CreateXMLReaderFromInStream(InStream: InStream)
    begin
        XmlReader := XmlReader.Create(InStream, XmlReaderSettings);
    end;

    local procedure CreateXMLReaderFromOutStream(OutStream: OutStream)
    begin
        XmlReader := XmlReader.Create(OutStream, XmlReaderSettings);
    end;

    local procedure CreateXmlReaderFromXmlText(XmlText: Text)
    begin
        StringReader := StringReader.StringReader(XmlText);
        XmlReader := XmlReader.Create(StringReader, XmlReaderSettings);
    end;

    local procedure InitializeXMLReaderSettings()
    begin
        XmlUrlResolver := XmlUrlResolver.XmlUrlResolver();
        XmlUrlResolver.Credentials := NetCredentialCache.DefaultNetworkCredentials;

        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings();
        XmlReaderSettings.DtdProcessing := XmlDtdProcessing.Ignore;
        XmlReaderSettings.XmlResolver := XmlUrlResolver;
    end;

    local procedure ParseXML(var XMLBuffer: Record "XML Buffer")
    var
        ParentXMLBuffer: Record "XML Buffer";
    begin
        if XMLBuffer.FindLast() then;

        ParentXMLBuffer.Init();
        ParseXMLIteratively(XMLBuffer, ParentXMLBuffer);

        XmlReader.Close();
        XMLBuffer.Reset();
        XMLBuffer.SetRange("Import ID", XMLBuffer."Import ID");
        XMLBuffer.FindFirst();
    end;

    local procedure ParseXMLIteratively(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer")
    var
        LastInsertedXMLBufferElement: Record "XML Buffer";
        ElementNumber: Integer;
        Depth: Integer;
        ProcessingInstructionNumber: Integer;
    begin
        Depth := XmlReader.Depth;
        repeat
            if IsParentElement(Depth) then
                exit;
            ParseCurrentXmlNode(XMLBuffer, ParentXMLBuffer, LastInsertedXMLBufferElement, ElementNumber, Depth, ProcessingInstructionNumber);
        until not XmlReader.Read();
    end;

    local procedure ParseCurrentXmlNode(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; var LastInsertedXMLBufferElement: Record "XML Buffer"; var ElementNumber: Integer; Depth: Integer; var ProcessingInstructionNumber: Integer)
    begin
        if IsParentElement(Depth) then
            exit;
        if IsChildElement(Depth) then begin
            ParseXMLIteratively(XMLBuffer, LastInsertedXMLBufferElement);
            ParseCurrentXmlNode(XMLBuffer, ParentXMLBuffer, LastInsertedXMLBufferElement, ElementNumber, Depth, ProcessingInstructionNumber);
        end else
            ReadAndInsertXmlElement(XMLBuffer, ParentXMLBuffer, ElementNumber, LastInsertedXMLBufferElement, ProcessingInstructionNumber);
    end;

    local procedure IsChildElement(CurrentDepth: Integer): Boolean
    begin
        exit(XmlReader.Depth > CurrentDepth)
    end;

    local procedure IsParentElement(CurrentDepth: Integer): Boolean
    begin
        exit(XmlReader.Depth < CurrentDepth)
    end;

    local procedure ReadAndInsertXmlElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; var ElementNumber: Integer; var InsertedXMLBufferElement: Record "XML Buffer"; var ProcessingInstructionNumber: Integer)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        XmlNodeType := XmlReader.NodeType;
        if XmlNodeType.Equals(XmlNodeType.Element) then begin
            ElementNumber += 1;
            ProcessXmlElement(XMLBuffer, ParentXMLBuffer, ElementNumber, InsertedXMLBufferElement)
        end else
            if XmlNodeType.Equals(XmlNodeType.Text) then begin
                if XMLBuffer.IsTemporary then begin
                    TempXMLBuffer.Copy(XMLBuffer, true);
                    TempXMLBuffer := ParentXMLBuffer;
                    AddXmlTextNodeIntoParentXMLBuffer(TempXMLBuffer);
                end else
                    AddXmlTextNodeIntoParentXMLBuffer(ParentXMLBuffer);
            end else
                if XmlNodeType.Equals(XmlNodeType.ProcessingInstruction) then begin
                    ProcessingInstructionNumber += 1;
                    InsertXmlProcessingInstruction(XMLBuffer, ParentXMLBuffer, ProcessingInstructionNumber)
                end else
                    if XmlNodeType.Equals(XmlNodeType.XmlDeclaration) or
                       XmlNodeType.Equals(XmlNodeType.Comment)
                    then
                        ;

        OnAfterReadAndInsertXmlElement(XMLBuffer, ParentXMLBuffer, ElementNumber, InsertedXMLBufferElement, ProcessingInstructionNumber);
    end;

    local procedure ProcessXmlElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ElementNumber: Integer; var InsertedXMLBufferElement: Record "XML Buffer")
    var
        AttributeNumber: Integer;
    begin
        InsertXmlElement(XMLBuffer, ParentXMLBuffer, ElementNumber);
        InsertedXMLBufferElement := XMLBuffer;

        if XmlReader.MoveToFirstAttribute() then
            repeat
                AttributeNumber += 1;
                InsertXmlAttribute(XMLBuffer, InsertedXMLBufferElement, AttributeNumber);
            until not XmlReader.MoveToNextAttribute();
    end;

    local procedure InsertXmlElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ElementNumber: Integer)
    begin
        if OnlyGenerateStructure then begin
            XMLBuffer.Reset();
            XMLBuffer.SetRange("Parent Entry No.", ParentXMLBuffer."Entry No.");
            XMLBuffer.SetRange(Type, XMLBuffer.Type::Element);
            XMLBuffer.SetRange(Name, XmlReader.Name);
            if XMLBuffer.FindFirst() then
                exit;
        end;

        InsertElement(XMLBuffer, ParentXMLBuffer, ElementNumber, XmlReader.Depth + 1, XmlReader.Name, '');
    end;

    local procedure InsertXmlAttribute(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; AttributeNumber: Integer)
    begin
        if OnlyGenerateStructure then begin
            XMLBuffer.Reset();
            XMLBuffer.SetRange("Parent Entry No.", ParentXMLBuffer."Entry No.");
            XMLBuffer.SetRange(Type, XMLBuffer.Type::Attribute);
            XMLBuffer.SetRange(Name, XmlReader.Name);
            if XMLBuffer.FindFirst() then
                exit;
        end;
#if not CLEAN26
        if CanPassValue(XmlReader.Name, XmlReader.Value) then
#endif
            InsertAttribute(XMLBuffer, ParentXMLBuffer, AttributeNumber, XmlReader.Depth + 1, XmlReader.Name, XmlReader.Value);
    end;

    local procedure InsertXmlProcessingInstruction(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ProcessingInstructionNumber: Integer)
    begin
        if OnlyGenerateStructure then begin
            XMLBuffer.Reset();
            XMLBuffer.SetRange("Parent Entry No.", ParentXMLBuffer."Entry No.");
            XMLBuffer.SetRange(Type, XMLBuffer.Type::"Processing Instruction");
            XMLBuffer.SetRange(Name, XmlReader.Name);
            if XMLBuffer.FindFirst() then
                exit;
        end;

        InsertProcessingInstruction(XMLBuffer, ParentXMLBuffer, ProcessingInstructionNumber, XmlReader.Depth + 1
          , XmlReader.Name, XmlReader.Value);
    end;

    local procedure GetType(Value: Text): Integer
    var
        DummyXMLBuffer: Record "XML Buffer";
        Decimal: Decimal;
    begin
        if Value = '' then
            exit(DummyXMLBuffer."Data Type"::Text);

        if Evaluate(Decimal, Value) then
            exit(DummyXMLBuffer."Data Type"::Decimal);

        exit(DummyXMLBuffer."Data Type"::Text)
    end;

    local procedure AddXmlTextNodeIntoParentXMLBuffer(var XMLBuffer: Record "XML Buffer")
    begin
        if XMLBuffer.Value <> '' then
            exit;

        XMLBuffer.SetValueWithoutModifying(XmlReader.Value);
        XMLBuffer.Validate("Data Type", GetType(XMLBuffer.Value));
        XMLBuffer.Modify();
    end;

    procedure InsertAttribute(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; NodeNumber: Integer; NodeDepth: Integer; AttributeName: Text; AttributeValue: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertAttribute(XMLBuffer, ParentXMLBuffer, NodeNumber, NodeDepth, AttributeName, AttributeValue, IsHandled);
        if IsHandled then
            exit;

        XMLBuffer.Reset();
        if XMLBuffer.FindLast() then;
        XMLBuffer.Init();
        XMLBuffer."Entry No." += 1;
        XMLBuffer."Parent Entry No." := ParentXMLBuffer."Entry No.";
        XMLBuffer.Path := CopyStr(ParentXMLBuffer.Path + '/@' + AttributeName, 1, MaxStrLen(XMLBuffer.Path));
        XMLBuffer."Node Number" := NodeNumber;
        XMLBuffer.Name := AttributeName;
        XMLBuffer.SetValueWithoutModifying(AttributeValue);
        XMLBuffer.Depth := NodeDepth;
        XMLBuffer."Data Type" := GetType(XMLBuffer.Value);
        XMLBuffer.Type := XMLBuffer.Type::Attribute;
        XMLBuffer."Import ID" := ParentXMLBuffer."Import ID";

        XMLBuffer.Insert();
    end;

    procedure InsertAttributeWithNamespace(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; NodeNumber: Integer; NodeDepth: Integer; AttributeNameWithNamespace: Text; AttributeValue: Text)
    var
        AttributeName: Text;
        AttributeNamespace: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertAttributeWithNamespace(XMLBuffer, ParentXMLBuffer, NodeNumber, NodeDepth, AttributeNameWithNamespace, AttributeValue, IsHandled);
        if IsHandled then
            exit;

        SplitXmlElementName(AttributeNameWithNamespace, AttributeName, AttributeNamespace);

        XMLBuffer.Reset();
        if XMLBuffer.FindLast() then;
        XMLBuffer.Init();
        XMLBuffer."Entry No." += 1;
        XMLBuffer."Parent Entry No." := ParentXMLBuffer."Entry No.";
        XMLBuffer.Path := CopyStr(ParentXMLBuffer.Path + '/@' + AttributeNameWithNamespace, 1, MaxStrLen(XMLBuffer.Path));
        XMLBuffer."Node Number" := NodeNumber;
        XMLBuffer.Name := CopyStr(AttributeName, 1, MaxStrLen(XMLBuffer.Name));
        XMLBuffer.Namespace := CopyStr(AttributeNamespace, 1, MaxStrLen(XMLBuffer.Namespace));
        XMLBuffer.SetValueWithoutModifying(AttributeValue);
        XMLBuffer.Depth := NodeDepth;
        XMLBuffer."Data Type" := GetType(XMLBuffer.Value);
        XMLBuffer.Type := XMLBuffer.Type::Attribute;
        XMLBuffer."Import ID" := ParentXMLBuffer."Import ID";

        XMLBuffer.Insert();
    end;

    procedure InsertElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ElementNumber: Integer; ElementDepth: Integer; ElementNameAndNamespace: Text; ElementValue: Text)
    var
        ElementName: Text;
        ElementNamespace: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertElement(XMLBuffer, ParentXMLBuffer, ElementNumber, ElementDepth, ElementNameAndNamespace, ElementValue, IsHandled);
        if IsHandled then
            exit;

        SplitXmlElementName(ElementNameAndNamespace, ElementName, ElementNamespace);

        if IsNullGuid(ParentXMLBuffer."Import ID") then
            ParentXMLBuffer."Import ID" := CreateGuid();

        XMLBuffer.Reset();
        if XMLBuffer.FindLast() then;
        XMLBuffer.Init();
        XMLBuffer."Entry No." += 1;
        XMLBuffer."Parent Entry No." := ParentXMLBuffer."Entry No.";
        XMLBuffer.Path := CopyStr(StrSubstNo('%1/%2', ParentXMLBuffer.Path, ElementNameAndNamespace), 1, MaxStrLen(XMLBuffer.Path));
        XMLBuffer."Node Number" := ElementNumber;
        XMLBuffer.Depth := ElementDepth;
        XMLBuffer.Name := CopyStr(ElementName, 1, MaxStrLen(XMLBuffer.Name));
        XMLBuffer.SetValueWithoutModifying(ElementValue);
        XMLBuffer.Type := XMLBuffer.Type::Element;
        XMLBuffer.Namespace := CopyStr(ElementNamespace, 1, MaxStrLen(XMLBuffer.Namespace));
        XMLBuffer."Import ID" := ParentXMLBuffer."Import ID";

        OnInsertElementOnBeforeInsertXMLBuffer(XMLBuffer, ParentXMLBuffer, ElementNumber, ElementDepth, ElementNameAndNamespace, ElementValue);
        XMLBuffer.Insert();
    end;

    procedure InsertProcessingInstruction(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; NodeNumber: Integer; NodeDepth: Integer; InstructionName: Text; InstructionValue: Text)
    begin
        XMLBuffer.Reset();
        if XMLBuffer.FindLast() then;
        XMLBuffer.Init();
        XMLBuffer."Entry No." += 1;
        XMLBuffer."Parent Entry No." := ParentXMLBuffer."Entry No.";
        XMLBuffer.Path := CopyStr(ParentXMLBuffer.Path + '/processing-instruction(''' + InstructionName + ''')', 1, MaxStrLen(XMLBuffer.Path));
        XMLBuffer."Node Number" := NodeNumber;
        XMLBuffer.Depth := NodeDepth;
        XMLBuffer.Name := CopyStr(InstructionName, 1, MaxStrLen(XMLBuffer.Name));
        XMLBuffer.SetValueWithoutModifying(InstructionValue);
        XMLBuffer.Type := XMLBuffer.Type::"Processing Instruction";
        XMLBuffer."Import ID" := ParentXMLBuffer."Import ID";

        XMLBuffer.Insert();
    end;

    local procedure SplitXmlElementName(RawXmlElementName: Text; var ElementName: Text; var ElementNamespace: Text)
    var
        ColonPosition: Integer;
    begin
        ColonPosition := StrPos(RawXmlElementName, ':');
        if ColonPosition <> 0 then begin
            ElementNamespace := CopyStr(RawXmlElementName, 1, ColonPosition - 1);
            ElementName := CopyStr(RawXmlElementName, ColonPosition + 1);
        end else begin
            ElementName := RawXmlElementName;
            ElementNamespace := '';
        end;
    end;

    [TryFunction]
    local procedure ReadXmlReader()
    begin
        XmlReader.Read();
    end;

#if not CLEAN26
    local procedure CanPassValue(Name: Text; Value: Text): Boolean
    var
        ReturnValue: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCanPassValue(Name, Value, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);
        exit(true);
    end;

    [Obsolete('This event is obsolete and will be removed in a future release. There is no replacement.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanPassValue(Name: Text; var Value: Text; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAttribute(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; NodeNumber: Integer; NodeDepth: Integer; var AttributeName: Text; var AttributeValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAttributeWithNamespace(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; NodeNumber: Integer; NodeDepth: Integer; var AttributeNameWithNamespace: Text; var AttributeValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ElementNumber: Integer; ElementDepth: Integer; var ElementNameAndNamespace: Text; var ElementValue: Text; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertElementOnBeforeInsertXMLBuffer(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ElementNumber: Integer; ElementDepth: Integer; var ElementNameAndNamespace: Text; var ElementValue: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReadAndInsertXmlElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; var ElementNumber: Integer; var InsertedXMLBufferElement: Record "XML Buffer"; var ProcessingInstructionNumber: Integer);
    begin
    end;
}

