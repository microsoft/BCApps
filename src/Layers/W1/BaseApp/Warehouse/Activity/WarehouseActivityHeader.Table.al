// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Assembly.Document;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;

table 5766 "Warehouse Activity Header"
{
    Caption = 'Warehouse Activity Header';
    LookupPageID = "Warehouse Activity List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Warehouse Activity Type")
        {
            Caption = 'Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
            begin
                if "Location Code" <> xRec."Location Code" then
                    if LineExist() then
                        Error(Text002, FieldCaption("Location Code"));

                if "Location Code" <> '' then
                    if not WMSManagement.LocationIsAllowed("Location Code") then
                        Error(SetUpWarehouseEmployeeInLocationErr, UserId, FieldCaption("Location Code"), "Location Code");

                GetLocation("Location Code");
                case Type of
                    Type::"Invt. Put-away":
                        if ((Location.Code <> '') and ProdWhseHandlingIsInventoryPutaway(Location) and ("Source Document" <> "Source Document"::"Prod. Output")) or
                           ((Location.Code = '') and Location.RequireReceive("Location Code") and ("Source Document" <> "Source Document"::"Prod. Output"))
                         then
                            Validate("Source Document", "Source Document"::"Prod. Output");
                    Type::"Invt. Pick":
                        if (Location.Code = '') and Location.RequireShipment("Location Code") then
                            Location.TestField("Require Shipment", false);
                    Type::"Invt. Movement":
                        Location.TestField("Directed Put-away and Pick", false);
                end;
            end;
        }
        field(4; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Warehouse Employee" where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "Assigned User ID" <> '' then begin
                    "Assignment Date" := Today;
                    "Assignment Time" := Time;
                end else begin
                    "Assignment Date" := 0D;
                    "Assignment Time" := 0T;
                end;
            end;
        }
        field(5; "Assignment Date"; Date)
        {
            Caption = 'Assignment Date';
            Editable = false;
        }
        field(6; "Assignment Time"; Time)
        {
            Caption = 'Assignment Time';
            Editable = false;
        }
        field(7; "Sorting Method"; Enum "Whse. Activity Sorting Method")
        {
            Caption = 'Sorting Method';

            trigger OnValidate()
            begin
                if "Sorting Method" <> xRec."Sorting Method" then
                    SortWhseDoc();
            end;
        }
        field(9; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(10; Comment; Boolean)
        {
            CalcFormula = exist("Warehouse Comment Line" where("Table Name" = const("Whse. Activity Header"),
                                                                Type = field(Type),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(13; "No. of Lines"; Integer)
        {
            CalcFormula = count("Warehouse Activity Line" where("Activity Type" = field(Type),
                                                                 "No." = field("No."),
                                                                 "Source Type" = field("Source Type Filter"),
                                                                 "Source Subtype" = field("Source Subtype Filter"),
                                                                 "Source No." = field("Source No. Filter"),
                                                                 "Location Code" = field("Location Filter")));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Source Type Filter"; Integer)
        {
            Caption = 'Source Type Filter';
            FieldClass = FlowFilter;
        }
        field(15; "Source Subtype Filter"; Option)
        {
            Caption = 'Source Subtype Filter';
            FieldClass = FlowFilter;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(16; "Source No. Filter"; Code[250])
        {
            Caption = 'Source No. Filter';
            FieldClass = FlowFilter;
        }
        field(17; "Location Filter"; Code[250])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
            ValidateTableRelation = false;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(61; "Registering No."; Code[20])
        {
            Caption = 'Registering No.';
        }
        field(62; "Last Registering No."; Code[20])
        {
            Caption = 'Last Registering No.';
            Editable = false;
            TableRelation = if (Type = const("Put-away")) "Registered Whse. Activity Hdr."."No." where(Type = const("Put-away"))
            else
            if (Type = const(Pick)) "Registered Whse. Activity Hdr."."No." where(Type = const(Pick))
            else
            if (Type = const(Movement)) "Registered Whse. Activity Hdr."."No." where(Type = const(Movement));
        }
        field(63; "Registering No. Series"; Code[20])
        {
            Caption = 'Registering No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                WhseActivHeader := Rec;
                WhseSetup.Get();
                TestNoSeries();
                if NoSeries.LookupRelatedNoSeries(GetRegisteringNoSeriesCode(), WhseActivHeader."Registering No. Series") then
                    WhseActivHeader.Validate(WhseActivHeader."Registering No. Series");
                Rec := WhseActivHeader;
            end;

            trigger OnValidate()
            begin
                if "Registering No. Series" <> '' then begin
                    WhseSetup.Get();
                    TestNoSeries();
                    NoSeries.TestAreRelated(GetRegisteringNoSeriesCode(), "Registering No. Series");
                end;
            end;
        }
        field(7303; "Date of Last Printing"; Date)
        {
            Caption = 'Date of Last Printing';
            Editable = false;
        }
        field(7304; "Time of Last Printing"; Time)
        {
            Caption = 'Time of Last Printing';
            Editable = false;
        }
        field(7305; "Breakbulk Filter"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Breakbulk Filter';

            trigger OnValidate()
            begin
                if "Breakbulk Filter" <> xRec."Breakbulk Filter" then
                    SetBreakbulkFilter();
            end;
        }
        field(7306; "Source No."; Code[20])
        {
            Caption = 'Source No.';

            trigger OnValidate()
            var
                WarehouseRequest: Record "Warehouse Request";
                CreateInventoryPutAway: Codeunit "Create Inventory Put-away";
                CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
            begin
                if "Source No." <> xRec."Source No." then begin
                    if LineExist() then
                        Error(Text002, FieldCaption("Source No."));
                    if "Source No." <> '' then begin
                        TestField("Location Code");
                        TestField("Source Document");
                    end;
                    ClearDestinationFields();

                    if ("Source Type" <> 0) and ("Source No." <> '') then begin
                        if Type = Type::"Invt. Put-away" then begin
                            WarehouseRequest.Get(
                              WarehouseRequest.Type::Inbound, "Location Code", "Source Type", "Source Subtype", "Source No.");
                            WarehouseRequest.TestField("Document Status", WarehouseRequest."Document Status"::Released);
                            CreateInventoryPutAway.SetWhseRequest(WarehouseRequest, true);
                            CreateInventoryPutAway.Run(Rec);
                        end;
                        if Type = Type::"Invt. Pick" then begin
                            WarehouseRequest.Get(
                              WarehouseRequest.Type::Outbound, "Location Code", "Source Type", "Source Subtype", "Source No.");
                            WarehouseRequest.TestField("Document Status", WarehouseRequest."Document Status"::Released);
                            CreateInventoryPickMovement.SetWhseRequest(WarehouseRequest, true);
                            CreateInventoryPickMovement.Run(Rec);
                        end;
                        if Type = Type::"Invt. Movement" then begin
                            WarehouseRequest.Get(
                              WarehouseRequest.Type::Outbound, "Location Code", "Source Type", "Source Subtype", "Source No.");
                            WarehouseRequest.TestField("Document Status", WarehouseRequest."Document Status"::Released);
                            CreateInventoryPickMovement.SetInvtMovement(true);
                            CreateInventoryPickMovement.SetWhseRequest(WarehouseRequest, true);
                            CreateInventoryPickMovement.Run(Rec);
                        end;
                    end;
                end;
            end;
        }
        field(7307; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';

            trigger OnValidate()
            var
                AssemblyLine: Record "Assembly Line";
            begin
                if "Source Document" <> xRec."Source Document" then begin
                    if LineExist() then
                        Error(Text002, FieldCaption("Source Document"));
                    "Source No." := '';
                    ClearDestinationFields();
                    if Type = Type::"Invt. Put-away" then begin
                        GetLocation("Location Code");
                        if Location.RequireReceive("Location Code") then
                            TestField("Source Document", "Source Document"::"Prod. Output");
                    end;
                end;

                case "Source Document" of
                    "Source Document"::"Purchase Order":
                        begin
                            "Source Type" := Database::"Purchase Line";
                            "Source Subtype" := 1;
                        end;
                    "Source Document"::"Purchase Return Order":
                        begin
                            "Source Type" := Database::"Purchase Line";
                            "Source Subtype" := 5;
                        end;
                    "Source Document"::"Sales Order":
                        begin
                            "Source Type" := Database::"Sales Line";
                            "Source Subtype" := 1;
                        end;
                    "Source Document"::"Sales Return Order":
                        begin
                            "Source Type" := Database::"Sales Line";
                            "Source Subtype" := 5;
                        end;
                    "Source Document"::"Outbound Transfer":
                        begin
                            "Source Type" := Database::"Transfer Line";
                            "Source Subtype" := 0;
                        end;
                    "Source Document"::"Inbound Transfer":
                        begin
                            "Source Type" := Database::"Transfer Line";
                            "Source Subtype" := 1;
                        end;
                    "Source Document"::"Assembly Consumption":
                        begin
                            "Source Type" := Database::"Assembly Line";
                            "Source Subtype" := AssemblyLine."Document Type"::Order.AsInteger();
                        end;
                    "Source Document"::"Job Usage":
                        "Source Type" := Database::Job;
                    else
                        OnValidateSourceDocumentOnAssignSourceType(Rec);
                end;

                if "Source Document" = "Source Document"::" " then begin
                    "Source Type" := 0;
                    "Source Subtype" := 0;
                end;
            end;
        }
        field(7308; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(7309; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(7310; "Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
        }
        field(7311; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            TableRelation = if ("Destination Type" = const(Vendor)) Vendor
            else
            if ("Destination Type" = const(Customer)) Customer
            else
            if ("Destination Type" = const(Location)) Location
            else
            if ("Destination Type" = const(Item)) Item
            else
            if ("Destination Type" = const("Sales Order")) "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(7312; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(7313; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
        }
        field(7314; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(7315; "External Document No.2"; Code[35])
        {
            Caption = 'External Document No.2';
        }
        field(7316; "Do Not Fill Qty. to Handle"; Boolean)
        {
            Caption = 'Do Not Fill Qty. to Handle';
        }
    }

    keys
    {
        key(Key1; Type, "No.")
        {
            Clustered = true;
        }
        key(Key2; "Location Code", "Shipment Date")
        {
        }
        key(Key3; "Source Document", "Source No.", "Location Code")
        {
        }
        key(Key4; "Assigned User ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Location Code", "No.", "No. of Lines", "Source Document", "Source No.", "Assigned User ID")
        { }
    }

    trigger OnDelete()
    begin
        DeleteWhseActivHeader();
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            TestNoSeries();
            "No. Series" := GetNoSeriesCode();
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series", "Posting Date");

        end;

        if NoSeries.IsAutomatic(GetRegisteringNoSeriesCode()) then
            "Registering No. Series" := GetRegisteringNoSeriesCode();
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Location: Record Location;
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseSetup: Record "Warehouse Setup";
        InvtSetup: Record "Inventory Setup";
        NoSeries: Codeunit "No. Series";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SetUpWarehouseEmployeeInLocationErr: Label 'You must first set up user %1 as a warehouse employee. %2 %3', Comment = '%1 - user ID, %2 - caption, %3 - location code.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'You cannot change %1 because one or more lines exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure AssistEdit(OldWhseActivHeader: Record "Warehouse Activity Header"): Boolean
    begin
        WhseActivHeader := Rec;
        TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(GetNoSeriesCode(), OldWhseActivHeader."No. Series", WhseActivHeader."No. Series")
        then begin
            WhseActivHeader."No." := NoSeries.GetNextNo(WhseActivHeader."No. Series");
            Rec := WhseActivHeader;
            exit(true);
        end;
    end;

    local procedure GetNoSeriesCode() NoSeriesCode: Code[20]
    begin
        case Type of
            Type::"Put-away":
                begin
                    WhseSetup.Get();
                    NoSeriesCode := WhseSetup."Whse. Put-away Nos.";
                end;
            Type::Pick:
                begin
                    WhseSetup.Get();
                    NoSeriesCode := WhseSetup."Whse. Pick Nos.";
                end;
            Type::Movement:
                begin
                    WhseSetup.Get();
                    NoSeriesCode := WhseSetup."Whse. Movement Nos.";
                end;
            Type::"Invt. Put-away":
                begin
                    InvtSetup.Get();
                    NoSeriesCode := InvtSetup."Inventory Put-away Nos.";
                end;
            Type::"Invt. Pick":
                begin
                    InvtSetup.Get();
                    NoSeriesCode := InvtSetup."Inventory Pick Nos.";
                end;
            Type::"Invt. Movement":
                begin
                    InvtSetup.Get();
                    NoSeriesCode := InvtSetup."Inventory Movement Nos.";
                end;
        end;

        OnAfterGetNoSeriesCode(Rec, NoSeriesCode);
        exit(NoSeriesCode);
    end;

    local procedure TestNoSeries()
    begin
        case Type of
            Type::"Put-away":
                begin
                    WhseSetup.Get();
                    WhseSetup.TestField("Whse. Put-away Nos.");
                end;
            Type::Pick:
                begin
                    WhseSetup.Get();
                    WhseSetup.TestField("Whse. Pick Nos.");
                end;
            Type::Movement:
                begin
                    WhseSetup.Get();
                    WhseSetup.TestField("Whse. Movement Nos.");
                end;
            Type::"Invt. Put-away":
                begin
                    InvtSetup.Get();
                    InvtSetup.TestField("Inventory Put-away Nos.");
                end;
            Type::"Invt. Pick":
                begin
                    InvtSetup.Get();
                    InvtSetup.TestField("Inventory Pick Nos.");
                end;
            Type::"Invt. Movement":
                begin
                    InvtSetup.Get();
                    InvtSetup.TestField("Inventory Movement Nos.");
                end;
        end;
    end;

    local procedure GetRegisteringNoSeriesCode(): Code[20]
    var
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
        Result: Code[20];
    begin
        WhseSetup.Get();

        IsHandled := false;
        OnBeforeGetRegisteringNoSeriesCode(Rec, WhseSetup, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case Type of
            Type::"Put-away":
                exit(WhseSetup."Registered Whse. Put-away Nos.");
            Type::Pick:
                exit(WhseSetup."Registered Whse. Pick Nos.");
            Type::Movement:
                exit(WhseSetup."Registered Whse. Movement Nos.");
            Type::"Invt. Movement":
                begin
                    InventorySetup.Get();
                    exit(InventorySetup."Registered Invt. Movement Nos.");
                end;
        end;
    end;

    procedure SortWhseDoc()
    var
        WhseActivLine2: Record "Warehouse Activity Line";
        WhseActivLine3: Record "Warehouse Activity Line";
        SequenceNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSortWhseDoc(Rec, IsHandled);
        if not IsHandled then begin
            WhseActivLine2.LockTable();
            WhseActivLine2.SetRange("Activity Type", Type);
            WhseActivLine2.SetRange("No.", "No.");
            case "Sorting Method" of
                "Sorting Method"::Item:
                    WhseActivLine2.SetCurrentKey("Activity Type", "No.", "Item No.");
                "Sorting Method"::Document:
                    WhseActivLine2.SetCurrentKey("Activity Type", "No.", "Location Code", "Source Document", "Source No.");
                "Sorting Method"::"Shelf or Bin":
                    SortWhseDocByShelfOrBin(WhseActivLine2, SequenceNo);
                "Sorting Method"::"Due Date":
                    WhseActivLine2.SetCurrentKey("Activity Type", "No.", "Due Date");
                "Sorting Method"::"Ship-To":
                    WhseActivLine2.SetCurrentKey(
                      "Activity Type", "No.", "Destination Type", "Destination No.");
                "Sorting Method"::"Bin Ranking":
                    SortWhseDocByBinRanking(WhseActivLine2, SequenceNo);
                "Sorting Method"::"Action Type":
                    SortWhseDocByActionType(WhseActivLine2, SequenceNo);
                else
                    OnCaseSortWhseDoc(Rec, WhseActivLine2, SequenceNo);
            end;

            if SequenceNo = 0 then begin
                WhseActivLine2.SetRange("Breakbulk No.", 0);
                if WhseActivLine2.Find('-') then begin
                    SequenceNo := 10000;
                    repeat
                        SetActivityFilter(WhseActivLine2, WhseActivLine3);
                        if WhseActivLine3.Find('-') then
                            repeat
                                WhseActivLine3."Sorting Sequence No." := SequenceNo;
                                WhseActivLine3.Modify();
                                SequenceNo := SequenceNo + 10000;
                            until WhseActivLine3.Next() = 0;

                        WhseActivLine2."Sorting Sequence No." := SequenceNo;
                        WhseActivLine2.Modify();
                        SequenceNo := SequenceNo + 10000;
                    until WhseActivLine2.Next() = 0;
                end;
            end;
        end;
        OnAfterSortWhseDoc(Rec);
    end;

    procedure SortWhseDocByShelfOrBin(var WhseActivLine2: Record "Warehouse Activity Line"; var SequenceNo: Integer)
    var
        WhseActivLine3: Record "Warehouse Activity Line";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        SortingOrder: Option Bin,Shelf;
    begin
        GetLocation("Location Code");
        if Location."Bin Mandatory" then begin
            WhseActivLine2.SetCurrentKey("Activity Type", "No.", "Bin Code");
            if WhseActivLine2.Find('-') then
                if WhseActivLine2."Activity Type" <> WhseActivLine2."Activity Type"::Pick
                then begin
                    SequenceNo := 10000;
                    WhseActivLine2.SetRange("Action Type", WhseActivLine2."Action Type"::Place);
                    WhseActivLine2.SetRange("Breakbulk No.", 0);
                    if WhseActivLine2.Find('-') then
                        repeat
                            TempWhseActivLine.Init();
                            TempWhseActivLine.Copy(WhseActivLine2);
                            TempWhseActivLine.Insert();
                        until WhseActivLine2.Next() = 0;
                    TempWhseActivLine.SetRange("Breakbulk No.", 0);
                    if TempWhseActivLine.Find('-') then
                        repeat
                            WhseActivLine2.SetRange("Breakbulk No.", 0);
                            WhseActivLine2.SetRange("Action Type", WhseActivLine2."Action Type"::Take);
                            WhseActivLine2.SetRange("Whse. Document Type", TempWhseActivLine."Whse. Document Type");
                            WhseActivLine2.SetRange("Whse. Document No.", TempWhseActivLine."Whse. Document No.");
                            WhseActivLine2.SetRange("Whse. Document Line No.", TempWhseActivLine."Whse. Document Line No.");
                            OnSortWhseDocByShelfOrBinOnBeforeWhseActivLine2Find(WhseActivLine2, TempWhseActivLine);
                            if WhseActivLine2.Find('-') then
                                repeat
                                    SortTakeLines(WhseActivLine2, SequenceNo);
                                    WhseActivLine3.Get(
                                      TempWhseActivLine."Activity Type",
                                      TempWhseActivLine."No.", TempWhseActivLine."Line No.");
                                    WhseActivLine3."Sorting Sequence No." := SequenceNo;
                                    WhseActivLine3.Modify();
                                    SequenceNo := SequenceNo + 10000;
                                until WhseActivLine2.Next() = 0;
                        until TempWhseActivLine.Next() = 0;
                end else begin
                    SortLinesBinShelf(WhseActivLine2, SequenceNo, SortingOrder::Bin);
                    WhseActivLine2.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
                end;
        end else begin
            SortLinesBinShelf(WhseActivLine2, SequenceNo, SortingOrder::Shelf);
            WhseActivLine2.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
        end;
    end;

    local procedure SortWhseDocByBinRanking(var WhseActivLine2: Record "Warehouse Activity Line"; var SequenceNo: Integer)
    var
        WhseActivLine3: Record "Warehouse Activity Line";
        BreakBulkWhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine2.SetCurrentKey("Activity Type", "No.", "Bin Ranking");
        WhseActivLine2.SetRange("Breakbulk No.", 0);
        if WhseActivLine2.Find('-') then begin
            SequenceNo := 10000;
            WhseActivLine2.SetRange("Action Type", WhseActivLine2."Action Type"::Take);
            if WhseActivLine2.Find('-') then
                repeat
                    SetActivityFilter(WhseActivLine2, WhseActivLine3);
                    if WhseActivLine3.Find('-') then
                        repeat
                            WhseActivLine3."Sorting Sequence No." := SequenceNo;
                            WhseActivLine3.Modify();
                            SequenceNo := SequenceNo + 10000;
                            BreakBulkWhseActivLine.Copy(WhseActivLine3);
                            BreakBulkWhseActivLine.SetRange("Action Type", WhseActivLine3."Action Type"::Place);
                            BreakBulkWhseActivLine.SetRange("Breakbulk No.", WhseActivLine3."Breakbulk No.");
                            if BreakBulkWhseActivLine.Find('-') then
                                repeat
                                    BreakBulkWhseActivLine."Sorting Sequence No." := SequenceNo;
                                    BreakBulkWhseActivLine.Modify();
                                    SequenceNo := SequenceNo + 10000;
                                until BreakBulkWhseActivLine.Next() = 0;
                        until WhseActivLine3.Next() = 0;
                    WhseActivLine2."Sorting Sequence No." := SequenceNo;
                    WhseActivLine2.Modify();
                    SequenceNo := SequenceNo + 10000;
                until WhseActivLine2.Next() = 0;
            WhseActivLine2.SetRange("Action Type", WhseActivLine2."Action Type"::Place);
            WhseActivLine2.SetRange("Breakbulk No.", 0);
            if WhseActivLine2.Find('-') then
                repeat
                    WhseActivLine2."Sorting Sequence No." := SequenceNo;
                    WhseActivLine2.Modify();
                    SequenceNo := SequenceNo + 10000;
                until WhseActivLine2.Next() = 0;
        end;
    end;

    local procedure SortWhseDocByActionType(var WhseActivLine2: Record "Warehouse Activity Line"; var SequenceNo: Integer)
    var
        WhseActivLine3: Record "Warehouse Activity Line";
    begin
        WhseActivLine2.SetCurrentKey("Activity Type", "No.", "Action Type", "Bin Code");
        WhseActivLine2.SetRange("Action Type", WhseActivLine2."Action Type"::Take);
        if WhseActivLine2.Find('-') then begin
            SequenceNo := 10000;
            repeat
                WhseActivLine2."Sorting Sequence No." := SequenceNo;
                WhseActivLine2.Modify();
                SequenceNo := SequenceNo + 10000;
                if WhseActivLine2."Breakbulk No." <> 0 then begin
                    WhseActivLine3.Copy(WhseActivLine2);
                    WhseActivLine3.SetRange("Action Type", WhseActivLine2."Action Type"::Place);
                    WhseActivLine3.SetRange("Breakbulk No.", WhseActivLine2."Breakbulk No.");
                    if WhseActivLine3.Find('-') then
                        repeat
                            WhseActivLine3."Sorting Sequence No." := SequenceNo;
                            WhseActivLine3.Modify();
                            SequenceNo := SequenceNo + 10000;
                        until WhseActivLine3.Next() = 0;
                end;
            until WhseActivLine2.Next() = 0;
        end;
        WhseActivLine2.SetRange("Action Type", WhseActivLine2."Action Type"::Place);
        WhseActivLine2.SetRange("Breakbulk No.", 0);
        if WhseActivLine2.Find('-') then
            repeat
                WhseActivLine2."Sorting Sequence No." := SequenceNo;
                WhseActivLine2.Modify();
                SequenceNo := SequenceNo + 10000;
            until WhseActivLine2.Next() = 0;
    end;

    local procedure SortTakeLines(var NewWhseActivLine2: Record "Warehouse Activity Line"; var NewSequenceNo: Integer)
    var
        WhseActivLine3: Record "Warehouse Activity Line";
    begin
        if not NewWhseActivLine2.Mark() then begin
            WhseActivLine3.Copy(NewWhseActivLine2);
            WhseActivLine3.SetRange("Bin Code", NewWhseActivLine2."Bin Code");
            WhseActivLine3.SetFilter("Breakbulk No.", '<>0');
            WhseActivLine3.SetRange("Action Type");
            if WhseActivLine3.Find('-') then
                repeat
                    WhseActivLine3."Sorting Sequence No." := NewSequenceNo;
                    WhseActivLine3.Modify();
                    NewSequenceNo := NewSequenceNo + 10000;
                until WhseActivLine3.Next() = 0;

            NewWhseActivLine2.Mark(true);
            NewWhseActivLine2."Sorting Sequence No." := NewSequenceNo;
            NewWhseActivLine2.Modify();
            NewSequenceNo := NewSequenceNo + 10000;
        end;
    end;

    procedure SortLinesBinShelf(var WarehouseActivityLineParam: Record "Warehouse Activity Line"; var SeqNo: Integer; SortOrder: Option Bin,Shelf)
    var
        WarehouseActivityLineLocal: Record "Warehouse Activity Line";
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
        NewSequenceNo: Integer;
    begin
        TempWarehouseActivityLine.DeleteAll();
        SeqNo := 0;
        WarehouseActivityLineLocal.Copy(WarehouseActivityLineParam);
        WarehouseActivityLineLocal.SetCurrentKey("Activity Type", "No.", "Line No.");
        if not WarehouseActivityLineLocal.FindSet() then
            exit;
        repeat
            if (SortOrder = SortOrder::Bin) and
               (WarehouseActivityLineLocal."Action Type" = WarehouseActivityLineLocal."Action Type"::Take) or
               (SortOrder = SortOrder::Shelf) and
               (WarehouseActivityLineLocal."Action Type" = WarehouseActivityLineLocal."Action Type"::" ")
            then begin
                TempWarehouseActivityLine := WarehouseActivityLineLocal;
                TempWarehouseActivityLine.Insert();
            end;
        until WarehouseActivityLineLocal.Next() = 0;
        case SortOrder of
            SortOrder::Bin:
                TempWarehouseActivityLine.SetCurrentKey("Activity Type", "No.", "Bin Code", "Shelf No.");
            SortOrder::Shelf:
                TempWarehouseActivityLine.SetCurrentKey("Activity Type", "No.", "Shelf No.");
        end;
        if not TempWarehouseActivityLine.Find('-') then
            exit;
        NewSequenceNo := 0;
        repeat
            NewSequenceNo += 10000;
            WarehouseActivityLineLocal.Get(
              TempWarehouseActivityLine."Activity Type", TempWarehouseActivityLine."No.", TempWarehouseActivityLine."Line No.");
            WarehouseActivityLineLocal."Sorting Sequence No." := NewSequenceNo;
            WarehouseActivityLineLocal.Modify();
            NewSequenceNo += 10000;
            if WarehouseActivityLineLocal.Next() <> 0 then
                if WarehouseActivityLineLocal."Action Type" = WarehouseActivityLineLocal."Action Type"::Place then begin
                    WarehouseActivityLineLocal."Sorting Sequence No." := NewSequenceNo;
                    WarehouseActivityLineLocal.Modify();
                end;
        until TempWarehouseActivityLine.Next() = 0;
        SeqNo := NewSequenceNo;
    end;

    local procedure SetBreakbulkFilter()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.SetRange("Activity Type", Type);
        WhseActivLine.SetRange("No.", "No.");
        WhseActivLine.SetRange("Original Breakbulk", true);
        if "Breakbulk Filter" then
            WhseActivLine.ModifyAll(Breakbulk, true)
        else
            WhseActivLine.ModifyAll(Breakbulk, false)
    end;

    procedure SetActivityFilter(var WhseActivLineFrom: Record "Warehouse Activity Line"; var WhseActivLineTo: Record "Warehouse Activity Line")
    begin
        WhseActivLineTo.Copy(WhseActivLineFrom);
        WhseActivLineTo.SetRange("Bin Code", WhseActivLineFrom."Bin Code");
        WhseActivLineTo.SetFilter("Breakbulk No.", '<>0');
        WhseActivLineTo.SetRange("Whse. Document Type", WhseActivLineFrom."Whse. Document Type");
        WhseActivLineTo.SetRange("Whse. Document No.", WhseActivLineFrom."Whse. Document No.");
        WhseActivLineTo.SetRange("Whse. Document Line No.", WhseActivLineFrom."Whse. Document Line No.");
    end;

    local procedure DeleteWhseActivHeader()
    var
        WhseActivLine2: Record "Warehouse Activity Line";
        WhseCommentLine: Record "Warehouse Comment Line";
    begin
        WhseActivLine2.SetRange("Activity Type", Type);
        WhseActivLine2.SetRange("No.", "No.");
        if WhseActivLine2.FindFirst() then
            WhseActivLine2.DeleteRelatedWhseActivLines(WhseActivLine2, true);

        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Whse. Activity Header");
        WhseCommentLine.SetRange(Type, Type);
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.DeleteAll();

        OnAfterDeleteWhseActivHeader(Rec);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure LookupActivityHeader(var CurrentLocationCode: Code[10]; var WhseActivHeader: Record "Warehouse Activity Header")
    begin
        Commit();
        if UserId <> '' then begin
            WhseActivHeader.FilterGroup := 2;
            WhseActivHeader.SetRange("Location Code");
        end;
        if PAGE.RunModal(0, WhseActivHeader) = ACTION::LookupOK then;
        if UserId <> '' then begin
            WhseActivHeader.FilterGroup := 2;
            WhseActivHeader.SetRange("Location Code", WhseActivHeader."Location Code");
            WhseActivHeader.FilterGroup := 0;
        end;
        CurrentLocationCode := WhseActivHeader."Location Code";
    end;

    procedure LineExist(): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.SetRange("Activity Type", Type);
        WhseActivLine.SetRange("No.", "No.");
        exit(not WhseActivLine.IsEmpty);
    end;

    procedure FindFirstAllowedRec(Which: Text[1024]): Boolean
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        WMSManagement: Codeunit "WMS Management";
    begin
        if Find(Which) then begin
            WhseActivHeader := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowedToView("Location Code") then
                    exit(true);

                if Next(1) = 0 then begin
                    Rec := WhseActivHeader;
                    if Find(Which) then
                        while true do begin
                            if WMSManagement.LocationIsAllowedToView("Location Code") then
                                exit(true);

                            if Next(-1) = 0 then
                                exit(false);
                        end;
                end;
            end;
        end;
        exit(false);
    end;

    procedure FindNextAllowedRec(Steps: Integer): Integer
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        WMSManagement: Codeunit "WMS Management";
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        RealSteps := 0;
        if Steps <> 0 then begin
            WhseActivHeader := Rec;
            repeat
                NextSteps := Next(Steps / Abs(Steps));
                if WMSManagement.LocationIsAllowedToView("Location Code") then begin
                    RealSteps := RealSteps + NextSteps;
                    WhseActivHeader := Rec;
                end;
            until (NextSteps = 0) or (RealSteps = Steps);
            Rec := WhseActivHeader;
            if not Find() then;
        end;
        exit(RealSteps);
    end;

    procedure ErrorIfUserIsNotWhseEmployee()
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeErrorIfUserIsNotWhseEmployee("Location Code", IsHandled);
        if IsHandled then
            exit;

        WMSManagement.CheckUserIsWhseEmployee();
    end;

    procedure GetUserLocation(): Code[10]
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LocationCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUserLocation(LocationCode, IsHandled);
        if IsHandled then
            exit(LocationCode);

        WarehouseEmployee.SetCurrentKey(Default);
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.SetRange(Default, true);
        if WarehouseEmployee.FindFirst() then
            exit(WarehouseEmployee."Location Code");

        WarehouseEmployee.SetRange(Default);
        WarehouseEmployee.FindFirst();
        exit(WarehouseEmployee."Location Code");
    end;

    local procedure ClearDestinationFields()
    begin
        "Destination Type" := "Destination Type"::" ";
        "Destination No." := '';
    end;

    procedure Lock()
    begin
        LockTable();
        if FindLast() then;
    end;

    procedure BinCodeMandatory(): Boolean;
    begin
        GetLocation("Location Code");
        exit(Location."Bin Mandatory");
    end;

    internal procedure IsInvoiceNoMandatory(): Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
    begin
        exit(PostingSelectionManagement.IsPostingInvoiceMandatoryPurchase());
    end;

    internal procedure AssignToCurrentUser()
    begin
        if Rec.IsEmpty() then
            exit;

        Rec.Validate("Assigned User ID", UserId());
        Rec.Modify()
    end;

    internal procedure ProdWhseHandlingIsInventoryPutaway(Location: Record Location) Result: Boolean
    begin
        OnProdWhseHandlingIsInventoryPutaway(Location, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteWhseActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfUserIsNotWhseEmployee(LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUserLocation(var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSortWhseDoc(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCaseSortWhseDoc(WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var SequenceNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRegisteringNoSeriesCode(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseSetup: Record "Warehouse Setup"; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSortWhseDoc(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSortWhseDocByShelfOrBinOnBeforeWhseActivLine2Find(var WarehouseActivityLine2: Record "Warehouse Activity Line"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSourceDocumentOnAssignSourceType(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [InternalEvent(false)]
    local procedure OnProdWhseHandlingIsInventoryPutaway(Location: Record Location; var Result: Boolean)
    begin
    end;
}
