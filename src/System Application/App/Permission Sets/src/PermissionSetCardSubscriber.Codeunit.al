// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Environment;

/// <summary>
/// Subscribes to the platform OpenPermissionSetCard system action and opens the permission set card.
/// </summary>
codeunit 9850 "Permission Set Card Subscriber"
{
    Access = Internal;

    /// <summary>
    /// Event subscriber that opens the permission set card for the specified permission set.
    /// </summary>
    /// <param name="Scope">The permission set scope.</param>
    /// <param name="AppId">The app ID of the permission set.</param>
    /// <param name="RoleId">The role ID of the permission set.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenPermissionSetCard', '', false, false)]
    local procedure OnOpenPermissionSetCard(Scope: Integer; AppId: Guid; RoleId: Code[30])
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetRelation: Codeunit "Permission Set Relation";
    begin
        if not AggregatePermissionSet.Get(Scope, AppId, RoleId) then
            exit;

        PermissionSetRelation.OpenPermissionSetPage(
            AggregatePermissionSet.Name,
            AggregatePermissionSet."Role ID",
            AggregatePermissionSet."App ID",
            AggregatePermissionSet.Scope);
    end;
}
