// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.API.Codeunits;

using System.Azure.Identity;
using System.Security.User;

/// <summary>
/// API codeunit exposing identity, plan and login context as non-data-bound (unbound) reads.
/// Wraps "Azure AD Plan" (9016), "Azure AD Graph User" (9024), "Azure AD User Management" (9010)
/// and "User Login Time Tracker" (9026).
/// </summary>
/// <remarks>TODO(AB#641822): decorate with the API codeunit subtype (microsoft/codeunits) when the platform ships it.</remarks>
codeunit 6011 "Identity API"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>Returns whether the given plan is assigned to the current user.</summary>
    /// <param name="PlanGUID">The plan ID.</param>
    procedure IsPlanAssignedToUser(PlanGUID: Guid): Boolean
    var
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        exit(AzureADPlan.IsPlanAssignedToUser(PlanGUID));
    end;

    /// <summary>Returns whether the given plan is assigned to the specified user.</summary>
    /// <param name="PlanGUID">The plan ID.</param>
    /// <param name="UserGUID">The user security ID.</param>
    procedure IsPlanAssignedToUser(PlanGUID: Guid; UserGUID: Guid): Boolean
    var
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        exit(AzureADPlan.IsPlanAssignedToUser(PlanGUID, UserGUID));
    end;

    /// <summary>Returns whether the current user is a delegated admin.</summary>
    procedure IsUserDelegatedAdmin(): Boolean
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
    begin
        exit(AzureADGraphUser.IsUserDelegatedAdmin());
    end;

    /// <summary>Returns whether the current user is delegated.</summary>
    procedure IsUserDelegated(): Boolean
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
    begin
        exit(AzureADGraphUser.IsUserDelegated());
    end;

    /// <summary>Returns whether the current user is a tenant admin.</summary>
    procedure IsUserTenantAdmin(): Boolean
    var
        AzureADUserManagement: Codeunit "Azure AD User Management";
    begin
        exit(AzureADUserManagement.IsUserTenantAdmin());
    end;

    /// <summary>Returns whether the specified user's permissions are customized.</summary>
    /// <param name="UserSecurityId">The user security ID.</param>
    procedure ArePermissionsCustomized(UserSecurityId: Guid): Boolean
    var
        AzureADUserManagement: Codeunit "Azure AD User Management";
    begin
        exit(AzureADUserManagement.ArePermissionsCustomized(UserSecurityId));
    end;

    /// <summary>Returns whether the specified user is logging in for the first time.</summary>
    /// <param name="UserSecurityID">The user security ID.</param>
    procedure IsFirstLogin(UserSecurityID: Guid): Boolean
    var
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
    begin
        exit(UserLoginTimeTracker.IsFirstLogin(UserSecurityID));
    end;

    /// <summary>Returns whether the current user logged in since the given date/time.</summary>
    /// <param name="FromDateTime">The date/time to check from.</param>
    procedure UserLoggedInSinceDateTime(FromDateTime: DateTime): Boolean
    var
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
    begin
        exit(UserLoginTimeTracker.UserLoggedInSinceDateTime(FromDateTime));
    end;

    /// <summary>Returns the current user's penultimate login date/time.</summary>
    procedure GetPenultimateLoginDateTime(): DateTime
    var
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
    begin
        exit(UserLoginTimeTracker.GetPenultimateLoginDateTime());
    end;

    /// <summary>Returns the specified user's penultimate login date/time.</summary>
    /// <param name="UserSecurityID">The user security ID.</param>
    procedure GetPenultimateLoginDateTime(UserSecurityID: Guid): DateTime
    var
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
    begin
        exit(UserLoginTimeTracker.GetPenultimateLoginDateTime(UserSecurityID));
    end;
}
