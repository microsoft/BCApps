namespace System.Xml;

using System.IO;
using System.Utilities;

table 9600 "XML Schema"
{
    Caption = 'XML Schema';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "XML Schemas";
    LookupPageID = "XML Schemas";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(3; "Target Namespace"; Text[250])
        {
            Caption = 'Target Namespace';
        }
        field(4; XSD; BLOB)
        {
            Caption = 'XSD';
        }
        field(6; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(7; Path; Text[250])
        {
            Caption = 'Path';
        }
        field(10; "Target Namespace Aliases"; Text[250])
        {
            Caption = 'Target Namespace Aliases';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        XMLSchemaElement: Record "XML Schema Element";
        XMLSchemaRestriction: Record "XML Schema Restriction";
        ChildXMLSchema: Record "XML Schema";
        ReferencedXMLSchema: Record "Referenced XML Schema";
        TopSchemaCode: Code[20];
    begin
        if Indentation > 0 then
            TopSchemaCode := GetTopSchemaCode(Rec)
        else
            TopSchemaCode := Code;

        ReferencedXMLSchema.SetFilter(Code, StrSubstNo('%1:*|%1', TopSchemaCode));
        ReferencedXMLSchema.DeleteAll(true);

        XMLSchemaElement.SetFilter("XML Schema Code", StrSubstNo('%1:*|%1', TopSchemaCode));
        XMLSchemaElement.DeleteAll(true);

        XMLSchemaRestriction.SetFilter("XML Schema Code", StrSubstNo('%1:*|%1', TopSchemaCode));
        XMLSchemaRestriction.DeleteAll(true);

        ChildXMLSchema.SetFilter(Code, StrSubstNo('(%1:*|%1)&(<>%2)', TopSchemaCode, Code));
        ChildXMLSchema.DeleteAll(false);
    end;

    var
        ReplaceQst: Label 'Do you want to replace the existing definition?';

    [Scope('OnPrem')]
    procedure LoadSchema()
    var
        XMLSchema: Record "XML Schema";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        XSDParser: Codeunit "XSD Parser";
        RecordRef: RecordRef;
        XMLExists: Boolean;
        FileName: Text;
        i: Integer;
    begin
        CalcFields(XSD);
        XMLExists := XSD.HasValue;

        FileName := FileMgt.BLOBImport(TempBlob, '*.xsd');
        if FileName = '' then
            exit;

        if XMLExists then begin
            if not Confirm(ReplaceQst, false) then
                exit;

            TestField(Code);
            XMLSchema := Rec;
            Delete(true);
            XMLSchema.Insert();
            Rec := XMLSchema;
        end;

        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo(XSD));
        RecordRef.SetTable(Rec);

        if StrPos(FileName, '\') <> 0 then begin
            i := StrLen(FileName);
            while (i > 0) and (FileName[i] <> '\') do
                i := i - 1;
        end;

        Description := CopyStr(FileMgt.GetFileName(FileName), 1, MaxStrLen(Description));
        Path := CopyStr(FileName, 1, MaxStrLen(Path));
        XSDParser.LoadSchema(Rec);
        Modify();
    end;

    [Scope('OnPrem')]
    procedure ExportSchema(ShowFileDialog: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        TempBlob.FromRecord(Rec, FieldNo(XSD));
        if TempBlob.HasValue() then
            exit(FileMgt.BLOBExport(TempBlob, '*.xsd', ShowFileDialog));
    end;

    procedure GetSchemaContext(): Text
    var
        XMLSchemaElement: Record "XML Schema Element";
        XMLSchemaElement2: Record "XML Schema Element";
        Context: Text;
    begin
        XMLSchemaElement.SetRange("XML Schema Code", Code);
        XMLSchemaElement.SetCurrentKey(Indentation);

        Context := '';
        if XMLSchemaElement.FindSet() then
            repeat
                XMLSchemaElement2.CopyFilters(XMLSchemaElement);
                XMLSchemaElement2.SetRange(Indentation, XMLSchemaElement.Indentation);
                if XMLSchemaElement2.Count > 1 then
                    exit(Context);
                Context := XMLSchemaElement.GetFullPath();
            until XMLSchemaElement.Next() = 0;
    end;

    procedure GetTopSchemaCode(XMLSchema: Record "XML Schema"): Code[20]
    var
        TopElementCode: Text;
    begin
        TopElementCode := XMLSchema.Code;
        if StrPos(XMLSchema.Code, ':') > 1 then
            TopElementCode := CopyStr(XMLSchema.Code, 1, StrPos(XMLSchema.Code, ':') - 1);

        exit(TopElementCode);
    end;
}

