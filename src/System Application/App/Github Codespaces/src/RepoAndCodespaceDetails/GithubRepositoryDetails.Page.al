// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

page 8433 "GitHub Repository Details"
{
    PageType = List;
    SourceTable = "GitHub Repository Details";
    SourceTableTemporary = true;
    Caption = 'GitHub Repositories';
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
                field("Repository Name"; Rec."Repository Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the repository name';
                }
                field("Owner Login"; Rec."Owner Login")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the repository owner username';
                }
                field("Full Name"; Rec."HTML URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the hyperlink to the repository on GitHub';
                    ExtendedDatatype = URL;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the repository description';
                }
                field(Private; Rec.Private)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the repository is private';
                }
                field("Is Template"; Rec."Is Template")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the repository is a template';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RefreshRepositories)
            {
                ApplicationArea = All;
                Caption = 'Refresh Repositories';
                Image = Refresh;
                ToolTip = 'Specifies to refresh the list of repositories from GitHub';

                trigger OnAction()
                begin
                    LoadRepositories();
                end;
            }
            action(OpenInBrowser)
            {
                ApplicationArea = All;
                Caption = 'Open in Browser';
                Image = Web;
                ToolTip = 'Specifies to open the repository in a web browser';

                trigger OnAction()
                begin
                    if Rec."HTML URL" <> '' then
                        Hyperlink(Rec."HTML URL");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadRepositories();
    end;

    local procedure LoadRepositories()
    var
        Repositories: JsonArray;
        RepoToken: JsonToken;
        RepoObject: JsonObject;
        JToken: JsonToken;
        EntryNo: Integer;
    begin
        Rec.DeleteAll();

        Repositories := GithubAPIHelper.GetMyRepositories();
        EntryNo := 0;

        foreach RepoToken in Repositories do begin
            RepoObject := RepoToken.AsObject();
            EntryNo += 1;

            Rec.Init();
            Rec."Entry No." := EntryNo;

            // Repository ID
            if RepoObject.Get('id', JToken) then
                Rec."Repository ID" := JToken.AsValue().AsBigInteger();

            // Repository Name
            if RepoObject.Get('name', JToken) then
                Rec."Repository Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Repository Name"));

            // Full Name
            if RepoObject.Get('full_name', JToken) then
                Rec."Full Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Full Name"));

            // Description
            if RepoObject.Get('description', JToken) then
                if not JToken.AsValue().IsNull() then
                    Rec.Description := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec.Description));

            // HTML URL
            if RepoObject.Get('html_url', JToken) then
                Rec."HTML URL" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."HTML URL"));

            // Private
            if RepoObject.Get('private', JToken) then
                Rec.Private := JToken.AsValue().AsBoolean();

            // Is Template
            if RepoObject.Get('is_template', JToken) then
                Rec."Is Template" := JToken.AsValue().AsBoolean();

            // Owner information
            if RepoObject.Get('owner', JToken) then begin
                RepoObject := JToken.AsObject();
                if RepoObject.Get('login', JToken) then
                    Rec."Owner Login" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Owner Login"));
                if RepoObject.Get('type', JToken) then
                    Rec."Owner Type" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec."Owner Type"));
            end;

            Rec.Insert();
        end;

        if Rec.FindFirst() then;
    end;

    procedure SetGithubAPIHelper(GHAPIHelper: Codeunit "Github API Helper")
    begin
        GithubAPIHelper := GHAPIHelper;
    end;

    var
        GithubAPIHelper: Codeunit "Github API Helper";
}