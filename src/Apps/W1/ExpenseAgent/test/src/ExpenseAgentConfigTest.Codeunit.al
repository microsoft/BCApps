// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.TestLibraries.Security.AccessControl;

codeunit 148361 "Expense Agent Config. Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    Permissions =
        tabledata "AAD Application" = rm,
        tabledata "Access Control" = rid;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        UserPermissionsLibrary: Codeunit "User Permissions Library";
        ExpenseAgentAppIdTok: Label '66efe10c-8033-403b-a86d-77c0887178ba', Locked = true;
        ExpenseAgentPermissionSetTok: Label 'Expense Agent', Locked = true;
        UnrelatedPermissionSetTok: Label 'D365 BASIC', Locked = true;
        JsonPropertyMissingErr: Label 'The %1 property is missing.', Comment = '%1 = JSON property name';

    [Test]
    procedure ActivatingWithOtherCompanyPermissionAddsCurrentCompanyPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        OtherCompanyName: Text[30];
    begin
        // [SCENARIO 640454] Activating with another company permission adds the current company permission
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has the Expense Agent permission only for company "B"
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        OtherCompanyName := GetOtherCompanyName();
        AssignPermission(AadApplication, ExpenseAgentPermissionSetTok, OtherCompanyName);

        // [WHEN] Activating the Expense Agent for the current company
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [THEN] "EA" remains enabled and has Expense Agent permissions for both companies
        VerifyAadApplicationState(AadApplication.State::Enabled);
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, OtherCompanyName);
    end;

    [Test]
    procedure ActivatingDisabledAppWithCurrentPermissionDoesNotDuplicatePermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Activating a disabled Entra app preserves its existing current company permission
        Initialize();

        // [GIVEN] Disabled Entra app "EA" already has the Expense Agent permission for the current company
        PrepareAadApplication(AadApplication, AadApplication.State::Disabled);
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();
        SetAadApplicationState(AadApplication.State::Disabled);

        // [WHEN] Activating the Expense Agent for the current company
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [THEN] "EA" is enabled with one current company permission
        VerifyAadApplicationState(AadApplication.State::Enabled);
        VerifyPermissionCount(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName(), 1);
    end;

    [Test]
    procedure ActivatingWithUnrelatedPermissionPreservesPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Activating preserves an unrelated permission assigned to the Entra app user
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has an unrelated permission but no Expense Agent permission
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        AssignPermission(AadApplication, UnrelatedPermissionSetTok, GetCurrentCompanyName());

        // [WHEN] Activating the Expense Agent for the current company
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [THEN] "EA" remains enabled with both the unrelated and current Expense Agent permissions
        VerifyAadApplicationState(AadApplication.State::Enabled);
        VerifyPermissionExists(AadApplication, UnrelatedPermissionSetTok, GetCurrentCompanyName());
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
    end;

    [Test]
    procedure ActivatingWithGlobalPermissionAddsCurrentCompanyPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Activating with a global Expense Agent permission adds the current company permission
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has a global Expense Agent permission
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();
        MakeCurrentExpenseAgentPermissionGlobal(AadApplication);

        // [WHEN] Activating the Expense Agent for the current company
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [THEN] The global grant remains and an explicit current-company grant is added
        VerifyAadApplicationState(AadApplication.State::Enabled);
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, '');
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
    end;

    [Test]
    procedure DeactivatingPreservesOtherCompanyPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        OtherCompanyName: Text[30];
    begin
        // [SCENARIO 640454] Deactivating preserves another company permission
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has Expense Agent permissions for the current company and company "B"
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        OtherCompanyName := GetOtherCompanyName();
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();
        AssignPermission(AadApplication, ExpenseAgentPermissionSetTok, OtherCompanyName);
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, OtherCompanyName);

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] The current permission is removed and company "B" is preserved
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, OtherCompanyName);
    end;

    [Test]
    procedure DeactivatingRemovesCurrentCompanyPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Deactivating removes the current-company Expense Agent permission
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has the Expense Agent permission only for the current company
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] The current-company Expense Agent permission is removed and "EA" is disabled
        VerifyAadApplicationState(AadApplication.State::Disabled);
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
    end;

    [Test]
    procedure DeactivatingPreservesUnrelatedPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Deactivating preserves unrelated permissions
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has current Expense Agent and unrelated permissions
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        AssignPermission(AadApplication, UnrelatedPermissionSetTok, GetCurrentCompanyName());
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] The Expense Agent permission is removed and the unrelated permission remains
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
        VerifyPermissionExists(AadApplication, UnrelatedPermissionSetTok, GetCurrentCompanyName());
    end;

    [Test]
    procedure DeactivatingWithoutExpensePermissionPreservesUnrelatedPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Deactivating without a current grant preserves unrelated permissions
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has only an unrelated permission
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        AssignPermission(AadApplication, UnrelatedPermissionSetTok, GetCurrentCompanyName());

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] The unrelated permission remains
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
        VerifyPermissionExists(AadApplication, UnrelatedPermissionSetTok, GetCurrentCompanyName());
    end;

    [Test]
    procedure DeactivatingWithGlobalPermissionDisablesApplication()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] A global grant does not keep the Entra app enabled after the last company is deactivated
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has global and current-company Expense Agent permissions
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();
        MakeCurrentExpenseAgentPermissionGlobal(AadApplication);
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] "EA" is disabled, the current grant is removed, and the global grant remains
        VerifyAadApplicationState(AadApplication.State::Disabled);
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, '');
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
    end;

    [Test]
    procedure ServiceIdentityIsExpenseAgentApplicationUser()
    var
        AadApplication: Record "AAD Application";
        User: Record User;
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        IdentityManagement: Codeunit "Identity Management";
        ServiceIdentity: JsonObject;
    begin
        // [SCENARIO] The E2E service identity is the Expense Agent Entra application user with only the current company permission
        Initialize();

        // [GIVEN] Disabled Entra app "EA" without permissions
        PrepareAadApplication(AadApplication, AadApplication.State::Disabled);

        // [WHEN] Enabling "EA" as activating the agent does, and getting the service identity for E2E tests
        ExpenseTestHandlerAPI.EnableEntraApplication();
        ExpenseTestHandlerAPI.GetServiceIdentity(ServiceIdentity);

        // [THEN] "EA" is enabled with one current company Expense Agent permission
        VerifyAadApplicationState(AadApplication.State::Enabled);
        VerifyPermissionCount(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName(), 1);

        // [THEN] The identity is the application user of "EA" with its current web service access key, which does not expire
        AadApplication.Get(AadApplication."Client Id");
        User.Get(AadApplication."User ID");
        Assert.AreEqual(User."User Name", GetJsonText(ServiceIdentity, 'userName'), 'The service user name is incorrect.');
        Assert.AreNotEqual('', GetJsonText(ServiceIdentity, 'webServicesKey'), 'The web service access key must be returned.');
        Assert.AreEqual(
            IdentityManagement.GetWebServicesKey(AadApplication."User ID"),
            GetJsonText(ServiceIdentity, 'webServicesKey'),
            'The returned key must be the key of the application user.');
        Assert.AreEqual(0DT, IdentityManagement.GetWebServiceExpiryDate(AadApplication."User ID"), 'The web service access key must not expire.');
    end;

    [Test]
    procedure ServiceIdentityReusesKeyWithoutExpiry()
    var
        AadApplication: Record "AAD Application";
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        FirstServiceIdentity: JsonObject;
        SecondServiceIdentity: JsonObject;
    begin
        // [SCENARIO] Getting the E2E service identity again keeps the key that running services already use
        Initialize();

        // [GIVEN] Enabled Entra app "EA" whose service identity was already requested
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        ExpenseTestHandlerAPI.EnableEntraApplication();
        ExpenseTestHandlerAPI.GetServiceIdentity(FirstServiceIdentity);

        // [WHEN] Enabling "EA" and getting the service identity again, as a repeated Configure does
        ExpenseTestHandlerAPI.EnableEntraApplication();
        ExpenseTestHandlerAPI.GetServiceIdentity(SecondServiceIdentity);

        // [THEN] The same key is returned and "EA" keeps one current company Expense Agent permission
        Assert.AreEqual(
            GetJsonText(FirstServiceIdentity, 'webServicesKey'),
            GetJsonText(SecondServiceIdentity, 'webServicesKey'),
            'A web service access key without expiry must be reused.');
        VerifyPermissionCount(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName(), 1);
    end;

    [Test]
    procedure ServiceIdentityRepairsEnabledApplicationWithoutUser()
    var
        AadApplication: Record "AAD Application";
        User: Record User;
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        ServiceIdentity: JsonObject;
    begin
        // [SCENARIO] Enabling an Entra app whose user ID does not exist, as in a prepared container database, repairs its user
        Initialize();

        // [GIVEN] Enabled Entra app "EA" whose user ID does not refer to a user
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        AadApplication."User ID" := CreateGuid();
        AadApplication.Modify();

        // [WHEN] Enabling "EA" and getting the service identity for E2E tests
        ExpenseTestHandlerAPI.EnableEntraApplication();
        ExpenseTestHandlerAPI.GetServiceIdentity(ServiceIdentity);

        // [THEN] "EA" is enabled for an existing application user, which is the returned identity
        VerifyAadApplicationState(AadApplication.State::Enabled);
        AadApplication.Get(AadApplication."Client Id");
        User.Get(AadApplication."User ID");
        Assert.AreEqual(User."User Name", GetJsonText(ServiceIdentity, 'userName'), 'The service user name is incorrect.');
        VerifyPermissionCount(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName(), 1);
    end;

    [Test]
    procedure CompanyScopeIdMatchesKnownValue()
    var
        EAHttpClient: Codeunit "EA Http Client";
    begin
        // [SCENARIO] The company scope is a version 5 UUID over the length-prefixed identity
        Assert.AreEqual(
            '2433efa5-0404-5e0a-ab5e-77a8083344e9',
            EAHttpClient.CalculateCompanyScopeId('72f988bf-86f1-41af-91ab-2d7cd011db47', 'production', '11111111-2222-3333-4444-555555555555'),
            'The company scope is incorrect.');
    end;

    [Test]
    procedure CompanyScopeIdNormalizesWhitespaceCaseAndCompanyGuidFormat()
    var
        EAHttpClient: Codeunit "EA Http Client";
        ExpectedScopeId: Text;
        Whitespace: Text;
        WhitespaceCharacter: Char;
    begin
        // [SCENARIO] ASCII whitespace, ASCII case and the company GUID format do not change the scope
        ExpectedScopeId := '2433efa5-0404-5e0a-ab5e-77a8083344e9';
        Assert.AreEqual(ExpectedScopeId, EAHttpClient.CalculateCompanyScopeId('  72F988BF-86F1-41AF-91AB-2D7CD011DB47' + Tab(), '  ProDuction ', ' 11111111-2222-3333-4444-555555555555 '), 'Whitespace and case must be ignored.');
        WhitespaceCharacter := 13;
        Whitespace := Format(WhitespaceCharacter);
        WhitespaceCharacter := 10;
        Whitespace += Format(WhitespaceCharacter) + Tab() + ' ';
        Assert.AreEqual(ExpectedScopeId, EAHttpClient.CalculateCompanyScopeId(Whitespace + '72F988BF-86F1-41AF-91AB-2D7CD011DB47' + Whitespace, Whitespace + 'ProDuction' + Whitespace, Whitespace + '11111111-2222-3333-4444-555555555555' + Whitespace), 'Only leading and trailing ASCII whitespace must be ignored.');
        Assert.AreEqual(ExpectedScopeId, EAHttpClient.CalculateCompanyScopeId('72f988bf-86f1-41af-91ab-2d7cd011db47', 'production', '{11111111-2222-3333-4444-555555555555}'), 'Braces must be ignored.');
        Assert.AreEqual(ExpectedScopeId, EAHttpClient.CalculateCompanyScopeId('72f988bf-86f1-41af-91ab-2d7cd011db47', 'production', 'urn:uuid:11111111-2222-3333-4444-555555555555'), 'The URN prefix must be ignored.');
        Assert.AreEqual(ExpectedScopeId, EAHttpClient.CalculateCompanyScopeId('72f988bf-86f1-41af-91ab-2d7cd011db47', 'production', 'urn:uuid:{{11111111--2222-3333-4444-555555555555}}'), 'Repeated braces and hyphens must be ignored.');
        Assert.AreEqual(ExpectedScopeId, EAHttpClient.CalculateCompanyScopeId('72f988bf-86f1-41af-91ab-2d7cd011db47', 'production', '11111111222233334444555555555555'), 'Missing hyphens must be ignored.');
        Assert.AreEqual('cd72c104-3374-51c3-a84d-d76055db8f83', EAHttpClient.CalculateCompanyScopeId('tenant', 'ab' + Tab() + 'c', 'company'), 'Whitespace inside a value must be preserved.');
    end;

    [Test]
    procedure CompanyScopeIdKeepsNonAsciiCharacters()
    var
        EAHttpClient: Codeunit "EA Http Client";
    begin
        // [SCENARIO] Only ASCII letters are lowercased and non-ASCII values are hashed as UTF-8
        Assert.AreEqual(
            '06c05990-a88c-5374-baee-dac1d706964d',
            EAHttpClient.CalculateCompanyScopeId('TENANT', 'İstanbul', 'LEGACY-ŞİRKET'),
            'The company scope of non-ASCII values is incorrect.');
        Assert.AreEqual(
            '4da78c66-53e1-559d-88a8-9a5137589dd3',
            EAHttpClient.CalculateCompanyScopeId('CONTOSO', 'Ünïcode-ENV', 'company-Ä-😀'),
            'The company scope of non-ASCII values is incorrect.');
        Assert.AreEqual(
            'b32bbbb8-5d85-5628-a755-96517fc38039',
            EAHttpClient.CalculateCompanyScopeId('TENANT', '€|漢', 'company-😀'),
            'The company scope must use the UTF-8 byte length without a byte-order mark.');
    end;

    [Test]
    procedure CompanyScopeIdPreservesNonAsciiWhitespace()
    var
        EAHttpClient: Codeunit "EA Http Client";
        NonBreakingSpace: Char;
        EnvironmentName: Text;
    begin
        // [SCENARIO] Non-ASCII whitespace is part of the scope identity
        NonBreakingSpace := 160;
        EnvironmentName := Format(NonBreakingSpace) + 'ENV' + Format(NonBreakingSpace);
        Assert.AreEqual('c02a7c41-5664-5e30-b920-5b066f4269e1', EAHttpClient.CalculateCompanyScopeId('TENANT', EnvironmentName, 'company'), 'Non-ASCII whitespace must not be trimmed.');
    end;

    [Test]
    procedure CompanyScopeIdRejectsInvalidUnicode()
    var
        EAHttpClient: Codeunit "EA Http Client";
        InvalidText: Text[2];
    begin
        // [SCENARIO] Unpaired UTF-16 surrogates must not be silently replaced during UTF-8 conversion
        InvalidText := 'a';
        InvalidText[1] := 55296;
        asserterror EAHttpClient.CalculateCompanyScopeId('tenant', InvalidText, 'company');
        Assert.ExpectedError('invalid characters');
        InvalidText := 'ab';
        InvalidText[1] := 55296;
        asserterror EAHttpClient.CalculateCompanyScopeId('tenant', InvalidText, 'company');
        Assert.ExpectedError('invalid characters');
        InvalidText := 'a';
        InvalidText[1] := 56320;
        asserterror EAHttpClient.CalculateCompanyScopeId('tenant', InvalidText, 'company');
        Assert.ExpectedError('invalid characters');
    end;

    [Test]
    procedure CompanyScopeIdLengthPrefixPreventsDelimiterCollision()
    var
        EAHttpClient: Codeunit "EA Http Client";
    begin
        // [SCENARIO] Values containing the delimiter do not collide
        Assert.AreEqual('ea555b32-5add-5fa6-9b41-f89ec8e71190', EAHttpClient.CalculateCompanyScopeId('contoso', 'a|b', 'c'), 'The company scope is incorrect.');
        Assert.AreEqual('2e93100f-eb78-5916-bfd7-096409a680fc', EAHttpClient.CalculateCompanyScopeId('contoso', 'a', 'b|c'), 'The company scope is incorrect.');
    end;

    [Test]
    procedure CompanyScopeIdFailsForMissingIdentity()
    var
        EAHttpClient: Codeunit "EA Http Client";
    begin
        // [SCENARIO] A blank identity value blocks the scope calculation and names the value
        asserterror EAHttpClient.CalculateCompanyScopeId(' ', 'sandbox', 'company');
        Assert.ExpectedError('tenant_id');
        asserterror EAHttpClient.CalculateCompanyScopeId('contoso', Tab(), 'company');
        Assert.ExpectedError('environment_name');
        asserterror EAHttpClient.CalculateCompanyScopeId('contoso', 'sandbox', '');
        Assert.ExpectedError('company_id');
    end;

    local procedure Tab(): Text[1]
    var
        TabChar: Char;
    begin
        TabChar := 9;
        exit(Format(TabChar));
    end;

    local procedure GetJsonText(JsonObject: JsonObject; PropertyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        Assert.IsTrue(JsonObject.Get(PropertyName, JsonToken), StrSubstNo(JsonPropertyMissingErr, PropertyName));
        exit(JsonToken.AsValue().AsText());
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Agent Config. Test");
    end;

    local procedure PrepareAadApplication(var AadApplication: Record "AAD Application"; State: Option)
    var
        AccessControl: Record "Access Control";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        AadApplication.Get(ExpenseAgentEntraApp.GetAadAppId());
        if AadApplication.State <> State then begin
            AadApplication.Validate(State, State);
            AadApplication.Modify(true);
        end;

        AccessControl.SetRange("User Security ID", AadApplication."User ID");
        AccessControl.DeleteAll(true);
    end;

    local procedure AssignPermission(AadApplication: Record "AAD Application"; PermissionSetId: Code[20]; CompanyNameValue: Text[30])
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        if PermissionSetId = ExpenseAgentPermissionSetTok then begin
            GetExpenseAgentPermissionSet(AggregatePermissionSet);
            AssignPermission(AadApplication, AggregatePermissionSet, CompanyNameValue);
            exit;
        end;

        UserPermissionsLibrary.AssignPermissionSetToUser(AadApplication."User ID", PermissionSetId, CompanyNameValue);
    end;

    local procedure AssignPermission(AadApplication: Record "AAD Application"; AggregatePermissionSet: Record "Aggregate Permission Set"; CompanyNameValue: Text[30])
    var
        AccessControl: Record "Access Control";
    begin
        AadApplication.Get(AadApplication."Client Id");
        AccessControl.Init();
        AccessControl."User Security ID" := AadApplication."User ID";
        AccessControl."Role ID" := AggregatePermissionSet."Role ID";
        AccessControl."Company Name" := CompanyNameValue;
        AccessControl.Scope := AggregatePermissionSet.Scope;
        AccessControl."App ID" := AggregatePermissionSet."App ID";
        AccessControl.Insert(true);
    end;

    local procedure GetOtherCompanyName(): Text[30]
    begin
        exit(CopyStr(Format(CreateGuid()), 1, 30));
    end;

    local procedure GetCurrentCompanyName(): Text[30]
    begin
        exit(CopyStr(CompanyName(), 1, 30));
    end;

    local procedure VerifyAadApplicationState(ExpectedState: Option)
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        AadApplication.Get(ExpenseAgentEntraApp.GetAadAppId());
        Assert.AreEqual(ExpectedState, AadApplication.State, 'The Entra application state is incorrect.');
    end;

    local procedure SetAadApplicationState(State: Option)
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        AadApplication.Get(ExpenseAgentEntraApp.GetAadAppId());
        AadApplication.Validate(State, State);
        AadApplication.Modify(true);
    end;

    local procedure VerifyPermissionExists(AadApplication: Record "AAD Application"; PermissionSetId: Code[20]; CompanyNameValue: Text[30])
    begin
        VerifyPermissionCount(AadApplication, PermissionSetId, CompanyNameValue, 1);
    end;

    local procedure VerifyPermissionDoesNotExist(AadApplication: Record "AAD Application"; PermissionSetId: Code[20]; CompanyNameValue: Text[30])
    begin
        VerifyPermissionCount(AadApplication, PermissionSetId, CompanyNameValue, 0);
    end;

    local procedure VerifyPermissionCount(AadApplication: Record "AAD Application"; PermissionSetId: Code[20]; CompanyNameValue: Text[30]; ExpectedCount: Integer)
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AadApplication.Get(AadApplication."Client Id");
        AccessControl.SetRange("User Security ID", AadApplication."User ID");
        if PermissionSetId = ExpenseAgentPermissionSetTok then begin
            GetExpenseAgentPermissionSet(AggregatePermissionSet);
            AccessControl.SetRange(Scope, AggregatePermissionSet.Scope);
            AccessControl.SetRange("App ID", AggregatePermissionSet."App ID");
        end;
        AccessControl.SetRange("Role ID", PermissionSetId);
        AccessControl.SetRange("Company Name", CompanyNameValue);
        Assert.AreEqual(ExpectedCount, AccessControl.Count(), 'The number of matching Entra app permissions is incorrect.');
    end;

    local procedure GetExpenseAgentPermissionSet(var AggregatePermissionSet: Record "Aggregate Permission Set")
    begin
        GetPermissionSet(AggregatePermissionSet, ExpenseAgentPermissionSetTok);
    end;

    local procedure GetPermissionSet(var AggregatePermissionSet: Record "Aggregate Permission Set"; PermissionSetId: Code[20])
    var
        ExpenseAgentAppId: Guid;
    begin
        Evaluate(ExpenseAgentAppId, ExpenseAgentAppIdTok);
        AggregatePermissionSet.SetRange("App ID", ExpenseAgentAppId);
        AggregatePermissionSet.SetRange("Role ID", PermissionSetId);
        AggregatePermissionSet.FindFirst();
    end;

    local procedure MakeCurrentExpenseAgentPermissionGlobal(AadApplication: Record "AAD Application")
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        GetExpenseAgentPermissionSet(AggregatePermissionSet);
        AccessControl.Get(
            AadApplication."User ID",
            AggregatePermissionSet."Role ID",
            GetCurrentCompanyName(),
            AggregatePermissionSet.Scope,
            AggregatePermissionSet."App ID");
        AccessControl.Rename(
            AadApplication."User ID",
            AggregatePermissionSet."Role ID",
            '',
            AggregatePermissionSet.Scope,
            AggregatePermissionSet."App ID");
    end;
}
