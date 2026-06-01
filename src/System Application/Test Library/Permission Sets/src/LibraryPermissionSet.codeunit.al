// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Security.AccessControl;

using System.Security.AccessControl;

codeunit 133401 "Library Permission Set"
{
    Access = Public;

    /// <summary>
    /// Opens the permission set page for the given permission set.
    /// </summary>
    /// <param name="AppId">App ID of the permission set to open</param>
    /// <param name="RoleId">Role ID of the permission set to open</param>
    /// <param name="Name">Name of the permission set to open</param>
    procedure OpenPermissionSetPageForPermissionSet(AppId: Guid; RoleId: Code[30]; Name: Text)
    var
        TempPermissionSetBuffer: Record "PermissionSet Buffer";
        PermissionSetPage: Page "Permission Set";
    begin
        TempPermissionSetBuffer.Init();
        TempPermissionSetBuffer."App ID" := AppId;
        TempPermissionSetBuffer."Role ID" := RoleId;
        TempPermissionSetBuffer.Name := CopyStr(Name, 1, MaxStrLen(TempPermissionSetBuffer.Name));
        TempPermissionSetBuffer.Scope := TempPermissionSetBuffer.Scope::Tenant;
        PermissionSetPage.SetRecord(TempPermissionSetBuffer);
        PermissionSetPage.Run();
    end;
}