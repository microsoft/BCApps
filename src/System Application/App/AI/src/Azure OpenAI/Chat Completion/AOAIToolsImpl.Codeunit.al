// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI;

codeunit 7778 "AOAI Tools Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Initialized: Boolean;
        AddToolToPayload: Boolean;
        [NonDebuggable]
        ToolChoice: Text;
        [NonDebuggable]
        Tools: List of [JsonObject];
        ToolIdDoesNotExistErr: Label 'Tool id does not exist.';
        ToolObjectInvalidErr: Label '%1 object does not contain %2 property.', Comment = '%1 is the object name and %2 is the property that is missing.';
        ToolTypeErr: Label 'Tool type must be of function type.';

    [NonDebuggable]
    procedure AddTool(NewTool: JsonObject; CallerModuleInfo: ModuleInfo)
    begin
        Initialize();
        if ValidateTool(NewTool) then
            Tools.Add(NewTool);
    end;

    [NonDebuggable]
    procedure ModifyTool(Id: Integer; NewTool: JsonObject)
    begin
        if (Id < 1) or (Id > Tools.Count) then
            Error(ToolIdDoesNotExistErr);
        if ValidateTool(NewTool) then
            Tools.Set(Id, NewTool);
    end;

    procedure DeleteTool(Id: Integer)
    begin
        if (Id < 1) or (Id > Tools.Count) then
            Error(ToolIdDoesNotExistErr);

        Tools.RemoveAt(Id);
    end;

    [NonDebuggable]
    procedure GetTools(): List of [JsonObject]
    begin
        exit(Tools);
    end;

    [NonDebuggable]
    procedure PrepareTools() ToolsResult: JsonArray
    var
        Counter: Integer;
        Tool: JsonObject;
    begin
        if Tools.Count = 0 then
            exit;

        Initialize();
        Counter := 1;

        repeat
            Clear(Tool);
            Tools.Get(Counter, Tool);
            ToolsResult.Add(Tool);
            Counter += 1;
        until Counter > Tools.Count;
    end;

    procedure ToolsExists(): Boolean
    begin
        exit(AddToolToPayload and (Tools.Count > 0));
    end;

    procedure SetAddToolToPayload(AddToolsToPayload: Boolean)
    begin
        AddToolToPayload := AddToolsToPayload;
    end;

    [NonDebuggable]
    procedure SetToolChoice(NewToolChoice: Text)
    begin
        ToolChoice := NewToolChoice;
    end;

    [NonDebuggable]
    procedure GetToolChoice(): Text
    begin
        exit(ToolChoice);
    end;

    local procedure Initialize()
    begin
        if Initialized then
            exit;

        AddToolToPayload := true;
        ToolChoice := 'auto';
        Initialized := true;
    end;

    [NonDebuggable]
    local procedure ValidateTool(ToolObject: JsonObject): Boolean
    var
        AzureOpenAIImpl: Codeunit "Azure OpenAI Impl";
        TypeToken: JsonToken;
        FunctionToken: JsonToken;
        ToolObjectText: Text;
        ErrorMessage: Text;
    begin
        ToolObject.WriteTo(ToolObjectText);
        ToolObjectText := AzureOpenAIImpl.RemoveProhibitedCharacters(ToolObjectText);

        ToolObject.ReadFrom(ToolObjectText);

        if ToolObject.Get('type', TypeToken) then begin
            if TypeToken.AsValue().AsText() <> 'function' then
                Error(ToolTypeErr);

            if ToolObject.Get('function', FunctionToken) then begin
                if not FunctionToken.AsObject().Contains('name') then begin
                    ErrorMessage := StrSubstNo(ToolObjectInvalidErr, 'function', 'name');
                    Error(ErrorMessage);
                end;

                if not FunctionToken.AsObject().Contains('parameters') then begin
                    ErrorMessage := StrSubstNo(ToolObjectInvalidErr, 'function', 'parameters');
                    Error(ErrorMessage);
                end;
            end
            else begin
                ErrorMessage := StrSubstNo(ToolObjectInvalidErr, 'Tool', 'function');
                Error(ErrorMessage);
            end;
        end
        else begin
            ErrorMessage := StrSubstNo(ToolObjectInvalidErr, 'Tool', 'type');
            Error(ErrorMessage);
        end;
        exit(true);
    end;
}
