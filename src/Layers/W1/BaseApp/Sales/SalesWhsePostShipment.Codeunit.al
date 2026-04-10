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

/// <summary>
/// Handles sales-specific processing during warehouse shipment posting, including updating sales lines and posting sales documents.
/// </summary>
codeunit 5746 "Sales Whse. Post Shipment"
{

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
                    if not IsHandled then
                        if (SalesHeader."Posting Date" = 0D) or
                            (SalesHeader."Posting Date" <> WhseShptHeader."Posting Date") or ValidatePostingDate
                        then begin
                            NewCalledFromWhseDoc := true;
                            OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(SalesHeader, WhsePostParameters, NewCalledFromWhseDoc);
                            SalesRelease.SetSkipWhseRequestOperations(true);
                            SalesRelease.Reopen(SalesHeader);
                            SalesRelease.SetSkipCheckReleaseRestrictions();
                            SalesHeader.SetHideValidationDialog(true);
                            SalesHeader.SetCalledFromWhseDoc(NewCalledFromWhseDoc);
                            SalesHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
                            OnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(SalesHeader, WhseShptHeader, WhseShptLine);
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
        if IsHandled then
            exit;

        SalesLine.SetRange("Document Type", WhseShptLine."Source Subtype");
        SalesLine.SetRange("Document No.", WhseShptLine."Source No.");
        OnHandleSalesLineOnBeforeSalesLineFind(SalesLine);
        if SalesLine.Find('-') then
            repeat
                WhseShptLine.SetRange(WhseShptLine."Source Line No.", SalesLine."Line No.");
                OnHandleSalesLineOnFilterWhseShptLine(SalesLine, WhseShptLine);
                if WhseShptLine.Find('-') then begin
                    OnAfterFindWhseShptLineForSalesLine(WhseShptLine, SalesLine);
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
                            if WhsePostParameters."Post Invoice" then
                                SalesLine.Validate(
                                  "Qty. to Invoice",
                                  -WhseShptLine."Qty. to Ship" + SalesLine."Return Qty. Received" - SalesLine."Quantity Invoiced");
                        end;
                    end;
                    ShouldModifyShipmentDate := (WhseShptHeader."Shipment Date" <> 0D) and (SalesLine."Shipment Date" <> WhseShptHeader."Shipment Date") and (WhseShptLine."Qty. to Ship" = WhseShptLine."Qty. Outstanding");
                    OnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WhseShptHeader, WhseShptLine, SalesLine, ShouldModifyShipmentDate);
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
                if ModifyLine then
                    SalesLine.Modify();
                OnHandleSalesLineOnAfterSalesLineModify(SalesLine, ModifyLine, WhseShptHeader);
            until SalesLine.Next() = 0;

        OnAfterHandleSalesLine(WhseShptLine, SalesHeader, WhseShptHeader, WhsePostParameters);
    end;

    local procedure UpdateSaleslineQtyToShip(var SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean; SumOfQtyToShip: Decimal; SumOfQtyToShipBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSaleslineQtyToShip(SalesLine, WhseShptLine, ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound, SumOfQtyToShip, SumOfQtyToShipBase, IsHandled);
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
                    if WhsePostParameters."Print Documents" then
                        if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Sales Order" then begin
                            IsHandled := false;
                            OnPostSourceDocumentOnBeforePrintSalesShipment(SalesHeader, IsHandled, SalesShptHeader, WhseShptHeader);
                            if not IsHandled then
                                InsertDocumentEntryToPrint(
                                    DocumentEntryToPrint, Database::"Sales Shipment Header", SalesHeader."Last Shipping No.");
                            if WhsePostParameters."Post Invoice" then begin
                                IsHandled := false;
                                OnPostSourceDocumentOnBeforePrintSalesInvoice(SalesHeader, IsHandled, WhseShptLine);
                                if not IsHandled then
                                    InsertDocumentEntryToPrint(
                                        DocumentEntryToPrint, Database::"Sales Invoice Header", SalesHeader."Last Posting No.");
                            end;
                        end;

                    OnAfterSalesPost(WhseShptLine, SalesHeader, WhsePostParameters);
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
        if IsHandled then
            exit;

        if SalesPost.Run(SalesHeader) then begin
            CounterSourceDocOK := CounterSourceDocOK + 1;
            Result := true;
        end;
        OnPostSourceDocumentOnAfterSalesPost(CounterSourceDocOK, SalesPost, SalesHeader, Result);
    end;

    local procedure PostSourceSalesDocument(var SalesHeader: Record "Sales Header"; var SalesPost: Codeunit "Sales-Post"; var CounterSourceDocOK: Integer)
    begin
        OnBeforePostSourceSalesDocument(SalesPost);

        SalesPost.RunWithCheck(SalesHeader);
        CounterSourceDocOK := CounterSourceDocOK + 1;

        OnAfterPostSourceSalesDocument(CounterSourceDocOK, SalesPost, SalesHeader);
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
        end;
    end;

    /// <summary>
    /// Raises an event before updating the sales line quantity to ship based on warehouse shipment quantities.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line to update.</param>
    /// <param name="WhseShptLine">Specifies the warehouse shipment line.</param>
    /// <param name="ATOWhseShptLine">Specifies the assemble-to-order warehouse shipment line.</param>
    /// <param name="NonATOWhseShptLine">Specifies the non-assemble-to-order warehouse shipment line.</param>
    /// <param name="ATOLineFound">Indicates whether an assemble-to-order line was found.</param>
    /// <param name="NonATOLineFound">Indicates whether a non-assemble-to-order line was found.</param>
    /// <param name="SumOfQtyToShip">Specifies the total quantity to ship.</param>
    /// <param name="SumOfQtyToShipBase">Specifies the total quantity to ship in base units.</param>
    /// <param name="IsHandled">Set to true to skip the default quantity update logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSaleslineQtyToShip(var SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean; SumOfQtyToShip: Decimal; SumOfQtyToShipBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event before validating the posting date on the sales header during source document initialization.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to validate.</param>
    /// <param name="WarehouseShipmentLine">Specifies the warehouse shipment line being processed.</param>
    /// <param name="ValidatePostingDate">Indicates whether to validate the posting date.</param>
    /// <param name="IsHandled">Set to true to skip the default posting date validation.</param>
    /// <param name="ModifyHeader">Indicates whether the header should be modified.</param>
    /// <param name="WhseShptHeader">Specifies the warehouse shipment header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeValidatePostingDate(var SalesHeader: Record "Sales Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ValidatePostingDate: Boolean; var IsHandled: Boolean; var ModifyHeader: Boolean; var WhseShptHeader: Record "Warehouse Shipment Header");
    begin
    end;

    /// <summary>
    /// Raises an event before reopening the sales header during warehouse shipment processing.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header to reopen.</param>
    /// <param name="WhsePostParameters">Specifies the warehouse posting parameters.</param>
    /// <param name="NewCalledFromWhseDoc">Indicates whether the operation is called from a warehouse document.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(var SalesHeader: Record "Sales Header"; WhsePostParameters: Record "Whse. Post Parameters"; var NewCalledFromWhseDoc: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event before releasing the sales header during warehouse shipment processing.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header to release.</param>
    /// <param name="WhseShptHeader">Specifies the warehouse shipment header.</param>
    /// <param name="WhseShptLine">Specifies the warehouse shipment line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(var SalesHeader: Record "Sales Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    /// <summary>
    /// Raises an event before modifying the sales header during source document initialization.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header being modified.</param>
    /// <param name="WarehouseShipmentHeader">Specifies the warehouse shipment header.</param>
    /// <param name="ModifyHeader">Indicates whether the header should be modified.</param>
    /// <param name="WhsePostParameters">Specifies the warehouse posting parameters.</param>
    /// <param name="WarehouseShipmentLine">Specifies the warehouse shipment line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean; WhsePostParameters: Record "Whse. Post Parameters"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    /// <summary>
    /// Raises an event before handling a sales line during warehouse shipment processing.
    /// </summary>
    /// <param name="WarehouseShipmentLine">Specifies the warehouse shipment line.</param>
    /// <param name="SalesLine">Specifies the sales line to process.</param>
    /// <param name="SalesHeader">Specifies the sales header.</param>
    /// <param name="WhseShptHeader">Specifies the warehouse shipment header.</param>
    /// <param name="ModifyLine">Indicates whether the line should be modified.</param>
    /// <param name="IsHandled">Set to true to skip the default line handling logic.</param>
    /// <param name="WhsePostParameters">Specifies the warehouse posting parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    /// <summary>
    /// Raises an event before finding a sales line during warehouse shipment line handling.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnBeforeSalesLineFind(var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raises an event after finding a warehouse shipment line for a sales line.
    /// </summary>
    /// <param name="WarehouseShipmentLine">Specifies the found warehouse shipment line.</param>
    /// <param name="SalesLine">Specifies the corresponding sales line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raises an event before modifying a sales order line during warehouse shipment handling.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line to modify.</param>
    /// <param name="WhseShptLine">Specifies the warehouse shipment line.</param>
    /// <param name="WhsePostParameters">Specifies the warehouse posting parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine(var SalesLine: Record "Sales Line"; WhseShptLine: Record "Warehouse Shipment Line"; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    /// <summary>
    /// Raises an event after validating the return quantity to receive on a sales line.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line with validated return quantity.</param>
    /// <param name="WhseShptLine">Specifies the warehouse shipment line.</param>
    /// <param name="WhsePostParameters">Specifies the warehouse posting parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterValidateRetQtytoReceive(var SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; WhsePostParameters: Record "Whse. Post Parameters");
    begin
    end;

    /// <summary>
    /// Raises an event after calculating whether the shipment date should be modified on the sales line.
    /// </summary>
    /// <param name="WarehouseShipmentHeader">Specifies the warehouse shipment header.</param>
    /// <param name="WarehouseShipmentLine">Specifies the warehouse shipment line.</param>
    /// <param name="SalesLine">Specifies the sales line.</param>
    /// <param name="ShouldModifyShipmentDate">Indicates whether the shipment date should be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line"; var ShouldModifyShipmentDate: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event before modifying a sales line during warehouse shipment processing.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line to modify.</param>
    /// <param name="WarehouseShipmentLine">Specifies the warehouse shipment line.</param>
    /// <param name="ModifyLine">Indicates whether the line should be modified.</param>
    /// <param name="WhsePostParameters">Specifies the warehouse posting parameters.</param>
    /// <param name="WarehouseShipmentHeader">Specifies the warehouse shipment header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; WhsePostParameters: Record "Whse. Post Parameters"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    /// <summary>
    /// Raises an event after a sales line has been modified during warehouse shipment handling.
    /// </summary>
    /// <param name="SalesLine">Specifies the modified sales line.</param>
    /// <param name="ModifyLine">Indicates whether the line was modified.</param>
    /// <param name="WarehouseShipmentHeader">Specifies the warehouse shipment header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterSalesLineModify(var SalesLine: Record "Sales Line"; ModifyLine: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    /// <summary>
    /// Raises an event after handling a sales line during warehouse shipment processing.
    /// </summary>
    /// <param name="WhseShipmentLine">Specifies the warehouse shipment line that was processed.</param>
    /// <param name="SalesHeader">Specifies the sales header.</param>
    /// <param name="WarehouseShipmentHeader">Specifies the warehouse shipment header.</param>
    /// <param name="WhsePostParameters">Specifies the warehouse posting parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleSalesLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record "Sales Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    /// <summary>
    /// Raises an event after calculating whether a non-warehouse line should be modified.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line.</param>
    /// <param name="ModifyLine">Indicates whether the line should be modified.</param>
    /// <param name="WhseShptLine">Specifies the warehouse shipment line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnNonWhseLineOnAfterCalcModifyLine(var SalesLine: Record "Sales Line"; var ModifyLine: Boolean; WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    /// <summary>
    /// Raises an event before posting a sales header during warehouse shipment processing.
    /// </summary>
    /// <param name="SalesPost">Specifies the Sales-Post codeunit instance.</param>
    /// <param name="SalesHeader">Specifies the sales header to post.</param>
    /// <param name="WhseShptHeader">Specifies the warehouse shipment header.</param>
    /// <param name="CounterSourceDocOK">Specifies the count of successfully posted source documents.</param>
    /// <param name="WhsePostParameters">Specifies the warehouse posting parameters.</param>
    /// <param name="IsHandled">Set to true to skip the default posting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostSalesHeader(var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var CounterSourceDocOK: Integer; var WhsePostParameters: Record "Whse. Post Parameters"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event before printing sales documents after warehouse shipment posting.
    /// </summary>
    /// <param name="LastShippingNo">Specifies the number of the last shipment document.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesDocuments(LastShippingNo: Code[20])
    begin
    end;

    /// <summary>
    /// Raises an event before printing a sales shipment document.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header.</param>
    /// <param name="IsHandled">Set to true to skip the default print logic.</param>
    /// <param name="SalesShptHeader">Specifies the posted sales shipment header.</param>
    /// <param name="WhseShptHeader">Specifies the warehouse shipment header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesShipment(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesShptHeader: Record "Sales Shipment Header"; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    /// <summary>
    /// Raises an event before printing a sales invoice after warehouse shipment posting.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header.</param>
    /// <param name="IsHandled">Set to true to skip the default print logic.</param>
    /// <param name="WhseShptLine">Specifies the warehouse shipment line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesInvoice(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    /// <summary>
    /// Raises an event after the sales document has been posted during warehouse shipment processing.
    /// </summary>
    /// <param name="WarehouseShipmentLine">Specifies the warehouse shipment line.</param>
    /// <param name="SalesHeader">Specifies the posted sales header.</param>
    /// <param name="WhsePostParameters">Specifies the warehouse posting parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record "Sales Header"; WhsePostParameters: Record "Whse. Post Parameters")
    begin
    end;

    /// <summary>
    /// Raises an event before executing the Sales-Post codeunit during warehouse shipment posting.
    /// </summary>
    /// <param name="CounterSourceDocOK">Specifies the count of successfully posted source documents.</param>
    /// <param name="SalesPost">Specifies the Sales-Post codeunit instance.</param>
    /// <param name="SalesHeader">Specifies the sales header to post.</param>
    /// <param name="IsHandled">Set to true to skip the default posting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeSalesPost(var CounterSourceDocOK: Integer; var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event after executing the Sales-Post codeunit during warehouse shipment posting.
    /// </summary>
    /// <param name="CounterSourceDocOK">Specifies the count of successfully posted source documents.</param>
    /// <param name="SalesPost">Specifies the Sales-Post codeunit instance.</param>
    /// <param name="SalesHeader">Specifies the posted sales header.</param>
    /// <param name="Result">Indicates whether the posting was successful.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnAfterSalesPost(var CounterSourceDocOK: Integer; var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event before posting a source sales document.
    /// </summary>
    /// <param name="SalesPost">Specifies the Sales-Post codeunit instance.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceSalesDocument(var SalesPost: Codeunit "Sales-Post")
    begin
    end;

    /// <summary>
    /// Raises an event after posting a source sales document.
    /// </summary>
    /// <param name="CounterSourceDocOK">Specifies the count of successfully posted source documents.</param>
    /// <param name="SalesPost">Specifies the Sales-Post codeunit instance.</param>
    /// <param name="SalesHeader">Specifies the posted sales header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceSalesDocument(var CounterSourceDocOK: Integer; var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raises an event after printing a sales shipment document.
    /// </summary>
    /// <param name="ShipmentNo">Specifies the shipment document number that was printed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrintDocumentsOnAfterPrintSalesShipment(ShipmentNo: Code[20])
    begin
    end;

    /// <summary>
    /// Raises an event before updating an attached line during warehouse shipment processing.
    /// </summary>
    /// <param name="SalesLine">Specifies the attached sales line to update.</param>
    /// <param name="WarehouseShipmentLine">Specifies the warehouse shipment line.</param>
    /// <param name="ModifyLine">Indicates whether the line should be modified.</param>
    /// <param name="IsHandled">Set to true to skip the default update logic.</param>
    /// <param name="Result">Returns the result of the update operation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAttachedLine(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event before modifying an attached line during warehouse shipment processing.
    /// </summary>
    /// <param name="SalesLine">Specifies the attached sales line.</param>
    /// <param name="WarehouseShipmentLine">Specifies the warehouse shipment line.</param>
    /// <param name="ModifyLine">Indicates whether the line should be modified.</param>
    /// <param name="QtyToHandle">Specifies the quantity to handle.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateAttachedLineOnBeforeModifyLine(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; var QtyToHandle: Decimal)
    begin
    end;

    /// <summary>
    /// Raises an event when filtering warehouse shipment lines for a sales line.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line.</param>
    /// <param name="WarehouseShipmentLine">Specifies the warehouse shipment line with filters to apply.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnFilterWhseShptLine(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    /// <summary>
    /// Raises an event before printing documents after warehouse shipment posting.
    /// </summary>
    /// <param name="DocumentEntryToPrint">Specifies the document entries to print.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocuments(var DocumentEntryToPrint: Record "Document Entry")
    begin
    end;
}