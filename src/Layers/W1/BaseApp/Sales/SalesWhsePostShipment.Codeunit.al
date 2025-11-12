// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Posting;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Navigate;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Setup;

codeunit 5746 "Sales Whse. Post Shipment"
{
#if not CLEAN25
    var
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnGetSourceDocumentOnElseCase', '', false, false)]
    local procedure OnGetSourceDocument(var SourceHeader: Variant; var WhseShptLine: Record "Warehouse Shipment Line"; var GenJnlTemplateName: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        case WhseShptLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesHeader.Get(WhseShptLine."Source Subtype", WhseShptLine."Source No.");
                    SourceHeader := SalesHeader;
                    GenJnlTemplateName := SalesHeader."Journal Templ. Name";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnInitSourceDocumentHeader', '', false, false)]
    local procedure OnInitSourceDocumentHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var SourceHeader: Variant; WhsePostParameters: Record "Whse. Post Parameters" temporary);
    var
        SalesHeader: Record "Sales Header";
        SalesRelease: Codeunit "Release Sales Document";
        NewCalledFromWhseDoc: Boolean;
        ValidatePostingDate: Boolean;
        ModifyHeader: Boolean;
        IsHandled: Boolean;
    begin
        case WhseShptLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesHeader := SourceHeader;
                    SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
                    IsHandled := false;
                    OnInitSourceDocumentHeaderOnBeforeValidatePostingDate(SalesHeader, WhseShptLine, ValidatePostingDate, IsHandled, ModifyHeader, WhseShptHeader);
#if not CLEAN25
                    WhsePostShipment.RunOnInitSourceDocumentHeaderOnBeforeValidatePostingDate(SalesHeader, WhseShptLine, ValidatePostingDate, IsHandled, ModifyHeader, WhseShptHeader);
#endif
                    if not IsHandled then
                        if (SalesHeader."Posting Date" = 0D) or
                            (SalesHeader."Posting Date" <> WhseShptHeader."Posting Date") or ValidatePostingDate
                        then begin
                            NewCalledFromWhseDoc := true;
                            OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(SalesHeader, WhsePostParameters, NewCalledFromWhseDoc);
#if not CLEAN25
                            WhsePostShipment.RunOnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(SalesHeader, WhsePostParameters, NewCalledFromWhseDoc);
#endif
                            SalesRelease.SetSkipWhseRequestOperations(true);
                            SalesRelease.Reopen(SalesHeader);
                            SalesRelease.SetSkipCheckReleaseRestrictions();
                            SalesHeader.SetHideValidationDialog(true);
                            SalesHeader.SetCalledFromWhseDoc(NewCalledFromWhseDoc);
                            SalesHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
                            OnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(SalesHeader, WhseShptHeader, WhseShptLine);
#if not CLEAN25
                            WhsePostShipment.RunOnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(SalesHeader, WhseShptHeader, WhseShptLine);
#endif
                            SalesRelease.Run(SalesHeader);
                            ModifyHeader := true;
                        end;
                    if (WhseShptHeader."Shipment Date" <> 0D) and
                       (WhseShptHeader."Shipment Date" <> SalesHeader."Shipment Date")
                    then begin
                        SalesHeader."Shipment Date" := WhseShptHeader."Shipment Date";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."External Document No." <> '') and
                       (WhseShptHeader."External Document No." <> SalesHeader."External Document No.")
                    then begin
                        SalesHeader."External Document No." := WhseShptHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Code" <> '') and
                       (WhseShptHeader."Shipping Agent Code" <> SalesHeader."Shipping Agent Code")
                    then begin
                        SalesHeader."Shipping Agent Code" := WhseShptHeader."Shipping Agent Code";
                        SalesHeader."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Service Code" <> '') and
                       (WhseShptHeader."Shipping Agent Service Code" <>
                        SalesHeader."Shipping Agent Service Code")
                    then begin
                        SalesHeader."Shipping Agent Service Code" :=
                          WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipment Method Code" <> '') and
                       (WhseShptHeader."Shipment Method Code" <> SalesHeader."Shipment Method Code")
                    then begin
                        SalesHeader."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(SalesHeader, WhseShptHeader, ModifyHeader, WhsePostParameters, WhseShptLine);
#if not CLEAN25
                    WhsePostShipment.RunOnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(SalesHeader, WhseShptHeader, ModifyHeader, WhsePostParameters, WhseShptLine);
