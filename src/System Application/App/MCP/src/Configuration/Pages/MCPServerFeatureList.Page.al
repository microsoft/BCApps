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
                Enabled = ActionsEnabled and (Rec.Status = Rec.Status::Active) and Rec.Configurable;
                Visible = ActionsEnabled and (Rec.Status = Rec.Status::Active) and Rec.Configurable;
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

    internal procedure Reload(ConfigSystemId: Guid; CanModify: Boolean)
    var
        ServerFeature: Enum "MCP Server Feature";
        FeatureImplementations: List of [Integer];
        FeatureImplementation: Integer;
    begin
        ParentSystemId := ConfigSystemId;
        ActionsEnabled := CanModify;
        Rec.Reset();
        Rec.DeleteAll();
        FeatureImplementations := ServerFeature.Ordinals();
        foreach FeatureImplementation in FeatureImplementations do begin
            ServerFeature := "MCP Server Feature".FromInteger(FeatureImplementation);
            InsertRow(ServerFeature);
        end;
        if Rec.FindFirst() then;
    end;

    local procedure InsertRow(NewFeature: Enum "MCP Server Feature")
    var
        Handler: Interface "MCP Feature Handler";
    begin
        Handler := NewFeature;
        Rec.Init();
        Rec.Feature := NewFeature;
        Rec.Description := Handler.Description();
        if Handler.IsActive(ParentSystemId) then
            Rec.Status := Rec.Status::Active
        else
            Rec.Status := Rec.Status::Inactive;
        Rec.Configurable := Handler.HasSettings();
        Rec.Insert();
    end;

    local procedure SetActive(NewActive: Boolean)
    var
        Handler: Interface "MCP Feature Handler";
    begin
        Handler := Rec.Feature;
        Handler.SetActive(ParentSystemId, NewActive);

        if Handler.IsActive(ParentSystemId) then
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
        Handler: Interface "MCP Feature Handler";
    begin
        Handler := Rec.Feature;
        Handler.OpenSettings(ParentSystemId);
    end;
}
