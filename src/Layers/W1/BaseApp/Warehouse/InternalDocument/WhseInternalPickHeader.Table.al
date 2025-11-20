// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

table 7333 "Whse. Internal Pick Header"
{
    Caption = 'Whse. Internal Pick Header';
    DataCaptionFields = "No.";
    LookupPageID = "Whse. Internal Pick List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                WhseSetup.Get();
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(WhseSetup."Whse. Internal Pick Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                WhseInternalPickLine: Record "Whse. Internal Pick Line";
            begin
                if not WmsManagement.LocationIsAllowed("Location Code") then
                    Error(Text003, FieldCaption("Location Code"), "Location Code");

                CheckPickRequired("Location Code");
                if "Location Code" <> '' then begin
                    Location.Get("Location Code");
                    Location.TestField("Directed Put-away and Pick");
                end;
                if "Location Code" <> xRec."Location Code" then begin
                    "To Zone Code" := '';
                    "To Bin Code" := '';
                    WhseInternalPickLine.SetRange("No.", "No.");
                    if not WhseInternalPickLine.IsEmpty() then
                        Error(
                          Text001,
                          FieldCaption("Location Code"));
                end;
                if UserId <> '' then begin
                    FilterGroup := 2;
                    SetRange("Location Code", "Location Code");
                    FilterGroup := 0;
                end;
            end;
        }
        field(3; "Assigned User ID"; Code[50])
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
        field(4; "Assignment Date"; Date)
        {
            Caption = 'Assignment Date';
            Editable = false;
        }
        field(5; "Assignment Time"; Time)
        {
            Caption = 'Assignment Time';
            Editable = false;
        }
        field(6; "Sorting Method"; Enum "Warehouse Internal Sorting Method")
        {
            Caption = 'Sorting Method';

            trigger OnValidate()
            begin
                if "Sorting Method" <> xRec."Sorting Method" then
                    SortWhseDoc();
            end;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("Warehouse Comment Line" where("Table Name" = const("Internal Pick"),
                                                                Type = const(" "),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "To Bin Code"; Code[20])
        {
            Caption = 'To Bin Code';
            TableRelation = if ("To Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("To Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                                  "Zone Code" = field("To Zone Code"));

            trigger OnValidate()
            var
                Bin: Record Bin;
            begin
                if xRec."To Bin Code" <> "To Bin Code" then begin
                    TestField(Status, Status::Open);
                    if "To Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        if "To Bin Code" = Location."Adjustment Bin Code" then
                            FieldError(
                              "To Bin Code",
                              StrSubstNo(
                                Text005, Location.FieldCaption("Adjustment Bin Code"),
                                Location.TableCaption()));
                        Bin.Get("Location Code", "To Bin Code");
                        "To Zone Code" := Bin."Zone Code";
                    end;
                    MessageIfInternalPickLinesExist(FieldCaption("To Bin Code"));
                end;
            end;
        }
        field(13; "To Zone Code"; Code[10])
        {
            Caption = 'To Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "To Zone Code" <> xRec."To Zone Code" then begin
                    TestField(Status, Status::Open);
                    GetLocation("Location Code");
                    Location.TestField("Directed Put-away and Pick");
                    "To Bin Code" := '';
                    MessageIfInternalPickLinesExist(FieldCaption("To Zone Code"));
                end;
            end;
        }
        field(34; "Document Status"; Option)
        {
            Caption = 'Document Status';
            Editable = false;
            OptionCaption = ' ,Partially Picked,Completely Picked';
            OptionMembers = " ","Partially Picked","Completely Picked";

            trigger OnValidate()
            var
                WhsePickRequest: Record "Whse. Pick Request";
            begin
                if "Document Status" <> xRec."Document Status" then begin
                    WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::"Internal Pick");
                    WhsePickRequest.SetRange("Document No.", "No.");
                    if not WhsePickRequest.IsEmpty() then
                        WhsePickRequest.ModifyAll(
                          "Completely Picked", "Document Status" = "Document Status"::"Completely Picked");
                end;
            end;
        }
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                MessageIfInternalPickLinesExist(FieldCaption("Due Date"));
            end;
        }
        field(47; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);
        DeleteRelatedLines();
    end;

    trigger OnInsert()
    begin
        WhseSetup.Get();
        if "No." = '' then begin
            WhseSetup.TestField("Whse. Internal Pick Nos.");
                "No. Series" := WhseSetup."Whse. Internal Pick Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Location: Record Location;
        WhseSetup: Record "Warehouse Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        NoSeries: Codeunit "No. Series";
        WmsManagement: Codeunit "WMS Management";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change the %1, because the document has one or more lines.';
        Text003: Label 'You are not allowed to use %1 %2.';
        Text005: Label 'must not be the %1 of the %2';
        Text006: Label 'You have changed %1 on the %2, but it has not been changed on the existing Warehouse Internal Pick Lines.\';
#pragma warning restore AA0470
        Text007: Label 'You must update the existing Warehouse Internal Pick Lines manually.';
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    procedure AssistEdit(OldWhseInternalPickHeader: Record "Whse. Internal Pick Header"): Boolean
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
    begin
        WhseSetup.Get();
        WhseInternalPickHeader := Rec;
        WhseSetup.TestField("Whse. Internal Pick Nos.");
        if NoSeries.LookupRelatedNoSeries(WhseSetup."Whse. Internal Pick Nos.", OldWhseInternalPickHeader."No. Series", WhseInternalPickHeader."No. Series") then begin
            WhseInternalPickHeader."No." := NoSeries.GetNextNo(WhseInternalPickHeader."No. Series");
            Rec := WhseInternalPickHeader;
            exit(true);
        end;
    end;

    local procedure SortWhseDoc()
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        SequenceNo: Integer;
    begin
        WhseInternalPickLine.SetRange("No.", Rec."No.");
        case "Sorting Method" of
            "Sorting Method"::Item:
                WhseInternalPickLine.SetCurrentKey("No.", WhseInternalPickLine."Item No.");
            "Sorting Method"::"Shelf or Bin":
                begin
                    GetLocation(Rec."Location Code");
                    if Location."Bin Mandatory" then
                        WhseInternalPickLine.SetCurrentKey("No.", WhseInternalPickLine."To Bin Code")
                    else
                        WhseInternalPickLine.SetCurrentKey("No.", WhseInternalPickLine."Shelf No.");
                end;
            "Sorting Method"::"Due Date":
                WhseInternalPickLine.SetCurrentKey("No.", WhseInternalPickLine."Due Date");
            else
                OnSortWhseDocOnCaseSortingMethodElse(Rec);
        end;

        if WhseInternalPickLine.Find('-') then begin
            SequenceNo := 10000;
            repeat
                WhseInternalPickLine."Sorting Sequence No." := SequenceNo;
                WhseInternalPickLine.Modify();
                SequenceNo := SequenceNo + 10000;
            until WhseInternalPickLine.Next() = 0;
        end;
    end;

    procedure GetDocumentStatus(SkipLineNo: Integer): Integer
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        WhseInternalPickLine.SetRange("No.", "No.");
        if SkipLineNo <> 0 then
            WhseInternalPickLine.SetFilter("Line No.", '<>%1', SkipLineNo);

        WhseInternalPickLine.SetRange(Status, WhseInternalPickLine.Status::"Completely Picked");
        if not WhseInternalPickLine.IsEmpty() then begin
            WhseInternalPickLine.SetFilter(Status, '<>%1', WhseInternalPickLine.Status::"Completely Picked");
            if not WhseInternalPickLine.IsEmpty() then
                exit(WhseInternalPickLine.Status::"Partially Picked");

            exit(WhseInternalPickLine.Status::"Completely Picked");
        end else begin
            WhseInternalPickLine.SetRange(Status, WhseInternalPickLine.Status::"Partially Picked");
            if not WhseInternalPickLine.IsEmpty() then
                exit(WhseInternalPickLine.Status::"Partially Picked");
        end;

        exit(WhseInternalPickLine.Status::" ");
    end;

    procedure MessageIfInternalPickLinesExist(ChangedFieldName: Text[80])
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        WhseInternalPickLine.SetRange("No.", "No.");
        if not WhseInternalPickLine.IsEmpty() then
            if not HideValidationDialog then
                Message(
                  StrSubstNo(
                    Text006, ChangedFieldName, TableCaption) + Text007);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure SetWhseLocationFilter()
    var
        WmsManagement: Codeunit "WMS Management";
    begin
        if UserId <> '' then begin
            FilterGroup := 2;
            SetRange("Location Code", WmsManagement.GetAllowedLocation("Location Code"));
            FilterGroup := 0;
        end;
    end;

    procedure LookupLocation(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    var
        Location: Record Location;
    begin
        Commit();
        Location.FilterGroup := 2;
        Location.SetRange(Code);
        if PAGE.RunModal(PAGE::"Locations with Warehouse List", Location) = ACTION::LookupOK then
            WhseInternalPickHeader.Validate("Location Code", Location.Code);
        Location.FilterGroup := 0;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure DeleteRelatedLines()
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseCommentLine: Record "Warehouse Comment Line";
    begin
        WhseInternalPickLine.SetRange("No.", "No.");
        WhseInternalPickLine.DeleteAll();

        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::"Internal Pick");
        WhsePickRequest.SetRange("Document No.", "No.");
        if not WhsePickRequest.IsEmpty() then
            WhsePickRequest.DeleteAll();

        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Internal Pick");
        WhseCommentLine.SetRange(Type, WhseCommentLine.Type::" ");
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.DeleteAll();

        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          Database::"Whse. Internal Pick Line", 0, "No.", '', 0, 0, '', false);
    end;

    procedure CheckPickRequired(LocationCode: Code[10])
    begin
        if LocationCode = '' then begin
            WhseSetup.Get();
            WhseSetup.TestField("Require Pick");
        end else begin
            GetLocation(LocationCode);
            Location.TestField("Require Pick");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSortWhseDocOnCaseSortingMethodElse(WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    begin
    end;
}
