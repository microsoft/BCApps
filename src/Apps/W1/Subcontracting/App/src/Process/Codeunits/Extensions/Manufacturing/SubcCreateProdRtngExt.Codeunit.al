// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

codeunit 99001526 "Subc. Create Prod. Rtng. Ext."
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Report, Report::"Subc. Create Prod. Routing", OnAfterInsertRoutingHeader, '', false, false)]
    local procedure OnAfterInsertRoutingHeader(RoutingHeader: Record "Routing Header")
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        SubcontractingManagement.CreatePurchProvisionRoutingLine(RoutingHeader);
    end;
}