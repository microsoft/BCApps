// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;

page 913 "Assembly Availability Check"
{
    Caption = 'Assembly Availability Check';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = false;
    LinksAllowed = false;
    MultipleNewLines = false;
    PopulateAllFields = false;
    SaveValues = false;
    ShowFilter = true;
    SourceTable = "Assembly Header";
    SourceTableTemporary = true;

    layout
    {

        area(content)
        {
            label(Control2)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Heading;
                ShowCaption = false;
                Style = Unfavorable;
                StyleExpr = QtyAvailTooLow;
            }
            group(AssemblyHeaderDetails)
            {
                ShowCaption = false;
                Visible = AssemblyHeaderDetailsVisible;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number assigned to the assembly order from the number series that you set up in the Assembly Setup window.';
                }
            }
            group(Details)
            {
                Caption = 'Details';

                group(DetailsItem)
                {
                    ShowCaption = false;
                    field("Item No."; Rec."Item No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the number of the item that is being assembled with the assembly order.';
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = Assembly;
                        ToolTip = 'Specifies the description of the assembly item.';
                    }
                    field("Unit of Measure Code"; Rec."Unit of Measure Code")
                    {
                        ApplicationArea = Assembly;
                        ToolTip = 'Specifies the unit of measure code of the assembly item.';
                    }
                    field("Variant Code"; Rec."Variant Code")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies the code of the item variant of the item that is being assembled.';
                    }
                    field("Location Code"; Rec."Location Code")
                    {
                        ApplicationArea = Location;
                        ToolTip = 'Specifies the location to which you want to post output of the assembly item.';
                    }
                    field("Current Quantity"; Rec."Remaining Quantity")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Current Quantity';
                        ToolTip = 'Specifies how many units of the assembly item remain to be posted as assembled output.';
                    }
                    field("Reserved Quantity"; Rec."Reserved Quantity")
                    {
                        ApplicationArea = Reservation;
                        ToolTip = 'Specifies how many units of the assembly item are reserved for this assembly order header.';
                    }
                }
                group(DetailsQty)
                {
                    ShowCaption = false;

                    field(Inventory; Inventory)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Inventory';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies how many units of the assembly item are in inventory.';

                        trigger OnDrillDown()
                        var
                            Item: Record Item;
                            ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
                        begin
                            Item.Get(Rec."Item No.");
                            Rec.SetItemFilter(Item);
                            ItemAvailFormsMgt.ShowItemLedgerEntries(Item, false);
                        end;
                    }
                    field(GrossRequirement; GrossRequirement)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Gross Requirement';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies the total demand for the assembly item.';
                    }
                    field(AbleToAssemble; QtyAvailToMake)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Able to Assemble';
                        DecimalPlaces = 0 : 5;
                        Style = Unfavorable;
                        StyleExpr = QtyAvailTooLow;
                        ToolTip = 'Specifies how many units of the assembly item can be assembled, based on the availability of components on the assembly order lines.';
                    }
                    field(EarliestAvailableDate; EarliestAvailableDate)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Earliest Available Date';
                        ToolTip = 'Specifies the late arrival date of an inbound supply order that can cover the needed quantity of the assembly item.';
                    }

                    field(ReservedRequirement; ReservedRequirement)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Reserved Requirement';
                        DecimalPlaces = 0 : 5;
                    }
                    field(ScheduledReceipts; ScheduledReceipts)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Scheduled Receipts';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies how many units of the assembly item are inbound on orders.';
                    }
                    field(ReservedReceipts; ReservedReceipts)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Reserved Receipts';
                        DecimalPlaces = 0 : 5;
                    }
                }

            }
            part(AssemblyLineAvail; "Assembly Line Avail.")
            {
                ApplicationArea = Assembly;
                SubPageLink = "Document Type" = field("Document Type"),
                                  "Document No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    begin
        AssemblyHeaderDetailsVisible := Rec."No." <> '';
    end;

    var
        Inventory: Decimal;
        GrossRequirement: Decimal;
        ReservedRequirement: Decimal;
        ScheduledReceipts: Decimal;
        ReservedReceipts: Decimal;
        EarliestAvailableDate: Date;
        QtyAvailToMake: Decimal;
        QtyAvailTooLow: Boolean;
        AssemblyHeaderDetailsVisible: Boolean;
        Heading: Text;

    procedure SetHeading(Value: Text)
    begin
        Heading := Value;
    end;

    procedure SetAssemblyHeader(var TempAssemblyHeader2: Record "Assembly Header" temporary)
    begin
        Rec.Init();
        Rec := TempAssemblyHeader2;
        Rec.Insert();
        Rec.SetRange("No.", Rec."No.");
        CurrPage.AssemblyLineAvail.PAGE.SetHeader(TempAssemblyHeader2);
    end;

    procedure SetAssemblyLines(var TempAssemblyLine2: Record "Assembly Line" temporary)
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        TempAssemblyLine.Copy(TempAssemblyLine2, true);
        CurrPage.AssemblyLineAvail.PAGE.SetLinesRecord(TempAssemblyLine);
    end;

    procedure SetHeaderInventoryData(Inventory2: Decimal; GrossRequirement2: Decimal; ReservedRequirement2: Decimal; ScheduledReceipts2: Decimal; ReservedReceipts2: Decimal; EarliestAvailableDate2: Date; QtyAvailToMake2: Decimal; QtyAvailTooLow2: Boolean)
    begin
        Inventory := Inventory2;
        GrossRequirement := GrossRequirement2;
        ReservedRequirement := ReservedRequirement2;
        ScheduledReceipts := ScheduledReceipts2;
        ReservedReceipts := ReservedReceipts2;
        EarliestAvailableDate := EarliestAvailableDate2;
        QtyAvailToMake := QtyAvailToMake2;
        QtyAvailTooLow := QtyAvailTooLow2;
    end;

    procedure PopulateDataOnNotification(var AssemblyAvailabilityCheckNotification: Notification; var AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyAvailabilityCheckNotification.SetData('AssemblyType', Format(AssemblyHeader."Document Type".AsInteger()));
        AssemblyAvailabilityCheckNotification.SetData('AssemblyNo', AssemblyHeader."No.");

        AssemblyAvailabilityCheckNotification.SetData('ItemNo', AssemblyHeader."Item No.");
        AssemblyAvailabilityCheckNotification.SetData('ItemDescription', AssemblyHeader.Description);
        AssemblyAvailabilityCheckNotification.SetData('VariantCode', AssemblyHeader."Variant Code");
        AssemblyAvailabilityCheckNotification.SetData('UnitOfMeasureCode', AssemblyHeader."Unit of Measure Code");
        AssemblyAvailabilityCheckNotification.SetData('QtyPerUnitOfMeasureCode', Format(AssemblyHeader."Qty. per Unit of Measure"));
        AssemblyAvailabilityCheckNotification.SetData('LocationCode', AssemblyHeader."Location Code");
        AssemblyAvailabilityCheckNotification.SetData('BinCode', AssemblyHeader."Bin Code");
        AssemblyAvailabilityCheckNotification.SetData('DueDate', Format(AssemblyHeader."Due Date"));
        AssemblyAvailabilityCheckNotification.SetData('Quantity', Format(AssemblyHeader.Quantity));

        OnAfterPopulateDataOnNotification(AssemblyAvailabilityCheckNotification, AssemblyHeader);
    end;

    procedure InitializeFromNotification(AssemblyAvailabilityCheckNotification: Notification; var AssemblyHeader: Record "Assembly Header"; var ExisitngDocument: Boolean)
    var
        InDbAssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        AssemblyHeader.Reset();
        Evaluate(AssemblyHeader."Document Type", AssemblyAvailabilityCheckNotification.GetData('AssemblyType'));
        AssemblyHeader."No." := AssemblyAvailabilityCheckNotification.GetData('AssemblyNo');

        ExisitngDocument := InDbAssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.")
            and (InDbAssemblyHeader."Item No." <> '')
            and (InDbAssemblyHeader.Quantity <> 0);
        if ExisitngDocument then
            AssemblyHeader.Copy(InDbAssemblyHeader);

        AssemblyHeader."Item No." := AssemblyAvailabilityCheckNotification.GetData('ItemNo');
        AssemblyHeader.Description := AssemblyAvailabilityCheckNotification.GetData('ItemDescription');
        if AssemblyHeader.Description = '' then begin
            Item.Get(AssemblyHeader."Item No.");
            AssemblyHeader.Description := Item.Description;
        end;

        if AssemblyAvailabilityCheckNotification.GetData('VariantCode') <> '' then
            AssemblyHeader."Variant Code" := AssemblyAvailabilityCheckNotification.GetData('VariantCode');
        if AssemblyAvailabilityCheckNotification.GetData('UnitOfMeasureCode') <> '' then
            AssemblyHeader."Unit of Measure Code" := AssemblyAvailabilityCheckNotification.GetData('UnitOfMeasureCode');
        if AssemblyAvailabilityCheckNotification.GetData('QtyPerUnitOfMeasureCode') <> '' then
            Evaluate(AssemblyHeader."Qty. per Unit of Measure", AssemblyAvailabilityCheckNotification.GetData('QtyPerUnitOfMeasureCode'))
        else
            AssemblyHeader."Qty. per Unit of Measure" := 1;
        AssemblyHeader."Location Code" := AssemblyAvailabilityCheckNotification.GetData('LocationCode');
        if AssemblyAvailabilityCheckNotification.GetData('BinCode') <> '' then
            AssemblyHeader."Bin Code" := AssemblyAvailabilityCheckNotification.GetData('BinCode');
        if AssemblyAvailabilityCheckNotification.GetData('DueDate') <> '' then
            Evaluate(AssemblyHeader."Due Date", AssemblyAvailabilityCheckNotification.GetData('DueDate'))
        else
            AssemblyHeader."Due Date" := WorkDate();
        AssemblyHeader.ValidateDates(AssemblyHeader.FieldNo("Due Date"), true);
        Evaluate(AssemblyHeader.Quantity, AssemblyAvailabilityCheckNotification.GetData('Quantity'));
        AssemblyHeader."Quantity (Base)" := UnitofMeasureManagement.RoundQty(AssemblyHeader.Quantity * AssemblyHeader."Qty. per Unit of Measure", AssemblyHeader."Qty. Rounding Precision (Base)");
        AssemblyHeader.InitRemainingQty();

        OnAfterInitializeFromNotification(AssemblyAvailabilityCheckNotification, AssemblyHeader);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPopulateDataOnNotification(var AssemblyAvailabilityCheckNotification: Notification; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInitializeFromNotification(var AssemblyAvailabilityCheckNotification: Notification; var AssemblyHeader: Record "Assembly Header")
    begin
    end;
}

