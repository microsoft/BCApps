// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

/// <summary>
/// Contains functionality related to retrieving user details.
/// </summary>
codeunit 774 "User Details"
{
    Access = Public;

    /// <summary>
    /// Retrieves the details of a user.
    /// </summary>
    /// <param name="UserDetails">The user details record to be populated.</param>
    procedure GetUserDetails(var UserDetails: Record "User Details")
    var
        UserDetailsImpl: Codeunit "User Details Impl.";
    begin
        UserDetailsImpl.GetUserDetails(UserDetails);
    end;
}