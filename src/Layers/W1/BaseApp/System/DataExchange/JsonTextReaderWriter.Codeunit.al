namespace System.IO;

using System;
using System.Utilities;

codeunit 1234 "Json Text Reader/Writer"
{

    trigger OnRun()
    begin
    end;

    var
        StringBuilder: DotNet StringBuilder;
        StringWriter: DotNet StringWriter;
        JsonTextWriter: DotNet JsonTextWriter;
        DoNotFormat: Boolean;

    procedure ReadJSonToJSonBuffer(Json: Text; var JsonBuffer: Record "JSON Buffer")
    begin
        JsonBuffer.ReadFromText(Json);
    end;

    local procedure InitializeWriter()
    var
        Formatting: DotNet Formatting;
    begin
        if not IsNull(StringBuilder) then
            exit;
        StringBuilder := StringBuilder.StringBuilder();
        StringWriter := StringWriter.StringWriter(StringBuilder);
        JsonTextWriter := JsonTextWriter.JsonTextWriter(StringWriter);
        if DoNotFormat then
            JsonTextWriter.Formatting := Formatting.None
        else
            JsonTextWriter.Formatting := Formatting.Indented;
    end;

    procedure SetDoNotFormat()
    begin
        DoNotFormat := true;
    end;

    procedure WriteStartConstructor(Name: Text)
    begin
        InitializeWriter();

        JsonTextWriter.WriteStartConstructor(Name);
    end;

    procedure WriteEndConstructor()
    begin
        JsonTextWriter.WriteEndConstructor();
    end;

    procedure WriteStartObject(ObjectName: Text)
    begin
        InitializeWriter();

        if ObjectName <> '' then
            JsonTextWriter.WritePropertyName(ObjectName);
        JsonTextWriter.WriteStartObject();
    end;

    procedure WriteEndObject()
    begin
        JsonTextWriter.WriteEndObject();
    end;

    procedure WriteStartArray(ArrayName: Text)
    begin
        InitializeWriter();

        if ArrayName <> '' then
            JsonTextWriter.WritePropertyName(ArrayName);
        JsonTextWriter.WriteStartArray();
    end;

    procedure WriteEndArray()
    begin
        JsonTextWriter.WriteEndArray();
    end;

    procedure WriteStringProperty(VariableName: Text; Variable: Variant)
    begin
        JsonTextWriter.WritePropertyName(VariableName);
        JsonTextWriter.WriteValue(Format(Variable, 0, 9));
    end;

    procedure WriteNumberProperty(VariableName: Text; Variable: Variant)
    var
        Decimal: Decimal;
    begin
        case true of
            Variable.IsInteger, Variable.IsDecimal:
                Decimal := Variable;
            else
                Evaluate(Decimal, Variable);
        end;
        JsonTextWriter.WritePropertyName(VariableName);
        JsonTextWriter.WriteValue(Decimal);
    end;

    procedure WriteBooleanProperty(VariableName: Text; Variable: Variant)
    var
        Bool: Boolean;
    begin
        case true of
            Variable.IsBoolean:
                Bool := Variable;
            else
                Evaluate(Bool, Variable);
        end;
        JsonTextWriter.WritePropertyName(VariableName);
        JsonTextWriter.WriteValue(Bool);
    end;

    procedure WriteNullProperty(VariableName: Text)
    begin
        JsonTextWriter.WritePropertyName(VariableName);
        JsonTextWriter.WriteNull();
    end;

    procedure WriteNullValue()
    begin
        JsonTextWriter.WriteNull();
    end;

    procedure WriteBytesProperty(VariableName: Text; TempBlob: Codeunit "Temp Blob")
    var
        MemoryStream: DotNet MemoryStream;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        MemoryStream := MemoryStream.MemoryStream();
        CopyStream(MemoryStream, InStr);
        JsonTextWriter.WritePropertyName(VariableName);
        JsonTextWriter.WriteValue(MemoryStream.ToArray());
    end;

    procedure WriteRawProperty(VariableName: Text; Variable: Variant)
    begin
        JsonTextWriter.WritePropertyName(VariableName);
        JsonTextWriter.WriteValue(Variable);
    end;

    procedure GetJSonAsText() JSon: Text
    begin
        JSon := StringBuilder.ToString();
    end;

    procedure WriteValue(Variable: Variant)
    begin
        JsonTextWriter.WriteValue(Variable);
    end;

    procedure WriteProperty(VariableName: Text)
    begin
        JsonTextWriter.WritePropertyName(VariableName);
    end;
}

