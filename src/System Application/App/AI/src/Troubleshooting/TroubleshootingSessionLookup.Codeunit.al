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

        if User."Full Name" <> '' then
            exit(User."Full Name");
        exit(User."User Name");
    end;
}
