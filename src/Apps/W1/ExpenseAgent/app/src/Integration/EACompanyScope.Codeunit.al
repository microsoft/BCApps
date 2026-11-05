// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.Azure.Identity;
using System.Environment;
using System.Security.Encryption;
using System.Text;
using System.Utilities;

codeunit 6943 "EA Company Scope"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MissingIdentityErr: Label 'Expense Agent company identity is missing. Verify the Entra tenant, environment, and originating company before trying again.';
        NamespaceHexTok: Label '7d8f2d5b0e565f2d9b396ce7f2f54844', Locked = true;
        HexDigitsTok: Label '0123456789abcdef', Locked = true;

    procedure AddCompanyScopeHeader(var Request: HttpRequestMessage; OriginCompanyName: Text)
    var
        Company: Record Company;
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
        ScopeId: Guid;
    begin
        if OriginCompanyName = '' then
            Error(MissingIdentityErr);
        if not Company.Get(OriginCompanyName) then
            Error(MissingIdentityErr);
        if IsNullGuid(Company.Id) then
            Error(MissingIdentityErr);

        ScopeId := CalculateScopeId(AzureADTenant.GetAadTenantId(), EnvironmentInformation.GetEnvironmentName(), Format(Company.Id, 0, 4));
        SetCompanyScopeHeader(Request, ScopeId);
    end;

    internal procedure SetCompanyScopeHeader(var Request: HttpRequestMessage; ScopeId: Guid)
    var
        Headers: HttpHeaders;
    begin
        if IsNullGuid(ScopeId) then
            Error(MissingIdentityErr);
        Request.GetHeaders(Headers);
        if Headers.Contains('X-ERP-Scope') then
            Headers.Remove('X-ERP-Scope');
        Headers.Add('X-ERP-Scope', Format(ScopeId, 0, 4));
    end;

    procedure CalculateScopeId(TenantId: Text; EnvironmentName: Text; CompanyId: Text): Guid
    var
        HashInput: Codeunit "Temp Blob";
        DigestBlob: Codeunit "Temp Blob";
        CryptographyManagement: Codeunit "Cryptography Management";
        Base64Convert: Codeunit "Base64 Convert";
        HashOutStream: OutStream;
        HashInStream: InStream;
        DigestOutStream: OutStream;
        DigestInStream: InStream;
        Bytes: array[16] of Byte;
        NamespaceByte: Byte;
        Index: Integer;
        CanonicalName: Text;
        Digest: Text;
        ScopeId: Guid;
    begin
        TenantId := NormalizeAsciiIdentity(TenantId);
        EnvironmentName := NormalizeAsciiIdentity(EnvironmentName);
        CompanyId := CanonicalizeCompanyIdentity(CompanyId);
        CanonicalName := 'business-central|' + LengthPrefixUtf8(TenantId) + '|' +
            LengthPrefixUtf8(EnvironmentName) + '|' + LengthPrefixUtf8(CompanyId);

        HashInput.CreateOutStream(HashOutStream);
        for Index := 1 to 16 do begin
            NamespaceByte := (StrPos(HexDigitsTok, CopyStr(NamespaceHexTok, Index * 2 - 1, 1)) - 1) * 16 +
                StrPos(HexDigitsTok, CopyStr(NamespaceHexTok, Index * 2, 1)) - 1;
            HashOutStream.Write(NamespaceByte);
        end;
        WriteUtf8WithoutBom(CanonicalName, HashOutStream);
        HashInput.CreateInStream(HashInStream);
        Digest := CryptographyManagement.GenerateHash(HashInStream, 1); // Unkeyed SHA-1, returned as Base64.
        DigestBlob.CreateOutStream(DigestOutStream);
        Base64Convert.FromBase64(Digest, DigestOutStream);
        DigestBlob.CreateInStream(DigestInStream);
        for Index := 1 to 16 do
            DigestInStream.Read(Bytes[Index]);
        Bytes[7] := (Bytes[7] mod 16) + 80;
        Bytes[9] := (Bytes[9] mod 64) + 128;
        Evaluate(ScopeId, FormatCanonicalUuid(Bytes));
        exit(ScopeId);
    end;

    internal procedure NormalizeAsciiIdentity(Value: Text): Text
    var
        Whitespace: Text;
        Index: Integer;
    begin
        Whitespace[1] := 32;
        Whitespace[2] := 9;
        Whitespace[3] := 13;
        Whitespace[4] := 10;
        Value := DelChr(Value, '<>', Whitespace);
        if Value = '' then
            Error(MissingIdentityErr);
        for Index := 1 to StrLen(Value) do
            if (Value[Index] >= 65) and (Value[Index] <= 90) then
                Value[Index] := Value[Index] + 32;
        exit(Value);
    end;

    internal procedure CanonicalizeCompanyIdentity(Value: Text): Text
    var
        CompanyGuid: Guid;
        GuidText: Text;
        Index: Integer;
    begin
        Value := NormalizeAsciiIdentity(Value);
        GuidText := Value;
        if GuidText.StartsWith('urn:') then
            GuidText := CopyStr(GuidText, 5);
        if GuidText.StartsWith('uuid:') then
            GuidText := CopyStr(GuidText, 6);
        if GuidText.StartsWith('{') and GuidText.EndsWith('}') then
            GuidText := CopyStr(GuidText, 2, StrLen(GuidText) - 2);
        GuidText := DelChr(GuidText, '=', '-');
        if StrLen(GuidText) = 32 then begin
            for Index := 1 to 32 do
                if StrPos(HexDigitsTok, CopyStr(GuidText, Index, 1)) = 0 then
                    exit(Value);
            GuidText := CopyStr(GuidText, 1, 8) + '-' + CopyStr(GuidText, 9, 4) + '-' +
                CopyStr(GuidText, 13, 4) + '-' + CopyStr(GuidText, 17, 4) + '-' + CopyStr(GuidText, 21, 12);
            Evaluate(CompanyGuid, GuidText);
            exit(Format(CompanyGuid, 0, 4));
        end;
        exit(Value);
    end;

    internal procedure LengthPrefixUtf8(Value: Text): Text
    var
        Utf8Blob: Codeunit "Temp Blob";
        Utf8OutStream: OutStream;
    begin
        Utf8Blob.CreateOutStream(Utf8OutStream);
        WriteUtf8WithoutBom(Value, Utf8OutStream);
        exit(Format(Utf8Blob.Length(), 0, 9) + ':' + Value);
    end;

    local procedure WriteUtf8WithoutBom(Value: Text; var Output: OutStream)
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        // The text converter encodes UTF-8 bytes without a stream preamble or terminator.
        Base64Convert.FromBase64(Base64Convert.ToBase64(Value, TextEncoding::UTF8), Output);
    end;

    local procedure FormatCanonicalUuid(Bytes: array[16] of Byte): Text
    var
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to 16 do begin
            if Index in [5, 7, 9, 11] then
                Result += '-';
            Result += CopyStr(HexDigitsTok, (Bytes[Index] div 16) + 1, 1) +
                CopyStr(HexDigitsTok, (Bytes[Index] mod 16) + 1, 1);
        end;
        exit(Result);
    end;
}