#endif
                    if ModifyHeader then
                        SalesHeader.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnAfterInitSourceDocumentLines', '', false, false)]
    local procedure OnAfterInitSourceDocumentLines(var WhseShptLine2: Record "Warehouse Shipment Line"; var SourceHeader: Variant; var WhseShptHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters")
    var
        SalesHeader: Record "Sales Header";
    begin
        case WhseShptLine2."Source Type" of
            Database::"Sales Line":
                begin
                    SalesHeader := SourceHeader;
                    SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
                    HandleSalesLine(WhseShptLine2, SalesHeader, WhseShptHeader, WhsePostParameters);
                end;
        end;
    end;

    local procedure HandleSalesLine(var WhseShptLine: Record "Warehouse Shipment Line"; var SalesHeader: Record "Sales Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters")
    var
        SalesLine: Record "Sales Line";
        ATOWhseShptLine: Record "Warehouse Shipment Line";
        NonATOWhseShptLine: Record "Warehouse Shipment Line";
        ATOLink: Record "Assemble-to-Order Link";
        AsmHeader: Record "Assembly Header";
        ModifyLine: Boolean;
        ATOLineFound: Boolean;
        NonATOLineFound: Boolean;
        SumOfQtyToShip: Decimal;
        SumOfQtyToShipBase: Decimal;
        IsHandled: Boolean;
        ShouldModifyShipmentDate: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleSalesLine(WhseShptLine, SalesLine, SalesHeader, WhseShptHeader, ModifyLine, IsHandled, WhsePostParameters);
#if not CLEAN25
        WhsePostShipment.RunOnBeforeHandleSalesLine(WhseShptLine, SalesLine, SalesHeader, WhseShptHeader, ModifyLine, IsHandled, WhsePostParameters);
#endif
        if IsHandled then
            exit;

        SalesLine.SetRange("Document Type", WhseShptLine."Source Subtype");
        SalesLine.SetRange("Document No.", WhseShptLine."Source No.");
        OnHandleSalesLineOnBeforeSalesLineFind(SalesLine);
#if not CLEAN25
        WhsePostShipment.RunOnHandleSalesLineOnBeforeSalesLineFind(SalesLine);
#endif
        if SalesLine.Find('-') then
            repeat
                WhseShptLine.SetRange(WhseShptLine."Source Line No.", SalesLine."Line No.");
                OnHandleSalesLineOnFilterWhseShptLine(SalesLine, WhseShptLine);
                if WhseShptLine.Find('-') then begin
                    OnAfterFindWhseShptLineForSalesLine(WhseShptLine, SalesLine);
#if not CLEAN25
                    WhsePostShipment.RunOnAfterFindWhseShptLineForSalesLine(WhseShptLine, SalesLine);
#endif
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Sales Order" then begin
                        SumOfQtyToShip := 0;
                        SumOfQtyToShipBase := 0;
                        WhseShptLine.GetATOAndNonATOLines(ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound);
                        if ATOLineFound then begin
                            SumOfQtyToShip += ATOWhseShptLine."Qty. to Ship";
                            SumOfQtyToShipBase += ATOWhseShptLine."Qty. to Ship (Base)";
                        end;
                        if NonATOLineFound then begin
                            SumOfQtyToShip += NonATOWhseShptLine."Qty. to Ship";
                            SumOfQtyToShipBase += NonATOWhseShptLine."Qty. to Ship (Base)";
                        end;

                        OnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine(SalesLine, WhseShptLine, WhsePostParameters);
#if not CLEAN25
                        WhsePostShipment.RunOnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine(SalesLine, WhseShptLine, WhsePostParameters);
#endif
                        ModifyLine := SalesLine."Qty. to Ship" <> SumOfQtyToShip;
                        if ModifyLine then begin
                            UpdateSaleslineQtyToShip(SalesLine, WhseShptLine, ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound, SumOfQtyToShip, SumOfQtyToShipBase);
                            if ATOLineFound then
                                ATOLink.UpdateQtyToAsmFromWhseShptLine(ATOWhseShptLine);
                            if WhsePostParameters."Post Invoice" then
                                SalesLine.Validate(
                                  "Qty. to Invoice",
                                  SalesLine."Qty. to Ship" + SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced");
                        end;
                    end else begin
                        ModifyLine := SalesLine."Return Qty. to Receive" <> -WhseShptLine."Qty. to Ship";
                        if ModifyLine then begin
                            SalesLine.Validate("Return Qty. to Receive", -WhseShptLine."Qty. to Ship");
                            OnHandleSalesLineOnAfterValidateRetQtytoReceive(SalesLine, WhseShptLine, WhsePostParameters);
#if not CLEAN25
                            WhsePostShipment.RunOnHandleSalesLineOnAfterValidateRetQtytoReceive(SalesLine, WhseShptLine, WhsePostParameters);
#endif
                            if WhsePostParameters."Post Invoice" then
                                SalesLine.Validate(
                                  "Qty. to Invoice",
                                  -WhseShptLine."Qty. to Ship" + SalesLine."Return Qty. Received" - SalesLine."Quantity Invoiced");
                        end;
                    end;
                    ShouldModifyShipmentDate := (WhseShptHeader."Shipment Date" <> 0D) and (SalesLine."Shipment Date" <> WhseShptHeader."Shipment Date") and (WhseShptLine."Qty. to Ship" = WhseShptLine."Qty. Outstanding");
                    OnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WhseShptHeader, WhseShptLine, SalesLine, ShouldModifyShipmentDate);
#if not CLEAN25
                    WhsePostShipment.RunOnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WhseShptHeader, WhseShptLine, SalesLine, ShouldModifyShipmentDate);
