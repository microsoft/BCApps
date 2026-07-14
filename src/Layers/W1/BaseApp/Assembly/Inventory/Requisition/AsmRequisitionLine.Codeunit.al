// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;

codeunit 923 "Asm. Requisition Line"
{
    var
        NoAssemblyHeaderErr: Label 'There is no Assembly Header for this line.';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnGetDimFromRefOrderLineElseCase', '', false, false)]
    local procedure OnGetDimFromRefOrderLineElseCase(var RequisitionLine: Record "Requisition Line"; DimSetIDArr: array[10] of Integer; i: Integer)
    var
        AsmHeader: Record "Assembly Header";
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::Assembly:
                if AsmHeader.Get(AsmHeader."Document Type"::Order, RequisitionLine."Ref. Order No.") then
                    DimSetIDArr[i] := AsmHeader."Dimension Set ID";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnLookupRefOrderNoElseCase', '', false, false)]
    local procedure OnLookupRefOrderNoElseCase(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyOrder: Page "Assembly Order";
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::Assembly:
                if AssemblyHeader.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.") then begin
                    AssemblyOrder.SetRecord(AssemblyHeader);
                    AssemblyOrder.RunModal();
                end else
                    Message(NoAssemblyHeaderErr);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnValidateReplenishmentSystemCaseElse', '', false, false)]
    local procedure OnValidateReplenishmentSystemCaseElse(var RequisitionLine: Record "Requisition Line")
    begin
        case RequisitionLine."Replenishment System" of
            RequisitionLine."Replenishment System"::Assembly:
                RequisitionLine.SetReplenishmentSystemFromAssembly();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetFromBinCodeOnSetBinCode', '', false, false)]
    local procedure OnSetFromBinCodeOnSetBinCode(var RequisitionLine: Record "Requisition Line"; Location: Record Location)
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::Assembly:
                if RequisitionLine."Bin Code" = '' then
                    RequisitionLine."Bin Code" := Location."From-Assembly Bin Code";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterShouldUpdateEndingDateForSourceType', '', false, false)]
    local procedure OnAfterShouldUpdateEndingDateForSourceType(SourceType: Integer; var ShouldUpdate: Boolean)
    begin
        ShouldUpdate := ShouldUpdate or (SourceType = Database::"Assembly Header");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Action Messages", 'OnInitReqFromSourceBySource', '', false, false)]
    local procedure OnInitReqFromSourceBySource(var ReqLine: Record "Requisition Line"; ActionMessageEntry: Record "Action Message Entry"; var IsHandled: Boolean; var ShouldExit: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        case ActionMessageEntry."Source Type" of
            Database::"Assembly Header":
                begin
                    if AssemblyHeader.Get(ActionMessageEntry."Source Subtype", ActionMessageEntry."Source ID") then begin
                        ReqLine.GetAsmHeader(AssemblyHeader);
                        ShouldExit := true;
                    end;
                    IsHandled := true;
                end;
        end;
    end;
}