// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

table 6505 "Lot No. Information"
{
    Caption = 'Lot No. Information';
    DataCaptionFields = "Item No.", "Variant Code", "Lot No.", Description;
    DrillDownPageID = "Lot No. Information List";
    LookupPageID = "Lot No. Information List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
            OptimizeForTextSearch = true;
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
            OptimizeForTextSearch = true;
            ExtendedDatatype = Barcode;
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the lot no. information record.';
            OptimizeForTextSearch = true;
        }
        field(11; "Test Quality"; Option)
        {
            Caption = 'Test Quality';
            ToolTip = 'Specifies the quality of a given lot if you have inspected the items.';
            OptionCaption = ' ,Good,Average,Bad';
            OptionMembers = " ",Good,"Average",Bad;
        }
        field(12; "Certificate Number"; Code[20])
        {
            Caption = 'Certificate Number';
            ToolTip = 'Specifies the number provided by the supplier to indicate that the batch or lot meets the specified requirements.';
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
        }
        field(14; Comment; Boolean)
        {
            CalcFormula = exist("Item Tracking Comment" where(Type = const("Lot No."),
                                                               "Item No." = field("Item No."),
                                                               "Variant Code" = field("Variant Code"),
                                                               "Serial/Lot No." = field("Lot No.")));
            Caption = 'Comment';
            ToolTip = 'Specifies that a comment has been recorded for the lot number.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Inventory; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("Item No."),
                                                                  "Variant Code" = field("Variant Code"),
                                                                  "Lot No." = field("Lot No."),
                                                                  "Location Code" = field("Location Filter")));
            Caption = 'Inventory';
            ToolTip = 'Specifies the inventory quantity of the specified lot number.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(22; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(23; "Bin Filter"; Code[20])
        {
            Caption = 'Bin Filter';
            FieldClass = FlowFilter;
            TableRelation = Bin.Code where("Location Code" = field("Location Filter"));
        }
        field(24; "Expired Inventory"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Item Ledger Entry"."Remaining Quantity" where("Item No." = field("Item No."),
                                                                              "Variant Code" = field("Variant Code"),
                                                                              "Lot No." = field("Lot No."),
                                                                              "Location Code" = field("Location Filter"),
                                                                              "Expiration Date" = field("Date Filter"),
                                                                              Open = const(true),
                                                                              Positive = const(true)));
            Caption = 'Expired Inventory';
            ToolTip = 'Specifies the inventory of the lot number with an expiration date before the posting date on the associated document.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(8000; "EUDR Certificate No."; Code[50])
        {
            Caption = 'EUDR Certificate No.';
            ToolTip = 'Specifies the certificate number that documents EUDR compliance for this lot.';
        }
        field(8001; "Certification Scheme"; Text[100])
        {
            Caption = 'Certification Scheme';
            ToolTip = 'Specifies the certification scheme that applies to this lot, such as FSC, PEFC, RSPO, Rainforest Alliance, or Fairtrade.';
        }
        field(8002; "EUDR Valid From"; Date)
        {
            Caption = 'Valid From';
            ToolTip = 'Specifies the first date that the EUDR certificate is valid for this lot.';

            trigger OnValidate()
            begin
                if ("EUDR Valid From" <> 0D) and ("EUDR Valid To" <> 0D) then
                    if "EUDR Valid From" > "EUDR Valid To" then
                        Error(EUDRValidFromAfterValidToErr, FieldCaption("EUDR Valid From"), FieldCaption("EUDR Valid To"));
            end;
        }
        field(8003; "EUDR Valid To"; Date)
        {
            Caption = 'Valid To';
            ToolTip = 'Specifies the last date that the EUDR certificate is valid for this lot.';

            trigger OnValidate()
            begin
                if ("EUDR Valid From" <> 0D) and ("EUDR Valid To" <> 0D) then
                    if "EUDR Valid To" < "EUDR Valid From" then
                        Error(EUDRValidFromAfterValidToErr, FieldCaption("EUDR Valid From"), FieldCaption("EUDR Valid To"));
            end;
        }
        field(8004; "Country/Region of Prod. Code"; Code[10])
        {
            Caption = 'Country/Region of Production Code';
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country or region where the goods in this lot were produced. You can change the value if the distributor provides different origin information.';
        }
        field(8005; "DDS Reference Number"; Code[50])
        {
            Caption = 'DDS Reference Number';
            ToolTip = 'Specifies the reference number issued when the due diligence statement is registered in the EU Information System, TRACES.';
        }
        field(8006; "DDS Verification No."; Code[50])
        {
            Caption = 'DDS Verification No.';
            ToolTip = 'Specifies the verification number for the EUDR due diligence statement.';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Lot No.")
        {
            Clustered = true;
        }
        key(Key2; "Lot No.")
        {
            Enabled = false;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Variant Code", "Lot No.")
        {
        }
    }

    trigger OnDelete()
    begin
        ItemTrackingComment.SetRange(Type, ItemTrackingComment.Type::"Lot No.");
        ItemTrackingComment.SetRange("Item No.", "Item No.");
        ItemTrackingComment.SetRange("Variant Code", "Variant Code");
        ItemTrackingComment.SetRange("Serial/Lot No.", "Lot No.");
        ItemTrackingComment.DeleteAll();
    end;

    var
        ItemTrackingComment: Record "Item Tracking Comment";
        EUDRValidFromAfterValidToErr: Label '%1 must not be after %2.', Comment = '%1 = Valid From field caption, %2 = Valid To field caption';

    procedure ShowCard(LotNo: Code[50]; TrackingSpecification: Record "Tracking Specification")
    var
        LotNoInfoNew: Record "Lot No. Information";
        LotNoInfoForm: Page "Lot No. Information Card";
    begin
        Clear(LotNoInfoForm);
        LotNoInfoForm.Init(TrackingSpecification);

        LotNoInfoNew.SetRange("Item No.", TrackingSpecification."Item No.");
        LotNoInfoNew.SetRange("Variant Code", TrackingSpecification."Variant Code");
        LotNoInfoNew.SetRange("Lot No.", LotNo);
        OnShowCardOnAfterLotNoInfoNewSetFilters(LotNoInfoNew, TrackingSpecification, LotNo, LotNoInfoForm);

        LotNoInfoForm.SetTableView(LotNoInfoNew);
        LotNoInfoForm.Run();
    end;

    procedure ShowCard(LotNo: Code[50]; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        LotNoInfoNew: Record "Lot No. Information";
        LotNoInfoForm: Page "Lot No. Information Card";
    begin
        Clear(LotNoInfoForm);
        LotNoInfoForm.InitWhse(WhseItemTrackingLine);

        LotNoInfoNew.SetRange("Item No.", WhseItemTrackingLine."Item No.");
        LotNoInfoNew.SetRange("Variant Code", WhseItemTrackingLine."Variant Code");
        LotNoInfoNew.SetRange("Lot No.", LotNo);
        OnShowCardOnAfterLotNoInfoNewSetFilters2(LotNoInfoNew, WhseItemTrackingLine, LotNo, LotNoInfoForm);

        LotNoInfoForm.SetTableView(LotNoInfoNew);
        LotNoInfoForm.Run();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCardOnAfterLotNoInfoNewSetFilters(var LotNoInformation: Record "Lot No. Information"; TrackingSpecification: Record "Tracking Specification"; LotNo: Code[50]; var LotNoInformationCard: Page "Lot No. Information Card")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCardOnAfterLotNoInfoNewSetFilters2(var LotNoInformation: Record "Lot No. Information"; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; LotNo: Code[50]; var LotNoInformationCard: Page "Lot No. Information Card")
    begin
    end;
}

