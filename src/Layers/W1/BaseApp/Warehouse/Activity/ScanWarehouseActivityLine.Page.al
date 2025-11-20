// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Item.Picture;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;
using System.Device;
using System.Telemetry;

page 7388 "Scan Warehouse Activity Line"
{
    Caption = 'Line Details';
    InsertAllowed = false;
    DeleteAllowed = false;
    PageType = Card;
    SourceTable = "Warehouse Activity Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                group(ActionType)
                {
                    Caption = 'Action Type';
                    ShowCaption = false;
                    Visible = ActionTypeVisible;
                    field("Action Type"; Rec."Action Type")
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies the action type for the warehouse activity line.';
                    }
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the item number of the item to be handled, such as picked or put away.';
                }
                group(Variant)
                {
                    ShowCaption = false;
                    Visible = VariantVisible;
                    field("Variant Code"; Rec."Variant Code")
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies the variant of the item on the line.';
                    }
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies a description of the item on the line.';
                }
                group(DescriptionGrp)
                {
                    ShowCaption = false;
                    Visible = Description2Visible;
                    field(Description2; Rec.Description)
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies an extended description of the item on the line.';

                    }
                }
                group(SerialNo)
                {
                    ShowCaption = false;
                    Visible = SerialNoVisible;
                    field("Serial No."; Rec."Serial No.")
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ToolTip = 'Specifies the serial number to handle in the document.';
                    }
                }
                group(LotNo)
                {
                    ShowCaption = false;
                    Visible = LotNoVisible;
                    field("Lot No."; Rec."Lot No.")
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ToolTip = 'Specifies the lot number to handle in the document.';
                        Visible = LotNoVisible;
                    }
                }
                group(PackageNo)
                {
                    ShowCaption = false;
                    Visible = PackageNoVisible;
                    field("Package No."; Rec."Package No.")
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ToolTip = 'Specifies the package number to handle in the document.';
                    }
                }
                group(Bin)
                {
                    ShowCaption = false;
                    Visible = BinVisible;
                    field("Bin Code"; Rec."Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies the bin where the items are picked or put away.';
                    }
                }
                group(ShelfNo)
                {
                    ShowCaption = false;
                    Visible = ShelfNoVisible;
                    field("Shelf No."; Rec."Shelf No.")
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies the shelf number of the item for informational use.';
                    }
                }
                group(SpecialEquipment)
                {
                    ShowCaption = false;
                    Visible = SpecialEquipmentCodeVisible;
                    field("Special Equipment Code"; Rec."Special Equipment Code")
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies the code of the equipment required when you perform the action on the line.';
                    }
                }
            }
            group(EnterOrScan)
            {
                Caption = 'Enter or Scan';
                group(ScanBin)
                {
                    ShowCaption = false;
                    Visible = ScanBinVisible;
                    field("Scan Bin Code"; Rec."Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Editable = BinCodeEditable;
                        ToolTip = 'Specifies the bin where the items are picked or put away.';
                    }
                }
                field("Scan Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for informational use.';
                    Visible = false;
                }
                field("Scan Qty. to Handle"; Rec."Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units to handle in this warehouse activity.';
                }
                field("Qty. Outstanding"; Rec."Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the number of items that have not yet been handled for this warehouse activity line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                group(ScanSerial)
                {
                    Visible = ScanSerialNoVisible;
                    ShowCaption = false;
                    field("Scan Serial No."; Rec."Serial No.")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies the serial number to handle in the document.';

                        trigger OnValidate()
                        begin
                            SerialNoOnAfterValidate();
                        end;
                    }
                }
                group(ScanLot)
                {
                    Visible = ScanLotNoVisible;
                    ShowCaption = false;
                    field("Scan Lot No."; Rec."Lot No.")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies the lot number to handle in the document.';

                        trigger OnValidate()
                        begin
                            LotNoOnAfterValidate();
                        end;
                    }
                }
                group(ScanPackage)
                {
                    Visible = ScanPackageNoVisible;
                    ShowCaption = false;
                    field("Scan Package No."; Rec."Package No.")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies the package number to handle in the document.';

                        trigger OnValidate()
                        begin
                            Rec.UpdateExpirationDate(Rec.FieldNo("Package No."));
                        end;
                    }
                }
                field("Scan Warehouse Reason Code"; Rec."Warehouse Reason Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the reason for the warehouse activity.';
                }
            }
            usercontrol(BarCodeScanner; BarcodeScannerProviderAddIn)
            {
                ApplicationArea = Warehouse;

                trigger ControlAddInReady(IsSupported: Boolean)
                begin
                    if IsSupported then
                        RequestBarcodeScannerAsync()
                    else
                        Message(BarcodeScannerNotSupportedMsg);
                end;

                trigger BarcodeReceived(Barcode: Text; Format: Text)
                var
                    ScanWarehouseLine: Codeunit "Scan Warehouse Activity Line";
                    FeatureTelemetry: Codeunit "Feature Telemetry";
                    NeedsRefresh: Boolean;
                    AllLinesFulfilled: Boolean;
                begin
                    FeatureTelemetry.LogUsage('0000MZQ', FeatureTelemetryNameLbl, ScannedBarcodeAvailableLbl);
                    ScanWarehouseLine.CheckAndSetBarcode(Rec, Barcode, NeedsRefresh, AllLinesFulfilled);

                    if AllLinesFulfilled then begin
                        Message(AllLinesFulfilledMsg);
                        CurrPage.Close();
                    end;

                    if NeedsRefresh then begin
                        Message(CurrentLineFulfilledMoveNextMsg);
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
        area(factboxes)
        {
            part(ItemPicture; "Item Picture")
            {
                ApplicationArea = Warehouse;
                Caption = 'Picture';
                SubPageLink = "No." = field("Item No.");
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetFieldsVisibility();
    end;

    var
        BinVisible: Boolean;
        ShelfNoVisible: Boolean;
        VariantVisible: Boolean;
        SerialNoVisible: Boolean;
        LotNoVisible: Boolean;
        PackageNoVisible: Boolean;
        BinCodeEditable: Boolean;
        ActionTypeVisible: Boolean;
        Description2Visible: Boolean;
        SpecialEquipmentCodeVisible: Boolean;
        ScanSerialNoVisible: Boolean;
        ScanLotNoVisible: Boolean;
        ScanPackageNoVisible: Boolean;
        ScanBinVisible: Boolean;
        BarcodeScannerNotSupportedMsg: Label 'Barcode scanner is not supported on this device.';
        CurrentLineFulfilledMoveNextMsg: Label 'The quantity to handle has been fulfilled on this line. Continuing to the next line.';
        AllLinesFulfilledMsg: Label 'The quantity to handle on all the lines have been fulfulled. Page will be closed.';
        FeatureTelemetryNameLbl: Label 'Barcode Scanning', Locked = true;
        ScannedBarcodeAvailableLbl: Label 'Scanned barcode from laser scanner available for processing.', Locked = true;

    local procedure SetFieldsVisibility()
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemBin: Record Bin;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        // Show "Action Type" in the General tab only if it is set
        ActionTypeVisible := Rec."Action Type" <> Rec."Action Type"::" ";
        // Show "Description 2" in the General tab only if it is set 
        Description2Visible := Rec."Description 2" <> '';
        // Show "Variant Code" in the General tab only if it is set
        VariantVisible := Rec."Variant Code" <> '';
        // Show "Serial No." in the General tab only if it is set
        SerialNoVisible := Rec."Serial No." <> '';
        // Show "Lot No." in the General tab only if it is set
        LotNoVisible := Rec."Lot No." <> '';
        // Show "Package No." in the General tab only if it is set
        PackageNoVisible := Rec."Package No." <> '';
        // Show "Bin Code" in the General tab only if it is set
        BinVisible := Rec."Bin Code" <> '';
        // Show "Shelf No." in the General tab only if it is set
        ShelfNoVisible := Rec."Shelf No." <> '';
        // Show "Special Equipment Code" in the General tab only if it is set
        SpecialEquipmentCodeVisible := Rec."Special Equipment Code" <> '';

        // Show "Bin Code" in the "Enter or Scan" tab only if items are available in bins and bin is not set
        ItemBin.SetRange("Location Code", Rec."Location Code");
        ScanBinVisible := not ItemBin.IsEmpty() and (Rec."Bin Code" = '');
        // Set if the "Bin Code" fileld in "Enter and Scan tab" is editable
        SetBinEditable();

        ItemTrackingManagement.GetWhseItemTrkgSetup(Rec."Item No.", ItemTrackingSetup);
        // Show "Scan Serial No." in the "Enter or Scan" tab only if it is required and not set
        ScanSerialNoVisible := ItemTrackingSetup."Serial No. Required" and (Rec."Serial No." = '');
        // Show "Scan Lot No." in the "Enter or Scan" tab only if it is required and not set
        ScanLotNoVisible := ItemTrackingSetup."Lot No. Required" and (Rec."Lot No." = '');
        // Show "Scan Package No." in the "Enter or Scan" tab only if it is required and not set
        ScanPackageNoVisible := ItemTrackingSetup."Package No. Required" and (Rec."Package No." = '');
    end;

    local procedure SetBinEditable()
    var
        PlaceLineForConsumption: Boolean;
    begin
        PlaceLineForConsumption :=
          (Rec."Action Type" = Rec."Action Type"::Place) and
          (Rec."Source Document" in ["Warehouse Activity Source Document"::"Prod. Consumption",
                                     "Warehouse Activity Source Document"::"Assembly Consumption",
                                     "Warehouse Activity Source Document"::"Job Usage"]) and
          (Rec."Whse. Document Type" in ["Warehouse Activity Document Type"::Production,
                                         "Warehouse Activity Document Type"::Assembly,
                                         "Warehouse Activity Document Type"::Job]);

        BinCodeEditable :=
          (Rec."Action Type" = Rec."Action Type"::Take) or (Rec."Breakbulk No." <> 0) or PlaceLineForConsumption;
    end;

    local procedure SerialNoOnAfterValidate()
    begin
        Rec.UpdateExpirationDate(Rec.FieldNo("Serial No."));
    end;

    local procedure LotNoOnAfterValidate()
    begin
        Rec.UpdateExpirationDate(Rec.FieldNo("Lot No."));
    end;

    local procedure RequestBarcodeScannerAsync()
    var
        IntentAction, IntentCategory, DataString, DataFormat : Text;
    begin
        OnBeforeRequestBarcodeScannerAsync(IntentAction, IntentCategory, DataString, DataFormat);

        if (IntentAction = '') and (IntentCategory = '') and (DataString = '') and (DataFormat = '') then
            CurrPage.BarCodeScanner.RequestBarcodeScannerAsync()
        else
            CurrPage.BarCodeScanner.RequestBarcodeScannerAsync(IntentAction, IntentCategory, DataString, DataFormat);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRequestBarcodeScannerAsync(var IntentAction: Text; var IntentCategory: Text; var DataString: Text; var DataFormat: Text)
    begin
    end;
}