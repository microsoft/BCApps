// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using System.Utilities;

codeunit 5920 ServItemManagement
{

    trigger OnRun()
    begin
    end;

    var
        ServItem: Record "Service Item";
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        ServInvoiceLine: Record "Service Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempReservEntry: Record "Reservation Entry" temporary;
        GLSetup: Record "General Ledger Setup";
        TempServiceItem: Record "Service Item" temporary;
        TempServiceItemComp: Record "Service Item Component" temporary;
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
        ServLogMgt: Codeunit ServLogManagement;
        ServOrderMgt: Codeunit ServOrderManagement;
        NextLineNo: Integer;
        Index: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Do you want to create a service item?';
        Text001: Label 'Service item %1 was created. This service item does not belong to any service contract.';
        Text002: Label 'You have inserted a %1 on the selected %2.\Would you like to copy this information into the %1 field for the newly created %3?';
        Text003: Label 'Posting cannot be completed successfully. %1 %2  belongs to the %3 that requires creating service items. Check if the %4 field contains a whole number.';
        Text004: Label 'Posting cannot be completed successfully. For the items that are used to replace or create service item components, the %1 field on the %2 must contain a whole number.';
        Text005: Label 'The service item that is linked to the order has been deleted.';
        CannotDeleteErr: Label 'You cannot delete item variant %1 because there is at least one %2 that includes this Variant Code.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure AddOrReplaceSIComponent(var ServLine: Record "Service Line"; ServHeader: Record "Service Header"; ServShptDocNo: Code[20]; ServShptLineNo: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ServItemComponent: Record "Service Item Component";
        ServItemComponent2: Record "Service Item Component";
        NewServItemComponent: Record "Service Item Component";
        ComponentLine: Integer;
        x: Integer;
        TrackingLinesExist: Boolean;
        IsHandled: Boolean;
    begin
        if (ServLine.Type <> ServLine.Type::Item) or (ServLine."Qty. to Ship" = 0) then
            exit;

        IsHandled := false;
        OnBeforeReplaceSIComponent(ServLine, ServHeader, ServShptDocNo, ServShptLineNo, TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        case ServLine."Spare Part Action" of
            ServLine."Spare Part Action"::"Component Replaced":
                begin
                    CheckWholeNumber(ServLine);
                    NewServItemComponent.LockTable();
                    NewServItemComponent.Reset();
                    NewServItemComponent.SetRange(Active, false);
                    NewServItemComponent.SetRange("Parent Service Item No.", ServLine."Service Item No.");
                    if NewServItemComponent.FindLast() then
                        ComponentLine := NewServItemComponent."Line No."
                    else
                        ComponentLine := 0;

                    if ServItemComponent2.Get(true, ServLine."Service Item No.", ServLine."Component Line No.") then begin
                        ServItemComponent := ServItemComponent2;
                        ServItemComponent."Service Order No." := ServLine."Document No.";
                        Clear(ServLogMgt);
                        ServLogMgt.ServItemComponentRemoved(ServItemComponent);
                        ServItemComponent.Delete();
                        ServItemComponent2.Active := false;
                        ServItemComponent2."Line No." := ComponentLine + 10000;
                        ServItemComponent2."From Line No." := ServItemComponent."Line No.";
                        ServItemComponent2."Service Order No." := ServHeader."No.";
                        ServItemComponent2.Insert();
                        if ServItemComponent2.Type = ServItemComponent2.Type::"Service Item" then begin
                            ServItem.Get(ServItemComponent2."No.");
                            ServItem.Status := ServItem.Status::Defective;
                            ServItem.Modify();
                        end;
                    end;

                    InitNewServItemComponent(NewServItemComponent, ServLine, ServItemComponent."Line No.", ServHeader."Posting Date");
                    TempTrackingSpecification.SetSourceFilter(DATABASE::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServLine."Line No.", false);
                    TrackingLinesExist := TempTrackingSpecification.Find('-');
                    if TrackingLinesExist then begin
                        NewServItemComponent."Serial No." := TempTrackingSpecification."Serial No.";
                        if TempTrackingSpecification.Next() = 0 then
                            TrackingLinesExist := false;
                    end;
                    OnBeforeInsertNewServItemComponent(NewServItemComponent, ServLine);
                    NewServItemComponent.Insert();
                    Clear(ServLogMgt);
                    ServLogMgt.ServItemComponentAdded(NewServItemComponent);

                    NewServItemComponent.SetRange(Active, true);
                    if NewServItemComponent.FindLast() then
                        ComponentLine := NewServItemComponent."Line No."
                    else
                        ComponentLine := 0;

                    for x := 2 to ServLine."Qty. to Ship" do begin
                        ComponentLine := ComponentLine + 10000;
                        InitNewServItemComponent(NewServItemComponent, ServLine, ComponentLine, ServHeader."Posting Date");
                        if TrackingLinesExist then begin
                            NewServItemComponent."Serial No." := TempTrackingSpecification."Serial No.";
                            if TempTrackingSpecification.Next() = 0 then
                                TrackingLinesExist := false;
                        end;
                        OnBeforeInsertNewServItemComponent(NewServItemComponent, ServLine);
                        NewServItemComponent.Insert();
                        Clear(ServLogMgt);
                        ServLogMgt.ServItemComponentAdded(NewServItemComponent);
                    end;
                end;
            ServLine."Spare Part Action"::"Component Installed":
                begin
                    CheckWholeNumber(ServLine);
                    NewServItemComponent.LockTable();
                    NewServItemComponent.Reset();
                    NewServItemComponent.SetRange(Active, true);
                    NewServItemComponent.SetRange("Parent Service Item No.", ServLine."Service Item No.");
                    if NewServItemComponent.FindLast() then
                        ComponentLine := NewServItemComponent."Line No."
                    else
                        ComponentLine := 0;

                    TempTrackingSpecification.SetSourceFilter(DATABASE::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServLine."Line No.", false);
                    TrackingLinesExist := TempTrackingSpecification.Find('-');

                    for x := 1 to ServLine."Qty. to Ship" do begin
                        ComponentLine := ComponentLine + 10000;
                        InitNewServItemComponent(NewServItemComponent, ServLine, ComponentLine, ServHeader."Posting Date");
                        NewServItemComponent."Service Order No." := ServLine."Document No.";
                        if TrackingLinesExist then begin
                            NewServItemComponent."Serial No." := TempTrackingSpecification."Serial No.";
                            if TempTrackingSpecification.Next() = 0 then
                                TrackingLinesExist := false;
                        end;
                        OnBeforeInsertNewServItemComponent(NewServItemComponent, ServLine);
                        NewServItemComponent.Insert();
                        Clear(ServLogMgt);
                        ServLogMgt.ServItemComponentAdded(NewServItemComponent);
                    end;
                end;
            ServLine."Spare Part Action"::Permanent,
            ServLine."Spare Part Action"::"Temporary":
                begin
                    IsHandled := false;
                    OnAddOrReplaceSIComponentPermanentTemporary(ServItem, ServLine, IsHandled);
                    if not IsHandled then
                        ServItem.Get(ServLine."Service Item No.");
                    ServOrderMgt.ReplacementCreateServItem(ServItem, ServLine,
                      ServShptDocNo, ServShptLineNo, TempTrackingSpecification);
                end;
        end;
    end;

    local procedure InitNewServItemComponent(var NewServItemComponent: Record "Service Item Component"; ServiceLine: Record "Service Line"; NextLineNo: Integer; PostingDate: Date)
    begin
        NewServItemComponent.Init();
        NewServItemComponent."Parent Service Item No." := ServiceLine."Service Item No.";
        NewServItemComponent."Line No." := NextLineNo;
        NewServItemComponent.Active := true;
        NewServItemComponent."No." := ServiceLine."No.";
        NewServItemComponent.Type := NewServItemComponent.Type::Item;
        NewServItemComponent."Date Installed" := PostingDate;
        NewServItemComponent.Description := ServiceLine.Description;
        NewServItemComponent."Description 2" := ServiceLine."Description 2";
        NewServItemComponent."Variant Code" := ServiceLine."Variant Code";
        NewServItemComponent."Service Order No." := ServiceLine."Document No.";
        NewServItemComponent."Last Date Modified" := Today;

        OnAfterInitNewServItemComponent(NewServItemComponent, ServiceLine);
    end;

    procedure InsertServiceItemComponent(var ServiceItemComponent: Record "Service Item Component"; BOMComponent: Record "BOM Component"; BOMComponent2: Record "BOM Component"; SalesHeader: Record "Sales Header"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
        ServiceItemComponent.Init();
        ServiceItemComponent.Active := true;
        ServiceItemComponent."Parent Service Item No." := ServItem."No.";
        ServiceItemComponent."Line No." := NextLineNo;
        ServiceItemComponent.Type := ServiceItemComponent.Type::Item;
        ServiceItemComponent."No." := BOMComponent2."No.";
        ServiceItemComponent."Date Installed" := SalesHeader."Posting Date";
        ServiceItemComponent.Description := BOMComponent2.Description;
        ServiceItemComponent."Serial No." := '';
        ServiceItemComponent."Variant Code" := BOMComponent2."Variant Code";
        OnBeforeInsertServItemComponent(ServiceItemComponent, ServItem, SalesHeader, SalesShipmentLine, BOMComponent, BOMComponent2);
        ServiceItemComponent.Insert();
    end;

    procedure CreateServItemOnSalesLineShpt(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line")
    var
        NoSeries: Codeunit "No. Series";
        Item: Record Item;
        ServItemGr: Record "Service Item Group";
        TrackingLinesExist: Boolean;
        i: Integer;
        ServItemWithSerialNoExist: Boolean;
        IsHandled: Boolean;
        ShouldCreateServiceItem: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateServItemOnSalesLineShpt(SalesHeader, SalesLine, SalesShipmentLine, IsHandled, TempReservEntry, TempServiceItem, TempServiceItemComp);
        if IsHandled then
            exit;

        if DoesSalesLineNeedServiceItemCreation(SalesLine, Item, ServItemGr) then begin
            if SalesLine."Qty. to Ship (Base)" <> Round(SalesLine."Qty. to Ship (Base)", 1) then
                Error(
                  Text003,
                  Item.TableCaption(),
                  Item."No.",
                  ServItemGr.TableCaption(),
                  SalesLine.FieldCaption("Qty. to Ship (Base)"));

            TempReservEntry.SetRange("Item No.", SalesLine."No.");
            TempReservEntry.SetRange("Location Code", SalesLine."Location Code");
            TempReservEntry.SetRange("Variant Code", SalesLine."Variant Code");
            TempReservEntry.SetRange("Source Subtype", SalesLine."Document Type");
            TempReservEntry.SetRange("Source ID", SalesLine."Document No.");
            TempReservEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
            TrackingLinesExist := TempReservEntry.FindSet();

            TempServiceItem.DeleteAll();
            TempServiceItemComp.DeleteAll();

            GLSetup.Get();
            ServMgtSetup.Get();
            ServMgtSetup.TestField("Service Item Nos.");
            for i := 1 to SalesLine."Qty. to Ship (Base)" do begin
                Clear(ServItem);
                ServItemWithSerialNoExist := false;
                if TempReservEntry."Serial No." <> '' then begin
                    ServItem.SetRange("Item No.", SalesLine."No.");
                    ServItem.SetRange("Serial No.", TempReservEntry."Serial No.");
                    if ServItem.FindFirst() then
                        ServItemWithSerialNoExist := true;
                end;
                ShouldCreateServiceItem := (TempReservEntry."Serial No." = '') or (not ServItemWithSerialNoExist);
                OnCreateServItemOnSalesLineShptOnAfterCalcShouldCreateServiceItem(SalesLine, SalesShipmentLine, TempReservEntry."Serial No.", ServItem, ServItemWithSerialNoExist, ShouldCreateServiceItem);
                if ShouldCreateServiceItem then begin
                    ServItem.Init();
                    ServItem."No. Series" := ServMgtSetup."Service Item Nos.";
                    ServItem."No." := NoSeries.GetNextNo(ServItem."No. Series");
                    ServItem.Insert();
                end;

                IsHandled := false;
                OnCreateServItemOnSalesLineShptOnAfterInsertServiceItem(
                    ServItem, SalesHeader, SalesLine, SalesShipmentLine, TempReservEntry, ServItemWithSerialNoExist, IsHandled);
                if not IsHandled then begin
                    ModifyServiceItem(SalesHeader, SalesLine, SalesShipmentLine, ServItem, Item, TrackingLinesExist);

                    Clear(TempServiceItem);
                    TempServiceItem := ServItem;
                    if TempServiceItem.Insert() then;
                    ResSkillMgt.AssignServItemResSkills(ServItem);

                    AddServiceItemComponents(SalesHeader, SalesLine, SalesShipmentLine);

                    Clear(ServLogMgt);
                    ServLogMgt.ServItemAutoCreated(ServItem);
                end;

                TrackingLinesExist := TempReservEntry.Next() = 1;
            end;
        end;
    end;

    local procedure ModifyServiceItem(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line"; var ServItem: Record "Service Item"; Item: Record Item; TrackingLinesExist: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        ItemTrackingWarrantyDF: DateFormula;
        WarrantyStartDate: Date;
    begin
        ServItem."Sales/Serv. Shpt. Document No." := SalesShipmentLine."Document No.";
        ServItem."Sales/Serv. Shpt. Line No." := SalesShipmentLine."Line No.";
        ServItem."Shipment Type" := ServItem."Shipment Type"::Sales;
        ServItem.Validate(Description,
            CopyStr(SalesLine.Description, 1, MaxStrLen(ServItem.Description)));
        ServItem."Description 2" := CopyStr(
            StrSubstNo('%1 %2', SalesHeader."Document Type", SalesHeader."No."),
            1, MaxStrLen(ServItem."Description 2"));
        ServItem.Validate("Customer No.", SalesHeader."Sell-to Customer No.");
        ServItem.Validate("Ship-to Code", SalesHeader."Ship-to Code");
        ServItem.OmitAssignResSkills(true);
        ServItem.Validate("Item No.", Item."No.");
        ServItem.OmitAssignResSkills(false);
        if TrackingLinesExist then
            ServItem."Serial No." := TempReservEntry."Serial No.";
        ServItem."Variant Code" := SalesLine."Variant Code";
        ItemUnitOfMeasure.Get(Item."No.", SalesLine."Unit of Measure Code");
        ServItem.Validate("Sales Unit Cost", Round(SalesLine."Unit Cost (LCY)" /
            ItemUnitOfMeasure."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision"));
        if SalesHeader."Currency Code" <> '' then
            ServItem.Validate(
                "Sales Unit Price",
                CalcAmountLCY(
                Round(SalesLine."Unit Price" /
                    ItemUnitOfMeasure."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision"),
                SalesHeader."Currency Factor",
                SalesHeader."Currency Code",
                SalesHeader."Posting Date"))
        else
            ServItem.Validate("Sales Unit Price", Round(SalesLine."Unit Price" /
                ItemUnitOfMeasure."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision"));
        ServItem."Vendor No." := Item."Vendor No.";
        ServItem."Vendor Item No." := Item."Vendor Item No.";
        ServItem."Unit of Measure Code" := Item."Base Unit of Measure";
        ServItem."Sales Date" := SalesHeader."Posting Date";
        ServItem."Installation Date" := SalesHeader."Posting Date";
        ServItem."Warranty % (Parts)" := ServMgtSetup."Warranty Disc. % (Parts)";
        ServItem."Warranty % (Labor)" := ServMgtSetup."Warranty Disc. % (Labor)";

        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            ItemTrackingCode.Init();

        if TrackingLinesExist and (TempReservEntry."Warranty Date" <> 0D) then
            if Format(ItemTrackingCode."Warranty Date Formula") <> '' then begin
                Evaluate(ItemTrackingWarrantyDF, StrSubstNo('-%1', ItemTrackingCode."Warranty Date Formula"));
                WarrantyStartDate := CalcDate(ItemTrackingWarrantyDF, TempReservEntry."Warranty Date");
            end
            else
                WarrantyStartDate := TempReservEntry."Warranty Date"
        else begin
            WarrantyStartDate := SalesHeader."Posting Date";
            if (WarrantyStartDate = 0D) and SalesLine."Drop Shipment" then
                if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, SalesLine."Purchase Order No.") then
                    WarrantyStartDate := PurchaseHeader."Posting Date";
        end;

        CalcServiceWarrantyDates(
            ServItem, WarrantyStartDate, ItemTrackingCode."Warranty Date Formula", ServMgtSetup."Default Warranty Duration");

        OnCreateServItemOnSalesLineShpt(ServItem, SalesHeader, SalesLine);

        ServItem.Modify();
    end;

    local procedure AddServiceItemComponents(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line")
    var
        ServItemComponent: Record "Service Item Component";
        BOMComp: Record "BOM Component";
        BOMComp2: Record "BOM Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        CreateServItemOnSalesLineShptOnBeforeInsertServiceItemComponents(ServItem, IsHandled);
        if not IsHandled then
            if SalesLine."BOM Item No." <> '' then begin
                Clear(BOMComp);
                BOMComp.SetRange("Parent Item No.", SalesLine."BOM Item No.");
                BOMComp.SetRange(Type, BOMComp.Type::Item);
                BOMComp.SetRange("No.", SalesLine."No.");
                BOMComp.SetRange("Installed in Line No.", 0);
                if BOMComp.FindSet() then
                    repeat
                        Clear(BOMComp2);
                        BOMComp2.SetRange("Parent Item No.", SalesLine."BOM Item No.");
                        BOMComp2.SetRange("Installed in Line No.", BOMComp."Line No.");
                        NextLineNo := 0;
                        if BOMComp2.FindSet() then
                            repeat
                                for Index := 1 to Round(BOMComp2."Quantity per", 1) do begin
                                    NextLineNo := NextLineNo + 10000;
                                    InsertServiceItemComponent(ServItemComponent, BOMComp, BOMComp2, SalesHeader, SalesShipmentLine);
                                    Clear(TempServiceItemComp);
                                    TempServiceItemComp := ServItemComponent;
                                    TempServiceItemComp.Insert();
                                end;
                            until BOMComp2.Next() = 0;
                    until BOMComp.Next() = 0;
            end;

        OnCreateServItemOnSalesLineShptOnAfterAddServItemComponents(
            SalesHeader, SalesLine, SalesShipmentLine, ServItem, TempServiceItem, TempServiceItemComp);
    end;

    procedure CalcServiceWarrantyDates(var ServiceItem: Record "Service Item"; StartingWarrantyDate: Date; ItemTrackingWarrantyDateFormula: DateFormula; ServMgtSetupDefaultWarrantyDuration: DateFormula)
    begin
        ServiceItem."Warranty Starting Date (Parts)" := StartingWarrantyDate;
        ServiceItem."Warranty Starting Date (Labor)" := StartingWarrantyDate;
        if Format(ItemTrackingWarrantyDateFormula) <> '' then
            ServiceItem."Warranty Ending Date (Parts)" := CalcDate(ItemTrackingWarrantyDateFormula, StartingWarrantyDate)
        else
            ServiceItem."Warranty Ending Date (Parts)" := CalcDate(ServMgtSetupDefaultWarrantyDuration, StartingWarrantyDate);
        ServiceItem."Warranty Ending Date (Labor)" := CalcDate(ServMgtSetupDefaultWarrantyDuration, StartingWarrantyDate);
    end;

    procedure CreateServItemOnServItemLine(var ServItemLine: Record "Service Item Line")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        OnBeforeCreateServItemOnServItemLine(ServItemLine);
        ServItemLine.TestField("Service Item No.", '');
        ServItemLine.TestField("Document No.");
        ServItemLine.TestField(Description);
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text000), true) then
            exit;

        Clear(ServItem);
        ServItem.Init();
        ServMgtSetup.Get();
        ServMgtSetup.TestField("Service Item Nos.");
        ServItem."No. Series" := ServMgtSetup."Service Item Nos.";
        ServItem."No." := NoSeries.GetNextNo(ServItem."No. Series");
        OnCreateServItemOnServItemLineOnBeforeServiceItemInsert(ServItem, ServItemLine);
        ServItem.Insert();
        ServItem.Validate(Description, ServItemLine.Description);
        Clear(ServHeader);
        ServHeader.Get(ServItemLine."Document Type", ServItemLine."Document No.");
        ServItem.Validate("Customer No.", ServHeader."Customer No.");
        ServItem.Validate("Ship-to Code", ServHeader."Ship-to Code");
        ServItem.OmitAssignResSkills(true);
        ServItem.Validate("Item No.", ServItemLine."Item No.");
        ServItem.OmitAssignResSkills(false);
        ServItem."Variant Code" := ServItemLine."Variant Code";
        ServItem.Validate("Serial No.", ServItemLine."Serial No.");
        ServItem."Response Time (Hours)" := ServItemLine."Response Time (Hours)";
        ServItem."Sales Unit Cost" := 0;
        ServItem."Sales Unit Price" := 0;
        ServItem."Vendor No." := ServItemLine."Vendor No.";
        ServItem."Vendor Item No." := ServItemLine."Vendor Item No.";
        ServItem."Unit of Measure Code" := '';
        ServItem."Sales Date" := 0D;
        ServItem."Installation Date" := ServHeader."Posting Date";
        ServItem."Warranty Starting Date (Parts)" := ServItemLine."Warranty Starting Date (Parts)";
        ServItem."Warranty Ending Date (Parts)" := ServItemLine."Warranty Ending Date (Parts)";
        ServItem."Warranty Starting Date (Labor)" := ServItemLine."Warranty Starting Date (Labor)";
        ServItem."Warranty Ending Date (Labor)" := ServItemLine."Warranty Ending Date (Labor)";
        ServItem."Warranty % (Parts)" := ServItemLine."Warranty % (Parts)";
        ServItem."Warranty % (Labor)" := ServItemLine."Warranty % (Labor)";
        ServItem."Service Item Group Code" := ServItemLine."Service Item Group Code";
        if ServItemLine."Service Price Group Code" <> '' then
            if ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text002, ServItemLine.FieldCaption(ServItemLine."Service Price Group Code"),
                   ServItemLine.TableCaption, ServItem.TableCaption()), true)
            then
                ServItem."Service Price Group Code" := ServItemLine."Service Price Group Code";

        OnCreateServItemOnServItemLineOnBeforeServItemModify(ServItem, ServHeader, ServItemLine);
        ServItem.Modify();
        ResSkillMgt.AssignServItemResSkills(ServItem);
        Clear(ServLogMgt);
        ServLogMgt.ServItemAutoCreated(ServItem);
        Message(Text001, ServItem."No.");
        ServItemLine."Service Item No." := ServItem."No.";
        ServItemLine."Contract No." := '';

        IsHandled := false;
        OnCreateServItemOnServItemLine(ServItem, ServItemLine, IsHandled);
        if not IsHandled then begin
            ServItemLine.Modify();
            ServItemLine.CreateDimFromDefaultDim(0);
        end;

        ServLogMgt.ServItemToServOrder(ServItemLine);

        ServInvoiceLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServInvoiceLine.SetRange("Document Type", ServItemLine."Document Type");
        ServInvoiceLine.SetRange("Document No.", ServItemLine."Document No.");
        ServInvoiceLine.SetRange("Service Item Line No.", ServItemLine."Line No.");
        ServInvoiceLine.ModifyAll("Service Item No.", ServItemLine."Service Item No.");

        OnAfterCreateServItemOnServItemLine(ServItemLine);
    end;

    procedure CalcAmountLCY(FCAmount: Decimal; CurrencyFactor: Decimal; CurrencyCode: Code[10]; CurrencyDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency.TestField("Unit-Amount Rounding Precision");
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              CurrencyDate, CurrencyCode,
              FCAmount, CurrencyFactor),
            Currency."Unit-Amount Rounding Precision"));
    end;

    procedure CopyReservationEntry(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ServItemGr: Record "Service Item Group";
        SalesLineNeedServiceItemCreation: Boolean;
    begin
        OnBeforeCopyReservationEntry(SalesHeader, TempReservEntry);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Qty. to Ship", '<>0');
        SalesLine.SetLoadFields("Document Type", "Document No.", "Line No.", Type, "No.");
        if SalesLine.FindSet() then
            repeat
                SalesLineNeedServiceItemCreation := DoesSalesLineNeedServiceItemCreation(SalesLine, Item, ServItemGr);
                OnBeforeCopyReservationEntryLineAfterCheckSalesLineNeedsServiceItemCreation(SalesLine, SalesLineNeedServiceItemCreation);
                if SalesLineNeedServiceItemCreation then
                    CopyReservationEntryLine(SalesLine);
            until SalesLine.Next() = 0;
    end;

    procedure CopyReservationEntryService(ServHeader: Record "Service Header")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.Reset();
        Clear(TempReservEntry);

        ReservEntry.SetRange("Source Subtype", ServHeader."Document Type");
        ReservEntry.SetRange("Source ID", ServHeader."No.");
        ReservEntry.SetRange(Positive, false);
        ReservEntry.SetRange("Source Type", DATABASE::"Service Line");
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        ReservEntry.SetFilter("Serial No.", '<>%1', '');
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>%1', 0);

        if ReservEntry.FindSet() then
            repeat
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until ReservEntry.Next() = 0;
    end;

    procedure CreateServItemOnSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        DummySalesShptLine: Record "Sales Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateServItemOnSalesInvoice(SalesHeader, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                CreateServItemOnSalesLineShpt(SalesHeader, SalesLine, DummySalesShptLine);
            until SalesLine.Next() = 0;
    end;

    local procedure CheckWholeNumber(var ServLine: Record "Service Line")
    begin
        if ServLine.Quantity <> Round(ServLine.Quantity, 1) then
            Error(Text004, ServLine.FieldCaption(Quantity), ServLine.TableCaption);
        if ServLine."Qty. to Ship" <> Round(ServLine."Qty. to Ship", 1) then
            Error(Text004, ServLine.FieldCaption("Qty. to Ship"), ServLine.TableCaption);
    end;

    procedure ReturnServItemComp(var TempServItem: Record "Service Item" temporary; var TempServItemComp: Record "Service Item Component" temporary)
    begin
        TempServItem.DeleteAll();
        if TempServiceItem.Find('-') then
            repeat
                TempServItem := TempServiceItem;
                TempServItem.Insert();
            until TempServiceItem.Next() = 0;
        TempServItemComp.DeleteAll();
        if TempServiceItemComp.Find('-') then
            repeat
                TempServItemComp := TempServiceItemComp;
                TempServItemComp.Insert();
            until TempServiceItemComp.Next() = 0;
    end;

    procedure DeleteServItemOnSaleCreditMemo(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        ServItem: Record "Service Item";
        ReservationEntry: Record "Reservation Entry";
        ServItemDeleted: Boolean;
        IsHandled: Boolean;
    begin
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order"]) then
            exit;

        IsHandled := false;
        OnBeforeDeleteServItemOnSaleCreditMemo(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        ServItemDeleted := false;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                if SalesLine.Type = SalesLine.Type::Item then begin
                    ReservationEntry.SetRange("Item No.", SalesLine."No.");
                    ReservationEntry.SetRange("Location Code", SalesLine."Location Code");
                    ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
                    ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
                    if ReservationEntry.FindSet() then
                        repeat
                            ServItem.SetRange("Item No.", SalesLine."No.");
                            ServItem.SetRange("Customer No.", SalesLine."Sell-to Customer No.");
                            ServItem.SetRange("Serial No.", ReservationEntry."Serial No.");
                            if ServItem.FindFirst() then
                                if ServItem.CheckIfCanBeDeleted() <> '' then begin
                                    ServItem.Validate(Status, ServItem.Status::" ");
                                    ServItem.Modify(true);
                                end else
                                    if ServItem.Delete(true) then
                                        ServItemDeleted := true;
                        until ReservationEntry.Next() = 0;
                end;
            until SalesLine.Next() = 0;
        if ServItemDeleted then
            Message(Text005);
    end;

    local procedure CopyReservationEntryLine(var SalesLine: Record "Sales Line")
    var
        ReservEntry: Record "Reservation Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyReservationEntryLine(SalesLine, TempReservEntry, IsHandled);
        if IsHandled then
            exit;

        Clear(TempReservEntry);

        ReservEntry.Reset();
        ReservEntry.SetRange("Source Subtype", SalesLine."Document Type");
        ReservEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservEntry.SetRange(Positive, false);
        ReservEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        if Item.Get(SalesLine."No.") then
            if (Item."Item Tracking Code" <> '') and ItemTrackingCode.Get(Item."Item Tracking Code") and ItemTrackingCode."SN Specific Tracking" then
                ReservEntry.SetFilter("Serial No.", '<>%1', '');
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>%1', 0);

        OnCopyReservationEntryLineOnBeforeReservationEntryFindSet(SalesLine, ReservEntry);

        if ReservEntry.FindSet() then
            repeat
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until ReservEntry.Next() = 0;
    end;

    procedure CopyReservation(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Drop Shipment", true);
        PurchaseLine.SetFilter(Quantity, '<>0');
        PurchaseLine.SetLoadFields(PurchaseLine."Sales Order No.", PurchaseLine."Sales Order Line No.");
        if PurchaseLine.FindSet() then
            repeat
                if DoesPurchaseLineNeedServiceItemCreation(PurchaseLine) then begin
                    SalesLine.SetLoadFields("Document Type", "Document No.", "Line No.");
                    if SalesLine.Get(SalesLine."Document Type"::Order, PurchaseLine."Sales Order No.", PurchaseLine."Sales Order Line No.") then
                        CopyReservationEntryLine(SalesLine);
                end;
            until PurchaseLine.Next() = 0;
    end;

    procedure DoesSalesLineNeedServiceItemCreation(SalesLine: Record "Sales Line"; var Item: Record Item; var ServItemGr: Record "Service Item Group") SalesLineNeedsServiceItem: Boolean
    var
        IsHandled: Boolean;
    begin
        SalesLineNeedsServiceItem := false;
        OnBeforeDoesSalesLineNeedServiceItemCreation(SalesLine, SalesLineNeedsServiceItem, Item, ServItemGr, IsHandled);
        if IsHandled then
            exit;

        if not (SalesLine."Document Type" in [SalesLine."Document Type"::Order, SalesLine."Document Type"::Invoice]) then
            exit;

        if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."Qty. to Ship (Base)" > 0) then begin

            Item.SetLoadFields("Service Item Group", "Vendor No.", "Vendor Item No.", "Base Unit of Measure", "Item Tracking Code");
            Item.Get(SalesLine."No.");

            ServItemGr.SetLoadFields("Create Service Item");
            if ServItemGr.Get(Item."Service Item Group") and ServItemGr."Create Service Item" then
                SalesLineNeedsServiceItem := true;
        end;
    end;

    procedure DoesPurchaseLineNeedServiceItemCreation(PurchaseLine: Record "Purchase Line") PurchaseLineNeedsServiceItem: Boolean
    var
        Item: Record Item;
        ServItemGr: Record "Service Item Group";
        IsHandled: Boolean;
    begin
        PurchaseLineNeedsServiceItem := false;
        OnBeforeDoesPurchaseLineNeedServiceItemCreation(PurchaseLine, PurchaseLineNeedsServiceItem, IsHandled);
        if IsHandled then
            exit;

        if (PurchaseLine."Sales Order No." = '') or (PurchaseLine."Sales Order Line No." = 0) then
            exit;

        if (PurchaseLine.Type = PurchaseLine.Type::Item) and (PurchaseLine."Qty. to Receive (Base)" > 0) then begin
            Item.SetLoadFields("Service Item Group", "Vendor No.", "Vendor Item No.", "Base Unit of Measure", "Item Tracking Code");
            Item.Get(PurchaseLine."No.");

            ServItemGr.SetLoadFields("Create Service Item");
            if ServItemGr.Get(Item."Service Item Group") and ServItemGr."Create Service Item" then
                PurchaseLineNeedsServiceItem := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddOrReplaceSIComponentPermanentTemporary(var ServItem: Record "Service Item"; var ServLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewServItemComponent(var ServItemComponent: Record "Service Item Component"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyReservationEntry(SalesHeader: Record "Sales Header"; var TempReservationEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateServItemOnSalesLineShpt(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean; var TempReservEntry: Record "Reservation Entry"; var TempServiceItem: Record "Service Item" temporary; var TempServiceItemComponent: Record "Service Item Component" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateServItemOnServItemLine(var ServItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServItemOnSaleCreditMemo(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServItemComponent(var ServiceItemComponent: Record "Service Item Component"; ServiceItem: Record "Service Item"; SalesHeader: Record "Sales Header"; SalesShipmentLine: Record "Sales Shipment Line"; BOMComponent: Record "BOM Component"; BOMComponent2: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewServItemComponent(var ServiceItemComponent: Record "Service Item Component"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReplaceSIComponent(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServShptDocNo: Code[20]; ServShptLineNo: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnSalesLineShpt(var ServiceItem: Record "Service Item"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnServItemLine(var ServiceItem: Record "Service Item"; ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnServItemLineOnBeforeServItemModify(var ServiceItem: Record "Service Item"; ServiceHeader: Record "Service Header"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnSalesLineShptOnAfterAddServItemComponents(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesShipmentLine: Record "Sales Shipment Line"; var ServiceItem: Record "Service Item"; var TempServiceItem: Record "Service Item" temporary; var TempServiceItemComp: Record "Service Item Component" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnSalesLineShptOnAfterCalcShouldCreateServiceItem(SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line"; var SerialNo: Code[50]; var ServItem: Record "Service Item"; var ServItemWithSerialNoExist: Boolean; var ShouldCreateServiceItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure CreateServItemOnSalesLineShptOnBeforeInsertServiceItemComponents(var ServItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnSalesLineShptOnAfterInsertServiceItem(var ServiceItem: Record "Service Item"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line"; var TempReservEntry: Record "Reservation Entry" temporary; ServItemWithSerialNoExist: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateServItemOnServItemLine(ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateServItemOnSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyReservationEntryLineOnBeforeReservationEntryFindSet(SalesLine: Record "Sales Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyReservationEntryLine(SalesLine: Record "Sales Line"; var TempReservationEntry: Record "Reservation Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoesSalesLineNeedServiceItemCreation(SalesLine: Record "Sales Line"; var SalesLineNeedsServiceItem: Boolean; var Item: Record Item; var ServItemGr: Record "Service Item Group"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoesPurchaseLineNeedServiceItemCreation(PurchaseLine: Record "Purchase Line"; var PurchaseLineNeedsServiceItem: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyReservationEntryLineAfterCheckSalesLineNeedsServiceItemCreation(var SalesLine: Record "Sales Line"; var SalesLineNeedServiceItemCreation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnServItemLineOnBeforeServiceItemInsert(var ServiceItem: Record "Service Item"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnAfterOnDelete', '', false, false)]
    local procedure ItemVariantOnAfterOnDelete(ItemVariant: Record "Item Variant")
    var
        ServiceLine: Record "Service Line";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
    begin
        ServiceItem.SetCurrentKey("Item No.", "Serial No.");
        ServiceItem.SetRange("Item No.", ItemVariant."Item No.");
        ServiceItem.SetRange("Variant Code", ItemVariant.Code);
        if not ServiceItem.IsEmpty() then
            Error(CannotDeleteErr, ItemVariant.Code, ServiceItem.TableCaption());

        ServiceLine.SetCurrentKey(Type, "No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetRange("No.", ItemVariant."Item No.");
        ServiceLine.SetRange("Variant Code", ItemVariant.Code);
        if not ServiceLine.IsEmpty() then
            Error(CannotDeleteErr, ItemVariant.Code, ServiceLine.TableCaption());

        ServiceContractLine.SetRange("Item No.", ItemVariant."Item No.");
        ServiceContractLine.SetRange("Variant Code", ItemVariant.Code);
        if not ServiceContractLine.IsEmpty() then
            Error(CannotDeleteErr, ItemVariant.Code, ServiceContractLine.TableCaption());

        ServiceItemComponent.SetRange(Type, ServiceItemComponent.Type::Item);
        ServiceItemComponent.SetRange("No.", ItemVariant."Item No.");
        ServiceItemComponent.SetRange("Variant Code", ItemVariant.Code);
        ServiceItemComponent.ModifyAll("Variant Code", '');
    end;
}