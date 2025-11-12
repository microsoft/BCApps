// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Manufacturing.ProductionBOM;

table 5416 "Prod. Order Comp. Cmt Line"
{
    Caption = 'Prod. Order Comp. Cmt Line';
    DrillDownPageID = "Prod. Order BOM Cmt List";
    LookupPageID = "Prod. Order BOM Cmt List";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Prod. Order BOM Line No."; Integer)
        {
            Caption = 'Prod. Order BOM Line No.';
            NotBlank = true;
            TableRelation = "Prod. Order Component"."Line No." where(Status = field(Status),
                                                                      "Prod. Order No." = field("Prod. Order No."),
                                                                      "Prod. Order Line No." = field("Prod. Order Line No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
        }
        field(12; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(13; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(22; Status; Enum "Production Order Status")
        {
            Caption = 'Status';
        }
        field(23; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            NotBlank = true;
            TableRelation = "Production Order"."No." where(Status = field(Status));
        }
        field(24; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            NotBlank = true;
            TableRelation = "Prod. Order Line"."Line No." where(Status = field(Status),
                                                                 "Prod. Order No." = field("Prod. Order No."));
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Prod. Order Line No.", "Prod. Order BOM Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);
    end;

    trigger OnInsert()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);
    end;

    trigger OnModify()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'A %1 %2 cannot be inserted, modified, or deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetupNewLine()
    var
        ProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
    begin
        ProdOrderBOMComment.SetRange(Status, Status);
        ProdOrderBOMComment.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderBOMComment.SetRange("Prod. Order Line No.", "Prod. Order Line No.");
        ProdOrderBOMComment.SetRange(
          "Prod. Order BOM Line No.", "Prod. Order BOM Line No.");
        ProdOrderBOMComment.SetRange(Date, WorkDate());
        if not ProdOrderBOMComment.FindFirst() then
            Date := WorkDate();
    end;

    procedure Caption(): Text
    var
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if GetFilters = '' then
            exit('');

        if not ProdOrder.Get(Status, "Prod. Order No.") then
            exit('');

        if not ProdOrderComp.Get(Status, "Prod. Order No.", "Prod. Order Line No.", "Prod. Order BOM Line No.") then
            Clear(ProdOrderComp);

        exit(
          StrSubstNo('%1 %2 %3 %4 %5',
            Status, "Prod. Order No.", ProdOrder.Description, ProdOrderComp."Item No.", ProdOrderComp.Description));
    end;

    [Scope('OnPrem')]
    procedure CopyFromProdBOMComponent(ProductionBOMCommentLine: Record "Production BOM Comment Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
        TransferFields(ProductionBOMCommentLine);
        Status := ProdOrderComponent.Status;
        "Prod. Order No." := ProdOrderComponent."Prod. Order No.";
        "Prod. Order Line No." := ProdOrderComponent."Prod. Order Line No.";
        "Prod. Order BOM Line No." := ProdOrderComponent."Line No.";
    end;
}