#endif
                    if ShouldModifyShipmentDate then begin
                        SalesLine."Shipment Date" := WhseShptHeader."Shipment Date";
                        ModifyLine := true;
                        if ATOLineFound then
                            if AsmHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No.") then begin
                                AsmHeader."Due Date" := WhseShptHeader."Shipment Date";
                                AsmHeader.Modify(true);
                            end;
                    end;
                    if SalesLine."Bin Code" <> WhseShptLine."Bin Code" then begin
                        SalesLine."Bin Code" := WhseShptLine."Bin Code";
                        ModifyLine := true;
                        if ATOLineFound then
                            ATOLink.UpdateAsmBinCodeFromWhseShptLine(ATOWhseShptLine);
                    end;
                end else
                    if not UpdateAllNonInventoryLines(SalesHeader, SalesLine, ModifyLine) then
                        if not UpdateAttachedLine(SalesLine, WhseShptLine, ModifyLine) then
                            ClearSalesLineQtyToShipReceive(SalesHeader, SalesLine, WhseShptLine, ModifyLine);
                OnBeforeSalesLineModify(SalesLine, WhseShptLine, ModifyLine, WhsePostParameters, WhseShptHeader);
#if not CLEAN25
                WhsePostShipment.RunOnBeforeSalesLineModify(SalesLine, WhseShptLine, ModifyLine, WhsePostParameters, WhseShptHeader);
#endif
                if ModifyLine then
                    SalesLine.Modify();
                OnHandleSalesLineOnAfterSalesLineModify(SalesLine, ModifyLine, WhseShptHeader);
#if not CLEAN25
                WhsePostShipment.RunOnHandleSalesLineOnAfterSalesLineModify(SalesLine, ModifyLine, WhseShptHeader);
#endif
            until SalesLine.Next() = 0;

        OnAfterHandleSalesLine(WhseShptLine, SalesHeader, WhseShptHeader, WhsePostParameters);
#if not CLEAN25
        WhsePostShipment.RunOnAfterHandleSalesLine(WhseShptLine, SalesHeader, WhseShptHeader, WhsePostParameters);
#endif
    end;

    local procedure UpdateSaleslineQtyToShip(var SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean; SumOfQtyToShip: Decimal; SumOfQtyToShipBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSaleslineQtyToShip(SalesLine, WhseShptLine, ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound, SumOfQtyToShip, SumOfQtyToShipBase, IsHandled);
#if not CLEAN25
        WhsePostShipment.RunOnBeforeUpdateSaleslineQtyToShip(SalesLine, WhseShptLine, ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound, SumOfQtyToShip, SumOfQtyToShipBase, IsHandled);
#endif
        if IsHandled then
            exit;

        SalesLine.Validate("Qty. to Ship", SumOfQtyToShip);
        SalesLine."Qty. to Ship (Base)" := SalesLine.MaxQtyToShipBase(SumOfQtyToShipBase);
    end;

    local procedure UpdateAllNonInventoryLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ModifyLine: Boolean): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if SalesLine.IsInventoriableItem() then
            exit(false);

        SalesReceivablesSetup.Get();
        if (SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::All) and
           (SalesHeader."Shipping Advice" <> SalesHeader."Shipping Advice"::Complete)
        then
            exit(false);

        if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
            ModifyLine := SalesLine."Qty. to Ship" <> SalesLine."Outstanding Quantity";
            if ModifyLine then
                SalesLine.Validate("Qty. to Ship", SalesLine."Outstanding Quantity");
        end else begin
            ModifyLine := SalesLine."Return Qty. to Receive" <> SalesLine."Outstanding Quantity";
            if ModifyLine then
                SalesLine.Validate("Return Qty. to Receive", SalesLine."Outstanding Quantity");
        end;

        exit(true);
    end;

    local procedure ClearSalesLineQtyToShipReceive(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean)
    begin
        ModifyLine :=
            ((SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Partial) or
            (SalesLine.Type = SalesLine.Type::Item)) and
            ((SalesLine."Qty. to Ship" <> 0) or
            (SalesLine."Return Qty. to Receive" <> 0) or
            (SalesLine."Qty. to Invoice" <> 0));
        OnHandleSalesLineOnNonWhseLineOnAfterCalcModifyLine(SalesLine, ModifyLine, WarehouseShipmentLine);
