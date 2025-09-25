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
                Visible = false;

                field(GitUserName; GitUserName)
                {
                    Caption = 'Git Username';
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Specifies your Git username.';
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

                label(RepositorySetupInstructionLbl)
                {
                    ApplicationArea = All;
                    Caption = 'You can create a new repository from a template or select an existing one.';
                }

                group(SelectExistingRepository)
                {
                    Editable = true;
                    Caption = 'Select an existing repository';
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
                }

                group(SetupNewRepository)
                {
                    ShowCaption = false;
                    InstructionalText = 'Alternatively, click here to create a new repository.';

                    field(CreateRepository; 'Create new repository')
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        ToolTip = 'Create a new GitHub repository from a template for Codespaces.';
                        Editable = false;
                        Visible = ShowRepositorySetup;

                        trigger OnDrillDown()
                        var
                            CreateRepo: Page "Create New Repository Dialog";
                        begin
                            if CreateRepo.RunModal() = Action::LookupOK then begin
                                RepositoryName := CreateRepo.GetRepositoryName();
                                CurrPage.Update();
                                Message('Repository %1 created successfully.', RepositoryName);
                            end;
                        end;
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

                label(CodespaceSetupInstructionLbl)
                {
                    ApplicationArea = All;
                    Caption = 'You can create a new codespace or select an existing one.';
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
                        var
                            CodespacesHelper: Codeunit "Github API Helper";
                            CodespaceURLLbl: Label 'https://%1.github.dev/', Comment = '%1: Codespace Name';
                        begin
                            if RepositoryName = '' then
                                Error('Please select or create a repository first.');
                            CodespaceName := CodespacesHelper.CreateCodespaceInRepo(GitUserName, RepositoryName);
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
            action(MoveToCodespaceSetup)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = IsRepositorySet;
                Visible = ShowRepositorySetup;
                InFooterBar = true;
                Image = NextRecord;

                trigger OnAction()
                begin
                    ShowRepositorySetup := false;
                    IsCodespaceSetupVisible := true;
                    CurrPage.Update();
                end;
            }
            action(LaunchCodespace)
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
        if Rec."Source Repository Url" <> '' then begin
            IsRepositorySet := true;
            RepositoryName := Rec."Source Repository Url";
        end else
            ShowRepositorySetup := true;

        GitUserName := 'blrobl';
        CurrPage.Update();
    end;

    var
        ShowRepositorySetup: Boolean;
        IsRepositorySet: Boolean;
        IsCodespaceSetupVisible: Boolean;
        RepositoryName: Text;
        GitUserName: Text;

        CodespaceName: Text;
        CodespaceWebUrl: Text;
        IsCodespaceSelected: Boolean;
}