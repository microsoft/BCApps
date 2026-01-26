// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Service.History;
using Microsoft.Service.Posting;

codeunit 10640 "Serv. Event Subscribers NO"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnBeforeServShptHeaderInsert', '', false, false)]
    local procedure OnBeforeServShptHeaderInsert(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: Record "Service Header")
    begin
        ServiceShipmentHeader."External Document No." := ServiceHeader."External Document No.";
    end;
}