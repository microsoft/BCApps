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
        case ActivityType of
            ActivityType::WebClient:
                ClientTpe := ClientTpe::"Web Client";
            ActivityType::Background:
                ClientTpe := ClientTpe::Background;
            ActivityType::WebAPIClient:
                ClientTpe := ClientTpe::"Web Service";
        end;
    end;

    procedure MapClientTypeToActivityType(ClientTpe: Option ,,"Web Service",,,Background,,"Web Client",,,,; var ActivityType: Enum "Perf. Profile Activity Type")
    begin
        case ClientTpe of
            ClientTpe::Background:
                ActivityType := ActivityType::Background;
            ClientTpe::"Web Client":
                ActivityType := ActivityType::WebClient;
            ClientTpe::"Web Service":
                ActivityType := ActivityType::WebAPIClient;
        end;
    end;
}