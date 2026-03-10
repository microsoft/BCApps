// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

/// <summary>
/// Represents a SharePoint list item as returned by Microsoft Graph API.
/// </summary>
table 9131 "SharePoint Graph List Item"
{
    Access = Public;
    TableType = Temporary;
    DataClassification = SystemMetadata;
    InherentEntitlements = X;
    InherentPermissions = X;
    Extensible = false;

    fields
    {
        field(1; Id; Text[250])
        {
            Caption = 'Id';
            Description = 'Unique identifier of the list item';
        }
        field(2; ListId; Text[250])
        {
            Caption = 'List Id';
            Description = 'ID of the parent list';
        }
        field(3; Title; Text[250])
        {
            Caption = 'Title';
            Description = 'Title of the list item';
            DataClassification = CustomerContent;
        }
        field(4; ContentType; Text[100])
        {
            Caption = 'Content Type';
            Description = 'Content type of the list item';
        }
        field(5; WebUrl; Text[2048])
        {
            Caption = 'Web URL';
            Description = 'URL to view the list item in a web browser';
        }
        field(6; CreatedDateTime; DateTime)
        {
            Caption = 'Created Date Time';
            Description = 'Date and time when the list item was created';
        }
        field(7; LastModifiedDateTime; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Description = 'Date and time when the list item was last modified';
        }
        field(8; FieldsJson; Blob)
        {
            Caption = 'Fields JSON';
            Description = 'JSON representation of the list item''s custom fields';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; ListId, Id)
        {
        }
    }

    /// <summary>
    /// Sets the custom fields for the list item as a JSON object.
    /// </summary>
    /// <param name="FieldsJsonObject">JSON object containing the custom fields</param>
    procedure SetFieldsJson(FieldsJsonObject: JsonObject)
    var
        OutStream: OutStream;
    begin
        FieldsJson.CreateOutStream(OutStream, TextEncoding::UTF8);
        FieldsJsonObject.WriteTo(OutStream);
    end;

    /// <summary>
    /// Gets the custom fields for the list item as a JSON object.
    /// </summary>
    /// <param name="FieldsJsonObject">JSON object that will contain the custom fields</param>
    /// <returns>True if fields were retrieved successfully, false otherwise</returns>
    procedure GetFieldsJson(var FieldsJsonObject: JsonObject): Boolean
    var
        InStream: InStream;
        JsonText: Text;
    begin
        FieldsJson.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(JsonText);
        if JsonText = '' then
            exit(false);

        exit(FieldsJsonObject.ReadFrom(JsonText));
    end;

    /// <summary>
    /// Gets a specific field value from the custom fields.
    /// </summary>
    /// <param name="FieldName">Name of the field to retrieve</param>
    /// <param name="FieldValue">Text value that will contain the field value</param>
    /// <returns>True if field was found, false otherwise</returns>
    procedure GetFieldValue(FieldName: Text; var FieldValue: Text): Boolean
    var
        FieldsJsonObject: JsonObject;
        FieldToken: JsonToken;
    begin
        if not GetFieldsJson(FieldsJsonObject) then
            exit(false);

        if not FieldsJsonObject.Get(FieldName, FieldToken) then
            exit(false);

        if not FieldToken.IsValue() then
            exit(false);

        FieldValue := FieldToken.AsValue().AsText();
        exit(true);
    end;
}