// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Tooling;

codeunit 1934 "Perf. Prof. Activity Mapper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;


    procedure MapActivityTypeToClientType(var ClientTpe: Option ,,"Web Service",,,Background,,"Web Client",,,,; ActivityType: Enum "Perf. Profile Activity Type")
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

    procedure MapClientTypeToActivityType(ClientTpe: Option ,,"Web Service",,,Background,,"Web Client",,,,; var ActivityType: Enum "Perf. Profile Activity Type")
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
}