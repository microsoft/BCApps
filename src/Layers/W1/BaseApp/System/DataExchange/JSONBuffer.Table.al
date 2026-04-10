namespace System.IO;

using System;
using System.Reflection;
using System.Utilities;

table 1236 "JSON Buffer"
{
    Caption = 'JSON Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Depth; Integer)
        {
            Caption = 'Depth';
            DataClassification = SystemMetadata;
        }
        field(3; "Token type"; Option)
        {
            Caption = 'Token type';
            DataClassification = SystemMetadata;
            OptionCaption = 'None,Start Object,Start Array,Start Constructor,Property Name,Comment,Raw,Integer,Decimal,String,Boolean,Null,Undefined,End Object,End Array,End Constructor,Date,Bytes';
            OptionMembers = "None","Start Object","Start Array","Start Constructor","Property Name",Comment,Raw,"Integer",Decimal,String,Boolean,Null,Undefined,"End Object","End Array","End Constructor",Date,Bytes;
        }
        field(4; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
        field(5; "Value Type"; Text[50])
        {
            Caption = 'Value Type';
            DataClassification = SystemMetadata;
        }
        field(6; Path; Text[250])
        {
            Caption = 'Path';
            DataClassification = SystemMetadata;
        }
        field(7; "Value BLOB"; BLOB)
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
    }

    fieldgroups
    {
    }

    var
        DevMsgNotTemporaryErr: Label 'This function can only be used when the record is temporary.';

    procedure ReadFromBlob(BlobFieldRef: FieldRef)
    var
        TypeHelper: Codeunit "Type Helper";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromRecordRef(BlobFieldRef.Record(), BlobFieldRef.Number);
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        ReadFromText(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator()));
    end;

    procedure ReadFromText(JSONText: Text)
    var
        JSONTextReader: DotNet JsonTextReader;
        StringReader: DotNet StringReader;
        TokenType: Integer;
        FormatValue: Integer;
    begin
        if not IsTemporary then
            Error(DevMsgNotTemporaryErr);
        DeleteAll();
        JSONTextReader := JSONTextReader.JsonTextReader(StringReader.StringReader(JSONText));
        if JSONTextReader.Read() then
            repeat
                Init();
                "Entry No." += 1;
                Depth := JSONTextReader.Depth;
                TokenType := JSONTextReader.TokenType;
                "Token type" := TokenType;
                if IsNull(JSONTextReader.Value) then
                    Value := ''
                else begin
                    if JSONTextReader.ValueType.ToString() = 'System.DateTime' then
                        FormatValue := 1
                    else
                        FormatValue := 0;
                    SetValueWithoutModifying(Format(JSONTextReader.Value, 0, FormatValue));
                end;

                if IsNull(JSONTextReader.ValueType) then
                    "Value Type" := ''
                else
                    "Value Type" := Format(JSONTextReader.ValueType);
                Path := JSONTextReader.Path;
                Insert();
            until not JSONTextReader.Read();
    end;

    procedure FindArray(var TempJSONBuffer: Record "JSON Buffer" temporary; ArrayName: Text): Boolean
    begin
        TempJSONBuffer.Copy(Rec, true);
        TempJSONBuffer.Reset();

        TempJSONBuffer.SetRange(Path, AppendPathToCurrent(ArrayName));
        if not TempJSONBuffer.FindFirst() then
            exit(false);
        TempJSONBuffer.SetFilter(Path, AppendPathToCurrent(ArrayName) + '[*');
        TempJSONBuffer.SetRange(Depth, TempJSONBuffer.Depth + 1);
        TempJSONBuffer.SetFilter("Token type", '<>%1', "Token type"::"End Object");
        exit(TempJSONBuffer.FindSet());
    end;

    procedure GetPropertyValue(var PropertyValue: Text; PropertyName: Text): Boolean
    begin
        exit(GetPropertyValueAtPath(PropertyValue, PropertyName, Path + '*'));
    end;

    procedure GetPropertyValueAtPath(var PropertyValue: Text; PropertyName: Text; PropertyPath: Text): Boolean
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
    begin
        TempJSONBuffer.Copy(Rec, true);
        TempJSONBuffer.Reset();

        TempJSONBuffer.SetFilter(Path, PropertyPath);
        TempJSONBuffer.SetRange("Token type", "Token type"::"Property Name");
        TempJSONBuffer.SetRange(Value, PropertyName);
        if not TempJSONBuffer.FindFirst() then
            exit;
        if TempJSONBuffer.Get(TempJSONBuffer."Entry No." + 1) then begin
            PropertyValue := TempJSONBuffer.GetValue();
            exit(true);
        end;
    end;

    procedure GetBooleanPropertyValue(var BooleanValue: Boolean; PropertyName: Text): Boolean
    var
        PropertyValue: Text;
    begin
        if GetPropertyValue(PropertyValue, PropertyName) then
            exit(Evaluate(BooleanValue, PropertyValue));
    end;

    procedure GetIntegerPropertyValue(var IntegerValue: Integer; PropertyName: Text): Boolean
    var
        PropertyValue: Text;
    begin
        if GetPropertyValue(PropertyValue, PropertyName) then
            exit(Evaluate(IntegerValue, PropertyValue));
    end;

    procedure GetDatePropertyValue(var DateValue: Date; PropertyName: Text): Boolean
    var
        PropertyValue: Text;
    begin
        if GetPropertyValue(PropertyValue, PropertyName) then
            exit(Evaluate(DateValue, PropertyValue));
    end;

    procedure GetDecimalPropertyValue(var DecimalValue: Decimal; PropertyName: Text): Boolean
    var
        PropertyValue: Text;
    begin
        if GetPropertyValue(PropertyValue, PropertyName) then
            exit(Evaluate(DecimalValue, PropertyValue));
    end;

    local procedure AppendPathToCurrent(AppendPath: Text): Text
    begin
        if Path <> '' then
            exit(Path + '.' + AppendPath);
        exit(AppendPath)
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
        Value := CopyStr(NewValue, 1, MaxStrLen(Value));
        if StrLen(NewValue) <= MaxStrLen(Value) then
            exit; // No need to store anything in the blob
        if NewValue = '' then
            exit;

        "Value BLOB".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.Write(NewValue);
    end;
}

