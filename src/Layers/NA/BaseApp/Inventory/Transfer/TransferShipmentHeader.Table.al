// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.FixedAsset;
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
using System.IO;
using System.Utilities;

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
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(3; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
        }
        field(4; "Transfer-from Name 2"; Text[50])
        {
            Caption = 'Transfer-from Name 2';
        }
        field(5; "Transfer-from Address"; Text[100])
        {
            Caption = 'Transfer-from Address';
        }
        field(6; "Transfer-from Address 2"; Text[50])
        {
            Caption = 'Transfer-from Address 2';
        }
        field(7; "Transfer-from Post Code"; Code[20])
        {
            Caption = 'Transfer-from Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';
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
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(12; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
        }
        field(13; "Transfer-to Name 2"; Text[50])
        {
            Caption = 'Transfer-to Name 2';
        }
        field(14; "Transfer-to Address"; Text[100])
        {
            Caption = 'Transfer-to Address';
        }
        field(15; "Transfer-to Address 2"; Text[50])
        {
            Caption = 'Transfer-to Address 2';
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
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
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
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
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
        }
        field(28; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';
        }
        field(29; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            TableRelation = Location.Code where("Use As In-Transit" = const(true));
        }
        field(30; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
        }
        field(31; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
        }
        field(32; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(33; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(34; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(35; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(49; "Partner VAT ID"; Code[20])
        {
            Caption = 'Partner VAT ID';
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(70; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
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
        field(10020; "Original Document XML"; BLOB)
        {
            Caption = 'Original Document XML';
        }
        field(10022; "Original String"; BLOB)
        {
            Caption = 'Original String';
        }
        field(10023; "Digital Stamp SAT"; BLOB)
        {
            Caption = 'Digital Stamp SAT';
        }
        field(10024; "Certificate Serial No."; Text[250])
        {
            Caption = 'Certificate Serial No.';
            Editable = false;
        }
        field(10025; "Signed Document XML"; BLOB)
        {
            Caption = 'Signed Document XML';
        }
        field(10026; "Digital Stamp PAC"; BLOB)
        {
            Caption = 'Digital Stamp PAC';
        }
        field(10030; "Electronic Document Status"; Option)
        {
            Caption = 'Electronic Document Status';
            Editable = false;
            OptionCaption = ' ,Stamp Received,Sent,Canceled,Stamp Request Error,Cancel Error,Cancel In Progress';
            OptionMembers = " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        }
        field(10031; "Date/Time Stamped"; Text[50])
        {
            Caption = 'Date/Time Stamped';
            Editable = false;
        }
        field(10033; "Date/Time Canceled"; Text[50])
        {
            Caption = 'Date/Time Canceled';
            Editable = false;
        }
        field(10035; "Error Code"; Code[10])
        {
            Caption = 'Error Code';
            Editable = false;
        }
        field(10036; "Error Description"; Text[250])
        {
            Caption = 'Error Description';
            Editable = false;
        }
        field(10037; "Date/Time Stamp Received"; DateTime)
        {
            Caption = 'Date/Time Stamp Received';
            Editable = false;
        }
        field(10038; "Date/Time Cancel Sent"; DateTime)
        {
            Caption = 'Date/Time Cancel Sent';
            Editable = false;
        }
        field(10039; "Identifier IdCCP"; Text[50])
        {
            Caption = 'Identifier IdCCP';
            Editable = false;
        }
        field(10040; "PAC Web Service Name"; Text[50])
        {
            Caption = 'PAC Web Service Name';
            Editable = false;
        }
        field(10041; "QR Code"; BLOB)
        {
            Caption = 'QR Code';
        }
        field(10042; "Fiscal Invoice Number PAC"; Text[50])
        {
            Caption = 'Fiscal Invoice Number PAC';
            Editable = false;
        }
        field(10043; "Date/Time First Req. Sent"; Text[50])
        {
            Caption = 'Date/Time First Req. Sent';
            Editable = false;
        }
        field(10044; "Transport Operators"; Integer)
        {
            Caption = 'Transport Operators';
            CalcFormula = count("CFDI Transport Operator" where("Document Table ID" = const(5744),
                                                                 "Document No." = field("No.")));
            FieldClass = FlowField;
        }
        field(10045; "Transit-from Date/Time"; DateTime)
        {
            Caption = 'Transit-from Date/Time';
        }
        field(10046; "Transit Hours"; Integer)
        {
            Caption = 'Transit Hours';
        }
        field(10047; "Transit Distance"; Decimal)
        {
            Caption = 'Transit Distance';
        }
        field(10048; "Insurer Name"; Text[50])
        {
            Caption = 'Insurer Name';
        }
        field(10049; "Insurer Policy Number"; Text[30])
        {
            Caption = 'Insurer Policy Number';
        }
        field(10050; "Foreign Trade"; Boolean)
        {
            Caption = 'Foreign Trade';
        }
        field(10051; "Vehicle Code"; Code[20])
        {
            Caption = 'Vehicle Code';
            TableRelation = "Fixed Asset";
        }
        field(10052; "Trailer 1"; Code[20])
        {
            Caption = 'Trailer 1';
            TableRelation = "Fixed Asset" where("SAT Trailer Type" = filter(<> ''));
        }
        field(10053; "Trailer 2"; Code[20])
        {
            Caption = 'Trailer 2';
            TableRelation = "Fixed Asset" where("SAT Trailer Type" = filter(<> ''));
        }
        field(10056; "Medical Insurer Name"; Text[50])
        {
            Caption = 'Medical Insurer Name';
        }
        field(10057; "Medical Ins. Policy Number"; Text[30])
        {
            Caption = 'Medical Ins. Policy Number';
        }
        field(10058; "SAT Weight Unit Of Measure"; Code[10])
        {
            Caption = 'SAT Weight Unit Of Measure';
            TableRelation = "SAT Weight Unit of Measure";
        }
        field(10059; "SAT International Trade Term"; Code[10])
        {
            Caption = 'SAT International Trade Term';
            TableRelation = "SAT International Trade Term";
        }
        field(10060; "Exchange Rate USD"; Decimal)
        {
            Caption = 'Exchange Rate USD';
            DecimalPlaces = 0 : 6;
        }
        field(10061; "SAT Customs Regime"; Code[10])
        {
            Caption = 'SAT Customs Regime';
            TableRelation = "SAT Customs Regime";
        }
        field(10062; "SAT Transfer Reason"; Code[10])
        {
            Caption = 'SAT Transfer Reason';
            TableRelation = "SAT Transfer Reason";
        }
        field(27002; "CFDI Cancellation Reason Code"; Code[10])
        {
            Caption = 'CFDI Cancellation Reason';
            TableRelation = "CFDI Cancellation Reason";
        }
        field(27003; "Substitution Document No."; Code[20])
        {
            Caption = 'Substitution Document No.';
            TableRelation = "Transfer Shipment Header" where("Electronic Document Status" = filter("Stamp Received"));
        }
        field(27004; "CFDI Export Code"; Code[10])
        {
            Caption = 'CFDI Export Code';
            TableRelation = "CFDI Export Code";
        }
        field(27007; "CFDI Cancellation ID"; Text[50])
        {
            Caption = 'CFDI Cancellation ID';
        }
        field(27008; "Marked as Canceled"; Boolean)
        {
            Caption = 'Marked as Canceled';
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
        NoElectronicStampErr: Label 'There is no electronic stamp for document no. %1.', Comment = '%1 - Document No.';

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

    procedure ExportEDocument()
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        CalcFields("Signed Document XML");
        if "Signed Document XML".HasValue() then begin
            TempBlob.FromRecord(Rec, FieldNo("Signed Document XML"));
            FileManagement.BLOBExport(TempBlob, "No." + '.xml', true);
        end else
            Error(NoElectronicStampErr, "No.");
    end;

    procedure RequestStampEDocument()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        LoCRecRef: RecordRef;
    begin
        LoCRecRef.GetTable(Rec);
        EInvoiceMgt.RequestStampDocument(LoCRecRef, false);
    end;

    procedure CancelEDocument()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        LoCRecRef: RecordRef;
    begin
        LoCRecRef.GetTable(Rec);
        EInvoiceMgt.CancelDocument(LoCRecRef);
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

