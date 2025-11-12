// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.History;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Projects.Project.Job;

table 914 "Posted Assemble-to-Order Link"
{
    Caption = 'Posted Assemble-to-Order Link';
    DataClassification = CustomerContent;
    Permissions = TableData "Posted Assembly Header" = d,
                  TableData "Posted Assemble-to-Order Link" = d;

    fields
    {
        field(1; "Assembly Document Type"; Option)
        {
            Caption = 'Assembly Document Type';
            OptionCaption = ' ,Assembly';
            OptionMembers = " ",Assembly;
        }
        field(2; "Assembly Document No."; Code[20])
        {
            Caption = 'Assembly Document No.';
            TableRelation = if ("Assembly Document Type" = const(Assembly)) "Posted Assembly Header" where("No." = field("Assembly Document No."));
        }
        field(12; "Document Type"; enum "Posted Assembly Link Type")
        {
            Caption = 'Document Type';
        }
        field(13; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = if ("Document Type" = const("Sales Shipment")) "Sales Shipment Line" where("Document No." = field("Document No."),
                                                                                                      "Line No." = field("Document Line No."));
        }
        field(14; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(20; "Assembled Quantity"; Decimal)
        {
            Caption = 'Assembled Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(21; "Assembled Quantity (Base)"; Decimal)
        {
            Caption = 'Assembled Quantity (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(32; "Assembly Order No."; Code[20])
        {
            Caption = 'Assembly Order No.';
        }
        field(33; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(34; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(40; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        field(41; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
    }

    keys
    {
        key(Key1; "Assembly Document Type", "Assembly Document No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", "Document Line No.")
        {
        }
        key(Key3; "Order No.", "Order Line No.")
        {
        }
        key(Key4; "Job No.", "Job Task No.", "Document Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        PostedAsmHeader: Record "Posted Assembly Header";

    procedure AsmExistsForPostedShipmentLine(SalesShipmentLine: Record "Sales Shipment Line"): Boolean
    begin
        Reset();
        SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        SetRange("Document Type", "Document Type"::"Sales Shipment");
        SetRange("Document No.", SalesShipmentLine."Document No.");
        SetRange("Document Line No.", SalesShipmentLine."Line No.");
        exit(FindFirst());
    end;

    procedure DeleteAsmFromSalesShptLine(SalesShptLine: Record "Sales Shipment Line")
    begin
        if AsmExistsForPostedShipmentLine(SalesShptLine) then begin
            Delete();

            if GetPostedAsmHeader() then begin
                PostedAsmHeader.Delete(true);
                PostedAsmHeader.Init();
            end;
        end;
    end;

    procedure ShowPostedAsm(SalesShptLine: Record "Sales Shipment Line")
    begin
        if AsmExistsForPostedShipmentLine(SalesShptLine) then begin
            GetPostedAsmHeader();
            PAGE.RunModal(PAGE::"Posted Assembly Order", PostedAsmHeader);
        end;
    end;

    procedure ShowSalesShpt(PostedAsmHeader: Record "Posted Assembly Header")
    var
        SalesShptHeader: Record "Sales Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSalesShpt(Rec, PostedAsmHeader, IsHandled);
        if IsHandled then
            exit;

        if Get("Assembly Document Type"::Assembly, PostedAsmHeader."No.") then
            if "Document Type" = "Document Type"::"Sales Shipment" then begin
                SalesShptHeader.Get("Document No.");
                PAGE.RunModal(PAGE::"Posted Sales Shipment", SalesShptHeader);
            end;
    end;

    local procedure GetPostedAsmHeader(): Boolean
    begin
        if PostedAsmHeader."No." = "Assembly Document No." then
            exit(true);
        exit(PostedAsmHeader.Get("Assembly Document No."));
    end;

    procedure FindLinksFromSalesLine(SalesLine: Record "Sales Line"): Boolean
    begin
        case SalesLine."Document Type" of
            SalesLine."Document Type"::Order:
                begin
                    SetCurrentKey("Order No.", "Order Line No.");
                    SetRange("Order No.", SalesLine."Document No.");
                    SetRange("Order Line No.", SalesLine."Line No.");
                end;
            SalesLine."Document Type"::Invoice:
                begin
                    SetCurrentKey("Document Type", "Document No.", "Document Line No.");
                    SetRange("Document Type", "Document Type"::"Sales Shipment");
                    SetRange("Document No.", SalesLine."Shipment No.");
                    SetRange("Document Line No.", SalesLine."Shipment Line No.");
                end;
            else
                SalesLine.FieldError("Document Type");
        end;
        exit(FindSet());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSalesShpt(var PostedAssembletoOrderLink: Record "Posted Assemble-to-Order Link"; PostedAsmHeader: Record "Posted Assembly Header"; var IsHandled: Boolean)
    begin
    end;
}
