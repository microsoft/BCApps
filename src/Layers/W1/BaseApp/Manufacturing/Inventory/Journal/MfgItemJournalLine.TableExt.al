// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.CRM.Team;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Posting;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Warehouse.Request;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Inventory.Location;

tableextension 99000758 "Mfg. Item Journal Line" extends "Item Journal Line"
{
    fields
    {
        field(5838; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
            TableRelation = if ("Order Type" = const(Production)) "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                                                                  "Prod. Order No." = field("Order No."),
                                                                                                                  "Routing No." = field("Routing No."),
                                                                                                                  "Routing Reference No." = field("Routing Reference No."));

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                TestField("Entry Type", "Entry Type"::Output);
                if "Operation No." = '' then
                    exit;

                TestField("Order Type", "Order Type"::Production);
                TestField("Order No.");
                TestField("Item No.");

                CheckConfirmOutputOnFinishedOperation();
                GetProdOrderRoutingLine(ProdOrderRtngLine);

                case ProdOrderRtngLine.Type of
                    ProdOrderRtngLine.Type::"Work Center":
                        Type := Type::"Work Center";
                    ProdOrderRtngLine.Type::"Machine Center":
                        Type := Type::"Machine Center";
                end;
                Validate("No.", ProdOrderRtngLine."No.");
                Description := ProdOrderRtngLine.Description;
            end;
        }
        field(5849; "Concurrent Capacity"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Concurrent Capacity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                WorkCenter: Record "Work Center";
                ShopCalendarMgt: Codeunit "Shop Calendar Management";
                TotalTime: Integer;
            begin
                TestField("Entry Type", "Entry Type"::Output);
                if "Concurrent Capacity" = 0 then
                    exit;

                TestField("Starting Time");
                TestField("Ending Time");
                TotalTime := ShopCalendarMgt.CalcTimeDelta("Ending Time", "Starting Time");
                OnValidateConcurrentCapacityOnAfterCalcTotalTime(Rec, TotalTime, xRec);
                if "Ending Time" < "Starting Time" then
                    TotalTime := TotalTime + 86400000;
                TestField("Work Center No.");
                WorkCenter.Get("Work Center No.");
                Validate("Setup Time", 0);
                Validate(
                  "Run Time",
                  Round(
                    TotalTime / ShopCalendarMgt.TimeFactor("Cap. Unit of Measure Code") *
                    "Concurrent Capacity", WorkCenter."Calendar Rounding Precision"));
            end;
        }
        field(5839; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center";

            trigger OnValidate()
            begin
                ErrorIfSubcontractingWorkCenterUsed();
            end;
        }
        field(5841; "Setup Time"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Setup Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if SubcontractingWorkCenterUsed() and ("Setup Time" <> 0) then
                    Error(SubcontractedErr, FieldCaption("Setup Time"), "Line No.");
                "Setup Time (Base)" := CalcBaseTime("Setup Time");
            end;
        }
        field(5842; "Run Time"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Run Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if SubcontractingWorkCenterUsed() and ("Run Time" <> 0) then
                    Error(SubcontractedErr, FieldCaption("Run Time"), "Line No.");

                "Run Time (Base)" := CalcBaseTime("Run Time");
            end;
        }
        field(5843; "Stop Time"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Stop Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Stop Time (Base)" := CalcBaseTime("Stop Time");
            end;
        }
        field(5846; "Output Quantity"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Output Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                Item: Record Item;
                WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
            begin
                TestField("Entry Type", "Entry Type"::Output);
                if SubcontractingWorkCenterUsed() and ("Output Quantity" <> 0) then
                    Error(SubcontractedErr, FieldCaption("Output Quantity"), "Line No.");

                CheckConfirmOutputOnFinishedOperation();

                if LastOutputOperation(Rec) then begin
                    Item.Get("Item No.");
                    if Item.IsInventoriableType() then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
                end;

                "Output Quantity (Base)" := CalcBaseQty("Output Quantity", FieldCaption("Output Quantity"), FieldCaption("Output Quantity (Base)"));

                Validate(Quantity, "Output Quantity");
                ValidateQuantityIsBalanced();
            end;
        }
        field(5847; "Scrap Quantity"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Scrap Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Output);
                "Scrap Quantity (Base)" := CalcBaseQty("Scrap Quantity", FieldCaption("Scrap Quantity"), FieldCaption("Scrap Quantity (Base)"));
            end;
        }
        field(5851; "Setup Time (Base)"; Decimal)
        {
            Caption = 'Setup Time (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Cap. Unit of Measure", 1);
                Validate("Setup Time", "Setup Time (Base)");
            end;
        }
        field(5852; "Run Time (Base)"; Decimal)
        {
            Caption = 'Run Time (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Cap. Unit of Measure", 1);
                Validate("Run Time", "Run Time (Base)");
            end;
        }
        field(5853; "Stop Time (Base)"; Decimal)
        {
            Caption = 'Stop Time (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Cap. Unit of Measure", 1);
                Validate("Stop Time", "Stop Time (Base)");
            end;
        }
        field(5856; "Output Quantity (Base)"; Decimal)
        {
            Caption = 'Output Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateOutputQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Output Quantity", "Output Quantity (Base)");
            end;
        }
        field(5857; "Scrap Quantity (Base)"; Decimal)
        {
            Caption = 'Scrap Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateScrapQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Scrap Quantity", "Scrap Quantity (Base)");
            end;
        }
        field(5873; "Starting Time"; Time)
        {
            AccessByPermission = TableData "Machine Center" = R;
            DataClassification = CustomerContent;
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                if "Ending Time" < "Starting Time" then
                    "Ending Time" := "Starting Time";

                Validate("Concurrent Capacity");
            end;
        }
        field(5874; "Ending Time"; Time)
        {
            AccessByPermission = TableData "Machine Center" = R;
            DataClassification = CustomerContent;
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                Validate("Concurrent Capacity");
            end;
        }
        field(5882; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Routing Header";
        }
        field(5883; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            DataClassification = CustomerContent;
        }
        field(5884; "Prod. Order Comp. Line No."; Integer)
        {
            Caption = 'Prod. Order Comp. Line No.';
            DataClassification = CustomerContent;
            TableRelation = if ("Order Type" = const(Production)) "Prod. Order Component"."Line No." where(Status = const(Released),
                                                                                                          "Prod. Order No." = field("Order No."),
                                                                                                          "Prod. Order Line No." = field("Order Line No."));

            trigger OnValidate()
            var
                ProdOrderComponent: Record "Prod. Order Component";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateProdOrderCompLineNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Prod. Order Comp. Line No." <> xRec."Prod. Order Comp. Line No." then begin
                    if ("Order Type" = "Order Type"::Production) and ("Prod. Order Comp. Line No." <> 0) then begin
                        ProdOrderComponent.Get(
                          ProdOrderComponent.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.");
                        if "Item No." <> ProdOrderComponent."Item No." then
                            Validate("Item No.", ProdOrderComponent."Item No.");
                    end;

                    CreateProdDim();
                end;
            end;
        }
        field(5885; Finished; Boolean)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Finished';
            DataClassification = CustomerContent;
        }
        field(5895; "Stop Code"; Code[10])
        {
            Caption = 'Stop Code';
            DataClassification = CustomerContent;
            TableRelation = Stop;
        }
        field(5896; "Scrap Code"; Code[10])
        {
            Caption = 'Scrap Code';
            DataClassification = CustomerContent;
            TableRelation = Scrap;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateScrapCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if not (Type in [Type::"Work Center", Type::"Machine Center"]) then
                    Error(ScrapCodeTypeErr);
            end;
        }
        field(5898; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center Group";
        }
        field(5899; "Work Shift Code"; Code[10])
        {
            Caption = 'Work Shift Code';
            DataClassification = CustomerContent;
            TableRelation = "Work Shift";
        }
        field(5900; "Rev. Capacity Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Capacity Ledger Entry No.';
            DataClassification = CustomerContent;
            TableRelation = Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
        }

        modify("No.")
        {
            TableRelation = if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center";
        }
        modify("Order No.")
        {
            TableRelation = if ("Order Type" = const(Production)) "Production Order"."No." where(Status = const(Released));
        }
        modify("Order Line No.")
        {
            TableRelation = if ("Order Type" = const(Production)) "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                                                     "Prod. Order No." = field("Order No."));
        }
    }

    var
        UOMMgt: Codeunit "Unit of Measure Management";

        DifferentBinCodeQst: Label 'The entered bin code %1 is different from the bin code %2 in production order component %3.\\Are you sure that you want to post the consumption from bin code %1?', Comment = '%1, %2 - bin code, %3 - prod. order component';
        FinishedOutputQst: Label 'The operation has been finished. Do you want to post output for the finished operation?';
        ScrapCodeTypeErr: Label 'When using Scrap Code, Type must be Work Center or Machine Center.';
        SubcontractedErr: Label '%1 must be zero in line number %2 because it is linked to the subcontracted work center.', Comment = '%1 - Field Caption, %2 - Line No.';
        UpdateInterruptedErr: Label 'The update has been interrupted to respect the warning.';

    local procedure CalcBaseTime(Qty: Decimal): Decimal
    begin
        if "Run Time" <> 0 then
            TestField("Qty. per Cap. Unit of Measure");
        exit(Round(Qty * "Qty. per Cap. Unit of Measure", UOMMgt.TimeRndPrecision()));
    end;

    local procedure CheckConfirmOutputOnFinishedOperation()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if ("Entry Type" <> "Entry Type"::Output) or ("Output Quantity" = 0) then
            exit;

        if not ProdOrderRtngLine.Get(
             ProdOrderRtngLine.Status::Released, "Order No.", "Routing Reference No.", "Routing No.", "Operation No.")
        then
            exit;

        if ProdOrderRtngLine."Routing Status" <> ProdOrderRtngLine."Routing Status"::Finished then
            exit;

        ConfirmOutputOnFinishedOperation();
    end;

    local procedure ConfirmOutputOnFinishedOperation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmOutputOnFinishedOperation(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Confirm(FinishedOutputQst) then
            Error(UpdateInterruptedErr);
    end;

    procedure CheckProdOrderCompBinCode()
    var
        ProdOrderComp: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderCompBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComp.Get(ProdOrderComp.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.");
        if (ProdOrderComp."Bin Code" <> '') and (ProdOrderComp."Bin Code" <> "Bin Code") then
            if not Confirm(
                 DifferentBinCodeQst,
                 false,
                 "Bin Code",
                 ProdOrderComp."Bin Code",
                 "Order No.")
            then
                Error(UpdateInterruptedErr);
    end;

    procedure CopyFromProdOrderComp(ProdOrderComp: Record "Prod. Order Component")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromProdOrderComp(Rec, ProdOrderComp, IsHandled);
        if IsHandled then
            exit;

        Validate("Order Line No.", ProdOrderComp."Prod. Order Line No.");
        Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        "Unit of Measure Code" := ProdOrderComp."Unit of Measure Code";
        "Location Code" := ProdOrderComp."Location Code";
        Validate("Variant Code", ProdOrderComp."Variant Code");
        Validate("Bin Code", ProdOrderComp."Bin Code");

        OnAfterCopyFromProdOrderComp(Rec, ProdOrderComp);
    end;

    procedure CopyFromProdOrderLine(ProdOrderLine: Record "Prod. Order Line")
    begin
        Validate("Order Line No.", ProdOrderLine."Line No.");
        "Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        "Location Code" := ProdOrderLine."Location Code";
        Validate("Variant Code", ProdOrderLine."Variant Code");
        Validate("Bin Code", ProdOrderLine."Bin Code");

        OnAfterCopyFromProdOrderLine(Rec, ProdOrderLine);
    end;

    procedure CopyFromWorkCenter(WorkCenter: Record "Work Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromWorkCenter(Rec, WorkCenter, IsHandled);
        if IsHandled then
            exit;

        "Work Center No." := WorkCenter."No.";
        Description := WorkCenter.Name;
        "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
        "Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";

        OnAfterCopyFromWorkCenter(Rec, WorkCenter);
    end;

    procedure CopyFromMachineCenter(MachineCenter: Record "Machine Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromMachineCenter(Rec, MachineCenter, IsHandled);
        if IsHandled then
            exit;

        "Work Center No." := MachineCenter."Work Center No.";
        Description := MachineCenter.Name;
        "Gen. Prod. Posting Group" := MachineCenter."Gen. Prod. Posting Group";
        "Unit Cost Calculation" := "Unit Cost Calculation"::Time;

        OnAfterCopyFromMachineCenter(Rec, MachineCenter);
    end;

    /// <summary>
    /// Creates and assigns a dimension set ID to an item journal line record based on the dimensions of the associated 
    /// production order, production order line, and production order component.
    /// </summary>
    procedure CreateProdDim()
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        DimSetIDArr: array[10] of Integer;
        i: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateProdDim(Rec, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := 0;
        if ("Order Type" <> "Order Type"::Production) or ("Order No." = '') then
            exit;
        ProdOrder.Get(ProdOrder.Status::Released, "Order No.");
        i := 1;
        DimSetIDArr[i] := ProdOrder."Dimension Set ID";
        if "Order Line No." <> 0 then begin
            i := i + 1;
            ProdOrderLine.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.");
            DimSetIDArr[i] := ProdOrderLine."Dimension Set ID";
        end;

        IsHandled := false;
        OnCreateProdDimOnBeforeCreateDimSetIDArr(Rec, DimSetIDArr, IsHandled);
        if not IsHandled then
            if "Prod. Order Comp. Line No." <> 0 then begin
                i := i + 1;
                ProdOrderComp.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.");
                DimSetIDArr[i] := ProdOrderComp."Dimension Set ID";
            end;

        OnCreateProdDimOnAfterCreateDimSetIDArr(Rec, DimSetIDArr, i);
        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure CreateDimWithProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        InheritFromDimSetID: Integer;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        if "Order Type" = "Order Type"::Production then
            if ProdOrderLine.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.") then
                InheritFromDimSetID := ProdOrderLine."Dimension Set ID";

        DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", Rec."Work Center No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code");
        OnCreateDimWithProdOrderLineOnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, Rec.FieldNo("No."));
        CreateDim(DefaultDimSource, InheritFromDimSetID, Database::Item);
    end;

    procedure GetProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetProdOrderRoutingLine(ProdOrderRoutingLine, Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Order Type", "Order Type"::Production);
        TestField("Order No.");
        TestField("Operation No.");

        ProdOrderRoutingLine.Get(
            ProdOrderRoutingLine.Status::Released, "Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
    end;

    procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"): Boolean
    var
        IsHandled: Boolean;
        RecordCount: Integer;
    begin
        ProdOrderComponent.SetFilterByReleasedOrderNo("Order No.");
        if "Order Line No." <> 0 then
            ProdOrderComponent.SetRange("Prod. Order Line No.", "Order Line No.");
        ProdOrderComponent.SetRange("Line No.", "Prod. Order Comp. Line No.");
        IsHandled := false;
        OnValidateItemNoOnAfterProdOrderCompSetFilters(Rec, ProdOrderComponent, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComponent.SetRange("Item No.", "Item No.");
        RecordCount := ProdOrderComponent.Count();
        if RecordCount > 1 then
            exit(false)
        else
            if RecordCount = 1 then
                exit(ProdOrderComponent.FindFirst());

        ProdOrderComponent.SetRange("Line No.");
        if ProdOrderComponent.Count() = 1 then
            exit(ProdOrderComponent.FindFirst());

        exit(false);
    end;

    procedure ErrorIfSubcontractingWorkCenterUsed()
    begin
        if not SubcontractingWorkCenterUsed() then
            exit;
        if "Setup Time" <> 0 then
            Error(ErrorInfo.Create(StrSubstNo(SubcontractedErr, FieldCaption("Setup Time"), "Line No."), true));
        if "Run Time" <> 0 then
            Error(ErrorInfo.Create(StrSubstNo(SubcontractedErr, FieldCaption("Run Time"), "Line No."), true));
        if "Output Quantity" <> 0 then
            Error(ErrorInfo.Create(StrSubstNo(SubcontractedErr, FieldCaption("Output Quantity"), "Line No."), true));
    end;

    /// <summary>
    /// Determines if the next operation number on the associated production order routing line exists.
    /// </summary>
    /// <remarks>
    /// If item journal line entry type is not output, it returns true.
    /// </remarks>
    /// <returns>True if next operation number does not exists, otherwise false.</returns>
    procedure ItemPosting() Result: Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NextOperationNoIsEmpty: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeItemPosting(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ("Entry Type" = "Entry Type"::Output) and ("Output Quantity" <> 0) and ("Operation No." <> '') then begin
            GetProdOrderRoutingLine(ProdOrderRoutingLine);
            IsHandled := false;
            OnAfterItemPosting(ProdOrderRoutingLine, NextOperationNoIsEmpty, IsHandled);
            if IsHandled then
                exit(NextOperationNoIsEmpty);
            exit(ProdOrderRoutingLine."Next Operation No." = '');
        end;

        exit(true);
    end;

    /// <summary>
    /// Determines whether the operation specified in the provided item journal line record is the last output operation 
    /// in the associated production order routing line.
    /// </summary>
    /// <param name="ItemJnlLine">Item journal line to check.</param>
    /// <returns>True if this is the last output operation, otherwise false.</returns>
    procedure LastOutputOperation(ItemJnlLine2: Record "Item Journal Line") Result: Boolean
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        Operation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLastOutputOperation(ItemJnlLine2, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ItemJnlLine2."Operation No." <> '' then begin
            IsHandled := false;
            OnLastOutputOperationOnBeforeTestRoutingNo(ItemJnlLine2, IsHandled);
            if not IsHandled then
                ItemJnlLine2.TestField("Routing No.");
            if not ProdOrderRtngLine.Get(
                 ProdOrderRtngLine.Status::Released, ItemJnlLine2."Order No.",
                 ItemJnlLine2."Routing Reference No.", ItemJnlLine2."Routing No.", ItemJnlLine2."Operation No.")
            then
                ProdOrderRtngLine.Get(
                  ProdOrderRtngLine.Status::Finished, ItemJnlLine2."Order No.",
                  ItemJnlLine2."Routing Reference No.", ItemJnlLine2."Routing No.", ItemJnlLine2."Operation No.");
            if ItemJnlLine2.Finished then
                ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::Finished
            else
                ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::"In Progress";
            Operation := not ProdOrderRtngLine.NextOperationExist();
        end else
            Operation := true;
        exit(Operation);
    end;

    procedure LookupProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderLineList: Page "Prod. Order Line List";
    begin
        ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
        ProdOrderLine.Status := ProdOrderLine.Status::Released;
        ProdOrderLine."Prod. Order No." := "Order No.";
        ProdOrderLine."Line No." := "Order Line No.";
        ProdOrderLine."Item No." := "Item No.";
        ProdOrderLine."Variant Code" := "Variant Code";

        ProdOrderLineList.LookupMode(true);
        ProdOrderLineList.SetTableView(ProdOrderLine);
        ProdOrderLineList.SetRecord(ProdOrderLine);

        if ProdOrderLineList.RunModal() = ACTION::LookupOK then begin
            ProdOrderLineList.GetRecord(ProdOrderLine);
            Validate("Item No.", ProdOrderLine."Item No.");
            if (ProdOrderLine."Variant Code" <> '') and ("Variant Code" <> ProdOrderLine."Variant Code") then
                Validate("Variant Code", ProdOrderLine."Variant Code");
            if "Order Line No." <> ProdOrderLine."Line No." then
                Validate("Order Line No.", ProdOrderLine."Line No.");
        end;
    end;

    procedure LookupProdOrderComp()
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderCompLineList: Page "Prod. Order Comp. Line List";
        IsHandled: Boolean;
    begin
        ProdOrderComp.SetFilterByReleasedOrderNo("Order No.");
        if "Order Line No." <> 0 then
            ProdOrderComp.SetRange("Prod. Order Line No.", "Order Line No.");
        ProdOrderComp.Status := ProdOrderComp.Status::Released;
        ProdOrderComp."Prod. Order No." := "Order No.";
        ProdOrderComp."Prod. Order Line No." := "Order Line No.";
        ProdOrderComp."Line No." := "Prod. Order Comp. Line No.";
        ProdOrderComp."Item No." := "Item No.";

        ProdOrderCompLineList.LookupMode(true);
        OnLookupProdOrderCompOnBeforeSetTableView(ProdOrderComp, Rec);
        ProdOrderCompLineList.SetTableView(ProdOrderComp);
        ProdOrderCompLineList.SetRecord(ProdOrderComp);

        IsHandled := false;
        OnLookupProdOrderCompBeforeRunModal(ProdOrderComp, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderCompLineList.RunModal() = ACTION::LookupOK then begin
            ProdOrderCompLineList.GetRecord(ProdOrderComp);
            if "Prod. Order Comp. Line No." <> ProdOrderComp."Line No." then begin
                Validate("Item No.", ProdOrderComp."Item No.");
                Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
            end;
        end;
    end;

    /// <summary>
    /// Determines if an output value posting should be performed for an item journal line.
    /// </summary>
    /// <returns>True if output posting should be performed, otherwise false.</returns>
    procedure OutputValuePosting() Result: Boolean
    begin
        Result := TimeIsEmpty() and ("Invoiced Quantity" <> 0) and not Subcontracting;
        OnAfterOutputValuePosting(Rec, Result);
    end;

    /// <summary>
    /// Posts an item journal line record from a production order.
    /// </summary>
    /// <param name="Print">If true, additional functionality of printing documents is executed.</param>
    procedure PostingItemJnlFromProduction(Print: Boolean)
    var
        ProductionOrder: Record "Production Order";
        IsHandled: Boolean;
    begin
        if ("Order Type" = "Order Type"::Production) and ("Order No." <> '') then
            ProductionOrder.Get(ProductionOrder.Status::Released, "Order No.");

        IsHandled := false;
        OnBeforePostingItemJnlFromProduction(Rec, Print, IsHandled);
        if IsHandled then
            exit;

        if Print then
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post+Print", Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post", Rec);
    end;

    internal procedure PreviewPostItemJnlFromProduction()
    var
        ProductionOrder: Record "Production Order";
        ItemJnlPost: Codeunit "Item Jnl.-Post";
    begin
        if ("Order Type" = "Order Type"::Production) and ("Order No." <> '') then
            ProductionOrder.Get(ProductionOrder.Status::Released, "Order No.");

        ItemJnlPost.Preview(Rec);
    end;

    /// <summary>
    /// Determines whether a subcontracting work center is used in an item journal line.
    /// </summary>
    /// <returns>True if a subcontracting work center is used, otherwise false.</returns>
    procedure SubcontractingWorkCenterUsed() Result: Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        if Type = Type::"Work Center" then
            if WorkCenter.Get("Work Center No.") then
                Result := WorkCenter."Subcontractor No." <> '';
        OnAfterSubcontractingWorkCenterUsed(Rec, WorkCenter, Result);
    end;

    local procedure ValidateQuantityIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Quantity (Base)", "Output Quantity", "Output Quantity (Base)", 0, 0);
    end;

    /// <summary>
    /// Checks warehouse settings for a provided location and adjusts the output quantity 
    /// for an item journal line record based on these settings and the entry type of the record.
    /// </summary>
    /// <param name="LocationCode">Location to check warehouse settings for.</param>
    /// <param name="QtyToPost">Return value: Output quantity to use.</param>
    procedure CheckWhse(LocationCode: Code[20]; var QtyToPost: Decimal)
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);

        if "Entry Type" = "Entry Type"::Output then begin
            if Location."Prod. Output Whse. Handling" = Enum::Microsoft.Manufacturing.Setup."Prod. Output Whse. Handling"::"Inventory Put-away" then
                QtyToPost := 0;
        end else
            if Location."Require Put-away" and
               (not Location."Directed Put-away and Pick") and
               (not Location."Require Receive")
            then
                QtyToPost := 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromProdOrderComp(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromProdOrderComp(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnValidateOrderNoOrderTypeProduction(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order")
    begin
        OnValidateOrderNoOrderTypeProduction(ItemJournalLine, ProductionOrder);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateProdDim(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdDimOnBeforeCreateDimSetIDArr(var ItemJournalLine: Record "Item Journal Line"; var DimSetIDArr: array[10] of Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdDimOnAfterCreateDimSetIDArr(var ItemJournalLine: Record "Item Journal Line"; var DimSetIDArr: array[10] of Integer; var i: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimWithProdOrderLineOnAfterInitDefaultDimensionSources(var ItemJournalLine: Record "Item Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderNoOrderTypeProduction(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnValidateCapUnitofMeasureCodeOnBeforeRoutingCostPerUnit(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
        OnValidateCapUnitofMeasureCodeOnBeforeRoutingCostPerUnit(ItemJournalLine, ProdOrderRoutingLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCapUnitofMeasureCodeOnBeforeRoutingCostPerUnit(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterProdOrderCompSetFilters(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnValidateItemNoOnAfterValidateProdOrderCompLineNo(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        OnValidateItemNoOnAfterValidateProdOrderCompLineNo(ItemJournalLine, ProdOrderLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterValidateProdOrderCompLineNo(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    internal procedure RunOnValidateItemNoOnAfterSetProdOrderLineItemNoFilter(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
        OnValidateItemNoOnAfterSetProdOrderLineItemNoFilter(ItemJournalLine, xItemJournalLine, ProdOrderLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterSetProdOrderLineItemNoFilter(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    internal procedure RunOnValidateItemNoOnAfterCalcShouldCopyFromSingleProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line"; var ShouldCopyFromSingleProdOrderLine: Boolean)
    begin
        OnValidateItemNoOnAfterCalcShouldCopyFromSingleProdOrderLine(ItemJournalLine, xItemJournalLine, ProdOrderLine, ShouldCopyFromSingleProdOrderLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCalcShouldCopyFromSingleProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line"; var ShouldCopyFromSingleProdOrderLine: Boolean)
    begin
    end;

    internal procedure RunOnValidateItemNoOnAfterCalcShouldThrowRevaluationError(var ItemJournalLine: Record "Item Journal Line"; var ShouldThrowRevaluationError: Boolean)
    begin
        OnValidateItemNoOnAfterCalcShouldThrowRevaluationError(ItemJournalLine, ShouldThrowRevaluationError);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCalcShouldThrowRevaluationError(var ItemJournalLine: Record "Item Journal Line"; var ShouldThrowRevaluationError: Boolean)
    begin
    end;

    internal procedure RunOnValidateOrderLineNoOnAfterProdOrderLineSetFilters(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
        OnValidateOrderLineNoOnAfterProdOrderLineSetFilters(ItemJournalLine, ProdOrderLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderLineNoOnAfterProdOrderLineSetFilters(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    internal procedure RunOnOrderLineNoOnValidateOnAfterAssignProdOrderLineValues(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        OnOrderLineNoOnValidateOnAfterAssignProdOrderLineValues(ItemJournalLine, ProdOrderLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOrderLineNoOnValidateOnAfterAssignProdOrderLineValues(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLastOutputOperation(ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLastOutputOperationOnBeforeTestRoutingNo(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemPosting(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var NextOperationNoIsEmpty: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemPosting(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityIsBalanced(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmOutputOnFinishedOperation(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderCompBinCode(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupProdOrderCompOnBeforeSetTableView(var ProdOrderComponent: Record "Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupProdOrderCompBeforeRunModal(var ProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromMachineCenter(var ItemJournalLine: Record "Item Journal Line"; var MachineCenter: Record "Machine Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromWorkCenter(var ItemJournalLine: Record "Item Journal Line"; var WorkCenter: Record "Work Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromWorkCenter(var ItemJournalLine: Record "Item Journal Line"; WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromMachineCenter(var ItemJournalLine: Record "Item Journal Line"; MachineCenter: Record "Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateConcurrentCapacityOnAfterCalcTotalTime(var ItemJournalLine: Record "Item Journal Line"; var TotalTime: Integer; xItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSubcontractingWorkCenterUsed(ItemJournalLine: Record "Item Journal Line"; WorkCenter: Record "Work Center"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOutputValuePosting(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateScrapCode(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostingItemJnlFromProduction(var ItemJournalLine: Record "Item Journal Line"; Print: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateScrapQuantityBase(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateOutputQuantityBase(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateProdOrderCompLineNo(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
}
