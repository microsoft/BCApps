// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

/// <summary>
/// Provides procedures to open the Permissions Overview page with optional filters.
/// Raises integration events that allow the hosting application to handle the navigation.
/// </summary>
codeunit 9865 "Permissions Overview"
{
    Access = Public;

    /// <summary>
    /// Opens the Permissions Overview page without any filters.
    /// </summary>
    procedure Open()
    begin
        OnOpenPermissionsOverview();
    end;

    /// <summary>
    /// Opens the Permissions Overview page filtered to a specific permission set (Where-Used).
    /// </summary>
    /// <param name="RoleID">The Role ID of the permission set to filter on.</param>
    procedure OpenForPermissionSet(RoleID: Text[30])
    begin
        OnOpenPermissionsOverviewForPermissionSet(RoleID);
    end;

    /// <summary>
    /// Opens the Permissions Overview page filtered to a specific table.
    /// </summary>
    /// <param name="TableNo">The table number to filter on.</param>
    procedure OpenForTable(TableNo: Integer)
    begin
        OnOpenPermissionsOverviewForTable(TableNo);
    end;

    /// <summary>
    /// Raised when the Permissions Overview page should be opened without filters.
    /// </summary>
    [IntegrationEvent(false, false)]
    internal procedure OnOpenPermissionsOverview()
    begin
    end;

    /// <summary>
    /// Raised when the Permissions Overview page should be opened filtered to a permission set.
    /// </summary>
    /// <param name="RoleID">The Role ID to filter on.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnOpenPermissionsOverviewForPermissionSet(RoleID: Text[30])
    begin
    end;

    /// <summary>
    /// Raised when the Permissions Overview page should be opened filtered to a table.
    /// </summary>
    /// <param name="TableNo">The table number to filter on.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnOpenPermissionsOverviewForTable(TableNo: Integer)
    begin
    end;
}
