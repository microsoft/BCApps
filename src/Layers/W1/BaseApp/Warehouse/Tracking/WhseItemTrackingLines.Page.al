// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Worksheet;
using System.Utilities;

page 6550 "Whse. Item Tracking Lines"
{
    // Function button Line exist in two overlayed versions to make dynamic show/hide/enable of
    // individual menu items possible.

    Caption = 'Whse. Item Tracking Lines';
    DataCaptionFields = "Item No.", "Variant Code", Description;
    DelayedInsert = true;
    PageType = Worksheet;
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    PopulateAllFields = true;
    SourceTable = "Whse. Item Tracking Line";

    layout
    {
        area(content)
        {
            group(Control59)
            {
                ShowCaption = false;
                fixed(Control1903651101)
                {
                    ShowCaption = false;
                    group(Source)
                    {
                        Caption = 'Source';
                        field(TextCaption; GetTextCaption())
                        {
                            ApplicationArea = ItemTracking;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("SourceQuantityArray[1]"; SourceQuantityArray[1])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of the item that corresponds to the warehouse tracking line.';
                        }
                        field(Handle1; SourceQuantityArray[2])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Qty. to Handle';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the item-tracked quantity to be handled. The quantities must correspond to those of the document line.';
                            Visible = Handle1Visible;
                        }
                    }
                    group("Item Tracking")
                    {
                        Caption = 'Item Tracking';
                        field(Text003; PlaceholderTxt)
                        {
                            ApplicationArea = ItemTracking;
                            Visible = false;
                        }
#pragma warning disable AA0100
                        field("TotalWhseItemTrackingLine.""Quantity (Base)"""; TotalWhseItemTrackingLine."Quantity (Base)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of the item that corresponds to the warehouse tracking line.';
                        }
                        field(Handle2; TotalWhseItemTrackingLine."Qty. to Handle (Base)")
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Qty. to Ship/Receive';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantities handled in warehouse activity lines.';
                            Visible = Handle2Visible;
                        }
                    }
                    group(Undefined)
                    {
                        Caption = 'Undefined';
                        field(Control52; PlaceholderTxt)
                        {
                            ApplicationArea = ItemTracking;
                            Visible = false;
                        }
                        field(Quantity3; UndefinedQtyArray[1])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(Handle3; UndefinedQtyArray[2])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                            Visible = Handle3Visible;
                        }
                    }
                }
            }
            group(Control43)
            {
                ShowCaption = false;
                field("ItemTrackingCode.Code"; ItemTrackingCode.Code)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item Tracking Code';
                    Editable = false;
                    ToolTip = 'Specifies the code for the warehouse item to be tracked.';

                    trigger OnDrillDown()
                    var
                        ItemTrackingCodeToShow: Record "Item Tracking Code";
                        ItemTrackingCodeCard: Page "Item Tracking Code Card";
                    begin
                        ItemTrackingCodeToShow.SetRange(Code, ItemTrackingCode.Code);

                        ItemTrackingCodeCard.SetTableView(ItemTrackingCodeToShow);
                        ItemTrackingCodeCard.Editable := false;
                        ItemTrackingCodeCard.RunModal();
                    end;
                }
                field("ItemTrackingCode.Description"; ItemTrackingCode.Description)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the warehouse item.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    ExtendedDatatype = Barcode;

                    trigger OnAssistEdit()
                    var
                        MaxQuantity: Decimal;
                    begin
                        if ColorOfQuantityArray[1] = 0 then
                            MaxQuantity := UndefinedQtyArray[1];

                        Rec.LookUpTrackingSummary(Rec, Enum::"Item Tracking Type"::"Serial No.", MaxQuantity, -1, true);
                        CurrPage.Update();
                        CalculateSums();
                    end;

                    trigger OnValidate()
                    begin
                        SerialNoOnAfterValidate();
                    end;
                }
                field("New Serial No."; Rec."New Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewSerialNoEditable;
                    ToolTip = 'Specifies a new serial number that replaces the number in the Serial No. field, when you post the warehouse item reclassification journal.';
                    Visible = NewSerialNoVisible;
                    ExtendedDatatype = Barcode;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    ExtendedDatatype = Barcode;

                    trigger OnAssistEdit()
                    var
                        MaxQuantity: Decimal;
                    begin
                        if ColorOfQuantityArray[1] = 0 then
                            MaxQuantity := UndefinedQtyArray[1];

                        Rec.LookUpTrackingSummary(Rec, Enum::"Item Tracking Type"::"Lot No.", MaxQuantity, -1, true);
                        CurrPage.Update();
                        CalculateSums();
                    end;

                    trigger OnValidate()
                    begin
                        LotNoOnAfterValidate();
                    end;
                }
                field("New Lot No."; Rec."New Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewLotNoEditable;
                    ToolTip = 'Specifies a new lot number that replaces the number in the Lot No. field, when you post the warehouse item reclassification journal.';
                    Visible = NewLotNoVisible;
                    ExtendedDatatype = Barcode;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a new package number that replaces the package number, when you post the warehouse item reclassification journal.';
                    ExtendedDatatype = Barcode;

                    trigger OnAssistEdit()
                    var
                        MaxQuantity: Decimal;
                    begin
                        if ColorOfQuantityArray[1] = 0 then
                            MaxQuantity := UndefinedQtyArray[1];

                        Rec.LookUpTrackingSummary(Rec, Enum::"Item Tracking Type"::"Package No.", MaxQuantity, -1, true);
                        CurrPage.Update();
                        CalculateSums();
                    end;

                    trigger OnValidate()
                    begin
                        PackageNoOnAfterValidate();
                    end;
                }
                field("New Package No."; Rec."New Package No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewPackageNoEditable;
                    ToolTip = 'Specifies a new package number that replaces the number in the Package No. field, when you post the warehouse item reclassification journal.';
                    Visible = NewPackageNoVisible;
                    ExtendedDatatype = Barcode;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = ExpirationDateEditable;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = ExpirationDateVisible;
                }
                field("New Expiration Date"; Rec."New Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = NewExpirationDateEditable;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = NewExpirationDateVisible;
                }
                field("Warranty Date"; Rec."Warranty Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the same as the field with the same name in the Item Tracking Lines window.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = false;
                }
                field(Quantity; Rec."Quantity (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    BlankZero = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        QuantityBaseOnAfterValidate();
                    end;
                }
                field("Qty. to Handle (Base)"; Rec."Qty. to Handle (Base)")
                {
                    ApplicationArea = ItemTracking;
                    Editable = QtyToHandleBaseEditable;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = QtyToHandleBaseVisible;

                    trigger OnValidate()
                    begin
                        QtytoHandleBaseOnAfterValidate();
                    end;
                }
                field("Quantity Handled (Base)"; Rec."Quantity Handled (Base)")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the same as the field in the Item Tracking Lines window.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ButtonLineReclass)
            {
                Caption = '&Line';
                Image = Line;
                Visible = ButtonLineReclassVisible;
                action(Reclass_SerialNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No. Information Card';
                    Image = SNInfo;
                    ToolTip = 'View or edit detailed information about the serial number.';

                    trigger OnAction()
                    var
                        SerialNoInfo: Record "Serial No. Information";
                    begin
                        Rec.TestField("Serial No.");
                        SerialNoInfo.ShowCard(Rec."Serial No.", Rec);
                    end;
                }
                action(Reclass_LotNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No. Information Card';
                    Image = LotInfo;
                    ToolTip = 'View or edit detailed information about the lot number.';

                    trigger OnAction()
                    var
                        LotNoInfo: Record "Lot No. Information";
                    begin
                        Rec.TestField("Lot No.");
                        LotNoInfo.ShowCard(Rec."Lot No.", Rec);
                    end;
                }
                action(Reclass_PackageNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Package No. Information Card';
                    Image = LotInfo;
                    ToolTip = 'View or edit detailed information about the package number.';

                    trigger OnAction()
                    var
                        PackageNoInfo: Record "Package No. Information";
                    begin
                        Rec.TestField("Package No.");
                        PackageNoInfo.ShowCard(Rec."Package No.", Rec);
                    end;
                }
                separator(Action44)
                {
                }
                action("New S&erial No. Information")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'New S&erial No. Information';
                    Image = NewSerialNoProperties;
                    ToolTip = 'Create a record with detailed information about the serial number.';

                    trigger OnAction()
                    var
                        SerialNoInfo: Record "Serial No. Information";
                    begin
                        Rec.TestField("New Serial No.");
                        SerialNoInfo.ShowCard(Rec."New Serial No.", Rec);
                    end;
                }
                action("New L&ot No. Information")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'New L&ot No. Information';
                    Image = NewLotProperties;
                    RunPageOnRec = false;
                    ToolTip = 'Create a record with detailed information about the lot number.';

                    trigger OnAction()
                    var
                        LotNoInfo: Record "Lot No. Information";
                    begin
                        Rec.TestField("New Lot No.");
                        LotNoInfo.ShowCard(Rec."New Lot No.", Rec);
                    end;
                }
                action("New P&ackage No. Information")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'New P&ackage No. Information';
                    Image = NewLotProperties;
                    RunPageOnRec = false;
                    ToolTip = 'Create a record with detailed information about the package number.';

                    trigger OnAction()
                    var
                        PackageNoInfo: Record "Package No. Information";
                    begin
                        Rec.TestField("New Package No.");
                        PackageNoInfo.ShowCard(Rec."New Package No.", Rec);
                    end;
                }
            }
            group(ButtonLine)
            {
                Caption = '&Line';
                Image = Line;
                Visible = ButtonLineVisible;
                action(Line_SerialNoInfoCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No. Information Card';
                    Image = SNInfo;
                    ToolTip = 'View or edit detailed information about the serial number.';

                    trigger OnAction()
                    var
                        SerialNoInfo: Record "Serial No. Information";
                    begin
                        Rec.TestField("Serial No.");
                        SerialNoInfo.ShowCard(Rec."Serial No.", Rec);
                    end;
                }
                action(Line_LotNoInforCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No. Information Card';
                    Image = LotInfo;
                    ToolTip = 'View or edit detailed information about the lot number.';

                    trigger OnAction()
                    var
                        LotNoInfo: Record "Lot No. Information";
                    begin
                        Rec.TestField("Lot No.");
                        LotNoInfo.ShowCard(Rec."Lot No.", Rec);
                    end;
                }
                action(Line_PackageNoInforCard)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Package No. Information Card';
                    Image = LotInfo;
                    ToolTip = 'View or edit detailed information about the package number.';

                    trigger OnAction()
                    var
                        PackageNoInfo: Record "Package No. Information";
                    begin
                        Rec.TestField("Package No.");
                        PackageNoInfo.ShowCard(Rec."Package No.", Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Line_LotNoInforCard_Promoted; Line_LotNoInforCard)
                {
                }
                actionref(Line_SerialNoInfoCard_Promoted; Line_SerialNoInfoCard)
                {
                }
                actionref("New L&ot No. Information_Promoted"; "New L&ot No. Information")
                {
                }
                actionref(Reclass_LotNoInfoCard_Promoted; Reclass_LotNoInfoCard)
                {
                }
                actionref(Reclass_SerialNoInfoCard_Promoted; Reclass_SerialNoInfoCard)
                {
                }
                actionref(Line_PackageNoInforCard_Promoted; Line_PackageNoInforCard)
                {
                }
                actionref("New S&erial No. Information_Promoted"; "New S&erial No. Information")
                {
                }
                actionref(Reclass_PackageNoInfoCard_Promoted; Reclass_PackageNoInfoCard)
                {
                }
                actionref("New P&ackage No. Information_Promoted"; "New P&ackage No. Information")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateExpDateEditable();
        CalculateSums();
    end;

    trigger OnAfterGetRecord()
    begin
        ExpirationDateOnFormat();
    end;

    trigger OnClosePage()
    begin
        if FormUpdated then
            if not UpdateUndefinedQty() then
                RestoreInitialTrkgLine()
            else
                if not CopyToReservEntry() then
                    RestoreInitialTrkgLine();

        OnAfterOnClosePage(Rec, WhseWorksheetLine, FormSourceType, FormUpdated);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FormUpdated := true;
        Rec.Delete(); // to ensure correct recalculation
        CalculateSums();
    end;

    trigger OnInit()
    begin
        ExpirationDateEditable := true;
        NewExpirationDateEditable := true;
        NewLotNoEditable := true;
        NewSerialNoEditable := true;
        QtyToHandleBaseEditable := true;
        ButtonLineVisible := true;
        QtyToHandleBaseVisible := true;
        Handle3Visible := true;
        Handle2Visible := true;
        Handle1Visible := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        WhseItemTrackingLine2: Record "Whse. Item Tracking Line";
    begin
        FormUpdated := true;
        if not Rec.TrackingExists() then
            exit(false);
        if WhseItemTrackingLine2.FindLast() then;
        Rec."Entry No." := WhseItemTrackingLine2."Entry No." + 1;
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FormUpdated := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateUndefinedQty();
        SaveItemTrkgLine(TempInitialTrkgLine);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if FormUpdated then begin
            if not UpdateUndefinedQty() then
                exit(Confirm(ExcessQuantityQst));

            if CountLinesWithQtyZero() > 0 then
                exit(ConfirmManagement.GetResponseOrDefault(ConfirmWhenExitingQst, true));
        end;
    end;

    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        TempInitialTrkgLine: Record "Whse. Item Tracking Line" temporary;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ConfirmManagement: Codeunit "Confirm Management";
        FormSourceType: Integer;
        FormUpdated: Boolean;
        Reclass: Boolean;
        LineTxt: Label 'Line';
        ExcessQuantityQst: Label 'The corrections cannot be saved as excess quantity has been defined.\Close the form anyway?';
        PlaceholderTxt: Label 'Placeholder';
        ConfirmWhenExitingQst: Label 'One or more lines have tracking specified, but Quantity (Base) is zero. If you continue, data on these lines will be lost. Do you want to close the page?';

    protected var
        UndefinedQtyArray: array[2] of Decimal;
        SourceQuantityArray: array[2] of Decimal;
        ColorOfQuantityArray: array[2] of Integer;
        Handle1Visible: Boolean;
        Handle2Visible: Boolean;
        Handle3Visible: Boolean;
        QtyToHandleBaseVisible: Boolean;
        ExpirationDateVisible: Boolean;
        NewSerialNoVisible: Boolean;
        NewLotNoVisible: Boolean;
        NewPackageNoVisible: Boolean;
        NewExpirationDateVisible: Boolean;
        ButtonLineReclassVisible: Boolean;
        ButtonLineVisible: Boolean;
        QtyToHandleBaseEditable: Boolean;
        NewSerialNoEditable: Boolean;
        NewLotNoEditable: Boolean;
        NewPackageNoEditable: Boolean;
        NewExpirationDateEditable: Boolean;
        ExpirationDateEditable: Boolean;

    local procedure GetTextCaption(): Text[30]
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        case Rec."Source Type" of
            Database::"Posted Whse. Receipt Line":
                exit(CopyStr(PostedWhseRcptLine.TableCaption(), 1, 30));
            Database::"Warehouse Shipment Line":
                exit(CopyStr(WhseShipmentLine.TableCaption(), 1, 30));
            else
                exit(LineTxt);
        end;
    end;

    procedure SetSource(WhseWrkshLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    begin
        FormUpdated := false;
        FormSourceType := SourceType;
        WhseWorksheetLine := WhseWrkshLine;
        GetItem(WhseWorksheetLine."Item No.");
        ItemTrackingMgt.CheckWhseItemTrkgSetup(WhseWorksheetLine."Item No.");

        SetControlsAsHandle();
        Reclass := Rec.IsReclass(FormSourceType, WhseWorksheetLine."Worksheet Template Name");
        SetControlsAsReclass();

        SetFilters(Rec, FormSourceType);
        ItemTrackingMgt.UpdateQuantities(
          WhseWorksheetLine, TotalWhseItemTrackingLine, SourceQuantityArray, UndefinedQtyArray, FormSourceType);
        OnAfterSetSource(WhseWorksheetLine, WhseWrkshLine, SourceType);
        UpdateColorOfQty();
    end;

    local procedure SetControlsAsHandle()
    var
        SetAccess: Boolean;
    begin
        ExpirationDateVisible := ItemTrackingCode."Use Expiration Dates";

        SetAccess := FormSourceType <> Database::"Warehouse Journal Line";
        Handle1Visible := SetAccess;
        Handle2Visible := SetAccess;
        Handle3Visible := SetAccess;
        QtyToHandleBaseVisible := SetAccess;
        QtyToHandleBaseEditable := SetAccess;
    end;

    local procedure SetControlsAsReclass()
    begin
        ExpirationDateVisible := ItemTrackingCode."Use Expiration Dates";

        NewSerialNoVisible := Reclass;
        NewSerialNoEditable := Reclass;
        NewLotNoVisible := Reclass;
        NewLotNoEditable := Reclass;
        NewPackageNoVisible := Reclass;
        NewPackageNoEditable := Reclass;
        NewExpirationDateVisible := Reclass;
        NewExpirationDateEditable := Reclass;
        ButtonLineReclassVisible := Reclass;
        ButtonLineVisible := not Reclass;
    end;

    procedure SetFilters(var WhseItemTrackingLine2: Record "Whse. Item Tracking Line"; SourceType: Integer)
    begin
        WhseItemTrackingLine2.FilterGroup := 2;
        WhseItemTrackingLine2.SetRange("Source Type", SourceType);
        WhseItemTrackingLine2.SetRange("Location Code", WhseWorksheetLine."Location Code");
        WhseItemTrackingLine2.SetRange("Item No.", WhseWorksheetLine."Item No.");
        WhseItemTrackingLine2.SetRange("Variant Code", WhseWorksheetLine."Variant Code");
        WhseItemTrackingLine2.SetRange("Qty. per Unit of Measure", WhseWorksheetLine."Qty. per Unit of Measure");

        case SourceType of
            Database::"Posted Whse. Receipt Line",
            Database::"Warehouse Shipment Line",
            Database::"Whse. Internal Put-away Line",
            Database::"Whse. Internal Pick Line",
            Database::"Assembly Line",
            Database::"Internal Movement Line":
                begin
                    WhseItemTrackingLine2.SetRange("Source ID", WhseWorksheetLine."Whse. Document No.");
                    WhseItemTrackingLine2.SetRange("Source Ref. No.", WhseWorksheetLine."Whse. Document Line No.");
                end;
            Database::"Whse. Worksheet Line",
            Database::"Warehouse Journal Line":
                begin
                    WhseItemTrackingLine2.SetRange("Source Batch Name", WhseWorksheetLine."Worksheet Template Name");
                    WhseItemTrackingLine2.SetRange("Source ID", WhseWorksheetLine.Name);
                    WhseItemTrackingLine2.SetRange("Source Ref. No.", WhseWorksheetLine."Line No.");
                end;
            else
                OnSetSourceFilters(WhseItemTrackingLine2, WhseWorksheetLine, SourceType);
        end;
        WhseItemTrackingLine2.FilterGroup := 0;

        OnAfterSetFilters(WhseItemTrackingLine2, SourceType);
    end;

    local procedure UpdateExpDateColor()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateExpDateColor(Rec, IsHandled);
        if IsHandled then
            exit;

        if BlockExpDate() then;
    end;

    local procedure UpdateExpDateEditable()
    begin
        ExpirationDateEditable := not BlockExpDate();
    end;

    local procedure BlockExpDate(): Boolean
    begin
        exit(
          (Rec."Buffer Status2" = Rec."Buffer Status2"::"ExpDate blocked") or
          (WhseWorksheetLine."Qty. (Base)" < 0) or
          Reclass or
          (FormSourceType in
           [Database::"Whse. Worksheet Line",
            Database::"Posted Whse. Receipt Line",
            Database::"Whse. Internal Put-away Line"]));
    end;

    procedure CalculateSums()
    begin
        ItemTrackingMgt.CalculateSums(
          WhseWorksheetLine, TotalWhseItemTrackingLine,
          SourceQuantityArray, UndefinedQtyArray, FormSourceType);
        UpdateColorOfQty();
    end;

    local procedure UpdateUndefinedQty() QtyIsValid: Boolean
    begin
        QtyIsValid := ItemTrackingMgt.UpdateUndefinedQty(TotalWhseItemTrackingLine, SourceQuantityArray, UndefinedQtyArray);
        UpdateColorOfQty();

        OnAfterUpdateUndefinedQty(Rec, TotalWhseItemTrackingLine, QtyIsValid);
    end;

    local procedure UpdateColorOfQty()
    begin
        ColorOfQuantityArray[1] := GetQtyColor(SourceQuantityArray[1], TotalWhseItemTrackingLine."Quantity (Base)");
        ColorOfQuantityArray[2] := GetQtyColor(SourceQuantityArray[2], TotalWhseItemTrackingLine."Qty. to Handle (Base)");
    end;

    local procedure GetQtyColor(SourceQty: Decimal; TrackingQty: Decimal): Integer
    begin
        if Abs(SourceQty) < Abs(TrackingQty) then
            exit(255);
        exit(0);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then begin
            Item.Get(ItemNo);
            Item.TestField("Item Tracking Code");
            if ItemTrackingCode.Code <> Item."Item Tracking Code" then
                ItemTrackingCode.Get(Item."Item Tracking Code");
        end;
    end;

    local procedure SaveItemTrkgLine(var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary)
    var
        WhseItemTrackingLine2: Record "Whse. Item Tracking Line";
    begin
        SetFilters(WhseItemTrackingLine2, FormSourceType);
        TempWhseItemTrkgLine.Reset();
        TempWhseItemTrkgLine.DeleteAll();
        if WhseItemTrackingLine2.Find('-') then
            repeat
                TempWhseItemTrkgLine := WhseItemTrackingLine2;
                TempWhseItemTrkgLine.Insert();
            until WhseItemTrackingLine2.Next() = 0;
    end;

    local procedure RestoreInitialTrkgLine()
    var
        WhseItemTrackingLine2: Record "Whse. Item Tracking Line";
    begin
        SetFilters(WhseItemTrackingLine2, FormSourceType);
        WhseItemTrackingLine2.DeleteAll();
        if TempInitialTrkgLine.Find('-') then
            repeat
                WhseItemTrackingLine2 := TempInitialTrkgLine;
                WhseItemTrackingLine2.Insert();
            until TempInitialTrkgLine.Next() = 0;
    end;

    local procedure CopyToReservEntry(): Boolean
    var
        WhseItemTrackingLine2: Record "Whse. Item Tracking Line";
        TempSourceWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        WhseShptLine: Record "Warehouse Shipment Line";
        QuantityBase: Decimal;
        DueDate: Date;
        Updated: Boolean;
        IsHandled: Boolean;
    begin
        SetFilters(WhseItemTrackingLine2, FormSourceType);

        if WhseItemTrackingLine2.Find('-') then
            TempSourceWhseItemTrackingLine := WhseItemTrackingLine2
        else
            if TempInitialTrkgLine.Find('-') then
                TempSourceWhseItemTrackingLine := TempInitialTrkgLine
            else
                exit(true);

        case FormSourceType of
            Database::"Warehouse Shipment Line":
                begin
                    WhseShptLine.Get(TempSourceWhseItemTrackingLine."Source ID", TempSourceWhseItemTrackingLine."Source Ref. No.");
                    QuantityBase := WhseShptLine."Qty. (Base)";
                    DueDate := WhseShptLine."Due Date";
                    Updated := UpdateReservEntry(
                        WhseShptLine."Source Type",
                        WhseShptLine."Source Subtype",
                        WhseShptLine."Source No.",
                        0,
                        WhseShptLine."Source Line No.",
                        TempSourceWhseItemTrackingLine, QuantityBase, DueDate);
                end;
            else begin
                IsHandled := false;
                OnCopyToReservEntryOnUpdate(TempSourceWhseItemTrackingLine, QuantityBase, DueDate, Updated, FormSourceType, IsHandled);
                exit(true);
            end;
        end;
        exit(Updated)
    end;

    procedure UpdateReservEntry(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceProdOrderLine: Integer; SourceRefNo: Integer; TempSourceWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; QuantityBase: Decimal; DueDate: Date): Boolean
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SourceTrackingSpecification: Record "Tracking Specification";
        WhseItemTrackingLine2: Record "Whse. Item Tracking Line";
        LastEntryNo: Integer;
    begin
        LastEntryNo := 0;
        if TempInitialTrkgLine.Find('-') then
            repeat
                TempTrackingSpecification.TransferFields(TempInitialTrkgLine);
                TempTrackingSpecification."Quantity (Base)" *= -1;
                TempTrackingSpecification."Entry No." := LastEntryNo + 1;
                TempTrackingSpecification.Insert();
                LastEntryNo := TempTrackingSpecification."Entry No.";
            until TempInitialTrkgLine.Next() = 0;

        SetFilters(WhseItemTrackingLine2, FormSourceType);
        if WhseItemTrackingLine2.Find('-') then
            repeat
                TempTrackingSpecification.TransferFields(WhseItemTrackingLine2);
                TempTrackingSpecification."Entry No." := LastEntryNo + 1;
                TempTrackingSpecification.Insert();
                LastEntryNo := TempTrackingSpecification."Entry No.";
            until WhseItemTrackingLine2.Next() = 0;

        SetSourceSpecification(SourceTrackingSpecification, TempSourceWhseItemTrackingLine, SourceType, SourceSubtype, SourceID, SourceProdOrderLine, SourceRefNo, QuantityBase);
        ItemTrackingMgt.SetGlobalParameters(SourceTrackingSpecification, TempTrackingSpecification, DueDate);
        exit(ItemTrackingMgt.Run());
    end;

    procedure InsertItemTrackingLine(WhseWrkshLine: Record "Whse. Worksheet Line"; WhseEntry: Record "Warehouse Entry"; QtyToEmpty: Decimal)
    var
        WhseItemTrackingLine2: Record "Whse. Item Tracking Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertItemTrackingLine(Rec, WhseWrkshLine, WhseEntry, QtyToEmpty, IsHandled);
        if IsHandled then
            exit;

        UpdateUndefinedQty();
        SaveItemTrkgLine(TempInitialTrkgLine);
        Rec.CopyTrackingFromWhseEntry(WhseEntry);
        Rec."Expiration Date" := WhseEntry."Expiration Date";
        Rec."Qty. per Unit of Measure" := WhseWrkshLine."Qty. per Unit of Measure";
        Rec.Validate("Quantity (Base)", QtyToEmpty);
        Rec."Source Type" := FormSourceType;
        Rec."Source ID" := WhseWorksheetLine."Whse. Document No.";
        Rec."Source Ref. No." := WhseWorksheetLine."Whse. Document Line No.";
        Rec."Source Batch Name" := WhseWrkshLine."Worksheet Template Name";
        Rec."Location Code" := WhseWorksheetLine."Location Code";
        Rec."Item No." := WhseWorksheetLine."Item No.";
        Rec."Variant Code" := WhseWrkshLine."Variant Code";
        if (Rec."Expiration Date" <> 0D) and (FormSourceType = Database::"Internal Movement Line") then
            Rec.InitExpirationDate();
        if WhseItemTrackingLine2.FindLast() then;
        Rec."Entry No." := WhseItemTrackingLine2."Entry No." + 1;
        OnBeforeItemTrackingLineInsert(Rec, WhseWrkshLine, WhseEntry);
        Rec.Insert();
    end;

    protected procedure SerialNoOnAfterValidate()
    begin
        UpdateExpDateEditable();
        CurrPage.Update();
    end;

    protected procedure LotNoOnAfterValidate()
    begin
        UpdateExpDateEditable();
        CurrPage.Update();
    end;

    protected procedure PackageNoOnAfterValidate()
    begin
        UpdateExpDateEditable();
        CurrPage.Update();
    end;

    protected procedure QuantityBaseOnAfterValidate()
    begin
        CurrPage.Update();
        CalculateSums();
    end;

    protected procedure QtytoHandleBaseOnAfterValidate()
    begin
        CurrPage.Update();
        CalculateSums();
    end;

    local procedure ExpirationDateOnFormat()
    begin
        UpdateExpDateColor();
    end;

    local procedure SetSourceSpecification(var SourceSpecification: Record "Tracking Specification"; TempSourceWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceProdOrderLine: Integer; SourceRefNo: Integer; QuantityBase: Decimal)
    begin
        SourceSpecification."Source Type" := SourceType;
        SourceSpecification."Source Subtype" := SourceSubtype;
        SourceSpecification."Source ID" := SourceID;
        SourceSpecification."Source Batch Name" := '';
        SourceSpecification."Source Prod. Order Line" := SourceProdOrderLine;
        SourceSpecification."Source Ref. No." := SourceRefNo;
        SourceSpecification."Quantity (Base)" := QuantityBase;
        SourceSpecification."Item No." := TempSourceWhseItemTrackingLine."Item No.";
        SourceSpecification."Variant Code" := TempSourceWhseItemTrackingLine."Variant Code";
        SourceSpecification."Location Code" := TempSourceWhseItemTrackingLine."Location Code";
        SourceSpecification.Description := TempSourceWhseItemTrackingLine.Description;
        SourceSpecification."Qty. per Unit of Measure" := TempSourceWhseItemTrackingLine."Qty. per Unit of Measure";

        OnAfterSetSourceSpecification(SourceSpecification, TempSourceWhseItemTrackingLine);
    end;


    local procedure CountLinesWithQtyZero(): Integer
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.Copy(Rec);
        WhseItemTrackingLine.SetRange("Quantity (Base)", 0);
        exit(WhseItemTrackingLine.Count());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSource(var GlobalWhseWorksheetLine: Record "Whse. Worksheet Line"; SourceWhseWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnClosePage(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line"; FormSourceType: Integer; FormUpdated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUndefinedQty(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line"; var QtyIsValid: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemTrackingLineInsert(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseWorksheetLine: Record "Whse. Worksheet Line"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemTrackingLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseWorksheetLine: Record "Whse. Worksheet Line"; WarehouseEntry: Record "Warehouse Entry"; QtyToEmpty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceSpecification(var SourceSpecification: Record "Tracking Specification"; SourceWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateExpDateColor(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetSourceFilters(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopyToReservEntryOnUpdate(var TempSourceWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var QuantityBase: Decimal; var DueDate: Date; var Updated: Boolean; FormSourceType: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceType: Integer)
    begin
    end;
}
