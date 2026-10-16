// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.User;

using System.Azure.Identity;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Azure.ActiveDirectory;
using System.TestLibraries.Security.User;
using System.TestLibraries.Utilities;

codeunit 132908 "User Details Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestGetUserDetails()
    var
        User1: Record User;
        User2: Record User;
        AccessControl: Record "Access Control";
        UserDetailsTestLibrary: Codeunit "User Details Test Library";
        PlanIDs: Codeunit "Plan Ids";
        AzureADPlan: Codeunit "Azure AD Plan";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        PlanNames: List of [Text];
    begin
        // [GIVEN] Two users with different details exist:
        // User 1 has a global administrator plan, Essential plan and SUPER permission set
        // User 2 has only M365 plan
        User1."User Security ID" := CreateGuid();
        User1."User Name" := CreateGuid();
        User1.Insert();
        User2."User Security ID" := CreateGuid();
        User2."User Name" := CreateGuid();
        User2.Insert();

        AzureADPlanTestLibrary.AssignUserToPlan(User1."User Security ID", PlanIDs.GetGlobalAdminPlanId());
        AzureADPlanTestLibrary.AssignUserToPlan(User1."User Security ID", PlanIDs.GetEssentialPlanId());
        AzureADPlanTestLibrary.AssignUserToPlan(User2."User Security ID", PlanIDs.GetMicrosoft365PlanId());

        AccessControl."User Security ID" := User1."User Security ID";
        AccessControl."Role ID" := 'SUPER';
        AccessControl.Scope := AccessControl.Scope::System;
        AccessControl.Insert();

        // [WHEN] User details are retrieved with UserDetails.Get (inside the test library)
        UserDetailsTestLibrary.GetUserDetails();

        // [THEN] The details are as expected
        Assert.IsTrue(UserDetailsTestLibrary.HasSuperPermissionSet(User1."User Security ID"), 'Expected the user to have SUPER');
        Assert.IsTrue(UserDetailsTestLibrary.HasEssentialPlan(User1."User Security ID"), 'Expected the user to have an Essential plan');
        Assert.IsTrue(UserDetailsTestLibrary.HasEssentialOrPremiumPlan(User1."User Security ID"), 'Expected the user to have an Essential plan');
        Assert.IsFalse(UserDetailsTestLibrary.HasM365Plan((User1."User Security ID")), 'Expected the user to not have an M365 plan');

        AzureADPlan.GetPlanNames(User1."User Security ID", PlanNames);
        Assert.AreEqual(PlanNames.Get(1) + ' ; ' + PlanNames.Get(2), UserDetailsTestLibrary.UserPlans((User1."User Security ID")), 'Unexpected user plans were returned.');

        Assert.IsFalse(UserDetailsTestLibrary.HasSuperPermissionSet(User2."User Security ID"), 'Expected the user to have SUPER');
        Assert.IsFalse(UserDetailsTestLibrary.HasEssentialPlan(User2."User Security ID"), 'Expected the user to have an Essential plan');
        Assert.IsFalse(UserDetailsTestLibrary.HasEssentialOrPremiumPlan(User2."User Security ID"), 'Expected the user to have an Essential plan');
        Assert.IsTrue(UserDetailsTestLibrary.HasM365Plan((User2."User Security ID")), 'Expected the user to not have an M365 plan');

        AzureADPlan.GetPlanNames(User2."User Security ID", PlanNames);
        Assert.AreEqual(PlanNames.Get(1), UserDetailsTestLibrary.UserPlans((User2."User Security ID")), 'Unexpected user plans were returned.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestUserAuditFlowFields()
    var
        User: Record User;
        TempUserDetails: Record "User Details";
        UserDetails: Codeunit "User Details";
    begin
        User."User Security ID" := CreateGuid();
        User."User Name" := CreateGuid();
        User.Insert();

        UserDetails.Get(TempUserDetails);
        User."Full Name" := 'Updated user';
        User.Modify();
        User.Get(User."User Security ID");
        Assert.AreNotEqual(0DT, User.SystemCreatedAt, 'The source user must have a creation timestamp.');
        Assert.AreNotEqual(0DT, User.SystemModifiedAt, 'The source user must have a modification timestamp.');
        Assert.AreEqual(UserSecurityId(), User.SystemCreatedBy, 'The source user must have a creator.');
        Assert.AreEqual(UserSecurityId(), User.SystemModifiedBy, 'The source user must have a modifier.');

        TempUserDetails.Get(User."User Security ID");
        TempUserDetails.CalcFields("User System Created At", "User System Created By", "User System Modified At", "User System Modified By");

        Assert.AreEqual(User.SystemCreatedAt, TempUserDetails."User System Created At", 'Created at must come from the user record.');
        Assert.AreEqual(User.SystemCreatedBy, TempUserDetails."User System Created By", 'Created by must come from the user record.');
        Assert.AreEqual(User.SystemModifiedAt, TempUserDetails."User System Modified At", 'Modified at must come from the user record.');
        Assert.AreEqual(User.SystemModifiedBy, TempUserDetails."User System Modified By", 'Modified by must come from the user record.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestInactive7DaysFilter()
    begin
        VerifyInactiveDaysFilter(Enum::"User Detail Date Filter"::"7 Days", CalcDate('<-7D>', Today()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestInactive30DaysFilter()
    begin
        VerifyInactiveDaysFilter(Enum::"User Detail Date Filter"::"30 Days", CalcDate('<-30D>', Today()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestInactive90DaysFilter()
    begin
        VerifyInactiveDaysFilter(Enum::"User Detail Date Filter"::"90 Days", CalcDate('<-90D>', Today()));
    end;

    local procedure VerifyInactiveDaysFilter(DateFilter: Enum "User Detail Date Filter"; CutoffDate: Date)
    var
        CutoffUser: Record User;
        RecentUser: Record User;
        NeverLoggedInUser: Record User;
        UserDetailsPage: TestPage "User Details";
        CutoffDateTime: DateTime;
    begin
        CutoffDateTime := CreateDateTime(CutoffDate, 235959T);
        CreateUserWithLastLogin(CutoffUser, CutoffDateTime);
        CreateUserWithLastLogin(RecentUser, CutoffDateTime + 1000);
        CreateUserWithLastLogin(NeverLoggedInUser, 0DT);

        UserDetailsPage.OpenView();
        UserDetailsPage.Filter.SetFilter("Inactive Days Date Filter", Format(DateFilter));
        UserDetailsPage.Filter.SetFilter("User Name", CutoffUser."User Name");
        Assert.IsTrue(UserDetailsPage.First(), 'A login at the end of the cutoff day must be included.');
        UserDetailsPage."Last Login Date".AssertEquals(CutoffDateTime);

        UserDetailsPage.Filter.SetFilter("User Name", RecentUser."User Name");
        Assert.IsFalse(UserDetailsPage.First(), 'A login just after the cutoff day must be excluded.');

        UserDetailsPage.Filter.SetFilter("User Name", NeverLoggedInUser."User Name");
        Assert.IsTrue(UserDetailsPage.First(), 'A user who has never logged in must be included.');
        UserDetailsPage."Last Login Date".AssertEquals(0DT);

        UserDetailsPage.Filter.SetFilter("User Name", RecentUser."User Name");
        UserDetailsPage.Filter.SetFilter("Inactive Days Date Filter", '');
        Assert.IsTrue(UserDetailsPage.First(), 'Clearing the inactive filter must include recent logins again.');
        UserDetailsPage.Close();
    end;

    local procedure CreateUserWithLastLogin(var User: Record User; LastLoginDateTime: DateTime)
    var
        UserLogin: Record "User Login";
    begin
        User."User Security ID" := CreateGuid();
        User."User Name" := CreateGuid();
        User.Insert();

        if LastLoginDateTime = 0DT then
            exit;

        UserLogin."User SID" := User."User Security ID";
        UserLogin."Last Login Date" := LastLoginDateTime;
        UserLogin.Insert();
    end;
}

