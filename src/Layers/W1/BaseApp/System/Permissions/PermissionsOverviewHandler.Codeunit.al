// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

codeunit 9886 "Permissions Overview Handler"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Permissions Overview", 'OnOpenPermissionsOverview', '', false, false)]
    local procedure HandleOpenPermissionsOverview()
    var
        PermissionsOverviewPage: Page "Permissions Overview";
    begin
        PermissionsOverviewPage.Run();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Permissions Overview", 'OnOpenPermissionsOverviewForPermissionSet', '', false, false)]
    local procedure HandleOpenForPermissionSet(RoleID: Text[30])
    var
        PermissionsOverviewPage: Page "Permissions Overview";
    begin
        PermissionsOverviewPage.SetInitialRoleIDFilter(RoleID);
        PermissionsOverviewPage.Run();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Permissions Overview", 'OnOpenPermissionsOverviewForTable', '', false, false)]
    local procedure HandleOpenForTable(TableNo: Integer)
    var
        PermissionsOverviewPage: Page "Permissions Overview";
        ObjType: Option None,"Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
    begin
        PermissionsOverviewPage.SetInitialObjectFilter(ObjType::"Table Data", Format(TableNo));
        PermissionsOverviewPage.Run();
    end;
}
