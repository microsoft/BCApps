// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;

codeunit 1314 "Purch. Doc. From Sales Doc."
{

    trigger OnRun()
    begin
    end;

    var
        CreatePurchInvOptionQst: Label 'All Lines,Selected Lines';
        CreatePurchInvInstructionTxt: Label 'A purchase invoice will be created. Select which sales invoice lines to use.';
        SelectVentorTxt: Label 'Select a vendor';
#pragma warning disable AA0470
        TypeNotSupportedErr: Label 'Type %1 is not supported.', Comment = 'Line or Document type';
#pragma warning restore AA0470
        NoPurchaseOrdersCreatedErr: Label 'No purchase orders are created.';

    procedure CreatePurchaseInvoice(SalesHeader: Record "Sales Header"; var SelectedSalesLine: Record "Sales Line")
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        OptionNumber: Integer;
        IsHandled: Boolean;
    begin
        OptionNumber := DIALOG.StrMenu(CreatePurchInvOptionQst, 1, CreatePurchInvInstructionTxt);

        if OptionNumber = 0 then
            exit;

        case OptionNumber of
            0:
                exit;
            1:
                begin
                    SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                    SalesLine.SetRange("Document No.", SalesHeader."No.");
                end;
            2:
                SalesLine.Copy(SelectedSalesLine);
        end;

        if SelectVendor(Vendor, SalesLine) then begin
            OnBeforeCreatePurchaseInvoice(SalesHeader, SalesLine);
            CreatePurchaseHeader(PurchaseHeader, SalesHeader, Vendor);
            CopySalesLinesToPurchaseLines(PurchaseHeader, SalesLine);
            IsHandled := false;
            OnCreatePurchaseInvoiceOnBeforeOpenPage(PurchaseHeader, IsHandled);
            if not IsHandled then
                PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader);
        end;
    end;

    procedure CreatePurchaseOrder(SalesHeader: Record "Sales Header")
    var
        TempManufacturingUserTemplate: Record "Manufacturing User Template" temporary;
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        TempDocumentEntry: Record "Document Entry" temporary;
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
        PurchOrderFromSalesOrder: Page "Purch. Order From Sales Order";
        NoFilter: Text;
    begin
        TempManufacturingUserTemplate.Init();
        TempManufacturingUserTemplate."User ID" := CopyStr(UserId(), 1, MaxStrLen(TempManufacturingUserTemplate."User ID"));
        TempManufacturingUserTemplate."Make Orders" := TempManufacturingUserTemplate."Make Orders"::"The Active Order";
        TempManufacturingUserTemplate."Create Purchase Order" :=
          TempManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders";
        TempManufacturingUserTemplate."Create Production Order" := TempManufacturingUserTemplate."Create Production Order"::" ";
        TempManufacturingUserTemplate."Create Transfer Order" := TempManufacturingUserTemplate."Create Transfer Order"::" ";
        TempManufacturingUserTemplate."Create Assembly Order" := TempManufacturingUserTemplate."Create Assembly Order"::" ";
        TempManufacturingUserTemplate.Insert();

        PurchOrderFromSalesOrder.LookupMode(true);
        PurchOrderFromSalesOrder.SetSalesOrderNo(SalesHeader."No.");
        if PurchOrderFromSalesOrder.RunModal() <> ACTION::LookupOK then begin
            OrderPlanningMgt.PrepareRequisitionRecord(RequisitionLine);
            exit;
        end;

        PurchOrderFromSalesOrder.GetRecord(RequisitionLine);
        RequisitionLine.SetRange("User ID", UserId);
        RequisitionLine.SetRange("Demand Order No.", SalesHeader."No.");
        RequisitionLine.SetRange("Demand Subtype", SalesHeader."Document Type"::Order);
        RequisitionLine.SetRange(Level);
        RequisitionLine.SetFilter(Quantity, '>%1', 0);
        if not RequisitionLine.IsEmpty() then
            MakeSupplyOrders(TempManufacturingUserTemplate, TempDocumentEntry, RequisitionLine);

        TempDocumentEntry.SetRange("Table ID", DATABASE::"Purchase Header");
        if TempDocumentEntry.FindSet() then
            repeat
                if PurchaseHeader.Get(TempDocumentEntry."Document Type", TempDocumentEntry."Document No.") then
                    BuildFilter(NoFilter, PurchaseHeader."No.");
            until TempDocumentEntry.Next() = 0;

        if NoFilter = '' then
            Error(NoPurchaseOrdersCreatedErr);

        PurchaseHeader.SetFilter("No.", NoFilter);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        OnCreatePurchaseOrderOnAfterPurchaseHeaderSetFilters(PurchaseHeader, SalesHeader);

        case PurchaseHeader.Count of
            0:
                Error(NoPurchaseOrdersCreatedErr);
            1:
                PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);
            else
                PAGE.Run(PAGE::"Purchase Order List", PurchaseHeader);
        end;
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; Vendor: Record Vendor)
    begin
        PurchaseHeader.Init();

        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Order] then
            PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice)
        else
            Error(TypeNotSupportedErr, Format(SalesHeader."Document Type"));

        OnBeforeInitRecord(PurchaseHeader, SalesHeader, Vendor);
        PurchaseHeader.InitRecord();
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        OnCreatePurchaseHeaderOnBeforeInsert(PurchaseHeader, SalesHeader, Vendor);
        PurchaseHeader.Insert(true);
    end;

    local procedure CopySalesLinesToPurchaseLines(PurchaseHeader: Record "Purchase Header"; var SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineNo: Integer;
        IsHandled: Boolean;
    begin
        PurchaseLineNo := 0;
        if SalesLine.Find('-') then
            repeat
                Clear(PurchaseLine);
                PurchaseLine.Init();
                PurchaseLine."Document No." := PurchaseHeader."No.";
                PurchaseLine."Document Type" := PurchaseHeader."Document Type";

                PurchaseLineNo := PurchaseLineNo + 10000;
                PurchaseLine."Line No." := PurchaseLineNo;

                case SalesLine.Type of
                    SalesLine.Type::" ":
                        PurchaseLine.Type := PurchaseLine.Type::" ";
                    SalesLine.Type::Item:
                        PurchaseLine.Type := PurchaseLine.Type::Item;
                    else begin
                        IsHandled := false;
                        OnCopySalesLinesToPurchaseLinesOnLineTypeValidate(PurchaseLine, SalesLine, IsHandled);
                        if not IsHandled then
                            Error(TypeNotSupportedErr, Format(SalesLine.Type));
                    end
                end;

                PurchaseLine.Validate("No.", SalesLine."No.");
                PurchaseLine.Description := SalesLine.Description;
                OnCopySalesLinesToPurchaseLinesOnAfterAssignDescription(PurchaseLine, SalesLine);

                if PurchaseLine."No." <> '' then begin
                    PurchaseLine.Validate("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
                    PurchaseLine.Validate("Pay-to Vendor No.", PurchaseHeader."Pay-to Vendor No.");
                    PurchaseLine.Validate(Quantity, SalesLine.Quantity);
                    PurchaseLine.Validate("Unit of Measure Code", SalesLine."Unit of Measure Code");
                end;

                OnCopySalesLinesToPurchaseLinesOnBeforeInsert(PurchaseLine, SalesLine);
                PurchaseLine.Insert(true);
            until SalesLine.Next() = 0;
    end;

    local procedure SelectVendor(var Vendor: Record Vendor; var SelectedSalesLine: Record "Sales Line"): Boolean
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        VendorList: Page "Vendor List";
        VendorNo: Code[20];
        DefaultVendorFound: Boolean;
    begin
        SalesLine.Copy(SelectedSalesLine);

        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("No.", '<>%1', '');
        if SalesLine.FindSet() then begin
            Item.Get(SalesLine."No.");
            VendorNo := Item."Vendor No.";
            DefaultVendorFound := (VendorNo <> '');

            while DefaultVendorFound and (SalesLine.Next() <> 0) do begin
                Item.Get(SalesLine."No.");
                DefaultVendorFound := (VendorNo = Item."Vendor No.");
            end;

            if DefaultVendorFound then begin
                Vendor.Get(VendorNo);
                exit(true);
            end;
        end;

        VendorList.LookupMode(true);
        VendorList.Caption(SelectVentorTxt);
        if VendorList.RunModal() = ACTION::LookupOK then begin
            VendorList.GetRecord(Vendor);
            exit(true);
        end;

        exit(false);
    end;

    local procedure BuildFilter(var InitialFilter: Text; NewValue: Text)
    begin
        if StrPos(InitialFilter, NewValue) = 0 then begin
            if StrLen(InitialFilter) > 0 then
                InitialFilter += '|';
            InitialFilter += NewValue;
        end;
    end;

    local procedure MakeSupplyOrders(var TempManufacturingUserTemplate: Record "Manufacturing User Template" temporary; var TempDocumentEntry: Record "Document Entry" temporary; var RequisitionLine: Record "Requisition Line")
    var
        MakeSupplyOrdersYesNo: Codeunit "Make Supply Orders (Yes/No)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeSupplyOrders(TempManufacturingUserTemplate, TempDocumentEntry, RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        MakeSupplyOrdersYesNo.SetManufUserTemplate(TempManufacturingUserTemplate);
        MakeSupplyOrdersYesNo.SetBlockForm();

        MakeSupplyOrdersYesNo.SetCreatedDocumentBuffer(TempDocumentEntry);
        MakeSupplyOrdersYesNo.Run(RequisitionLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLinesToPurchaseLinesOnAfterAssignDescription(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLinesToPurchaseLinesOnBeforeInsert(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLinesToPurchaseLinesOnLineTypeValidate(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchaseHeaderOnBeforeInsert(var PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchaseOrderOnAfterPurchaseHeaderSetFilters(var PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeSupplyOrders(var TempManufacturingUserTemplate: Record "Manufacturing User Template" temporary; var TempDocumentEntry: Record "Document Entry" temporary; var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchaseInvoiceOnBeforeOpenPage(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}

