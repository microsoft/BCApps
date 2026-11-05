// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148332 "EA Company Scope Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EACompanyScope: Codeunit "EA Company Scope";

    [Test]
    procedure PublishedGuidVector()
    begin
        Assert.AreEqual('2433efa5-0404-5e0a-ab5e-77a8083344e9',
            Format(EACompanyScope.CalculateScopeId('72f988bf-86f1-41af-91ab-2d7cd011db47', 'production', '11111111-2222-3333-4444-555555555555'), 0, 4),
            'UUIDv5 must hash namespace bytes in network order followed by the exact canonical UTF-8 name.');
    end;

    [Test]
    procedure PublishedUnicodeVector()
    var
        EnvironmentName: Text;
        CompanyId: Text;
    begin
        EnvironmentName := 'Istanbul';
        EnvironmentName[1] := 304;
        CompanyId := 'LEGACY-SIRKET';
        CompanyId[8] := 350;
        CompanyId[9] := 304;

        Assert.AreEqual('9:' + EnvironmentName, EACompanyScope.LengthPrefixUtf8(EnvironmentName), 'Length must count UTF-8 bytes without a BOM.');
        Assert.AreEqual('06c05990-a88c-5374-baee-dac1d706964d',
            Format(EACompanyScope.CalculateScopeId('TENANT', EnvironmentName, CompanyId), 0, 4),
            'Only ASCII letters may be lowercased; non-ASCII letters must be preserved.');
    end;

    [Test]
    procedure AsciiWhitespaceAndCase()
    var
        Whitespace: Text;
    begin
        Whitespace[1] := 32;
        Whitespace[2] := 9;
        Whitespace[3] := 13;
        Whitespace[4] := 10;

        Assert.AreEqual(
            EACompanyScope.CalculateScopeId('tenant', 'production', 'legacy-company'),
            EACompanyScope.CalculateScopeId(Whitespace + 'TENANT' + Whitespace, Whitespace + 'PRODUCTION' + Whitespace, Whitespace + 'LEGACY-COMPANY' + Whitespace),
            'ASCII case and surrounding ASCII whitespace must not change the scope.');
        Assert.AreEqual('a b', EACompanyScope.NormalizeAsciiIdentity(' A B '), 'Interior whitespace must be preserved.');
    end;

    [Test]
    procedure NonbreakingSpacesArePreserved()
    var
        Value: Text;
    begin
        Value := ' TENANT ';
        Value[1] := 160;
        Value[8] := 160;
        Assert.AreNotEqual(EACompanyScope.CalculateScopeId('tenant', 'production', 'company'),
            EACompanyScope.CalculateScopeId(Value, 'production', 'company'), 'Nonbreaking spaces are identity characters, not trim characters.');
    end;

    [Test]
    procedure EquivalentCompanyGuids()
    var
        Expected: Guid;
    begin
        Expected := EACompanyScope.CalculateScopeId('tenant', 'production', 'abcdefab-1234-5678-90ab-abcdefabcdef');
        Assert.AreEqual(Expected, EACompanyScope.CalculateScopeId('tenant', 'production', ' {ABCDEFAB-1234-5678-90AB-ABCDEFABCDEF} '), 'Braced GUIDs must be canonicalized.');
        Assert.AreEqual(Expected, EACompanyScope.CalculateScopeId('tenant', 'production', 'ABCDEFAB1234567890ABABCDEFABCDEF'), 'Hyphenless GUIDs must be canonicalized.');
        Assert.AreEqual(Expected, EACompanyScope.CalculateScopeId('tenant', 'production', 'URN:UUID:ABCDEFAB-1234-5678-90AB-ABCDEFABCDEF'), 'URN GUIDs must be canonicalized.');
        Assert.AreEqual(Expected, EACompanyScope.CalculateScopeId('tenant', 'production', 'uuid:abcdefab1234567890ababcdefabcdef'), 'UUID-prefixed GUIDs must be canonicalized.');
    end;

    [Test]
    procedure TenantAndEnvironmentAreNotParsedAsGuids()
    begin
        Assert.AreNotEqual(
            EACompanyScope.CalculateScopeId('{abcdefab-1234-5678-90ab-abcdefabcdef}', 'production', 'company'),
            EACompanyScope.CalculateScopeId('abcdefab-1234-5678-90ab-abcdefabcdef', 'production', 'company'),
            'Tenant identity is normalized text, not a parsed GUID.');
        Assert.AreNotEqual(
            EACompanyScope.CalculateScopeId('tenant', '{abcdefab-1234-5678-90ab-abcdefabcdef}', 'company'),
            EACompanyScope.CalculateScopeId('tenant', 'abcdefab-1234-5678-90ab-abcdefabcdef', 'company'),
            'Environment identity is normalized text, not a parsed GUID.');
    end;

    [Test]
    procedure RejectBlankIdentityComponents()
    var
        Whitespace: Text;
    begin
        Whitespace[1] := 32;
        Whitespace[2] := 9;
        Whitespace[3] := 13;
        Whitespace[4] := 10;
        asserterror EACompanyScope.CalculateScopeId('', 'production', 'company');
        Assert.ExpectedError('Expense Agent company identity is missing.');
        asserterror EACompanyScope.CalculateScopeId('tenant', Whitespace, 'company');
        Assert.ExpectedError('Expense Agent company identity is missing.');
        asserterror EACompanyScope.CalculateScopeId('tenant', 'production', Whitespace);
        Assert.ExpectedError('Expense Agent company identity is missing.');
    end;

    [Test]
    procedure DelimitersCannotAliasIdentities()
    begin
        Assert.AreNotEqual(EACompanyScope.CalculateScopeId('tenant', 'a|b', 'c'),
            EACompanyScope.CalculateScopeId('tenant', 'a', 'b|c'), 'Length prefixes must distinguish embedded pipe delimiters.');
    end;

    [Test]
    procedure CompanyAndEnvironmentCopiesGetNewScopes()
    begin
        Assert.AreNotEqual(EACompanyScope.CalculateScopeId('tenant', 'production', '11111111-2222-3333-4444-555555555555'),
            EACompanyScope.CalculateScopeId('tenant', 'production', 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'), 'A copied company must use its new GUID.');
        Assert.AreNotEqual(EACompanyScope.CalculateScopeId('tenant', 'production', '11111111-2222-3333-4444-555555555555'),
            EACompanyScope.CalculateScopeId('tenant', 'sandbox', '11111111-2222-3333-4444-555555555555'), 'An environment copy must use its actual environment name.');
    end;

    [Test]
    procedure ScopeHeaderIsReplacedAndRequestLocal()
    var
        Request: HttpRequestMessage;
        OtherRequest: HttpRequestMessage;
        Headers: HttpHeaders;
        OtherHeaders: HttpHeaders;
        Values: List of [Text];
        ScopeId: Guid;
    begin
        ScopeId := EACompanyScope.CalculateScopeId('tenant', 'production', 'company');
        Request.GetHeaders(Headers);
        Headers.Add('X-ERP-Scope', 'old-scope');
        Headers.Add('Authorization', 'Bearer existing-token');
        Headers.Add('On-Behalf-Of', 'employee@contoso.com');
        EACompanyScope.SetCompanyScopeHeader(Request, ScopeId);
        EACompanyScope.SetCompanyScopeHeader(Request, ScopeId);

        Headers.GetValues('X-ERP-Scope', Values);
        Assert.AreEqual(1, Values.Count(), 'There must be exactly one scope header, including after a retry.');
        Assert.AreEqual(Format(ScopeId, 0, 4), Values.Get(1), 'The scope must be a canonical UUID.');
        Headers.GetValues('Authorization', Values);
        Assert.AreEqual('Bearer existing-token', Values.Get(1), 'Authentication must be unchanged.');
        Headers.GetValues('On-Behalf-Of', Values);
        Assert.AreEqual('employee@contoso.com', Values.Get(1), 'Delegation must be unchanged.');
        OtherRequest.GetHeaders(OtherHeaders);
        Assert.IsFalse(OtherHeaders.Contains('X-ERP-Scope'), 'No scope may leak to another request.');
    end;

    [Test]
    procedure MissingOriginNeverUsesSessionCompany()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
        EmptyGuid: Guid;
    begin
        asserterror EACompanyScope.AddCompanyScopeHeader(Request, '');
        Assert.ExpectedError('Expense Agent company identity is missing.');
        asserterror EACompanyScope.SetCompanyScopeHeader(Request, EmptyGuid);
        Assert.ExpectedError('Expense Agent company identity is missing.');
        Request.GetHeaders(Headers);
        Assert.IsFalse(Headers.Contains('X-ERP-Scope'), 'Missing identity must fail before building a request header.');
    end;
}
