// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;

/// <summary>
/// Stores query schema definitions per feature.
/// Each feature defines the structure of its query fields (e.g., instructions, message, attachments).
/// The schema is used by the No-Code wizard to dynamically render the appropriate query editor.
/// </summary>
table 149060 "AIT Query Schema"
{
    Caption = 'AI Test Query Schema';
    DataClassification = SystemMetadata;
    ReplicateData = false;
    Extensible = true;
    Access = Public;

    fields
    {
        field(1; "Feature Code"; Code[50])
        {
            Caption = 'Feature Code';
            NotBlank = true;
            ToolTip = 'Specifies the unique identifier for the AI feature (e.g., AGENT-RUNTIME, COPILOT-SALES).';
        }
        field(2; "Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the AI feature.';
        }
        field(3; "Schema JSON"; Blob)
        {
            Caption = 'Schema JSON';
            ToolTip = 'Specifies the JSON schema defining the query fields for this feature.';
        }
        field(4; "Default Codeunit ID"; Integer)
        {
            Caption = 'Default Codeunit ID';
            ToolTip = 'Specifies the default test codeunit ID for this feature.';
        }
        field(5; "Default Codeunit Name"; Text[249])
        {
            Caption = 'Default Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit), "Object ID" = field("Default Codeunit ID")));
            ToolTip = 'Specifies the name of the default test codeunit.';
        }
    }

    keys
    {
        key(PK; "Feature Code")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Gets the schema JSON as a JsonObject.
    /// </summary>
    procedure GetSchemaJson(): JsonObject
    var
        SchemaInStream: InStream;
        SchemaText: Text;
        SchemaJson: JsonObject;
    begin
        CalcFields("Schema JSON");
        if not "Schema JSON".HasValue() then
            exit(SchemaJson);

        "Schema JSON".CreateInStream(SchemaInStream, TextEncoding::UTF8);
        SchemaInStream.ReadText(SchemaText);
        SchemaJson.ReadFrom(SchemaText);
        exit(SchemaJson);
    end;

    /// <summary>
    /// Sets the schema JSON from a JsonObject.
    /// </summary>
    procedure SetSchemaJson(SchemaJson: JsonObject)
    var
        SchemaOutStream: OutStream;
        SchemaText: Text;
    begin
        SchemaJson.WriteTo(SchemaText);
        "Schema JSON".CreateOutStream(SchemaOutStream, TextEncoding::UTF8);
        SchemaOutStream.WriteText(SchemaText);
    end;
}
