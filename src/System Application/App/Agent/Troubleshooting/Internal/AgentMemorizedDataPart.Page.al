// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

page 4330 "Agent Memorized Data Part"
{
    Caption = 'Agent Memorized Data';
    AboutText = 'Displays the memorized key-value data for the agent.';
    AboutTitle = 'Agent Memorized Data';
    Extensible = false;
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Agent JSON Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(MemorizedData)
            {
                ShowCaption = false;
                field(KeyField; KeyText)
                {
                    Caption = 'Key';
                    ToolTip = 'Specifies the key of the memorized data entry.';
                }
                field(Value; ValueText)
                {
                    Caption = 'Value';
                    ToolTip = 'Specifies the value of the memorized data.';
                }
            }
        }
    }

    var
        KeyText: Text;
        ValueText: Text;

    trigger OnAfterGetRecord()
    begin
        ParseKeyValuePair();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ParseKeyValuePair();
    end;

    local procedure ParseKeyValuePair()
    var
        JsonText: Text;
        JsonObject: JsonObject;
        KeyToken: JsonToken;
        ValueToken: JsonToken;
    begin
        JsonText := Rec.GetJsonText();

        // Clear previous values
        KeyText := '';
        ValueText := '';

        if JsonText = '' then
            exit;

        if JsonObject.ReadFrom(JsonText) then begin
            if JsonObject.Get('key', KeyToken) then
                KeyText := KeyToken.AsValue().AsText();
            if JsonObject.Get('value', ValueToken) then
                ValueText := ValueToken.AsValue().AsText();
        end;
    end;

    internal procedure SetData(var Data: Record "Agent JSON Buffer" temporary)
    begin
        Rec.DeleteAll();
        Data.SetAutoCalcFields(Data.Json);
        if not Data.FindSet() then
            exit;

        repeat
            Rec.Id := Data.Id;
            Rec.Json := Data.Json;
            Rec.Insert();
        until Data.Next() = 0;

        if Rec.FindFirst() then;
    end;

    internal procedure ClearData()
    begin
        Rec.DeleteAll();
        KeyText := '';
        ValueText := '';
    end;
}