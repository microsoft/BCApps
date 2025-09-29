// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

page 8435 "GitHub Codespaces Details"
{
    PageType = List;
    SourceTable = "GitHub Codespaces Details";
    SourceTableTemporary = true;
    Caption = 'GitHub Codespaces';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the codespace name';
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the human-readable codespace name';
                }
                field(State; Rec.State)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current state of the codespace';
                    Style = Strong;
                    StyleExpr = StateStyleExpr;
                }
                field("Machine Display Name"; Rec."Machine Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the machine type and specifications';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the creation date and time';
                }
                field("Last Used At"; Rec."Last Used At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last used date and time';
                }
                field(Location; Rec.Location)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the geographic location';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RefreshCodespaces)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Specifies to refresh the list of codespaces';

                trigger OnAction()
                begin
                    LoadCodespaces();
                end;
            }
            action(OpenCodespace)
            {
                ApplicationArea = All;
                Caption = 'Open in Browser';
                Image = Web;
                ToolTip = 'Specifies to open the codespace in a web browser';

                trigger OnAction()
                begin
                    if Rec."Web URL" <> '' then
                        Hyperlink(Rec."Web URL");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadCodespaces();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStateStyle();
    end;

    local procedure LoadCodespaces()
    var
        Codespaces: JsonArray;
        CodespaceToken: JsonToken;
        CodespaceObject: JsonObject;
        RepositoryObject: JsonObject;
        MachineObject: JsonObject;
        JToken: JsonToken;
        EntryNo: Integer;
        CreatedAtText: Text;
        UpdatedAtText: Text;
        LastUsedAtText: Text;
    begin
        Rec.DeleteAll();

        Codespaces := GithubAPIHelper.GetMyCodespaces();
        EntryNo := 0;

        foreach CodespaceToken in Codespaces do begin
            CodespaceObject := CodespaceToken.AsObject();
            EntryNo += 1;

            Rec.Init();
            Rec."Entry No." := EntryNo;

            // Codespace ID
            if CodespaceObject.Get('id', JToken) then
                Rec."Codespace ID" := JToken.AsValue().AsBigInteger();

            // Name
            if CodespaceObject.Get('name', JToken) then
                Rec.Name := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec.Name));

            // Display Name
            if CodespaceObject.Get('display_name', JToken) then
                if not JToken.AsValue().IsNull() then
                    Rec."Display Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Display Name"));

            // State
            if CodespaceObject.Get('state', JToken) then
                Rec.State := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec.State));

            // Web URL
            if CodespaceObject.Get('web_url', JToken) then
                Rec."Web URL" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Web URL"));

            // Location
            if CodespaceObject.Get('location', JToken) then
                Rec.Location := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec.Location));

            // Repository information
            if CodespaceObject.Get('repository', JToken) then begin
                RepositoryObject := JToken.AsObject();

                if RepositoryObject.Get('name', JToken) then
                    Rec."Repository Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Repository Name"));

                if RepositoryObject.Get('full_name', JToken) then
                    Rec."Repository Full Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Repository Full Name"));

                if RepositoryObject.Get('owner', JToken) then begin
                    RepositoryObject := JToken.AsObject();
                    if RepositoryObject.Get('login', JToken) then
                        Rec."Owner Login" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Owner Login"));
                end;
            end;

            // Machine information
            CodespaceObject := CodespaceToken.AsObject(); // Reset to main object
            if CodespaceObject.Get('machine', JToken) then begin
                MachineObject := JToken.AsObject();
                if MachineObject.Get('display_name', JToken) then
                    Rec."Machine Display Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Machine Display Name"));
            end;

            // Dates
            if CodespaceObject.Get('created_at', JToken) then begin
                CreatedAtText := JToken.AsValue().AsText();
                if Evaluate(Rec."Created At", CreatedAtText) then;
            end;

            if CodespaceObject.Get('updated_at', JToken) then begin
                UpdatedAtText := JToken.AsValue().AsText();
                if Evaluate(Rec."Updated At", UpdatedAtText) then;
            end;

            if CodespaceObject.Get('last_used_at', JToken) then begin
                LastUsedAtText := JToken.AsValue().AsText();
                if not JToken.AsValue().IsNull() then
                    if Evaluate(Rec."Last Used At", LastUsedAtText) then;
            end;

            Rec.Insert();
        end;

        if Rec.FindFirst() then;
    end;

    local procedure SetStateStyle()
    begin
        case Rec.State of
            'Available':
                StateStyleExpr := 'Favorable';
            'Shutdown':
                StateStyleExpr := 'Subordinate';
            'Starting', 'Stopping':
                StateStyleExpr := 'Ambiguous';
            else
                StateStyleExpr := 'Standard';
        end;
    end;

    procedure SetGithubAPIHelper(GHAPIHelper: Codeunit "Github API Helper")
    begin
        GithubAPIHelper := GHAPIHelper;
    end;

    var
        GithubAPIHelper: Codeunit "Github API Helper";
        StateStyleExpr: Text;
}