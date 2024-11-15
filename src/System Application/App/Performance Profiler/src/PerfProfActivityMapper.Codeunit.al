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

    procedure MapActivityTypeToClientType(var ClientType: Option ,,"Web Service",,,Background,,"Web Client",,,,; ActivityType: Enum "Perf. Profile Activity Type")
    begin
        case ActivityType of
            ActivityType::"Web Client":
                ClientType := ClientType::"Web Client";
            ActivityType::Background:
                ClientType := ClientType::Background;
            ActivityType::"Web API Client":
                ClientType := ClientType::"Web Service";
        end;
    end;

    procedure MapClientTypeToActivityType(ClientType: Option ,,"Web Service",,,Background,,"Web Client",,,,; var ActivityType: Enum "Perf. Profile Activity Type")
    begin
        case ClientType of
            ClientType::Background:
                ActivityType := ActivityType::Background;
            ClientType::"Web Client":
                ActivityType := ActivityType::"Web Client";
            ClientType::"Web Service":
                ActivityType := ActivityType::"Web API Client";
        end;
    end;
}