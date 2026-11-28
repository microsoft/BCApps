// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.Troubleshooting;

using System.Security.AccessControl;

codeunit 7756 "Troubleshooting Session Lookup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure GetOwnerName(OwnerId: Guid): Text
    var
        User: Record User;
    begin
        if IsNullGuid(OwnerId) or not User.ReadPermission() then
            exit('');

        if not User.Get(OwnerId) then
            exit('');

        exit(GetDisplayName(User));
    end;

    internal procedure LoadReadableOwnerNames(var NamesByOwner: Dictionary of [Guid, Text])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        User: Record User;
    begin
        Clear(NamesByOwner);
        if not User.ReadPermission() then
            exit;

        User.SetLoadFields("User Security ID", "Full Name", "User Name");
        if User.FindSet() then
            repeat
                NamesByOwner.Add(User."User Security ID", GetDisplayName(User));
            until User.Next() = 0;
    end;

    local procedure GetDisplayName(User: Record User): Text
    begin
        if User."Full Name" <> '' then
            exit(User."Full Name");
        exit(User."User Name");
    end;
}
