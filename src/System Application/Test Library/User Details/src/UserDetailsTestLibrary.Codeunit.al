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
    procedure GetUserDetails()
    var
        UserDetails: Codeunit "User Details";
    begin
        UserDetails.Get(UserDetailsRec);
    end;

    /// <summary>
    /// Gets the value of "Has SUPER permission set" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure HasSuperPermissionSet(UserSID: Guid): Boolean
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
    procedure UserPlans(UserSID: Guid): Text
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."User Plans");
    end;

    /// <summary>
    /// Gets the value of "Is Delegated" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure IsDelegated(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Is Delegated");
    end;

    /// <summary>
    /// Gets the value of "Has M365 Plan" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure HasM365Plan(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Has M365 Plan");
    end;

    /// <summary>
    /// Gets the value of "Has Essential Plan" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure HasEssentialPlan(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Has Essential Plan");
    end;

    /// <summary>
    /// Gets the value of "Has Premium Plan" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure HasPremiumPlan(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Has Premium Plan");
    end;

    /// <summary>
    /// Gets the value of "Has Essential Or Premium Plan" for the user.
    /// </summary>
    /// <param name="UserSID">The user security ID</param>
    procedure HasEssentialOrPremiumPlan(UserSID: Guid): Boolean
    begin
        if not UserDetailsRec.Get(UserSID) then
            Error(UserDoesNotExistErr, UserSID);

        exit(UserDetailsRec."Has Essential Or Premium Plan");
    end;
}