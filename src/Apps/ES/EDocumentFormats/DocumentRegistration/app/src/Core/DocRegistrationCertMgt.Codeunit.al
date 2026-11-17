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
        // DER-encoded OIDs (tag, length and value): extension OIDs from RFC 5280 / RFC 3739, QcType from ETSI EN 319 412-5,
        // legal person policies (QCP-l / QCP-l-qscd) from ETSI EN 319 411-2
#pragma warning disable AA0240 // DER-encoded OID bytes, not phone numbers
        QcStatementsExtensionOidTok: Label '06082B06010505070103', Locked = true;
        CertificatePoliciesExtensionOidTok: Label '0603551D20', Locked = true;
        QcTypeStatementOidTok: Label '060604008E460106', Locked = true;
        QcTypeESealOidTok: Label '060704008E46010602', Locked = true;
        PolicyQcpLegalOidTok: Label '060704008BEC400101', Locked = true;
        PolicyQcpLegalQscdOidTok: Label '060704008BEC400103', Locked = true;
#pragma warning restore AA0240
        SequenceTagTok: Label '30', Locked = true;
        ObjectIdentifierTagTok: Label '06', Locked = true;
        OctetStringTagTok: Label '04', Locked = true;
        BooleanTagTok: Label '01', Locked = true;
        ExtensionsTagTok: Label 'A3', Locked = true;
        HexDigitsTok: Label '0123456789ABCDEF', Locked = true;

    /// <summary>
    /// Detects whether the certificate is an electronic seal certificate. Returns false when the certificate cannot be read.
    /// </summary>
    internal procedure TryGetIsSealCertificate(CertCode: Code[20]; var IsSeal: Boolean): Boolean
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        IsSeal := false;
        if CertCode = '' then
            exit(false);
        // Users without access to certificates can still open Verifactu Setup; the certificate type is then not detected.
        if not IsolatedCertificate.ReadPermission() then
            exit(false);
        if not IsolatedCertificate.Get(CertCode) then
            exit(false);
        exit(TryDetectSealCertificate(IsolatedCertificate, IsSeal));
    end;

    /// <summary>
    /// Returns true only when the certificate explicitly identifies itself as an electronic seal, through the eIDAS QcType eSeal
    /// in the QcStatements extension or a legal person policy (QCP-l / QCP-l-qscd) in the CertificatePolicies extension.
    /// Any other certificate, including one that cannot be parsed, keeps using the standard endpoint.
    /// </summary>
    internal procedure IsSealCertificateData(RawCertDataBase64: Text): Boolean
    var
        CertDataHex, TagHex : Text;
        CertContentPos, CertContentLen, TbsContentPos, TbsContentLen, TbsEnd, Pos, ContentPos, ContentLen : Integer;
    begin
        CertDataHex := ConvertBase64ToHex(RawCertDataBase64);
        // Certificate ::= SEQUENCE { tbsCertificate TBSCertificate, signatureAlgorithm, signatureValue }
        if not ReadDerElement(CertDataHex, 0, StrLen(CertDataHex) div 2, TagHex, CertContentPos, CertContentLen) then
            exit(false);
        if TagHex <> SequenceTagTok then
            exit(false);
        if not ReadDerElement(CertDataHex, CertContentPos, CertContentPos + CertContentLen, TagHex, TbsContentPos, TbsContentLen) then
            exit(false);
        if TagHex <> SequenceTagTok then
            exit(false);
        // The extensions are the [3] EXPLICIT field of TBSCertificate.
        Pos := TbsContentPos;
        TbsEnd := TbsContentPos + TbsContentLen;
        while Pos < TbsEnd do begin
            if not ReadDerElement(CertDataHex, Pos, TbsEnd, TagHex, ContentPos, ContentLen) then
                exit(false);
            if TagHex = ExtensionsTagTok then
                exit(HasSealExtension(CertDataHex, ContentPos, ContentPos + ContentLen));
            Pos := ContentPos + ContentLen;
        end;
        exit(false);
    end;

    local procedure HasSealExtension(CertDataHex: Text; StartPos: Integer; EndPos: Integer): Boolean
    var
        TagHex, ExtensionOidHex : Text;
        ListPos, ListLen, ListEnd, Pos, ExtensionPos, ExtensionLen, ExtensionEnd, ElementPos, ElementLen : Integer;
    begin
        // Extensions ::= SEQUENCE OF Extension
        if not ReadDerElement(CertDataHex, StartPos, EndPos, TagHex, ListPos, ListLen) then
            exit(false);
        if TagHex <> SequenceTagTok then
            exit(false);
        Pos := ListPos;
        ListEnd := ListPos + ListLen;
        while Pos < ListEnd do begin
            // Extension ::= SEQUENCE { extnID OBJECT IDENTIFIER, critical BOOLEAN DEFAULT FALSE, extnValue OCTET STRING }
            if not ReadDerElement(CertDataHex, Pos, ListEnd, TagHex, ExtensionPos, ExtensionLen) then
                exit(false);
            if TagHex <> SequenceTagTok then
                exit(false);
            ExtensionEnd := ExtensionPos + ExtensionLen;
            if not ReadDerElement(CertDataHex, ExtensionPos, ExtensionEnd, TagHex, ElementPos, ElementLen) then
                exit(false);
            if TagHex <> ObjectIdentifierTagTok then
                exit(false);
            ExtensionOidHex := GetDerHex(CertDataHex, ExtensionPos, ElementPos + ElementLen);
            if not ReadDerElement(CertDataHex, ElementPos + ElementLen, ExtensionEnd, TagHex, ElementPos, ElementLen) then
                exit(false);
            if TagHex = BooleanTagTok then
                if not ReadDerElement(CertDataHex, ElementPos + ElementLen, ExtensionEnd, TagHex, ElementPos, ElementLen) then
                    exit(false);
            if TagHex <> OctetStringTagTok then
                exit(false);
            if ExtensionOidHex = QcStatementsExtensionOidTok then
                if HasQcTypeESeal(CertDataHex, ElementPos, ElementPos + ElementLen) then
                    exit(true);
            if ExtensionOidHex = CertificatePoliciesExtensionOidTok then
                if HasLegalPersonPolicy(CertDataHex, ElementPos, ElementPos + ElementLen) then
                    exit(true);
            Pos := ExtensionEnd;
        end;
        exit(false);
    end;

    local procedure HasQcTypeESeal(CertDataHex: Text; StartPos: Integer; EndPos: Integer): Boolean
    var
        TagHex: Text;
        ListPos, ListLen, ListEnd, Pos, StatementPos, StatementLen, StatementEnd, IdPos, IdLen : Integer;
    begin
        // QCStatements ::= SEQUENCE OF QCStatement; QCStatement ::= SEQUENCE { statementId OBJECT IDENTIFIER, statementInfo ANY OPTIONAL }
        if not ReadDerElement(CertDataHex, StartPos, EndPos, TagHex, ListPos, ListLen) then
            exit(false);
        if TagHex <> SequenceTagTok then
            exit(false);
        Pos := ListPos;
        ListEnd := ListPos + ListLen;
        while Pos < ListEnd do begin
            if not ReadDerElement(CertDataHex, Pos, ListEnd, TagHex, StatementPos, StatementLen) then
                exit(false);
            if TagHex <> SequenceTagTok then
                exit(false);
            StatementEnd := StatementPos + StatementLen;
            if not ReadDerElement(CertDataHex, StatementPos, StatementEnd, TagHex, IdPos, IdLen) then
                exit(false);
            if TagHex <> ObjectIdentifierTagTok then
                exit(false);
            // QcType statementInfo ::= SEQUENCE OF OBJECT IDENTIFIER
            if GetDerHex(CertDataHex, StatementPos, IdPos + IdLen) = QcTypeStatementOidTok then
                if SequenceContainsOid(CertDataHex, IdPos + IdLen, StatementEnd, QcTypeESealOidTok) then
                    exit(true);
            Pos := StatementEnd;
        end;
        exit(false);
    end;

    local procedure HasLegalPersonPolicy(CertDataHex: Text; StartPos: Integer; EndPos: Integer): Boolean
    var
        TagHex, PolicyOidHex : Text;
        ListPos, ListLen, ListEnd, Pos, PolicyPos, PolicyLen, OidPos, OidLen : Integer;
    begin
        // certificatePolicies ::= SEQUENCE OF PolicyInformation; PolicyInformation ::= SEQUENCE { policyIdentifier OBJECT IDENTIFIER, policyQualifiers OPTIONAL }
        if not ReadDerElement(CertDataHex, StartPos, EndPos, TagHex, ListPos, ListLen) then
            exit(false);
        if TagHex <> SequenceTagTok then
            exit(false);
        Pos := ListPos;
        ListEnd := ListPos + ListLen;
        while Pos < ListEnd do begin
            if not ReadDerElement(CertDataHex, Pos, ListEnd, TagHex, PolicyPos, PolicyLen) then
                exit(false);
            if TagHex <> SequenceTagTok then
                exit(false);
            if not ReadDerElement(CertDataHex, PolicyPos, PolicyPos + PolicyLen, TagHex, OidPos, OidLen) then
                exit(false);
            if TagHex <> ObjectIdentifierTagTok then
                exit(false);
            PolicyOidHex := GetDerHex(CertDataHex, PolicyPos, OidPos + OidLen);
            if (PolicyOidHex = PolicyQcpLegalOidTok) or (PolicyOidHex = PolicyQcpLegalQscdOidTok) then
                exit(true);
            Pos := PolicyPos + PolicyLen;
        end;
        exit(false);
    end;

    local procedure SequenceContainsOid(CertDataHex: Text; StartPos: Integer; EndPos: Integer; OidHex: Text): Boolean
    var
        TagHex: Text;
        SequencePos, SequenceLen, SequenceEnd, Pos, ContentPos, ContentLen : Integer;
    begin
        if not ReadDerElement(CertDataHex, StartPos, EndPos, TagHex, SequencePos, SequenceLen) then
            exit(false);
        if TagHex <> SequenceTagTok then
            exit(false);
        Pos := SequencePos;
        SequenceEnd := SequencePos + SequenceLen;
        while Pos < SequenceEnd do begin
            if not ReadDerElement(CertDataHex, Pos, SequenceEnd, TagHex, ContentPos, ContentLen) then
                exit(false);
            if TagHex = ObjectIdentifierTagTok then
                if GetDerHex(CertDataHex, Pos, ContentPos + ContentLen) = OidHex then
                    exit(true);
            Pos := ContentPos + ContentLen;
        end;
        exit(false);
    end;

    /// <summary>
    /// Reads the DER element header at byte position Pos. Fails when the element does not fit before byte position EndPos.
    /// Positions are zero-based byte offsets into the hex text.
    /// </summary>
    local procedure ReadDerElement(CertDataHex: Text; Pos: Integer; EndPos: Integer; var TagHex: Text; var ContentPos: Integer; var ContentLen: Integer): Boolean
    var
        LengthByte, LengthByteCount, i : Integer;
    begin
        if (Pos < 0) or (Pos + 2 > EndPos) or (EndPos > StrLen(CertDataHex) div 2) then
            exit(false);
        // Multi-byte tags are not used in X.509 certificates.
        if GetDerByte(CertDataHex, Pos) mod 32 = 31 then
            exit(false);
        TagHex := GetDerHex(CertDataHex, Pos, Pos + 1);
        LengthByte := GetDerByte(CertDataHex, Pos + 1);
        ContentPos := Pos + 2;
        if LengthByte < 128 then
            ContentLen := LengthByte
        else begin
            LengthByteCount := LengthByte - 128;
            if (LengthByteCount < 1) or (LengthByteCount > 3) or (ContentPos + LengthByteCount > EndPos) then
                exit(false);
            ContentLen := 0;
            for i := 0 to LengthByteCount - 1 do
                ContentLen := ContentLen * 256 + GetDerByte(CertDataHex, ContentPos + i);
            ContentPos += LengthByteCount;
        end;
        exit(ContentPos + ContentLen <= EndPos);
    end;

    local procedure GetDerByte(CertDataHex: Text; Pos: Integer): Integer
    begin
        exit((StrPos(HexDigitsTok, CopyStr(CertDataHex, 2 * Pos + 1, 1)) - 1) * 16 + StrPos(HexDigitsTok, CopyStr(CertDataHex, 2 * Pos + 2, 1)) - 1);
    end;

    local procedure GetDerHex(CertDataHex: Text; StartPos: Integer; EndPos: Integer): Text
    begin
        exit(CopyStr(CertDataHex, 2 * StartPos + 1, 2 * (EndPos - StartPos)));
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryDetectSealCertificate(IsolatedCertificate: Record "Isolated Certificate"; var IsSeal: Boolean)
    begin
        IsSeal := DetectSealCertificate(GetCertAsBase64String(IsolatedCertificate), GetPasswordAsSecret(IsolatedCertificate));
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryDetectSealCertificateFromData(CertBase64: Text; CertPassword: SecretText; var IsSeal: Boolean)
    begin
        IsSeal := DetectSealCertificate(CertBase64, CertPassword);
    end;

    [NonDebuggable]
    local procedure DetectSealCertificate(CertBase64: Text; CertPassword: SecretText): Boolean
    var
        X509Certificate2: Codeunit X509Certificate2;
    begin
        exit(IsSealCertificateData(X509Certificate2.GetRawCertDataAsBase64String(CertBase64, CertPassword)));
    end;

    local procedure ConvertBase64ToHex(Base64Text: Text): Text
    var
        CertDataBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        HexBuilder: TextBuilder;
        OutStr: OutStream;
        InStr: InStream;
        ByteValue: Byte;
    begin
        if Base64Text = '' then
            exit('');
        CertDataBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(Base64Text, OutStr);
        CertDataBlob.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.Read(ByteValue);
            HexBuilder.Append(CopyStr(HexDigitsTok, ByteValue div 16 + 1, 1));
            HexBuilder.Append(CopyStr(HexDigitsTok, ByteValue mod 16 + 1, 1));
        end;
        exit(HexBuilder.ToText());
    end;

    internal procedure GetIsolatedCertificate(CertCode: Code[20]; var CertText: SecretText; var CertPassword: SecretText): Boolean
    var
        IsSealCertificate: Boolean;
    begin
        exit(GetIsolatedCertificate(CertCode, CertText, CertPassword, IsSealCertificate));
    end;

    /// <summary>
    /// Loads the certificate and its password, and detects from the same data whether it is an electronic seal certificate.
    /// IsSealCertificate is false when the certificate cannot be classified.
    /// </summary>
    [NonDebuggable]
    internal procedure GetIsolatedCertificate(CertCode: Code[20]; var CertText: SecretText; var CertPassword: SecretText; var IsSealCertificate: Boolean): Boolean
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertBase64: Text;
    begin
        IsSealCertificate := false;
        if not IsolatedCertificate.Get(CertCode) then
            exit(false);
        CertPassword := GetPasswordAsSecret(IsolatedCertificate);
        CertBase64 := GetCertAsBase64String(IsolatedCertificate);
        CertText := SecretStrSubstNo(CertBase64);
        if not TryDetectSealCertificateFromData(CertBase64, CertPassword, IsSealCertificate) then
            IsSealCertificate := false;
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