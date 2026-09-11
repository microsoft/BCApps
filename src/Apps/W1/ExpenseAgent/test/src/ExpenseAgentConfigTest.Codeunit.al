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
    TestPermissions = Restrictive;
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
    procedure ActivatingWithGlobalPermissionDoesNotAddCompanyPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Activating with a global Expense Agent permission does not add a company permission
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has a global Expense Agent permission
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();
        MakeCurrentExpenseAgentPermissionGlobal(AadApplication);

        // [WHEN] Activating the Expense Agent for the current company
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [THEN] "EA" remains enabled with only the global Expense Agent permission
        VerifyAadApplicationState(AadApplication.State::Enabled);
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, '');
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, GetCurrentCompanyName());
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
            SelectLatestVersion();
            exit;
        end;

        UserPermissionsLibrary.AssignPermissionSetToUser(AadApplication."User ID", PermissionSetId, CompanyNameValue);
    end;

    local procedure AssignPermission(AadApplication: Record "AAD Application"; AggregatePermissionSet: Record "Aggregate Permission Set"; CompanyNameValue: Text[30])
    var
        AccessControl: Record "Access Control";
    begin
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
    var
        ExpenseAgentAppId: Guid;
    begin
        Evaluate(ExpenseAgentAppId, ExpenseAgentAppIdTok);
        AggregatePermissionSet.SetRange("App ID", ExpenseAgentAppId);
        AggregatePermissionSet.SetRange("Role ID", ExpenseAgentPermissionSetTok);
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
