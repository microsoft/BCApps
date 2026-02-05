// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Displays an account that was registered via the SFTP connector.
/// </summary>
page 4621 "Ext. SFTP Account"
{
    ApplicationArea = All;
    Caption = 'SFTP Account';
    DataCaptionExpression = Rec.Name;
    Extensible = false;
    InsertAllowed = false;
    PageType = Card;
    Permissions = tabledata "Ext. SFTP Account" = rimd;
    SourceTable = "Ext. SFTP Account";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameField; Rec.Name)
            {
                NotBlank = true;
                ShowMandatory = true;
            }
            field(Hostname; Rec.Hostname) { }
            field(Port; Rec.Port) { }
            field(Fingerprints; Rec.Fingerprints) { }
            field("Base Relative Folder Path"; Rec."Base Relative Folder Path") { }
            field("Authentication Type"; Rec."Authentication Type")
            {
                trigger OnValidate()
                begin
                    MaskSensitiveFields();
                    UpdateAuthTypeVisibility();
                    CurrPage.Update(true);
                end;
            }
            field(Username; Rec.Username) { }
            group(Credentials)
            {
                Caption = 'Credentials';
                Editable = PageEditable;

                group(SFTPPasswordGroup)
                {
                    ShowCaption = false;
                    Visible = PasswordVisible;

                    field(PasswordField; Password)
                    {
                        Caption = 'Password';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the Password to access the SFTP Server.';
                        trigger OnValidate()
                        begin
                            Rec.SetPassword(Password);
                        end;
                    }
                }
                group(SFTPCertificateGroup)
                {
                    ShowCaption = false;
                    Visible = CertificateVisible;

                    field(CertificateUploadStatus; CertificateStatusText)
                    {
                        Caption = 'Certificate';
                        Editable = false;
                        ToolTip = 'Specifies the key file used for authentication. Click here to upload a key file (.pk, .ppk, or .pub).';

                        trigger OnDrillDown()
                        begin
                            Certificate := Rec.UploadCertificateFile();
                            Rec.SetCertificate(Certificate);
                            UpdateCertificateStatus();
                        end;
                    }

                    field(CertificatePasswordField; CertificatePassword)
                    {
                        Caption = 'Certificate Password';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password used to protect the private key in the certificate. Leave empty if the certificate is not password-protected.';

                        trigger OnValidate()
                        begin
                            Rec.SetCertificatePassword(CertificatePassword);
                        end;
                    }
                }
            }
            field(Disabled; Rec.Disabled) { }
        }
    }

    var
        PageEditable: Boolean;
        PasswordVisible: Boolean;
        CertificateVisible: Boolean;
        [NonDebuggable]
        Password: Text;
        [NonDebuggable]
        CertificatePassword, Certificate : Text;
        CertificateStatusText: Text;

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Name);
        UpdateAuthTypeVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        PageEditable := CurrPage.Editable();

        MaskSensitiveFields();
        UpdateAuthTypeVisibility();
        UpdateCertificateStatus();
    end;

    local procedure MaskSensitiveFields()
    begin
        Clear(Password);
        Clear(Certificate);
        Clear(CertificatePassword);

        if not IsNullGuid(Rec."Password Key") then
            Password := '***';

        if not IsNullGuid(Rec."Certificate Password Key") then
            CertificatePassword := '***';
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
        NoCertificateLbl: Label 'No certificate (click to upload)';
        CertificateUploadedLbl: Label 'Certificate uploaded (click to change)';
    begin
        if IsNullGuid(Rec."Certificate Key") then
            CertificateStatusText := NoCertificateLbl
        else
            CertificateStatusText := CertificateUploadedLbl;
    end;
}