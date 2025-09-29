// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

using System.Apps;

page 8432 "Codespaces Config. Wizard"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Published Application";
    Editable = true;
    Caption = 'GitHub Codespaces Setup Wizard';

    layout
    {
        area(Content)
        {
            group(ConfigureGitUser)
            {
                Caption = 'Configure Git User';
                InstructionalText = 'Set your Git username and email to associate commits with your identity.';
                Visible = ConfigureGitHub;

                field(GitUserName; GitUserName)
                {
                    Caption = 'Git Username';
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Specifies your Git username.';

                    trigger OnValidate()
                    begin
                        GithubAPIHelper.SetGitHubUserName(GitUserName);
                    end;
                }

                field(AccessToken; AccessToken)
                {
                    Caption = 'GitHub Access Token';
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Specifies your GitHub access token with repo permissions.';
                    MaskType = Concealed;

                    trigger OnValidate()
                    begin
                        GithubAPIHelper.SetGitHubAccessToken(AccessToken);
                    end;
                }
            }

            group(SetupRepository)
            {
                Caption = 'Setup Repository';
                Editable = true;
                Visible = ShowRepositorySetup;

                label(RepositorySetupLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Currently there is no repository set up for this extension.';
                }

                group(SelectRepository)
                {
                    Editable = true;
                    Caption = 'Select a repository';
                    InstructionalText = 'Select an existing GitHub repository to use with Codespaces.';

                    field(SelectRepositoryName; RepositoryName)
                    {
                        ApplicationArea = All;
                        Editable = true;
                        ToolTip = 'Enter the name for the new GitHub repository.';
                        Lookup = true;
                        ShowCaption = false;
                        LookupPageId = "GitHub Repository Details";

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GitHubRepo: Record "GitHub Repository Details";
                            GitHubRepoPage: Page "GitHub Repository Details";
                        begin
                            GitHubRepoPage.SetGithubAPIHelper(GithubAPIHelper);
                            GitHubRepoPage.LookupMode(true);
                            if GitHubRepoPage.RunModal() = Action::LookupOK then begin
                                GitHubRepoPage.GetRecord(GitHubRepo);
                                Text := GitHubRepo."Repository Name";
                                CurrPage.Update();
                            end;
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            IsRepositorySet := RepositoryName <> '';
                            CurrPage.Update();
                        end;

                    }
                    group(SetupNewRepository)
                    {
                        ShowCaption = false;
                        InstructionalText = 'Alternatively, click here to create a new repository.';

                        field(CreateRepository; 'Create a repository for a new AL extension')
                        {
                            ApplicationArea = All;
                            ShowCaption = false;
                            ToolTip = 'Create a new GitHub repository from a template for Codespaces.';
                            Editable = false;

                            trigger OnDrillDown()
                            begin
                                if CreateNewRepositoryDialog.RunModal() = Action::LookupOK then begin
                                    RepositoryName := CreateNewRepositoryDialog.GetRepositoryName();
                                    CurrPage.Update();
                                    Message('Repository %1 created successfully.', RepositoryName);
                                end;
                            end;
                        }
                    }
                }
                group(Configuration)
                {
                    Caption = 'Configuration';
                    Editable = true;

                    field(ConfigureRepository; ConfigureRepository)
                    {
                        ApplicationArea = All;
                        Caption = 'Configure your AL extension for this environment';
                        ToolTip = 'Specifies whether to update project configuration files in the selected repository to match this environment.';
                        Editable = true;
                    }
                }
            }

            group(CodespaceSetup)
            {
                Caption = 'Codespace Setup';
                Editable = true;
                Visible = IsCodespaceSetupVisible;

                label(CodespaceSetupLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Set up your Codespace in the selected repository.';
                }

                group(SelectExistingCodespace)
                {
                    Editable = true;
                    Caption = 'Select an existing codespace';
                    InstructionalText = 'Select an existing GitHub Codespace to open. This will show all your available codespaces.';
                    Visible = IsCodespaceSetupVisible;

                    field(SelectCodespaceName; CodespaceName)
                    {
                        ApplicationArea = All;
                        Editable = true;
                        ToolTip = 'Specifies an existing codespace to open.';
                        Lookup = true;
                        Caption = 'Codespace Name';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GitHubCodespace: Record "GitHub Codespaces Details";
                            GitHubCodespacePage: Page "GitHub Codespaces Details";
                        begin
                            GitHubCodespacePage.LookupMode(true);
                            GitHubCodespace.SetFilter("Repository Name", RepositoryName);
                            GitHubCodespacePage.SetTableView(GitHubCodespace);
                            GitHubCodespacePage.SetGithubAPIHelper(GithubAPIHelper);
                            if GitHubCodespacePage.RunModal() = Action::LookupOK then begin
                                GitHubCodespacePage.GetRecord(GitHubCodespace);
                                Text := GitHubCodespace.Name;
                                CodespaceWebUrl := GitHubCodespace."Web URL";
                                CurrPage.Update();
                            end;
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            IsCodespaceSelected := CodespaceName <> '';
                            CurrPage.Update();
                        end;
                    }
                }
                group(SetupNewCodespace)
                {
                    ShowCaption = false;
                    InstructionalText = 'Alternatively, click here to create a new codespace.';

                    field(CreateNewCodespace; 'Create new codespace')
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'Create new codespace';
                        ToolTip = 'Create a new codespace in the selected repository and open it in your browser.';
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            if RepositoryName = '' then
                                Error('Please select or create a repository first.');
                            CodespaceName := GithubAPIHelper.CreateCodespaceInRepo(GitUserName, RepositoryName);
                            CodespaceWebUrl := StrSubstNo(CodespaceURLLbl, CodespaceName);
                            IsCodespaceSelected := true;
                            CurrPage.Update();
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(SetupRepositoryAction)
            {
                ApplicationArea = All;
                Caption = 'Create Repository';
                ToolTip = 'Set up the GitHub repository for Codespaces.';
                Visible = false;
                InFooterBar = true;
                Image = NextSet;

                trigger OnAction()
                begin
                    if CreateNewRepositoryDialog.RunModal() = Action::LookupOK then begin
                        RepositoryName := CreateNewRepositoryDialog.GetRepositoryName();
                        CurrPage.Update();
                        Message('Repository %1 created successfully.', RepositoryName);
                    end;
                end;
            }
            action(MoveToRepositorySetup)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = true;
                Visible = ConfigureGitHub;
                InFooterBar = true;
                Image = NextSet;

                trigger OnAction()
                begin
                    if Rec."Source Repository Url" <> '' then begin
                        IsRepositorySet := true;
                        IsCodespaceSetupVisible := true;
                        RepositoryName := Rec."Source Repository Url";
                    end else
                        ShowRepositorySetup := true;
                    ConfigureGitHub := false;
                    CreateNewRepositoryDialog.SetGithubAPIHelper(GithubAPIHelper);
                    CurrPage.Update();
                end;
            }
            action(MoveToCodespaceSetup)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = IsRepositorySet;
                Visible = ShowRepositorySetup;
                InFooterBar = true;
                Image = NextSet;

                trigger OnAction()
                var
                    AlProjectConfiguration: Codeunit "AL Project Configuration";
                begin
                    // Push current AL request configuration to the repository
                    if ConfigureRepository then begin
                        AlProjectConfiguration.SetGithubAPIHelper(GithubAPIHelper);
                        if AlProjectConfiguration.PushCurrentAlRequestConfigToRepository(GitUserName, RepositoryName) then
                            Message('AL request configuration pushed to repository successfully.');
                    end;

                    ShowRepositorySetup := false;
                    IsCodespaceSetupVisible := true;
                    CurrPage.Update();
                end;
            }
            action(LaunchNewCodespace)
            {
                ApplicationArea = All;
                Caption = 'Launch New Codespace';
                ToolTip = ' Create a new codespace in the selected repository and open it in your browser.';
                Visible = false;
                InFooterBar = true;
                Image = LaunchWeb;

                trigger OnAction()
                var
                    CodespaceName: Text;
                begin
                    CodespaceName := GitHubApiHelper.CreateCodespaceInRepo(GitUserName, RepositoryName);
                    Hyperlink(StrSubstNo(CodespaceURLLbl, CodespaceName));
                    CurrPage.Close();
                end;
            }
            action(OpenSelectedCodespace)
            {
                ApplicationArea = All;
                Caption = 'Open Codespace';
                ToolTip = 'Open the selected codespace in your browser.';
                Visible = IsCodespaceSetupVisible;
                Enabled = IsCodespaceSelected;
                InFooterBar = true;
                Image = LaunchWeb;

                trigger OnAction()
                begin
                    if CodespaceWebUrl <> '' then
                        Hyperlink(CodespaceWebUrl);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ConfigureGitHub := true;
        CurrPage.Update();
    end;

    var
        GithubAPIHelper: Codeunit "Github API Helper";
        CreateNewRepositoryDialog: Page "Create New Repository Dialog";
        CodespaceURLLbl: Label 'https://%1.github.dev/', Comment = '%1: Codespace Name';
        ShowRepositorySetup: Boolean;
        IsRepositorySet: Boolean;
        IsCodespaceSetupVisible: Boolean;
        RepositoryName: Text;
        GitUserName: Text;
        CodespaceName: Text;
        CodespaceWebUrl: Text;
        IsCodespaceSelected: Boolean;
        ConfigureRepository: Boolean;
        ConfigureGitHub: Boolean;
        AccessToken: Text;
}