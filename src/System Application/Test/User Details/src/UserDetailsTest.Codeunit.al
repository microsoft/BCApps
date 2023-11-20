// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.User;

using System.TestLibraries.Azure.ActiveDirectory;
using System.TestLibraries.Security.User;
using System.Azure.Identity;
using System.Security.AccessControl;
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
}

