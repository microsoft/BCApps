// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Telemetry;
using System.Utilities;

report 7305 "Whse.-Source - Create Document"
{
    Caption = 'Whse.-Source - Create Document';
    Permissions = TableData "Whse. Item Tracking Line" = rm;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            dataitem("Posted Whse. Receipt Line"; "Posted Whse. Receipt Line")
            {
                DataItemTableView = sorting("No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    PostedWhseReceiptLine2: Record "Posted Whse. Receipt Line";
                    TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
                    WMSMgt: Codeunit "WMS Management";
                    ItemTrackingManagement: Codeunit "Item Tracking Management";
                    IsHandled: Boolean;
                begin
                    WMSMgt.CheckOutboundBlockedBin("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");

                    WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
                    if not WhseWkshLine.FindFirst() then begin
                        PostedWhseReceiptLine2 := "Posted Whse. Receipt Line";
                        PostedWhseReceiptLine2.TestField("Qty. per Unit of Measure");
                        PostedWhseReceiptLine2.CalcFields("Put-away Qty. (Base)");
                        PostedWhseReceiptLine2."Qty. (Base)" :=
                        PostedWhseReceiptLine2."Qty. (Base)" -
                        (PostedWhseReceiptLine2."Qty. Put Away (Base)" +
                        PostedWhseReceiptLine2."Put-away Qty. (Base)");
                        if PostedWhseReceiptLine2."Qty. (Base)" > 0 then begin
                            PostedWhseReceiptLine2.Quantity :=
                            Round(
                                PostedWhseReceiptLine2."Qty. (Base)" /
                                PostedWhseReceiptLine2."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                            IsHandled := false;
                            OnPostedWhseReceiptLineOnAfterGetRecordOnBeforeGetWhseItemTrkgSetup(WhseWkshLine, "Posted Whse. Receipt Line", IsHandled);
                            if not IsHandled then
                                if ItemTrackingManagement.GetWhseItemTrkgSetup("Item No.") then
                                    ItemTrackingManagement.InitItemTrackingForTempWhseWorksheetLine(
                                        Enum::"Warehouse Worksheet Document Type"::Receipt, PostedWhseReceiptLine2."No.", PostedWhseReceiptLine2."Line No.",
                                        PostedWhseReceiptLine2."Source Type", PostedWhseReceiptLine2."Source Subtype",
                                        PostedWhseReceiptLine2."Source No.", PostedWhseReceiptLine2."Source Line No.", 0);

                            CreatePutAway.SetCrossDockValues(PostedWhseReceiptLine2."Qty. Cross-Docked" <> 0);
                            CreatePutAwayFromDiffSource(PostedWhseReceiptLine2, Database::"Posted Whse. Receipt Line");
                            CreatePutAway.GetQtyHandledBase(TempWhseItemTrkgLine);
                            UpdateWhseItemTrkgLines(PostedWhseReceiptLine2, Database::"Posted Whse. Receipt Line", TempWhseItemTrkgLine);

                            if CreateErrorText = '' then
                                CreatePutAway.GetMessageText(CreateErrorText);
                            if EverythingHandled then
                                EverythingHandled := CreatePutAway.EverythingIsHandled();
                        end;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    OnAfterPostedWhseReceiptLineOnPostDataItem("Posted Whse. Receipt Line");
                end;

                trigger OnPreDataItem()
                begin
                    if WhseDoc <> WhseDoc::"Posted Receipt" then
                        CurrReport.Break();

                    CreatePutAway.SetValues(AssignedID, SortActivity, DoNotFillQtytoHandleReq, BreakbulkFilter);
                    CopyFilters(PostedWhseReceiptLine);

                    WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                    WhseWkshLine.SetRange(
                    "Whse. Document Type", WhseWkshLine."Whse. Document Type"::Receipt);
                    WhseWkshLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
                end;
            }
            dataitem("Whse. Mov.-Worksheet Line"; "Whse. Worksheet Line")
            {
                DataItemTableView = sorting("Worksheet Template Name", Name, "Location Code", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if FEFOLocation("Location Code") and ItemTracking("Item No.") then
                        CreatePick.SetCalledFromWksh(true)
                    else
                        CreatePick.SetCalledFromWksh(false);

                    TestField("Qty. per Unit of Measure");
                    if WhseWkshLine.CheckAvailQtytoMove() < 0 then
                        Error(
                        Text004,
                        TableCaption, FieldCaption("Worksheet Template Name"), "Worksheet Template Name",
                        FieldCaption(Name), Name, FieldCaption("Location Code"), "Location Code",
                        FieldCaption("Line No."), "Line No.");

                    CheckBin("Location Code", "From Bin Code", false);
                    CheckBin("Location Code", "To Bin Code", true);
                    CheckAvailabilityWithTracking("Whse. Mov.-Worksheet Line");
                    UpdateWkshMovementLineBuffer("Whse. Mov.-Worksheet Line");
                end;

                trigger OnPostDataItem()
                var
                    PickQty: Decimal;
                    PickQtyBase: Decimal;
                    QtyHandled: Decimal;
                    QtyHandledBase: Decimal;
                begin
                    if TempWhseWorksheetLineMovement.IsEmpty() then
                        CurrReport.Skip();

                    TempWhseWorksheetLineMovement.FindSet();
                    repeat
                        CreateMovementLines(TempWhseWorksheetLineMovement, PickQty, PickQtyBase);
                        QtyHandled := TempWhseWorksheetLineMovement."Qty. to Handle" - PickQty;
                        QtyHandledBase := TempWhseWorksheetLineMovement."Qty. to Handle (Base)" - PickQtyBase;
                        UpdateMovementWorksheet(TempWhseWorksheetLineMovement, QtyHandled, QtyHandledBase);
                    until TempWhseWorksheetLineMovement.Next() = 0;
                end;

                trigger OnPreDataItem()
                begin
                    if WhseDoc <> WhseDoc::"Whse. Mov.-Worksheet" then
                        CurrReport.Break();

                    Clear(CreatePickParameters);
                    CreatePickParameters."Assigned ID" := AssignedID;
                    CreatePickParameters."Sorting Method" := SortActivity;
                    CreatePickParameters."Max No. of Lines" := 0;
                    CreatePickParameters."Max No. of Source Doc." := 0;
                    CreatePickParameters."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandleReq;
                    CreatePickParameters."Breakbulk Filter" := BreakbulkFilter;
                    CreatePickParameters."Per Bin" := false;
                    CreatePickParameters."Per Zone" := false;
                    CreatePickParameters."Whse. Document" := CreatePickParameters."Whse. Document"::"Movement Worksheet";
                    CreatePickParameters."Whse. Document Type" := CreatePickParameters."Whse. Document Type"::Movement;
                    CreatePick.SetParameters(CreatePickParameters);

                    CreatePick.SetCalledFromMoveWksh(true);

                    CopyFilters(WhseWkshLine);
                    SetFilter("Qty. to Handle (Base)", '>0');
                    LockTable();

                    TempWhseWorksheetLineMovement.Reset();
                    TempWhseWorksheetLineMovement.DeleteAll();

                    OnBeforeProcessWhseMovWkshLines("Whse. Mov.-Worksheet Line");
                end;
            }
            dataitem("Whse. Put-away Worksheet Line"; "Whse. Worksheet Line")
            {
                DataItemTableView = sorting("Worksheet Template Name", Name, "Location Code", "Line No.") where("Whse. Document Type" = filter(Receipt | "Internal Put-away"));

                trigger OnAfterGetRecord()
                var
                    PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
                    TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
                    QtyHandledBase: Decimal;
                    SourceType: Integer;
                begin
                    LockTable();

                    CheckBin("Location Code", "From Bin Code", false);
                    if "Whse. Document Type" <> "Whse. Document Type"::Production then begin
                        InitPostedWhseReceiptLineFromPutAway(PostedWhseRcptLine, "Whse. Put-away Worksheet Line", SourceType);
                        CreatePutAway.SetCrossDockValues(PostedWhseRcptLine."Qty. Cross-Docked" <> 0);
                        CreatePutAwayFromDiffSource(PostedWhseRcptLine, SourceType);
                        if "Qty. to Handle" <> "Qty. Outstanding" then
                            EverythingHandled := false;
                        if EverythingHandled then
                            EverythingHandled := CreatePutAway.EverythingIsHandled();
                        QtyHandledBase := CreatePutAway.GetQtyHandledBase(TempWhseItemTrkgLine)
                    end else
                        OnCreatePutawayFromProduction("Whse. Put-away Worksheet Line", SourceType, EverythingHandled, QtyHandledBase);

                    if QtyHandledBase > 0 then begin
                        // update/delete line
                        WhseWkshLine := "Whse. Put-away Worksheet Line";
                        WhseWkshLine.Validate("Qty. Handled (Base)", "Qty. Handled (Base)" + QtyHandledBase);
                        if (WhseWkshLine."Qty. Outstanding" = 0) and
                        (WhseWkshLine."Qty. Outstanding (Base)" = 0)
                        then
                            WhseWkshLine.Delete()
                        else
                            WhseWkshLine.Modify();
                        UpdateWhseItemTrkgLines(PostedWhseRcptLine, SourceType, TempWhseItemTrkgLine);
                    end else
                        if CreateErrorText = '' then
                            if "Whse. Document Type" <> "Whse. Document Type"::Production then
                                CreatePutAway.GetMessageText(CreateErrorText)
                            else
                                OnGetProductionMessageText(CreateErrorText);
                end;

                trigger OnPreDataItem()
                begin
                    OnBeforeWhsePutAwayWorksheetLineOnPreDataItem("Whse. Put-away Worksheet Line");
                    if WhseDoc <> WhseDoc::"Put-away Worksheet" then
                        CurrReport.Break();

                    CreatePutAway.SetValues(AssignedID, SortActivity, DoNotFillQtytoHandleReq, BreakbulkFilter);
                    OnAfterCreatePutawaySetValues(AssignedID, SortActivity, DoNotFillQtytoHandleReq, BreakbulkFilter);

                    CopyFilters(WhseWkshLine);
                    SetFilter("Qty. to Handle (Base)", '>0');
                end;

                trigger OnPostDataItem()
                begin
                    OnAfterWhsePutAwayWorksheetLineOnPostDataItem("Whse. Put-away Worksheet Line")
                end;
            }
            dataitem("Whse. Internal Pick Line"; "Whse. Internal Pick Line")
            {
                DataItemTableView = sorting("No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    WMSMgt: Codeunit "WMS Management";
                    QtyToPick: Decimal;
                    QtyToPickBase: Decimal;
                begin
                    WMSMgt.CheckInboundBlockedBin("Location Code", "To Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");

                    CheckBin(false);
                    WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
                    if not WhseWkshLine.FindFirst() then begin
                        TestField("Qty. per Unit of Measure");
                        CalcFields("Pick Qty. (Base)");
                        QtyToPickBase := "Qty. (Base)" - ("Qty. Picked (Base)" + "Pick Qty. (Base)");
                        QtyToPick :=
                        Round(
                            ("Qty. (Base)" - ("Qty. Picked (Base)" + "Pick Qty. (Base)")) /
                            "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                        if QtyToPick > 0 then begin
                            CreatePick.SetWhseInternalPickLine("Whse. Internal Pick Line", 1);
                            CreatePick.SetTempWhseItemTrkgLine(
                            "No.", Database::"Whse. Internal Pick Line", '', 0, "Line No.", "Location Code");
                            CreatePick.CreateTempLine(
                            "Location Code", "Item No.", "Variant Code", "Unit of Measure Code",
                            '', "To Bin Code", "Qty. per Unit of Measure", QtyToPick, QtyToPickBase);
                        end;
                    end else
                        WhseWkshLineFound := true;
                end;

                trigger OnPreDataItem()
                begin
                    if WhseDoc <> WhseDoc::"Internal Pick" then
                        CurrReport.Break();

                    Clear(CreatePickParameters);
                    CreatePickParameters."Assigned ID" := AssignedID;
                    CreatePickParameters."Sorting Method" := SortActivity;
                    CreatePickParameters."Max No. of Lines" := 0;
                    CreatePickParameters."Max No. of Source Doc." := 0;
                    CreatePickParameters."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandleReq;
                    CreatePickParameters."Breakbulk Filter" := BreakbulkFilter;
                    CreatePickParameters."Per Bin" := false;
                    CreatePickParameters."Per Zone" := false;
                    CreatePickParameters."Whse. Document" := CreatePickParameters."Whse. Document"::"Internal Pick";
                    CreatePickParameters."Whse. Document Type" := CreatePickParameters."Whse. Document Type"::Pick;
                    CreatePick.SetParameters(CreatePickParameters);

                    CopyFilters(WhseInternalPickLine);
                    SetFilter("Qty. (Base)", '>0');

                    WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                    WhseWkshLine.SetRange(
                    "Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Pick");
                    WhseWkshLine.SetRange("Whse. Document No.", WhseInternalPickLine."No.");
                end;
            }
            dataitem("Whse. Internal Put-away Line"; "Whse. Internal Put-away Line")
            {
                DataItemTableView = sorting("No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
                    WMSMgt: Codeunit "WMS Management";
                    QtyToPutAway: Decimal;
                begin
                    WMSMgt.CheckOutboundBlockedBin("Location Code", "From Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
                    CheckCurrentLineQty();
                    WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
                    if not WhseWkshLine.FindFirst() then begin
                        TestField("Qty. per Unit of Measure");
                        CalcFields("Put-away Qty. (Base)");
                        QtyToPutAway :=
                        Round(
                            ("Qty. (Base)" - ("Qty. Put Away (Base)" + "Put-away Qty. (Base)")) /
                            "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                        if QtyToPutAway > 0 then begin
                            InitPostedWhseReceiptLineFromInternalPutAway(PostedWhseReceiptLine, "Whse. Internal Put-away Line", QtyToPutAway);

                            CreatePutAwayFromDiffSource(PostedWhseReceiptLine, Database::"Whse. Internal Put-away Line");
                            CreatePutAway.GetQtyHandledBase(TempWhseItemTrkgLine);

                            UpdateWhseItemTrkgLines(PostedWhseReceiptLine, Database::"Whse. Internal Put-away Line", TempWhseItemTrkgLine);
                        end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if WhseDoc <> WhseDoc::"Internal Put-away" then
                        CurrReport.Break();

                    CreatePutAway.SetValues(AssignedID, SortActivity, DoNotFillQtytoHandleReq, BreakbulkFilter);

                    SetRange("No.", WhseInternalPutAwayHeader."No.");
                    SetFilter("Qty. (Base)", '>0');

                    WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                    WhseWkshLine.SetRange(
                    "Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Put-away");
                    WhseWkshLine.SetRange("Whse. Document No.", WhseInternalPutAwayHeader."No.");

                    OnBeforeProcessWhseMovWkshLines("Whse. Put-away Worksheet Line");
                end;
            }
            dataitem("Assembly Line"; "Assembly Line")
            {
                DataItemTableView = sorting("Document Type", "Document No.", Type, "Location Code") where(Type = const(Item));

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    Location: Record Location;
                    WMSMgt: Codeunit "WMS Management";
                begin
                    if "Assembly Line"."Location Code" <> '' then begin
                        Location.Get("Assembly Line"."Location Code");
                        if not (Location."Asm. Consump. Whse. Handling" in [Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)"]) then
                            CurrReport.Skip();
                    end;

                    FeatureTelemetry.LogUsage('0000KT0', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);

                    Item.Get("No.");
                    if Item.IsNonInventoriableType() then
                        CurrReport.Skip();

                    if not CheckIfAssemblyLineMeetsReservedFromStockSetting("Remaining Quantity (Base)", ReservedFromStock) then
                        CurrReport.Skip();

                    WMSMgt.CheckInboundBlockedBin("Location Code", "Bin Code", "No.", "Variant Code", "Unit of Measure Code");

                    WhseWkshLine.SetRange("Source Line No.", "Line No.");
                    if not WhseWkshLine.FindFirst() then
                        CreatePick.CreateAssemblyPickLine("Assembly Line")
                    else begin
                        WhseWkshLineFound := true;
                        CreatePick.InsertSkippedLinesToCalculationSummary(Database::"Assembly Line", "Document No.", "Line No.", "Document Type".AsInteger(), 0, "Location Code", "No.", "Variant Code", "Unit of Measure Code", "Bin Code", Quantity, "Quantity (Base)", WhseWkshLine.SystemId);
                    end;
                end;

                trigger OnPreDataItem()
                var
                    IsHandled: Boolean;
                begin
                    if WhseDoc <> WhseDoc::Assembly then
                        CurrReport.Break();

                    IsHandled := false;
                    OnBeforeOnPreDataItemAssemblyLine(AssemblyHeader, HideValidationDialog, IsHandled);
                    if IsHandled then
                        CurrReport.Break();

                    WhseSetup.Get();

                    Clear(CreatePickParameters);
                    CreatePickParameters."Assigned ID" := AssignedID;
                    CreatePickParameters."Sorting Method" := SortActivity;
                    CreatePickParameters."Max No. of Lines" := 0;
                    CreatePickParameters."Max No. of Source Doc." := 0;
                    CreatePickParameters."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandleReq;
                    CreatePickParameters."Breakbulk Filter" := BreakbulkFilter;
                    CreatePickParameters."Per Bin" := false;
                    CreatePickParameters."Per Zone" := false;
                    CreatePickParameters."Whse. Document" := CreatePickParameters."Whse. Document"::Assembly;
                    CreatePickParameters."Whse. Document Type" := CreatePickParameters."Whse. Document Type"::Pick;
                    CreatePick.SetParameters(CreatePickParameters);
                    CreatePick.SetSaveSummary(ShowSummary);

                    SetRange("Document No.", AssemblyHeader."No.");
                    SetRange("Document Type", AssemblyHeader."Document Type");
                    SetRange(Type, Type::Item);
                    SetFilter("Remaining Quantity (Base)", '>0');

                    WhseWkshLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                    WhseWkshLine.SetRange("Source Type", Database::"Assembly Line");
                    WhseWkshLine.SetRange("Source Subtype", AssemblyHeader."Document Type");
                    WhseWkshLine.SetRange("Source No.", AssemblyHeader."No.");
                end;
            }
            dataitem("Job Planning Line"; "Job Planning Line")
            {
                DataItemTableView = sorting("Job No.", "Job Contract Entry No.") where("Line Type" = filter("Budget" | "Both Budget and Billable"), Type = const(Item));

                dataitem("Assembly Header"; "Assembly Header")
                {
                    DataItemTableView = sorting("Document Type", "No.");
                    dataitem(AssembleToOrderJobPlanningLine; "Assembly Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                        trigger OnAfterGetRecord()
                        var
                            WMSMgt: Codeunit "WMS Management";
                        begin
                            if not AssembleToOrderJobPlanningLine.IsInventoriableItem() then
                                CurrReport.Skip();

                            if not CheckIfAssemblyLineMeetsReservedFromStockSetting("Remaining Quantity (Base)", ReservedFromStock) then
                                CurrReport.Skip();

                            WMSMgt.CheckInboundBlockedBin("Location Code", "Bin Code", "No.", "Variant Code", "Unit of Measure Code");
                            CreatePick.CreateAssemblyPickLine(AssembleToOrderJobPlanningLine);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Type, Type::Item);
                            SetFilter("Remaining Quantity (Base)", '>0');
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        if not "Job Planning Line".AsmToOrderExists("Assembly Header") then
                            CurrReport.Break();

                        SetRange("Document Type", "Document Type");
                        SetRange("No.", "No.");
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    Location: Record Location;
                    WMSMgt: Codeunit "WMS Management";
                    QtyToPick: Decimal;
                    QtyToPickBase: Decimal;
                begin
                    if "Job Planning Line"."Location Code" <> '' then begin
                        Location.Get("Job Planning Line"."Location Code");
                        if not (Location."Job Consump. Whse. Handling" in [Location."Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)"]) then
                            CurrReport.Skip();
                    end;

                    FeatureTelemetry.LogUsage('0000KT1', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);

                    Item.Get("No.");
                    if Item.IsNonInventoriableType() then
                        CurrReport.Skip();

                    if not CheckIfJobPlngLineMeetsReservedFromStockSetting("Remaining Qty. (Base)", ReservedFromStock) then
                        CurrReport.Skip();

                    WMSMgt.CheckInboundBlockedBin("Location Code", "Bin Code", "No.", "Variant Code", "Unit of Measure Code");

                    WhseWkshLine.SetRange("Source Line No.", "Job Contract Entry No.");
                    WhseWkshLine.SetRange("Source Subline No.", "Line No.");
                    if WhseWkshLine.IsEmpty() then begin
                        TestField("Qty. per Unit of Measure");
                        CalcFields("Pick Qty.");

                        QtyToPick := Quantity - "Qty. Picked" - "Pick Qty.";
                        QtyToPickBase := UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", QtyToPick, "Qty. per Unit of Measure");

                        if QtyToPick > 0 then begin
                            CreatePick.SetJobPlanningLine("Job Planning Line");
                            if not "Assemble to Order" then begin
                                CreatePick.SetTempWhseItemTrkgLine("Job Planning Line"."Job No.", Database::"Job Planning Line", '', 0, "Job Contract Entry No.", "Location Code");
                                CreatePick.CreateTempLine("Location Code", "No.", "Variant Code", "Unit of Measure Code", '', "Bin Code", "Qty. per Unit of Measure", "Qty. Rounding Precision", "Qty. Rounding Precision (Base)", QtyToPick, QtyToPickBase);
                            end;
                        end;
                    end else
                        WhseWkshLineFound := true;
                end;

                trigger OnPreDataItem()
                begin
                    if WhseDoc <> WhseDoc::Job then
                        CurrReport.Break();

                    WhseSetup.Get();

                    Clear(CreatePickParameters);
                    CreatePickParameters."Assigned ID" := AssignedID;
                    CreatePickParameters."Sorting Method" := SortActivity;
                    CreatePickParameters."Max No. of Lines" := 0;
                    CreatePickParameters."Max No. of Source Doc." := 0;
                    CreatePickParameters."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandleReq;
                    CreatePickParameters."Breakbulk Filter" := BreakbulkFilter;
                    CreatePickParameters."Per Bin" := false;
                    CreatePickParameters."Per Zone" := false;
                    CreatePickParameters."Whse. Document" := CreatePickParameters."Whse. Document"::Job;
                    CreatePickParameters."Whse. Document Type" := CreatePickParameters."Whse. Document Type"::Pick;
                    CreatePick.SetParameters(CreatePickParameters);
                    CreatePick.SetSaveSummary(ShowSummary);

                    SetRange("Job No.", JobHeader."No.");
                    SetFilter(Quantity, '>0');

                    OnPreDataItemJobPlanningLineOnAfterSetFilters("Job Planning Line", JobHeader);

                    WhseWkshLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                    WhseWkshLine.SetRange("Source Type", Database::Job);
                    WhseWkshLine.SetRange("Source Subtype", 0);
                    WhseWkshLine.SetRange("Source No.", JobHeader."No.");
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AssignedID; AssignedID)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Assigned User ID';
                        TableRelation = "Warehouse Employee";
                        ToolTip = 'Specifies the ID of the assigned user to perform the pick instruction.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            WhseEmployee: Record "Warehouse Employee";
                            LookupWhseEmployee: Page "Warehouse Employee List";
                        begin
                            WhseEmployee.SetCurrentKey("Location Code");
                            WhseEmployee.SetRange("Location Code", GetHeaderLocationCode());
                            LookupWhseEmployee.LookupMode(true);
                            LookupWhseEmployee.SetTableView(WhseEmployee);
                            if LookupWhseEmployee.RunModal() = ACTION::LookupOK then begin
                                LookupWhseEmployee.GetRecord(WhseEmployee);
                                AssignedID := WhseEmployee."User ID";
                            end;
                        end;

                        trigger OnValidate()
                        var
                            WhseEmployee: Record "Warehouse Employee";
                        begin
                            if AssignedID <> '' then
                                WhseEmployee.Get(AssignedID, GetHeaderLocationCode());
                        end;
                    }
                    field(SortingMethodForActivityLines; SortActivity)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Sorting Method for Activity Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies the method by which the lines in the instruction will be sorted. The options are by item, document, shelf or bin (when the location uses bins, this is the bin code), due date, bin ranking, or action type.';
                    }
                    field("Reserved From Stock"; ReservedFromStock)
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Reserved from stock';
                        ToolTip = 'Specifies if you want to include only source document lines that are fully or partially reserved from current stock.';
                        ValuesAllowed = " ", "Full and Partial", Full;
                    }
                    field(BreakbulkFilter; BreakbulkFilter)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Set Breakbulk Filter';
                        ToolTip = 'Specifies if you want the program to hide intermediate break-bulk lines when an entire larger unit of measure is converted to a smaller unit of measure and picked completely.';
                    }
                    field(DoNotFillQtytoHandle; DoNotFillQtytoHandleReq)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Do Not Fill Qty. to Handle';
                        ToolTip = 'Specifies if you want to manually fill in the Quantity to Handle field on each line.';
                    }
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Print Document';
                        ToolTip = 'Specifies if you want the instructions to be printed. Otherwise, you can print it later from the warehouse instruction window.';
                    }
                    field(ShowSummaryField; ShowSummary)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Show Summary (Directed Put-away and Pick)';
                        ToolTip = 'Specifies if you want the summary window to be shown after creating pick lines.';
                        Visible = (WhseDoc = WhseDoc::Assembly) or (WhseDoc = WhseDoc::Production) or (WhseDoc = WhseDoc::Job);
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            Location: Record Location;
        begin
            GetLocation(Location, GetHeaderLocationCode());
            if Location."Use ADCS" then
                DoNotFillQtytoHandleReq := true;
            ShowSummary := false;

            OnAfterOpenPage(Location, DoNotFillQtytoHandleReq);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        HideNothingToHandleErr: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPostReportOnBeforeCreateWarehouseDocument(this, TempWhseItemTrkgLine, ItemTrackingManagement, CreatePick, CreatePutAway, WhseDoc, CreateErrorText, FirstActivityNo, LastActivityNo, IsHandled);
        if not IsHandled then begin
            if (CreateErrorText <> '') and (FirstActivityNo = '') and (LastActivityNo = '') then
                Error(CreateErrorText);
            if not (WhseDoc in [WhseDoc::"Put-away Worksheet", WhseDoc::"Posted Receipt", WhseDoc::"Internal Put-away"]) then begin
                CreatePick.CreateWhseDocument(FirstActivityNo, LastActivityNo, true);
                CreatePick.ReturnTempItemTrkgLines(TempWhseItemTrkgLine);
                ItemTrackingManagement.UpdateWhseItemTrkgLines(TempWhseItemTrkgLine);
                Commit();
            end else begin
                CreatePutaway.GetWhseActivHeaderNo(FirstActivityNo, LastActivityNo);
                OnAfterCreatePutawayGetWhseActivHeaderNo(FirstActivityNo, LastActivityNo);
            end;
        end;

        HideNothingToHandleErr := false;
        OnBeforeSortWhseDocsForPrints(WhseDoc, FirstActivityNo, LastActivityNo, SortActivity, PrintDoc, HideNothingToHandleErr);

        WarehouseActivityHeader.SetRange("No.", FirstActivityNo, LastActivityNo);

        case WhseDoc of
            WhseDoc::"Internal Pick", WhseDoc::Production, WhseDoc::Assembly, WhseDoc::Job:
                WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::Pick);
            WhseDoc::"Whse. Mov.-Worksheet":
                WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::Movement);
            WhseDoc::"Posted Receipt", WhseDoc::"Put-away Worksheet", WhseDoc::"Internal Put-away":
                WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        end;

        if WarehouseActivityHeader.Find('-') then begin
            IsHandled := false;
            OnPostReportOnBeforeDeleteBlankBinContent(this, WarehouseActivityHeader, SortActivity, IsHandled);
            if not IsHandled then
                repeat
                    CreatePutAway.DeleteBlankBinContent(WarehouseActivityHeader);
                    OnAfterCreatePutAwayDeleteBlankBinContent(WarehouseActivityHeader);
                    if SortActivity <> SortActivity::None then
                        WarehouseActivityHeader.SortWhseDoc();
                    Commit();
                until WarehouseActivityHeader.Next() = 0;

            if PrintDoc then
                PrintWarehouseDocument(WarehouseActivityHeader);
        end else
            if WhseDoc in [WhseDoc::Production, WhseDoc::Assembly, WhseDoc::Job] then begin
                CreatePick.SetSummaryPageMessage(Text003, false);
                if not CreatePick.ShowCalculationSummary() then
                    if not HideNothingToHandleErr then
                        Error(Text003);
            end
            else
                if not HideNothingToHandleErr then
                    Error(Text003);

        OnAfterPostReport(FirstActivityNo, LastActivityNo, WarehouseActivityHeader, this);
    end;

    trigger OnPreReport()
    begin
        Clear(CreatePick);
        Clear(CreatePutAway);
        EverythingHandled := true;
    end;

    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        AssemblyHeader: Record "Assembly Header";
        JobHeader: Record Job;
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        TempWhseWorksheetLineMovement: Record "Whse. Worksheet Line" temporary;
        TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        CreatePutAway: Codeunit "Create Put-away";
        FirstActivityNo: Code[20];
        LastActivityNo: Code[20];
        CreateErrorText: Text;
        PrintDoc: Boolean;
        EverythingHandled: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 activity no. %2 has been created.';
        Text001: Label '%1 activities no. %2 to %3 have been created.';
        Text002: Label '\For %1 with existing Warehouse Worksheet Lines, no %2 lines have been created.';
        Text003: Label 'There is nothing to handle.';
        Text004: Label 'You can create a Movement only for the available quantity in %1 %2 = %3,%4 = %5,%6 = %7,%8 = %9.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TotalPendingMovQtyExceedsBinAvailErr: Label 'Item tracking defined for line %1, lot number %2, serial number %3, package number %4 cannot be applied.', Comment = '%1=Line No.,%2=Lot No.,%3=Serial No.,%4=Package No.';

    protected var
        CreatePickParameters: Record "Create Pick Parameters";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseSetup: Record "Warehouse Setup";
        CreatePick: Codeunit "Create Pick";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        UOMMgt: Codeunit "Unit of Measure Management";
        SortActivity: Enum "Whse. Activity Sorting Method";
        WhseDoc: Option "Whse. Mov.-Worksheet","Posted Receipt","Internal Pick","Internal Put-away",Production,"Put-away Worksheet",Assembly,"Service Order",Job;
        AssignedID: Code[50];
        BreakbulkFilter: Boolean;
        DoNotFillQtytoHandleReq: Boolean;
        HideValidationDialog: Boolean;
        ShowSummary: Boolean;
        WhseWkshLineFound: Boolean;
        SourceTableCaption: Text;
        SourceLocationCode: Code[10];
        ReservedFromStock: Enum "Reservation From Stock";
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Project Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Project Whse. Handling in used for warehouse pick.', Locked = true;

    procedure SetPostedWhseReceiptLine(var PostedWhseReceiptLine2: Record "Posted Whse. Receipt Line"; AssignedID2: Code[50])
    var
        SortingMethod: Option;
    begin
        PostedWhseReceiptLine.Copy(PostedWhseReceiptLine2);
        WhseDoc := WhseDoc::"Posted Receipt";
        SourceLocationCode := PostedWhseReceiptLine."Location Code";
        SourceTableCaption := PostedWhseReceiptLine.TableCaption();
        AssignedID := AssignedID2;

        SortingMethod := SortActivity.AsInteger();
        OnAfterSetPostedWhseReceiptLine(PostedWhseReceiptLine, SortingMethod);
        SortActivity := "Whse. Activity Sorting Method".FromInteger(SortingMethod);
    end;

    procedure SetWhseWkshLine(var WhseWkshLine2: Record "Whse. Worksheet Line")
    var
        SortingMethod: Option;
    begin
        WhseWkshLine.Copy(WhseWkshLine2);
        case WhseWkshLine."Whse. Document Type" of
            WhseWkshLine."Whse. Document Type"::Receipt,
          WhseWkshLine."Whse. Document Type"::"Internal Put-away",
          WhseWkshLine."Whse. Document Type"::Production:
                WhseDoc := WhseDoc::"Put-away Worksheet";
            WhseWkshLine."Whse. Document Type"::" ":
                WhseDoc := WhseDoc::"Whse. Mov.-Worksheet";
        end;

        SortingMethod := SortActivity.AsInteger();
        OnAfterSetWhseWkshLine(WhseWkshLine, SortingMethod);
        SortActivity := "Whse. Activity Sorting Method".FromInteger(SortingMethod);
    end;

    procedure SetWhseInternalPickLine(var WhseInternalPickLine2: Record "Whse. Internal Pick Line"; AssignedID2: Code[50])
    var
        SortingMethod: Option;
    begin
        WhseInternalPickLine.Copy(WhseInternalPickLine2);
        WhseDoc := WhseDoc::"Internal Pick";
        SourceLocationCode := WhseInternalPickLine."Location Code";
        SourceTableCaption := WhseInternalPickLine.TableCaption();
        AssignedID := AssignedID2;

        SortingMethod := SortActivity.AsInteger();
        OnAfterSetWhseInternalPickLine(WhseInternalPickLine, SortingMethod);
        SortActivity := Enum::"Whse. Activity Sorting Method".FromInteger(SortingMethod);
    end;

    procedure SetWhseInternalPutAway(var WhseInternalPutAwayHeader2: Record "Whse. Internal Put-away Header")
    var
        SortingMethod: Option;
    begin
        WhseInternalPutAwayHeader.Copy(WhseInternalPutAwayHeader2);
        WhseDoc := WhseDoc::"Internal Put-away";
        SourceLocationCode := WhseInternalPutAwayHeader."Location Code";
        SourceTableCaption := WhseInternalPutAwayHeader.TableCaption();
        AssignedID := WhseInternalPutAwayHeader2."Assigned User ID";

        SortingMethod := SortActivity.AsInteger();
        OnAfterSetWhseInternalPutAway(WhseInternalPutAwayHeader, SortingMethod);
        SortActivity := "Whse. Activity Sorting Method".FromInteger(SortingMethod);
    end;

    procedure SetAssemblyOrder(var AssemblyHeader2: Record "Assembly Header")
    begin
        AssemblyHeader.Copy(AssemblyHeader2);
        WhseDoc := WhseDoc::Assembly;
        SourceLocationCode := AssemblyHeader."Location Code";
        SourceTableCaption := AssemblyHeader.TableCaption();
        OnAfterSetAssemblyOrder(AssemblyHeader, SortActivity);
    end;

    procedure SetJob(var Job2: Record Job)
    begin
        JobHeader.Copy(Job2);
        WhseDoc := WhseDoc::Job;
        SourceLocationCode := JobHeader."Location Code";
        SourceTableCaption := JobHeader.TableCaption();
        OnAfterSetJob(JobHeader, SortActivity);
    end;

    procedure GetActivityHeader(var WhseActivityHeader: Record "Warehouse Activity Header"; TypeToFilter: Option " ","Put-away",Pick,Movement,"Invt. Put-away","Invt. Pick","Invt. Movement")
    begin
        WhseActivityHeader.SetRange("No.", FirstActivityNo, LastActivityNo);
        WhseActivityHeader.SetRange(Type, TypeToFilter);
        if not WhseActivityHeader.FindFirst() then
            WhseActivityHeader.Init();
    end;

    procedure GetResultMessage(WhseDocType: Option): Boolean
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        MessageTxt: Text;
    begin
        if FirstActivityNo = '' then
            exit(false);

        if not HideValidationDialog then begin
            WhseActivHeader.Type := "Warehouse Activity Type".FromInteger(WhseDocType);
            if WhseWkshLineFound then begin
                if FirstActivityNo = LastActivityNo then
                    MessageTxt :=
                      StrSubstNo(
                        Text000, Format(WhseActivHeader.Type), FirstActivityNo) +
                      StrSubstNo(
                        Text002, SourceTableCaption, Format(WhseActivHeader.Type))
                else
                    MessageTxt :=
                      StrSubstNo(
                        Text001,
                        Format(WhseActivHeader.Type), FirstActivityNo, LastActivityNo) +
                      StrSubstNo(
                        Text002, SourceTableCaption, Format(WhseActivHeader.Type));
            end else
                if FirstActivityNo = LastActivityNo then
                    MessageTxt := StrSubstNo(Text000, Format(WhseActivHeader.Type), FirstActivityNo)
                else
                    MessageTxt := StrSubstNo(Text001, Format(WhseActivHeader.Type), FirstActivityNo, LastActivityNo);

            if (WhseDoc in [WhseDoc::Production, WhseDoc::Assembly, WhseDoc::Job]) then begin
                CreatePick.SetSummaryPageMessage(MessageTxt, false);
                if not CreatePick.ShowCalculationSummary() then
                    Message(MessageTxt);
            end else
                Message(MessageTxt);
        end;
        exit(EverythingHandled);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            if LocationCode = '' then
                Clear(Location)
            else
                Location.Get(LocationCode);
    end;

    procedure Initialize(AssignedID2: Code[50]; SortActivity2: Enum "Whse. Activity Sorting Method"; PrintDoc2: Boolean; DoNotFillQtytoHandle2: Boolean; BreakbulkFilter2: Boolean)
    begin
        Initialize(AssignedID2, SortActivity2, PrintDoc2, DoNotFillQtytoHandle2, BreakbulkFilter2, false);
    end;

    procedure Initialize(AssignedID2: Code[50]; SortActivity2: Enum "Whse. Activity Sorting Method"; PrintDoc2: Boolean; DoNotFillQtytoHandle2: Boolean; BreakbulkFilter2: Boolean; ShowSummary2: Boolean)
    begin
        AssignedID := AssignedID2;
        SortActivity := SortActivity2;
        PrintDoc := PrintDoc2;
        DoNotFillQtytoHandleReq := DoNotFillQtytoHandle2;
        BreakbulkFilter := BreakbulkFilter2;
        ShowSummary := ShowSummary2;
    end;

    local procedure InitPostedWhseReceiptLineFromPutAway(var PostedWhseReceiptLine2: Record "Posted Whse. Receipt Line"; WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceType: Integer)
    begin
        if not PostedWhseReceiptLine2.Get(WhseWorksheetLine."Whse. Document No.", WhseWorksheetLine."Whse. Document Line No.") then begin
            PostedWhseReceiptLine2.Init();
            PostedWhseReceiptLine2."No." := WhseWorksheetLine."Whse. Document No.";
            PostedWhseReceiptLine2."Line No." := WhseWorksheetLine."Whse. Document Line No.";
            PostedWhseReceiptLine2."Item No." := WhseWorksheetLine."Item No.";
            PostedWhseReceiptLine2.Description := WhseWorksheetLine.Description;
            PostedWhseReceiptLine2."Description 2" := WhseWorksheetLine."Description 2";
            PostedWhseReceiptLine2."Location Code" := WhseWorksheetLine."Location Code";
            PostedWhseReceiptLine2."Zone Code" := WhseWorksheetLine."From Zone Code";
            PostedWhseReceiptLine2."Bin Code" := WhseWorksheetLine."From Bin Code";
            PostedWhseReceiptLine2."Shelf No." := WhseWorksheetLine."Shelf No.";
            PostedWhseReceiptLine2."Qty. per Unit of Measure" := WhseWorksheetLine."Qty. per Unit of Measure";
            PostedWhseReceiptLine2."Due Date" := WhseWorksheetLine."Due Date";
            PostedWhseReceiptLine2."Unit of Measure Code" := WhseWorksheetLine."Unit of Measure Code";
            SourceType := Database::"Whse. Internal Put-away Line";
        end else
            SourceType := Database::"Posted Whse. Receipt Line";

        PostedWhseReceiptLine2.TestField(PostedWhseReceiptLine2."Qty. per Unit of Measure");
        PostedWhseReceiptLine2.Quantity := WhseWorksheetLine."Qty. to Handle";
        PostedWhseReceiptLine2."Qty. (Base)" := WhseWorksheetLine."Qty. to Handle (Base)";

        OnAfterInitPostedWhseReceiptLineFromPutAway(PostedWhseReceiptLine2, WhseWorksheetLine);
    end;

    local procedure InitPostedWhseReceiptLineFromInternalPutAway(var PostedWhseReceiptLine2: Record "Posted Whse. Receipt Line"; WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; QtyToPutAway: Decimal)
    begin
        PostedWhseReceiptLine2.Init();
        PostedWhseReceiptLine2."No." := WhseInternalPutAwayLine."No.";
        PostedWhseReceiptLine2."Line No." := WhseInternalPutAwayLine."Line No.";
        PostedWhseReceiptLine2."Location Code" := WhseInternalPutAwayLine."Location Code";
        PostedWhseReceiptLine2."Bin Code" := WhseInternalPutAwayLine."From Bin Code";
        PostedWhseReceiptLine2."Zone Code" := WhseInternalPutAwayLine."From Zone Code";
        PostedWhseReceiptLine2."Item No." := WhseInternalPutAwayLine."Item No.";
        PostedWhseReceiptLine2."Shelf No." := WhseInternalPutAwayLine."Shelf No.";
        PostedWhseReceiptLine2.Quantity := QtyToPutAway;
        PostedWhseReceiptLine2."Qty. (Base)" :=
          WhseInternalPutAwayLine."Qty. (Base)" -
          (WhseInternalPutAwayLine."Qty. Put Away (Base)" +
           WhseInternalPutAwayLine."Put-away Qty. (Base)");
        PostedWhseReceiptLine2."Qty. Put Away" := WhseInternalPutAwayLine."Qty. Put Away";
        PostedWhseReceiptLine2."Qty. Put Away (Base)" := WhseInternalPutAwayLine."Qty. Put Away (Base)";
        PostedWhseReceiptLine2."Put-away Qty." := WhseInternalPutAwayLine."Put-away Qty.";
        PostedWhseReceiptLine2."Put-away Qty. (Base)" := WhseInternalPutAwayLine."Put-away Qty. (Base)";
        PostedWhseReceiptLine2."Unit of Measure Code" := WhseInternalPutAwayLine."Unit of Measure Code";
        PostedWhseReceiptLine2."Qty. per Unit of Measure" := WhseInternalPutAwayLine."Qty. per Unit of Measure";
        PostedWhseReceiptLine2."Variant Code" := WhseInternalPutAwayLine."Variant Code";
        PostedWhseReceiptLine2.Description := WhseInternalPutAwayLine.Description;
        PostedWhseReceiptLine2."Description 2" := WhseInternalPutAwayLine."Description 2";
        PostedWhseReceiptLine2."Due Date" := WhseInternalPutAwayLine."Due Date";

        OnAfterInitPostedWhseReceiptLineFromInternalPutAway(PostedWhseReceiptLine2, WhseInternalPutAwayLine);
    end;

    procedure SetQuantity(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer; var QtyToHandleBase: Decimal)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetQuantity(PostedWhseRcptLine, SourceType, QtyToHandleBase, IsHandled);
        if IsHandled then
            exit;

        WhseItemTrackingLine.Reset();
        WhseItemTrackingLine.SetTrackingKey();
        WhseItemTrackingLine.SetTrackingFilterFromPostedWhseReceiptLine(PostedWhseRcptLine);
        WhseItemTrackingLine.SetRange("Source Type", SourceType);
        WhseItemTrackingLine.SetRange("Source ID", PostedWhseRcptLine."No.");
        WhseItemTrackingLine.SetRange("Source Ref. No.", PostedWhseRcptLine."Line No.");
        OnSetQuantityOnAfterWhseItemTrackingLineSetFilters(WhseItemTrackingLine, PostedWhseRcptLine);
        if WhseItemTrackingLine.FindFirst() then begin
            OnSetQuantityOnAfterFindWhseItemTrackingLine(WhseItemTrackingLine, PostedWhseRcptLine);
            if QtyToHandleBase < WhseItemTrackingLine."Qty. to Handle (Base)" then
                PostedWhseRcptLine."Qty. (Base)" := QtyToHandleBase
            else
                PostedWhseRcptLine."Qty. (Base)" := WhseItemTrackingLine."Qty. to Handle (Base)";
            QtyToHandleBase -= PostedWhseRcptLine."Qty. (Base)";
            PostedWhseRcptLine.Quantity :=
              Round(PostedWhseRcptLine."Qty. (Base)" / PostedWhseRcptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        end;

        OnAfterSetQuantity(PostedWhseRcptLine, WhseItemTrackingLine);
    end;

    local procedure CheckAvailabilityWithTracking(WhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        TrackedQtyInBin: Decimal;
    begin
        WhseItemTrackingLine.SetSourceFilter(Database::"Whse. Worksheet Line", 0, WhseWorksheetLine.Name, WhseWorksheetLine."Line No.", false);
        WhseItemTrackingLine.SetRange("Source Batch Name", WhseWorksheetLine."Worksheet Template Name");
        WhseItemTrackingLine.SetRange("Location Code", WhseWorksheetLine."Location Code");
        WhseItemTrackingLine.SetRange("Item No.", WhseWorksheetLine."Item No.");
        WhseItemTrackingLine.SetRange("Variant Code", WhseWorksheetLine."Variant Code");
        if WhseItemTrackingLine.IsEmpty() then
            exit;

        WhseItemTrackingLine.FindSet();
        repeat
            WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);
            TrackedQtyInBin :=
                WarehouseAvailabilityMgt.CalcQtyOnBin(
                    WhseWorksheetLine."Location Code", WhseWorksheetLine."From Bin Code", WhseWorksheetLine."Item No.",
                    WhseWorksheetLine."Variant Code", WhseItemTrackingSetup);
            if TrackedQtyInBin < WhseItemTrackingLine."Quantity (Base)" + WarehouseAvailabilityMgt.CalcQtyAssignedToMove(
                 WhseWorksheetLine, WhseItemTrackingLine)
            then
                Error(TotalPendingMovQtyExceedsBinAvailErr, WhseWorksheetLine."Line No.", WhseItemTrackingLine."Lot No.", WhseItemTrackingLine."Serial No.", WhseItemTrackingLine."Package No.");
        until WhseItemTrackingLine.Next() = 0;
    end;

    procedure UpdateWhseItemTrkgLines(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer; var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.Reset();
        WhseItemTrackingLine.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Source Ref. No.");
        WhseItemTrackingLine.SetRange("Source ID", PostedWhseRcptLine."No.");
        WhseItemTrackingLine.SetRange("Source Type", SourceType);
        WhseItemTrackingLine.SetRange("Source Subtype", 0);
        WhseItemTrackingLine.SetRange("Source Batch Name", '');
        WhseItemTrackingLine.SetRange("Source Prod. Order Line", 0);
        WhseItemTrackingLine.SetRange("Source Ref. No.", PostedWhseRcptLine."Line No.");
        if WhseItemTrackingLine.Find('-') then
            repeat
                TempWhseItemTrkgLine.SetRange("Source Type", WhseItemTrackingLine."Source Type");
                TempWhseItemTrkgLine.SetRange("Source ID", WhseItemTrackingLine."Source ID");
                TempWhseItemTrkgLine.SetRange("Source Ref. No.", WhseItemTrackingLine."Source Ref. No.");
                TempWhseItemTrkgLine.SetTrackingFilterFromWhseItemTrackingLine(WhseItemTrackingLine);
                if TempWhseItemTrkgLine.Find('-') then
                    WhseItemTrackingLine."Quantity Handled (Base)" += TempWhseItemTrkgLine."Quantity (Base)";
                WhseItemTrackingLine."Qty. to Handle (Base)" := WhseItemTrackingLine."Quantity (Base)" - WhseItemTrackingLine."Quantity Handled (Base)";
                OnBeforeWhseItemTrackingLineModify(WhseItemTrackingLine, TempWhseItemTrkgLine);
                WhseItemTrackingLine.Modify();
            until WhseItemTrackingLine.Next() = 0;
    end;

    local procedure UpdateWkshMovementLineBuffer(WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        FilterWkshLine(TempWhseWorksheetLineMovement, WhseWorksheetLine);
        if TempWhseWorksheetLineMovement.FindFirst() then begin
            TempWhseWorksheetLineMovement."Qty. (Base)" += WhseWorksheetLine."Qty. (Base)";
            TempWhseWorksheetLineMovement.Quantity += WhseWorksheetLine.Quantity;
            TempWhseWorksheetLineMovement."Qty. Outstanding (Base)" += WhseWorksheetLine."Qty. Outstanding (Base)";
            TempWhseWorksheetLineMovement."Qty. Outstanding" += WhseWorksheetLine."Qty. Outstanding";
            TempWhseWorksheetLineMovement."Qty. to Handle (Base)" += WhseWorksheetLine."Qty. to Handle (Base)";
            TempWhseWorksheetLineMovement."Qty. to Handle" += WhseWorksheetLine."Qty. to Handle";
            TempWhseWorksheetLineMovement."Qty. Handled (Base)" += WhseWorksheetLine."Qty. Handled (Base)";
            TempWhseWorksheetLineMovement."Qty. Handled" += WhseWorksheetLine."Qty. Handled (Base)";
            OnBeforeTempWhseWorksheetLineMovementModify(TempWhseWorksheetLineMovement, WhseWorksheetLine);
            TempWhseWorksheetLineMovement.Modify();
        end else begin
            TempWhseWorksheetLineMovement := WhseWorksheetLine;
            TempWhseWorksheetLineMovement.Insert();
        end;
        UpdateWhseItemTrackingBuffer(WhseWorksheetLine, TempWhseWorksheetLineMovement);
        TempWhseWorksheetLineMovement.Reset();
    end;

    local procedure UpdateWhseItemTrackingBuffer(SourceWhseWorksheetLine: Record "Whse. Worksheet Line"; BufferWhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        LastWhseItemTrkgLineNo: Integer;
    begin
        TempWhseItemTrackingLine.Reset();
        if TempWhseItemTrackingLine.FindLast() then
            LastWhseItemTrkgLineNo := TempWhseItemTrackingLine."Entry No.";

        WhseItemTrackingLine.SetSourceFilter(
          Database::"Whse. Worksheet Line", 0, SourceWhseWorksheetLine.Name, SourceWhseWorksheetLine."Line No.", true);
        WhseItemTrackingLine.SetSourceFilter(SourceWhseWorksheetLine."Worksheet Template Name", 0);
        WhseItemTrackingLine.SetRange("Location Code", SourceWhseWorksheetLine."Location Code");
        WhseItemTrackingLine.SetFilter("Qty. to Handle (Base)", '>0');
        if WhseItemTrackingLine.FindSet() then
            repeat
                TempWhseItemTrackingLine.SetSourceFilter(
                  Database::"Whse. Worksheet Line", 0, BufferWhseWorksheetLine.Name, BufferWhseWorksheetLine."Line No.", false);
                TempWhseItemTrackingLine.SetSourceFilter(BufferWhseWorksheetLine."Worksheet Template Name", 0);
                TempWhseItemTrackingLine.SetRange("Location Code", BufferWhseWorksheetLine."Location Code");
                TempWhseItemTrackingLine.SetTrackingFilterFromWhseItemTrackingLine(WhseItemTrackingLine);
                if TempWhseItemTrackingLine.FindFirst() then begin
                    TempWhseItemTrackingLine."Quantity (Base)" += WhseItemTrackingLine."Quantity (Base)";
                    TempWhseItemTrackingLine."Quantity Handled (Base)" += WhseItemTrackingLine."Quantity Handled (Base)";
                    TempWhseItemTrackingLine."Qty. to Handle (Base)" += WhseItemTrackingLine."Qty. to Handle (Base)";
                    TempWhseItemTrackingLine.Modify();
                end else begin
                    TempWhseItemTrackingLine.Init();
                    TempWhseItemTrackingLine := WhseItemTrackingLine;
                    TempWhseItemTrackingLine."Source Ref. No." := BufferWhseWorksheetLine."Line No.";
                    TempWhseItemTrackingLine."Entry No." := LastWhseItemTrkgLineNo + 1;
                    TempWhseItemTrackingLine.Insert();
                    LastWhseItemTrkgLineNo := TempWhseItemTrackingLine."Entry No.";
                end;
            until WhseItemTrackingLine.Next() = 0;
    end;

    local procedure CreateMovementLines(WhseWorksheetLine: Record "Whse. Worksheet Line"; var PickQty: Decimal; var PickQtyBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateMovementLines(WhseWorksheetLine, PickQty, PickQtyBase, IsHandled);
        if IsHandled then
            exit;

        CreatePick.SetCalledFromWksh(true);
        CreatePick.SetWhseWkshLine(WhseWorksheetLine, 1);

        CreatePick.SetTempWhseItemTrkgLineFromBuffer(
            TempWhseItemTrackingLine,
            WhseWorksheetLine.Name, Database::"Whse. Worksheet Line", WhseWorksheetLine."Worksheet Template Name", 0, WhseWorksheetLine."Line No.", WhseWorksheetLine."Location Code");
        PickQty := WhseWorksheetLine."Qty. to Handle";
        PickQtyBase := WhseWorksheetLine."Qty. to Handle (Base)";
        CreatePick.CreateTempLine(
          WhseWorksheetLine."Location Code", WhseWorksheetLine."Item No.", WhseWorksheetLine."Variant Code", WhseWorksheetLine."Unit of Measure Code", WhseWorksheetLine."From Bin Code", WhseWorksheetLine."To Bin Code",
          WhseWorksheetLine."Qty. per Unit of Measure", WhseWorksheetLine."Qty. Rounding Precision", WhseWorksheetLine."Qty. Rounding Precision (Base)", PickQty, PickQtyBase);
    end;

    local procedure UpdateMovementWorksheet(WhseWorksheetLineBuffer: Record "Whse. Worksheet Line"; QtyHandled: Decimal; QtyHandledBase: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldQtyToHandleBase: Decimal;
        OldQtyHandledBase: Decimal;
    begin
        FilterWkshLine(WhseWorksheetLine, WhseWorksheetLineBuffer);
        WhseWorksheetLine.FindSet(true);
        repeat
            if WhseWorksheetLine."Qty. to Handle" = WhseWorksheetLine."Qty. Outstanding" then begin
                WhseWorksheetLine.Delete();
                ItemTrackingMgt.DeleteWhseItemTrkgLines(
                  Database::"Whse. Worksheet Line", 0, WhseWorksheetLine.Name, WhseWorksheetLine."Worksheet Template Name", 0, WhseWorksheetLine."Line No.", WhseWorksheetLine."Location Code", true);
                QtyHandled -= WhseWorksheetLine."Qty. to Handle";
                QtyHandledBase -= WhseWorksheetLine."Qty. to Handle (Base)";
            end else begin
                OldQtyHandledBase := WhseWorksheetLine."Qty. Handled (Base)";
                OldQtyToHandleBase := WhseWorksheetLine."Qty. to Handle (Base)";
                if QtyHandledBase >= WhseWorksheetLine."Qty. to Handle (Base)" then begin
                    QtyHandledBase -= WhseWorksheetLine."Qty. to Handle (Base)";
                    QtyHandled -= WhseWorksheetLine."Qty. to Handle";
                    WhseWorksheetLine.Validate(WhseWorksheetLine."Qty. Handled", WhseWorksheetLine."Qty. Handled" + WhseWorksheetLine."Qty. to Handle");
                    WhseWorksheetLine."Qty. Handled (Base)" := OldQtyHandledBase + OldQtyToHandleBase;
                end else begin
                    WhseWorksheetLine.Validate(WhseWorksheetLine."Qty. Handled", WhseWorksheetLine."Qty. Handled" + WhseWorksheetLine."Qty. to Handle" - QtyHandled);
                    WhseWorksheetLine."Qty. Handled (Base)" := OldQtyHandledBase + OldQtyToHandleBase - QtyHandledBase;
                    QtyHandledBase := 0;
                    QtyHandled := 0;
                end;
                WhseWorksheetLine."Qty. Outstanding (Base)" := WhseWorksheetLine."Qty. (Base)" - WhseWorksheetLine."Qty. Handled (Base)";
                WhseWorksheetLine.Modify();
            end;
        until (WhseWorksheetLine.Next() = 0) or (QtyHandledBase = 0);
    end;

    local procedure FilterWkshLine(var WhseWorksheetLineToFilter: Record "Whse. Worksheet Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        WhseWorksheetLineToFilter.SetRange("Worksheet Template Name", WhseWorksheetLine."Worksheet Template Name");
        WhseWorksheetLineToFilter.SetRange(Name, WhseWorksheetLine.Name);
        WhseWorksheetLineToFilter.SetRange("Location Code", WhseWorksheetLine."Location Code");
        WhseWorksheetLineToFilter.SetRange("Item No.", WhseWorksheetLine."Item No.");
        WhseWorksheetLineToFilter.SetRange("Variant Code", WhseWorksheetLine."Variant Code");
        WhseWorksheetLineToFilter.SetRange("From Bin Code", WhseWorksheetLine."From Bin Code");
        WhseWorksheetLineToFilter.SetRange("To Bin Code", WhseWorksheetLine."To Bin Code");
        WhseWorksheetLineToFilter.SetRange("From Zone Code", WhseWorksheetLine."From Zone Code");
        WhseWorksheetLineToFilter.SetRange("To Zone Code", WhseWorksheetLine."To Zone Code");
        WhseWorksheetLineToFilter.SetRange("Unit of Measure Code", WhseWorksheetLine."Unit of Measure Code");
        WhseWorksheetLineToFilter.SetRange("From Unit of Measure Code", WhseWorksheetLine."From Unit of Measure Code");
        OnAfterFilterWkshLine(WhseWorksheetLineToFilter, WhseWorksheetLine);
    end;

    procedure CreatePutAwayFromDiffSource(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer)
    var
        TempPostedWhseReceiptLine: Record "Posted Whse. Receipt Line" temporary;
        TempPostedWhseReceiptLine2: Record "Posted Whse. Receipt Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        RemQtyToHandleBase: Decimal;
        IsHandled: Boolean;
    begin
        case SourceType of
            Database::"Whse. Internal Put-away Line":
                ItemTrackingMgt.SplitInternalPutAwayLine(PostedWhseRcptLine, TempPostedWhseReceiptLine);
            Database::"Posted Whse. Receipt Line":
                ItemTrackingMgt.SplitPostedWhseRcptLine(PostedWhseRcptLine, TempPostedWhseReceiptLine);
        end;
        RemQtyToHandleBase := PostedWhseRcptLine."Qty. (Base)";

        TempPostedWhseReceiptLine.Reset();
        IsHandled := false;
        OnCreatePutAwayFromDiffSourceOnBeforeProcessCreatePutAway(this, PostedWhseRcptLine, TempPostedWhseReceiptLine, CreatePutAway, IsHandled);
        if not IsHandled then
            if TempPostedWhseReceiptLine.FindSet() then
                repeat
                    TempPostedWhseReceiptLine2 := TempPostedWhseReceiptLine;
                    TempPostedWhseReceiptLine2."Line No." := PostedWhseRcptLine."Line No.";
                    SetQuantity(TempPostedWhseReceiptLine2, SourceType, RemQtyToHandleBase);
                    if TempPostedWhseReceiptLine2."Qty. (Base)" > 0 then begin
                        CreatePutAway.Run(TempPostedWhseReceiptLine2);
                        CreatePutAway.UpdateTempWhseItemTrkgLines(TempPostedWhseReceiptLine2, SourceType);
                    end;
                until TempPostedWhseReceiptLine.Next() = 0;
    end;

    procedure FEFOLocation(LocCode: Code[10]): Boolean
    var
        Location2: Record Location;
    begin
        if LocCode <> '' then begin
            Location2.Get(LocCode);
            exit(Location2."Pick According to FEFO");
        end;
        exit(false);
    end;

    procedure ItemTracking(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if ItemNo <> '' then begin
            Item.Get(ItemNo);
            if Item."Item Tracking Code" <> '' then begin
                ItemTrackingCode.Get(Item."Item Tracking Code");
                exit(ItemTrackingCode.IsSpecific());
            end;
        end;
        exit(false);
    end;

    local procedure GetHeaderLocationCode(): Code[10]
    begin
        case WhseDoc of
            WhseDoc::"Put-away Worksheet",
            WhseDoc::"Whse. Mov.-Worksheet":
                exit(WhseWkshLine."Location Code");
            else
                exit(SourceLocationCode);
        end;
    end;

    local procedure PrintWarehouseDocument(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        case WhseDoc of
            WhseDoc::"Internal Pick", WhseDoc::Production, WhseDoc::Assembly, WhseDoc::Job:
                WarehouseDocumentPrint.PrintPickHeader(WarehouseActivityHeader);
            WhseDoc::"Whse. Mov.-Worksheet":
                WarehouseDocumentPrint.PrintMovementHeader(WarehouseActivityHeader);
            WhseDoc::"Posted Receipt", WhseDoc::"Put-away Worksheet", WhseDoc::"Internal Put-away":
                WarehouseDocumentPrint.PrintPutAwayHeader(WarehouseActivityHeader);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutAwayDeleteBlankBinContent(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterWkshLine(var WhseWorksheetLineToFilter: Record "Whse. Worksheet Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostedWhseReceiptLineFromPutAway(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostedWhseReceiptLineFromInternalPutAway(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOpenPage(var Location: Record Location; var DoNotFillQtytoHandle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(FirstActivityNo: Code[20]; LastActivityNo: Code[20]; var WarehouseActivityHeader: Record "Warehouse Activity Header"; WhseSourceCreateDocument: Report "Whse.-Source - Create Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseReceiptLineOnPostDataItem(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var SortActivity: Enum "Whse. Activity Sorting Method")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJob(var Job: Record Job; var SortActivity: Enum "Whse. Activity Sorting Method")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPostedWhseReceiptLine(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQuantity(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseInternalPickLine(WhseInternalPickLine: Record "Whse. Internal Pick Line"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseInternalPutAway(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseWkshLine(WhseWorksheetLine: Record "Whse. Worksheet Line"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhsePutAwayWorksheetLineOnPostDataItem(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessWhseMovWkshLines(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetQuantity(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer; var QtyToHandleBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSortWhseDocsForPrints(WhseDoc: Option "Whse. Mov.-Worksheet","Posted Receipt","Internal Pick","Internal Put-away",Production,"Put-away Worksheet",Assembly,"Service Order"; var FirstActivityNo: Code[20]; var LastActivityNo: Code[20]; SortActivity: Enum "Whse. Activity Sorting Method"; PrintDoc: Boolean; var HideNothingToHandleErr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseWorksheetLineMovementModify(var TempWhseWorksheetLineMovement: Record "Whse. Worksheet Line" temporary; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseItemTrackingLineModify(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhsePutAwayWorksheetLineOnPreDataItem(var WhsePutawayWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetQuantityOnAfterWhseItemTrackingLineSetFilters(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostedWhseReceiptLineOnAfterGetRecordOnBeforeGetWhseItemTrkgSetup(WhseWorksheetLine: Record "Whse. Worksheet Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetQuantityOnAfterFindWhseItemTrackingLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreDataItemAssemblyLine(var AssemblyHeader: Record "Assembly Header"; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateMovementLines(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var PickQty: Decimal; var PickQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreDataItemJobPlanningLineOnAfterSetFilters(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforeCreateWarehouseDocument(WhseSourceCreateDocument: Report "Whse.-Source - Create Document"; TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var ItemTrackingManagement: Codeunit "Item Tracking Management"; var CreatePick: Codeunit "Create Pick"; var CreatePutAway: Codeunit "Create Put-away"; WhseDoc: Option "Whse. Mov.-Worksheet","Posted Receipt","Internal Pick","Internal Put-away",Production,"Put-away Worksheet",Assembly,"Service Order",Job; var CreateErrorText: Text; var FirstActivityNo: Code[20]; var LastActivityNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforeDeleteBlankBinContent(WhseSourceCreateDocument: Report "Whse.-Source - Create Document"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WhseActivitySortingMethod: Enum "Whse. Activity Sorting Method"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutAwayFromDiffSourceOnBeforeProcessCreatePutAway(WhseSourceCreateDocument: Report "Whse.-Source - Create Document"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseReceiptLine: Record "Posted Whse. Receipt Line" temporary; var CreatePutAway: Codeunit "Create Put-away"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayFromProduction(var WhsePutawayWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer; var EverythingHandled: Boolean; var QtyHandledBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutawaySetValues(NewAssignedID: Code[50]; NewSortActivity: Enum "Whse. Activity Sorting Method"; NewDoNotFillQtytoHandle: Boolean; NewBreakbulkFilter: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetProductionMessageText(var CreateErrorText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutawayGetWhseActivHeaderNo(var FirstActivityNo: Code[20]; var LastActivityNo: Code[20])
    begin
    end;
}

