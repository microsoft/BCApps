// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;
using System.Utilities;

codeunit 7302 "WMS Management"
{

    trigger OnRun()
    begin
    end;

    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        Bin: Record Bin;
        TempErrorLog: Record "License Information" temporary;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseManagement: Codeunit "Whse. Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ShowError: Boolean;
        NextLineNo: Integer;
        LogErrors: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must not be %1';
        Text002: Label '\Do you still want to use this %1 ?';
        Text003: Label 'You must set-up a default location code for user %1.';
        Text004: Label '%1 to place (%2) exceeds the available capacity (%3) on %4 %5.';
        Text005: Label '%1 = ''%2'', %3 = ''%4'':\The total base quantity to take %5 must be equal to the total base quantity to place %6.';
        Text006: Label 'You must enter a %1 in %2 %3 = %4, %5 = %6.';
#pragma warning restore AA0470
        Text007: Label 'Cancelled.';
        Text008: Label 'Destination Name';
        Text009: Label 'Sales Order';
#pragma warning disable AA0470
        Text010: Label 'You cannot change the %1 because this item journal line is created from warehouse entries.\%2 %3 is set up with %4 and therefore changes must be made in a %5. ';
        Text011: Label 'You cannot use %1 %2 because it is set up with %3.\Adjustments to this location must therefore be made in a %4.';
        Text012: Label 'You cannot reclassify %1 %2 because it is set up with %3.\You can change this location code by creating a %4.';
        Text013: Label 'You cannot change item tracking because it is created from warehouse entries.\The %1 is set up with warehouse tracking, and %2 %3 is set up with %4.\Adjustments to item tracking must therefore be made in a warehouse journal.';
        Text014: Label 'You cannot change item tracking because the %1 is set up with warehouse tracking and %2 %3 is set up with %4.\Adjustments to item tracking must therefore be made in a warehouse journal.';
        Text015: Label 'You cannot use a %1 because %2 %3 is set up with %4.';
        Text016: Label '%1 = ''%2'', %3 = ''%4'', %5 = ''%6'', %7 = ''%8'': The total base quantity to take %9 must be equal to the total base quantity to place %10.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        UserIsNotWhseEmployeeErr: Label 'You must first set up user %1 as a warehouse employee.';
#pragma warning restore AA0470
        UserIsNotWhseEmployeeForLocationErr: Label 'To open warehouse document for location %1, You must first set up user %2 as a warehouse employee.', Comment = '%1: Location Code, %2: User Id';
        OpenWarehouseEmployeesPageQst: Label 'Do you want to do that now?';
        UserIsNotWhseEmployeeAtWMSLocationErr: Label 'You must first set up user %1 as a warehouse employee at a location with the Bin Mandatory setting.', Comment = '%1: USERID';
        DefaultLocationNotDirectedPutawayPickErr: Label 'You must set up a default location with the Directed Put-away and Pick setting and assign it to user %1.', Comment = '%1: USERID';

    procedure CreateWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; ItemJnlTemplateType: Option; var WhseJnlLine: Record "Warehouse Journal Line"; ToTransfer: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseJnlLine(ItemJnlLine, ItemJnlTemplateType, WhseJnlLine, ToTransfer, IsHandled);
        if IsHandled then
            exit;

        if ((not ItemJnlLine."Phys. Inventory") and (ItemJnlLine.Quantity = 0) and (ItemJnlLine."Invoiced Quantity" = 0)) or
        (ItemJnlLine."Value Entry Type" in [ItemJnlLine."Value Entry Type"::Rounding, ItemJnlLine."Value Entry Type"::Revaluation]) or
        ItemJnlLine.Adjustment
        then
            exit(false);

        if ToTransfer then
            ItemJnlLine."Location Code" := ItemJnlLine."New Location Code";
        GetLocation(ItemJnlLine."Location Code");
        OnCreateWhseJnlLineOnAfterGetLocation(ItemJnlLine, WhseJnlLine, Location);
        InitWhseJnlLine(ItemJnlLine, WhseJnlLine, ItemJnlLine."Quantity (Base)");
        SetZoneAndBins(ItemJnlLine, WhseJnlLine, ToTransfer);
        if (ItemJnlLine."Journal Template Name" <> '') and (ItemJnlLine."Journal Batch Name" <> '') then begin
            WhseJnlLine.SetSource(Database::"Item Journal Line", ItemJnlTemplateType, ItemJnlLine."Document No.", ItemJnlLine."Line No.", 0);
            WhseJnlLine."Source Document" := WhseManagement.GetWhseJnlSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
        end else
            if ItemJnlLine."Job No." <> '' then begin
                WhseJnlLine.SetSource(Database::"Job Journal Line", ItemJnlTemplateType, ItemJnlLine."Document No.", ItemJnlLine."Line No.", 0);
                WhseJnlLine."Source Document" := WhseManagement.GetWhseJnlSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
            end;
        WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";
        if ItemJnlLine."Job No." = '' then
            WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Item Journal"
        else
            WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Job Journal";
        WhseJnlLine."Reference No." := ItemJnlLine."Document No.";
        TransferWhseItemTracking(WhseJnlLine, ItemJnlLine);
        WhseJnlLine.Description := ItemJnlLine.Description;
        OnAfterCreateWhseJnlLine(WhseJnlLine, ItemJnlLine, ToTransfer);
        exit(true);
    end;

    procedure CheckWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal; ToTransfer: Boolean)
    var
        BinContent: Record "Bin Content";
        QtyAbsBase: Decimal;
        DeductQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseJnlLine(WarehouseJournalLine, SourceJnl, DecreaseQtyBase, ToTransfer, IsHandled);
        if IsHandled then
            exit;

        GetItem(WarehouseJournalLine."Item No.");
        WarehouseJournalLine.TestField("Location Code");
        GetLocation(WarehouseJournalLine."Location Code");
        OnCheckWhseJnlLineOnAfterGetLocation(WarehouseJournalLine, Location, Item);

        if SourceJnl = SourceJnl::WhseJnl then
            CheckAdjBinCode(WarehouseJournalLine);

        CheckWhseJnlLineTracking(WarehouseJournalLine);

        if WarehouseJournalLine."Entry Type" in [WarehouseJournalLine."Entry Type"::"Positive Adjmt.", WarehouseJournalLine."Entry Type"::Movement] then
            if SourceJnl = SourceJnl::" " then begin
                CheckWhseDocumentToZoneCode(WarehouseJournalLine);
                if WarehouseJournalLine."To Bin Code" = '' then
                    Error(
                      Text006,
                      WarehouseJournalLine.FieldCaption("Bin Code"), WarehouseJournalLine."Whse. Document Type",
                      WarehouseJournalLine.FieldCaption("Whse. Document No."), WarehouseJournalLine."Whse. Document No.",
                      WarehouseJournalLine.FieldCaption("Line No."), WarehouseJournalLine."Whse. Document Line No.");
            end else
                if (WarehouseJournalLine."Entry Type" <> WarehouseJournalLine."Entry Type"::Movement) or ToTransfer then begin
                    CheckToZoneCode(WarehouseJournalLine);
                    WarehouseJournalLine.TestField(WarehouseJournalLine."To Bin Code");
                end;
        if WarehouseJournalLine."Entry Type" in [WarehouseJournalLine."Entry Type"::"Negative Adjmt.", WarehouseJournalLine."Entry Type"::Movement] then
            if SourceJnl = SourceJnl::" " then begin
                CheckWhseDocumentFromZoneCode(WarehouseJournalLine);
                if WarehouseJournalLine."From Bin Code" = '' then
                    Error(
                      Text006,
                      WarehouseJournalLine.FieldCaption("Bin Code"), WarehouseJournalLine."Whse. Document Type",
                      WarehouseJournalLine.FieldCaption("Whse. Document No."), WarehouseJournalLine."Whse. Document No.",
                      WarehouseJournalLine.FieldCaption("Line No."), WarehouseJournalLine."Whse. Document Line No.");
            end else
                if (WarehouseJournalLine."Entry Type" <> WarehouseJournalLine."Entry Type"::Movement) or not ToTransfer then begin
                    if Location."Directed Put-away and Pick" then
                        WarehouseJournalLine.TestField(WarehouseJournalLine."From Zone Code");
                    WarehouseJournalLine.TestField(WarehouseJournalLine."From Bin Code");
                end;

        QtyAbsBase := WarehouseJournalLine."Qty. (Absolute, Base)";
        IsHandled := false;
        OnCheckWhseJnlLineOnBeforeCheckBySourceJnl(WarehouseJournalLine, Bin, SourceJnl, BinContent, Location, DecreaseQtyBase, IsHandled);
        if not IsHandled then begin
            CheckDecreaseBinContent(WarehouseJournalLine, SourceJnl, DecreaseQtyBase);
            case SourceJnl of
                SourceJnl::" ", SourceJnl::ItemJnl:
                    if (WarehouseJournalLine."To Bin Code" <> '') and (WarehouseJournalLine."To Bin Code" <> Location."Adjustment Bin Code") then
                        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then begin
                            if (WarehouseJournalLine."Reference Document" = WarehouseJournalLine."Reference Document"::"Posted Rcpt.") or
                                   (WarehouseJournalLine."Reference Document" = WarehouseJournalLine."Reference Document"::"Posted Rtrn. Rcpt.") or
                                   (WarehouseJournalLine."Reference Document" = WarehouseJournalLine."Reference Document"::"Posted T. Receipt") or
                                   (not Location."Directed Put-away and Pick")
                            then
                                DeductQty := 0
                            else
                                DeductQty := WarehouseJournalLine."Qty. (Absolute, Base)";

                            if BinContent.Get(WarehouseJournalLine."Location Code", WarehouseJournalLine."To Bin Code", WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Unit of Measure Code") then
                                BinContent.CheckIncreaseBinContent(WarehouseJournalLine."Qty. (Absolute, Base)", DeductQty, WarehouseJournalLine.Cubage, WarehouseJournalLine.Weight, WarehouseJournalLine.Cubage, WarehouseJournalLine.Weight, true, false)
                            else begin
                                GetBin(WarehouseJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
                                Bin.CheckIncreaseBin(Bin.Code, WarehouseJournalLine."Item No.", WarehouseJournalLine."Qty. (Absolute)", WarehouseJournalLine.Cubage, WarehouseJournalLine.Weight, WarehouseJournalLine.Cubage, WarehouseJournalLine.Weight, true, false);
                            end;
                        end else begin
                            CheckWarehouseClass(WarehouseJournalLine."Location Code", WarehouseJournalLine."To Bin Code", WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Unit of Measure Code");
                            CheckBinAndBinContentMovement(WarehouseJournalLine);
                        end;
                SourceJnl::OutputJnl, SourceJnl::ConsumpJnl:
                    if WarehouseJournalLine."To Bin Code" <> '' then
                        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
                            if BinContent.Get(WarehouseJournalLine."Location Code", WarehouseJournalLine."To Bin Code", WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Unit of Measure Code") then
                                BinContent.CheckIncreaseBinContent(WarehouseJournalLine."Qty. (Absolute)", WarehouseJournalLine."Qty. (Absolute)", WarehouseJournalLine.Cubage, WarehouseJournalLine.Weight, WarehouseJournalLine.Cubage, WarehouseJournalLine.Weight, true, false)
                            else begin
                                GetBin(WarehouseJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
                                Bin.CheckIncreaseBin(Bin.Code, WarehouseJournalLine."Item No.", WarehouseJournalLine."Qty. (Absolute)", WarehouseJournalLine.Cubage, WarehouseJournalLine.Weight, WarehouseJournalLine.Cubage, WarehouseJournalLine.Weight, true, false);
                            end
                        else
                            CheckWarehouseClass(WarehouseJournalLine."Location Code", WarehouseJournalLine."To Bin Code", WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Unit of Measure Code");
                SourceJnl::WhseJnl:
                    if (WarehouseJournalLine."To Bin Code" <> '') and
                       (WarehouseJournalLine."To Bin Code" <> Location."Adjustment Bin Code") and
                       Location."Check Whse. Class"
                    then begin
                        GetBin(WarehouseJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
                        Bin.CheckWhseClass(WarehouseJournalLine."Item No.", false);
                    end;
            end;
        end;
        if QtyAbsBase <> WarehouseJournalLine."Qty. (Absolute, Base)" then begin
            WarehouseJournalLine.Validate(WarehouseJournalLine."Qty. (Absolute, Base)");
            WarehouseJournalLine.Modify();
        end;

        OnAfterCheckWhseJnlLine(WarehouseJournalLine, SourceJnl, DecreaseQtyBase, ToTransfer, Item);
    end;

    local procedure CheckWarehouseClass(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        GetLocation(LocationCode);
        if Location."Check Whse. Class" and (BinCode <> '') then
            if BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode) then
                BinContent.CheckWhseClass(false)
            else begin
                GetBin(LocationCode, BinCode);
                Bin.CheckWhseClass(ItemNo, false);
            end;
    end;

    local procedure CheckDecreaseBinContent(var WarehouseJournalLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal)
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDecreaseBinContent(WarehouseJournalLine, SourceJnl, DecreaseQtyBase, IsHandled);
        if IsHandled then
            exit;

        GetLocation(WarehouseJournalLine."Location Code");
        BinContent.ReadIsolation(IsolationLevel::UpdLock); // to avoid concurrent sessions to take from the same bin
        case SourceJnl of
            SourceJnl::" ", SourceJnl::ItemJnl:
                if (WarehouseJournalLine."From Bin Code" <> '') and
                   (WarehouseJournalLine."From Bin Code" <> Location."Adjustment Bin Code") and
                   Location."Directed Put-away and Pick"
                then begin
                    BinContent.Get(
                      WarehouseJournalLine."Location Code", WarehouseJournalLine."From Bin Code",
                      WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Unit of Measure Code");
                    BinContent.CheckDecreaseBinContent(WarehouseJournalLine."Qty. (Absolute)", WarehouseJournalLine."Qty. (Absolute, Base)", DecreaseQtyBase);
                end;
            SourceJnl::OutputJnl, SourceJnl::ConsumpJnl:
                if (WarehouseJournalLine."From Bin Code" <> '') and
                   Location."Directed Put-away and Pick"
                then begin
                    BinContent.Get(
                      WarehouseJournalLine."Location Code", WarehouseJournalLine."From Bin Code",
                      WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Unit of Measure Code");
                    BinContent.CheckDecreaseBinContent(WarehouseJournalLine."Qty. (Absolute)", WarehouseJournalLine."Qty. (Absolute, Base)", DecreaseQtyBase);
                end;
            SourceJnl::WhseJnl:
                if (WarehouseJournalLine."From Bin Code" <> '') and
                   (WarehouseJournalLine."From Bin Code" <> Location."Adjustment Bin Code") and
                   Location."Directed Put-away and Pick"
                then
                    if not ItemTrackingMgt.GetWhseItemTrkgSetup(WarehouseJournalLine."Item No.") then begin
                        BinContent.Get(
                          WarehouseJournalLine."Location Code", WarehouseJournalLine."From Bin Code",
                          WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Unit of Measure Code");
                        BinContent.CheckDecreaseBinContent(WarehouseJournalLine."Qty. (Absolute)", WarehouseJournalLine."Qty. (Absolute, Base)", DecreaseQtyBase);
                    end;
        end;
    end;

    local procedure CheckWhseJnlLineTracking(var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseJnlLineTracking(WarehouseJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
            if (WarehouseJournalLine."Serial No." <> '') and
               (WarehouseJournalLine."From Bin Code" <> '') and
               ItemTrackingCode."SN Specific Tracking" and
               (WarehouseJournalLine."From Bin Code" <> Location."Adjustment Bin Code") and
               (((Location."Adjustment Bin Code" <> '') and
                 (WarehouseJournalLine."Entry Type" = WarehouseJournalLine."Entry Type"::Movement)) or
                ((WarehouseJournalLine."Entry Type" <> WarehouseJournalLine."Entry Type"::Movement) or
                 (WarehouseJournalLine."Source Document" = WarehouseJournalLine."Source Document"::"Reclass. Jnl.")))
            then
                CheckSerialNo(
                  WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Location Code", WarehouseJournalLine."From Bin Code",
                  WarehouseJournalLine."Unit of Measure Code", WarehouseJournalLine."Serial No.", WarehouseJournalLine.CalcReservEntryQuantity());

            if (WarehouseJournalLine."Lot No." <> '') and
               (WarehouseJournalLine."From Bin Code" <> '') and
               ItemTrackingCode."Lot Specific Tracking" and
               (WarehouseJournalLine."From Bin Code" <> Location."Adjustment Bin Code") and
               (((Location."Adjustment Bin Code" <> '') and
                 (WarehouseJournalLine."Entry Type" = WarehouseJournalLine."Entry Type"::Movement)) or
                ((WarehouseJournalLine."Entry Type" <> WarehouseJournalLine."Entry Type"::Movement) or
                 (WarehouseJournalLine."Source Document" = WarehouseJournalLine."Source Document"::"Reclass. Jnl.")))
            then
                CheckLotNo(
                  WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Location Code", WarehouseJournalLine."From Bin Code",
                  WarehouseJournalLine."Unit of Measure Code", WarehouseJournalLine."Lot No.", WarehouseJournalLine.CalcReservEntryQuantity());

            OnCheckWhseJnlLineOnAfterCheckTracking(WarehouseJournalLine, ItemTrackingCode, Location);
        end;
    end;

    local procedure CheckWhseDocumentToZoneCode(WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseDocumentToZoneCode(WarehouseJournalLine, IsHandled);
        if IsHandled then
            exit;

        if Location."Directed Put-away and Pick" and (WarehouseJournalLine."To Zone Code" = '') then
            Error(
              Text006,
              WarehouseJournalLine.FieldCaption("Zone Code"), WarehouseJournalLine."Whse. Document Type",
              WarehouseJournalLine.FieldCaption("Whse. Document No."), WarehouseJournalLine."Whse. Document No.",
              WarehouseJournalLine.FieldCaption("Line No."), WarehouseJournalLine."Whse. Document Line No.");
    end;

    local procedure CheckWhseDocumentFromZoneCode(WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseDocumentFromZoneCode(WarehouseJournalLine, IsHandled);
        if IsHandled then
            exit;

        if Location."Directed Put-away and Pick" and (WarehouseJournalLine."From Zone Code" = '') then
            Error(
              Text006,
              WarehouseJournalLine.FieldCaption("Zone Code"), WarehouseJournalLine."Whse. Document Type",
              WarehouseJournalLine.FieldCaption("Whse. Document No."), WarehouseJournalLine."Whse. Document No.",
              WarehouseJournalLine.FieldCaption("Line No."), WarehouseJournalLine."Whse. Document Line No.");
    end;

    local procedure CheckToZoneCode(WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckToZoneCode(WarehouseJournalLine, IsHandled);
        if IsHandled then
            exit;

        if Location."Directed Put-away and Pick" then
            WarehouseJournalLine.TestField("To Zone Code");
    end;

    local procedure CheckAdjBinCode(WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        FieldCapTxt: Text;
    begin
        if WarehouseJournalLine."Entry Type" = WarehouseJournalLine."Entry Type"::Movement then
            exit;

        GetLocation(WarehouseJournalLine."Location Code");
        if not Location."Directed Put-away and Pick" then
            exit;

        WarehouseJournalTemplate.Get(WarehouseJournalLine."Journal Template Name");
        if WarehouseJournalTemplate.Type = WarehouseJournalTemplate.Type::Reclassification then
            exit;

        Location.TestField("Adjustment Bin Code");
        case WarehouseJournalLine."Entry Type" of
            WarehouseJournalLine."Entry Type"::"Positive Adjmt.":
                if (WarehouseJournalLine."From Bin Code" <> '') and (WarehouseJournalLine."From Bin Code" <> Location."Adjustment Bin Code") then
                    FieldCapTxt := WarehouseJournalLine.FieldCaption("From Bin Code");
            WarehouseJournalLine."Entry Type"::"Negative Adjmt.":
                if (WarehouseJournalLine."To Bin Code" <> '') and (WarehouseJournalLine."To Bin Code" <> Location."Adjustment Bin Code") then
                    FieldCapTxt := WarehouseJournalLine.FieldCaption("To Bin Code");
        end;
        if FieldCapTxt <> '' then
            Error(
              Text006,
              StrSubstNo('%1 = ''%2''', FieldCapTxt, Location."Adjustment Bin Code"),
              WarehouseJournalLine."Whse. Document Type",
              WarehouseJournalLine.FieldCaption("Whse. Document No."), WarehouseJournalLine."Whse. Document No.",
              WarehouseJournalLine.FieldCaption("Line No."), WarehouseJournalLine."Line No.");
    end;

    procedure CheckItemJnlLineFieldChange(ItemJnlLine: Record "Item Journal Line"; xItemJnlLine: Record "Item Journal Line"; CurrFieldCaption: Text[30])
    var
        BinContent: Record "Bin Content";
        WhseItemJournal: Page "Whse. Item Journal";
        WhsePhysInvtJournal: Page "Whse. Phys. Invt. Journal";
        BinIsEligible: Boolean;
        IsHandled: Boolean;
        Cubage: Decimal;
        Weight: Decimal;
    begin
        IsHandled := false;
        OnBeforeCheckItemJnlLineFieldChange(ItemJnlLine, xItemJnlLine, CurrFieldCaption, IsHandled);
        if IsHandled then
            exit;

        GetLocation(ItemJnlLine."Location Code");
        OnCheckIfBinIsEligible(ItemJnlLine, BinIsEligible);

        ShowError := CheckBinCodeChange(ItemJnlLine."Location Code", ItemJnlLine."Bin Code", xItemJnlLine."Bin Code") and not BinIsEligible;
        if not ShowError then
            ShowError := CheckBinCodeChange(ItemJnlLine."New Location Code", ItemJnlLine."New Bin Code", xItemJnlLine."New Bin Code");

        OnCheckItemJnlLineFieldChangeOnAfterCheckBinCodeChange(ItemJnlLine, xItemJnlLine, CurrFieldCaption, ShowError, BinIsEligible);
        if ShowError then begin
            IsHandled := false;
            OnCheckItemJnlLineFieldChangeOnBeforeShowError(ItemJnlLine, xItemJnlLine, IsHandled);
            if not IsHandled then
                Error(Text015,
                  CurrFieldCaption,
                  LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"));
        end;

        if ItemJnlLine."Entry Type" in
           [ItemJnlLine."Entry Type"::"Negative Adjmt.", ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemJnlLine."Entry Type"::Sale, ItemJnlLine."Entry Type"::Purchase]
        then begin
            if (ItemJnlLine."Location Code" <> xItemJnlLine."Location Code") and (xItemJnlLine."Location Code" <> '') then begin
                GetLocation(xItemJnlLine."Location Code");
                ShowError := Location."Directed Put-away and Pick";
            end;

            if ((ItemJnlLine."Item No." <> xItemJnlLine."Item No.") and (xItemJnlLine."Item No." <> '')) or
               ((ItemJnlLine.Quantity <> xItemJnlLine.Quantity) and (xItemJnlLine.Quantity <> 0)) or
               (ItemJnlLine."Variant Code" <> xItemJnlLine."Variant Code") or
               (ItemJnlLine."Unit of Measure Code" <> xItemJnlLine."Unit of Measure Code") or
               (ItemJnlLine."Entry Type" <> xItemJnlLine."Entry Type") or
               (ItemJnlLine."Phys. Inventory" and
                (ItemJnlLine."Qty. (Phys. Inventory)" <> xItemJnlLine."Qty. (Phys. Inventory)") or
                (ItemJnlLine.Quantity <> xItemJnlLine.Quantity))
            then begin
                GetLocation(ItemJnlLine."Location Code");
                ShowError := Location."Directed Put-away and Pick";
            end;

            OnCheckItemJnlLineFieldChangeOnAfterAssignShowError(ItemJnlLine, xItemJnlLine, CurrFieldCaption, ShowError);
            if ShowError then begin
                IsHandled := false;
                OnCheckItemJnlLineFieldChangeOnBeforeShowError(ItemJnlLine, xItemJnlLine, IsHandled);
                if not IsHandled then begin
                    if ItemJnlLine."Phys. Inventory" then
                        Error(Text010,
                          CurrFieldCaption,
                          Location.TableCaption(), Location.Code, Location.FieldCaption("Directed Put-away and Pick"),
                          WhsePhysInvtJournal.Caption);

                    Error(Text010,
                      CurrFieldCaption,
                      Location.TableCaption(), Location.Code, Location.FieldCaption("Directed Put-away and Pick"),
                      WhseItemJournal.Caption);
                end;
            end;
            GetLocation(ItemJnlLine."Location Code");
            if not Location."Bin Mandatory" then
                exit;
            if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then begin
                if ItemJnlLine."Bin Code" <> '' then begin
                    CalcCubageAndWeight(ItemJnlLine."Item No.", ItemJnlLine."Unit of Measure Code", ItemJnlLine.Quantity, Cubage, Weight);
                    if BinContent.Get(Location.Code, ItemJnlLine."Bin Code", ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."Unit of Measure Code") then
                        BinContent.CheckIncreaseBinContent(ItemJnlLine.Quantity, 0, 0, 0, Cubage, Weight, false, false)
                    else begin
                        GetBin(Location.Code, ItemJnlLine."Bin Code");
                        Bin.CheckIncreaseBin(Bin.Code, ItemJnlLine."Item No.", ItemJnlLine.Quantity, 0, 0, Cubage, Weight, false, false);
                    end;
                end
            end else
                CheckWarehouseClass(Location.Code, ItemJnlLine."Bin Code", ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."Unit of Measure Code");
        end;
    end;

    internal procedure CheckWarehouse(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; ItemUnitOfMeasureCode: Code[10]; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
        Cubage: Decimal;
        Weight: Decimal;
    begin
        GetLocation(LocationCode);
        if not Location."Bin Mandatory" then
            exit;
        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then begin
            if BinCode <> '' then begin
                CalcCubageAndWeight(ItemNo, ItemUnitOfMeasureCode, Quantity, Cubage, Weight);
                if BinContent.Get(Location.Code, BinCode, ItemNo, VariantCode, ItemUnitOfMeasureCode) then
                    BinContent.CheckIncreaseBinContent(Quantity, 0, 0, 0, Cubage, Weight, false, false)
                else begin
                    GetBin(LocationCode, BinCode);
                    Bin.CheckIncreaseBin(BinCode, ItemNo, Quantity, 0, 0, Cubage, Weight, false, false);
                end;
            end
        end else
            CheckWarehouseClass(Location.Code, BinCode, ItemNo, VariantCode, ItemUnitOfMeasureCode);
    end;

    procedure CheckItemJnlLineLocation(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line")
    var
        WhseItemJournal: Page "Whse. Item Journal";
        TransferOrder: Page "Transfer Order";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemJnlLineLocation(ItemJournalLine, xItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJournalLine."Entry Type" in
            [ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine."Entry Type"::Sale, ItemJournalLine."Entry Type"::Purchase]
        then
            if ItemJournalLine."Location Code" <> xItemJournalLine."Location Code" then begin
                GetLocation(xItemJournalLine."Location Code");
                if not Location."Directed Put-away and Pick" then begin
                    GetLocation(ItemJournalLine."Location Code");
                    if Location."Directed Put-away and Pick" then
                        Error(Text011,
                          LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"),
                          WhseItemJournal.Caption());
                end;
            end;

        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then begin
            if (ItemJournalLine."New Location Code" <> ItemJournalLine."Location Code") and
               ((ItemJournalLine."Location Code" <> xItemJournalLine."Location Code") or
                (ItemJournalLine."New Location Code" <> xItemJournalLine."New Location Code"))
            then begin
                GetLocation(ItemJournalLine."Location Code");
                ShowError := Location."Directed Put-away and Pick";
                if not Location."Directed Put-away and Pick" then begin
                    GetLocation(ItemJournalLine."New Location Code");
                    ShowError := Location."Directed Put-away and Pick";
                end;
            end;

            if ShowError then
                Error(Text012,
                  LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"),
                  TransferOrder.Caption);
        end;
    end;

    procedure CheckItemTrackingChange(TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingChange(TrackingSpecification, xTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        if (TrackingSpecification."Source Type" = Database::"Item Journal Line") and
            (TrackingSpecification."Item No." <> '') and
            (TrackingSpecification."Location Code" <> '')
        then begin
            if TrackingSpecification."Source Subtype" in [0, 1, 2, 3] then
                if not TrackingSpecification.HasSameTracking(xTrackingSpecification) or
                   ((xTrackingSpecification."Expiration Date" <> 0D) and
                    (TrackingSpecification."Expiration Date" <> xTrackingSpecification."Expiration Date")) or
                   (TrackingSpecification."Quantity (Base)" <> xTrackingSpecification."Quantity (Base)")
                then begin
                    GetLocation(TrackingSpecification."Location Code");
                    if Location."Directed Put-away and Pick" then begin
                        GetItem(TrackingSpecification."Item No.");
                        if ItemTrackingCode.IsWarehouseTracking() then
                            Error(Text013,
                              LowerCase(Item.TableCaption()),
                              LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"));
                    end;
                end;

            if TrackingSpecification.IsReclass() then
                if CheckTrackingSpecificationChangeNeeded(TrackingSpecification, xTrackingSpecification) then begin
                    GetLocation(TrackingSpecification."Location Code");
                    if Location."Directed Put-away and Pick" then begin
                        GetItem(TrackingSpecification."Item No.");
                        if ItemTrackingCode.IsWarehouseTracking() then
                            Error(Text014,
                              LowerCase(Item.TableCaption()),
                              LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"));
                    end;
                end;
        end;
    end;

    local procedure CheckBinCodeChange(LocationCode: Code[10]; BinCode: Code[20]; xRecBinCode: Code[20]): Boolean
    begin
        if (BinCode <> xRecBinCode) and (BinCode <> '') then begin
            GetLocation(LocationCode);
            exit(Location."Directed Put-away and Pick");
        end;

        exit(false);
    end;

    local procedure CheckTrackingSpecificationChangeNeeded(TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification") CheckNeeded: Boolean
    begin
        CheckNeeded :=
            (TrackingSpecification."New Lot No." <> TrackingSpecification."Lot No.") and
            ((TrackingSpecification."Lot No." <> xTrackingSpecification."Lot No.") or
            (TrackingSpecification."New Lot No." <> xTrackingSpecification."New Lot No.")) or
            (TrackingSpecification."New Serial No." <> TrackingSpecification."Serial No.") and
            ((TrackingSpecification."Serial No." <> xTrackingSpecification."Serial No.") or
            (TrackingSpecification."New Serial No." <> xTrackingSpecification."New Serial No.")) or
            (TrackingSpecification."New Expiration Date" <> TrackingSpecification."Expiration Date") and
            ((TrackingSpecification."Expiration Date" <> xTrackingSpecification."Expiration Date") or
            (TrackingSpecification."New Expiration Date" <> xTrackingSpecification."New Expiration Date"));

        OnAfterCheckTrackingSpecificationChangeNeeded(TrackingSpecification, xTrackingSpecification, CheckNeeded);
    end;

    procedure CheckAdjmtBin(Location2: Record Location; Quantity: Decimal; PosEntryType: Boolean)
    begin
        if not Location2."Directed Put-away and Pick" then
            exit;

        Location2.TestField(Code);
        Location2.TestField("Adjustment Bin Code");
        GetBin(Location2.Code, Location2."Adjustment Bin Code");

        // Test whether bin movement is blocked for current Entry Type
        if (PosEntryType and (Quantity > 0)) or
           (not PosEntryType and (Quantity < 0))
        then
            ShowError := (Bin."Block Movement" in
                          [Bin."Block Movement"::Inbound, Bin."Block Movement"::All])
        else
            if (PosEntryType and (Quantity < 0)) or
               (not PosEntryType and (Quantity > 0))
            then
                ShowError := (Bin."Block Movement" in
                              [Bin."Block Movement"::Outbound, Bin."Block Movement"::All]);

        if ShowError then
            Bin.FieldError("Block Movement", StrSubstNo(Text000, Bin."Block Movement"));
    end;

    procedure CheckInbOutbBin(LocationCode: Code[10]; BinCode: Code[20]; CheckInbound: Boolean)
    begin
        GetLocation(LocationCode);
        GetBin(LocationCode, BinCode);

        // Test whether bin movement is blocked for current Entry Type
        if CheckInbound then
            if Bin."Block Movement" in [Bin."Block Movement"::Inbound, Bin."Block Movement"::All] then
                Bin.FieldError("Block Movement", StrSubstNo(Text000, Bin."Block Movement"));

        if not CheckInbound then
            if Bin."Block Movement" in [Bin."Block Movement"::Outbound, Bin."Block Movement"::All] then
                Bin.FieldError("Block Movement", StrSubstNo(Text000, Bin."Block Movement"));
    end;

    procedure CheckUserIsWhseEmployee()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUserIsWhseEmployee(Location, IsHandled);
        if IsHandled then
            exit;

        if UserId <> '' then begin
            WarehouseEmployee.SetRange("User ID", UserId);
            if WarehouseEmployee.IsEmpty() then
                ConfirmOpenWarehouseEmployees(WarehouseEmployee, StrSubstNo(UserIsNotWhseEmployeeErr, UserId()));
        end;
    end;

    procedure CheckUserIsWhseEmployeeForLocation(LocationCode: Code[10]; DoCommit: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        if UserId <> '' then begin
            if DoCommit then
                Commit();

            WarehouseEmployee.SetRange("User ID", UserId);
            WarehouseEmployee.SetRange("Location Code", LocationCode);
            if WarehouseEmployee.IsEmpty() then
                ConfirmOpenWarehouseEmployees(WarehouseEmployee, StrSubstNo(UserIsNotWhseEmployeeForLocationErr, LocationCode, UserId()));
        end;
    end;

    local procedure ConfirmOpenWarehouseEmployees(var WarehouseEmployee: Record "Warehouse Employee"; ErrorMessage: Text)
    var
        WarehouseEmployeeLocal: Record "Warehouse Employee";
        ConfirmManagement: Codeunit "Confirm Management";
        WarehouseEmployees: Page "Warehouse Employees";
        ConfirmText: TextBuilder;
        WarehouseEmployeeExists: Boolean;
    begin
        ConfirmText.AppendLine(ErrorMessage);
        ConfirmText.AppendLine();
        ConfirmText.AppendLine(OpenWarehouseEmployeesPageQst);

        WarehouseEmployeeLocal.CopyFilters(WarehouseEmployee);
        WarehouseEmployeeLocal.SetRange(Default);

        if ConfirmManagement.GetResponseOrDefault(ConfirmText.ToText(), false) then begin
            WarehouseEmployees.SetTableView(WarehouseEmployeeLocal);
            WarehouseEmployees.RunModal();
            if not WarehouseEmployee.IsEmpty() then
                WarehouseEmployeeExists := true;
        end;

        if not WarehouseEmployeeExists then
            Error(ErrorMessage);
    end;

    procedure CalcCubageAndWeight(ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; var Cubage: Decimal; var Weight: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCubageAndWeight(ItemNo, UOMCode, Qty, Cubage, Weight, IsHandled);
        if IsHandled then
            exit;

        if ItemNo <> '' then begin
            GetItemUnitOfMeasure(ItemNo, UOMCode);
            Cubage := Qty * ItemUnitOfMeasure.Cubage;
            Weight := Qty * ItemUnitOfMeasure.Weight;
        end else begin
            Cubage := 0;
            Weight := 0;
        end;
    end;

    procedure GetDefaultLocation(): Code[10]
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LocationCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultLocation(LocationCode, IsHandled);
        if IsHandled then
            exit(LocationCode);

        if UserId() <> '' then begin
            WarehouseEmployee.SetCurrentKey(Default);
            WarehouseEmployee.SetRange(Default, true);
            WarehouseEmployee.SetRange("User ID", UserId());
            if WarehouseEmployee.IsEmpty() then
                ConfirmOpenWarehouseEmployees(WarehouseEmployee, StrSubstNo(Text003, UserId()));
            WarehouseEmployee.FindFirst();
            exit(WarehouseEmployee."Location Code");
        end;
    end;

    procedure GetWMSLocation(var CurrentLocationCode: Code[10])
    var
        Location2: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WhseEmployeesAtLocations: Query "Whse. Employees at Locations";
    begin
        if WarehouseEmployee.Get(UserId, CurrentLocationCode) and Location2.Get(CurrentLocationCode) then
            if Location2."Bin Mandatory" then
                exit;

        WhseEmployeesAtLocations.TopNumberOfRows(1);
        WhseEmployeesAtLocations.SetRange(User_ID, UserId());
        WhseEmployeesAtLocations.SetRange(Bin_Mandatory, true);
        WhseEmployeesAtLocations.Open();
        if WhseEmployeesAtLocations.Read() then begin
            CurrentLocationCode := WhseEmployeesAtLocations.Code;
            exit;
        end;

        WarehouseEmployee.SetRange("User Id", UserId());
        ConfirmOpenWarehouseEmployees(WarehouseEmployee, StrSubstNo(UserIsNotWhseEmployeeAtWMSLocationErr, UserId()));

        WhseEmployeesAtLocations.Open();
        if WhseEmployeesAtLocations.Read() then
            CurrentLocationCode := WhseEmployeesAtLocations.Code
        else
            Error(UserIsNotWhseEmployeeAtWMSLocationErr, UserId());
    end;

    procedure GetDefaultDirectedPutawayAndPickLocation() LocationCode: Code[10]
    var
        WarehouseEmployee: Record "Warehouse Employee";
        WhseEmployeesAtLocations: Query "Whse. Employees at Locations";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultDirectedPutawayAndPickLocation(LocationCode, IsHandled);
        if IsHandled then
            exit(LocationCode);

        WhseEmployeesAtLocations.TopNumberOfRows(1);
        WhseEmployeesAtLocations.SetRange(User_ID, UserId());
        WhseEmployeesAtLocations.SetRange(Default, true);
        WhseEmployeesAtLocations.SetRange(Directed_Put_away_and_Pick, true);
        WhseEmployeesAtLocations.Open();
        if WhseEmployeesAtLocations.Read() then
            exit(WhseEmployeesAtLocations.Code);

        WarehouseEmployee.SetRange("User Id", UserId());
        WarehouseEmployee.SetRange(Default, true);
        ConfirmOpenWarehouseEmployees(WarehouseEmployee, StrSubstNo(DefaultLocationNotDirectedPutawayPickErr, UserId()));

        WhseEmployeesAtLocations.Open();
        if WhseEmployeesAtLocations.Read() then
            exit(WhseEmployeesAtLocations.Code);

        Error(DefaultLocationNotDirectedPutawayPickErr, UserId);
    end;

    procedure GetDefaultBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var BinCode: Code[20]) Result: Boolean
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(ItemNo, VariantCode, LocationCode, BinCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        BinContent.SetCurrentKey(Default);
        BinContent.SetRange(Default, true);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContent.SetLoadFields("Bin Code");
        if BinContent.FindFirst() then begin
            BinCode := BinContent."Bin Code";
            exit(true);
        end;
    end;

    procedure CheckDefaultBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]): Boolean
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetCurrentKey(Default);
        BinContent.SetRange(Default, true);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContent.SetFilter("Bin Code", '<>%1', BinCode);
        exit(not BinContent.IsEmpty);
    end;

    procedure CheckBalanceQtyToHandle(var WarehouseActivityLine2: Record "Warehouse Activity Line")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine3: Record "Warehouse Activity Line";
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
        QtyToPick: Decimal;
        QtyToPutAway: Decimal;
        ErrorText: Text[250];
    begin
        OnBeforeCheckBalanceQtyToHandle(WarehouseActivityLine2);
        WarehouseActivityLine.Copy(WarehouseActivityLine2);

        WarehouseActivityLine.SetCurrentKey("Activity Type", "No.", "Item No.", "Variant Code", "Action Type");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityLine.SetRange("Action Type");
        if WarehouseActivityLine.FindSet() then
            repeat
                if not TempWarehouseActivityLine.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.", WarehouseActivityLine."Line No.") then begin
                    WarehouseActivityLine3.Copy(WarehouseActivityLine);
                    WarehouseActivityLine3.SetRange("Item No.", WarehouseActivityLine."Item No.");
                    WarehouseActivityLine3.SetRange("Variant Code", WarehouseActivityLine."Variant Code");
                    WarehouseActivityLine3.SetTrackingFilterFromWhseActivityLine(WarehouseActivityLine);
                    OnCheckBalanceQtyToHandleOnAfterSetFilters(WarehouseActivityLine3, WarehouseActivityLine);

                    if (WarehouseActivityLine2."Action Type" = WarehouseActivityLine2."Action Type"::Take) or
                        (WarehouseActivityLine2.GetFilter("Action Type") = '')
                    then begin
                        WarehouseActivityLine3.SetRange("Action Type", WarehouseActivityLine3."Action Type"::Take);
                        if WarehouseActivityLine3.FindSet() then
                            repeat
                                QtyToPick := QtyToPick + WarehouseActivityLine3."Qty. to Handle (Base)";
                                TempWarehouseActivityLine := WarehouseActivityLine3;
                                TempWarehouseActivityLine.Insert();
                            until WarehouseActivityLine3.Next() = 0;
                    end;

                    if (WarehouseActivityLine2."Action Type" = WarehouseActivityLine2."Action Type"::Place) or
                        (WarehouseActivityLine2.GetFilter("Action Type") = '')
                    then begin
                        WarehouseActivityLine3.SetRange("Action Type", WarehouseActivityLine3."Action Type"::Place);
                        if WarehouseActivityLine3.FindSet() then
                            repeat
                                QtyToPutAway := QtyToPutAway + WarehouseActivityLine3."Qty. to Handle (Base)";
                                TempWarehouseActivityLine := WarehouseActivityLine3;
                                TempWarehouseActivityLine.Insert();
                            until WarehouseActivityLine3.Next() = 0;
                    end;

                    if QtyToPick <> QtyToPutAway then begin
                        ErrorText := GetWrongPickPutAwayQtyErrorText(WarehouseActivityLine, WarehouseActivityLine3, QtyToPick, QtyToPutAway);
                        HandleError(ErrorText);
                    end;

                    QtyToPick := 0;
                    QtyToPutAway := 0;
                end;
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure GetWrongPickPutAwayQtyErrorText(WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine3: Record "Warehouse Activity Line"; QtyToPick: Decimal; QtyToPutAway: Decimal) ErrorText: Text[250]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetWrongPickPutAwayQtyErrorText(WarehouseActivityLine3, QtyToPick, QtyToPutAway, ErrorText, IsHandled, WarehouseActivityLine);
        if IsHandled then
            exit(ErrorText);

        if WarehouseActivityLine3.TrackingFilterExists() then
            ErrorText :=
              StrSubstNo(
                Text016,
                WarehouseActivityLine.FieldCaption("Item No."), WarehouseActivityLine."Item No.",
                WarehouseActivityLine.FieldCaption("Variant Code"), WarehouseActivityLine."Variant Code",
                WarehouseActivityLine.FieldCaption("Lot No."), WarehouseActivityLine."Lot No.",
                WarehouseActivityLine.FieldCaption("Serial No."), WarehouseActivityLine."Serial No.",
                QtyToPick, QtyToPutAway)
        else
            ErrorText :=
                StrSubstNo(
                Text005,
                WarehouseActivityLine.FieldCaption("Item No."), WarehouseActivityLine."Item No.",
                WarehouseActivityLine.FieldCaption("Variant Code"), WarehouseActivityLine."Variant Code",
                QtyToPick, QtyToPutAway);
    end;

    procedure CheckPutAwayAvailability(BinCode: Code[20]; CheckFieldCaption: Text[100]; CheckTableCaption: Text[100]; ValueToPutAway: Decimal; ValueAvailable: Decimal; Prohibit: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPutAwayAvailability(BinCode, CheckFieldCaption, CheckTableCaption, ValueToPutAway, ValueAvailable, Prohibit, IsHandled);
        if IsHandled then
            exit;

        if ValueToPutAway <= ValueAvailable then
            exit;
        if Prohibit then
            Error(
              Text004, CheckFieldCaption, ValueToPutAway, ValueAvailable,
              CheckTableCaption, BinCode);

        ConfirmExceededCapacity(BinCode, CheckFieldCaption, CheckTableCaption, ValueToPutAway, ValueAvailable);
    end;

    local procedure ConfirmExceededCapacity(BinCode: Code[20]; CheckFieldCaption: Text[100]; CheckTableCaption: Text[100]; ValueToPutAway: Decimal; ValueAvailable: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmExceededCapacity(IsHandled, BinCode, CheckFieldCaption, CheckTableCaption, ValueToPutAway, ValueAvailable);
        if IsHandled then
            exit;

        if not Confirm(
             StrSubstNo(
               Text004, CheckFieldCaption, ValueToPutAway, ValueAvailable,
               CheckTableCaption, BinCode) + StrSubstNo(Text002, CheckTableCaption), false)
        then
            Error(Text007);
    end;

    internal procedure InitWhseJnlLine(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line"; QuantityBase: Decimal)
    begin
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Journal Template Name" := ItemJournalLine."Journal Template Name";
        WarehouseJournalLine."Journal Batch Name" := ItemJournalLine."Journal Batch Name";
        WarehouseJournalLine."Location Code" := ItemJournalLine."Location Code";
        WarehouseJournalLine."Item No." := ItemJournalLine."Item No.";
        WarehouseJournalLine."Registering Date" := ItemJournalLine."Posting Date";
        WarehouseJournalLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(WarehouseJournalLine."User ID"));
        WarehouseJournalLine."Variant Code" := ItemJournalLine."Variant Code";
        if ItemJournalLine."Qty. per Unit of Measure" = 0 then
            ItemJournalLine."Qty. per Unit of Measure" := 1;
        GetLocation(WarehouseJournalLine."Location Code");
        if Location."Directed Put-away and Pick" then begin
            WarehouseJournalLine.Quantity := Round(QuantityBase / ItemJournalLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            WarehouseJournalLine."Unit of Measure Code" := ItemJournalLine."Unit of Measure Code";
            WarehouseJournalLine."Qty. per Unit of Measure" := ItemJournalLine."Qty. per Unit of Measure";
        end else begin
            WarehouseJournalLine.Quantity := QuantityBase;
            WarehouseJournalLine."Unit of Measure Code" := GetBaseUOM(ItemJournalLine."Item No.");
            WarehouseJournalLine."Qty. per Unit of Measure" := 1;
        end;
        OnInitWhseJnlLineOnAfterGetQuantity(ItemJournalLine, WarehouseJournalLine, Location);

        WarehouseJournalLine."Qty. (Base)" := QuantityBase;
        WarehouseJournalLine."Qty. (Absolute)" := Abs(WarehouseJournalLine.Quantity);
        WarehouseJournalLine."Qty. (Absolute, Base)" := Abs(QuantityBase);

        WarehouseJournalLine."Source Code" := ItemJournalLine."Source Code";
        WarehouseJournalLine."Reason Code" := ItemJournalLine."Reason Code";
        WarehouseJournalLine."Registering No. Series" := ItemJournalLine."Posting No. Series";
        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
            CalcCubageAndWeight(
              ItemJournalLine."Item No.", ItemJournalLine."Unit of Measure Code", WarehouseJournalLine."Qty. (Absolute)", WarehouseJournalLine.Cubage, WarehouseJournalLine.Weight);

        OnInitWhseJnlLineCopyFromItemJnlLine(WarehouseJournalLine, ItemJournalLine);
    end;

    procedure InitErrorLog()
    begin
        LogErrors := true;
        TempErrorLog.DeleteAll();
        NextLineNo := 1;
    end;

    local procedure HandleError(ErrorText: Text[250])
    var
        Position: Integer;
    begin
        if LogErrors then begin
            Position := StrPos(ErrorText, '\');
            if Position = 0 then
                InsertErrorLog(ErrorText)
            else begin
                repeat
                    InsertErrorLog(CopyStr(ErrorText, 1, Position - 1));
                    ErrorText := DelStr(ErrorText, 1, Position);
                    Position := StrPos(ErrorText, '\');
                until Position = 0;
                InsertErrorLog(ErrorText);
                InsertErrorLog('');
            end;
        end else
            Error(ErrorText);
    end;

    local procedure InsertErrorLog(ErrorText: Text[250])
    begin
        TempErrorLog."Line No." := NextLineNo;
        TempErrorLog.Text := ErrorText;
        TempErrorLog.Insert();
        NextLineNo := NextLineNo + 1;
    end;

    procedure GetWarehouseEmployeeLocationFilter(UserName: code[50]): Text
    var
        WarehouseEmployee: Record "Warehouse Employee";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Location2: Record Location;
        WhseEmplLocationBuffer: Codeunit WhseEmplLocationBuffer;
        AssignedLocations: List of [code[20]];
        Filterstring: Text;
        LocationAllowed: Boolean;
        FilterTooLong: Boolean;
        HasLocationSubscribers: Boolean;
    begin
        // buffered?
        Filterstring := WhseEmplLocationBuffer.GetWarehouseEmployeeLocationFilter();
        if Filterstring <> '' then
            exit(Filterstring);
        Filterstring := StrSubstNo('%1', ''''''); // All users can see the blank location
        if UserName = '' then
            exit(Filterstring);
        WarehouseEmployee.SetRange("User ID", UserName);
        WarehouseEmployee.SetFilter("Location Code", '<>%1', '');
        if WarehouseEmployee.Count > 1000 then  // if more, later filter length will exceed allowed length and it will use all values anyway
            exit(''); // can't filter to that many locations. Then remove filter
        if WarehouseEmployee.FindSet() then
            repeat
                AssignedLocations.Add(WarehouseEmployee."Location Code");
                LocationAllowed := true;
                OnBeforeLocationIsAllowed(WarehouseEmployee."Location Code", LocationAllowed);
                if LocationAllowed then
                    Filterstring += '|' + StrSubstNo('''%1''', ConvertStr(WarehouseEmployee."Location Code", '''', '*'));
            until WarehouseEmployee.Next() = 0;
        if WhseEmplLocationBuffer.NeedToCheckLocationSubscribers() then
            if Location2.FindSet() then
                repeat
                    if not AssignedLocations.Contains(Location2.Code) then begin
                        LocationAllowed := false;
                        OnBeforeLocationIsAllowed(Location2.Code, LocationAllowed);
                        if LocationAllowed then begin
                            Filterstring += '|' + StrSubstNo('''%1''', ConvertStr(Location2.Code, '''', '*'));
                            FilterTooLong := StrLen(Filterstring) > 2000; // platform limitation on length
                            HasLocationSubscribers := true;
                        end;
                    end;
                until (Location2.Next() = 0) or FilterTooLong;
        WhseEmplLocationBuffer.SetHasLocationSubscribers(HasLocationSubscribers);
        if FilterTooLong then
            Filterstring := '*';
        WhseEmplLocationBuffer.SetWarehouseEmployeeLocationFilter(Filterstring);
        exit(Filterstring);
    end;

    procedure GetAllowedLocation(LocationCode: Code[10]): Code[10]
    var
        WarehouseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAllowedLocation(LocationCode, IsHandled);
        if IsHandled then
            exit(LocationCode);

        CheckUserIsWhseEmployee();
        if WarehouseEmployee.Get(UserId, LocationCode) then
            exit(LocationCode);
        exit(GetDefaultLocation());
    end;

    procedure LocationIsAllowed(LocationCode: Code[10]): Boolean
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LocationAllowed: Boolean;
    begin
        LocationAllowed := WarehouseEmployee.Get(UserId(), LocationCode) or (UserId() = '');
        OnBeforeLocationIsAllowed(LocationCode, LocationAllowed);
        exit(LocationAllowed);
    end;

    procedure LocationIsAllowedToView(LocationCode: Code[10]): Boolean
    begin
        exit((LocationCode = '') or LocationIsAllowed(LocationCode))
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then
            Bin.Get(LocationCode, BinCode);
        Bin.TestField(Code);

        GetLocation(LocationCode);
        if Location."Directed Put-away and Pick" then
            Bin.TestField("Zone Code");
    end;

    local procedure GetItemUnitOfMeasure(ItemNo: Code[20]; UOMCode: Code[10])
    begin
        if (ItemUnitOfMeasure."Item No." <> ItemNo) or
           (ItemUnitOfMeasure.Code <> UOMCode)
        then
            if not ItemUnitOfMeasure.Get(ItemNo, UOMCode) then
                ItemUnitOfMeasure.Init();
    end;

    procedure GetBaseUOM(ItemNo: Code[20]): Code[10]
    begin
        GetItem(ItemNo);
        exit(Item."Base Unit of Measure");
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo = Item."No." then
            exit;

        Item.Get(ItemNo);
        OnGetItemOnAfterGetItem(Item);
        if Item."Item Tracking Code" <> '' then
            ItemTrackingCode.Get(Item."Item Tracking Code")
        else
            Clear(ItemTrackingCode);
    end;

    procedure ShowWhseRcptLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.Reset();
        WarehouseReceiptLine.SetRange("No.", WhseDocNo);
        WarehouseReceiptLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Whse. Receipt Lines", WarehouseReceiptLine);
    end;

    procedure ShowPostedWhseRcptLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.Reset();
        PostedWhseReceiptLine.SetRange("No.", WhseDocNo);
        PostedWhseReceiptLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Posted Whse. Receipt Lines", PostedWhseReceiptLine);
    end;

    procedure ShowWhseShptLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.Reset();
        WarehouseShipmentLine.SetRange("No.", WhseDocNo);
        WarehouseShipmentLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Whse. Shipment Lines", WarehouseShipmentLine);
    end;

    procedure ShowPostedWhseShptLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShipmentLine.Reset();
        PostedWhseShipmentLine.SetCurrentKey("Whse. Shipment No.", "Whse Shipment Line No.");
        PostedWhseShipmentLine.SetRange("Whse. Shipment No.", WhseDocNo);
        PostedWhseShipmentLine.SetRange("Whse Shipment Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Posted Whse. Shipment Lines", PostedWhseShipmentLine);
    end;

    procedure ShowWhseInternalPutawayLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        WhseInternalPutawayLine: Record "Whse. Internal Put-away Line";
    begin
        WhseInternalPutawayLine.Reset();
        WhseInternalPutawayLine.SetRange("No.", WhseDocNo);
        WhseInternalPutawayLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Whse. Internal Put-away Lines", WhseInternalPutawayLine);
    end;

    procedure ShowWhseInternalPickLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        WhseInternalPickLine.Reset();
        WhseInternalPickLine.SetRange("No.", WhseDocNo);
        WhseInternalPickLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Whse. Internal Pick Lines", WhseInternalPickLine);
    end;

    procedure ShowWhseActivityDocLine(WhseActivityDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    begin
        case WhseActivityDocType of
            WhseActivityDocType::Receipt:
                ShowPostedWhseRcptLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::Shipment:
                ShowWhseShptLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::"Internal Put-away":
                ShowWhseInternalPutawayLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::"Internal Pick":
                ShowWhseInternalPickLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::"Movement Worksheet":
                ;
            else
                OnShowWhseActivityDocLine(WhseActivityDocType, WhseDocNo, WhseDocLineNo);
        end;
    end;

    procedure ShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
        OnShowSourceDocLine(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo);
    end;

    procedure ShowSourceDocAttachedLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
        OnShowSourceDocAttachedLines(SourceType, SourceSubType, SourceNo, SourceLineNo);
    end;

    procedure ShowPostedSourceDocument(PostedSourceDoc: Enum "Warehouse Shipment Posted Source Document"; PostedSourceNo: Code[20])
    var
        DummyWarehouseActivitySourceDocument: Enum "Warehouse Activity Source Document";
    begin
        ShowPostedSourceDocument(PostedSourceDoc, PostedSourceNo, DummyWarehouseActivitySourceDocument);
    end;

    procedure ShowPostedSourceDocument(PostedSourceDoc: Enum "Warehouse Shipment Posted Source Document"; PostedSourceNo: Code[20]; WarehouseActivitySourceDocument: Enum "Warehouse Activity Source Document")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowPostedSourceDocument(PostedSourceDoc, PostedSourceNo, WarehouseActivitySourceDocument, IsHandled);
        if IsHandled then
            exit;

        OnShowPostedSourceDoc(PostedSourceDoc.AsInteger(), PostedSourceNo, WarehouseActivitySourceDocument);
    end;

    procedure ShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSourceDocCard(SourceType, SourceSubtype, SourceNo, IsHandled);
        if IsHandled then
            exit;

        OnShowSourceDocCard(SourceType, SourceSubType, SourceNo);
    end;

    procedure TransferWhseItemTracking(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        ItemTrackingMgt.GetWhseItemTrkgSetup(ItemJournalLine."Item No.", WhseItemTrackingSetup);

        IsHandled := false;
        OnBeforeTransferWhseItemTracking(WarehouseJournalLine, ItemJournalLine, WhseItemTrackingSetup, IsHandled);
        if IsHandled then
            exit;

        if not WhseItemTrackingSetup.TrackingRequired() then
            exit;

        if WhseItemTrackingSetup."Serial No. Required" then
            WarehouseJournalLine.TestField("Qty. per Unit of Measure", 1);

        WhseItemTrackingSetup.CopyTrackingFromItemJnlLine(ItemJournalLine);
        WarehouseJournalLine.CopyTrackingFromItemTrackingSetupIfRequired(WhseItemTrackingSetup);
        WarehouseJournalLine."Warranty Date" := ItemJournalLine."Warranty Date";
        WarehouseJournalLine."Expiration Date" := ItemJournalLine."Item Expiration Date";

        OnAfterTransferWhseItemTrkg(WarehouseJournalLine, ItemJournalLine);
    end;

    procedure SetTransferLine(TransferLine: Record "Transfer Line"; var WarehouseJournalLine: Record "Warehouse Journal Line"; PostingType: Option Shipment,Receipt; PostedDocNo: Code[20])
    begin
        WarehouseJournalLine.SetSource(Database::"Transfer Line", PostingType, TransferLine."Document No.", TransferLine."Line No.", 0);
        WarehouseJournalLine."Source Document" := WhseManagement.GetWhseJnlSourceDocument(WarehouseJournalLine."Source Type", WarehouseJournalLine."Source Subtype");
        if PostingType = PostingType::Shipment then
            WarehouseJournalLine."Reference Document" := WarehouseJournalLine."Reference Document"::"Posted T. Shipment"
        else
            WarehouseJournalLine."Reference Document" := WarehouseJournalLine."Reference Document"::"Posted T. Receipt";
        WarehouseJournalLine."Reference No." := PostedDocNo;
        WarehouseJournalLine."Entry Type" := PostingType;
    end;

    local procedure SetZoneAndBins(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line"; ToTransfer: Boolean)
    var
        IsDirectedPutAwayAndPick: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetZoneAndBins(ItemJournalLine, WarehouseJournalLine, ToTransfer, IsHandled);
        if IsHandled then
            exit;

        if ((ItemJournalLine."Entry Type" in
                 [ItemJournalLine."Entry Type"::Purchase, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine."Entry Type"::"Assembly Output"]) and
                (ItemJournalLine.Quantity > 0)) or
               ((ItemJournalLine."Entry Type" in
                 [ItemJournalLine."Entry Type"::Sale, ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemJournalLine."Entry Type"::"Assembly Consumption"]) and
                (ItemJournalLine.Quantity < 0)) or
               ToTransfer
        then begin
            if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::Movement
            else
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
            IsDirectedPutAwayAndPick := Location."Directed Put-away and Pick";
            OnSetZoneAndBinsOnAfterCalcIsDirectedPutAwayAndPick(ItemJournalLine, Location, IsDirectedPutAwayAndPick, true);
            if IsDirectedPutAwayAndPick then
                if CheckItemJournalLineBinCodeForDirectedPutAwayAndPickLocation(ItemJournalLine) then
                    WarehouseJournalLine."To Bin Code" := ItemJournalLine."Bin Code"
                else
                    WarehouseJournalLine."To Bin Code" := GetWhseJnlLineBinCode(ItemJournalLine."Source Code", ItemJournalLine."Bin Code", Location."Adjustment Bin Code")
            else
                if ToTransfer then
                    WarehouseJournalLine."To Bin Code" := ItemJournalLine."New Bin Code"
                else
                    WarehouseJournalLine."To Bin Code" := ItemJournalLine."Bin Code";
            GetBin(ItemJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
            WarehouseJournalLine."To Zone Code" := Bin."Zone Code";
        end else
            if ((ItemJournalLine."Entry Type" in
                 [ItemJournalLine."Entry Type"::Purchase, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine."Entry Type"::"Assembly Output"]) and
                (ItemJournalLine.Quantity < 0)) or
               ((ItemJournalLine."Entry Type" in
                 [ItemJournalLine."Entry Type"::Sale, ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemJournalLine."Entry Type"::"Assembly Consumption"]) and
                (ItemJournalLine.Quantity > 0)) or
               ((ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer) and (not ToTransfer))
            then begin
                if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then
                    WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::Movement
                else
                    WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
                IsDirectedPutAwayAndPick := Location."Directed Put-away and Pick";
                OnSetZoneAndBinsOnAfterCalcIsDirectedPutAwayAndPick(ItemJournalLine, Location, IsDirectedPutAwayAndPick, false);
                if IsDirectedPutAwayAndPick then
                    if CheckItemJournalLineBinCodeForDirectedPutAwayAndPickLocation(ItemJournalLine) then
                        WarehouseJournalLine."From Bin Code" := ItemJournalLine."Bin Code"
                    else
                        WarehouseJournalLine."From Bin Code" := GetWhseJnlLineBinCode(ItemJournalLine."Source Code", ItemJournalLine."Bin Code", Location."Adjustment Bin Code")
                else
                    WarehouseJournalLine."From Bin Code" := ItemJournalLine."Bin Code";
                if Location."Directed Put-away and Pick" then begin
                    GetBin(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
                    WarehouseJournalLine."From Zone Code" := Bin."Zone Code";
                    WarehouseJournalLine."From Bin Type Code" := Bin."Bin Type Code";
                end;
                if WarehouseJournalLine."From Zone Code" = '' then
                    WarehouseJournalLine."From Zone Code" := GetZoneCode(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
                if WarehouseJournalLine."From Bin Type Code" = '' then
                    WarehouseJournalLine."From Bin Type Code" := GetBinTypeCode(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
            end else
                if ItemJournalLine."Phys. Inventory" and (ItemJournalLine.Quantity = 0) and (ItemJournalLine."Invoiced Quantity" = 0) then begin
                    WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
                    if Location."Directed Put-away and Pick" then
                        WarehouseJournalLine."To Bin Code" := Location."Adjustment Bin Code"
                    else
                        WarehouseJournalLine."To Bin Code" := ItemJournalLine."Bin Code";
                    GetBin(ItemJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
                    WarehouseJournalLine."To Zone Code" := Bin."Zone Code";
                end;

        OnAfterSetZoneAndBins(WarehouseJournalLine, ItemJournalLine, Location, Bin);
    end;

    local procedure CheckItemJournalLineBinCodeForDirectedPutAwayAndPickLocation(ItemJournalLine: Record "Item Journal Line") Result: Boolean
    begin
        Result :=
            ((ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Negative Adjmt.") and (ItemJournalLine."Job No." <> '')) or
            (ItemJournalLine."Entry Type" in [ItemJournalLine."Entry Type"::"Assembly Output", ItemJournalLine."Entry Type"::"Assembly Consumption"]);

        OnAfterCheckItemJournalLineBinCodeForDirectedPutAwayAndPickLocation(ItemJournalLine, Result);
    end;

    procedure SerialNoOnInventory(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; SerialNo: Code[50]): Boolean
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        GetLocation(LocationCode);
        WarehouseEntry.SetCurrentKey("Serial No.", "Item No.", "Variant Code", "Location Code", "Bin Code");
        WarehouseEntry.SetRange("Serial No.", SerialNo);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Variant Code", VariantCode);
        if WarehouseEntry.IsEmpty() then
            exit(false);

        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetFilter("Bin Code", '<>%1', Location."Adjustment Bin Code");
        OnSerialNoOnInventoryOnBeforeCalcQtyBase(WarehouseEntry);
        WarehouseEntry.CalcSums("Qty. (Base)");
        exit(WarehouseEntry."Qty. (Base)" > 0);
    end;

    local procedure CheckSerialNo(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; SerialNo: Code[50]; QuantityBase: Decimal)
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNo(ItemNo, VariantCode, LocationCode, BinCode, UOMCode, SerialNo, QuantityBase, IsHandled);
        if IsHandled then
            exit;

        BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UOMCode);
        BinContent.SetRange("Serial No. Filter", SerialNo);
        BinContent.CalcFields("Quantity (Base)");
        if BinContent."Quantity (Base)" < Abs(QuantityBase) then
            BinContent.FieldError(
              "Quantity (Base)", StrSubstNo(Text000, Abs(QuantityBase) - 1));
    end;

    local procedure CheckLotNo(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; LotNo: Code[50]; QuantityBase: Decimal)
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLotNo(ItemNo, VariantCode, LocationCode, BinCode, UOMCode, LotNo, QuantityBase, IsHandled);
        if IsHandled then
            exit;

        BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UOMCode);
        BinContent.SetRange("Lot No. Filter", LotNo);
        BinContent.CalcFields("Quantity (Base)");
        if BinContent."Quantity (Base)" < Abs(QuantityBase) then
            BinContent.FieldError(
              "Quantity (Base)", StrSubstNo(Text000, BinContent."Quantity (Base)" - Abs(QuantityBase)));
    end;

    procedure BinLookUp(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]): Code[20]
    var
        Bin2: Record Bin;
    begin
        Bin2.SetRange("Location Code", LocationCode);
        Bin2.SetRange("Item Filter", ItemNo);
        Bin2.SetRange("Variant Filter", VariantCode);
        if ZoneCode <> '' then
            Bin2.SetRange("Zone Code", ZoneCode);

        OnBinLookUpOnAfterSetFilters(Bin2);
        if PAGE.RunModal(0, Bin2) = ACTION::LookupOK then
            exit(Bin2.Code);
    end;

    procedure BinContentLookUp(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; CurrBinCode: Code[20]): Code[20]
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        exit(BinContentLookUp(LocationCode, ItemNo, VariantCode, ZoneCode, DummyItemTrackingSetup, CurrBinCode));
    end;

    procedure BinContentLookUp(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; CurrBinCode: Code[20]) BinCode: Code[20]
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBinContentLookUp(LocationCode, ItemNo, VariantCode, ZoneCode, WhseItemTrackingSetup, CurrBinCode, BinCode, IsHandled);
        if IsHandled then
            exit(BinCode);

        GetItem(ItemNo);
        BinContent.SetCurrentKey("Location Code", "Item No.", "Variant Code");
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        WhseItemTrackingSetup.CopyTrackingFromItemTrackingCodeWarehouseTracking(ItemTrackingCode);
        BinContent.SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup);
        if ZoneCode <> '' then
            BinContent.SetRange("Zone Code", ZoneCode);
        BinContent.SetRange("Bin Code", CurrBinCode);
        if BinContent.FindFirst() then;
        BinContent.SetRange("Bin Code");

        if PAGE.RunModal(0, BinContent) = ACTION::LookupOK then
            exit(BinContent."Bin Code");
    end;

    procedure FindBin(LocationCode: Code[10]; BinCode: Code[20]; ZoneCode: Code[10])
    var
        Bin2: Record Bin;
    begin
        if ZoneCode <> '' then begin
            Bin2.SetCurrentKey("Location Code", "Zone Code", Code);
            Bin2.SetRange("Location Code", LocationCode);
            Bin2.SetRange("Zone Code", ZoneCode);
            Bin2.SetRange(Code, BinCode);
            Bin2.FindFirst();
        end else
            Bin2.Get(LocationCode, BinCode);
    end;

    procedure FindBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10])
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBinContent(LocationCode, BinCode, ItemNo, VariantCode, ZoneCode, IsHandled);
        if IsHandled then
            exit;

        BinContent.SetLoadFields("Location Code");
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        if ZoneCode <> '' then
            BinContent.SetRange("Zone Code", ZoneCode);
        BinContent.FindFirst();
    end;

    procedure CalcLineReservedQtyNotonInvt(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer): Decimal
    var
        ReservEntry: Record "Reservation Entry";
        ReservQtyNotonInvt: Decimal;
    begin
        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
        if SourceType = 5407 then begin // Database::"Prod. Order Component"
            ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceSubLineNo, true);
            ReservEntry.SetSourceFilter('', SourceLineNo);
        end else begin
            ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
            ReservEntry.SetSourceFilter('', 0);
        end;
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetFilter("Expected Receipt Date", '<>%1', 0D);
        ReservEntry.SetFilter("Shipment Date", '<>%1', 0D);
        if ReservEntry.Find('-') then
            repeat
                ReservQtyNotonInvt := ReservQtyNotonInvt + Abs(ReservEntry."Quantity (Base)");
            until ReservEntry.Next() = 0;
        exit(ReservQtyNotonInvt);
    end;

    procedure GetCaption(DestType: Option " ",Customer,Vendor,Location,Item,Family,"Sales Order"; SourceDoc: Option " ","Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order","Inbound Transfer","Outbound Transfer","Prod. Consumption","Prod. Output"; Selection: Integer): Text[50]
    begin
        exit(
            GetCaptionClass(
                "Warehouse Destination Type".FromInteger(DestType),
                Enum::"Warehouse Activity Source Document".FromInteger(SourceDoc), Selection));
    end;

    procedure GetCaptionClass(DestType: Enum "Warehouse Destination Type"; SourceDoc: Enum "Warehouse Activity Source Document";
                                            Selection: Integer) CaptionClass: Text[50]
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Customer: Record Customer;
        Location2: Record Location;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        case Selection of
            0:
                case DestType of
                    DestType::Vendor:
                        exit(Vendor.TableCaption() + ' ' + Vendor.FieldCaption("No."));
                    DestType::Customer:
                        exit(Customer.TableCaption() + ' ' + Customer.FieldCaption("No."));
                    DestType::Location:
                        exit(Location2.TableCaption() + ' ' + Location2.FieldCaption(Code));
                    DestType::Item:
                        exit(Item2.TableCaption() + ' ' + Item2.FieldCaption("No."));
                    DestType::"Sales Order":
                        exit(Text009 + ' ' + SalesHeader.FieldCaption("No."));
                    else begin
                        OnGetCaptionClass(DestType, Selection, CaptionClass);
                        if CaptionClass <> '' then
                            exit(CaptionClass)
                        else
                            exit(CopyStr(WarehouseActivityHeader.FieldCaption("Destination No."), 1, 50));
                    end;
                end;
            1:
                case DestType of
                    DestType::Vendor:
                        exit(Vendor.TableCaption() + ' ' + Vendor.FieldCaption(Name));
                    DestType::Customer:
                        exit(Customer.TableCaption() + ' ' + Customer.FieldCaption(Name));
                    DestType::Location:
                        exit(Location2.TableCaption() + ' ' + Location2.FieldCaption(Name));
                    DestType::Item:
                        exit(Item2.TableCaption() + ' ' + Item2.FieldCaption(Description));
                    DestType::"Sales Order":
                        exit(Text009 + ' ' + SalesHeader.FieldCaption("Sell-to Customer Name"));
                    else
                        exit(Text008);
                end;
            2:
                if SourceDoc in [
                                 SourceDoc::"Purchase Order",
                                 SourceDoc::"Purchase Return Order"]
                then
                    exit(CopyStr(PurchaseHeader.FieldCaption("Vendor Shipment No."), 1, 50))
                else
                    exit(CopyStr(WarehouseActivityHeader.FieldCaption("External Document No."), 1, 50));
            3:
                case SourceDoc of
                    SourceDoc::"Purchase Order":
                        exit(CopyStr(PurchaseHeader.FieldCaption("Vendor Invoice No."), 1, 50));
                    SourceDoc::"Purchase Return Order":
                        exit(CopyStr(PurchaseHeader.FieldCaption("Vendor Cr. Memo No."), 1, 50));
                    else
                        exit(CopyStr(WarehouseActivityHeader.FieldCaption("External Document No.2"), 1, 50));
                end;
        end;
    end;

    procedure GetDestinationEntityName(DestinationType: Enum "Warehouse Destination Type"; DestNo: Code[20]) DestinationEntityName: Text[100]
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Location2: Record Location;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDestinationEntityName(DestinationType, DestNo, DestinationEntityName, IsHandled);
        if IsHandled then
            exit(DestinationEntityName);

        case DestinationType of
            DestinationType::Customer:
                if Customer.Get(DestNo) then
                    exit(Customer.Name);
            DestinationType::Vendor:
                if Vendor.Get(DestNo) then
                    exit(Vendor.Name);
            DestinationType::Location:
                if Location2.Get(DestNo) then
                    exit(Location2.Name);
            DestinationType::Item:
                if Item2.Get(DestNo) then
                    exit(Item2.Description);
            DestinationType::"Sales Order":
                if SalesHeader.Get(SalesHeader."Document Type"::Order, DestNo) then
                    exit(SalesHeader."Sell-to Customer Name");
            else begin
                DestinationEntityName := '';
                OnGetDestinationEntityName(DestinationType, DestNo, DestinationEntityName);
                exit(DestinationEntityName);
            end;
        end;
    end;

    procedure GetATOSalesLine(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer; var SalesLine: Record "Sales Line"): Boolean
    begin
        if SourceType <> Database::"Sales Line" then
            exit(false);
        if SalesLine.Get(SourceSubtype, SourceID, SourceRefNo) then
            exit(SalesLine."Qty. to Asm. to Order (Base)" <> 0);
    end;

    procedure GetATOJobPlanningLine(SourceType: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceLineNo: Integer; var JobPlanningLine: Record "Job Planning Line"): Boolean
    begin
        if SourceType <> Database::Job then
            exit(false);
        JobPlanningLine.SetRange("Job No.", SourceID);
        JobPlanningLine.SetRange("Job Contract Entry No.", SourceRefNo);
        JobPlanningLine.SetRange("Line No.", SourceLineNo);
        if JobPlanningLine.FindFirst() then
            exit(JobPlanningLine."Qty. to Assemble (Base)" <> 0);
    end;

    local procedure SetFiltersOnATOInvtPick(SalesLine: Record "Sales Line"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.SetRange(WarehouseActivityLine."Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetSourceFilter(
            Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, false);
        WarehouseActivityLine.SetRange(WarehouseActivityLine."Assemble to Order", true);
        WarehouseActivityLine.SetTrackingFilterIfNotEmpty();
    end;

    local procedure SetFiltersOnATOInvtPick(JobPlanningLine: Record "Job Planning Line"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.SetRange(WarehouseActivityLine."Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetSourceFilter(
            Database::"Job", 0, JobPlanningLine."Document No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.", false);
        WarehouseActivityLine.SetRange(WarehouseActivityLine."Assemble to Order", true);
        WarehouseActivityLine.SetTrackingFilterIfNotEmpty();
    end;

    procedure ATOInvtPickExists(SalesLine: Record "Sales Line"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        SetFiltersOnATOInvtPick(SalesLine, WarehouseActivityLine);
        exit(not WarehouseActivityLine.IsEmpty);
    end;

    procedure CalcQtyBaseOnATOInvtPick(SalesLine: Record "Sales Line"; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyBase: Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.CopyTrackingFromItemTrackingSetup(WhseItemTrackingSetup);
        SetFiltersOnATOInvtPick(SalesLine, WarehouseActivityLine);
        if WarehouseActivityLine.FindSet() then
            repeat
                QtyBase += WarehouseActivityLine."Qty. Outstanding (Base)";
            until WarehouseActivityLine.Next() = 0;
    end;

    procedure CalcQtyBaseOnATOInvtPick(JobPlanningLine: Record "Job Planning Line"; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyBase: Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.CopyTrackingFromItemTrackingSetup(WhseItemTrackingSetup);
        SetFiltersOnATOInvtPick(JobPlanningLine, WarehouseActivityLine);
        if WarehouseActivityLine.FindSet() then
            repeat
                QtyBase += WarehouseActivityLine."Qty. Outstanding (Base)";
            until WarehouseActivityLine.Next() = 0;
    end;

    procedure CheckOutboundBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        CheckBlockedBin(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode, false);
    end;

    procedure CheckInboundBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        CheckBlockedBin(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode, true);
    end;

    local procedure SetFiltersOnATOWhseShpt(SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        WarehouseShipmentLine.SetSourceFilter(
            Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", false);
        WarehouseShipmentLine.SetRange(WarehouseShipmentLine."Assemble to Order", true);
    end;

    procedure ATOWhseShptExists(SalesLine: Record "Sales Line"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        SetFiltersOnATOWhseShpt(SalesLine, WarehouseShipmentLine);
        exit(not WarehouseShipmentLine.IsEmpty());
    end;

    local procedure CheckBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; CheckInbound: Boolean)
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlockedBin(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode, CheckInbound, IsHandled);
        if not IsHandled then begin
            GetLocation(LocationCode);
            if (Location."Directed Put-away and Pick") or ((BinCode <> '') and (Location."Bin Capacity Policy" = Location."Bin Capacity Policy"::"Never Check Capacity")) then
                if BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode) then begin
                    if (CheckInbound and
                        (BinContent."Block Movement" in [BinContent."Block Movement"::Inbound, BinContent."Block Movement"::All])) or
                       (not CheckInbound and
                        (BinContent."Block Movement" in [BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All]))
                    then
                        BinContent.FieldError("Block Movement");
                end else
                    if Location."Bin Mandatory" then begin
                        GetBin(LocationCode, BinCode);
                        if (CheckInbound and (Bin."Block Movement" in [Bin."Block Movement"::Inbound, Bin."Block Movement"::All])) or
                           (not CheckInbound and (Bin."Block Movement" in [Bin."Block Movement"::Outbound, Bin."Block Movement"::All]))
                        then
                            Bin.FieldError("Block Movement");
                    end;
        end;
        OnAfterCheckBlockedBin(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode, CheckInbound);
    end;

    local procedure GetWhseJnlLineBinCode(SourceCode: Code[10]; BinCode: Code[20]; AdjBinCode: Code[20]) Result: Code[20]
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        Result := AdjBinCode;
        SourceCodeSetup.Get();
        OnAfterGetWhseJnlLineBinCode(SourceCode, BinCode, AdjBinCode, SourceCodeSetup, Result);
    end;

    local procedure GetZoneCode(LocationCode: Code[10]; BinCode: Code[20]): Code[10]
    var
        Bin2: Record Bin;
    begin
        if Bin2.Get(LocationCode, BinCode) then
            exit(Bin2."Zone Code");
    end;

    local procedure GetBinTypeCode(LocationCode: Code[10]; BinCode: Code[20]): Code[10]
    var
        Bin2: Record Bin;
    begin
        if Bin2.Get(LocationCode, BinCode) then
            exit(Bin2."Bin Type Code");
    end;

    local procedure CheckBinAndBinContentMovement(WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        if WarehouseJournalLine.Quantity = 0 then
            exit;

        case WarehouseJournalLine."Entry Type" of
            WarehouseJournalLine."Entry Type"::"Positive Adjmt.":
                CheckBlockedBin(WarehouseJournalLine."Location Code", WarehouseJournalLine."To Bin Code", WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Unit of Measure Code", WarehouseJournalLine.Quantity > 0);
            WarehouseJournalLine."Entry Type"::"Negative Adjmt.":
                CheckBlockedBin(WarehouseJournalLine."Location Code", WarehouseJournalLine."To Bin Code", WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Unit of Measure Code", WarehouseJournalLine.Quantity < 0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; CheckInbound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal; ToTransfer: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingSpecificationChangeNeeded(TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; var CheckNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLine(var WhseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line"; ToTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWhseJnlLineBinCode(SourceCode: Code[10]; BinCode: Code[20]; AdjBinCode: Code[20]; SourceCodeSetup: Record "Source Code Setup"; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetZoneAndBins(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line"; Location: Record Location; Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferWhseItemTrkg(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinContentLookUp(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; CurrBinCode: Code[20]; var BinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalanceQtyToHandle(var WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; CheckInbound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDecreaseBinContent(var WhseJnlLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemJnlLineLocation(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemJnlLineFieldChange(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line"; CurrentFieldCaption: Text[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLotNo(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; LotNo: Code[50]; QuantityBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseDocumentFromZoneCode(WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseDocumentToZoneCode(WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckToZoneCode(WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingChange(TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPutAwayAvailability(BinCode: Code[20]; CheckFieldCaption: Text[100]; CheckTableCaption: Text[100]; ValueToPutAway: Decimal; ValueAvailable: Decimal; Prohibit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUserIsWhseEmployee(Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal; ToTransfer: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmExceededCapacity(var IsHandled: Boolean; BinCode: Code[20]; CheckFieldCaption: Text[100]; CheckTableCaption: Text[100]; ValueToPutAway: Decimal; ValueAvailable: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseJnlLine(var ItemJnlLine: Record "Item Journal Line"; ItemJnlTemplateType: Option; var WhseJnlLine: Record "Warehouse Journal Line"; ToTransfer: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAllowedLocation(var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var BinCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultDirectedPutawayAndPickLocation(var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultLocation(var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWrongPickPutAwayQtyErrorText(var WhseActivLine: Record "Warehouse Activity Line"; QtyToPick: Decimal; QtyToPutAway: Decimal; var ErrorTxt: Text[250]; var IsHandled: Boolean; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLocationIsAllowed(LocationCode: Code[10]; var LocationAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPostedSourceDocument(PostedSourceDoc: Enum "Warehouse Shipment Posted Source Document"; PostedSourceNo: Code[20]; WarehouseActivitySourceDocument: Enum "Warehouse Activity Source Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetZoneAndBins(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; ToTransfer: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBinLookUpOnAfterSetFilters(var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBalanceQtyToHandleOnAfterSetFilters(var ToWarehouseActivityLine: Record "Warehouse Activity Line"; FromWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseJnlLineOnAfterCheckTracking(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemTrackingCode: Record "Item Tracking Code"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseJnlLineOnAfterGetLocation(var WarehouseJournalLine: Record "Warehouse Journal Line"; var Location: Record Location; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseJnlLineOnAfterGetLocation(var ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseJnlLineTracking(var WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemOnAfterGetItem(var Item: Record "Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWhseJnlLineCopyFromItemJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowPostedSourceDoc(PostedSourceDoc: Option; PostedSourceNo: Code[20]; WarehouseActivitySourceDocument: Enum "Warehouse Activity Source Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocAttachedLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseJnlLineOnBeforeCheckBySourceJnl(var WhseJnlLine: Record "Warehouse Journal Line"; var Bin: Record Bin; SourceJnl: Option; var BinContent: Record "Bin Content"; Location: Record Location; DecreaseQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeTransferWhseItemTracking(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ItemJournalLine: Record "Item Journal Line"; var ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetZoneAndBinsOnAfterCalcIsDirectedPutAwayAndPick(ItemJnlLine: Record "Item Journal Line"; Location: Record Location; var IsDirectedPutAwayAndPick: Boolean; IsQtyIncrease: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWhseJnlLineOnAfterGetQuantity(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowWhseActivityDocLine(WhseActivityDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfBinIsEligible(ItemJournalLine: Record "Item Journal Line"; var BinIsEligible: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCubageAndWeight(ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; var Cubage: Decimal; var Weight: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDestinationEntityName(DestinationType: Enum "Warehouse Destination Type"; DestNo: Code[20]; var DestinationName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDestinationEntityName(DestinationType: Enum "Warehouse Destination Type"; DestinationNo: Code[20]; var DestinationName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSerialNoOnInventoryOnBeforeCalcQtyBase(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCaptionClass(DestinationType: Enum "Warehouse Destination Type"; Selection: Integer; var CaptionClass: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemJnlLineFieldChangeOnBeforeShowError(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckItemJnlLineFieldChangeOnAfterCheckBinCodeChange(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line"; CurrFieldCaption: Text[30]; var ShowError: Boolean; var BinIsEligible: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckItemJnlLineFieldChangeOnAfterAssignShowError(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line"; CurrFieldCaption: Text[30]; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemJournalLineBinCodeForDirectedPutAwayAndPickLocation(ItemJournalLine: Record "Item Journal Line"; var CheckResult: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNo(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; SerialNo: Code[50]; QuantityBase: Decimal; var IsHandled: Boolean)
    begin
    end;
}

