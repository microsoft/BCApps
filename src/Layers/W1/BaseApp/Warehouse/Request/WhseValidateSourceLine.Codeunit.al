// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Worksheet;

codeunit 5777 "Whse. Validate Source Line"
{
    trigger OnRun()
    begin
    end;

    var
        WhseActivLine: Record "Warehouse Activity Line";
        TableCaptionValue: Text;

#pragma warning disable AA0074, AA0470
        Text000: Label 'must not be changed when a %1 for this %2 exists: ';
        Text001: Label 'The %1 cannot be deleted when a related %2 exists.';
#pragma warning restore AA0074, AA0470
        JobPostQtyPickRemainErr: Label 'You cannot post usage for project number %1 because a quantity of %2 remains to be picked.', Comment = '%1 = Project number, %2 = remaining quantity to pick';

    procedure VerifyFieldNotChanged(NewRecRef: RecordRef; OldRecRef: RecordRef; FieldNumber: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNumber, IsHandled);
        if IsHandled then
            exit;

        VerifyFieldHasSameValue(NewRecRef, OldRecRef, FieldNumber, StrSubstNo(Text000, TableCaptionValue, NewRecRef.Caption));
    end;

    procedure VerifyFieldNotChanged(NewRecRef: RecordRef; OldRecRef: RecordRef; FieldNumber: Integer; ErrorMessage: Text)
    begin
        VerifyFieldHasSameValue(NewRecRef, OldRecRef, FieldNumber, ErrorMessage);
    end;

    local procedure VerifyFieldHasSameValue(FirstRecordRef: RecordRef; SecondRecordRef: RecordRef; FieldNumber: Integer; ErrorMessage: Text)
    var
        FirstFieldRef: FieldRef;
        SecondFieldRef: FieldRef;
    begin
        FirstFieldRef := FirstRecordRef.Field(FieldNumber);
        SecondFieldRef := SecondRecordRef.Field(FieldNumber);

        if Format(FirstFieldRef.Value) <> Format(SecondFieldRef.Value) then
            FirstFieldRef.FieldError(ErrorMessage);
    end;

    internal procedure FieldValueIsChanged(FirstRecordRef: RecordRef; SecondRecordRef: RecordRef; FieldNumber: Integer): Boolean
    var
        FirstFieldRef: FieldRef;
        SecondFieldRef: FieldRef;
    begin
        FirstFieldRef := FirstRecordRef.Field(FieldNumber);
        SecondFieldRef := SecondRecordRef.Field(FieldNumber);

        if Format(FirstFieldRef.Value) <> Format(SecondFieldRef.Value) then
            exit(true);

        exit(false);
    end;

    procedure TransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransLineVerifyChange(NewTransLine, OldTransLine, IsHandled);
        if IsHandled then
            exit;

        if WhseLinesExist(Database::"Transfer Line", 0, NewTransLine."Document No.", NewTransLine."Line No.", 0, NewTransLine.Quantity) then begin
            TransLineCommonVerification(NewTransLine, OldTransLine);
            if NewTransLine."Qty. to Ship" <> OldTransLine."Qty. to Ship" then
                NewTransLine.FieldError("Qty. to Ship", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));
        end;

        if WhseLinesExist(Database::"Transfer Line", 1, NewTransLine."Document No.", NewTransLine."Line No.", 0, NewTransLine.Quantity) then begin
            TransLineCommonVerification(NewTransLine, OldTransLine);
            if NewTransLine."Qty. to Receive" <> OldTransLine."Qty. to Receive" then
                NewTransLine.FieldError("Qty. to Receive", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));
        end;

        OnAfterTransLineVerifyChange(NewTransLine, OldTransLine);
    end;

    local procedure TransLineCommonVerification(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        if NewTransLine."Item No." <> OldTransLine."Item No." then
            NewTransLine.FieldError("Item No.", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));

        if NewTransLine."Variant Code" <> OldTransLine."Variant Code" then
            NewTransLine.FieldError("Variant Code", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));

        if NewTransLine."Unit of Measure Code" <> OldTransLine."Unit of Measure Code" then
            NewTransLine.FieldError("Unit of Measure Code", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));

        IsHandled := false;
        OnTransLineCommonVerificationOnBeforeQuantityCheck(OldTransLine, NewTransLine, IsHandled);
        if not IsHandled then
            if NewTransLine.Quantity <> OldTransLine.Quantity then
                NewTransLine.FieldError(Quantity, StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));
    end;

    procedure TransLineDelete(var TransLine: Record "Transfer Line")
    begin
        if WhseLinesExist(Database::"Transfer Line", 0, TransLine."Document No.", TransLine."Line No.", 0, TransLine.Quantity) then
            Error(Text001, TransLine.TableCaption(), TableCaptionValue);
        if WhseLinesExist(Database::"Transfer Line", 1, TransLine."Document No.", TransLine."Line No.", 0, TransLine.Quantity) then
            Error(Text001, TransLine.TableCaption(), TableCaptionValue);

        OnAfterTransLineDelete(TransLine);
    end;

    procedure WhseLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal) Result: Boolean
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseManagement: Codeunit "Whse. Management";
        CheckReceipt: Boolean;
        CheckShipment: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty, TableCaptionValue, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CheckReceipt := false;
        OnWhseLineExistOnBeforeCheckReceipt(SourceType, SourceSubType, SourceQty, CheckReceipt);
        if CheckReceipt then begin
            WhseManagement.SetSourceFilterForWhseRcptLine(WhseRcptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, true);
            OnWhseLinesExistOnAfterWhseRcptLineSetFilters(WhseRcptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceQty);
            if not WhseRcptLine.IsEmpty() then begin
                TableCaptionValue := WhseRcptLine.TableCaption();
                exit(true);
            end;
        end;

        CheckShipment := false;
        OnWhseLineExistOnBeforeCheckShipment(SourceType, SourceSubType, SourceQty, CheckShipment);
        if CheckShipment then begin
            WhseShptLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
            OnWhseLinesExistOnAfterWhseShptLineSetFilters(WhseShptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceQty, IsHandled);
            if not IsHandled then
                if not WhseShptLine.IsEmpty() then begin
                    TableCaptionValue := WhseShptLine.TableCaption();
                    exit(true);
                end;
        end;

        WhseActivLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, true);
        IsHandled := false;
        OnWhseLinesExistOnAfterWhseActivLineSetFilters(WhseActivLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceQty, IsHandled);
        if not IsHandled then
            if not WhseActivLine.IsEmpty() then begin
                TableCaptionValue := WhseActivLine.TableCaption();
                exit(true);
            end;

        TableCaptionValue := '';
        exit(false);
    end;

    procedure WhseLinesExistWithTableCaptionOut(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal; var TableCaptionValueOut: Text[100]): Boolean
    var
        Success: Boolean;
    begin
        Success := WhseLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty);
        TableCaptionValueOut := TableCaptionValue;
        exit(Success);
    end;

    procedure WhseWorkSheetLinesExistForJobOrProdOrderComponent(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal): Boolean
    begin
        if (SourceType in [Database::Job, 5407]) then // Database::"Prod. Order Component"
            exit(WhseWorkSheetLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty));

        TableCaptionValue := '';
        exit(false);
    end;

    internal procedure WhseWorkSheetLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal) Result: Boolean
    var
        WhseWorkSheetLine: Record "Whse. Worksheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseWorkSheetLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty, TableCaptionValue, Result, IsHandled);
        if IsHandled then
            exit(Result);

        WhseWorkSheetLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
        if not WhseWorkSheetLine.IsEmpty() then begin
            TableCaptionValue := WhseWorkSheetLine.TableCaption();
            exit(true);
        end;

        TableCaptionValue := '';
        exit(false);
    end;

    procedure ItemLineVerifyChange(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    var
        LinesExist: Boolean;
        QtyChecked: Boolean;
    begin
        LinesExist := false;
        OnItemLineVerifyChangeOnCheckEntryType(NewItemJnlLine, OldItemJnlLine, LinesExist, QtyChecked);

        if LinesExist then begin
            if (NewItemJnlLine."Item No." <> OldItemJnlLine."Item No.") and
               (OldItemJnlLine."Item No." <> '')
            then
                NewItemJnlLine.FieldError("Item No.", StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));

            if (NewItemJnlLine."Variant Code" <> OldItemJnlLine."Variant Code") and
               (OldItemJnlLine."Variant Code" <> '')
            then
                NewItemJnlLine.FieldError("Variant Code", StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));

            if (NewItemJnlLine."Location Code" <> OldItemJnlLine."Location Code") and
               (OldItemJnlLine."Location Code" <> '')
            then
                NewItemJnlLine.FieldError("Location Code", StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));

            if (NewItemJnlLine."Unit of Measure Code" <> OldItemJnlLine."Unit of Measure Code") and
               (OldItemJnlLine."Unit of Measure Code" <> '')
            then
                NewItemJnlLine.FieldError("Unit of Measure Code", StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));

            if (NewItemJnlLine.Quantity <> OldItemJnlLine.Quantity) and
               (OldItemJnlLine.Quantity <> 0) and
               not QtyChecked
            then
                NewItemJnlLine.FieldError(Quantity, StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));
        end;

        OnAfterItemLineVerifyChange(NewItemJnlLine, OldItemJnlLine);
    end;

    internal procedure JobJnlLineVerifyChangeForWhsePick(var NewJobJnlLine: Record "Job Journal Line"; var OldJobJnlLine: Record "Job Journal Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        QtyRemainingToBePicked: Decimal;
    begin
        if NewJobJnlLine.Quantity < 0 then
            exit;

        if not IsWhsePickRequiredForJobJnlLine(NewJobJnlLine) then
            exit;

        JobPlanningLine.SetLoadFields("Qty. Posted", "Qty. Picked", "Qty. to Assemble");
        if JobPlanningLine.Get(NewJobJnlLine."Job No.", NewJobJnlLine."Job Task No.", NewJobJnlLine."Job Planning Line No.") then begin
            QtyRemainingToBePicked := NewJobJnlLine.Quantity + JobPlanningLine."Qty. Posted" - JobPlanningLine."Qty. Picked" - JobPlanningLine."Qty. to Assemble";
            CheckQtyRemainingToBePickedForJob(NewJobJnlLine, QtyRemainingToBePicked);
        end;
    end;

    internal procedure IsWhsePickRequiredForJobJnlLine(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        Item: Record Item;
    begin
        if (JobJournalLine."Line Type" in [JobJournalLine."Line Type"::Budget, JobJournalLine."Line Type"::"Both Budget and Billable"]) and (JobJournalLine.Type = JobJournalLine.Type::Item) then
            if RequireWarehousePicking(JobJournalLine) then begin
                Item.SetLoadFields(Type);
                if Item.Get(JobJournalLine."No.") then
                    if Item.IsInventoriableType() then
                        exit(true);
            end;
    end;

    internal procedure IsInventoryPickRequiredForJobJnlLine(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        if (JobJournalLine."Line Type" in [JobJournalLine."Line Type"::Budget, JobJournalLine."Line Type"::"Both Budget and Billable"]) and (JobJournalLine.Type = JobJournalLine.Type::Item) then
            if RequireInventoryPicking(JobJournalLine) then begin
                if JobJournalLine."Job Planning Line No." <> 0 then
                    WarehouseActivityLine.SetRange("Source Subline No.", JobJournalLine."Job Planning Line No.");
                WarehouseActivityLine.SetRange("Source Type", Database::Job);
                WarehouseActivityLine.SetRange("Source No.", JobJournalLine."Job No.");
                exit(not WarehouseActivityLine.IsEmpty());
            end;
    end;

    local procedure RequireInventoryPicking(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        Location: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
    begin
        Location.SetLoadFields("Job Consump. Whse. Handling");
        if Location.Get(JobJournalLine."Location Code") then
            exit(Location."Job Consump. Whse. Handling" = Enum::"Job Consump. Whse. Handling"::"Inventory Pick");

        WarehouseSetup.SetLoadFields("Require Pick", "Require Shipment");
        WarehouseSetup.Get();
        exit(WarehouseSetup."Require Pick" and not WarehouseSetup."Require Shipment");
    end;

    local procedure RequireWarehousePicking(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        Location: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
    begin
        Location.SetLoadFields("Job Consump. Whse. Handling");
        if Location.Get(JobJournalLine."Location Code") then
            exit(Location."Job Consump. Whse. Handling" = Enum::"Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)");

        WarehouseSetup.SetLoadFields("Require Pick", "Require Shipment");
        WarehouseSetup.Get();
        exit(WarehouseSetup."Require Pick" and WarehouseSetup."Require Shipment");
    end;

    local procedure CheckQtyRemainingToBePickedForJob(NewJobJnlLine: Record "Job Journal Line"; QtyRemainingToBePicked: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyRemainingToBePickedForJob(NewJobJnlLine, QtyRemainingToBePicked, IsHandled);
        if IsHandled then
            exit;

        if QtyRemainingToBePicked > 0 then
            Error(JobPostQtyPickRemainErr, NewJobJnlLine."Job No.", QtyRemainingToBePicked);
    end;

#if not CLEAN26
    [Obsolete('Replaced by same procedure in codeunit ProdOrder Warehouse Mgt.', '26.0')]
    procedure CalcNextLevelProdOutput(ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"): Decimal
    var
        ProdOrderWarehouseMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Warehouse Mgt.";
    begin
        exit(ProdOrderWarehouseMgt.CalcNextLevelProdOutput(ProdOrderComp));
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemLineVerifyChange(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineDelete(var TransferLine: Record "Transfer Line")
    begin
    end;

#if not CLEAN26
    [Obsolete('Replaced by same event in codeunit Assembly Warehouse Mgt.', '26.0')]
    internal procedure RunOnBeforeCheckQtyRemainingToBePickedForAssemblyConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; var QtyRemainingToBePicked: Decimal)
    begin
        OnBeforeCheckQtyRemainingToBePickedForAssemblyConsumption(NewItemJnlLine, OldItemJnlLine, IsHandled, QtyRemainingToBePicked);
    end;

    [Obsolete('Replaced by same event in codeunit Assembly Warehouse Mgt.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyRemainingToBePickedForAssemblyConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; var QtyRemainingToBePicked: Decimal)
    begin
    end;
#endif

#if not CLEAN26
    internal procedure RunOnBeforeCheckQtyRemainingToBePickedForConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; QtyRemainingToBePicked: Decimal)
    begin
        OnBeforeCheckQtyRemainingToBePickedForConsumption(NewItemJnlLine, OldItemJnlLine, IsHandled, ProdOrderComp, QtyRemainingToBePicked);
    end;

    [Obsolete('Replaced by same event in codeunit ProdOrder Warehouse Mgt.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyRemainingToBePickedForConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; QtyRemainingToBePicked: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyRemainingToBePickedForJob(NewJobJnlLine: Record "Job Journal Line"; QtyRemainingToBePicked: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyFieldNotChanged(NewRecRef: RecordRef; OldRecRef: RecordRef; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal; var TableCaptionValue: Text[100]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN26
    internal procedure RunOnItemLineVerifyChangeOnBeforeCheckConsumptionQty(NewItemJournalLine: Record "Item Journal Line"; Location: Record Location; var QtyChecked: Boolean; var IsHandled: Boolean)
    begin
        OnItemLineVerifyChangeOnBeforeCheckConsumptionQty(NewItemJournalLine, Location, QtyChecked, IsHandled);
    end;

    [Obsolete('Replaced by same event in codeunit ProdOrderWarehouseMgt', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnItemLineVerifyChangeOnBeforeCheckConsumptionQty(NewItemJournalLine: Record "Item Journal Line"; Location: Record Location; var QtyChecked: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnTransLineCommonVerificationOnBeforeQuantityCheck(var OldTransferLine: Record "Transfer Line"; var NewTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseLinesExistOnAfterWhseRcptLineSetFilters(var WhseRcptLine: Record "Warehouse Receipt Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseLinesExistOnAfterWhseShptLineSetFilters(var WhseShptLine: Record "Warehouse Shipment Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseWorkSheetLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal; var TableCaptionValue: Text[100]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    internal procedure RaiseCannotBeDeletedErr(SourceTableCaption: Text)
    begin
        Error(Text001, SourceTableCaption, TableCaptionValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseLineExistOnBeforeCheckReceipt(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckReceipt: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseLineExistOnBeforeCheckShipment(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckShipment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseLinesExistOnAfterWhseActivLineSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemLineVerifyChangeOnCheckEntryType(NewItemJnlLine: Record "Item Journal Line"; OldItemJnlLine: Record "Item Journal Line"; var LinesExist: Boolean; var QtyChecked: Boolean)
    begin
    end;
}
