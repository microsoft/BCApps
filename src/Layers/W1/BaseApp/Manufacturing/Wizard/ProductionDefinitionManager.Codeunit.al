// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

codeunit 99001017 "Production Definition Manager"
{
    var
        TempData: Codeunit "Prod. Definition Temp Data";
        ProdDefVersionMgmt: Codeunit "Prod. Definition Version Mgmt.";
        ProdDefSourceInitializer: Codeunit "Prod. Def. Source Initializer";
        BomRtngSaveTarget: Enum "Prod. Definition Save Target";
        WizardMode: Enum "Prod. Definition Mode";
        ProdOrderNotificationIdTok: Label '{5A3C5A1F-3B2E-4C8D-9F0A-1B2C3D4E5F6A}', Locked = true;

    /// <summary>
    /// Opens the Production Definition Wizard for any source record type using the default Released production order status.
    /// </summary>
    /// <param name="Source">The source record (Item, Stockkeeping Unit, Sales Line, or any other supported type).</param>
    /// <param name="Mode">Determines the wizard behavior.</param>
    /// <returns>True if the wizard was completed and confirmed; false if the user cancelled.</returns>
    internal procedure RunForSource(Source: Variant; Mode: Enum "Prod. Definition Mode"): Boolean
    begin
        exit(RunForSource(Source, Mode, "Production Order Status"::Released));
    end;

    /// <summary>
    /// Opens the Production Definition Wizard for any source record type. The source is dispatched
    /// through Prod. Def. Source Initializer, which handles Item, Stockkeeping Unit, and Sales Line natively.
    /// For other source types such as Purchase Line, subscribe to OnInitializeFromSource on that codeunit.
    /// BOM and routing are resolved from the best matching SKU or item. Depending on the wizard mode,
    /// a production order may also be created directly from the resulting definition.
    /// </summary>
    /// <param name="Source">The source record (Item, Stockkeeping Unit, Sales Line, Purchase Line, or any other supported type).</param>
    /// <param name="Mode">Determines the wizard behavior.</param>
    /// <param name="ProdOrderStatus">The status to use when creating the production order. Defaults to Released.</param>
    /// <returns>True if the wizard was completed and confirmed; false if the user cancelled.</returns>

    internal procedure RunForSource(Source: Variant; Mode: Enum "Prod. Definition Mode"; ProdOrderStatus: Enum "Production Order Status"): Boolean
    var
        Item: Record Item;
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        SourceType: Enum "Prod. Definition Source";
        ScenarioType: Enum "Prod. Definition Scenario";
    begin
        WizardMode := Mode;
        TempData.SetProdOrderStatus(ProdOrderStatus);

        ProdDefSourceInitializer.InitializeFromSource(TempData, Source);
        ValidateSourceTypeForMode(TempData.GetGlobalSourceType(), Mode);

        ItemNo := TempData.GetGlobalItemNo();
        Item.SetLoadFields(Description, "Base Unit of Measure", "Production BOM No.", "Routing No.");
        Item.Get(ItemNo);

        GetLocationAndVariantFromTempData(LocationCode, VariantCode);
        GetBOMAndRoutingFromBestSource(ItemNo, VariantCode, LocationCode, BOMNo, RoutingNo, SourceType);

        TempData.SetRtngBOMSourceType(SourceType);
        ScenarioType := GetScenarioType(BOMNo, RoutingNo);
        PrepareBOMAndRoutingDataForScenario(BOMNo, RoutingNo, Item.Description, Item."Base Unit of Measure");

        if ExecuteWizardProcess(Item, ScenarioType) then begin
            PostWizardProcessing(ItemNo);
            exit(true);
        end;
        exit(false);
    end;

    local procedure ValidateSourceTypeForMode(SourceType: Enum "Prod. Definition Source"; Mode: Enum "Prod. Definition Mode")
    var
        CreateProdOrderNotSupportedErr: Label 'Creating a production order directly is not supported when the wizard is called from an Item or Stockkeeping Unit. Use the Sales Line source instead.';
    begin
        if Mode <> Mode::CreateProductionOrder then
            exit;
        if SourceType in ["Prod. Definition Source"::Item, "Prod. Definition Source"::StockkeepingUnit] then
            Error(CreateProdOrderNotSupportedErr);
    end;

    local procedure GetScenarioType(BOMNo: Code[20]; RoutingNo: Code[20]): Enum "Prod. Definition Scenario"
    var
        ScenarioType: Enum "Prod. Definition Scenario";
    begin
        if (BOMNo <> '') and (RoutingNo <> '') then
            exit(ScenarioType::BothAvailable);
        if (BOMNo <> '') or (RoutingNo <> '') then
            exit(ScenarioType::PartiallyAvailable);
        exit(ScenarioType::NothingAvailable);
    end;

    local procedure PrepareBOMAndRoutingDataForScenario(BOMNo: Code[20]; RoutingNo: Code[20]; ItemDescription: Text[100]; BaseUOMCode: Code[10])
    var
        BOMVersionCode: Code[20];
        RoutingVersionCode: Code[20];
    begin
        TempData.InitializeNewTemporaryBOMInformation(TempData.GetGlobalItemNo(), ItemDescription, BaseUOMCode);
        if BOMNo <> '' then begin
            BOMVersionCode := ProdDefVersionMgmt.GetDefaultBOMVersion(BOMNo);
            TempData.LoadBOMLines(BOMNo, BOMVersionCode);
        end;

        TempData.InitializeNewTemporaryRoutingInformation(TempData.GetGlobalItemNo(), ItemDescription);
        if RoutingNo <> '' then begin
            RoutingVersionCode := ProdDefVersionMgmt.GetDefaultRoutingVersion(RoutingNo);
            TempData.LoadRoutingLines(RoutingNo, RoutingVersionCode);
        end;
    end;

    local procedure ExecuteWizardProcess(Item: Record Item; ScenarioType: Enum "Prod. Definition Scenario"): Boolean
    var
        BOMRoutingDisplay: Enum "Prod. Definition Display";
        ProdCompDisplay: Enum "Prod. Definition Display";
    begin
        GetShowEditTypesForScenario(ScenarioType, BOMRoutingDisplay, ProdCompDisplay);

        if ShouldSkipUserInteraction(BOMRoutingDisplay, ProdCompDisplay) then begin
            TempData.BuildTemporaryStructureFromBOMRouting();
            exit(true);
        end;

        exit(ExecuteWizardPageWithTemporaryData(Item, BOMRoutingDisplay, ProdCompDisplay));
    end;

    local procedure GetShowEditTypesForScenario(ScenarioType: Enum "Prod. Definition Scenario"; var BOMRoutingDisplay: Enum "Prod. Definition Display"; var ProdCompDisplay: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin

        ManufacturingSetup.SetLoadFields("Show Rtng BOM Select Both", "Show Prod Comp Select Both", "Show Rtng BOM Select Partial", "Show Prod Comp Select Partial", "Show Rtng BOM Select Nothing", "Show Prod Comp Select Nothing");
        ManufacturingSetup.Get();
        case ScenarioType of
            ScenarioType::BothAvailable:
                begin
                    BOMRoutingDisplay := ManufacturingSetup."Show Rtng BOM Select Both";
                    ProdCompDisplay := ManufacturingSetup."Show Prod Comp Select Both";
                end;
            ScenarioType::PartiallyAvailable:
                begin
                    BOMRoutingDisplay := ManufacturingSetup."Show Rtng BOM Select Partial";
                    ProdCompDisplay := ManufacturingSetup."Show Prod Comp Select Partial";
                end;
            ScenarioType::NothingAvailable:
                begin
                    BOMRoutingDisplay := ManufacturingSetup."Show Rtng BOM Select Nothing";
                    ProdCompDisplay := ManufacturingSetup."Show Prod Comp Select Nothing";
                end;
        end;

        if WizardMode = WizardMode::DefineItemStructure then
            ProdCompDisplay := ProdCompDisplay::Hide;
    end;

    local procedure ShouldSkipUserInteraction(BOMRoutingDisplay: Enum "Prod. Definition Display"; ProdCompDisplay: Enum "Prod. Definition Display"): Boolean
    begin
        exit((BOMRoutingDisplay = BOMRoutingDisplay::Hide) and (ProdCompDisplay = ProdCompDisplay::Hide));
    end;

    local procedure ExecuteWizardPageWithTemporaryData(Item: Record Item; BOMRoutingDisplay: Enum "Prod. Definition Display"; ProdCompDisplay: Enum "Prod. Definition Display"): Boolean
    var
        ProductionDefinitionWizard: Page "Production Definition Wizard";
    begin
        ProductionDefinitionWizard.SetItem(Item);
        ProductionDefinitionWizard.SetBOMRoutingDisplay(BOMRoutingDisplay);
        ProductionDefinitionWizard.SetProdCompDisplay(ProdCompDisplay);
        ProductionDefinitionWizard.SetTempData(TempData);
        ProductionDefinitionWizard.SetWizardMode(WizardMode);
        ProductionDefinitionWizard.RunModal();

        if ProductionDefinitionWizard.GetFinished() then begin
            BomRtngSaveTarget := ProductionDefinitionWizard.GetBomRtngSaveTarget();
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Persists the temporary production BOM and routing data collected during the wizard run.
    /// If no existing BOM or routing is found for the item, new records are created using the
    /// configured number series and certified immediately. If a version code is present, a new
    /// BOM or routing version is created instead. After saving, the resolved BOM and routing
    /// numbers are written back to the source item or stockkeeping unit.
    /// </summary>
    /// <param name="ItemNo">The item number whose production BOM and routing records are to be created or versioned.</param>
    internal procedure ProcessBOMAndRoutingData(ItemNo: Code[20])
    var
        TempBOMHeader: Record "Production BOM Header" temporary;
        TempBOMLine: Record "Production BOM Line" temporary;
        TempRoutingHeader: Record "Routing Header" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
        BOMNo: Code[20];
        BOMVersionCode: Code[20];
        RoutingNo: Code[20];
        RoutingVersionCode: Code[20];
    begin
        TempData.GetGlobalBOMHeader(TempBOMHeader);
        TempData.GetGlobalBOMLines(TempBOMLine);
        TempData.GetGlobalRoutingHeader(TempRoutingHeader);
        TempData.GetGlobalRoutingLines(TempRoutingLine);

        if TempBOMLine.FindFirst() then begin
            BOMNo := TempBOMLine."Production BOM No.";
            BOMVersionCode := TempBOMLine."Version Code";
            if BOMVersionCode = '' then
                CreateBOMIfNotExists(TempBOMHeader, TempBOMLine, BOMNo)
            else
                SaveBOMVersionIfRequired(TempBOMHeader, TempBOMLine, BOMNo, BOMVersionCode);
        end;
        if TempRoutingLine.FindFirst() then begin
            RoutingNo := TempRoutingLine."Routing No.";
            RoutingVersionCode := TempRoutingLine."Version Code";
            if RoutingVersionCode = '' then
                CreateRoutingIfNotExists(TempRoutingHeader, TempRoutingLine, RoutingNo)
            else
                SaveRoutingVersionIfRequired(TempRoutingHeader, TempRoutingLine, RoutingNo, RoutingVersionCode);
        end;

        UpdateSourceWithBOMRoutingNumbers(ItemNo, BOMNo, RoutingNo);

        TempData.UpdateProdOrderRoutingInfo(RoutingNo, RoutingVersionCode);
        TempData.UpdateProdOrderBOMInfo(BOMNo, BOMVersionCode);
    end;

    local procedure CreateBOMIfNotExists(var TempBOMHeader: Record "Production BOM Header" temporary; var TempBOMLine: Record "Production BOM Line" temporary; var BOMNo: Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        BOMHeader: Record "Production BOM Header";
        BOMLine: Record "Production BOM Line";
        NoSeries: Codeunit "No. Series";
    begin
        if TempBOMLine.IsEmpty() then
            exit;
        if ProdDefVersionMgmt.CheckBOMExists(BOMNo, '') then
            exit;

        ManufacturingSetup.Get();
        BOMNo := NoSeries.GetNextNo(ManufacturingSetup."Production BOM Nos.");

        BOMHeader.Init();
        BOMHeader."No." := BOMNo;
        BOMHeader.Description := TempBOMHeader.Description;
        BOMHeader.Validate("Unit of Measure Code", TempBOMHeader."Unit of Measure Code");
        BOMHeader.Insert(true);

        if TempBOMLine.FindSet() then
            repeat
                BOMLine := TempBOMLine;
                BOMLine."Production BOM No." := BOMNo;
                BOMLine."Version Code" := '';
                BOMLine.Insert(true);
            until TempBOMLine.Next() = 0;

        BOMHeader.Validate(Status, "BOM Status"::Certified);
        BOMHeader.Modify(true);

        TempData.LoadBOMLines(BOMNo, '');
    end;

    local procedure CreateRoutingIfNotExists(var TempRoutingHeader: Record "Routing Header" temporary; var TempRoutingLine: Record "Routing Line" temporary; var RoutingNo: Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        NoSeries: Codeunit "No. Series";
    begin
        if TempRoutingLine.IsEmpty() then
            exit;
        if not TempRoutingHeader.FindFirst() then
            exit;

        if ProdDefVersionMgmt.CheckRoutingExists(RoutingNo, '') then
            exit;

        ManufacturingSetup.Get();
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.");

        RoutingHeader.Init();
        RoutingHeader."No." := RoutingNo;
        RoutingHeader.Description := TempRoutingHeader.Description;
        RoutingHeader.Insert(true);

        if TempRoutingLine.FindSet() then
            repeat
                RoutingLine := TempRoutingLine;
                RoutingLine."Routing No." := RoutingNo;
                RoutingLine."Version Code" := '';
                RoutingLine.Insert(true);
            until TempRoutingLine.Next() = 0;

        RoutingHeader.Validate(Status, "Routing Status"::Certified);
        RoutingHeader.Modify(true);

        TempData.LoadRoutingLines(RoutingNo, '');
    end;

    local procedure SaveBOMVersionIfRequired(var TempBOMHeader: Record "Production BOM Header" temporary; var TempBOMLine: Record "Production BOM Line" temporary; BOMNo: Code[20]; BOMVersionCode: Code[20])
    var
        BOMHeader: Record "Production BOM Header";
        BOMLine: Record "Production BOM Line";
        BOMVersion: Record "Production BOM Version";
        NoSeries: Codeunit "No. Series";
        NewBOMVersionCode: Code[20];
    begin
        if ProdDefVersionMgmt.CheckBOMExists(BOMNo, BOMVersionCode) then begin
            TempData.UpdateBOMVersionCode(BOMVersionCode);
            exit;
        end;

        NewBOMVersionCode := NoSeries.GetNextNo(ProdDefVersionMgmt.GetBOMVersionNoSeries(BOMNo));
        TempData.UpdateBOMVersionCode(NewBOMVersionCode);

        BOMHeader.SetLoadFields(Description, "Unit of Measure Code");
        BOMHeader.Get(BOMNo);

        BOMVersion.Init();
        BOMVersion."Production BOM No." := BOMNo;
        BOMVersion."Version Code" := NewBOMVersionCode;
        BOMVersion.Description := BOMHeader.Description;
        BOMVersion."Unit of Measure Code" := BOMHeader."Unit of Measure Code";
        BOMVersion."Starting Date" := WorkDate();
        BOMVersion.Insert(true);

        if TempBOMLine.FindSet() then
            repeat
                BOMLine := TempBOMLine;
                BOMLine."Production BOM No." := BOMNo;
                BOMLine."Version Code" := NewBOMVersionCode;
                BOMLine.Insert(true);
            until TempBOMLine.Next() = 0;

        BOMVersion.Validate(Status, "BOM Status"::Certified);
        BOMVersion.Modify(true);
    end;

    local procedure SaveRoutingVersionIfRequired(var TempRoutingHeader: Record "Routing Header" temporary; var TempRoutingLine: Record "Routing Line" temporary; RoutingNo: Code[20]; RoutingVersionCode: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        NoSeries: Codeunit "No. Series";
        NewRoutingVersionCode: Code[20];
    begin
        if ProdDefVersionMgmt.CheckRoutingExists(RoutingNo, RoutingVersionCode) then begin
            TempData.UpdateRoutingVersionCode(RoutingVersionCode);
            exit;
        end;

        NewRoutingVersionCode := NoSeries.GetNextNo(ProdDefVersionMgmt.GetRoutingVersionNoSeries(RoutingNo));
        TempData.UpdateRoutingVersionCode(NewRoutingVersionCode);


        RoutingHeader.SetLoadFields(Description, Type);
        RoutingHeader.Get(RoutingNo);

        RoutingVersion.Init();
        RoutingVersion."Routing No." := RoutingNo;
        RoutingVersion."Version Code" := NewRoutingVersionCode;
        RoutingVersion.Description := RoutingHeader.Description;
        RoutingVersion.Type := RoutingHeader.Type;
        RoutingVersion."Starting Date" := WorkDate();
        RoutingVersion.Insert(true);

        if TempRoutingLine.FindSet() then
            repeat
                RoutingLine := TempRoutingLine;
                RoutingLine."Routing No." := RoutingNo;
                RoutingLine."Version Code" := NewRoutingVersionCode;
                RoutingLine.Insert(true);
            until TempRoutingLine.Next() = 0;

        RoutingVersion.Validate(Status, "Routing Status"::Certified);
        RoutingVersion.Modify(true);
    end;

    local procedure UpdateSourceWithBOMRoutingNumbers(ItemNo: Code[20]; BOMNo: Code[20]; RoutingNo: Code[20])
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        case BomRtngSaveTarget of
            BomRtngSaveTarget::Item:
                if Item.Get(ItemNo) then
                    if (Item."Production BOM No." <> BOMNo) or (Item."Routing No." <> RoutingNo) then begin
                        Item.Validate("Production BOM No.", BOMNo);
                        Item.Validate("Routing No.", RoutingNo);
                        Item.Modify(true);
                    end;
            BomRtngSaveTarget::StockkeepingUnit:
                begin
                    GetLocationAndVariantFromTempData(LocationCode, VariantCode);
                    if StockkeepingUnit.Get(LocationCode, ItemNo, VariantCode) then begin
                        if (StockkeepingUnit."Production BOM No." <> BOMNo) or (StockkeepingUnit."Routing No." <> RoutingNo) then begin
                            StockkeepingUnit.Validate("Production BOM No.", BOMNo);
                            StockkeepingUnit.Validate("Routing No.", RoutingNo);
                            StockkeepingUnit.Modify(true);
                        end;
                    end else begin
                        StockkeepingUnit.Init();
                        StockkeepingUnit."Location Code" := LocationCode;
                        StockkeepingUnit."Item No." := ItemNo;
                        StockkeepingUnit."Variant Code" := VariantCode;
                        StockkeepingUnit.Validate("Production BOM No.", BOMNo);
                        StockkeepingUnit.Validate("Routing No.", RoutingNo);
                        StockkeepingUnit.Insert(true);
                    end;
                end;
        end;
    end;

    local procedure GetLocationAndVariantFromTempData(var LocationCode: Code[10]; var VariantCode: Code[10])
    var
        TempSKU: Record "Stockkeeping Unit" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        SourceType: Enum "Prod. Definition Source";
    begin
        SourceType := TempData.GetGlobalSourceType();
        case SourceType of
            SourceType::StockkeepingUnit:
                begin
                    TempData.GetGlobalSKU(TempSKU);
                    if TempSKU.FindFirst() then begin
                        LocationCode := TempSKU."Location Code";
                        VariantCode := TempSKU."Variant Code";
                    end;
                end;
            SourceType::SalesLine:
                begin
                    TempData.GetGlobalSalesLine(TempSalesLine);
                    if TempSalesLine.FindFirst() then begin
                        LocationCode := TempSalesLine."Location Code";
                        VariantCode := TempSalesLine."Variant Code";
                    end;
                end;
            SourceType::PurchaseLine:
                begin
                    TempData.GetGlobalPurchLine(TempPurchLine);
                    if TempPurchLine.FindFirst() then begin
                        LocationCode := TempPurchLine."Location Code";
                        VariantCode := TempPurchLine."Variant Code";
                    end;
                end;
        end;
    end;

    /// <summary>
    /// Returns the internal temporary data codeunit that holds the BOM, routing, and source
    /// document data collected during or after a wizard run. Use this to inspect or pass the
    /// wizard results to other codeunits without re-running the wizard.
    /// </summary>
    /// <param name="OutTempData">Receives the temporary data codeunit instance used by this manager.</param>
    internal procedure GetTempData(var OutTempData: Codeunit "Prod. Definition Temp Data")
    begin
        OutTempData := TempData;
    end;

    local procedure PostWizardProcessing(ItemNo: Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdOrderDirectCreator: Codeunit "Prod. Order Direct Creator";
        ProdOrder: Record "Production Order";
    begin
        ManufacturingSetup.SetLoadFields("Always Save Modified Versions");
        ManufacturingSetup.Get();

        if (BomRtngSaveTarget <> BomRtngSaveTarget::Empty) or ManufacturingSetup."Always Save Modified Versions" then
            ProcessBOMAndRoutingData(ItemNo);

        if WizardMode = WizardMode::CreateProductionOrder then begin
            ProdOrderDirectCreator.CreateProductionOrderFromTempData(TempData, ProdOrder);
            ProdOrderDirectCreator.RefreshProductionOrder(ProdOrder);
            CreateReservationFromSalesLine(ProdOrder);
            FlushReleasedProdOrderForSalesSource(ProdOrder);
            SendProdOrderCreatedNotification(ProdOrder);
        end;

        OnAfterPostWizardProcessing(TempData, ProdOrder);
    end;

    local procedure GetBOMAndRoutingFromBestSource(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var BOMNo: Code[20]; var RoutingNo: Code[20]; var SourceType: Enum "Prod. Definition Source")
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        Item: Record Item;
    begin
        Item.SetLoadFields("Production BOM No.", "Routing No.");
        Item.Get(ItemNo);

        BOMNo := Item."Production BOM No.";
        RoutingNo := Item."Routing No.";
        if (BOMNo <> '') or (RoutingNo <> '') then
            SourceType := SourceType::Item;

        if StockkeepingUnit.Get(LocationCode, ItemNo, VariantCode) then begin
            if StockkeepingUnit."Production BOM No." <> '' then
                BOMNo := StockkeepingUnit."Production BOM No.";
            if StockkeepingUnit."Routing No." <> '' then
                RoutingNo := StockkeepingUnit."Routing No.";
            if (StockkeepingUnit."Production BOM No." <> '') or (StockkeepingUnit."Routing No." <> '') then
                SourceType := SourceType::StockkeepingUnit;
        end;
    end;

    local procedure FlushReleasedProdOrderForSalesSource(ProdOrder: Record "Production Order")
    var
        TempSalesLine: Record "Sales Line" temporary;
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
    begin
        if ProdOrder.Status <> ProdOrder.Status::Released then
            exit;
        TempData.GetGlobalSalesLine(TempSalesLine);
        if not TempSalesLine.FindFirst() then
            exit;
        ProdOrderStatusMgt.FlushProdOrder(ProdOrder, ProdOrder.Status, WorkDate());
    end;

    local procedure CreateReservationFromSalesLine(ProdOrder: Record "Production Order")
    var
        TempSalesLine: Record "Sales Line" temporary;
        SalesLine: Record "Sales Line";
        ProdOrderLine: Record "Prod. Order Line";
        TrackingSpecification: Record "Tracking Specification";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ProdOrderRowID: Text[250];
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        TempData.GetGlobalSalesLine(TempSalesLine);
        if not TempSalesLine.FindFirst() then
            exit;

        if not SalesLine.Get(TempSalesLine."Document Type", TempSalesLine."Document No.", TempSalesLine."Line No.") then
            exit;

        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if not ProdOrderLine.FindFirst() then
            exit;

        ProdOrderRowID := ItemTrackingMgt.ComposeRowID(
            Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(),
            ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0);
        ItemTrackingMgt.CopyItemTracking(SalesLine.RowID1(), ProdOrderRowID, true, true);

        SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if ProdOrderLine."Remaining Qty. (Base)" > (SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)") then begin
            ReservQty := SalesLine."Outstanding Quantity" - SalesLine."Reserved Quantity";
            ReservQtyBase := SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)";
        end else begin
            ReservQty := Round(ProdOrderLine."Remaining Qty. (Base)" / SalesLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            ReservQtyBase := ProdOrderLine."Remaining Qty. (Base)";
        end;

        TrackingSpecification.InitTrackingSpecification(
            Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
            ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        SalesLineReserve.BindToTracking(
            SalesLine, TrackingSpecification, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);

        if SalesLine.Reserve = SalesLine.Reserve::Never then begin
            SalesLine.Reserve := SalesLine.Reserve::Optional;
            SalesLine.Modify();
        end;
        ProdOrderLine.Modify();
    end;

    local procedure SendProdOrderCreatedNotification(ProdOrder: Record "Production Order")
    var
        ProdOrderNotification: Notification;
        ProdOrderCreatedMsg: Label 'Production Order %1 has been created.', Comment = '%1 = Production Order No.';
        OpenProdOrderActionLbl: Label 'Open Production Order';
    begin
        ProdOrderNotification.Id(GetProdOrderCreatedNotificationId());
        ProdOrderNotification.Message(StrSubstNo(ProdOrderCreatedMsg, ProdOrder."No."));
        ProdOrderNotification.SetData('Status', Format(ProdOrder.Status.AsInteger()));
        ProdOrderNotification.SetData('No', ProdOrder."No.");
        ProdOrderNotification.AddAction(OpenProdOrderActionLbl, Codeunit::"Production Definition Manager", 'OpenCreatedProductionOrder');
        ProdOrderNotification.Send();
    end;

    local procedure GetProdOrderCreatedNotificationId(): Guid
    begin
        exit(ProdOrderNotificationIdTok);
    end;

    /// <summary>
    /// Opens the production order card page that corresponds to the status stored in the notification.
    /// This procedure is the action callback for the notification sent after a production order is created
    /// by the Production Definition Wizard.
    /// </summary>
    /// <param name="ProdOrderNotification">The notification that carries the production order status and number as data entries.</param>
    internal procedure OpenCreatedProductionOrder(ProdOrderNotification: Notification)
    var
        ProdOrder: Record "Production Order";
        PageManagement: Codeunit "Page Management";
        StatusInt: Integer;
        Status: Enum "Production Order Status";
        ProdOrderNo: Code[20];
    begin
        Evaluate(StatusInt, ProdOrderNotification.GetData('Status'));
        Status := Enum::"Production Order Status".FromInteger(StatusInt);
        ProdOrderNo := CopyStr(ProdOrderNotification.GetData('No'), 1, MaxStrLen(ProdOrder."No."));
        ProdOrder.Get(Status, ProdOrderNo);
        PageManagement.PageRun(ProdOrder)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWizardProcessing(TempData: Codeunit "Prod. Definition Temp Data"; var ProdOrder: Record "Production Order")
    begin
    end;


}