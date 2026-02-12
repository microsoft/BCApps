// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

codeunit 7784 "AOAI User Message Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ContentParts: JsonArray;

    procedure AddTextPart(TextContent: Text)
    var
        TextPartObject: JsonObject;
    begin
        TextPartObject.Add('type', 'text');
        TextPartObject.Add('text', TextContent);
        ContentParts.Add(TextPartObject);
    end;

    procedure AddFilePart(FileData: Text)
    var
        FilePartObject: JsonObject;
        FileDataObject: JsonObject;
    begin
        FileDataObject.Add('file_data', FileData);
        FilePartObject.Add('type', 'file');
        FilePartObject.Add('file', FileDataObject);
        ContentParts.Add(FilePartObject);
    end;

    procedure GetContentParts(): JsonArray
    begin
        exit(ContentParts);
    end;
}
