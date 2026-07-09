// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

codeunit 7327 WhseEmplLocationBuffer
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        WarehouseEmployeeLocationFilter: Text;
        HasLocationSubscribers: Boolean;
        CheckedLocationSubscribers: Boolean;

    procedure SetWarehouseEmployeeLocationFilter(NewFilter: Text)
    begin
        WarehouseEmployeeLocationFilter := NewFilter;
    end;

    procedure GetWarehouseEmployeeLocationFilter(): Text
    begin
        exit(WarehouseEmployeeLocationFilter);
    end;

    // There is an option to override the employee setup using event subscribers so we need to check all locations.
    // But we will only check once per session
    procedure SetHasLocationSubscribers(NewHasLocationSubscribers: Boolean)
    begin
        HasLocationSubscribers := NewHasLocationSubscribers;
        CheckedLocationSubscribers := true;
    end;

    procedure NeedToCheckLocationSubscribers(): Boolean
    begin
        if not CheckedLocationSubscribers then
            exit(true);
        exit(HasLocationSubscribers);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Employee", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterWhseEmplInsert(var Rec: Record "Warehouse Employee"; RunTrigger: Boolean)
    begin
        WarehouseEmployeeLocationFilter := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Employee", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterWhseEmplModify(var Rec: Record "Warehouse Employee"; RunTrigger: Boolean)
    begin
        WarehouseEmployeeLocationFilter := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Employee", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterWhseEmplDelete(var Rec: Record "Warehouse Employee"; RunTrigger: Boolean)
    begin
        WarehouseEmployeeLocationFilter := '';
    end;
}
