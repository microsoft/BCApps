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
#if not CLEAN25
        [NonDebuggable]
        Tools: List of [JsonObject];
        ToolIdDoesNotExistErr: Label 'Tool id does not exist.';
#endif
        ToolObjectInvalidErr: Label '%1 object does not contain %2 property.', Comment = '%1 is the object name and %2 is the property that is missing.';
        ToolTypeErr: Label 'Tool type must be of function type.';
        Functions: array[20] of Interface "AOAI Function";
        FunctionNames: Dictionary of [Text, Integer];

    procedure AddTool(Tool: Interface "AOAI Function")
    var
        Index: Integer;
    begin
        Initialize();
        Index := FunctionNames.Count() + 1;

        if Index > ArrayLen(Functions) then
            Error('Too many tools added. Maximum number of tools is %1', ArrayLen(Functions));

        ValidateTool(Tool.GetPrompt());

        Functions[Index] := Tool;
        FunctionNames.Add(Tool.GetName(), Index);
    end;

    procedure GetTool(Name: Text): Interface "AOAI Function"
    begin
        if FunctionNames.ContainsKey(Name) then
            exit(Functions[FunctionNames.get(Name)]);

        Error('Tool not found');
    end;

    procedure GetFunctionTools(): List of [Text]
    begin
        exit(FunctionNames.Keys());
    end;

#if not CLEAN25
    [NonDebuggable]
    [Obsolete('Use AddTool that takes in an AOAI Function interface instead.', '25.0')]
    procedure AddTool(NewTool: JsonObject)
    begin
        Initialize();
        if ValidateTool(NewTool) then
            Tools.Add(NewTool);
    end;

    [NonDebuggable]
    [Obsolete('Use ModifyTool that takes in an AOAI Function interface instead.', '25.0')]
    procedure ModifyTool(Id: Integer; NewTool: JsonObject)
    begin
        if (Id < 1) or (Id > Tools.Count) then
            Error(ToolIdDoesNotExistErr);
        if ValidateTool(NewTool) then
            Tools.Set(Id, NewTool);
    end;

    [Obsolete('Use DeleteTool that takes in a function name instead.', '25.0')]
    procedure DeleteTool(Id: Integer)
    begin
        if (Id < 1) or (Id > Tools.Count) then
            Error(ToolIdDoesNotExistErr);

        Tools.RemoveAt(Id);
    end;

    [NonDebuggable]
    [Obsolete('Use GetTool() that takes in a function name and returns the interface.', '25.0')]
    procedure GetTools(): List of [JsonObject]
    begin
        exit(Tools);
    end;
#endif

    procedure DeleteTool(Name: Text)
    var
        Index: Integer;
    begin
        if not FunctionNames.ContainsKey(Name) then
            exit;

        Index := FunctionNames.get(Name);
        FunctionNames.Remove(Name);

        for Index := Index to FunctionNames.Count() do begin
            Functions[Index] := Functions[Index + 1];
            FunctionNames.Set(Functions[Index].GetName(), Index);
        end;
        Clear(Functions[Index + 1]);
    end;

    procedure ClearTools()
    begin
#if not CLEAN25
        Clear(Tools);
#endif
        Clear(Functions);
        Clear(FunctionNames);
    end;

    [NonDebuggable]
    procedure PrepareTools() ToolsResult: JsonArray
    var
        Counter: Integer;
#if not CLEAN25
        Tool: JsonObject;
#endif
    begin
        Initialize();
        Counter := 1;

        if FunctionNames.Count <> 0 then
            repeat
                ToolsResult.Add(Functions[Counter].GetPrompt());
                Counter += 1;
            until Counter > FunctionNames.Count();

#if not CLEAN25
        Counter := 1;
        if Tools.Count <> 0 then
            repeat
                Clear(Tool);
                Tools.Get(Counter, Tool);
                ToolsResult.Add(Tool);
                Counter += 1;
            until Counter > Tools.Count;
#endif
    end;

    procedure ToolsExists(): Boolean
    begin
        if not AddToolToPayload then
            exit(false);

#if not CLEAN25
        if (FunctionNames.Count() = 0) and (Tools.Count = 0) then
#else
        if (FunctionNames.Count() = 0) then
#endif
            exit(false);

        exit(true);
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
    procedure SetFunctionAsToolChoice(FunctionName: Text)
    var
        ToolChoiceObject: JsonObject;
        FunctionObject: JsonObject;
    begin
        ToolChoiceObject.add('type', 'function');
        FunctionObject.add('name', FunctionName);
        ToolChoiceObject.add('function', FunctionObject);
        ToolChoiceObject.WriteTo(ToolChoice);
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
