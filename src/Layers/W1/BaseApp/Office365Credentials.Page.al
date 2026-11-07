// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
page 1312 "Office 365 Credentials"
{
    Caption = 'Office 365 Credentials';
    PageType = StandardDialog;
    Permissions = TableData "Office Admin. Credentials" = rimd;
    SourceTable = "Office Admin. Credentials";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control7)
            {
                InstructionalText = 'Provide your Office 365 email address and password:';
                ShowCaption = false;
                field(Email; Rec.Email)
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address that is associated with the Office 365 account.';
                }
                field(Password; PasswordText)
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password that is associated with the Office 365 account.';

                    trigger OnValidate()
                    begin
                        if (PasswordText <> '') and (not EncryptionEnabled()) then
                            if Confirm(CryptographyManagement.GetEncryptionIsNotActivatedQst()) then
                                PAGE.RunModal(PAGE::"Data Encryption Management");
                    end;
                }
                field(StatusText; StatusText)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    Style = Attention;
                    StyleExpr = true;
                }
                field(WhySignInIsNeededLbl; WhySignInIsNeededLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Message(WhySignInIsNeededDescriptionMsg);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        StatusText := GetLastErrorText;
    end;

    trigger OnOpenPage()
    begin
        SetPasswordGlobal();
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
        StatusText: Text;
        WhySignInIsNeededLbl: Label 'Why do I have to sign in to Office 365 now?';
        WhySignInIsNeededDescriptionMsg: Label 'To set up the Business Inbox in Outlook, we need your permission to install two add-ins in Office 365.';
        [NonDebuggable]
        PasswordText: Text;

    [NonDebuggable]
    local procedure SetPasswordGlobal()
    begin
        PasswordText := Rec.GetPasswordAsSecretText().Unwrap();
    end;

}

