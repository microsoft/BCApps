// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;

table 5744 "Transfer Shipment Header"
{
    Caption = 'Transfer Shipment Header';
    DataCaptionFields = "No.";
    LookupPageID = "Posted Transfer Shipments";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            ToolTip = 'Specifies the code of the location that items are transferred from.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(3; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
            ToolTip = 'Specifies the name of the sender at the location that the items are transferred from.';
        }
        field(4; "Transfer-from Name 2"; Text[50])
        {
            Caption = 'Transfer-from Name 2';
            ToolTip = 'Specifies an additional part of the name of the sender at the location that the items are transferred from.';
        }
        field(5; "Transfer-from Address"; Text[100])
        {
            Caption = 'Transfer-from Address';
            ToolTip = 'Specifies the address of the location that the items are transferred from.';
        }
        field(6; "Transfer-from Address 2"; Text[50])
        {
            Caption = 'Transfer-from Address 2';
            ToolTip = 'Specifies an additional part of the address of the location that items are transferred from.';
        }
        field(7; "Transfer-from Post Code"; Code[20])
        {
            Caption = 'Transfer-from Post Code';
            ToolTip = 'Specifies the postal code of the location that the items are transferred from.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';
            ToolTip = 'Specifies the city of the location that the items are transferred from.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(9; "Transfer-from County"; Text[30])
        {
            CaptionClass = '5,7,' + "Trsf.-from Country/Region Code";
            Caption = 'Transfer-from County';
        }
        field(10; "Trsf.-from Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-from Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            ToolTip = 'Specifies the code of the location that the items are transferred to.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(12; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
            ToolTip = 'Specifies the name of the recipient at the location that the items are transferred to.';
        }
        field(13; "Transfer-to Name 2"; Text[50])
        {
            Caption = 'Transfer-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the recipient at the location that the items are transferred to.';
        }
        field(14; "Transfer-to Address"; Text[100])
        {
            Caption = 'Transfer-to Address';
            ToolTip = 'Specifies the address of the location that the items are transferred to.';
        }
        field(15; "Transfer-to Address 2"; Text[50])
        {
            Caption = 'Transfer-to Address 2';
            ToolTip = 'Specifies an additional part of the address of the location that items are transferred to.';
        }
        field(16; "Transfer-to Post Code"; Code[20])
        {
            Caption = 'Transfer-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(17; "Transfer-to City"; Text[30])
        {
            Caption = 'Transfer-to City';
            ToolTip = 'Specifies the city of the location that items are transferred to.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(18; "Transfer-to County"; Text[30])
        {
            CaptionClass = '5,8,' + "Trsf.-to Country/Region Code";
            Caption = 'Transfer-to County';
        }
        field(19; "Trsf.-to Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(20; "Transfer Order Date"; Date)
        {
            Caption = 'Transfer Order Date';
            ToolTip = 'Specifies the date when the transfer order was created.';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date for this document.';
        }
        field(22; Comment; Boolean)
        {
            CalcFormula = exist("Inventory Comment Line" where("Document Type" = const("Posted Transfer Shipment"),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            ToolTip = 'Specifies the number of the related transfer order.';
            TableRelation = "Transfer Header";
            ValidateTableRelation = false;
        }
        field(26; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(27; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        field(28; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';
            ToolTip = 'Specifies the receipt date of the transfer order.';
        }
        field(29; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            ToolTip = 'Specifies the in-transit code for the transfer order, such as a shipping agent.';
            TableRelation = Location.Code where("Use As In-Transit" = const(true));
        }
        field(30; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
            ToolTip = 'Specifies the name of the contact person at the location that the items are transferred from.';
        }
        field(31; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
            ToolTip = 'Specifies the name of the contact person at the location that items are transferred to.';
        }
        field(32; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(33; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
            TableRelation = "Shipping Agent";
        }
        field(34; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(35; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
            TableRelation = "Shipment Method";
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
            TableRelation = "Transport Method";
        }
        field(49; "Partner VAT ID"; Code[20])
        {
            Caption = 'Partner VAT ID';
            ToolTip = 'Specifies the counter party''s VAT number.';
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            ToolTip = 'Specifies the code of either the port of entry at which the items passed into your country/region, or the port of exit.';
            TableRelation = "Entry/Exit Point";
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
            TableRelation = "Transaction Specification";
        }
        field(70; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
            ToolTip = 'Specifies that the transfer does not use an in-transit location.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Transfer-from Code", "Transfer-to Code", "Posting Date", "Transfer Order Date")
        {
        }
    }

    trigger OnDelete()
    var
        InvtCommentLine: Record "Inventory Comment Line";
        TransShptLine: Record "Transfer Shipment Line";
        MoveEntries: Codeunit MoveEntries;
    begin
        TransShptLine.SetRange("Document No.", "No.");
        if TransShptLine.Find('-') then
            repeat
                TransShptLine.Delete();
            until TransShptLine.Next() = 0;

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Posted Transfer Shipment");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.DeleteAll();

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Transfer Shipment Line", 0, "No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Transfer Shipment Header", "No.");
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        ItemTrackingMgt: Codeunit "Item Tracking Management";

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "Report Selections";
        TransShptHeader: Record "Transfer Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestForm, IsHandled);
        if IsHandled then
            exit;

        TransShptHeader.Copy(Rec);
        ReportSelection.PrintWithDialogForCust(ReportSelection.Usage::Inv2, TransShptHeader, ShowRequestForm, 0);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    procedure CopyFromTransferHeader(TransHeader: Record "Transfer Header")
    begin
        "Transfer-from Code" := TransHeader."Transfer-from Code";
        "Transfer-from Name" := TransHeader."Transfer-from Name";
        "Transfer-from Name 2" := TransHeader."Transfer-from Name 2";
        "Transfer-from Address" := TransHeader."Transfer-from Address";
        "Transfer-from Address 2" := TransHeader."Transfer-from Address 2";
        "Transfer-from Post Code" := TransHeader."Transfer-from Post Code";
        "Transfer-from City" := TransHeader."Transfer-from City";
        "Transfer-from County" := TransHeader."Transfer-from County";
        "Trsf.-from Country/Region Code" := TransHeader."Trsf.-from Country/Region Code";
        "Transfer-from Contact" := TransHeader."Transfer-from Contact";
        "Transfer-to Code" := TransHeader."Transfer-to Code";
        "Transfer-to Name" := TransHeader."Transfer-to Name";
        "Transfer-to Name 2" := TransHeader."Transfer-to Name 2";
        "Transfer-to Address" := TransHeader."Transfer-to Address";
        "Transfer-to Address 2" := TransHeader."Transfer-to Address 2";
        "Transfer-to Post Code" := TransHeader."Transfer-to Post Code";
        "Transfer-to City" := TransHeader."Transfer-to City";
        "Transfer-to County" := TransHeader."Transfer-to County";
        "Trsf.-to Country/Region Code" := TransHeader."Trsf.-to Country/Region Code";
        "Transfer-to Contact" := TransHeader."Transfer-to Contact";
        "Transfer Order Date" := TransHeader."Posting Date";
        "Posting Date" := TransHeader."Posting Date";
        "Shipment Date" := TransHeader."Shipment Date";
        "Receipt Date" := TransHeader."Receipt Date";
        "Shortcut Dimension 1 Code" := TransHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := TransHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := TransHeader."Dimension Set ID";
        "Transfer Order No." := TransHeader."No.";
        "External Document No." := TransHeader."External Document No.";
        "In-Transit Code" := TransHeader."In-Transit Code";
        "Shipping Agent Code" := TransHeader."Shipping Agent Code";
        "Shipping Agent Service Code" := TransHeader."Shipping Agent Service Code";
        "Shipment Method Code" := TransHeader."Shipment Method Code";
        "Transaction Type" := TransHeader."Transaction Type";
        "Transport Method" := TransHeader."Transport Method";
        "Partner VAT ID" := TransHeader."Partner VAT ID";
        "Entry/Exit Point" := TransHeader."Entry/Exit Point";
        Area := TransHeader.Area;
        "Transaction Specification" := TransHeader."Transaction Specification";
        "Direct Transfer" := TransHeader."Direct Transfer";

        OnAfterCopyFromTransferHeader(Rec, TransHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTransferHeader(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var TransShptHeader: Record "Transfer Shipment Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;
}

