// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4331 "Agent Creation Control Lookup"
{
    ApplicationArea = All;
    Caption = 'Agent Creation Control Lookup';
    Editable = false;
    PageType = List;
    InherentEntitlements = X;
    InherentPermissions = X;
    SourceTable = "Agent Creation Control Lookup";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                ShowCaption = false;
                field(Value; Rec.Value)
                {
                    ShowCaption = false;
                }
            }
        }
    }

    procedure SetCaption(NewCaption: Text)
    begin
        CurrPage.Caption := NewCaption;
    end;

    procedure AddItem(ItemName: Text[250]; ItemValue: Text[2048])
    var
        NextID: Integer;
    begin
        Rec.LockTable();
        if Rec.FindLast() then
            NextID := Rec.ID + 1
        else
            NextID := 1;

        Rec.Init();
        Rec.ID := NextID;
        Rec."Key" := ItemName;
        Rec.Value := ItemValue;
        Rec.Insert();
    end;
}
