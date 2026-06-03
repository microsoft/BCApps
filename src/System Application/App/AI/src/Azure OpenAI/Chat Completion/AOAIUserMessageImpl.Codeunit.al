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
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        [NonDebuggable]
        ContentParts: JsonArray;
        HasFileContent, HasTextContent : Boolean;
        NotMicrosoftPublisherErr: Label 'This functionality is only available to Microsoft published apps.';

    [NonDebuggable]
    procedure AddTextPart(TextContent: Text; CallerModuleInfo: ModuleInfo)
    var
        TextPartObject: JsonObject;
    begin
        if not CopilotCapabilityImpl.IsPublisherMicrosoft(CallerModuleInfo) then
            Error(NotMicrosoftPublisherErr);
        TextPartObject.Add('type', 'text');
        TextPartObject.Add('text', TextContent);
        ContentParts.Add(TextPartObject);
        HasTextContent := true;
    end;

    [NonDebuggable]
    procedure AddFilePart(FileData: Text; CallerModuleInfo: ModuleInfo)
    var
        FilePartObject: JsonObject;
        FileDataObject: JsonObject;
    begin
        if not CopilotCapabilityImpl.IsPublisherMicrosoft(CallerModuleInfo) then
            Error(NotMicrosoftPublisherErr);
        FileDataObject.Add('file_data', FileData);
        FilePartObject.Add('type', 'file');
        FilePartObject.Add('file', FileDataObject);
        ContentParts.Add(FilePartObject);
        HasFileContent := true;
    end;

    [NonDebuggable]
    procedure GetContentParts(): JsonArray
    begin
        exit(ContentParts);
    end;

    internal procedure HasFilePart(): Boolean
    begin
        exit(HasFileContent);
    end;

    internal procedure HasTextPart(): Boolean
    begin
        exit(HasTextContent);
    end;
}
