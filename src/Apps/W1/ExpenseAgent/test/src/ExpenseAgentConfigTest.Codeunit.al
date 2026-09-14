// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Security.AccessControl;

codeunit 148361 "Expense Agent Config. Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Restrictive;
    Permissions =
        tabledata "AAD Application" = rm,
        tabledata "Access Control" = rid;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        UserPermissionsLibrary: Codeunit "User Permissions Library";
        AgentAdminPermissionSetTok: Label 'Agent - Admin', Locked = true;
        ExpenseAgentAppIdTok: Label '66efe10c-8033-403b-a86d-77c0887178ba', Locked = true;
        ExpenseAgentPermissionSetTok: Label 'Expense Agent', Locked = true;
        ExpenseManagementAdminPermissionSetTok: Label 'Expense Mgmt. Admin', Locked = true;
        UnrelatedPermissionSetTok: Label 'D365 BASIC', Locked = true;

    [Test]
    procedure ActivatingWithOtherCompanyPermissionAddsCurrentCompanyPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        OtherCompanyName: Text[30];
    begin
        // [FEATURE] [AI test 1.0]
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
        // [FEATURE] [AI test 1.0]
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
        // [FEATURE] [AI test 1.0]
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
        // [FEATURE] [AI test 1.0]
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
        // [FEATURE] [AI test 1.0]
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
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 640454] Deactivating removes the current-company Expense Agent permission
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has the Expense Agent permission only for the current company
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] The current-company Expense Agent permission is removed
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
    end;

    [Test]
    procedure DeactivatingPreservesUnrelatedPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
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
        // [FEATURE] [AI test 1.0]
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
        // [FEATURE] [AI test 1.0]
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

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Agent Config. Test");
        EnsureCurrentUserAgentAdminPermissionSetAssigned();
        EnsureCurrentUserPermissionSetAssigned(ExpenseManagementAdminPermissionSetTok);
        EnsureCurrentUserPermissionSetAssigned(ExpenseAgentPermissionSetTok);
    end;

    local procedure EnsureCurrentUserAgentAdminPermissionSetAssigned()
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        UserPermissions: Codeunit "User Permissions";
    begin
        AggregatePermissionSet.SetRange("Role ID", AgentAdminPermissionSetTok);
        AggregatePermissionSet.FindFirst();
        if UserPermissions.HasUserPermissionSetAssigned(
            UserSecurityId(),
            GetCurrentCompanyName(),
            AggregatePermissionSet."Role ID",
            AggregatePermissionSet.Scope,
            AggregatePermissionSet."App ID")
        then
            exit;

        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId();
        AccessControl."Role ID" := AggregatePermissionSet."Role ID";
        AccessControl.Scope := AggregatePermissionSet.Scope;
        AccessControl."App ID" := AggregatePermissionSet."App ID";
        AccessControl.Insert(true);
    end;

    local procedure EnsureCurrentUserPermissionSetAssigned(PermissionSetId: Code[20])
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        UserPermissions: Codeunit "User Permissions";
    begin
        GetPermissionSet(AggregatePermissionSet, PermissionSetId);
        if UserPermissions.HasUserPermissionSetAssigned(
            UserSecurityId(),
            GetCurrentCompanyName(),
            AggregatePermissionSet."Role ID",
            AggregatePermissionSet.Scope,
            AggregatePermissionSet."App ID")
        then
            exit;

        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId();
        AccessControl."Role ID" := AggregatePermissionSet."Role ID";
        AccessControl."Company Name" := GetCurrentCompanyName();
        AccessControl.Scope := AggregatePermissionSet.Scope;
        AccessControl."App ID" := AggregatePermissionSet."App ID";
        AccessControl.Insert(true);
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
