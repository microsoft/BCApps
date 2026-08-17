// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Verifactu;

using System.DataAdministration;
using System.Environment.Configuration;
using System.IO;
using System.Security.Encryption;
using System.Text;
using System.Utilities;

codeunit 10771 "Doc. Registration Cert. Mgt."
{
    Access = Internal;

    var
        [NonDebuggable]
        TempBlob: Codeunit "Temp Blob";
        SecretCertPassword: SecretText;
        ReadingCertErr: Label 'Could not load the certificate.';
        PasswordSuffixTxt: Label 'Password', Locked = true;
        SavingPasswordErr: Label 'Could not save the password.';
        SavingCertErr: Label 'Could not save the certificate.';
        CertFileNotValidErr: Label 'This is not a valid certificate file.';
        VerifactuServiceNameTxt: Label 'Verifactu Document Registration', Locked = true;
        SecurityAuditCertSavedTxt: Label 'Verifactu certificate saved to isolated storage.', Locked = true;
        SecurityAuditCertSaveFailedTxt: Label 'Failed to save Verifactu certificate to isolated storage.', Locked = true;
        SecurityAuditCertPasswordSavedTxt: Label 'Verifactu certificate password saved to isolated storage.', Locked = true;
        SecurityAuditCertPasswordSaveFailedTxt: Label 'Failed to save Verifactu certificate password to isolated storage.', Locked = true;
        SecurityAuditCertDeletedTxt: Label 'Verifactu certificate and password deleted from isolated storage.', Locked = true;
        SecurityAuditSetupCleanedTxt: Label 'Verifactu setup deleted during environment cleanup.', Locked = true;

    internal procedure GetIsolatedCertificate(CertCode: Code[20]; var CertText: SecretText; var CertPassword: SecretText): Boolean
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        if not IsolatedCertificate.Get(CertCode) then
            exit(false);
        CertPassword := GetPasswordAsSecret(IsolatedCertificate);
        CertText := SecretStrSubstNo(GetCertAsBase64String(IsolatedCertificate));
        exit(true);
    end;

    [NonDebuggable]
    local procedure GetCertAsBase64String(IsolatedCertificate: Record "Isolated Certificate"): Text
    var
        CertificateManagement: Codeunit "Certificate Management";
        CertString: Text;
    begin
        CertString := '';
        if not IsolatedStorage.Get(IsolatedCertificate.Code, CertificateManagement.GetCertDataScope(IsolatedCertificate), CertString) then
            Error(ReadingCertErr);
        exit(CertString);
    end;

    [NonDebuggable]
    local procedure GetPasswordAsSecret(IsolatedCertificate: Record "Isolated Certificate") StoredPassword: SecretText
    begin
        GetPasswordFromIsolatedStorage(StoredPassword, IsolatedCertificate);
    end;

    [NonDebuggable]
    local procedure GetPasswordFromIsolatedStorage(var StoredPassword: SecretText; IsolatedCertificate: Record "Isolated Certificate")
    var
        CertificateManagement: Codeunit "Certificate Management";
    begin
        if IsolatedStorage.Get(IsolatedCertificate.Code + PasswordSuffixTxt, CertificateManagement.GetCertDataScope(IsolatedCertificate), StoredPassword) then;
    end;

    internal procedure DeleteCertAndPasswordFromIsolatedStorage(IsolatedCertificate: Record "Isolated Certificate")
    var
        CertificateManagement: Codeunit "Certificate Management";
        CertDataScope: DataScope;
        DeletedAny: Boolean;
    begin
        CertDataScope := CertificateManagement.GetCertDataScope(IsolatedCertificate);
        if IsolatedStorage.Contains(IsolatedCertificate.Code, CertDataScope) then begin
            IsolatedStorage.Delete(IsolatedCertificate.Code, CertDataScope);
            DeletedAny := true;
        end;
        if IsolatedStorage.Contains(IsolatedCertificate.Code + PasswordSuffixTxt, CertDataScope) then begin
            IsolatedStorage.Delete(IsolatedCertificate.Code + PasswordSuffixTxt, CertDataScope);
            DeletedAny := true;
        end;
        if DeletedAny then
            Session.LogSecurityAudit(VerifactuServiceNameTxt, SecurityOperationResult::Success, SecurityAuditCertDeletedTxt, AuditCategory::UserManagement);
    end;

    [NonDebuggable]
    internal procedure SaveCertToIsolatedStorage(IsolatedCertificate: Record "Isolated Certificate")
    var
        CertificateManagement: Codeunit "Certificate Management";
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
        CertString: Text;
    begin
        if not TempBlob.HasValue() then
            Error(CertFileNotValidErr);

        TempBlob.CreateInStream(InStream);
        CertString := Base64Convert.ToBase64(InStream);
        if not IsolatedStorage.Set(IsolatedCertificate.Code, CertString, CertificateManagement.GetCertDataScope(IsolatedCertificate)) then begin
            Session.LogSecurityAudit(VerifactuServiceNameTxt, SecurityOperationResult::Failure, SecurityAuditCertSaveFailedTxt, AuditCategory::UserManagement);
            Error(SavingCertErr);
        end;
        Session.LogSecurityAudit(VerifactuServiceNameTxt, SecurityOperationResult::Success, SecurityAuditCertSavedTxt, AuditCategory::UserManagement);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    internal procedure SavePasswordToIsolatedStorage(var IsolatedCertificate: Record "Isolated Certificate")
    var
        CertificateManagement: Codeunit "Certificate Management";
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        if SecretCertPassword.IsEmpty() then
            exit;
        if CryptographyManagement.IsEncryptionEnabled() then begin
            if not IsolatedStorage.SetEncrypted(IsolatedCertificate.Code + PasswordSuffixTxt, SecretCertPassword, CertificateManagement.GetCertDataScope(IsolatedCertificate)) then begin
                Session.LogSecurityAudit(VerifactuServiceNameTxt, SecurityOperationResult::Failure, SecurityAuditCertPasswordSaveFailedTxt, AuditCategory::UserManagement);
                Error(SavingPasswordErr);
            end;
        end else
            if not IsolatedStorage.Set(IsolatedCertificate.Code + PasswordSuffixTxt, SecretCertPassword, CertificateManagement.GetCertDataScope(IsolatedCertificate)) then begin
                Session.LogSecurityAudit(VerifactuServiceNameTxt, SecurityOperationResult::Failure, SecurityAuditCertPasswordSaveFailedTxt, AuditCategory::UserManagement);
                Error(SavingPasswordErr);
            end;
        Session.LogSecurityAudit(VerifactuServiceNameTxt, SecurityOperationResult::Success, SecurityAuditCertPasswordSavedTxt, AuditCategory::UserManagement);
    end;

    [Scope('OnPrem')]
    procedure UploadAndVerifyCert(var IsolatedCertificate: Record "Isolated Certificate"): Boolean
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
        SelectFileTxt: Label 'Select a certificate file';
        CertFileFilterTxt: Label 'Certificate Files (*.pfx, *.p12,*.p7b,*.cer,*.crt,*.der)|*.pfx;*.p12;*.p7b;*.cer;*.crt;*.der', Locked = true;
        CertExtFilterTxt: Label '.pfx.p12.p7b.cer.crt.der', Locked = true;
        UploadedCertFileName: Text;
    begin
        FileName := FileManagement.BLOBImportWithFilter(TempBlob, SelectFileTxt, FileName, CertFileFilterTxt, CertExtFilterTxt);
        if FileName = '' then
            Error('');

        UploadedCertFileName := FileManagement.GetFileName(FileName);
        exit(VerifyCert(IsolatedCertificate));
    end;

    [Scope('OnPrem')]
    procedure VerifyCert(var IsolatedCertificate: Record "Isolated Certificate"): Boolean
    var
        CertificateManagement: Codeunit "Certificate Management";
        InStr: InStream;
        CertFileNotValidDotNetTok: Label 'Cannot find the requested object.', Locked = true;
    begin
        if not TempBlob.HasValue() then
            Error(CertFileNotValidErr);

        TempBlob.CreateInStream(InStr);
        if CertificateManagement.ReadCertFromStream(SecretCertPassword, InStr) then begin
            CertificateManagement.ValidateCertFields(IsolatedCertificate);
            exit(true);
        end;

        if StrPos(GetLastErrorText, CertFileNotValidDotNetTok) <> 0 then
            Error(CertFileNotValidErr);
        exit(false);
    end;

    internal procedure LookupCertificate(var CertificateCode: Code[20])
    var
        IsolatedCertificate: Record "Isolated Certificate";
        DocRegistrationCertificates: Page "Doc. Registration Certificates";
    begin
        DocRegistrationCertificates.SetTableView(IsolatedCertificate);
        DocRegistrationCertificates.LookupMode(true);
        if CertificateCode <> '' then
            if IsolatedCertificate.Get(CertificateCode) then
                DocRegistrationCertificates.SetRecord(IsolatedCertificate);
        if DocRegistrationCertificates.RunModal() = ACTION::LookupOK then begin
            DocRegistrationCertificates.GetRecord(IsolatedCertificate);
            CertificateCode := IsolatedCertificate.Code;
        end;
    end;

    internal procedure SetCertPassword(CertificatePassword: SecretText)
    begin
        SecretCertPassword := CertificatePassword;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure HandleOnClearCompanyConfig(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        CleanupSetup(CopyStr(CompanyName, 1, 30));
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Company", 'OnAfterCreatedNewCompanyByCopyCompany', '', false, false)]
    local procedure HandleOnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30])
    begin
        CleanupSetup(NewCompanyName);
    end;

    local procedure CleanupSetup(SetupCompanyName: Text[30])
    var
        VerifactuSetup: Record "Verifactu Setup";
    begin
        if SetupCompanyName <> CompanyName() then
            VerifactuSetup.ChangeCompany(SetupCompanyName);

        if VerifactuSetup.IsEmpty() then
            exit;

        VerifactuSetup.DeleteAll();
        Session.LogSecurityAudit(VerifactuServiceNameTxt, SecurityOperationResult::Success, SecurityAuditSetupCleanedTxt, AuditCategory::ApplicationManagement);
    end;
}