#if not CLEAN25
        WhsePostShipment.RunOnHandleSalesLineOnNonWhseLineOnAfterCalcModifyLine(SalesLine, ModifyLine, WarehouseShipmentLine);
#endif

        if ModifyLine then begin
            if WarehouseShipmentLine."Source Document" = WarehouseShipmentLine."Source Document"::"Sales Order" then
                SalesLine.Validate("Qty. to Ship", 0)
            else
                SalesLine.Validate("Return Qty. to Receive", 0);
            SalesLine.Validate("Qty. to Invoice", 0);
        end;
    end;

    local procedure UpdateAttachedLine(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean) Result: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        WhseShptLine2: Record "Warehouse Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        QtyToHandle: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAttachedLine(SalesLine, WarehouseShipmentLine, ModifyLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit(false);

        if SalesLine.Type = SalesLine.Type::"Charge (Item)" then begin
            ItemChargeAssignmentSales.SetRange("Document Type", SalesLine."Document Type");
            ItemChargeAssignmentSales.SetRange("Document No.", SalesLine."Document No.");
            ItemChargeAssignmentSales.SetRange("Document Line No.", SalesLine."Line No.");
            ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", SalesLine."Document Type");
            ItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", SalesLine."Document No.");
            ItemChargeAssignmentSales.SetFilter("Qty. to Handle", '<>0');
            if not ItemChargeAssignmentSales.FindSet() then
                exit(false);
            repeat
                WhseShptLine2.Copy(WarehouseShipmentLine);
                WhseShptLine2.SetRange("Source Line No.", ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                if not WhseShptLine2.IsEmpty() then
                    QtyToHandle += ItemChargeAssignmentSales."Qty. to Handle";
            until ItemChargeAssignmentSales.Next() = 0;
        end else begin
            if SalesLine."Attached to Line No." = 0 then
                exit(false);
            WhseShptLine2.Copy(WarehouseShipmentLine);
            WhseShptLine2.SetRange("Source Line No.", SalesLine."Attached to Line No.");
            if WhseShptLine2.IsEmpty() then
                exit(false);
            QtyToHandle := SalesLine."Outstanding Quantity";
        end;

        OnUpdateAttachedLineOnBeforeModifyLine(SalesLine, WarehouseShipmentLine, ModifyLine, QtyToHandle);
        if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
            ModifyLine := SalesLine."Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Qty. to Ship", QtyToHandle);
        end else begin
            ModifyLine := SalesLine."Return Qty. to Receive" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Return Qty. to Receive", QtyToHandle);
        end;

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnPostSourceDocument', '', false, false)]
    local procedure OnPostSourceDocument(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var CounterDocOK: Integer; var SourceHeader: Variant; WhsePostParameters: Record "Whse. Post Parameters"; var DocumentEntryToPrint: Record "Document Entry" temporary)
    var
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        WarehouseSetup: Record "Warehouse Setup";
        SalesPost: Codeunit "Sales-Post";
        IsHandled: Boolean;
    begin
        case WhseShptLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesHeader := SourceHeader;
                    SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Sales Order" then
                        SalesHeader.Ship := true
                    else
                        SalesHeader.Receive := true;
                    SalesHeader.Invoice := WhsePostParameters."Post Invoice";

                    SalesPost.SetWhseShptHeader(WhseShptHeader);
                    SalesPost.SetPreviewMode(WhsePostParameters."Preview Posting");
                    SalesPost.SetSuppressCommit(WhsePostParameters."Suppress Commit");
                    SalesPost.SetCalledBy(Codeunit::"Whse.-Post Shipment");

                    IsHandled := false;
                    OnPostSourceDocumentOnBeforePostSalesHeader(SalesPost, SalesHeader, WhseShptHeader, CounterDocOK, WhsePostParameters, IsHandled);
