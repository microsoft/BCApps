// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

page 4329 "Agent Available Tools Part"
{
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
            repeater(GroupName)
            {
                ShowCaption = false;
                field(Description; JsonText)
                {
                    ShowCaption = false;
                }
            }
        }
    }

    var
        JsonText: Text;

    trigger OnAfterGetRecord()
    begin
        JsonText := Rec.GetJsonText();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        JsonText := Rec.GetJsonText();
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
        Rec.FindFirst();
    end;

    internal procedure ClearData()
    begin
        Rec.DeleteAll();
    end;
}