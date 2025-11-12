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

table 7331 "Whse. Internal Put-away Header"
{
    Caption = 'Whse. Internal Put-away Header';
    LookupPageID = "Whse. Internal Put-away List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                WhseSetup.Get();
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(WhseSetup."Whse. Internal Put-away Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            begin
                if not WmsManagement.LocationIsAllowed("Location Code") then
                    Error(Text006, FieldCaption("Location Code"), "Location Code");

                CheckPutawayRequired("Location Code");
                if "Location Code" <> '' then begin
                    Location.Get("Location Code");
                    Location.TestField("Directed Put-away and Pick");
                end;
                if "Location Code" <> xRec."Location Code" then begin
                    "From Zone Code" := '';
                    "From Bin Code" := '';
                    WhseInternalPutAwayLine.SetRange("No.", "No.");
                    if WhseInternalPutAwayLine.Find('-') then
                        Error(
                          Text005,
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
        field(6; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(7; Comment; Boolean)
        {
            CalcFormula = exist("Warehouse Comment Line" where("Table Name" = const("Internal Put-away"),
                                                                Type = const(" "),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "From Bin Code"; Code[20])
        {
            Caption = 'From Bin Code';
            TableRelation = if ("From Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("From Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                                    "Zone Code" = field("From Zone Code"));

            trigger OnValidate()
            var
                BinType: Record "Bin Type";
            begin
                if xRec."From Bin Code" <> "From Bin Code" then begin
                    if "From Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        if "From Bin Code" = Location."Adjustment Bin Code" then
                            FieldError(
                              "From Bin Code",
                              StrSubstNo(
                                Text001, Location.FieldCaption("Adjustment Bin Code"),
                                Location.TableCaption()));

                        Bin.Get("Location Code", "From Bin Code");
                        if Bin."Bin Type Code" <> '' then
                            if BinType.Get(Bin."Bin Type Code") then
                                BinType.TestField(Receive, false);

                        "From Zone Code" := Bin."Zone Code";
                    end;
                    MessageIfInternalPutawayLinesExist(FieldCaption("From Bin Code"));
                end;
            end;
        }
        field(9; "From Zone Code"; Code[10])
        {
            Caption = 'From Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "From Zone Code" <> xRec."From Zone Code" then begin
                    GetLocation("Location Code");
                    if "From Zone Code" <> '' then
                        Location.TestField("Directed Put-away and Pick");
                    "From Bin Code" := '';
                    MessageIfInternalPutawayLinesExist(FieldCaption("From Zone Code"));
                end;
            end;
        }
        field(10; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                MessageIfInternalPutawayLinesExist(FieldCaption("Due Date"));
            end;
        }
        field(11; "Document Status"; Option)
        {
            Caption = 'Document Status';
            Editable = false;
            OptionCaption = ' ,Partially Put Away,Completely Put Away';
            OptionMembers = " ","Partially Put Away","Completely Put Away";

            trigger OnValidate()
            var
                WhsePutAwayRequest: Record "Whse. Put-away Request";
            begin
                if "Document Status" <> xRec."Document Status" then begin
                    WhsePutAwayRequest.SetRange("Document Type", WhsePutAwayRequest."Document Type"::"Internal Put-away");
                    WhsePutAwayRequest.SetRange("Document No.", "No.");
                    WhsePutAwayRequest.ModifyAll(
                      "Completely Put Away", "Document Status" = "Document Status"::"Completely Put Away");
                end;
            end;
        }
        field(12; "Sorting Method"; Enum "Warehouse Internal Sorting Method")
        {
            Caption = 'Sorting Method';

            trigger OnValidate()
            begin
                if "Sorting Method" <> xRec."Sorting Method" then
                    SortWhseDoc();
            end;
        }
        field(13; Status; Option)
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
            WhseSetup.TestField("Whse. Internal Put-away Nos.");
                "No. Series" := WhseSetup."Whse. Internal Put-away Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnRename()
    begin
        Error(Text004, TableCaption);
    end;

    var
        Location: Record Location;
        Bin: Record Bin;
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseSetup: Record "Warehouse Setup";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        NoSeries: Codeunit "No. Series";
        WmsManagement: Codeunit "WMS Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'must not be the %1 of the %2';
        Text002: Label 'You have changed %1 on the %2, but it has not been changed on the existing Warehouse Internal Put-Away Lines.\';
#pragma warning restore AA0470
        Text003: Label 'You must update the existing Warehouse Internal Put-Away Lines manually.';
#pragma warning disable AA0470
        Text004: Label 'You cannot rename a %1.';
        Text005: Label 'You cannot change the %1, because the document has one or more lines.';
        Text006: Label 'You are not allowed to use %1 %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    local procedure SortWhseDoc()
    var
        SequenceNo: Integer;
    begin
        WhseInternalPutAwayLine.Reset();
        WhseInternalPutAwayLine.SetRange("No.", "No.");
        case "Sorting Method" of
            "Sorting Method"::Item:
                WhseInternalPutAwayLine.SetCurrentKey("No.", "Item No.");
            "Sorting Method"::"Shelf or Bin":
                begin
                    GetLocation("Location Code");
                    if Location."Bin Mandatory" then
                        WhseInternalPutAwayLine.SetCurrentKey("No.", "From Bin Code")
                    else
                        WhseInternalPutAwayLine.SetCurrentKey("No.", "Shelf No.");
                end;
            "Sorting Method"::"Due Date":
                WhseInternalPutAwayLine.SetCurrentKey("No.", "Due Date");
            else
                OnSortWhseDocOnCaseSortingMethodElse(Rec);
        end;

        if WhseInternalPutAwayLine.Find('-') then begin
            SequenceNo := 10000;
            repeat
                WhseInternalPutAwayLine."Sorting Sequence No." := SequenceNo;
                WhseInternalPutAwayLine.Modify();
                SequenceNo := SequenceNo + 10000;
            until WhseInternalPutAwayLine.Next() = 0;
        end;
    end;

    procedure MessageIfInternalPutawayLinesExist(ChangedFieldName: Text[80])
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
    begin
        WhseInternalPutAwayLine.SetRange("No.", "No.");
        if not WhseInternalPutAwayLine.IsEmpty() then
            if not HideValidationDialog then
                Message(
                  StrSubstNo(
                    Text002, ChangedFieldName, TableCaption) + Text003);
    end;

    procedure AssistEdit(OldWhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"): Boolean
    begin
        WhseSetup.Get();
        WhseInternalPutAwayHeader := Rec;
        WhseSetup.TestField("Whse. Internal Put-away Nos.");
        if NoSeries.LookupRelatedNoSeries(WhseSetup."Whse. Internal Put-away Nos.", OldWhseInternalPutAwayHeader."No. Series", WhseInternalPutAwayHeader."No. Series") then begin
            WhseInternalPutAwayHeader."No." := NoSeries.GetNextNo(WhseInternalPutAwayHeader."No. Series");
            Rec := WhseInternalPutAwayHeader;
            exit(true);
        end;
    end;

    procedure GetDocumentStatus(SkipLineNo: Integer): Integer
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
    begin
        WhseInternalPutAwayLine.SetRange("No.", "No.");
        if SkipLineNo <> 0 then
            WhseInternalPutAwayLine.SetFilter("Line No.", '<>%1', SkipLineNo);

        WhseInternalPutAwayLine.SetRange(Status, WhseInternalPutAwayLine.Status::"Completely Put Away");
        if not WhseInternalPutAwayLine.IsEmpty() then begin
            WhseInternalPutAwayLine.SetFilter(Status, '<>%1', WhseInternalPutAwayLine.Status::"Completely Put Away");
            if not WhseInternalPutAwayLine.IsEmpty() then
                exit(WhseInternalPutAwayLine.Status::"Partially Put Away");

            exit(WhseInternalPutAwayLine.Status::"Completely Put Away");
        end else begin
            WhseInternalPutAwayLine.SetRange(Status, WhseInternalPutAwayLine.Status::"Partially Put Away");
            if not WhseInternalPutAwayLine.IsEmpty() then
                exit(WhseInternalPutAwayLine.Status::"Partially Put Away");
        end;

        exit(WhseInternalPutAwayLine.Status::" ");
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

    procedure LookupLocation(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header")
    var
        Location: Record Location;
    begin
        Commit();
        Location.FilterGroup := 2;
        Location.SetRange(Code);
        if PAGE.RunModal(PAGE::"Locations with Warehouse List", Location) = ACTION::LookupOK then
            WhseInternalPutAwayHeader.Validate("Location Code", Location.Code);
        Location.FilterGroup := 0;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure DeleteRelatedLines()
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        WhseCommentLine: Record "Warehouse Comment Line";
    begin
        WhseInternalPutAwayLine.SetRange("No.", "No.");
        WhseInternalPutAwayLine.DeleteAll();

        WhsePutAwayRequest.SetRange("Document Type", WhsePutAwayRequest."Document Type"::"Internal Put-away");
        WhsePutAwayRequest.SetRange("Document No.", "No.");
        WhsePutAwayRequest.DeleteAll();

        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Internal Put-away");
        WhseCommentLine.SetRange(Type, WhseCommentLine.Type::" ");
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.DeleteAll();

        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          Database::"Whse. Internal Put-away Line", 0, "No.", '', 0, 0, '', false);
    end;

    procedure CheckPutawayRequired(LocationCode: Code[10])
    begin
        if LocationCode = '' then begin
            WhseSetup.Get();
            WhseSetup.TestField("Require Put-away");
        end else begin
            GetLocation(LocationCode);
            Location.TestField("Require Put-away");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSortWhseDocOnCaseSortingMethodElse(WhseInternalPutawayHeader: Record "Whse. Internal Put-away Header")
    begin
    end;
}
