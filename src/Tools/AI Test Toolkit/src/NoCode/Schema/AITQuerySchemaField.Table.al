// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Temporary table used to hold parsed query schema fields for UI rendering.
/// Loaded from the JSON schema stored in AIT Query Schema.
/// </summary>
table 149061 "AIT Query Schema Field"
{
    Caption = 'AI Test Query Schema Field';
    DataClassification = SystemMetadata;
    TableType = Temporary;
    ReplicateData = false;
    Extensible = false;
    Access = Internal;

    fields
    {
        field(1; "Feature Code"; Code[50])
        {
            Caption = 'Feature Code';
        }
        field(2; "Field Order"; Integer)
        {
            Caption = 'Field Order';
        }
        field(3; "Field Name"; Text[100])
        {
            Caption = 'Field Name';
            ToolTip = 'Specifies the JSON property name for this field.';
        }
        field(4; "Field Label"; Text[100])
        {
            Caption = 'Field Label';
            ToolTip = 'Specifies the display label for this field.';
        }
        field(5; "Field Type"; Enum "AIT Query Field Type")
        {
            Caption = 'Field Type';
            ToolTip = 'Specifies the data type of this field.';
        }
        field(6; "Is Required"; Boolean)
        {
            Caption = 'Required';
            ToolTip = 'Specifies whether this field is required.';
        }
        field(7; "Field Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description or help text for this field.';
        }
        field(8; "Default Value"; Text[250])
        {
            Caption = 'Default Value';
            ToolTip = 'Specifies the default value for this field.';
        }
        field(10; "Text Value"; Text[2048])
        {
            Caption = 'Text Value';
            ToolTip = 'Specifies the text value for this field.';
        }
        field(11; "Multiline Value"; Blob)
        {
            Caption = 'Multiline Value';
            ToolTip = 'Specifies the multiline text value for this field.';
        }
        field(12; "Boolean Value"; Boolean)
        {
            Caption = 'Boolean Value';
            ToolTip = 'Specifies the boolean value for this field.';
        }
        field(13; "Integer Value"; Integer)
        {
            Caption = 'Integer Value';
            ToolTip = 'Specifies the integer value for this field.';
        }
        field(14; "List Value"; Blob)
        {
            Caption = 'List Value';
            ToolTip = 'Specifies the list value (JSON array) for this field.';
        }
    }

    keys
    {
        key(PK; "Feature Code", "Field Order")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Gets the multiline value as text.
    /// </summary>
    procedure GetMultilineValue(): Text
    var
        ValueInStream: InStream;
        ValueText: Text;
    begin
        CalcFields("Multiline Value");
        if not "Multiline Value".HasValue() then
            exit('');

        "Multiline Value".CreateInStream(ValueInStream, TextEncoding::UTF8);
        ValueInStream.ReadText(ValueText);
        exit(ValueText);
    end;

    /// <summary>
    /// Sets the multiline value from text.
    /// </summary>
    procedure SetMultilineValue(ValueText: Text)
    var
        ValueOutStream: OutStream;
    begin
        "Multiline Value".CreateOutStream(ValueOutStream, TextEncoding::UTF8);
        ValueOutStream.WriteText(ValueText);
    end;

    /// <summary>
    /// Gets the list value as a JsonArray.
    /// </summary>
    procedure GetListValue(): JsonArray
    var
        ValueInStream: InStream;
        ValueText: Text;
        ValueArray: JsonArray;
    begin
        CalcFields("List Value");
        if not "List Value".HasValue() then
            exit(ValueArray);

        "List Value".CreateInStream(ValueInStream, TextEncoding::UTF8);
        ValueInStream.ReadText(ValueText);
        ValueArray.ReadFrom(ValueText);
        exit(ValueArray);
    end;

    /// <summary>
    /// Sets the list value from a JsonArray.
    /// </summary>
    procedure SetListValue(ValueArray: JsonArray)
    var
        ValueOutStream: OutStream;
        ValueText: Text;
    begin
        ValueArray.WriteTo(ValueText);
        "List Value".CreateOutStream(ValueOutStream, TextEncoding::UTF8);
        ValueOutStream.WriteText(ValueText);
    end;
}