#if not CLEAN25
                    WhsePostShipment.RunOnPostSourceDocumentOnBeforePostSalesHeader(SalesPost, SalesHeader, WhseShptHeader, CounterDocOK, WhsePostParameters, IsHandled);
#endif
                    if not IsHandled then
                        if WhsePostParameters."Preview Posting" then
                            PostSourceSalesDocument(SalesHeader, SalesPost, CounterDocOK)
                        else begin
                            WarehouseSetup.Get();
                            case WarehouseSetup."Shipment Posting Policy" of
                                WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                                    TryPostSourceSalesDocument(SalesHeader, SalesPost, CounterDocOK);
                                WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                                    PostSourceSalesDocument(SalesHeader, SalesPost, CounterDocOK);
                            end;
                        end;

                    OnPostSourceDocumentOnBeforePrintSalesDocuments(SalesHeader."Last Shipping No.");
#if not CLEAN25
                    WhsePostShipment.RunOnPostSourceDocumentOnBeforePrintSalesDocuments(SalesHeader."Last Shipping No.");
#endif
                    if WhsePostParameters."Print Documents" then
                        if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Sales Order" then begin
                            IsHandled := false;
                            OnPostSourceDocumentOnBeforePrintSalesShipment(SalesHeader, IsHandled, SalesShptHeader, WhseShptHeader);
#if not CLEAN25
                            WhsePostShipment.RunOnPostSourceDocumentOnBeforePrintSalesShipment(SalesHeader, IsHandled, SalesShptHeader, WhseShptHeader);
#endif
                            if not IsHandled then
                                InsertDocumentEntryToPrint(
                                    DocumentEntryToPrint, Database::"Sales Shipment Header", SalesHeader."Last Shipping No.");
                            if WhsePostParameters."Post Invoice" then begin
                                IsHandled := false;
                                OnPostSourceDocumentOnBeforePrintSalesInvoice(SalesHeader, IsHandled, WhseShptLine);
#if not CLEAN25
                                WhsePostShipment.RunOnPostSourceDocumentOnBeforePrintSalesInvoice(SalesHeader, IsHandled, WhseShptLine);
#endif
                                if not IsHandled then
                                    InsertDocumentEntryToPrint(
                                        DocumentEntryToPrint, Database::"Sales Invoice Header", SalesHeader."Last Posting No.");
                            end;
                        end;

                    OnAfterSalesPost(WhseShptLine, SalesHeader, WhsePostParameters);
#if not CLEAN25
                    WhsePostShipment.RunOnAfterSalesPost(WhseShptLine, SalesHeader, WhsePostParameters);
