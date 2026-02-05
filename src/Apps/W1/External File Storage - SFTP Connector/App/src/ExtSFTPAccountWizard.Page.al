// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Environment;

/// <summary>
/// Displays an account that is being registered via the SFTP connector.
/// </summary>
page 4622 "Ext. SFTP Account Wizard"
{
    ApplicationArea = All;
    Caption = 'Setup SFTP Account';
    Editable = true;
    Extensible = false;
    PageType = NavigatePage;
    Permissions = tabledata "Ext. SFTP Account" = rimd;
    SourceTable = "Ext. SFTP Account";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(TopBanner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible;
                field(NotDoneIcon; MediaResources."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = ' ', Locked = true;
                }
            }

            field(NameField; Rec.Name)
            {
                Caption = 'Account Name';
                NotBlank = true;
                ShowMandatory = true;
                ToolTip = 'Specifies a descriptive name for this SFTP storage account connection.';

                trigger OnValidate()
                begin
                    IsNextEnabled := ConnectorImpl.IsAccountValid(Rec);
                end;
            }
            field(Hostname; Rec.Hostname)
            {
                NotBlank = true;
                ShowMandatory = true;

                trigger OnValidate()
                begin
                    IsNextEnabled := ConnectorImpl.IsAccountValid(Rec);
                end;
            }
            field(Port; Rec.Port)
            {
                NotBlank = true;
                ShowMandatory = true;

                trigger OnValidate()
                begin
                    IsNextEnabled := ConnectorImpl.IsAccountValid(Rec);
                end;
            }
            field(Fingerprints; Rec.Fingerprints)
            {
                Caption = 'Fingerprints';
                ShowMandatory = true;

                trigger OnValidate()
                begin
                    IsNextEnabled := ConnectorImpl.IsAccountValid(Rec);
                end;
            }
            field("Authentication Type"; Rec."Authentication Type")
            {
                ToolTip = 'Specifies the authentication method used for this SFTP account. Password uses username and password authentication. Certificate uses SSH key-based authentication.';
                trigger OnValidate()
                begin
                    UpdateAuthTypeVisibility();
                    IsNextEnabled := ConnectorImpl.IsAccountValid(Rec);
                end;
            }
            field(Username; Rec.Username)
            {
                NotBlank = true;
                ShowMandatory = true;

                trigger OnValidate()
                begin
                    IsNextEnabled := ConnectorImpl.IsAccountValid(Rec);
                end;
            }
            group(PasswordGroup)
            {
                ShowCaption = false;
                Visible = PasswordVisible;

                field(Password; Password)
                {
                    Caption = 'Password';
                    ExtendedDatatype = Masked;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the Password to access the SFTP Server.';
                }
            }
            group(CertificateGroup)
            {
                ShowCaption = false;
                Visible = CertificateVisible;

                field(CertificateUploadStatus; CertificateStatusText)
                {
                    Caption = 'Certificate';
                    Editable = false;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the key file used for authentication. Click here to upload a key file (.pk, .ppk, or .pub).';

                    trigger OnDrillDown()
                    begin
                        Certificate := Rec.UploadCertificateFile();
                        UpdateCertificateStatus();
                        IsNextEnabled := ConnectorImpl.IsAccountValid(Rec);
                    end;
                }

                field(CertificatePasswordField; CertificatePassword)
                {
                    Caption = 'Certificate Password';
                    ExtendedDatatype = Masked;
                    ShowMandatory = false;
                    ToolTip = 'Specifies the password used to protect the private key in the certificate. Leave empty if the certificate is not password-protected.';
                }
            }

            field("Base Relative Folder Path"; Rec."Base Relative Folder Path")
            {
                ShowMandatory = true;

                trigger OnValidate()
                begin
                    IsNextEnabled := ConnectorImpl.IsAccountValid(Rec);
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Back)
            {
                Caption = 'Back';
                Image = Cancel;
                InFooterBar = true;
                ToolTip = 'Move to previous step.';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
            action(Next)
            {
                Caption = 'Next';
                Enabled = IsNextEnabled;
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Move to next step.';

                trigger OnAction()
                begin
                    ConnectorImpl.CreateAccount(Rec, Password, Certificate, CertificatePassword, Account);
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        Account: Record "File Account";
        MediaResources: Record "Media Resources";
        ConnectorImpl: Codeunit "Ext. SFTP Connector Impl";
        [NonDebuggable]
        Password, CertificatePassword, Certificate : Text;
        CertificateStatusText: Text;
        IsNextEnabled: Boolean;
        TopBannerVisible: Boolean;
        PasswordVisible, CertificateVisible : Boolean;

    trigger OnOpenPage()
    var
        AssistedSetupLogoTok: Label 'ASSISTEDSETUP-NOTEXT-400PX.PNG', Locked = true;
    begin
        Rec.Init();
        Rec.Insert();

        if MediaResources.Get(AssistedSetupLogoTok) and (CurrentClientType() = ClientType::Web) then
            TopBannerVisible := MediaResources."Media Reference".HasValue();

        UpdateAuthTypeVisibility();
        UpdateCertificateStatus();
    end;

    internal procedure GetAccount(var FileAccount: Record "File Account"): Boolean
    begin
        if IsNullGuid(Account."Account Id") then
            exit(false);

        FileAccount := Account;

        exit(true);
    end;

    local procedure UpdateAuthTypeVisibility()
    begin
        PasswordVisible := Rec."Authentication Type" = Enum::"Ext. SFTP Auth Type"::Password;
        CertificateVisible := Rec."Authentication Type" = Enum::"Ext. SFTP Auth Type"::Certificate;

        if CertificateVisible then
            UpdateCertificateStatus();
    end;

    local procedure UpdateCertificateStatus()
    var
        NoCertificateUploadedLbl: Label 'Click to upload certificate file...';
        CertificateUploadedLbl: Label 'Certificate uploaded (click to change)';
    begin
        if Certificate = '' then
            CertificateStatusText := NoCertificateUploadedLbl
        else
            CertificateStatusText := CertificateUploadedLbl;
    end;
}