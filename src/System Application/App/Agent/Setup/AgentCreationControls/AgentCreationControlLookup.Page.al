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

    trigger OnOpenPage()
    begin
        if HasSelectedKey then begin
            Rec.SetRange("Key", SelectedKey);
            if Rec.FindFirst() then;
            Rec.SetRange("Key");
        end else
            if Rec.FindFirst() then;
    end;

    procedure Initialize(PageCaption: Text; SelectedEntryKey: Text[250])
    begin
        CurrPage.Caption := PageCaption;
        SelectedKey := SelectedEntryKey;
        HasSelectedKey := true;
    end;

    procedure AddEntry(EntryKey: Text[250]; EntryValue: Text[2048])
    var
        NextID: Integer;
    begin
        if Rec.FindLast() then
            NextID := Rec.ID + 1
        else
            NextID := 1;

        Clear(Rec);
        Rec.ID := NextID;
        Rec."Key" := EntryKey;
        Rec.Value := EntryValue;
        Rec.Insert();
    end;

    var
        SelectedKey: Text[250];
        HasSelectedKey: Boolean;
}