#endif
                    Clear(SalesPost);
                end;
        end;
    end;

    local procedure InsertDocumentEntryToPrint(var DocumentEntry: Record "Document Entry"; TableID: Integer; DocumentNo: Code[20])
    begin
        DocumentEntry.Init();
        DocumentEntry."Entry No." := DocumentEntry."Entry No." + 1;
        DocumentEntry."Table ID" := TableID;
        DocumentEntry."Document No." := DocumentNo;
        DocumentEntry.Insert();
    end;

    local procedure TryPostSourceSalesDocument(var SalesHeader: Record "Sales Header"; var SalesPost: Codeunit "Sales-Post"; var CounterSourceDocOK: Integer)
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnPostSourceDocumentOnBeforeSalesPost(CounterSourceDocOK, SalesPost, SalesHeader, IsHandled);
#if not CLEAN25
        WhsePostShipment.RunOnPostSourceDocumentOnBeforeSalesPost(CounterSourceDocOK, SalesPost, SalesHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        if SalesPost.Run(SalesHeader) then begin
            CounterSourceDocOK := CounterSourceDocOK + 1;
            Result := true;
        end;
        OnPostSourceDocumentOnAfterSalesPost(CounterSourceDocOK, SalesPost, SalesHeader, Result);
#if not CLEAN25
        WhsePostShipment.RunOnPostSourceDocumentOnAfterSalesPost(CounterSourceDocOK, SalesPost, SalesHeader, Result);
#endif
    end;

    local procedure PostSourceSalesDocument(var SalesHeader: Record "Sales Header"; var SalesPost: Codeunit "Sales-Post"; var CounterSourceDocOK: Integer)
    begin
        OnBeforePostSourceSalesDocument(SalesPost);
#if not CLEAN25
        WhsePostShipment.RunOnBeforePostSourceSalesDocument(SalesPost);
#endif

        SalesPost.RunWithCheck(SalesHeader);
        CounterSourceDocOK := CounterSourceDocOK + 1;

        OnAfterPostSourceSalesDocument(CounterSourceDocOK, SalesPost, SalesHeader);
#if not CLEAN25
        WhsePostShipment.RunOnAfterPostSourceSalesDocument(CounterSourceDocOK, SalesPost, SalesHeader);
#endif
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnPrintDocuments', '', false, false)]
    local procedure OnPrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    begin
        PrintDocuments(DocumentEntryToPrint);
    end;

    local procedure PrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        OnBeforePrintDocuments(DocumentEntryToPrint);

        DocumentEntryToPrint.SetRange("Table ID", Database::"Sales Invoice Header");
        if not DocumentEntryToPrint.IsEmpty() then begin
            if DocumentEntryToPrint.FindSet() then
                repeat
                    SalesInvoiceHeader.Get(DocumentEntryToPrint."Document No.");
                    SalesInvoiceHeader.Mark(true);
                until DocumentEntryToPrint.Next() = 0;

            SalesInvoiceHeader.MarkedOnly(true);
            SalesInvoiceHeader.PrintRecords(false);
        end;

        DocumentEntryToPrint.SetRange("Table ID", Database::"Sales Shipment Header");
        if not DocumentEntryToPrint.IsEmpty() then begin
            if DocumentEntryToPrint.FindSet() then
                repeat
                    SalesShipmentHeader.Get(DocumentEntryToPrint."Document No.");
                    SalesShipmentHeader.Mark(true);
                until DocumentEntryToPrint.Next() = 0;

            SalesShipmentHeader.MarkedOnly(true);
            SalesShipmentHeader.PrintRecords(false);
            OnPrintDocumentsOnAfterPrintSalesShipment(SalesShipmentHeader."No.");
#if not CLEAN25
            WhsePostShipment.RunOnPrintDocumentsOnAfterPrintSalesShipment(SalesShipmentHeader."No.");
#endif
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSaleslineQtyToShip(var SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean; SumOfQtyToShip: Decimal; SumOfQtyToShipBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeValidatePostingDate(var SalesHeader: Record "Sales Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ValidatePostingDate: Boolean; var IsHandled: Boolean; var ModifyHeader: Boolean; var WhseShptHeader: Record "Warehouse Shipment Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(var SalesHeader: Record "Sales Header"; WhsePostParameters: Record "Whse. Post Parameters"; var NewCalledFromWhseDoc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(var SalesHeader: Record "Sales Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean; WhsePostParameters: Record "Whse. Post Parameters"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnBeforeSalesLineFind(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine(var SalesLine: Record "Sales Line"; WhseShptLine: Record "Warehouse Shipment Line"; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterValidateRetQtytoReceive(var SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; WhsePostParameters: Record "Whse. Post Parameters");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line"; var ShouldModifyShipmentDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; WhsePostParameters: Record "Whse. Post Parameters"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterSalesLineModify(var SalesLine: Record "Sales Line"; ModifyLine: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleSalesLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record "Sales Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnNonWhseLineOnAfterCalcModifyLine(var SalesLine: Record "Sales Line"; var ModifyLine: Boolean; WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostSalesHeader(var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var CounterSourceDocOK: Integer; var WhsePostParameters: Record "Whse. Post Parameters"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesDocuments(LastShippingNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesShipment(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesShptHeader: Record "Sales Shipment Header"; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesInvoice(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record "Sales Header"; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeSalesPost(var CounterSourceDocOK: Integer; var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnAfterSalesPost(var CounterSourceDocOK: Integer; var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceSalesDocument(var SalesPost: Codeunit "Sales-Post")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceSalesDocument(var CounterSourceDocOK: Integer; var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintDocumentsOnAfterPrintSalesShipment(ShipmentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAttachedLine(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAttachedLineOnBeforeModifyLine(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; var QtyToHandle: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnFilterWhseShptLine(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    begin
    end;
}
