// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Family;
using Microsoft.Inventory.Tracking;

codeunit 99000788 "Mfg. Experience Tier"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        MfgExperienceTier: Codeunit "Mfg. Experience Tier";
        CannotInsertErr: Label 'You cannot insert into table %1. Premium features are blocked since you are accessing a non-premium company.', Comment = '%1 - Table caption';

    local procedure BlockInsert(IsTemporary: Boolean; TableCaption: Text)
    begin
        if IsTemporary then
            exit;

        Error(CannotInsertErr, TableCaption);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Experience Tier", 'OnCheckExperienceTierForUserPlanPremium', '', false, false)]
    local procedure OnCheckExperienceTierForUserPlanPremium()
    begin
        BindSubscription(MfgExperienceTier);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionOrder(RunTrigger: Boolean; var Rec: Record "Production Order")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderComponent(RunTrigger: Boolean; var Rec: Record "Prod. Order Component")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRoutingLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Routing Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Capacity Need", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderCapacityNeed(RunTrigger: Boolean; var Rec: Record "Prod. Order Capacity Need")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Tool", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRoutingTool(RunTrigger: Boolean; var Rec: Record "Prod. Order Routing Tool")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Personnel", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRoutingPersonnel(RunTrigger: Boolean; var Rec: Record "Prod. Order Routing Personnel")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Rtng Qlty Meas.", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRtngQltyMeas(RunTrigger: Boolean; var Rec: Record "Prod. Order Rtng Qlty Meas.")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderCommentLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Comment Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Rtng Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRtngCommentLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Rtng Comment Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Comp. Cmt Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderCompCmtLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Comp. Cmt Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Shift", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertWorkShift(RunTrigger: Boolean; var Rec: Record "Work Shift")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Shop Calendar", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertShopCalendar(RunTrigger: Boolean; var Rec: Record "Shop Calendar")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Shop Calendar Working Days", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertShopCalendarWorkingDays(RunTrigger: Boolean; var Rec: Record "Shop Calendar Working Days")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Shop Calendar Holiday", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertShopCalendarHoliday(RunTrigger: Boolean; var Rec: Record "Shop Calendar Holiday")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertWorkCenterGroup(RunTrigger: Boolean; var Rec: Record "Work Center Group")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Calendar Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertCalendarEntry(RunTrigger: Boolean; var Rec: Record "Calendar Entry")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Machine Center", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertMachineCenter(RunTrigger: Boolean; var Rec: Record "Machine Center")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Calendar Absence Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertCalendarAbsenceEntry(RunTrigger: Boolean; var Rec: Record "Calendar Absence Entry")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Stop", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertStop(RunTrigger: Boolean; var Rec: Record "Stop")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Scrap", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertScrap(RunTrigger: Boolean; var Rec: Record "Scrap")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingHeader(RunTrigger: Boolean; var Rec: Record "Routing Header")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingLine(RunTrigger: Boolean; var Rec: Record "Routing Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Manufacturing Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertManufacturingCommentLine(RunTrigger: Boolean; var Rec: Record "Manufacturing Comment Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production BOM Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionBOMHeader(RunTrigger: Boolean; var Rec: Record "Production BOM Header")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production BOM Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionBOMLine(RunTrigger: Boolean; var Rec: Record "Production BOM Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Family", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertFamily(RunTrigger: Boolean; var Rec: Record "Family")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Family Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertFamilyLine(RunTrigger: Boolean; var Rec: Record "Family Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingCommentLine(RunTrigger: Boolean; var Rec: Record "Routing Comment Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production BOM Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionBOMCommentLine(RunTrigger: Boolean; var Rec: Record "Production BOM Comment Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Link", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingLink(RunTrigger: Boolean; var Rec: Record "Routing Link")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTask(RunTrigger: Boolean; var Rec: Record "Standard Task")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production BOM Version", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionBOMVersion(RunTrigger: Boolean; var Rec: Record "Production BOM Version")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Capacity Unit of Measure", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertCapacityUnitofMeasure(RunTrigger: Boolean; var Rec: Record "Capacity Unit of Measure")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task Tool", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTaskTool(RunTrigger: Boolean; var Rec: Record "Standard Task Tool")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task Personnel", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTaskPersonnel(RunTrigger: Boolean; var Rec: Record "Standard Task Personnel")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task Description", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTaskDescription(RunTrigger: Boolean; var Rec: Record "Standard Task Description")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task Quality Measure", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTaskQualityMeasure(RunTrigger: Boolean; var Rec: Record "Standard Task Quality Measure")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Quality Measure", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertQualityMeasure(RunTrigger: Boolean; var Rec: Record "Quality Measure")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Version", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingVersion(RunTrigger: Boolean; var Rec: Record "Routing Version")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Matrix BOM Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionMatrixBOMLine(RunTrigger: Boolean; var Rec: Record "Production Matrix BOM Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Matrix  BOM Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionMatrixBOMEntry(RunTrigger: Boolean; var Rec: Record "Production Matrix  BOM Entry")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Where-Used Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertWhereUsedLine(RunTrigger: Boolean; var Rec: Record "Where-Used Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Tool", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingTool(RunTrigger: Boolean; var Rec: Record "Routing Tool")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Personnel", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingPersonnel(RunTrigger: Boolean; var Rec: Record "Routing Personnel")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Quality Measure", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingQualityMeasure(RunTrigger: Boolean; var Rec: Record "Routing Quality Measure")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Planning Routing Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertPlanningRoutingLine(RunTrigger: Boolean; var Rec: Record "Planning Routing Line")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Absence", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRegisteredAbsence(RunTrigger: Boolean; var Rec: Record "Registered Absence")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Capacity Constrained Resource", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertCapacityConstrainedResource(RunTrigger: Boolean; var Rec: Record "Capacity Constrained Resource")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertInventoryProfile(RunTrigger: Boolean; var Rec: Record "Inventory Profile")
    begin
        BlockInsert(Rec.IsTemporary(), Rec.TableCaption());
    end;
}