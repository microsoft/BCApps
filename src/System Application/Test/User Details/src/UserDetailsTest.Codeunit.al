// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.User;

using System.Security.User;
using System.TestLibraries.Azure.ActiveDirectory;
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
        UserDetailsRec: Record "User Details";
        AccessControl: Record "Access Control";
        PlanIDs: Codeunit "Plan Ids";
        UserDetails: Codeunit "User Details";
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

        AzureADPlanTestLibrary.AssignUserToPlan(PlanIDs.GetGlobalAdminPlanId(), User1."User Security ID");
        AzureADPlanTestLibrary.AssignUserToPlan(PlanIDs.GetEssentialPlanId(), User1."User Security ID");
        AzureADPlanTestLibrary.AssignUserToPlan(PlanIDs.GetMicrosoft365PlanId(), User2."User Security ID");

        AccessControl."User Security ID" := User1."User Security ID";
        AccessControl."Role ID" := 'SUPER';
        AccessControl.Scope := AccessControl.Scope::System;
        AccessControl.Insert();

        // [WHEN] User details are retrieved with GetUserDetails
        UserDetails.GetUserDetails(UserDetailsRec);

        // [THEN] The details are as expected
        Assert.RecordCount(UserDetailsRec, 2);
        UserDetailsRec.SetAutoCalcFields();

        UserDetailsRec.SetRange("User Security ID", User1."User Security ID");
        UserDetailsRec.FindFirst();

        AzureADPlan.GetPlanNames(User1."User Security ID", PlanNames);
        Assert.AreEqual(PlanNames.Get(1) + ' ; ' + PlanNames.Get(2), UserDetailsRec."User Plans", 'Unexpected user plans were returned.'); // todo
        Assert.IsTrue(UserDetailsRec."Has SUPER permission set", 'Expected the user to have SUPER');
        Assert.IsTrue(UserDetailsRec."Has Essential Plan", 'Expected the user to have an Essential plan');
        Assert.IsFalse(UserDetailsRec."Has M365 Plan", 'Expected the user to not have an M365 plan');

        UserDetailsRec.SetRange("User Security ID", User2."User Security ID");
        UserDetailsRec.FindFirst();

        AzureADPlan.GetPlanNames(User2."User Security ID", PlanNames);
        Assert.AreEqual(PlanNames.Get(1), UserDetailsRec."User Plans", 'Unexpected user plans were returned.'); // todo
        Assert.IsFalse(UserDetailsRec."Has SUPER permission set", 'Expected the user to have SUPER');
        Assert.IsFalse(UserDetailsRec."Has Essential Plan", 'Expected the user to have an Essential plan');
        Assert.IsTrue(UserDetailsRec."Has M365 Plan", 'Expected the user to not have an M365 plan');
    end;
}

