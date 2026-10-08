// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;

report 7318 "Whse.-Shipment - Create Pick"
{
    Caption = 'Whse.-Shipment - Create Pick';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Warehouse Shipment Line"; "Warehouse Shipment Line")
        {
            DataItemTableView = sorting("No.", "Line No.");
            dataitem("Assembly Header"; "Assembly Header")
            {
                DataItemTableView = sorting("Document Type", "No.");
                dataitem("Assembly Line"; "Assembly Line")
                {
                    DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        WMSMgt: Codeunit "WMS Management";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnAssemblyLineDataItemOnBeforeOnAfterGetRecord("Warehouse Shipment Line", "Assembly Line", IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        if not "Assembly Line".IsInventoriableItem() then
                            CurrReport.Skip();

                        WMSMgt.CheckInboundBlockedBin("Location Code", "Bin Code", "No.", "Variant Code", "Unit of Measure Code");

                        WhseWkshLine.SetRange("Source Line No.", "Line No.");
                        if not WhseWkshLine.FindFirst() then
                            CreatePick.CreateAssemblyPickLine("Assembly Line")
                        else begin
                            CreatePick.InsertSkippedLinesToCalculationSummary(Database::"Assembly Line", "Document No.", "Line No.", "Document Type".AsInteger(), 0, "Location Code", "No.", "Variant Code", "Unit of Measure Code", "Bin Code", Quantity, "Quantity (Base)", WhseWkshLine.SystemId);
                            WhseWkshLineFound := true;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Type, Type::Item);
                        SetFilter("Remaining Quantity (Base)", '>0');

                        WhseWkshLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                        WhseWkshLine.SetRange("Source Type", Database::"Assembly Line");
                        WhseWkshLine.SetRange("Source Subtype", "Assembly Header"."Document Type");
                        WhseWkshLine.SetRange("Source No.", "Assembly Header"."No.");
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    IsHandled: Boolean;
                begin
                    OnBeforeOnAfterGetRecordAssemblyHeader("Assembly Header", IsHandled);
                    if IsHandled then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if not "Warehouse Shipment Line"."Assemble to Order" then
                        CurrReport.Break();

                    CheckIfAsmToOrderExists("Warehouse Shipment Line", "Assembly Header");
                    SetRange("Document Type", "Document Type");
                    SetRange("No.", "No.");
                end;
            }

            trigger OnAfterGetRecord()
            var
                QtyToPick: Decimal;
                QtyToPickBase: Decimal;
            begin
                CheckBin(0, 0);

                WhseWkshLine.Reset();
                WhseWkshLine.SetCurrentKey(
                  "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                WhseWkshLine.SetRange(
                  "Whse. Document Type", WhseWkshLine."Whse. Document Type"::Shipment);
                WhseWkshLine.SetRange("Whse. Document No.", WhseShptHeader."No.");
                WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
                OnAfterSetWhseWkshLineFilters(WhseWkshLine, "Warehouse Shipment Line", WhseShptHeader);
                if not WhseWkshLine.FindFirst() then begin
                    TestField("Qty. per Unit of Measure");
                    CalcFields("Pick Qty. (Base)", "Pick Qty.");
                    QtyToPickBase := "Qty. (Base)" - ("Qty. Picked (Base)" + "Pick Qty. (Base)");
                    QtyToPick := Quantity - ("Qty. Picked" + "Pick Qty.");
                    OnAfterCalculateQuantityToPick("Warehouse Shipment Line", QtyToPick, QtyToPickBase);
                    if QtyToPick > 0 then begin
                        if "Destination Type" = "Destination Type"::Customer then begin
                            TestField("Destination No.");
                            Cust.Get("Destination No.");
                            Cust.CheckBlockedCustOnDocs(Cust, "Source Document", false, false);
                        end;

                        CreatePick.SetWhseShipment(
                          "Warehouse Shipment Line", 1, WhseShptHeader."Shipping Agent Code",
                          WhseShptHeader."Shipping Agent Service Code", WhseShptHeader."Shipment Method Code");
                        if not "Assemble to Order" then begin
                            CreatePick.SetTempWhseItemTrkgLine(
                              "No.", Database::"Warehouse Shipment Line",
                              '', 0, "Line No.", "Location Code");

                            OnAfterGetRecordWarehouseShipmentLineOnBeforeCreatePickTempLine("Warehouse Shipment Line");
                            CreatePick.CreateTempLine(
                              "Location Code", "Item No.", "Variant Code", "Unit of Measure Code",
                              '', "Bin Code", "Qty. per Unit of Measure", "Qty. Rounding Precision",
                              "Qty. Rounding Precision (Base)", QtyToPick, QtyToPickBase);
                        end;
                    end
                    else
                        CreatePick.InsertSkippedLinesToCalculationSummary("Source Type", "Source No.", "Source Line No.", "Source Subtype", 0, "Location Code", "Item No.", "Variant Code", "Unit of Measure Code", "Bin Code", QtyToPick, QtyToPickBase, EmptyGuid);
                end else begin
                    WhseWkshLineFound := true;
                    CreatePick.InsertSkippedLinesToCalculationSummary("Source Type", "Source No.", "Source Line No.", "Source Subtype", 0, "Location Code", "Item No.", "Variant Code", "Unit of Measure Code", "Bin Code", Quantity, "Qty. (Base)", WhseWkshLine.SystemId);
                end;
            end;

            trigger OnPostDataItem()
            var
                TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
                ItemTrackingMgt: Codeunit "Item Tracking Management";
            begin
                CreatePick.ReturnTempItemTrkgLines(TempWhseItemTrkgLine);
                if TempWhseItemTrkgLine.Find('-') then
                    repeat
                        ItemTrackingMgt.CalcWhseItemTrkgLine(TempWhseItemTrkgLine);
                    until TempWhseItemTrkgLine.Next() = 0;

                if ApplyCustomSorting then
                    WhseShptHeader.SortWhseDoc();
            end;

            trigger OnPreDataItem()
            var
                CreatePickParameters: Record "Create Pick Parameters";
            begin
                ReadIsolation := IsolationLevel::UpdLock;

                CreatePickParameters."Assigned ID" := AssignedIDReq;
                CreatePickParameters."Sorting Method" := SortActivity;
                CreatePickParameters."Max No. of Lines" := 0;
                CreatePickParameters."Max No. of Source Doc." := 0;
                CreatePickParameters."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandleReq;
                CreatePickParameters."Breakbulk Filter" := BreakbulkFilterReq;
                CreatePickParameters."Per Bin" := false;
                CreatePickParameters."Per Zone" := false;
                CreatePickParameters."Whse. Document" := CreatePickParameters."Whse. Document"::Shipment;
                CreatePickParameters."Whse. Document Type" := CreatePickParameters."Whse. Document Type"::Pick;
                CreatePick.SetParameters(CreatePickParameters);
                CreatePick.SetSaveSummary(ShowSummary);

                CopyFilters(WhseShptLine);
                SetFilter("Qty. (Base)", '>0');

                if ApplyCustomSorting then begin
                    WhseShptHeader.ApplyCustomSortingToWhseShptLines("Warehouse Shipment Line");
                    SetCurrentKey("Sorting Sequence No.");
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AssignedID; AssignedIDReq)
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
                            WhseEmployee.SetRange("Location Code", Location.Code);
                            LookupWhseEmployee.LookupMode(true);
                            LookupWhseEmployee.SetTableView(WhseEmployee);
                            if LookupWhseEmployee.RunModal() = ACTION::LookupOK then begin
                                LookupWhseEmployee.GetRecord(WhseEmployee);
                                AssignedIDReq := WhseEmployee."User ID";
                            end;
                        end;

                        trigger OnValidate()
                        var
                            WhseEmployee: Record "Warehouse Employee";
                        begin
                            if AssignedIDReq <> '' then
                                WhseEmployee.Get(AssignedIDReq, Location.Code);
                        end;
                    }
                    field(SortingMethodForActivityLines; SortActivity)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Sorting Method for Activity Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies the method by which the lines in the instruction will be sorted. The options are by item, document, shelf or bin (if the location uses bins, this functions as the bin code), due date, bin ranking, or action type.';
                    }
                    field(BreakbulkFilter; BreakbulkFilterReq)
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
                    field(CustomSorting; ApplyCustomSorting)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Prioritize lines with item tracking';
                        ToolTip = 'Specifies if you want to pick the shipment lines with item tracking first.';
                    }
                    field(PrintDoc; PrintDocReq)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Print Document';
                        ToolTip = 'Specifies if you want the pick document to be printed. Otherwise, you can print it later from the Whse. Pick window.';
                    }
                    field(ShowSummaryField; ShowSummary)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Show Summary (Directed Put-away and Pick)';
                        ToolTip = 'Specifies if you want the summary window to be shown after creating pick lines.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if Location."Use ADCS" then
                DoNotFillQtytoHandleReq := true;

            OnAfterOpenPage(DoNotFillQtytoHandleReq);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
        IsHandled: Boolean;
    begin
        CreatePick.CreateWhseDocument(FirstActivityNo, LastActivityNo, not HideNothingToHandleErr);

        CreatePick.ReturnTempItemTrkgLines(TempWhseItemTrkgLine);
        ItemTrackingMgt.UpdateWhseItemTrkgLines(TempWhseItemTrkgLine);

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::Pick);
        WhseActivHeader.SetRange("No.", FirstActivityNo, LastActivityNo);
        OnBeforeSortWhseActivHeaders(WhseActivHeader, FirstActivityNo, LastActivityNo, HideNothingToHandleErr);
        if WhseActivHeader.FindSet(DoNotFillQtytoHandleReq) then begin
            repeat
                if SortActivity <> SortActivity::None then
                    WhseActivHeader.SortWhseDoc();
                WhseActivHeader."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandleReq;
                WhseActivHeader.Modify();
            until WhseActivHeader.Next() = 0;

            if PrintDocReq then begin
                // new pick has been created - in order to run a report to print it, a COMMIT is needed.
                Commit();

                IsHandled := false;
                OnBeforePrintPickingList(WhseActivHeader, IsHandled);
                if not IsHandled then
                    WarehouseDocumentPrint.PrintPickHeader(WhseActivHeader);
            end;
        end else
            if not HideNothingToHandleErr then begin
                CreatePick.SetSummaryPageMessage(NothingToHandleErr, false);
                if not CreatePick.ShowCalculationSummary() then
                    Error(NothingToHandleErr);
            end;

        OnAfterPostReport(FirstActivityNo, LastActivityNo);
    end;

    trigger OnPreReport()
    begin
        OnBeforeOnPreReport();
        Clear(CreatePick);
        EverythingHandled := true;
    end;

    var
        Location: Record Location;
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        Cust: Record Customer;
        CreatePick: Codeunit "Create Pick";
        FirstActivityNo: Code[20];
        LastActivityNo: Code[20];
        AssignedIDReq: Code[50];
        ShowSummary: Boolean;
        EverythingHandled: Boolean;
        WhseWkshLineFound: Boolean;
        HideNothingToHandleErr: Boolean;
        BreakbulkFilterReq: Boolean;
        EmptyGuid: Guid;
        SingleActivCreatedMsg: Label '%1 activity no. %2 has been created.%3', Comment = '%1=WhseActivHeader.Type;%2=Whse. Activity No.;%3=Concatenates ExpiredItemMessageText';
        SingleActivAndWhseShptCreatedMsg: Label '%1 activity no. %2 has been created. For Warehouse Shipment lines that have existing Pick Worksheet lines, no %3 lines have been created.%4', Comment = '%1=WhseActivHeader.Type;%2=Whse. Activity No.;%3=WhseActivHeader.Type;%4=Concatenates ExpiredItemMessageText';
        MultipleActivCreatedMsg: Label '%1 activities no. %2 to %3 have been created.%4', Comment = '%1=WhseActivHeader.Type;%2=First Whse. Activity No.;%3=Last Whse. Activity No.;%4=Concatenates ExpiredItemMessageText';
        MultipleActivAndWhseShptCreatedMsg: Label '%1 activities no. %2 to %3 have been created.For Warehouse Shipment lines that have existing Pick Worksheet lines, no %4 lines have been created.%5', Comment = '%1=WhseActivHeader.Type;%2=First Whse. Activity No.;%3=Last Whse. Activity No.;%4=WhseActivHeader.Type;%5=Concatenates ExpiredItemMessageText';
        NothingToHandleErr: Label 'There is nothing to handle.';
        ApplyCustomSorting: Boolean;

    protected var
        DoNotFillQtytoHandleReq: Boolean;
        HideValidationDialog: Boolean;
        PrintDocReq: Boolean;
        SortActivity: Enum "Whse. Activity Sorting Method";

    procedure SetWhseShipmentLine(var WhseShptLine2: Record "Warehouse Shipment Line"; WhseShptHeader2: Record "Warehouse Shipment Header")
    var
        SortingMethod: Option;
    begin
        WhseShptLine.Copy(WhseShptLine2);
        WhseShptHeader := WhseShptHeader2;
        AssignedIDReq := WhseShptHeader2."Assigned User ID";
        GetLocation(WhseShptLine."Location Code");

        SortingMethod := SortActivity.AsInteger();
        OnAfterSetWhseShipmentLine(WhseShptLine, WhseShptHeader, SortingMethod, AssignedIDReq);
        SortActivity := "Whse. Activity Sorting Method".FromInteger(SortingMethod);
    end;

    procedure GetResultMessage(): Boolean
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        CannotBeHandledReason: Text;
        MessageTxt: Text;
    begin
        CannotBeHandledReason := CreatePick.GetCannotBeHandledReason();
        if FirstActivityNo = '' then
            exit(false);

        if not HideValidationDialog then begin
            WhseActivHeader.Type := WhseActivHeader.Type::Pick;
            if WhseWkshLineFound then begin
                if FirstActivityNo = LastActivityNo then
                    MessageTxt :=
                      StrSubstNo(
                        SingleActivAndWhseShptCreatedMsg, Format(WhseActivHeader.Type), FirstActivityNo,
                        Format(WhseActivHeader.Type), CannotBeHandledReason)
                else
                    MessageTxt :=
                      StrSubstNo(
                        MultipleActivAndWhseShptCreatedMsg, Format(WhseActivHeader.Type), FirstActivityNo, LastActivityNo,
                        Format(WhseActivHeader.Type), CannotBeHandledReason);
            end else
                if FirstActivityNo = LastActivityNo then
                    MessageTxt :=
                      StrSubstNo(SingleActivCreatedMsg, Format(WhseActivHeader.Type), FirstActivityNo, CannotBeHandledReason)
                else
                    MessageTxt :=
                      StrSubstNo(MultipleActivCreatedMsg, Format(WhseActivHeader.Type),
                        FirstActivityNo, LastActivityNo, CannotBeHandledReason);

            CreatePick.SetSummaryPageMessage(MessageTxt, false);
            if not CreatePick.ShowCalculationSummary() then begin
                Message(MessageTxt);
                OnGetResultMessageOnAfterShowResultMessage();
            end;
        end;

        exit(EverythingHandled);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure SetHideNothingToHandleError(HideNothingToHandleError: Boolean)
    begin
        HideNothingToHandleErr := HideNothingToHandleError;
    end;

    local procedure GetLocation(LocationCode: Code[10])
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
        AssignedIDReq := AssignedID2;
        SortActivity := SortActivity2;
        PrintDocReq := PrintDoc2;
        DoNotFillQtytoHandleReq := DoNotFillQtytoHandle2;
        BreakbulkFilterReq := BreakbulkFilter2;
        ShowSummary := ShowSummary2;
    end;

    local procedure CheckIfAsmToOrderExists(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var AssemblyHeader: Record "Assembly Header")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnPreDataItemAssemblyHeader(AssemblyHeader, IsHandled, WarehouseShipmentLine);
        if IsHandled then
            exit;

        SalesLine.Get(WarehouseShipmentLine."Source Subtype", WarehouseShipmentLine."Source No.", WarehouseShipmentLine."Source Line No.");
        SalesLine.AsmToOrderExists(AssemblyHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateQuantityToPick(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var QtyToPick: Decimal; var QtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage(var DoNotFillQtytoHandle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(var FirstActivityNo: Code[20]; var LastActivityNo: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnPreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseWkshLineFilters(var WhseWkshLine: Record "Whse. Worksheet Line"; WhseShipmentLine: Record "Warehouse Shipment Line"; WhseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPickingList(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSortWhseActivHeaders(var WhseActivHeader: Record "Warehouse Activity Header"; FirstActivityNo: Code[20]; LastActivityNo: Code[20]; var HideNothingToHandleError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseShipmentLine(WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; var SortActivity: Option; var AssignedID: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyLineDataItemOnBeforeOnAfterGetRecord(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGetRecordAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetResultMessageOnAfterShowResultMessage()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordWarehouseShipmentLineOnBeforeCreatePickTempLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreDataItemAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;
}

