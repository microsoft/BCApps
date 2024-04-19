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
        Functions: array[20] of Interface "AOAI Function";
        FunctionNames: Dictionary of [Text, Integer];
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
        TooManyFunctionsAddedErr: Label 'Too many functions have been added. Maximum number of functions is %1', Comment = '%1 is the maximum number of tools that can be added.';
        FunctionAlreadyExistsErr: Label 'Function with the name, %1, already exists.', Comment = '%1 is the function name.';

    procedure AddTool(Tool: Interface "AOAI Function")
    var
        Index: Integer;
    begin
        Initialize();
        Index := FunctionNames.Count() + 1;

        ValidateTool(Tool.GetPrompt());

        if FunctionNames.ContainsKey(Tool.GetName()) then
            Error(FunctionAlreadyExistsErr, Tool.GetName());

        if Index > ArrayLen(Functions) then
            Error(TooManyFunctionsAddedErr, ArrayLen(Functions));

        Functions[Index] := Tool;
        FunctionNames.Add(Tool.GetName(), Index);
    end;

    procedure GetTool(Name: Text; var Function: Interface "AOAI Function"): Boolean
    begin
        if FunctionNames.ContainsKey(Name) then begin
            Function := Functions[FunctionNames.get(Name)];
            exit(true);
        end else
            exit(false);
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
    [Obsolete('Use GetTool() that takes in a function name and var for AOAI Function interface.', '25.0')]
    procedure GetTools(): List of [JsonObject]
    begin
        exit(Tools);
    end;
#endif

    procedure DeleteTool(Name: Text): Boolean
    var
        Index: Integer;
    begin
        if not FunctionNames.ContainsKey(Name) then
            exit(false);

        Index := FunctionNames.get(Name);
        FunctionNames.Remove(Name);

        for Index := Index to FunctionNames.Count() do begin
            Functions[Index] := Functions[Index + 1];
            FunctionNames.Set(Functions[Index].GetName(), Index);
        end;
        Clear(Functions[Index + 1]);
        exit(true);
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

    procedure SetFunctionAsToolChoice(Function: Interface "AOAI Function")
    begin
        SetFunctionAsToolChoice(Function.GetName());
    end;

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

    [TryFunction]
    [NonDebuggable]
    procedure IsToolsList(Message: Text)
    var
        MessageJArray: JsonArray;
        ToolToken: JsonToken;
        TypeToken: JsonToken;
        XPathLbl: Label '$.type', Comment = 'For more details on response, see https://aka.ms/AAlrz36', Locked = true;
        i: Integer;
    begin
        MessageJArray := ConvertToJsonArray(Message);

        for i := 0 to MessageJArray.Count - 1 do begin
            MessageJArray.Get(i, ToolToken);
            ToolToken.SelectToken(XPathLbl, TypeToken);
            if TypeToken.AsValue().AsText() <> 'function' then
                Error('');
        end;
    end;

    [NonDebuggable]
    procedure ConvertToJsonArray(Message: Text) MessageJArray: JsonArray;
    begin
        MessageJArray.ReadFrom(Message);
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
