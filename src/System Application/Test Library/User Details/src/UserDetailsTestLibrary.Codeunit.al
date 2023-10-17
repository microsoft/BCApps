// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Security.User;

using System.Security.User;

/// <summary>
/// Test library for the User Details module
/// </summary>
codeunit 132001 "User Details Test Library"
{
    var
        UserDetailsRec: Record "User Details";
        UserDoesNotExistErr: Label 'The user with security ID %1 does not exist', Locked = true;

    /// <summary>
    /// Saves the user details inside this instance, so that they can be access later.
    /// </summary>
    procedure FetchUserDetails()
    var
        UserDetails: Codeunit "User Details";
    begin
        UserDetails.GetUserDetails(UserDetailsRec);
    end;

    /// <summary>
    /// Gets the value of "Has SUPER permission set" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure GetHasSuperPermissionSet(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        UserDetailsRec.CalcFields("Has SUPER permission set");
        exit(UserDetailsRec."Has SUPER permission set");
    end;

    /// <summary>
    /// Gets the value of "User Plans" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure GetUserPlans(UserSID: Guid): Text
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."User Plans");
    end;

    /// <summary>
    /// Gets the value of "Is Delegated" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure GetIsDelegated(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Is Delegated");
    end;

    /// <summary>
    /// Gets the value of "Has M365 Plan" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure GetHasM365Plan(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Has M365 Plan");
    end;

    /// <summary>
    /// Gets the value of "Has Essential Plan" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure GetHasEssentialPlan(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Has Essential Plan");
    end;

    /// <summary>
    /// Gets the value of "Has Premium Plan" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure GetHasPremiumPlan(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Has Premium Plan");
    end;

    /// <summary>
    /// Gets the value of "Has Essential Or Premium Plan" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure GetHasEssentialOrPremiumPlan(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Has Essential Or Premium Plan");
    end;
}