// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using System.Security.Encryption;

page 1612 "Office Admin. Credentials"
{
    Caption = 'Office Admin. Credentials';
    DeleteAllowed = false;
    InsertAllowed = true;
    ModifyAllowed = true;
    MultipleNewLines = false;
    PageType = NavigatePage;
    Permissions = TableData "Office Admin. Credentials" = rimd;
    SaveValues = true;
    SourceTable = "Office Admin. Credentials";

    layout
    {
        area(content)
        {
            group(Question)
            {
                Caption = '';
                Visible = QuestionVisible;
                field(UseO365; EmailHostedInO365)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Are you using an Office 365 mailbox?';
                    DrillDown = true;
                }
            }
            group(O365Credential)
            {
                Caption = '';
                Visible = O365CredentialVisible;
                field(O365Email; Rec.Email)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Office 365 admin email address';
                    ExtendedDatatype = EMail;
                    NotBlank = true;
                }
                field(O365Password; PasswordText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Office 365 admin password';
                    ExtendedDatatype = Masked;
                    NotBlank = true;

                    trigger OnValidate()
                    begin
                        if (PasswordText <> '') and (not EncryptionEnabled()) then
                            if Confirm(CryptographyManagement.GetEncryptionIsNotActivatedQst()) then
                                PAGE.RunModal(PAGE::"Data Encryption Management");
                    end;
                }
            }
            group(OnPremCredential)
            {
                Caption = '';
                Visible = OnPremCredentialVisible;
                field(OnPremUsername; Rec.Email)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exchange admin username';
                    ExtendedDatatype = EMail;
                    NotBlank = true;
                }
                field(OnPremPassword; PasswordText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exchange admin password';
                    ExtendedDatatype = Masked;
                    NotBlank = true;

                    trigger OnValidate()
                    begin
                        if (PasswordText <> '') and (not EncryptionEnabled()) then
                            if Confirm(CryptographyManagement.GetEncryptionIsNotActivatedQst()) then
                                PAGE.RunModal(PAGE::"Data Encryption Management");
                    end;
                }
                field(Endpoint; Rec.Endpoint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exchange PowerShell Endpoint';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if (Rec.Email = '') or (PasswordText = '') or (EmailHostedInO365 and (Rec.Endpoint = '')) then
                        Error(MissingCredentialErr);

                    if not Rec.Insert(true) then
                        Rec.Modify(true);

                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowQuestion();
        EmailHostedInO365 := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction = ACTION::OK) or (CloseAction = ACTION::LookupOK) then begin
            if not Rec.Get() then
                Rec.Insert();
            Rec.SavePassword(PasswordText);
        end;
    end;

    var
        CryptographyManagement: Codeunit "Cryptography Management";
        Step: Option Question,O365Credential,OnPremCredential;
        EmailHostedInO365: Boolean;
        QuestionVisible: Boolean;
        O365CredentialVisible: Boolean;
        OnPremCredentialVisible: Boolean;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        MissingCredentialErr: Label 'You must specify both an email address and a password.';
        [NonDebuggable]
        PasswordText: Text;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::Question:
                ShowQuestion();
            Step::O365Credential:
                ShowO365Credential(Backwards);
            Step::OnPremCredential:
                ShowOnPremCredential();
        end;

        CurrPage.Update(true);
    end;

    local procedure ShowQuestion()
    begin
        ResetControls();

        BackEnabled := false;
        QuestionVisible := true;
    end;

    local procedure ShowO365Credential(Backwards: Boolean)
    begin
        ResetControls();

        // Skip to the next window if we're not using O365.
        if not EmailHostedInO365 then begin
            NextStep(Backwards);
            exit;
        end;

        FinishEnabled := true;
        NextEnabled := false;
        O365CredentialVisible := true;
    end;

    local procedure ShowOnPremCredential()
    begin
        ResetControls();

        FinishEnabled := true;
        NextEnabled := false;
        OnPremCredentialVisible := true;
    end;

    local procedure ResetControls()
    begin
        NextEnabled := true;
        BackEnabled := true;
        FinishEnabled := false;

        QuestionVisible := false;
        O365CredentialVisible := false;
        OnPremCredentialVisible := false;
    end;
}

