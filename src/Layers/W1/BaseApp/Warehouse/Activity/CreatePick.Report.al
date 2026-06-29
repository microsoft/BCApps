// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Utilities;

report 5754 "Create Pick"
{
    Caption = 'Create Pick';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                PickWhseWkshLine.SetFilter("Qty. to Handle (Base)", '>%1', 0);
                PickWhseWkshLineFilter.CopyFilters(PickWhseWkshLine);

                if PickWhseWkshLine.Find('-') then begin
                    if PickWhseWkshLine."Location Code" = '' then
                        Location.Init()
                    else
                        Location.Get(PickWhseWkshLine."Location Code");
                    repeat
                        OnCheckSourceDocument(PickWhseWkshLine);
                        PickWhseWkshLine.CheckBin(PickWhseWkshLine."Location Code", PickWhseWkshLine."To Bin Code", true);
                        TempNo := TempNo + 1;

                        if PerWhseDoc then begin
                            PickWhseWkshLine.SetRange("Whse. Document Type", PickWhseWkshLine."Whse. Document Type");
                            PickWhseWkshLine.SetRange("Whse. Document No.", PickWhseWkshLine."Whse. Document No.");
                        end;
                        if PerDestination then begin
                            PickWhseWkshLine.SetRange("Destination Type", PickWhseWkshLine."Destination Type");
                            PickWhseWkshLine.SetRange("Destination No.", PickWhseWkshLine."Destination No.");
                            OnAfterGetRecordOnBeforeSetPickFiltersPerDestination(PickWhseWkshLine);
                            SetPickFilters();
                            PickWhseWkshLineFilter.CopyFilter("Destination Type", PickWhseWkshLine."Destination Type");
                            PickWhseWkshLineFilter.CopyFilter("Destination No.", PickWhseWkshLine."Destination No.");
                        end else begin
                            PickWhseWkshLineFilter.CopyFilter("Destination Type", PickWhseWkshLine."Destination Type");
                            PickWhseWkshLineFilter.CopyFilter("Destination No.", PickWhseWkshLine."Destination No.");
                            SetPickFilters();
                        end;
                        PickWhseWkshLineFilter.CopyFilter("Whse. Document Type", PickWhseWkshLine."Whse. Document Type");
                        PickWhseWkshLineFilter.CopyFilter("Whse. Document No.", PickWhseWkshLine."Whse. Document No.");
                        OnAfterGetRecordOnAfterPickWhseWkshLineFilterSetFilters(PickWhseWkshLineFilter, PickWhseWkshLine);
                    until not PickWhseWkshLine.Find('-');
                    CheckPickActivity();
                end else begin
                    IsHandled := false;
                    OnBeforeNothingToHandedErr(IsHandled, PickWhseWkshLineFilter);
                    if not IsHandled then
                        Error(NothingToHandedErr);
                end;
            end;

            trigger OnPreDataItem()
            var
                CreatePickParameters: Record "Create Pick Parameters";
            begin
                Clear(CreatePick);
                CreatePickParameters."Assigned ID" := AssignedID;
                CreatePickParameters."Sorting Method" := SortActivity;
                CreatePickParameters."Max No. of Lines" := MaxNoOfLines;
                CreatePickParameters."Max No. of Source Doc." := MaxNoOfSourceDoc;
                CreatePickParameters."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandleReq;
                CreatePickParameters."Breakbulk Filter" := BreakbulkFilter;
                CreatePickParameters."Per Bin" := PerBin;
                CreatePickParameters."Per Zone" := PerZone;
                CreatePickParameters."Whse. Document" := CreatePickParameters."Whse. Document"::"Pick Worksheet";
                CreatePickParameters."Whse. Document Type" := CreatePickParameters."Whse. Document Type"::Pick;
                OnPreDataItemOnBeforeCreatePickSetParameters(CreatePickParameters);

                CreatePick.SetParameters(CreatePickParameters);

                OnAfterIntegerOnPreDataItem();
            end;
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
                    group("Create Pick")
                    {
                        Caption = 'Create Pick';
                        field(PerWhseDoc; PerWhseDoc)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Whse. Document';
                            ToolTip = 'Specifies if you want to create separate pick documents for worksheet lines with the same warehouse source document.';
                        }
                        field(PerDestination; PerDestination)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Cust./Vend./Loc.';
                            ToolTip = 'Specifies if you want to create separate pick documents for each customer (sale orders), vendor (purchase return orders), and location (transfer orders).';
                        }
                        field(PerItem; PerItem)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Item';
                            ToolTip = 'Specifies if you want to create separate pick documents for each item in the pick worksheet.';
                        }
                        field(PerZone; PerZone)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per From Zone';
                            ToolTip = 'Specifies if you want to create separate pick documents for each zone that you will take the items from.';
                        }
                        field(PerBin; PerBin)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Bin';
                            ToolTip = 'Specifies if you want to create separate pick documents for each bin that you will take the items from.';
                        }
                        field(PerDate; PerDate)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Due Date';
                            ToolTip = 'Specifies if you want to create separate pick documents for source documents that have the same due date.';
                        }
                    }
                    field(MaxNoOfLines; MaxNoOfLines)
                    {
                        ApplicationArea = Warehouse;
                        BlankZero = true;
                        Caption = 'Max. No. of Pick Lines';
                        MinValue = 0;
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to create pick documents that have no more than the specified number of lines in each document.';
                    }
                    field(MaxNoOfSourceDoc; MaxNoOfSourceDoc)
                    {
                        ApplicationArea = Warehouse;
                        BlankZero = true;
                        Caption = 'Max. No. of Pick Source Docs.';
                        MinValue = 0;
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to create pick documents that each cover no more than the specified number of source documents.';
                    }
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
                            WhseEmployee.SetRange("Location Code", LocationCode);
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
                                WhseEmployee.Get(AssignedID, LocationCode);
                        end;
                    }
                    field(SortPick; SortActivity)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Sorting Method for Pick Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies that you want to select from the available options to sort lines in the created pick document.';
                    }
                    field(BreakbulkFilter; BreakbulkFilter)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Set Breakbulk Filter';
                        ToolTip = 'Specifies if you do not want to view the intermediate breakbulk pick lines, when a larger unit of measure is converted to a smaller unit of measure and completely picked.';
                    }
                    field(DoNotFillQtytoHandle; DoNotFillQtytoHandleReq)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Do Not Fill Qty. to Handle';
                        ToolTip = 'Specifies if you want to leave the Quantity to Handle field in the created pick lines empty.';
                    }
                    field(PrintPick; PrintPick)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Print Pick';
                        ToolTip = 'Specifies that you want to print the pick documents when they are created.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if LocationCode <> '' then begin
                Location.Get(LocationCode);
                if Location."Use ADCS" then
                    DoNotFillQtytoHandleReq := true;
            end;

            OnAfterOnOpenPage(DoNotFillQtytoHandleReq);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        OnAfterOnPostReport(FirstPickNo, LastPickNo)
    end;

    var
        Location: Record Location;
        PickWhseWkshLineFilter: Record "Whse. Worksheet Line";
        Cust: Record Customer;
        LocationCode: Code[10];
        AssignedID: Code[50];
        FirstSetPickNo: Code[20];
        MaxNoOfLines: Integer;
        TempNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'You can create a Pick only for the available quantity in %1 %2 = %3,%4 = %5,%6 = %7,%8 = %9.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        BreakbulkFilter: Boolean;

        NothingToHandedErr: Label 'There is nothing to handle, because the worksheet lines do not contain a value for quantity to handle.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Pick activity no. %1 has been created.';
        Text002: Label 'Pick activities no. %1 to %2 have been created.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        NothingToHandleErr: Label 'There is nothing to handle. %1.';
