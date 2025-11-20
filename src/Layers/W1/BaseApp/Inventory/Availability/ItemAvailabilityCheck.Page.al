// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

page 1872 "Item Availability Check"
{
    AutoSplitKey = false;
    Caption = 'Availability Check';
    DelayedInsert = false;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    MultipleNewLines = false;
    PopulateAllFields = false;
    SaveValues = false;
    ShowFilter = true;
    SourceTable = Item;
    SourceTableTemporary = false;

    layout
    {
        area(content)
        {
            label(Control2)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Heading;
                ShowCaption = false;
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                field(InventoryQty; InventoryQty)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = AvailableInventoryCaption;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                }
                field(TotalQuantity; TotalQuantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Shortage';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item that is currently in inventory. The Total Quantity field is used to calculate the Available Inventory field as follows: Available Inventory = Total Quantity - Reserved Quantity.';
                }
                field("All locations"; Rec.Inventory)
                {
                    ApplicationArea = Location;
                    Caption = 'All locations';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of the item that is currently in inventory at all locations.';

                    trigger OnDrillDown()
                    begin
                        PAGE.RunModal(PAGE::"Item Availability by Location", Rec)
                    end;
                }
            }
            part(AvailabilityCheckDetails; "Item Availability Check Det.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Manage")
            {
                Caption = '&Manage';
                action("Page Item Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item';
                    Image = Item;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    RunPageMode = View;
                    ToolTip = 'View and edit detailed information for the item.';
                }
            }
            group(Create)
            {
                Caption = 'Create';
                action("Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Purchase Invoice';
                    Image = NewPurchaseInvoice;
                    ToolTip = 'Create a new purchase invoice.';

                    trigger OnAction()
                    begin
                        ShowNewPurchaseDocument(DummyPurchaseHeader."Document Type"::Invoice);
                    end;
                }
                action("Purchase Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Purchase Order';
                    Image = NewOrder;
                    ToolTip = 'Create a new purchase order.';

                    trigger OnAction()
                    begin
                        ShowNewPurchaseDocument(DummyPurchaseHeader."Document Type"::Order);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Purchase Order_Promoted"; "Purchase Order")
                {
                }
                actionref("Purchase Invoice_Promoted"; "Purchase Invoice")
                {
                }
                actionref("Page Item Card_Promoted"; "Page Item Card")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    var
        DummyPurchaseHeader: Record "Purchase Header";
        TotalQuantity: Decimal;
        InventoryQty: Decimal;
        LocationCode: Code[10];
        VariantCode: Code[10];
        UnitOfMeasureCode: Code[20];
        Heading: Text;
        SelectVentorTxt: Label 'Select a vendor';
        AvailableInventoryLbl: Label 'Available Inventory';
        AvailableInventoryCaptionLbl: Label '%1 (%2)', Comment = '%1 = Available Inventory Label, %2 = Location Code';
        AvailableInventoryCaption: Text;

    procedure PopulateDataOnNotification(var AvailabilityCheckNotification: Notification; ItemNo: Code[20]; UnitOfMeasureCode: Code[20]; InventoryQty: Decimal; GrossReq: Decimal; ReservedReq: Decimal; SchedRcpt: Decimal; ReservedRcpt: Decimal; CurrentQuantity: Decimal; CurrentReservedQty: Decimal; TotalQuantity: Decimal; EarliestAvailDate: Date; LocationCode: Code[10])
    begin
        AvailabilityCheckNotification.SetData('ItemNo', ItemNo);
        AvailabilityCheckNotification.SetData('UnitOfMeasureCode', UnitOfMeasureCode);
        AvailabilityCheckNotification.SetData('GrossReq', Format(GrossReq));
        AvailabilityCheckNotification.SetData('ReservedReq', Format(ReservedReq));
        AvailabilityCheckNotification.SetData('SchedRcpt', Format(SchedRcpt));
        AvailabilityCheckNotification.SetData('ReservedRcpt', Format(ReservedRcpt));
        AvailabilityCheckNotification.SetData('CurrentQuantity', Format(CurrentQuantity));
        AvailabilityCheckNotification.SetData('CurrentReservedQty', Format(CurrentReservedQty));
        AvailabilityCheckNotification.SetData('TotalQuantity', Format(TotalQuantity));
        AvailabilityCheckNotification.SetData('InventoryQty', Format(InventoryQty));
        AvailabilityCheckNotification.SetData('EarliestAvailDate', Format(EarliestAvailDate));
        AvailabilityCheckNotification.SetData('LocationCode', LocationCode);
    end;

    procedure PopulateDataOnNotification(var AvailabilityCheckNotification: Notification; Name: Text; Value: Text)
    begin
        AvailabilityCheckNotification.SetData(Name, Value);
    end;

    procedure InitializeFromNotification(AvailabilityCheckNotification: Notification)
    var
        GrossReq: Decimal;
        SchedRcpt: Decimal;
        ReservedReq: Decimal;
        ReservedRcpt: Decimal;
        CurrentQuantity: Decimal;
        CurrentReservedQty: Decimal;
        EarliestAvailDate: Date;
    begin
        Rec.Get(AvailabilityCheckNotification.GetData('ItemNo'));
        Rec.SetRange("No.", AvailabilityCheckNotification.GetData('ItemNo'));
        Evaluate(TotalQuantity, AvailabilityCheckNotification.GetData('TotalQuantity'));
        Evaluate(InventoryQty, AvailabilityCheckNotification.GetData('InventoryQty'));
        Evaluate(LocationCode, AvailabilityCheckNotification.GetData('LocationCode'));
        if AvailabilityCheckNotification.GetData('VariantCode') <> '' then
            Evaluate(VariantCode, AvailabilityCheckNotification.GetData('VariantCode'));
        if AvailabilityCheckNotification.GetData('UnitOfMeasureCode') <> '' then begin
            Evaluate(UnitOfMeasureCode, AvailabilityCheckNotification.GetData('UnitOfMeasureCode'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetUnitOfMeasureCode(AvailabilityCheckNotification.GetData('UnitOfMeasureCode'));
        end;

        if AvailabilityCheckNotification.GetData('GrossReq') <> '' then begin
            Evaluate(GrossReq, AvailabilityCheckNotification.GetData('GrossReq'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetGrossReq(GrossReq);
        end;
        if AvailabilityCheckNotification.GetData('ReservedReq') <> '' then begin
            Evaluate(ReservedReq, AvailabilityCheckNotification.GetData('ReservedReq'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetReservedReq(ReservedReq);
        end;
        if AvailabilityCheckNotification.GetData('SchedRcpt') <> '' then begin
            Evaluate(SchedRcpt, AvailabilityCheckNotification.GetData('SchedRcpt'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetSchedRcpt(SchedRcpt);
        end;
        if AvailabilityCheckNotification.GetData('ReservedRcpt') <> '' then begin
            Evaluate(ReservedRcpt, AvailabilityCheckNotification.GetData('ReservedRcpt'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetReservedRcpt(ReservedRcpt);
        end;
        if AvailabilityCheckNotification.GetData('CurrentQuantity') <> '' then begin
            Evaluate(CurrentQuantity, AvailabilityCheckNotification.GetData('CurrentQuantity'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetCurrentQuantity(CurrentQuantity);
        end;
        if AvailabilityCheckNotification.GetData('CurrentReservedQty') <> '' then begin
            Evaluate(CurrentReservedQty, AvailabilityCheckNotification.GetData('CurrentReservedQty'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetCurrentReservedQty(CurrentReservedQty);
        end;
        if AvailabilityCheckNotification.GetData('EarliestAvailDate') <> '' then begin
            Evaluate(EarliestAvailDate, AvailabilityCheckNotification.GetData('EarliestAvailDate'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetEarliestAvailDate(EarliestAvailDate);
        end;

        if LocationCode = '' then
            AvailableInventoryCaption := AvailableInventoryLbl
        else
            AvailableInventoryCaption := StrSubstNo('%1 (%2)', AvailableInventoryLbl, LocationCode);

        OnAfterInitializeFromNotification(Rec, AvailabilityCheckNotification);
    end;

    procedure InitializeFromData(ItemNo: Code[20]; NewUnitOfMeasureCode: Code[20]; InventoryQty2: Decimal; GrossReq: Decimal; ReservedReq: Decimal; SchedRcpt: Decimal; ReservedRcpt: Decimal; CurrentQuantity: Decimal; CurrentReservedQty: Decimal; TotalQuantity2: Decimal; EarliestAvailDate: Date; LocationCode2: Code[10])
    begin
        Rec.Get(ItemNo);
        Rec.SetRange("No.", ItemNo);
        TotalQuantity := TotalQuantity2;
        InventoryQty := InventoryQty2;
        LocationCode := LocationCode2;
        UnitOfMeasureCode := NewUnitOfMeasureCode;

        CurrPage.AvailabilityCheckDetails.PAGE.SetUnitOfMeasureCode(UnitOfMeasureCode);
        CurrPage.AvailabilityCheckDetails.PAGE.SetGrossReq(GrossReq);
        CurrPage.AvailabilityCheckDetails.PAGE.SetReservedReq(ReservedReq);
        CurrPage.AvailabilityCheckDetails.PAGE.SetSchedRcpt(SchedRcpt);
        CurrPage.AvailabilityCheckDetails.PAGE.SetReservedRcpt(ReservedRcpt);
        CurrPage.AvailabilityCheckDetails.PAGE.SetCurrentQuantity(CurrentQuantity);
        CurrPage.AvailabilityCheckDetails.PAGE.SetCurrentReservedQty(CurrentReservedQty);
        CurrPage.AvailabilityCheckDetails.PAGE.SetEarliestAvailDate(EarliestAvailDate);

        if LocationCode = '' then
            AvailableInventoryCaption := AvailableInventoryLbl
        else
            AvailableInventoryCaption := StrSubstNo(AvailableInventoryCaptionLbl, AvailableInventoryLbl, LocationCode);
    end;

    procedure SetHeading(Value: Text)
    begin
        Heading := Value;
    end;

    local procedure SelectVendor(var Vendor: Record Vendor): Boolean
    var
        VendorList: Page "Vendor List";
    begin
        VendorList.LookupMode(true);
        VendorList.Caption(SelectVentorTxt);
        if VendorList.RunModal() = ACTION::LookupOK then begin
            VendorList.GetRecord(Vendor);
            exit(true);
        end;

        exit(false);
    end;

    local procedure ShowNewPurchaseDocument(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if CreateNewPurchaseDocument(DocumentType, PurchaseHeader) then
            case DocumentType of
                PurchaseHeader."Document Type"::Invoice:
                    PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader);
                PurchaseHeader."Document Type"::Order:
                    PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);
            end;
    end;

    local procedure CreateNewPurchaseDocument(DocumentType: Enum "Purchase Document Type"; var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        if Rec."Vendor No." = '' then begin
            if not SelectVendor(Vendor) then
                exit(false);

            Rec."Vendor No." := Vendor."No."
        end;
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Rec."Vendor No.");
        PurchaseHeader.Modify(true);

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate("Line No.", 10000);
        PurchaseLine.Insert(true);

        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", Rec."No.");
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Validate(Quantity, -TotalQuantity);
        PurchaseLine.Modify(true);

        exit(true);
    end;

    procedure GetLocationCode(): Code[10]
    begin
        exit(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeFromNotification(var Item: Record Item; var AvailabilityCheckNotification: Notification)
    begin
    end;
}

