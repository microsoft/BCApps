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
        tabledata "Access Control" = rimd;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        UserPermissionsLibrary: Codeunit "User Permissions Library";
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
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());
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
        AssignPermission(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());

        // [WHEN] Activating the Expense Agent for the current company
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [THEN] "EA" is enabled with one current company permission
        VerifyAadApplicationState(AadApplication.State::Enabled);
        VerifyPermissionCount(AadApplication, ExpenseAgentPermissionSetTok, CompanyName(), 1);
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
        AssignPermission(AadApplication, UnrelatedPermissionSetTok, CompanyName());

        // [WHEN] Activating the Expense Agent for the current company
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();

        // [THEN] "EA" remains enabled with both the unrelated and current Expense Agent permissions
        VerifyAadApplicationState(AadApplication.State::Enabled);
        VerifyPermissionExists(AadApplication, UnrelatedPermissionSetTok, CompanyName());
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());
    end;

    [Test]
    procedure DeactivatingWithOtherCompanyPermissionKeepsApplicationEnabled()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        OtherCompanyName: Text[30];
    begin
        // [SCENARIO 640454] Deactivating preserves another company permission and keeps the Entra app enabled
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has Expense Agent permissions for the current company and company "B"
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        OtherCompanyName := GetOtherCompanyName();
        AssignPermission(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());
        AssignPermission(AadApplication, ExpenseAgentPermissionSetTok, OtherCompanyName);

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] "EA" remains enabled with only company "B" Expense Agent permission
        VerifyAadApplicationState(AadApplication.State::Enabled);
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());
        VerifyPermissionExists(AadApplication, ExpenseAgentPermissionSetTok, OtherCompanyName);
    end;

    [Test]
    procedure DeactivatingLastExpensePermissionDisablesApplication()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Deactivating the last Expense Agent company disables the Entra app
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has the Expense Agent permission only for the current company
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        AssignPermission(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] "EA" is disabled with no Expense Agent permission
        VerifyAadApplicationState(AadApplication.State::Disabled);
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());
    end;

    [Test]
    procedure DeactivatingLastExpensePermissionPreservesUnrelatedPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Deactivating the last Expense Agent company preserves unrelated permissions
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has current Expense Agent and unrelated permissions
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        AssignPermission(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());
        AssignPermission(AadApplication, UnrelatedPermissionSetTok, CompanyName());

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] "EA" is disabled, the Expense Agent permission is removed, and the unrelated permission remains
        VerifyAadApplicationState(AadApplication.State::Disabled);
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());
        VerifyPermissionExists(AadApplication, UnrelatedPermissionSetTok, CompanyName());
    end;

    [Test]
    procedure DeactivatingWithoutExpensePermissionDisablesApplication()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Deactivating disables the Entra app when no Expense Agent company permission exists
        Initialize();

        // [GIVEN] Enabled Entra app "EA" has only an unrelated permission
        PrepareAadApplication(AadApplication, AadApplication.State::Enabled);
        AssignPermission(AadApplication, UnrelatedPermissionSetTok, CompanyName());

        // [WHEN] Deactivating the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] "EA" is disabled and the unrelated permission remains
        VerifyAadApplicationState(AadApplication.State::Disabled);
        VerifyPermissionDoesNotExist(AadApplication, ExpenseAgentPermissionSetTok, CompanyName());
        VerifyPermissionExists(AadApplication, UnrelatedPermissionSetTok, CompanyName());
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
    begin
        UserPermissionsLibrary.AssignPermissionSetToUser(AadApplication."User ID", PermissionSetId, CompanyNameValue);
    end;

    local procedure GetOtherCompanyName(): Text[30]
    begin
        exit(CopyStr(Format(CreateGuid()), 1, 30));
    end;

    local procedure VerifyAadApplicationState(ExpectedState: Option)
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        AadApplication.Get(ExpenseAgentEntraApp.GetAadAppId());
        Assert.AreEqual(ExpectedState, AadApplication.State, 'The Entra application state is incorrect.');
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
    begin
        AccessControl.SetRange("User Security ID", AadApplication."User ID");
        AccessControl.SetRange("Role ID", PermissionSetId);
        AccessControl.SetRange("Company Name", CompanyNameValue);
        Assert.AreEqual(ExpectedCount, AccessControl.Count(), 'The number of matching Entra app permissions is incorrect.');
    end;
}
