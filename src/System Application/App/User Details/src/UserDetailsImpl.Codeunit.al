// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Security.AccessControl;

codeunit 775 "User Details Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Get(var UserDetails: Record "User Details")
    var
        User: Record User;
        LocalUserDetails: Record "User Details";
        UserDetailsFacade: Codeunit "User Details";
    begin
        LocalUserDetails.Copy(UserDetails, true);
        LocalUserDetails.Reset();
        LocalUserDetails.DeleteAll();

        User.SetRange("License Type", User."License Type"::"Full User");
        if User.FindSet() then
            repeat
                UserDetails."User Security ID" := User."User Security ID";
                UserDetailsFacade.OnAddUserDetails(UserDetails."User Security ID", UserDetails);
                UserDetails.Insert();
            until User.Next() = 0;
    end;
}