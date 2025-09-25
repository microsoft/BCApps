// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

page 8430 "Create New Repository Dialog"
{
    PageType = StandardDialog;
    Caption = 'Create New Repository from Template';

    layout
    {
        area(Content)
        {
            label(TemplateInfoLbl)
            {
                ApplicationArea = All;
                Caption = 'Create a new GitHub repository from a predefined template.\This will create a copy of the AL-Go-PTE template with your specified name.\The new repository will be ready for AL development.';
            }

            field(RepositoryName; RepositoryName)
            {
                ApplicationArea = All;
                Caption = 'Repository Name';
                ToolTip = 'Specifies the name for the new GitHub repository.';
                NotBlank = true;

                trigger OnValidate()
                begin
                    // Validate repository name format
                    if not IsValidRepositoryName(RepositoryName) then
                        Error('Repository name can only contain letters, numbers, hyphens, and underscores.');
                end;
            }

            field(OwnerName; OwnerName)
            {
                ApplicationArea = All;
                Caption = 'Owner';
                ToolTip = 'Specifies the GitHub username or organization that will own the new repository.';
                NotBlank = true;
            }

            field(RepositoryDescription; RepositoryDescription)
            {
                ApplicationArea = All;
                Caption = 'Description';
                ToolTip = 'Specifies the description for the new repository.';
                MultiLine = true;
            }

            field(IsPrivate; IsPrivate)
            {
                ApplicationArea = All;
                Caption = 'Private Repository';
                ToolTip = 'Specifies whether to create a private repository.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(CreateRepository)
            {
                ApplicationArea = All;
                Caption = 'Create Repository';
                ToolTip = 'Create the new repository from template';
                Image = NewDocument;
                InFooterBar = true;

                trigger OnAction()
                var
                    CodespacesHelper: Codeunit "Github API Helper";
                    ConfirmMsg: Label 'Create repository "%1" from template %2/%3?', Comment = '%1 = Repository Name, %2 = Template Owner, %3 = Template Repository';
                begin
                    if RepositoryName = '' then
                        Error('Repository name is required.');

                    if OwnerName = '' then
                        Error('Owner name is required.');

                    if Confirm(ConfirmMsg, false, RepositoryName, TemplateOwner, TemplateRepository) then begin
                        CodespacesHelper.CreateRepoFromTemplate(
                            TemplateOwner,
                            TemplateRepository,
                            OwnerName,
                            RepositoryName,
                            RepositoryDescription,
                            IsPrivate
                        );

                        Message('Repository "%1" created successfully!', RepositoryName);
                        CurrPage.Close();
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Set default values
        TemplateOwner := 'microsoft';
        TemplateRepository := 'AL-Go-PTE';
        OwnerName := 'blrobl'; // Default to current user
        RepositoryDescription := 'Business Central AL extension repository created from template';
        IsPrivate := false;
    end;

    local procedure IsValidRepositoryName(Name: Text): Boolean
    var
        i: Integer;
        Char: Char;
    begin
        if Name = '' then
            exit(false);

        // Check each character
        for i := 1 to StrLen(Name) do begin
            Char := Name[i];
            if not (Char in ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '-', '_']) then
                exit(false);
        end;

        // Repository name cannot start or end with hyphen
        if (Name[1] = '-') or (Name[StrLen(Name)] = '-') then
            exit(false);

        exit(true);
    end;

    procedure GetRepositoryName(): Text
    begin
        exit(RepositoryName);
    end;

    procedure GetOwnerName(): Text
    begin
        exit(OwnerName);
    end;

    var
        RepositoryName: Text[100];
        RepositoryDescription: Text[250];
        OwnerName: Text[100];
        TemplateOwner: Text[100];
        TemplateRepository: Text[100];
        IsPrivate: Boolean;
}