#pragma warning restore AA0470

    protected var
        PickWhseWkshLine: Record "Whse. Worksheet Line";
        CreatePick: Codeunit "Create Pick";
        FirstPickNo: Code[20];
        LastPickNo: Code[20];
        PerDestination: Boolean;
        PerItem: Boolean;
        PerZone: Boolean;
        PerBin: Boolean;
        PerWhseDoc: Boolean;
        PerDate: Boolean;
        PrintPick: Boolean;
        DoNotFillQtytoHandleReq: Boolean;
        MaxNoOfSourceDoc: Integer;
        SortActivity: Enum "Whse. Activity Sorting Method";

    local procedure CreateTempLine()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PickWhseActivHeader: Record "Warehouse Activity Header";
        TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
        PickQty: Decimal;
        PickQtyBase: Decimal;
        OldFirstSetPickNo: Code[20];
        TotalQtyPickedBase: Decimal;
        PickListReportID: Integer;
        IsHandled: Boolean;
    begin
        PickWhseWkshLine.LockTable();
        repeat
            if Location."Bin Mandatory" and
               (not Location."Always Create Pick Line")
            then begin
                IsHandled := false;
                OnCreateTempLineOnBeforeCalcAvailableQtyBase(PickWhseWkshLine, IsHandled);
                if not IsHandled then
                    if PickWhseWkshLine.CalcAvailableQtyBase() < PickWhseWkshLine."Qty. to Handle (Base)" then
                        Error(
                          Text003,
                          PickWhseWkshLine.TableCaption(), PickWhseWkshLine.FieldCaption("Worksheet Template Name"),
                          PickWhseWkshLine."Worksheet Template Name", PickWhseWkshLine.FieldCaption(Name),
                          PickWhseWkshLine.Name, PickWhseWkshLine.FieldCaption("Location Code"),
                          PickWhseWkshLine."Location Code", PickWhseWkshLine.FieldCaption("Line No."),
                          PickWhseWkshLine."Line No.");
            end;

            PickWhseWkshLine.TestField("Qty. per Unit of Measure");
            CreatePick.SetWhseWkshLine(PickWhseWkshLine, TempNo);
            IsHandled := false;
            OnCreateTempLineOnBeforeSetTempWhseItemTrackingLine(PickWhseWkshLine, PickQty, PickQtyBase, IsHandled);
            if not IsHandled then begin
                case PickWhseWkshLine."Whse. Document Type" of
                    PickWhseWkshLine."Whse. Document Type"::Shipment:
                        begin
                            WarehouseShipmentLine.Get(PickWhseWkshLine."Whse. Document No.", PickWhseWkshLine."Whse. Document Line No.");
                            if not WarehouseShipmentLine."Assemble to Order" then
                                CreatePick.SetTempWhseItemTrkgLine(
                                  PickWhseWkshLine."Whse. Document No.", Database::"Warehouse Shipment Line", '', 0,
                                  PickWhseWkshLine."Whse. Document Line No.", PickWhseWkshLine."Location Code")
                            else
                                CreatePick.SetTempWhseItemTrkgLine(
                                  PickWhseWkshLine."Source No.", Database::"Assembly Line", '', 0,
                                  PickWhseWkshLine."Source Line No.", PickWhseWkshLine."Location Code");
                        end;
                    PickWhseWkshLine."Whse. Document Type"::Assembly:
                        CreatePick.SetTempWhseItemTrkgLine(
                          PickWhseWkshLine."Whse. Document No.", Database::"Assembly Line", '', 0,
                          PickWhseWkshLine."Whse. Document Line No.", PickWhseWkshLine."Location Code");
                    PickWhseWkshLine."Whse. Document Type"::"Internal Pick":
                        CreatePick.SetTempWhseItemTrkgLine(
                          PickWhseWkshLine."Whse. Document No.", Database::"Whse. Internal Pick Line", '', 0,
                          PickWhseWkshLine."Whse. Document Line No.", PickWhseWkshLine."Location Code");
                    PickWhseWkshLine."Whse. Document Type"::Production:
                        CreatePick.SetTempWhseItemTrkgLine(
                          PickWhseWkshLine."Source No.", PickWhseWkshLine."Source Type", '', PickWhseWkshLine."Source Line No.",
                          PickWhseWkshLine."Source Subline No.", PickWhseWkshLine."Location Code");
                    PickWhseWkshLine."Whse. Document Type"::Job:
                        CreatePick.SetTempWhseItemTrkgLine(
                          PickWhseWkshLine."Source No.", Database::"Job Planning Line", '', 0,
                          PickWhseWkshLine."Source Line No.", PickWhseWkshLine."Location Code");
                    else // Movement Worksheet Line
                        CreatePick.SetTempWhseItemTrkgLine(
                          PickWhseWkshLine.Name, 5407, PickWhseWkshLine."Worksheet Template Name", // Database::"Prod. Order Component"
                          0, PickWhseWkshLine."Line No.", PickWhseWkshLine."Location Code");
                end;

                PickQty := PickWhseWkshLine."Qty. to Handle";
                PickQtyBase := PickWhseWkshLine."Qty. to Handle (Base)";
            end;
            OnAfterSetQuantityToPick(PickWhseWkshLine, PickQty, PickQtyBase);
            if (PickQty > 0) and
               (PickWhseWkshLine."Destination Type" = PickWhseWkshLine."Destination Type"::Customer)
            then begin
                PickWhseWkshLine.TestField("Destination No.");
                Cust.Get(PickWhseWkshLine."Destination No.");
                IsHandled := false;
                OnCreateTempLineOnBeforeCustCheckBlockedCustOnDocs(PickWhseWkshLine, IsHandled);
                if not IsHandled then
                    case PickWhseWkshLine."Source Document" of
                        PickWhseWkshLine."Source Document"::"Sales Order":
                            Cust.CheckBlockedCustOnDocs(Cust, "Sales Document Type"::Order, false, false);
                        PickWhseWkshLine."Source Document"::"Sales Return Order":
                            Cust.CheckBlockedCustOnDocs(Cust, "Sales Document Type"::"Return Order", false, false);
                    end;
            end;

            CreatePick.SetCalledFromWksh(true);

            IsHandled := false;
            OnCreateTempLineOnBeforeCreatePickCreateTempLine(PickWhseWkshLine, TempWhseItemTrkgLine, PickQty, PickQtyBase, TotalQtyPickedBase, IsHandled);
            if not IsHandled then
                CreatePick.CreateTempLine(
                    PickWhseWkshLine."Location Code", PickWhseWkshLine."Item No.", PickWhseWkshLine."Variant Code",
                    PickWhseWkshLine."Unit of Measure Code", '', PickWhseWkshLine."To Bin Code", PickWhseWkshLine."Qty. per Unit of Measure",
                    PickWhseWkshLine."Qty. Rounding Precision", PickWhseWkshLine."Qty. Rounding Precision (Base)", PickQty, PickQtyBase);

            TotalQtyPickedBase := CreatePick.GetActualQtyPickedBase();

            // Update/delete lines
            PickWhseWkshLine."Qty. to Handle (Base)" := PickWhseWkshLine.CalcBaseQty(PickWhseWkshLine."Qty. to Handle");
            IsHandled := false;
            OnCreateTempLineOnBeforeDeleteOrModifyPickWhseWorksheetLine(PickWhseWkshLine, TotalQtyPickedBase, PickQtyBase, IsHandled);
            if not IsHandled then
                if PickWhseWkshLine."Qty. (Base)" =
                   PickWhseWkshLine."Qty. Handled (Base)" + TotalQtyPickedBase
                then
                    PickWhseWkshLine.Delete(true)
                else begin
                    PickWhseWkshLine."Qty. Handled" := PickWhseWkshLine."Qty. Handled" + PickWhseWkshLine.CalcQty(TotalQtyPickedBase);
                    PickWhseWkshLine."Qty. Handled (Base)" := PickWhseWkshLine.CalcBaseQty(PickWhseWkshLine."Qty. Handled");
                    PickWhseWkshLine."Qty. Outstanding" := PickWhseWkshLine.Quantity - PickWhseWkshLine."Qty. Handled";
                    PickWhseWkshLine."Qty. Outstanding (Base)" := PickWhseWkshLine.CalcBaseQty(PickWhseWkshLine."Qty. Outstanding");
                    PickWhseWkshLine."Qty. to Handle" := 0;
                    PickWhseWkshLine."Qty. to Handle (Base)" := 0;
                    OnBeforePickWhseWkshLineModify(PickWhseWkshLine);
                    PickWhseWkshLine.Modify();
                end;
        until PickWhseWkshLine.Next() = 0;

        IsHandled := false;
        OnCreateTempLineOnBeforeSetOldFirstSetPickNo(PickWhseWkshLine, IsHandled);
        if not IsHandled then begin
            OldFirstSetPickNo := FirstSetPickNo;
            OnBeforeCreatePickWhseDocument(PickWhseWkshLine);
            CreatePick.CreateWhseDocument(FirstSetPickNo, LastPickNo, false);
            if FirstSetPickNo = OldFirstSetPickNo then
                exit;

            if FirstPickNo = '' then
                FirstPickNo := FirstSetPickNo;
            CreatePick.ReturnTempItemTrkgLines(TempWhseItemTrkgLine);
            ItemTrackingMgt.UpdateWhseItemTrkgLines(TempWhseItemTrkgLine);
            Commit();
        end;

        PickWhseActivHeader.SetRange(Type, PickWhseActivHeader.Type::Pick);
        PickWhseActivHeader.SetRange("No.", FirstSetPickNo, LastPickNo);
        PickWhseActivHeader.Find('-');
        repeat
            if SortActivity <> SortActivity::None then
                PickWhseActivHeader.SortWhseDoc();
            Commit();
            if PrintPick then begin
                PickListReportID := Report::"Picking List";
                OnBeforePrintPickList(PickWhseActivHeader, PickListReportID, IsHandled);
                if not IsHandled then
                    WarehouseDocumentPrint.PrintPickHeader(PickWhseActivHeader);
            end;
        until PickWhseActivHeader.Next() = 0;
    end;

    procedure SetWkshPickLine(var PickWhseWkshLine2: Record "Whse. Worksheet Line")
    var
        SortingMethod: Option;
    begin
        PickWhseWkshLine.CopyFilters(PickWhseWkshLine2);
        LocationCode := PickWhseWkshLine2."Location Code";

        SortingMethod := SortActivity.AsInteger();
        OnAfterSetWkshPickLine(PickWhseWkshLine2, SortingMethod);
        SortActivity := "Whse. Activity Sorting Method".FromInteger(SortingMethod);
    end;

    procedure GetResultMessage() ReturnValue: Boolean
    begin
        if FirstPickNo <> '' then
            if FirstPickNo = LastPickNo then
                Message(Text001, FirstPickNo)
            else
                Message(Text002, FirstPickNo, LastPickNo);
        ReturnValue := FirstPickNo <> '';
        OnAfterGetResultMessage(ReturnValue);
        exit(ReturnValue);
    end;

    procedure InitializeReport(AssignedID2: Code[50]; MaxNoOfLines2: Integer; MaxNoOfSourceDoc2: Integer; SortPick2: Enum "Whse. Activity Sorting Method"; PerDestination2: Boolean;
                                                                                                                         PerItem2: Boolean;
                                                                                                                         PerZone2: Boolean;
                                                                                                                         PerBin2: Boolean;
                                                                                                                         PerWhseDoc2: Boolean;
                                                                                                                         PerDate2: Boolean;
                                                                                                                         PrintPick2: Boolean;
                                                                                                                         DoNotFillQtytoHandle2: Boolean;
                                                                                                                         BreakbulkFilter2: Boolean)
    begin
        AssignedID := AssignedID2;
        MaxNoOfLines := MaxNoOfLines2;
        MaxNoOfSourceDoc := MaxNoOfSourceDoc2;
        SortActivity := SortPick2;
        PerDestination := PerDestination2;
        PerItem := PerItem2;
        PerZone := PerZone2;
        PerBin := PerBin2;
        PerWhseDoc := PerWhseDoc2;
        PerDate := PerDate2;
        PrintPick := PrintPick2;
        DoNotFillQtytoHandleReq := DoNotFillQtytoHandle2;
        BreakbulkFilter := BreakbulkFilter2;
    end;

    local procedure CheckPickActivity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPickActivity(IsHandled, FirstPickNo);
        if IsHandled then
            exit;

        if FirstPickNo = '' then
            Error(NothingToHandleErr, CreatePick.GetCannotBeHandledReason());
    end;

    local procedure SetPickFilters()
    begin
        OnBeforeSetPickFilters(PickWhseWkshLine);

        if PerItem then begin
            PickWhseWkshLine.SetRange("Item No.", PickWhseWkshLine."Item No.");
            if PerBin then
                SetPerBinFilters()
            else begin
                if not Location."Bin Mandatory" then
                    PickWhseWkshLineFilter.CopyFilter("Shelf No.", PickWhseWkshLine."Shelf No.");
                SetPerDateFilters();
            end;
            PickWhseWkshLineFilter.CopyFilter("Item No.", PickWhseWkshLine."Item No.");
        end else begin
            PickWhseWkshLineFilter.CopyFilter("Item No.", PickWhseWkshLine."Item No.");
            if PerBin then
                SetPerBinFilters()
            else begin
                if not Location."Bin Mandatory" then
                    PickWhseWkshLineFilter.CopyFilter("Shelf No.", PickWhseWkshLine."Shelf No.");
                SetPerDateFilters();
            end;
        end;

        OnAfterSetPickFilters(PickWhseWkshLine, PickWhseWkshLineFilter);
    end;

    local procedure SetPerBinFilters()
    begin
        if not Location."Bin Mandatory" then
            PickWhseWkshLine.SetRange("Shelf No.", PickWhseWkshLine."Shelf No.");
        if PerDate then begin
            PickWhseWkshLine.SetRange("Due Date", PickWhseWkshLine."Due Date");
            CreateTempLine();
            PickWhseWkshLineFilter.CopyFilter("Due Date", PickWhseWkshLine."Due Date");
        end else begin
            PickWhseWkshLineFilter.CopyFilter("Due Date", PickWhseWkshLine."Due Date");
            CreateTempLine();
        end;
        if not Location."Bin Mandatory" then
            PickWhseWkshLineFilter.CopyFilter("Shelf No.", PickWhseWkshLine."Shelf No.");
    end;

    local procedure SetPerDateFilters()
    begin
        if PerDate then begin
            PickWhseWkshLine.SetRange("Due Date", PickWhseWkshLine."Due Date");
            CreateTempLine();
            PickWhseWkshLineFilter.CopyFilter("Due Date", PickWhseWkshLine."Due Date");
        end else begin
            PickWhseWkshLineFilter.CopyFilter("Due Date", PickWhseWkshLine."Due Date");
            CreateTempLine();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetResultMessage(var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage(var DoNotFillQtytoHandle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPostReport(FirstPickNo: Code[20]; LastPickNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQuantityToPick(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var PickQty: Decimal; var PickQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPickFilters(var PickWhseWkshLine: Record "Whse. Worksheet Line"; var PickWhseWkshLineFilter: Record "Whse. Worksheet Line");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIntegerOnPreDataItem()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPickActivity(var IsHandled: Boolean; FirstPickNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickWhseDocument(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNothingToHandedErr(var IsHandled: Boolean; var PickWhseWkshLineFilter: Record "Whse. Worksheet Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickWhseWkshLineModify(var PickWhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPickList(var PickWhseActivHeader: Record "Warehouse Activity Header"; var PickListReportID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPickFilters(var PickWhseWkshLine: Record "Whse. Worksheet Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWkshPickLine(PickWhseWkshLine: Record "Whse. Worksheet Line"; var SortPick: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnBeforeSetPickFiltersPerDestination(var PickWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterPickWhseWkshLineFilterSetFilters(var PickWhseWkshLineFilter: Record "Whse. Worksheet Line"; var PickWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreDataItemOnBeforeCreatePickSetParameters(var CreatePickParameters: Record "Create Pick Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeCustCheckBlockedCustOnDocs(PickWhseWkshLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateTempLineOnBeforeCreatePickCreateTempLine(PickWhseWkshLine: Record "Whse. Worksheet Line"; TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var PickQty: Decimal; var PickQtyBase: Decimal; var TotalQtyPickedBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocument(var PickWhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeCalcAvailableQtyBase(PickWhseWorksheetLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateTempLineOnBeforeSetTempWhseItemTrackingLine(var PickWhseWorksheetLine: Record "Whse. Worksheet Line"; var PickQty: Decimal; var PickQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateTempLineOnBeforeDeleteOrModifyPickWhseWorksheetLine(var PickWhseWorksheetLine: Record "Whse. Worksheet Line"; var TotalQtyPickedBase: Decimal; var PickQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateTempLineOnBeforeSetOldFirstSetPickNo(var PickWhseWorksheetLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean)
    begin
    end;
}

