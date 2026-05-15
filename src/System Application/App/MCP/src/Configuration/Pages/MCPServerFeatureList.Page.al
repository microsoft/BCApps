// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8368 "MCP Server Feature List"
{
    Caption = 'Server Features';
    ApplicationArea = All;
    PageType = ListPart;
    SourceTable = "MCP Server Feature";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Features)
            {
                ShowCaption = false;
                field(Feature; Rec.Feature)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the server feature.';
                    Width = 30;
                }
                field("Description"; Rec."Description")
                {
                }
                field("Status"; Rec."Status")
                {
                    StyleExpr = StatusStyleExpr;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Activate)
            {
                Caption = 'Activate';
                ToolTip = 'Activate the selected server feature for this MCP configuration.';
                Image = Start;
                Enabled = ActionsEnabled and (Rec.Status = Rec.Status::Inactive);
                Visible = ActionsEnabled and (Rec.Status = Rec.Status::Inactive);
                Scope = Repeater;

                trigger OnAction()
                begin
                    SetActive(true);
                end;
            }
            action(Deactivate)
            {
                Caption = 'Deactivate';
                ToolTip = 'Deactivate the selected server feature for this MCP configuration.';
                Image = Stop;
                Enabled = ActionsEnabled and (Rec.Status = Rec.Status::Active);
                Visible = ActionsEnabled and (Rec.Status = Rec.Status::Active);
                Scope = Repeater;

                trigger OnAction()
                begin
                    SetActive(false);
                end;
            }
            action(Configure)
            {
                Caption = 'Configure';
                Ellipsis = true;
                ToolTip = 'Open feature-specific settings for the selected server feature.';
                Image = Setup;
                Enabled = ActionsEnabled and (Rec.Status = Rec.Status::Active);
                Visible = ActionsEnabled and (Rec.Status = Rec.Status::Active);
                Scope = Repeater;

                trigger OnAction()
                begin
                    OpenSettings();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetStatusStyle();
    end;

    var
        ParentSystemId: Guid;
        ActionsEnabled: Boolean;
        StatusStyleExpr: Text;
        // MOCK: AL Query Server activation has no platform-side persistence yet, so this page-local
        // boolean stands in for the real "AL Query Server enabled" flag that should live on
        // MCP Configuration. Reset every time the card is closed. Read back via IsALQueryActive().
        ALQueryActiveLocal: Boolean;
        ALQueryDescLbl: Label 'Adds system tools that compile and run AL query code submitted by the client on demand, letting agents author ad-hoc joins and aggregates that no pre-defined API query covers. API queries and API pages added to Available Tools are exposed independently and are not affected by this feature.';

    internal procedure Reload(ConfigSystemId: Guid; CanModify: Boolean)
    begin
        ParentSystemId := ConfigSystemId;
        ActionsEnabled := CanModify;
        Rec.Reset();
        Rec.DeleteAll();
        InsertRow(Rec.Feature::"AL Query Server", ALQueryDescLbl, ALQueryActiveLocal);
        if Rec.FindFirst() then;
    end;

    // MOCK: replace with a read of the platform-side "AL Query enabled" field on MCP Configuration
    // once it exists. Used by MCPConfigCard.RefreshSubPages to drive System Tools content.
    internal procedure IsALQueryActive(): Boolean
    begin
        exit(ALQueryActiveLocal);
    end;

    local procedure InsertRow(NewFeature: Enum "MCP Server Feature"; NewDescription: Text[500]; Active: Boolean)
    begin
        Rec.Init();
        Rec.Feature := NewFeature;
        Rec.Description := NewDescription;
        if Active then
            Rec.Status := Rec.Status::Active
        else
            Rec.Status := Rec.Status::Inactive;
        Rec.Insert();
    end;

    local procedure SetActive(NewActive: Boolean)
    begin
        case Rec.Feature of
            Rec.Feature::"AL Query Server":
                ALQueryActiveLocal := NewActive;
            else
                exit;
        end;

        if NewActive then
            Rec.Status := Rec.Status::Active
        else
            Rec.Status := Rec.Status::Inactive;

        Rec.Modify();
        SetStatusStyle();
        CurrPage.Update();
    end;

    local procedure SetStatusStyle()
    begin
        if Rec.Status = Rec.Status::Active then
            StatusStyleExpr := 'Favorable'
        else
            StatusStyleExpr := '';
    end;

    local procedure OpenSettings()
    var
        ServerFeatureSettings: Page "MCP Server Feature Settings";
    begin
        ServerFeatureSettings.SetContext(ParentSystemId, Rec.Feature);
        if ServerFeatureSettings.RunModal() = Action::OK then
            ServerFeatureSettings.SaveChanges();
    end;
}
