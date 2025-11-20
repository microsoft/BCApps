// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using System.Security.User;

table 5405 "Production Order"
{
    Caption = 'Production Order';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Production Order List";
    LookupPageID = "Production Order List";
    Permissions = TableData "Prod. Order Capacity Need" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Status; Enum "Production Order Status")
        {
            Caption = 'Status';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = "Production Order"."No." where(Status = field(Status));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    MfgSetup.Get();
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                "Search Description" := Description;
            end;
        }
        field(4; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(5; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(6; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(7; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(9; "Source Type"; Enum "Prod. Order Source Type")
        {
            Caption = 'Source Type';

            trigger OnValidate()
            begin
                if "Source Type" <> xRec."Source Type" then
                    CheckProdOrderStatus(FieldCaption("Source Type"));
            end;
        }
        field(10; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Item)) Item where(Type = const(Inventory), "Production Blocked" = filter(<> Output))
            else
            if ("Source Type" = const(Family)) Family
            else
            if (Status = const(Simulated),
                                     "Source Type" = const("Sales Header")) "Sales Header"."No." where("Document Type" = const(Quote))
            else
            if (Status = filter(Planned ..),
                                              "Source Type" = const("Sales Header")) "Sales Header"."No." where("Document Type" = const(Order));

            trigger OnValidate()
            var
                Item: Record Item;
                Family: Record Family;
                SalesHeader: Record "Sales Header";
            begin
                if "Source No." <> xRec."Source No." then begin
                    CheckProdOrderStatus(FieldCaption("Source No."));
                    "Variant Code" := '';
                end;

                if "Source No." = '' then
                    exit;

                case "Source Type" of
                    "Source Type"::Item:
                        begin
                            Item.Get("Source No.");
                            Item.TestField(Blocked, false);
                            InitFromSourceNo(
                              Item.Description, Item."Description 2", Item."Routing No.",
                              Item."Inventory Posting Group", Item."Gen. Prod. Posting Group", '', Item."Unit Cost");
                            CreateDimFromDefaultDim();
                            OnBeforeAssignItemNo(Rec, xRec, Item, CurrFieldNo);
                        end;
                    "Source Type"::Family:
                        begin
                            Family.Get("Source No.");
                            InitFromSourceNo(Family.Description, Family."Description 2", Family."Routing No.", '', '', '', 0);
                            OnBeforeAssignFamily(Rec, xRec, Family, CurrFieldNo);
                        end;
                    "Source Type"::"Sales Header":
                        begin
                            if Status = Status::Simulated then
                                SalesHeader.Get(SalesHeader."Document Type"::Quote, "Source No.")
                            else
                                SalesHeader.Get(SalesHeader."Document Type"::Order, "Source No.");
                            InitFromSourceNo(SalesHeader."Ship-to Name", SalesHeader."Ship-to Name 2", '', '', '', '', 0);
                            "Location Code" := SalesHeader."Location Code";
                            "Due Date" := SalesHeader."Shipment Date";
                            "Ending Date" := SalesHeader."Shipment Date";
                            "Dimension Set ID" := SalesHeader."Dimension Set ID";
                            "Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                            "Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                            OnBeforeAssignSalesHeader(Rec, xRec, SalesHeader, CurrFieldNo);
                        end;
                    else
                        OnValidateSourceNoOnSourceTypeEnumExtension(Rec);
                end;
                Validate(Description);
                InitRecord();
                UpdateDatetime();
            end;
        }
        field(11; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if ("Source Type" = const(Item)) "Item Variant".Code where("Item No." = field("Source No."),
                                                                                        Code = field("Variant Code"),
                                                                                        "Production Blocked" = filter(<> Output));

            trigger OnValidate()
            var
                Item: Record Item;
                ItemVariant: Record "Item Variant";
                StockkeepingUnit: Record "Stockkeeping Unit";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVariantCode(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if Rec."Variant Code" = xRec."Variant Code" then
                    exit;

                if Rec."Variant Code" <> '' then begin
                    ItemVariant.SetLoadFields(Blocked);
                    ItemVariant.Get(Rec."Source No.", Rec."Variant Code");
                    ItemVariant.TestField(Blocked, false);
                    Description := ItemVariant.Description;
                    "Description 2" := ItemVariant."Description 2";
                end;

                TestField("Source Type", "Source Type"::Item);
                TestField("Source No.");

                if StockkeepingUnit.Get("Location Code", "Source No.", "Variant Code") and
                   (StockkeepingUnit."Routing No." <> '')
                then
                    "Routing No." := StockkeepingUnit."Routing No.";

                if ("Routing No." = '') and ("Variant Code" = '') then begin
                    Item.Get("Source No.");
                    "Routing No." := Item."Routing No.";
                end;

                InitRecord();
                UpdateDatetime();
            end;
        }
        field(15; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(16; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(17; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(19; Comment; Boolean)
        {
            CalcFormula = exist("Prod. Order Comment Line" where(Status = field(Status),
                                                                  "Prod. Order No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                UpdateStartingEndingTime(0);
            end;
        }
        field(21; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                Validate("Starting Time");
            end;
        }
        field(22; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                UpdateStartingEndingTime(1);
            end;
        }
        field(23; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                Validate("Ending Time");
            end;
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                if "Due Date" = 0D then
                    exit;

                if CurrFieldNo <> 0 then
                    UpdateManualScheduling();

                if (CurrFieldNo = FieldNo("Due Date")) or
                   (CurrFieldNo = FieldNo("Location Code")) or
                   UpdateEndDate
                then begin
                    ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Planning Level Code");
                    ProdOrderLine.Ascending(true);
                    ProdOrderLine.SetRange(Status, Status);
                    ProdOrderLine.SetRange("Prod. Order No.", "No.");
                    ProdOrderLine.SetFilter("Item No.", '<>%1', '');
                    ProdOrderLine.SetFilter("Planning Level Code", '>%1', 0);
                    if not ProdOrderLine.IsEmpty() then begin
                        ProdOrderLine.SetRange("Planning Level Code", 0);
                        if "Source Type" = "Source Type"::Family then
                            UpdateEndingDate(ProdOrderLine)
                        else begin
                            if ProdOrderLine.Find('-') then
                                "Ending Date" :=
                                    LeadTimeMgt.GetPlannedEndingDate(
                                        ProdOrderLine."Item No.", "Location Code", '', "Due Date", '', "Requisition Ref. Order Type"::"Prod. Order")
                            else
                                "Ending Date" := "Due Date";
                            "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
                            MultiLevelMessage();
                            exit;
                        end;
                    end else begin
                        ProdOrderLine.SetRange("Planning Level Code");
                        if not ProdOrderLine.IsEmpty() then
                            UpdateEndingDate(ProdOrderLine)
                        else begin
                            if "Source Type" = "Source Type"::Item then
                                "Ending Date" :=
                                    LeadTimeMgt.GetPlannedEndingDate("Source No.", "Location Code", '', "Due Date", '', "Requisition Ref. Order Type"::"Prod. Order")
                            else
                                "Ending Date" := "Due Date";
                            "Starting Date" := "Ending Date";
                            "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
                            "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
                        end;
                        AdjustStartEndingDate();
                        Modify(true);
                    end;
                    OnValidateDueDateOnAfterModify(Rec);
                end;
            end;
        }
        field(25; "Finished Date"; Date)
        {
            Caption = 'Finished Date';
            Editable = false;
        }
        field(28; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(30; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(31; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(32; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            begin
                ValidateWarehousePutAwayLocation(Rec);

                GetDefaultBin();

                Validate("Due Date"); // Scheduling consider Calendar assigned to Location
                CreateDimFromDefaultDim();
            end;
        }
        field(33; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Source Type" = const(Item)) Bin.Code where("Location Code" = field("Location Code"),
                                                                           "Item Filter" = field("Source No."))
            else
            if ("Source Type" = filter(<> Item)) Bin.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            var
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                if "Bin Code" <> '' then
                    WhseIntegrationMgt.CheckBinTypeAndCode(
                        DATABASE::"Production Order", FieldCaption("Bin Code"), "Location Code", "Bin Code", 0);
            end;
        }
        field(34; "Replan Ref. No."; Code[20])
        {
            Caption = 'Replan Ref. No.';
            Editable = false;
        }
        field(35; "Replan Ref. Status"; Enum "Production Order Status")
        {
            Caption = 'Replan Ref. Status';
            Editable = false;
        }
        field(38; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            Editable = false;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Source Type" = "Source Type"::Item then
                    "Cost Amount" := Round(Quantity * "Unit Cost")
                else
                    "Cost Amount" := 0;
            end;
        }
        field(41; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DecimalPlaces = 2 : 5;
        }
        field(42; "Cost Amount"; Decimal)
        {
            Caption = 'Cost Amount';
            DecimalPlaces = 2 : 2;
        }
        field(47; "Work Center Filter"; Code[20])
        {
            Caption = 'Work Center Filter';
            FieldClass = FlowFilter;
            TableRelation = "Work Center";
        }
        field(48; "Capacity Type Filter"; Enum "Capacity Type")
        {
            Caption = 'Capacity Type Filter';
            FieldClass = FlowFilter;
        }
        field(49; "Capacity No. Filter"; Code[20])
        {
            Caption = 'Capacity No. Filter';
            FieldClass = FlowFilter;
            TableRelation = if ("Capacity Type Filter" = const("Machine Center")) "Machine Center"
            else
            if ("Capacity Type Filter" = const("Work Center")) "Work Center";
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(51; "Expected Operation Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Prod. Order Routing Line"."Expected Operation Cost Amt." where(Status = field(Status),
                                                                                               "Prod. Order No." = field("No.")));
            Caption = 'Expected Operation Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Expected Component Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Prod. Order Component"."Cost Amount" where(Status = field(Status),
                                                                           "Prod. Order No." = field("No."),
                                                                           "Due Date" = field("Date Filter")));
            Caption = 'Expected Component Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "Actual Time Used"; Decimal)
        {
            CalcFormula = sum("Capacity Ledger Entry".Quantity where("Order Type" = const(Production),
                                                                      "Order No." = field("No."),
                                                                      Type = field("Capacity Type Filter"),
                                                                      "No." = field("Capacity No. Filter"),
                                                                      "Posting Date" = field("Date Filter")));
            Caption = 'Actual Time Used';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Allocated Capacity Need"; Decimal)
        {
            CalcFormula = sum("Prod. Order Capacity Need"."Needed Time" where(Status = field(Status),
                                                                               "Prod. Order No." = field("No."),
                                                                               Type = field("Capacity Type Filter"),
                                                                               "No." = field("Capacity No. Filter"),
                                                                               "Work Center No." = field("Work Center Filter"),
                                                                               Date = field("Date Filter"),
                                                                               "Requested Only" = const(false)));
            Caption = 'Allocated Capacity Need';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; "Expected Capacity Need"; Decimal)
        {
            CalcFormula = sum("Prod. Order Capacity Need"."Needed Time" where(Status = field(Status),
                                                                               "Prod. Order No." = field("No."),
                                                                               Type = field("Capacity Type Filter"),
                                                                               "No." = field("Capacity No. Filter"),
                                                                               "Work Center No." = field("Work Center Filter"),
                                                                               Date = field("Date Filter"),
                                                                               "Requested Only" = const(false)));
            Caption = 'Expected Capacity Need';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(80; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(82; "Planned Order No."; Code[20])
        {
            Caption = 'Planned Order No.';
        }
        field(83; "Firm Planned Order No."; Code[20])
        {
            Caption = 'Firm Planned Order No.';
        }
        field(85; "Simulated Order No."; Code[20])
        {
            Caption = 'Simulated Order No.';
        }
        field(92; "Expected Material Ovhd. Cost"; Decimal)
        {
            CalcFormula = sum("Prod. Order Component"."Overhead Amount" where(Status = field(Status),
                                                                               "Prod. Order No." = field("No.")));
            Caption = 'Expected Material Ovhd. Cost';
            DecimalPlaces = 2 : 2;
            Editable = false;
            FieldClass = FlowField;
        }
        field(94; "Expected Capacity Ovhd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Prod. Order Routing Line"."Expected Capacity Ovhd. Cost" where(Status = field(Status),
                                                                                               "Prod. Order No." = field("No.")));
            Caption = 'Expected Capacity Ovhd. Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(98; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                "Starting Date" := DT2Date("Starting Date-Time");
                "Starting Time" := DT2Time("Starting Date-Time");
                Validate("Starting Time");
            end;
        }
        field(99; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    UpdateManualScheduling();

                "Ending Date" := DT2Date("Ending Date-Time");
                "Ending Time" := DT2Time("Ending Date-Time");
                Validate("Ending Time");
            end;
        }
        field(110; "Document Put-away Status"; Option)
        {
            Caption = 'Document Put-away Status';
            Editable = false;
            OptionCaption = ' ,Partially Put Away,Completely Put Away';
            OptionMembers = " ","Partially Put Away","Completely Put Away";
        }
        field(200; "Reopened"; Boolean)
        {
            Caption = 'Reopened';
            Editable = false;
        }
        field(290; "Manual Scheduling"; Boolean)
        {
            Caption = 'Manual Scheduling';
            Editable = false;
            ToolTip = 'Specifies that the End/Due Dates on the production have been scheduled manually.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(7300; "Completely Picked"; Boolean)
        {
            CalcFormula = min("Prod. Order Component"."Completely Picked" where(Status = field(Status),
                                                                                 "Prod. Order No." = field("No."),
                                                                                 "Supplied-by Line No." = filter(0)));
            Caption = 'Completely Picked';
            FieldClass = FlowField;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(Key1; Status, "No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", Status)
        {
        }
        key(Key3; "Search Description")
        {
        }
        key(Key4; "Low-Level Code", "Replan Ref. No.", "Replan Ref. Status")
        {
        }
        key(Key5; "Source Type", "Source No.")
        {
            Enabled = false;
        }
        key(Key6; Description)
        {
        }
        key(Key7; "Source No.")
        {
        }
        key(Key8; "Starting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Source No.", "Source Type", "Due Date")
        {
        }
        fieldgroup(Brick; "No.", Description, "Source No.", Status, "Due Date")
        { }
    }

    trigger OnDelete()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        PurchLine: Record "Purchase Line";
        RefreshRecord: Boolean;
    begin
        if Status = Status::Released then begin

            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", "No.");
            if not ItemLedgEntry.IsEmpty() then
                Error(
                  Text000,
                  Status, TableCaption(), "No.", ItemLedgEntry.TableCaption());

            CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
            CapLedgEntry.SetRange("Order No.", "No.");
            if not CapLedgEntry.IsEmpty() then
                Error(
                  Text000,
                  Status, TableCaption(), "No.", CapLedgEntry.TableCaption());
        end;

        if Status in [Status::Released, Status::Finished] then begin
            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange(Type, PurchLine.Type::Item);
            PurchLine.SetRange("Prod. Order No.", "No.");
            if not PurchLine.IsEmpty() then
                Error(
                  Text000,
                  Status, TableCaption(), "No.", PurchLine.TableCaption());
        end;

        if Status = Status::Released then
            ConfirmDeletion();

        if Status = Status::Finished then
            DeleteFinishedProdOrderRelations()
        else
            DeleteProdOrderRelations();

        RefreshRecord := false;
        OnAfterOnDelete(Rec, RefreshRecord);
        if RefreshRecord then
            Get(Status, "No.");
    end;

    trigger OnInsert()
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, xRec, InvtAdjmtEntryOrder, IsHandled);
        if IsHandled then
            exit;

        MfgSetup.Get();
        if "No." = '' then begin
            TestNoSeries();
            if NoSeries.AreRelated(GetNoSeriesCode(), xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := GetNoSeriesCode();
            "No." := NoSeries.GetNextNo("No. Series", "Due Date");
        end;

        IsHandled := false;
        OnInsertOnBeforeStatusCheck(Rec, IsHandled);
        if not IsHandled then
            if Status = Status::Released then begin
                if ProdOrder.Get(Status::Finished, "No.") then
                    Error(Text007, Status, TableCaption(), ProdOrder."No.", ProdOrder.Status);
                InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Production);
                InvtAdjmtEntryOrder.SetRange("Order No.", "No.");
                if not InvtAdjmtEntryOrder.IsEmpty() then
                    Error(Text007, Status, TableCaption(), ProdOrder."No.", InvtAdjmtEntryOrder.TableCaption());
            end;

        InitRecord();

        if MfgSetup."Normal Starting Time" <> 0T then
            Rec."Starting Time" := MfgSetup."Normal Starting Time";
        if MfgSetup."Normal Ending Time" <> 0T then
            Rec."Ending Time" := MfgSetup."Normal Ending Time";
        "Creation Date" := Today;
        UpdateDatetime();
        if MfgSetup."Normal Starting Time" = 0T then
            Rec."Starting Time" := DT2Time("Starting Date-Time");
        if MfgSetup."Normal Ending Time" = 0T then
            Rec."Ending Time" := DT2Time("Ending Date-Time");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        CheckStatusNotFinished();
    end;

    trigger OnRename()
    begin
        ShowErrorOnRename();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You cannot delete %1 %2 %3 because there is at least one %4 associated with it.', Comment = '%1 = Document status; %2 = Table caption; %3 = Field value; %4 = Table Caption';
#pragma warning disable AA0470
        Text001: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
        Text002: Label 'You cannot change %1 on %2 %3 %4 because there is at least one %5 associated with it.', Comment = '%1 = Field caption; %2 = Document status; %3 = Table caption; %4 = Field value; %5 = Table Caption';
#pragma warning restore AA0074
        MultiLevelMsg: Label 'The production order contains lines connected in a multi-level structure and the production order lines have not been automatically rescheduled.\Use Refresh if you want to reschedule the lines.';
        MfgSetup: Record "Manufacturing Setup";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Location: Record Location;
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
        Text006: Label 'A Finished Production Order cannot be modified.';
#pragma warning disable AA0470
        Text007: Label '%1 %2 %3 cannot be created, because a %4 %2 %3 already exists.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemTrackingMgt: Codeunit "Item Tracking Management";
#pragma warning disable AA0074
        Text008: Label 'Nothing to handle. The production components are completely picked or not eligible for picking.';
#pragma warning restore AA0074
        UpdateEndDate: Boolean;
#pragma warning disable AA0074
        Text010: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        Text011: Label 'You cannot change Finished Production Order dimensions.';
#pragma warning restore AA0074
        ConfirmDeleteQst: Label 'The items have been picked. If you delete the Production Order, then the items will remain in the operation area until you put them away.\Related item tracking information that is defined during the pick will be deleted.\Are you sure that you want to delete the Production Order?';

    protected var
        HideValidationDialog: Boolean;

    procedure InitRecord()
    begin
        OnBeforeInitRecord(Rec);

        if "Due Date" = 0D then
            Validate("Due Date", WorkDate());
        if ("Source Type" = "Source Type"::Item) and ("Source No." <> '') then
            "Ending Date" :=
              LeadTimeMgt.GetPlannedEndingDate(
                "Source No.", "Location Code", "Variant Code", "Due Date", '', "Requisition Ref. Order Type"::"Prod. Order")
        else
            "Ending Date" := "Due Date";
        "Starting Date" := "Ending Date";
        "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
        "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");

        SetDefaultGenBusPostingGroup();

        OnAfterInitRecord(Rec);
    end;

    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        MfgSetup.Get();
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, MfgSetup, IsHandled);
        if IsHandled then
            exit;

        case Status of
            Status::Simulated:
                MfgSetup.TestField("Simulated Order Nos.");
            Status::Planned:
                MfgSetup.TestField("Planned Order Nos.");
            Status::"Firm Planned":
                MfgSetup.TestField("Firm Planned Order Nos.");
            Status::Released:
                MfgSetup.TestField("Released Order Nos.");
        end;
    end;

    procedure AssistEdit(OldProdOrder: Record "Production Order"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        ProdOrder := Rec;
        MfgSetup.Get();
        ProdOrder.TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(ProdOrder.GetNoSeriesCode(), OldProdOrder."No. Series", ProdOrder."No. Series") then begin
            ProdOrder."No." := NoSeries.GetNextNo(ProdOrder."No. Series");
            Rec := ProdOrder;
            exit(true);
        end;
    end;

    procedure GetNoSeriesCode() NoSeriesCode: Code[20]
    var
        IsHandled: Boolean;
    begin
        MfgSetup.Get();
        OnBeforeGetNoSeriesCode(Rec, MfgSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        case Status of
            Status::Simulated:
                exit(MfgSetup."Simulated Order Nos.");
            Status::Planned:
                exit(MfgSetup."Planned Order Nos.");
            Status::"Firm Planned":
                exit(MfgSetup."Firm Planned Order Nos.");
            Status::Released:
                exit(MfgSetup."Released Order Nos.");
        end;
    end;

    procedure CheckProdOrderStatus(Name: Text[80])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if Status <> Status::Released then
            exit;

        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", "No.");
        if not ItemLedgEntry.IsEmpty() then
            Error(
              Text002,
              Name, Status, TableCaption(), "No.", ItemLedgEntry.TableCaption());

        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
        CapLedgEntry.SetRange("Order No.", "No.");
        if not CapLedgEntry.IsEmpty() then
            Error(
              Text002,
              Name, Status, TableCaption(), "No.", CapLedgEntry.TableCaption());
    end;

    local procedure CheckStatusNotFinished()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckStatusNotFinished(Rec, IsHandled);
        if IsHandled then
            exit;

        if Status = Status::Finished then
            Error(Text006);
    end;

    procedure DeleteProdOrderRelations()
    var
        ProdOrderComment: Record "Prod. Order Comment Line";
        WhseRequest: Record "Whse. Pick Request";
        ReservMgt: Codeunit "Reservation Management";
    begin
        OnBeforeDeleteRelations(Rec);

        ProdOrderComment.SetRange(Status, Status);
        ProdOrderComment.SetRange("Prod. Order No.", "No.");
        ProdOrderComment.DeleteAll();

        ReservMgt.DeleteDocumentReservation(Database::"Prod. Order Line", Status.AsInteger(), "No.", HideValidationDialog);

        DeleteProdOrderLines();

        WhseRequest.SetRange("Document Type", WhseRequest."Document Type"::Production);
        WhseRequest.SetRange("Document Subtype", Status);
        WhseRequest.SetRange("Document No.", "No.");
        if not WhseRequest.IsEmpty() then
            WhseRequest.DeleteAll(true);
        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          Database::"Prod. Order Component", Status.AsInteger(), "No.", '', 0, 0, '', false);

        OnAfterDeleteProdOrderRelations(Rec, ProdOrderComment, WhseRequest, ReservMgt, ItemTrackingMgt);
    end;

    local procedure DeleteProdOrderLines()
    begin
        OnBeforeDeleteProdOrderLines(Rec, ProdOrderLine);

        ProdOrderLine.LockTable();
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "No.");
        ProdOrderLine.SuspendDeletionCheck(true);
        ProdOrderLine.DeleteAll(true);
    end;

    procedure DeleteFinishedProdOrderRelations()
    var
        FnshdProdOrderRtngLine: Record "Prod. Order Routing Line";
        FnshdProdOrderLine: Record "Prod. Order Line";
        FnshdProdOrderComp: Record "Prod. Order Component";
        FnshdProdOrderRtngTool: Record "Prod. Order Routing Tool";
        FnshdProdOrderRtngPers: Record "Prod. Order Routing Personnel";
        FnshdProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
        FnshdProdOrderComment: Record "Prod. Order Comment Line";
        FnshdProdOrderRtngCmt: Record "Prod. Order Rtng Comment Line";
        FnshdProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
    begin
        OnBeforeDeleteFnshdProdOrderRelations(Rec);

        FnshdProdOrderRtngLine.SetRange(Status, Status);
        FnshdProdOrderRtngLine.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngLine.DeleteAll();

        FnshdProdOrderLine.SetRange(Status, Status);
        FnshdProdOrderLine.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderLine.DeleteAll();

        FnshdProdOrderComp.SetRange(Status, Status);
        FnshdProdOrderComp.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderComp.DeleteAll();

        FnshdProdOrderRtngTool.SetRange(Status, Status);
        FnshdProdOrderRtngTool.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngTool.DeleteAll();

        FnshdProdOrderRtngPers.SetRange(Status, Status);
        FnshdProdOrderRtngPers.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngPers.DeleteAll();

        FnshdProdOrderRtngQltyMeas.SetRange(Status, Status);
        FnshdProdOrderRtngQltyMeas.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngQltyMeas.DeleteAll();

        FnshdProdOrderComment.SetRange(Status, Status);
        FnshdProdOrderComment.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderComment.DeleteAll();

        FnshdProdOrderRtngCmt.SetRange(Status, Status);
        FnshdProdOrderRtngCmt.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngCmt.DeleteAll();

        FnshdProdOrderBOMComment.SetRange(Status, Status);
        FnshdProdOrderBOMComment.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderBOMComment.DeleteAll();
    end;

    procedure AdjustStartEndingDate()
    var
        EarliestLatestProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        EarliestLatestProdOrderLine.SetRange(Status, Status);
        EarliestLatestProdOrderLine.SetRange("Prod. Order No.", "No.");
        if EarliestLatestProdOrderLine.IsEmpty() then
            exit;

        EarliestLatestProdOrderLine.SetCurrentKey("Starting Date-Time");
        EarliestLatestProdOrderLine.FindFirst();
        "Starting Date" := EarliestLatestProdOrderLine."Starting Date";
        "Starting Time" := EarliestLatestProdOrderLine."Starting Time";

        EarliestLatestProdOrderLine.SetCurrentKey("Ending Date-Time");
        EarliestLatestProdOrderLine.FindLast();
        "Ending Date" := EarliestLatestProdOrderLine."Ending Date";
        "Ending Time" := EarliestLatestProdOrderLine."Ending Time";

        EarliestLatestProdOrderLine.SetCurrentKey("Due Date");
        EarliestLatestProdOrderLine.FindLast();

        IsHandled := false;
        OnAdjustStartEndingDateOnBeforeSetDueDate(Rec, EarliestLatestProdOrderLine, IsHandled);
        if not IsHandled then
            "Due Date" := EarliestLatestProdOrderLine."Due Date";

        UpdateDatetime();
    end;

    local procedure MultiLevelMessage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMultiLevelMessage(IsHandled, Rec, xRec, CurrFieldNo);
        if IsHandled then
            exit;

        Message(MultiLevelMsg);
    end;

    procedure UpdateDatetime()
    begin
        if (Rec."Starting Date" <> 0D) and (Rec."Starting Time" <> 0T) then
            Rec."Starting Date-Time" := CreateDateTime(Rec."Starting Date", Rec."Starting Time")
        else
            if Rec."Starting Date" = 0D then
                Rec."Starting Date-Time" := 0DT;

        if (Rec."Ending Date" <> 0D) and (Rec."Ending Time" <> 0T) then
            Rec."Ending Date-Time" := CreateDateTime(Rec."Ending Date", Rec."Ending Time")
        else
            if Rec."Ending Date" = 0D then
                Rec."Ending Date-Time" := 0DT;

        OnAfterUpdateDateTime(Rec, xRec, CurrFieldNo);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled);
        if not IsHandled then begin
            "Shortcut Dimension 1 Code" := '';
            "Shortcut Dimension 2 Code" := '';
            "Dimension Set ID" :=
              DimMgt.GetRecDefaultDimID(
                Rec, CurrFieldNo, DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        end;

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        if OldDimSetID <> "Dimension Set ID" then begin
            OnValidateShortcutDimCodeOnBeforeUpdateAllLineDim(Rec, xRec, FieldNumber);
            if Status = Status::Finished then
                Error(Text011);
            Modify();
            if ProdOrderLineExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Due Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    procedure GetHeaderPutAwayStatus(SkipLineNo: Integer): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetLoadFields("Put-away Status");
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "No.");
        if SkipLineNo <> 0 then
            ProdOrderLine.SetFilter("Line No.", '<>%1', SkipLineNo);

        ProdOrderLine.SetRange("Put-away Status", ProdOrderLine."Put-away Status"::"Completely Put Away");
        if not ProdOrderLine.IsEmpty() then begin
            ProdOrderLine.SetFilter("Put-away Status", '<>%1', ProdOrderLine."Put-away Status"::"Completely Put Away");
            if not ProdOrderLine.IsEmpty() then
                exit(ProdOrderLine."Put-away Status"::"Partially Put Away");

            exit(ProdOrderLine."Put-away Status"::"Completely Put Away");
        end else begin
            ProdOrderLine.SetRange("Put-away Status", ProdOrderLine."Put-away Status"::"Partially Put Away");
            if not ProdOrderLine.IsEmpty() then
                exit(ProdOrderLine."Put-away Status"::"Partially Put Away");
        end;

        exit(ProdOrderLine."Put-away Status"::" ");
    end;

    procedure CreatePick(AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
#if not CLEAN26
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        ProdOrderComponent.Reset();
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", "No.");
        OnCreatePickOnBeforeFindProdOrderComponent(ProdOrderComponent);
        if ProdOrderComponent.FindSet() then
            repeat
                ItemTrackingManagement.InitItemTrackingForTempWhseWorksheetLine(
                  Enum::"Warehouse Worksheet Document Type"::Production, ProdOrderComponent."Prod. Order No.",
                  ProdOrderComponent."Prod. Order Line No.", Database::"Prod. Order Component",
                  ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
                  ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.");
            until ProdOrderComponent.Next() = 0;
        Commit();

        TestField(Status, Status::Released);
        CalcFields("Completely Picked");
        if "Completely Picked" then
            Error(Text008);

        ProdOrderComponent.Reset();
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", "No.");

#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            ProdOrderComponent.SetFilter(
              "Flushing Method", '%1|%2|%3|%4',
              ProdOrderComponent."Flushing Method"::Manual,
              ProdOrderComponent."Flushing Method"::"Pick + Manual",
              ProdOrderComponent."Flushing Method"::"Pick + Forward",
              ProdOrderComponent."Flushing Method"::"Pick + Backward")
        else
#endif
            ProdOrderComponent.SetFilter(
              "Flushing Method", '%1|%2|%3',
              ProdOrderComponent."Flushing Method"::"Pick + Manual",
              ProdOrderComponent."Flushing Method"::"Pick + Forward",
              ProdOrderComponent."Flushing Method"::"Pick + Backward");
        ProdOrderComponent.SetRange("Planning Level Code", 0);
        ProdOrderComponent.SetFilter("Expected Quantity", '>0');
        OnCreatePickOnBeforeRunCreatePickFromWhseSource(ProdOrderComponent);
        if not ProdOrderComponent.IsEmpty() then
            RunCreatePickFromWhseSource(AssignedUserID, SortingMethod, SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument)
        else
            if not HideValidationDialog then
                Message(Text008);
    end;

    local procedure RunCreatePickFromWhseSource(AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean)
    var
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCreatePickFromWhseSource(Rec, AssignedUserID, SortingMethod, PrintDocument, DoNotFillQtyToHandle, SetBreakBulkFilter, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        CreatePickFromWhseSource.SetProdOrder(Rec);
        CreatePickFromWhseSource.SetHideValidationDialog(HideValidationDialog);
        if HideValidationDialog then
            CreatePickFromWhseSource.Initialize(
                AssignedUserID, Enum::"Whse. Activity Sorting Method".FromInteger(SortingMethod), PrintDocument, DoNotFillQtyToHandle, SetBreakBulkFilter);
        CreatePickFromWhseSource.UseRequestPage(not HideValidationDialog);
        CreatePickFromWhseSource.RunModal();
        CreatePickFromWhseSource.GetResultMessage(2);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure CreateInvtPutAwayPick()
    var
        WhseRequest: Record "Warehouse Request";
    begin
        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetFilter(
          "Source Document", '%1|%2',
          WhseRequest."Source Document"::"Prod. Consumption",
          WhseRequest."Source Document"::"Prod. Output");
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WhseRequest);
    end;

    local procedure GetDefaultBin()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        VersionManagement: Codeunit VersionManagement;
        RoutingNo: Code[20];
        IsHandled: Boolean;
    begin
        "Bin Code" := '';

        if "Source Type" <> "Source Type"::Item then
            exit;

        if "Location Code" = '' then
            exit;

        GetLocation("Location Code");
        if not Location."Bin Mandatory" or Location."Directed Put-away and Pick" then
            exit;

        if StockkeepingUnit.Get("Location Code", "Source No.", "Variant Code") then
            RoutingNo := StockkeepingUnit."Routing No.";
        if (RoutingNo = '') and Item.Get("Source No.") then
            RoutingNo := Item."Routing No.";

        // 1st priority - output bin from work/machine center
        if RoutingNo <> '' then
            "Bin Code" :=
              ProdOrderWarehouseMgt.GetLastOperationFromBinCode(
                RoutingNo, VersionManagement.GetRtngVersion(RoutingNo, "Due Date", true), "Location Code", false, Enum::"Flushing Method"::Manual);

        // 2nd priority - default output bin at location
        if "Bin Code" = '' then
            "Bin Code" := Location."From-Production Bin Code";

        // 3rd priority - default bin at location
        IsHandled := false;
        OnGetDefaultBinOnBeforeThirdPrioritySetBinCode(Rec, xRec, IsHandled);
        if not IsHandled then
            if ("Bin Code" = '') and ("Source No." <> '') then
                ProdOrderWarehouseMgt.GetDefaultBin("Source No.", '', "Location Code", "Bin Code");
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    procedure SetUpdateEndDate()
    begin
        UpdateEndDate := true;
    end;

    local procedure UpdateStartingEndingTime(Direction: Option Forward,Backward)
    var
        IsHandled: Boolean;
        NewDueDate: Date;
    begin
        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Planning Level Code");
        ProdOrderLine.Ascending(Direction = Direction::Backward);
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "No.");
        ProdOrderLine.SetFilter("Item No.", '<>%1', '');
        ProdOrderLine.SetFilter("Planning Level Code", '>%1', 0);
        if ProdOrderLine.Find('-') then begin
            case Direction of
                Direction::Forward:
                    "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
                Direction::Backward:
                    "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
            end;
            Modify();
            MultiLevelMessage();
            exit;
        end;
        "Due Date" := 0D;
        ProdOrderLine.SetRange("Planning Level Code");
        if ProdOrderLine.Find('-') then
            repeat
                case Direction of
                    Direction::Forward:
                        begin
                            ProdOrderLine."Starting Time" := "Starting Time";
                            ProdOrderLine."Starting Date" := "Starting Date";
                        end;
                    Direction::Backward:
                        begin
                            ProdOrderLine."Ending Time" := "Ending Time";
                            ProdOrderLine."Ending Date" := "Ending Date";
                        end;
                end;
                ProdOrderLine."Manual Scheduling" := Rec."Manual Scheduling";
                ProdOrderLine.Modify();

                LeadTimeMgt.SetManualScheduling(ProdOrderLine."Manual Scheduling");
                CalcProdOrder.SetParameter(true);
                case Direction of
                    Direction::Forward:
                        CalcProdOrder.Recalculate(ProdOrderLine, 0, true);
                    Direction::Backward:
                        if ProdOrderLine."Manual Scheduling" then
                            CalcProdOrder.Recalculate(ProdOrderLine, 1, false)
                        else
                            CalcProdOrder.Recalculate(ProdOrderLine, 1, true);
                end;
                IsHandled := false;
                OnBeforeUpdateProdOrderLineDueDate(ProdOrderLine, IsHandled, CalcProdOrder);
                if not IsHandled then
                    if ProdOrderLine."Planning Level Code" > 0 then
                        ProdOrderLine."Due Date" := ProdOrderLine."Ending Date"
                    else
                        if ProdOrderLine."Manual Scheduling" then begin
                            NewDueDate :=
                                LeadTimeMgt.GetPlannedDueDate(
                                    ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code",
                                    ProdOrderLine."Ending Date", '', "Requisition Ref. Order Type"::"Prod. Order");
                            if NewDueDate > ProdOrderLine."Due Date" then
                                if ProdOrderLine.ConfirmUpdateDueDateAndEndingDate(ProdOrderLine.FieldCaption("Due Date"), NewDueDate) then
                                    ProdOrderLine."Due Date" := NewDueDate
                        end else
                            ProdOrderLine."Due Date" :=
                              LeadTimeMgt.GetPlannedDueDate(
                                ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code",
                                ProdOrderLine."Ending Date", '', "Requisition Ref. Order Type"::"Prod. Order");

                if "Due Date" = 0D then
                    "Due Date" := ProdOrderLine."Due Date";
                case Direction of
                    Direction::Forward:
                        "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
                    Direction::Backward:
                        "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
                end;
                OnUpdateStartingEndingTimeOnBeforeProdOrderLineModify(ProdOrderLine, Rec);
                ProdOrderLine.Modify(true);
                ProdOrderLine.CheckEndingDate(CurrFieldNo <> 0);
            until ProdOrderLine.Next() = 0
        else
            case Direction of
                Direction::Forward:
                    begin
                        "Ending Date" := "Starting Date";
                        "Ending Time" := "Starting Time";
                    end;
                Direction::Backward:
                    begin
                        "Starting Date" := "Ending Date";
                        "Starting Time" := "Ending Time";
                    end;
            end;

        AdjustStartEndingDate();
        Modify();
    end;

    local procedure UpdateEndingDate(var ProdOrderLine: Record "Prod. Order Line")
    var
        IsHandled: Boolean;
        NewEndingDate: Date;
    begin
        IsHandled := false;
        OnBeforeUpdateEndingDate(ProdOrderLine, Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if ProdOrderLine.FindSet(true) then
            repeat
                ProdOrderLine."Manual Scheduling" := Rec."Manual Scheduling";
                ProdOrderLine."Due Date" := "Due Date";
                ProdOrderLine.Modify();
                CalcProdOrder.SetParameter(true);
                LeadTimeMgt.SetManualScheduling(ProdOrderLine."Manual Scheduling");
                if ShouldUpdateEndingDate(ProdOrderLine) then begin
                    NewEndingDate :=
                        LeadTimeMgt.GetPlannedEndingDate(
                            ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code",
                            ProdOrderLine."Due Date", '', "Requisition Ref. Order Type"::"Prod. Order");

                    if ProdOrderLine.ConfirmUpdateDueDateAndEndingDate(ProdOrderLine.FieldCaption("Ending Date"), NewEndingDate) then
                        ProdOrderLine."Ending Date" := NewEndingDate;
                end;

                OnUpdateEndingDateOnBeforeCalcProdOrderRecalculate(ProdOrderLine);
                if ProdOrderLine."Manual Scheduling" then
                    CalcProdOrder.Recalculate(ProdOrderLine, 1, false)
                else
                    CalcProdOrder.Recalculate(ProdOrderLine, 1, true);
                "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
                "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
                OnUpdateEndingDateOnBeforeProdOrderLineModify(ProdOrderLine, Rec);
                ProdOrderLine.Modify(true);
                ProdOrderLine.CheckEndingDate(CurrFieldNo <> 0);
            until ProdOrderLine.Next() = 0
    end;

    local procedure ShouldUpdateEndingDate(ProdOrderLine: Record "Prod. Order Line"): Boolean
    begin
        if not ProdOrderLine."Manual Scheduling" then
            exit(true);

        if ProdOrderLine."Ending Date" = 0D then
            exit(true);

        if ProdOrderLine."Ending Date" < ProdOrderLine."Due Date" then
            exit(false);

        exit(true);
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        TestField("No.");
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnShowDocDimOnAfterSetDimensionSetID(Rec, xRec);

        if OldDimSetID <> "Dimension Set ID" then begin
            if Status = Status::Finished then
                Error(Text011);
            Modify();
            if ProdOrderLineExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure ProdOrderLineExist(): Boolean
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange("Prod. Order No.", "No.");
        ProdOrderLine.SetRange(Status, Status);
        exit(not ProdOrderLine.IsEmpty());
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
        OldDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;

        if not ConfirmUpdateAllLineDim(NewParentDimSetID, OldParentDimSetID) then
            exit;

        ProdOrderLine.Reset();
        ProdOrderLine.SetRange("Prod. Order No.", "No.");
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.LockTable();
        if ProdOrderLine.Find('-') then
            repeat
                OldDimSetID := ProdOrderLine."Dimension Set ID";
                NewDimSetID := DimMgt.GetDeltaDimSetID(ProdOrderLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ProdOrderLine."Dimension Set ID" <> NewDimSetID then begin
                    ProdOrderLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ProdOrderLine."Dimension Set ID", ProdOrderLine."Shortcut Dimension 1 Code", ProdOrderLine."Shortcut Dimension 2 Code");
                    ProdOrderLine.Modify();
                    ProdOrderLine.UpdateProdOrderCompDim(NewDimSetID, OldDimSetID);
                    OnUpdateAllLineDimOnAfterUpdateProdOrderCompDim(Rec, ProdOrderLine, NewParentDimSetID, OldParentDimSetID);
                end;
            until ProdOrderLine.Next() = 0;
    end;

    local procedure ConfirmUpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer) Confirmed: Boolean;
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmUpdateAllLineDim(Rec, xRec, NewParentDimSetID, OldParentDimSetID, Confirmed, IsHandled);
        if not IsHandled then
            Confirmed := Confirm(Text010);
    end;

    procedure IsStatusLessThanReleased(): Boolean
    begin
        exit((Status = Status::Simulated) or (Status = Status::Planned) or (Status = Status::"Firm Planned"));
    end;

    local procedure InitFromSourceNo(SourceDescription: Text[100]; SourceDescription2: Text[50]; RoutingNo: Code[20]; InventoryPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; GenBusPostingGroup: Code[20]; UnitCost: Decimal)
    begin
        Description := SourceDescription;
        "Description 2" := SourceDescription2;
        "Routing No." := RoutingNo;
        "Inventory Posting Group" := InventoryPostingGroup;
        "Gen. Prod. Posting Group" := GenProdPostingGroup;
        "Gen. Bus. Posting Group" := GenBusPostingGroup;
        "Unit Cost" := UnitCost;
    end;

    local procedure ShowErrorOnRename()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowErrorOnRename(IsHandled, Rec);
        if IsHandled then
            exit;

        Error(Text001, TableCaption);
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Item, Rec."Source No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, CurrFieldNo);
    end;

    internal procedure GetQtyReservedFromStockState() Result: Enum "Reservation From Stock"
    var
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        QtyReservedFromStock: Decimal;
    begin
        QtyReservedFromStock := ProdOrderCompReserve.GetReservedQtyFromInventory(Rec);
        if QtyReservedFromStock = 0 then
            exit(Result::None);

        if QtyReservedFromStock = CalculateReservableRemainingQuantityBase() then
            exit(Result::Full);

        exit(Result::Partial);
    end;

    local procedure CalculateReservableRemainingQuantityBase() RemainingQtyBase: Decimal
    var
        RemQtyBaseInvtItemProdOrdComp: Query RemQtyBaseInvtItemProdOrdComp;
    begin
        RemQtyBaseInvtItemProdOrdComp.SetJobPlanningLineFilter(Rec);
        if RemQtyBaseInvtItemProdOrdComp.Open() then
            if RemQtyBaseInvtItemProdOrdComp.Read() then
                RemainingQtyBase := RemQtyBaseInvtItemProdOrdComp.Remaining_Qty___Base_;
        RemQtyBaseInvtItemProdOrdComp.Close();
    end;

    local procedure ConfirmDeletion()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Confirmed: Boolean;
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", "No.");
        if ProdOrderComponent.FindSet() then
            repeat
                if (ProdOrderComponent."Expected Quantity" - ProdOrderComponent."Remaining Quantity") < ProdOrderComponent."Qty. Picked" then begin
                    if not Confirm(ConfirmDeleteQst) then
                        Error('');
                    Confirmed := true;
                end;
            until (ProdOrderComponent.Next() = 0) or Confirmed;
    end;

    local procedure ValidateWarehousePutAwayLocation(ProductionOrder: Record "Production Order")
    var
        PutAwayProdOrderLine: Record "Prod. Order Line";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
    begin
        PutAwayProdOrderLine.SetLoadFields(Status, "Prod. Order No.", "Location Code", "Line No.");
        PutAwayProdOrderLine.SetRange(Status, ProductionOrder.Status);
        PutAwayProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        if PutAwayProdOrderLine.FindSet() then
            repeat
                ProdOrderWarehouseMgt.CompareProdOrderWithProdOrderLinesForLocation(Rec, PutAwayProdOrderLine);
            until PutAwayProdOrderLine.Next() = 0;
    end;

    local procedure SetDefaultGenBusPostingGroup()
    begin
        GetMfgSetup();
        if MfgSetup."Default Gen. Bus. Post. Group" <> '' then
            if Rec."Gen. Bus. Posting Group" = '' then
                Validate("Gen. Bus. Posting Group", MfgSetup."Default Gen. Bus. Post. Group");
    end;

    local procedure GetMfgSetup()
    begin
        MfgSetup.GetRecordOnce();
    end;

    local procedure UpdateManualScheduling()
    begin
        GetMfgSetup();

        Rec.Validate("Manual Scheduling", MfgSetup."Manual Scheduling");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ProductionOrder: Record "Production Order"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustStartEndingDateOnBeforeSetDueDate(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDelete(var ProductionOrder: Record "Production Order"; var RefreshOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ProductionOrder: Record "Production Order"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDateTime(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignItemNo(var ProdOrder: Record "Production Order"; xProdOrder: Record "Production Order"; var Item: Record Item; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignFamily(var ProdOrder: Record "Production Order"; xProdOrder: Record "Production Order"; var Family: Record Family; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignSalesHeader(var ProdOrder: Record "Production Order"; xProdOrder: Record "Production Order"; var SalesHeader: Record "Sales Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var ProductionOrder: Record "Production Order"; MfgSetup: Record "Manufacturing Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteFnshdProdOrderRelations(var ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteProdOrderLines(ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelations(var ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMultiLevelMessage(var IsHandled: Boolean; var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateEndingDate(var ProdOrderLine: Record "Prod. Order Line"; ProdOrder: Record "Production Order"; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderLineDueDate(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean; var CalculateProdOrder: Codeunit "Calculate Prod. Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVariantCode(var ProductionOrder: Record "Production Order"; xProductionOrder: Record "Production Order"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDueDateOnAfterModify(ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSourceNoOnSourceTypeEnumExtension(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEndingDateOnBeforeCalcProdOrderRecalculate(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStartingEndingTimeOnBeforeProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEndingDateOnBeforeProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowErrorOnRename(var IsHandled: Boolean; var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCreatePickFromWhseSource(var ProductionOrder: Record "Production Order"; AssignedUserID: Code[50]; SortingMethod: Option; PrintDocument: Boolean; DoNotFillQtyToHandle: Boolean; SetBreakBulkFilter: Boolean; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(ProductionOrder: Record "Production Order"; MfgSetup: Record "Manufacturing Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStatusNotFinished(ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultBinOnBeforeThirdPrioritySetBinCode(var ProductionOrder: Record "Production Order"; xProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeStatusCheck(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateAllLineDim(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShortcutDimCodeOnBeforeUpdateAllLineDim(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocDimOnAfterSetDimensionSetID(var ProductionOrder: Record "Production Order"; xProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnAfterUpdateProdOrderCompDim(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; NewParentDimSetID: Integer; OldParentDimSetID: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteProdOrderRelations(var ProductionOrder: Record "Production Order"; var ProdOrderCommentLine: Record "Prod. Order Comment Line"; var WhsePickRequest: Record "Whse. Pick Request"; var ReservationManagement: Codeunit "Reservation Management"; var ItemTrackingManagement: Codeunit "Item Tracking Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOnBeforeFindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOnBeforeRunCreatePickFromWhseSource(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;
}
