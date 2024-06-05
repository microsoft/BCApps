// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Tooling;

using System.Security.User;

codeunit 1934 "Performance Profile Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;


    procedure MapActivityTypeToClientType(var ClientTpe: Option ,,"Web Service",,,Background,,"Web Client",,,,; ActivityType: Enum "Activity Type")
    begin
        if (ActivityType = ActivityType::WebClient) then
            ClientTpe := ClientTpe::"Web Client"
        else
            if (ActivityType = ActivityType::Background) then
                ClientTpe := ClientTpe::Background
            else
                if (ActivityType = ActivityType::WebAPIClient) then
                    ClientTpe := ClientTpe::"Web Service";
    end;

    procedure MapClientTypeToActivityType(ClientTpe: Option ,,"Web Service",,,Background,,"Web Client",,,,; var ActivityType: Enum "Activity Type")
    begin
        if (ClientTpe = ClientTpe::Background) then
            ActivityType := ActivityType::Background
        else
            if (ClientTpe = ClientTpe::"Web Client") then
                ActivityType := ActivityType::WebClient
            else
                if (ClientTpe = ClientTpe::"Web Service") then
                    ActivityType := ActivityType::WebAPIClient;
    end;

    procedure FilterUsers(var RecordRef: RecordRef; SecurityID: Guid)
    var
        UserPermissions: Codeunit "User Permissions";
        FilterView: Text;
        FilterTextTxt: Label 'where("User ID"=filter(''%1''))', locked = true;

    begin
        if UserPermissions.CanManageUsersOnTenant(SecurityID) then
            exit; // No need for additional user filters

        FilterView := StrSubstNo(FilterTextTxt, SecurityID);
        RecordRef.FilterGroup(2);
        RecordRef.SetView(FilterView);
        RecordRef.FilterGroup(0);
    end;
}