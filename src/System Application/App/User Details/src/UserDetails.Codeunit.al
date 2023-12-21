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
    procedure Get(var UserDetails: Record "User Details")
    var
        UserDetailsImpl: Codeunit "User Details Impl.";
    begin
        UserDetailsImpl.Get(UserDetails);
    end;

    /// <summary>
    /// If an extension adds fields to the User Details table, this event allows it to populate the added user details fields.
    /// </summary>
    /// <param name="UserSecId">User Security ID of the user to add the details for.</param>
    /// <param name="UserDetails">The table that holds the values for user details.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnAddUserDetails(UserSecId: Guid; var UserDetails: Record "User Details")
    begin
    end;
}