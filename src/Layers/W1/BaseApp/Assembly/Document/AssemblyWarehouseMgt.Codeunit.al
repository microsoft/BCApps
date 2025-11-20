// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Inventory.Journal;

codeunit 5997 "Assembly Warehouse Mgt."
{
    var
        WhseManagement: Codeunit "Whse. Management";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";

        CannotPostConsumptionErr: Label 'You cannot post consumption for order no. %1 because a quantity of %2 remains to be picked.', Comment = '%1 - order number, %2 - quantity';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        AssemblyLine: Record "Assembly Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Assembly Line" then begin
            AssemblyLine.SetRange("Document Type", SourceSubType);
            AssemblyLine.SetRange("Document No.", SourceNo);
            AssemblyLine.SetRange("Line No.", SourceLineNo);
            IsHandled := false;
            OnBeforeShowAssemblyLines(AssemblyLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                PAGE.RunModal(PAGE::"Assembly Lines", AssemblyLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if SourceType = Database::"Assembly Line" then
            if AssemblyHeader.Get(SourceSubType, SourceNo) then begin
                AssemblyHeader.SetRange("Document Type", SourceSubType);
                PAGE.RunModal(PAGE::"Assembly Order", AssemblyHeader);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowWhseActivityDocLine', '', false, false)]
    local procedure OnAfterShowWhseActivityDocLine(WhseActivityDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    begin
        if WhseActivityDocType = WhseActivityDocType::Assembly then
            ShowAssemblyLine(WhseDocNo, WhseDocLineNo);
    end;

    procedure ShowAssemblyLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", WhseDocNo);
        AssemblyLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Assembly Lines", AssemblyLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAssemblyLines(var AssemblyLine: Record "Assembly Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure AssemblyLineVerifyChange(var NewAssemblyLine: Record "Assembly Line"; var OldAssemblyLine: Record "Assembly Line")
    var
        Location: Record Location;
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
    begin
        if OldAssemblyLine.Type <> OldAssemblyLine.Type::Item then
            exit;

        if not WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Assembly Line", NewAssemblyLine."Document Type".AsInteger(), NewAssemblyLine."Document No.",
             NewAssemblyLine."Line No.", 0, NewAssemblyLine.Quantity)
        then
            exit;

        NewRecordRef.GetTable(NewAssemblyLine);
        OldRecordRef.GetTable(OldAssemblyLine);
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("Document Type"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("Document No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("Line No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("Variant Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("Location Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("Unit of Measure Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("Due Date"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo(Quantity));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("Quantity per"));
        if Location.Get(NewAssemblyLine."Location Code") and not Location."Require Shipment" then
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewAssemblyLine.FieldNo("Quantity to Consume"));

        OnAfterAssemblyLineVerifyChange(NewRecordRef, OldRecordRef);
    end;

    procedure AssemblyLineDelete(var AssemblyLine: Record "Assembly Line")
    begin
        if AssemblyLine.Type <> AssemblyLine.Type::Item then
            exit;

        if WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", 0,
             AssemblyLine.Quantity)
        then
            WhseValidateSourceLine.RaiseCannotBeDeletedErr(AssemblyLine.TableCaption());

        OnAfterAssemblyLineDelete(AssemblyLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssemblyLineVerifyChange(var NewRecordRef: RecordRef; var OldRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssemblyLineDelete(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSrcDocLineQtyOutstanding', '', false, false)]
    local procedure OnAfterGetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyBaseOutstanding: Decimal; var QtyOutstanding: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if SourceType = Database::"Assembly Line" then
            if AssemblyLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                QtyOutstanding := AssemblyLine."Remaining Quantity";
                QtyBaseOutstanding := AssemblyLine."Remaining Quantity (Base)";
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSourceDocumentType', '', false, false)]
    local procedure WhseManagementGetSourceDocumentType(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        case SourceType of
            Database::"Assembly Line":
                begin
                    SourceDocument := "Warehouse Journal Source Document"::"Assembly Consumption";
                    IsHandled := true;
                end;
            Database::"Assembly Header":
                begin
                    SourceDocument := "Warehouse Journal Source Document"::"Assembly Order";
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetJournalSourceDocument', '', false, false)]
    local procedure WhseManagementGetJournalSourceDocument(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        case SourceType of
            Database::"Assembly Line":
                begin
                    SourceDocument := SourceDocument::"Assembly Consumption";
                    IsHandled := true;
                end;
            Database::"Assembly Header":
                begin
                    SourceDocument := SourceDocument::"Assembly Order";
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnBeforeGetSourceType', '', false, false)]
    local procedure WhseManagementOnBeforeGetSourceType(WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceType: Integer; var IsHandled: Boolean)
    begin
        if WhseWorksheetLine."Whse. Document Type" = WhseWorksheetLine."Whse. Document Type"::Assembly then begin
            SourceType := Database::"Assembly Line";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Create Pick", 'OnCheckSourceDocument', '', false, false)]
    local procedure CreatePickOnCheckSourceDocument(var PickWhseWkshLine: Record "Whse. Worksheet Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if PickWhseWkshLine."Source Type" = Database::"Assembly Line" then begin
            AssemblyLine.SetRange("Document Type", PickWhseWkshLine."Source Subtype");
            AssemblyLine.SetRange("Document No.", PickWhseWkshLine."Source No.");
            AssemblyLine.SetRange("Line No.", PickWhseWkshLine."Source Line No.");
            if AssemblyLine.IsEmpty() then
                Error(WhseManagement.GetSourceDocumentDoesNotExistErr(), AssemblyLine.TableCaption(), AssemblyLine.GetFilters());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Integration Management", 'OnCheckBinTypeAndCode', '', false, false)]
    local procedure OnCheckBinTypeAndCode(BinType: Record "Bin Type"; AdditionalIdentifier: Option; SourceTable: Integer)
    begin
        case SourceTable of
            Database::"Assembly Header":
                BinType.AllowPutawayPickOrQCBinsOnly();
            Database::"Assembly Line":
                BinType.AllowPutawayOrQCBinsOnly();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Cross-Dock Opportunity", 'OnShowReservation', '', false, false)]
    local procedure OnShowReservation(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case WhseCrossDockOpportunity."To Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyLine.Get(WhseCrossDockOpportunity."To Source Subtype", WhseCrossDockOpportunity."To Source No.", WhseCrossDockOpportunity."To Source Line No.");
                    AssemblyLine.ShowReservation();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Pick Request", 'OnLookupDocumentNo', '', false, false)]
    local procedure OnLookupDocumentNo(var WhsePickRequest: Record "Whse. Pick Request")
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyOrders: Page "Assembly Orders";
    begin
        case WhsePickRequest."Document Type" of
            WhsePickRequest."Document Type"::Assembly:
                begin
                    if AssemblyHeader.Get(WhsePickRequest."Document Subtype", WhsePickRequest."Document No.") then
                        AssemblyOrders.SetRecord(AssemblyHeader);
                    AssemblyOrders.RunModal();
                    Clear(AssemblyOrders);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnItemLineVerifyChangeOnCheckEntryType', '', false, false)]
    local procedure OnItemLineVerifyChangeOnCheckEntryType(NewItemJnlLine: Record "Item Journal Line"; OldItemJnlLine: Record "Item Journal Line"; var LinesExist: Boolean; var QtyChecked: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
        Location: Record Location;
        QtyRemainingToBePicked: Decimal;
    begin
        case NewItemJnlLine."Entry Type" of
            NewItemJnlLine."Entry Type"::"Assembly Consumption":
                begin
                    NewItemJnlLine.TestField("Order Type", NewItemJnlLine."Order Type"::Assembly);
                    if Location.Get(NewItemJnlLine."Location Code") and (Location."Asm. Consump. Whse. Handling" = Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)") then
                        if AssemblyLine.Get(AssemblyLine."Document Type"::Order, NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.") and
                           (NewItemJnlLine.Quantity >= 0)
                        then begin
                            QtyRemainingToBePicked := NewItemJnlLine.Quantity - AssemblyLine."Qty. Picked";
                            CheckQtyRemainingToBePickedForAssemblyConsumption(NewItemJnlLine, OldItemJnlLine, QtyRemainingToBePicked);
                            QtyChecked := true;
                        end;

                    LinesExist := false;
                end;
        end;
    end;

    local procedure CheckQtyRemainingToBePickedForAssemblyConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; QtyRemainingToBePicked: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyRemainingToBePickedForAssemblyConsumption(NewItemJnlLine, OldItemJnlLine, IsHandled, QtyRemainingToBePicked);
#if not CLEAN26
        WhseValidateSourceLine.RunOnBeforeCheckQtyRemainingToBePickedForAssemblyConsumption(NewItemJnlLine, OldItemJnlLine, IsHandled, QtyRemainingToBePicked);
#endif
        if IsHandled then
            exit;

        if QtyRemainingToBePicked > 0 then
            Error(CannotPostConsumptionErr, NewItemJnlLine."Order No.", QtyRemainingToBePicked);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyRemainingToBePickedForAssemblyConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; var QtyRemainingToBePicked: Decimal)
    begin
    end;
}
