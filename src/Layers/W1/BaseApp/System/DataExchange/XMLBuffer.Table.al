namespace System.IO;

using System.Reflection;
using System.Utilities;

table 1235 "XML Buffer"
{
    Caption = 'XML Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Element,Attribute,Processing Instruction';
            OptionMembers = " ",Element,Attribute,"Processing Instruction";
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(4; Path; Text[250])
        {
            Caption = 'Path';
            DataClassification = SystemMetadata;
        }
        field(5; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
        field(6; Depth; Integer)
        {
            Caption = 'Depth';
            DataClassification = SystemMetadata;
        }
        field(7; "Parent Entry No."; Integer)
        {
            Caption = 'Parent Entry No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Data Type"; Option)
        {
            Caption = 'Data Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Text,Date,Decimal,DateTime';
            OptionMembers = Text,Date,Decimal,DateTime;
        }
        field(13; "Node Number"; Integer)
        {
            Caption = 'Node Number';
            DataClassification = SystemMetadata;
        }
        field(14; Namespace; Text[250])
        {
            Caption = 'Namespace';
            DataClassification = SystemMetadata;
        }
        field(15; "Import ID"; Guid)
        {
            Caption = 'Import ID';
            DataClassification = SystemMetadata;
        }
        field(16; "Value BLOB"; BLOB)
        {
            Caption = 'Value BLOB';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Parent Entry No.", Type, "Node Number")
        {
        }
        key(Key3; "Import ID")
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Load(StreamOrServerFile: Variant)
    var
        XMLBufferWriter: Codeunit "XML Buffer Writer";
    begin
        XMLBufferWriter.InitializeXMLBufferFrom(Rec, StreamOrServerFile);
    end;

    procedure LoadFromStream(XmlStream: InStream)
    var
        XMLBufferWriter: Codeunit "XML Buffer Writer";
    begin
        XMLBufferWriter.InitializeXMLBufferFromStream(Rec, XmlStream);
    end;

    procedure ReadFromBlob(BlobFieldRef: FieldRef)
    var
        TypeHelper: Codeunit "Type Helper";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromRecordRef(BlobFieldRef.Record(), BlobFieldRef.Number);
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        LoadFromText(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator()));
    end;

    procedure LoadFromText(XmlText: Text)
    var
        XMLBufferWriter: Codeunit "XML Buffer Writer";
    begin
        XMLBufferWriter.InitializeXMLBufferFromText(Rec, XmlText);
    end;

    [Scope('OnPrem')]
    procedure Upload(): Boolean
    var
        FileManagement: Codeunit "File Management";
        ServerTempFileName: Text;
    begin
        ServerTempFileName := FileManagement.UploadFile('', '*.xml');
        if ServerTempFileName = '' then
            exit(false);
        Load(ServerTempFileName);
        FileManagement.DeleteServerFile(ServerTempFileName);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure Save(ServerFilePath: Text): Boolean
    var
        XMLBufferReader: Codeunit "XML Buffer Reader";
    begin
        exit(XMLBufferReader.SaveToFile(ServerFilePath, Rec));
    end;

    procedure Save(var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        XMLBufferReader: Codeunit "XML Buffer Reader";
    begin
        exit(XMLBufferReader.SaveToTempBlob(TempBlob, Rec));
    end;

    [Scope('OnPrem')]
    procedure Download() Success: Boolean
    var
        FileManagement: Codeunit "File Management";
        ServerTempFileName: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDownload(Rec, Success, IsHandled);
        if IsHandled then
            exit;

        ServerTempFileName := FileManagement.ServerTempFileName('xml');
        Save(ServerTempFileName);
        Success := FileManagement.DownloadHandler(ServerTempFileName, '', '', '', 'temp.xml');
        FileManagement.DeleteServerFile(ServerTempFileName);
    end;

    procedure CreateRootElement(ElementName: Text[250])
    var
        XMLBufferWriter: Codeunit "XML Buffer Writer";
    begin
        XMLBufferWriter.InsertElement(Rec, Rec, 1, 1, ElementName, '');
    end;

    procedure AddNamespace(NamespacePrefix: Text[244]; NamespacePath: Text[250])
    begin
        if NamespacePrefix = '' then
            AddAttribute('xmlns', NamespacePath)
        else
            AddAttribute('xmlns:' + NamespacePrefix, NamespacePath);
    end;

    procedure AddProcessingInstruction(InstructionName: Text[250]; InstructionValue: Text)
    var
        XMLBufferWriter: Codeunit "XML Buffer Writer";
    begin
        XMLBufferWriter.InsertProcessingInstruction(Rec, Rec, CountProcessingInstructions() + 1, Depth + 1, InstructionName, InstructionValue);
        GetParent();
    end;

    procedure AddAttribute(AttributeName: Text[250]; AttributeValue: Text)
    var
        XMLBufferWriter: Codeunit "XML Buffer Writer";
    begin
        XMLBufferWriter.InsertAttribute(Rec, Rec, CountAttributes() + 1, Depth + 1, AttributeName, AttributeValue);
        GetParent();
    end;

    procedure AddAttributeWithNamespace(AttributeNameWithNamespace: Text[250]; AttributeValue: Text)
    var
        XMLBufferWriter: Codeunit "XML Buffer Writer";
    begin
        XMLBufferWriter.InsertAttributeWithNamespace(Rec, Rec, CountAttributes() + 1, Depth + 1, AttributeNameWithNamespace, AttributeValue);
        GetParent();
    end;

    procedure AddGroupElement(ElementNameWithNamespace: Text[250]): Integer
    var
        XMLBufferWriter: Codeunit "XML Buffer Writer";
    begin
        XMLBufferWriter.InsertElement(Rec, Rec, CountChildElements() + 1, Depth + 1, ElementNameWithNamespace, '');
        exit("Entry No.");
    end;

    procedure AddGroupElementAt(ElementNameWithNamespace: Text[250]; EntryNo: Integer): Integer
    var
        XMLBufferWriter: Codeunit "XML Buffer Writer";
        CurrentView: Text;
        ElementNo: Integer;
    begin
        CurrentView := GetView();
        Get(EntryNo);
        ElementNo := "Node Number";
        Reset();
        SetRange("Parent Entry No.", "Parent Entry No.");
        SetFilter("Node Number", '>=%1', ElementNo);
        if FindSet(true) then
            repeat
                "Node Number" += 1;
                Modify();
            until Next() = 0;
        Get("Parent Entry No.");
        XMLBufferWriter.InsertElement(Rec, Rec, ElementNo, Depth + 1, ElementNameWithNamespace, '');
        SetView(CurrentView);
        exit("Entry No.");
    end;

    procedure AddElement(ElementNameWithNamespace: Text[250]; ElementValue: Text) ElementEntryNo: Integer
    begin
        ElementEntryNo := AddGroupElement(ElementNameWithNamespace);
        SetValueWithoutModifying(ElementValue);
        Modify(true);
        GetParent();
    end;

    procedure AddLastElement(ElementNameWithNamespace: Text[250]; ElementValue: Text) ElementEntryNo: Integer
    begin
        ElementEntryNo := AddElement(ElementNameWithNamespace, ElementValue);
        GetParent();
    end;

    procedure AddNonEmptyElement(ElementNameWithNamespace: Text[250]; ElementValue: Text) ElementEntryNo: Integer
    begin
        if ElementValue = '' then
            exit;
        ElementEntryNo := AddElement(ElementNameWithNamespace, ElementValue);
    end;

    procedure AddNonEmptyLastElement(ElementNameWithNamespace: Text[250]; ElementValue: Text) ElementEntryNo: Integer
    begin
        ElementEntryNo := AddNonEmptyElement(ElementNameWithNamespace, ElementValue);
        GetParent();
    end;

    procedure CopyImportFrom(var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        XMLBuffer: Record "XML Buffer";
    begin
        if TempXMLBuffer.IsTemporary then
            Copy(TempXMLBuffer, true)
        else begin
            XMLBuffer.SetRange("Import ID", TempXMLBuffer."Import ID");
            if XMLBuffer.FindSet() then
                repeat
                    Rec := XMLBuffer;
                    Insert();
                until XMLBuffer.Next() = 0;
            SetView(TempXMLBuffer.GetView());
        end;
    end;

    procedure CountChildElements() NumElements: Integer
    var
        CurrentView: Text;
    begin
        CurrentView := GetView();
        Reset();
        SetRange("Parent Entry No.", "Entry No.");
        SetRange(Type, Type::Element);
        NumElements := Count;
        SetView(CurrentView);
    end;

    procedure CountAttributes() NumAttributes: Integer
    var
        CurrentView: Text;
    begin
        CurrentView := GetView();
        Reset();
        SetRange("Parent Entry No.", "Entry No.");
        SetRange(Type, Type::Attribute);
        NumAttributes := Count;
        SetView(CurrentView);
    end;

    procedure CountProcessingInstructions() NumElements: Integer
    var
        CurrentView: Text;
    begin
        CurrentView := GetView();
        Reset();
        SetRange("Parent Entry No.", "Entry No.");
        SetRange(Type, Type::"Processing Instruction");
        NumElements := Count;
        SetView(CurrentView);
    end;

    procedure FindProcessingInstructions(var TempXMLBuffer: Record "XML Buffer" temporary): Boolean
    begin
        exit(FindChildNodes(TempXMLBuffer, Type::"Processing Instruction", ''));
    end;

    procedure FindAttributes(var TempResultAttributeXMLBuffer: Record "XML Buffer" temporary): Boolean
    begin
        exit(FindChildNodes(TempResultAttributeXMLBuffer, Type::Attribute, ''));
    end;

    procedure FindChildElements(var TempResultElementXMLBuffer: Record "XML Buffer" temporary): Boolean
    begin
        exit(FindChildNodes(TempResultElementXMLBuffer, Type::Element, ''));
    end;

    procedure FindNodesByXPath(var TempResultElementXMLBuffer: Record "XML Buffer" temporary; XPath: Text): Boolean
    begin
        TempResultElementXMLBuffer.CopyImportFrom(Rec);

        TempResultElementXMLBuffer.SetRange("Import ID", "Import ID");
        TempResultElementXMLBuffer.SetRange("Parent Entry No.");
        TempResultElementXMLBuffer.SetFilter(Path, '*' + XPath);
        exit(TempResultElementXMLBuffer.FindSet());
    end;

#if not CLEAN26
    [Obsolete('Replaced by GetAttributeValueAsText with unlimited text length on return type.', '26.0')]
    procedure GetAttributeValue(AttributeName: Text): Text[250]
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        if FindChildNodes(TempXMLBuffer, Type::Attribute, AttributeName) then
            exit(CopyStr(TempXMLBuffer.GetValue(), 1, 250));
    end;
#endif
    procedure GetAttributeValueAsText(AttributeName: Text): Text
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        if FindChildNodes(TempXMLBuffer, Type::Attribute, AttributeName) then
            exit(TempXMLBuffer.GetValue());
    end;

#if not CLEAN26
    [Obsolete('Replaced by GetNamespaceUriByPrefixAsText with increased text length on return type.', '26.0')]
    procedure GetNamespaceUriByPrefix(NamespacePrefix: Text): Text[250]
    var
        TempResultXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempResultXMLBuffer.CopyImportFrom(Rec);

        TempResultXMLBuffer.SetRange("Parent Entry No.");
        TempResultXMLBuffer.SetRange(Type, TempResultXMLBuffer.Type::Attribute);
        TempResultXMLBuffer.SetRange(Name, 'xmlns:' + NamespacePrefix);
        if TempResultXMLBuffer.FindFirst() then
            exit(CopyStr(TempResultXMLBuffer.GetValue(), 1, 250));
    end;
#endif

    procedure GetNamespaceUriByPrefixAsText(NamespacePrefix: Text): Text
    var
        TempResultXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempResultXMLBuffer.CopyImportFrom(Rec);

        TempResultXMLBuffer.SetRange("Parent Entry No.");
        TempResultXMLBuffer.SetRange(Type, TempResultXMLBuffer.Type::Attribute);
        TempResultXMLBuffer.SetRange(Name, 'xmlns:' + NamespacePrefix);
        if TempResultXMLBuffer.FindFirst() then
            exit(TempResultXMLBuffer.GetValue());
    end;

    procedure GetElementName(): Text
    begin
        if Namespace = '' then
            exit(Name);
        exit(Namespace + ':' + Name);
    end;

    procedure GetParent(): Boolean
    begin
        exit(Get("Parent Entry No."))
    end;

    procedure HasChildNodes() ChildNodesExists: Boolean
    var
        CurrentView: Text;
    begin
        CurrentView := GetView();
        Reset();
        SetRange("Parent Entry No.", "Entry No.");
        ChildNodesExists := not IsEmpty();
        SetView(CurrentView);
    end;

    local procedure FindChildNodes(var TempResultXMLBuffer: Record "XML Buffer" temporary; NodeType: Option; NodeName: Text): Boolean
    begin
        TempResultXMLBuffer.CopyImportFrom(Rec);

        TempResultXMLBuffer.SetRange("Parent Entry No.", "Entry No.");
        TempResultXMLBuffer.SetRange(Path);
        TempResultXMLBuffer.SetRange(Type, NodeType);
        if NodeName <> '' then
            TempResultXMLBuffer.SetRange(Name, NodeName);
        exit(TempResultXMLBuffer.FindSet());
    end;

    procedure GetValue(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Value BLOB");
        if not "Value BLOB".HasValue() then
            exit(Value);

        "Value BLOB".CreateInStream(InStream, TEXTENCODING::Windows);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    local procedure NormalizeElementValue(var ElementValue: Text)
    begin
        OnNormalizeElementValue(ElementValue);
    end;

    procedure SetValue(NewValue: Text)
    begin
        SetValueWithoutModifying(NewValue);
        Modify();
    end;

    procedure SetValueWithoutModifying(NewValue: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Value BLOB");
        NormalizeElementValue(NewValue);
        Rec.Value := CopyStr(NewValue, 1, MaxStrLen(Rec.Value));
        OnSetValueWithoutModifyingOnAfterAssignValue(Rec, NewValue);
        if StrLen(NewValue) <= MaxStrLen(Value) then
            exit; // No need to store anything in the blob
        if NewValue = '' then
            exit;
        "Value BLOB".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(NewValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownload(var XMLBuffer: Record "XML Buffer"; var Success: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNormalizeElementValue(var ElementValue: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetValueWithoutModifyingOnAfterAssignValue(var XMLBuffer: Record "XML Buffer"; NewValue: Text)
    begin
    end;
}
