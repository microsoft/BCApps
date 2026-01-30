// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

page 4327 "Agent PageStack Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Agent JSON Buffer";
    SourceTableTemporary = true;
    Editable = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(LineRepeater)
            {
                ShowCaption = false;
                field(PageName; JsonText)
                {
                    Caption = 'Page caption';
                    ToolTip = 'Specifies the caption of a page in the stack';
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
        Data.SetAutoCalcFields(Data.Json);
        if not Data.FindSet() then
            exit;

        Rec.DeleteAll();
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