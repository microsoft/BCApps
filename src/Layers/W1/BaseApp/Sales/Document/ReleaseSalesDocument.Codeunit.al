// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Sales.Setup;
using System.Automation;

/// <summary>
/// Releases sales documents for further processing such as shipping, invoicing, or warehouse handling.
/// </summary>
codeunit 414 "Release Sales Document"
{
    TableNo = "Sales Header";
    Permissions = TableData "Sales Header" = rm,
                  TableData "Sales Line" = r;

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);
        SalesHeader.Copy(Rec);
        OnRunOnAfterCopy(Rec, SalesHeader);
        SalesHeader.SetHideValidationDialog(Rec.GetHideValidationDialog());
        Code();
        Rec := SalesHeader;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'There is nothing to release for the document of type %1 with the number %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SalesSetup: Record "Sales & Receivables Setup";
        InvtSetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        WhseSalesRelease: Codeunit "Whse.-Sales Release";
#pragma warning disable AA0074
        Text002: Label 'This document can only be released when the approval process is complete.';
        Text003: Label 'The approval process must be cancelled or completed to reopen this document.';
#pragma warning disable AA0470
        Text005: Label 'There are unpaid prepayment invoices that are related to the document of type %1 with the number %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        UnpostedPrepaymentAmountsErr: Label 'There are unposted prepayment amounts on the document of type %1 with the number %2.', Comment = '%1 - Document Type; %2 - Document No.';
        PreviewMode: Boolean;
        SkipCheckReleaseRestrictions: Boolean;
        SkipWhseRequestOperations: Boolean;

    local procedure "Code"() LinesWereModified: Boolean
    var
        SalesLine: Record "Sales Line";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        NotOnlyDropShipment: Boolean;
        PostingDate: Date;
        PrintPostedDocuments: Boolean;
        ShouldSetStatusPrepayment: Boolean;
        IsHandled: Boolean;
    begin
        if SalesHeader.Status = SalesHeader.Status::Released then
            exit;

        IsHandled := false;
        OnBeforeReleaseSalesDoc(SalesHeader, PreviewMode, IsHandled, SkipCheckReleaseRestrictions, SkipWhseRequestOperations);
        if IsHandled then
            exit;
        if not (PreviewMode or SkipCheckReleaseRestrictions) then
            SalesHeader.CheckSalesReleaseRestrictions();

        IsHandled := false;
        OnBeforeCheckCustomerCreated(SalesHeader, IsHandled);
        if not IsHandled then
            if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then
                if SalesHeader.CheckCustomerCreated(true) then
                    SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesHeader."No.")
                else
                    exit;

        TestSellToCustomerNo(SalesHeader);

        IsHandled := false;
        OnCodeOnAfterCheckCustomerCreated(SalesHeader, PreviewMode, IsHandled, LinesWereModified);
        if IsHandled then
            exit;

        CheckSalesLines(SalesLine, LinesWereModified);

        OnCodeOnAfterCheck(SalesHeader, SalesLine, LinesWereModified);

        SalesLine.SetRange("Drop Shipment", false);
        NotOnlyDropShipment := SalesLine.FindFirst();

        OnCodeOnCheckTracking(SalesHeader, SalesLine);

        SalesLine.Reset();

        IsHandled := false;
        OnBeforeCalcInvDiscount(SalesHeader, PreviewMode, LinesWereModified, SalesLine, IsHandled);
        if not IsHandled then begin
            SalesSetup.Get();
            if SalesSetup."Calc. Inv. Discount" then begin
                PostingDate := SalesHeader."Posting Date";
                PrintPostedDocuments := SalesHeader."Print Posted Documents";
                CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
                LinesWereModified := true;
                SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
                SalesHeader."Print Posted Documents" := PrintPostedDocuments;
                if PostingDate <> SalesHeader."Posting Date" then
                    SalesHeader.Validate("Posting Date", PostingDate);
            end;
        end;

        IsHandled := false;
        OnBeforeModifySalesDoc(SalesHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        ShouldSetStatusPrepayment := PrepaymentMgt.TestSalesPrepayment(SalesHeader) and (SalesHeader."Document Type" = SalesHeader."Document Type"::Order);
        OnCodeOnAfterCalcShouldSetStatusPrepayment(SalesHeader, PreviewMode, ShouldSetStatusPrepayment);
        if ShouldSetStatusPrepayment then begin
            SalesHeader.Status := SalesHeader.Status::"Pending Prepayment";
            SalesHeader.Modify(true);
            OnAfterReleaseSalesDoc(SalesHeader, PreviewMode, LinesWereModified, SkipWhseRequestOperations);
            exit;
        end;

        OnCodeOnBeforeSetStatusReleased(SalesHeader);
        SalesHeader.Status := SalesHeader.Status::Released;

        LinesWereModified := LinesWereModified or CalcAndUpdateVATOnLines(SalesHeader, SalesLine);

        OnAfterUpdateSalesDocLines(SalesHeader, LinesWereModified, PreviewMode);

        ReleaseATOs(SalesHeader);
        OnAfterReleaseATOs(SalesHeader, SalesLine, PreviewMode);

        SalesHeader.Modify(true);
        OnCodeOnAfterModifySalesDoc(SalesHeader, LinesWereModified);

        if NotOnlyDropShipment then
            if SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order"] then
                if not SkipWhseRequestOperations then
                    WhseSalesRelease.Release(SalesHeader);

        OnAfterReleaseSalesDoc(SalesHeader, PreviewMode, LinesWereModified, SkipWhseRequestOperations);
    end;

    local procedure CheckSalesLines(var SalesLine: Record "Sales Line"; var LinesWereModified: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLines(SalesHeader, SalesLine, IsHandled, LinesWereModified);
        if IsHandled then
            exit;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '>0');
        SalesLine.SetFilter(Quantity, '<>0');
        IsHandled := false;
        OnBeforeSalesLineFind(SalesLine, SalesHeader, LinesWereModified, IsHandled);
        if not IsHandled then
            if not SalesLine.Find('-') then
                Error(Text001, SalesHeader."Document Type", SalesHeader."No.");

        CheckMandatoryFields(SalesLine);
    end;

    local procedure CheckMandatoryFields(var SalesLine: Record "Sales Line")
    var
        Item: Record "Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMandatoryFields(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        InvtSetup.Get();
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                if SalesLine.IsInventoriableItem() then begin
                    if InvtSetup."Location Mandatory" then begin
                        IsHandled := false;
                        OnCodeOnBeforeSalesLineCheck(SalesLine, IsHandled);
                        if not IsHandled then
                            SalesLine.TestField("Location Code");
                    end;
                    SalesLine.TestField("Unit of Measure Code");
                end;
                if Item.Get(SalesLine."No.") then
                    if Item.IsVariantMandatory() then
                        SalesLine.TestField("Variant Code");
                OnCodeOnAfterSalesLineCheck(SalesLine, SalesHeader, Item);
            until SalesLine.Next() = 0;
        SalesLine.SetFilter(Type, '>0');
    end;

    local procedure TestSellToCustomerNo(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSellToCustomerNo(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.TestField("Sell-to Customer No.");
    end;

    /// <summary>
    /// Reopens a released or pending prepayment sales document to allow modifications.
    /// </summary>
    /// <param name="SalesHeader">The sales header to reopen.</param>
    procedure Reopen(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopenSalesDoc(SalesHeader, PreviewMode, IsHandled, SkipWhseRequestOperations);
        if IsHandled then
            exit;

        if SalesHeader.Status = SalesHeader.Status::Open then
            exit;
        SalesHeader.Status := SalesHeader.Status::Open;

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            ReopenATOs(SalesHeader);

        OnReopenOnBeforeSalesHeaderModify(SalesHeader);
        SalesHeader.Modify(true);
        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order"] then
            if not SkipWhseRequestOperations then
                WhseSalesRelease.Reopen(SalesHeader);

        OnAfterReopenSalesDoc(SalesHeader, PreviewMode, SkipWhseRequestOperations);
    end;

    /// <summary>
    /// Performs a manual release of a sales document with prepayment and approval validation.
    /// </summary>
    /// <param name="SalesHeader">The sales header to release.</param>
    procedure PerformManualRelease(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePerformManualReleaseProcedure(SalesHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        CheckPrepaymentsForManualRelease(SalesHeader);

        OnBeforeManualReleaseSalesDoc(SalesHeader, PreviewMode);
        PerformManualCheckAndRelease(SalesHeader);
        OnAfterManualReleaseSalesDoc(SalesHeader, PreviewMode);
    end;

    local procedure CheckPrepaymentsForManualRelease(var SalesHeader: Record "Sales Header")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPerformManualReleaseOnBeforeTestSalesPrepayment(SalesHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        if PrepaymentMgt.TestSalesPrepayment(SalesHeader) then
            Error(UnpostedPrepaymentAmountsErr, SalesHeader."Document Type", SalesHeader."No.");
    end;

    /// <summary>
    /// Validates prepayment status and pending approval before releasing the sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header to validate and release.</param>
    procedure PerformManualCheckAndRelease(var SalesHeader: Record "Sales Header")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePerformManualCheckAndRelease(SalesHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        if (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) and PrepaymentMgt.TestSalesPayment(SalesHeader) then begin
            if SalesHeader.TestStatusIsNotPendingPrepayment() then begin
                SalesHeader.Status := SalesHeader.Status::"Pending Prepayment";
                OnPerformManualCheckAndReleaseOnBeforeSalesHeaderModify(SalesHeader, PreviewMode);
                SalesHeader.Modify();
                Commit();
            end;
            Error(Text005, SalesHeader."Document Type", SalesHeader."No.");
        end;

        CheckSalesHeaderPendingApproval(SalesHeader);

        IsHandled := false;
        OnBeforePerformManualRelease(SalesHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);

        OnAfterPerformManualCheckAndRelease(SalesHeader, PreviewMode);
    end;

    local procedure CheckSalesHeaderPendingApproval(var SalesHeader: Record "Sales Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesHeaderPendingApproval(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if ApprovalsMgmt.IsSalesHeaderPendingApproval(SalesHeader) then
            Error(Text002);
    end;

    /// <summary>
    /// Performs a manual reopen of a sales document with approval status validation.
    /// </summary>
    /// <param name="SalesHeader">The sales header to reopen.</param>
    procedure PerformManualReopen(var SalesHeader: Record "Sales Header")
    begin
        CheckReopenStatus(SalesHeader);

        OnBeforeManualReOpenSalesDoc(SalesHeader, PreviewMode);
        Reopen(SalesHeader);
        OnAfterManualReOpenSalesDoc(SalesHeader, PreviewMode);
    end;

    local procedure CheckReopenStatus(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReopenStatus(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader.Status = SalesHeader.Status::"Pending Approval" then
            Error(Text003);
    end;

    local procedure ReleaseATOs(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReleaseATOs(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                if SalesLine.AsmToOrderExists(AsmHeader) then
                    CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AsmHeader);
            until SalesLine.Next() = 0;
    end;

    local procedure ReopenATOs(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        ReleaseAssemblyDocument: Codeunit "Release Assembly Document";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                if SalesLine.AsmToOrderExists(AsmHeader) then
                    ReleaseAssemblyDocument.Reopen(AsmHeader);
            until SalesLine.Next() = 0;
    end;

    /// <summary>
    /// Releases a sales header with optional preview mode for posting preview scenarios.
    /// </summary>
    /// <param name="SalesHdr">The sales header to release.</param>
    /// <param name="Preview">True to run in preview mode without committing changes.</param>
    /// <returns>True if lines were modified during release; otherwise, false.</returns>
    procedure ReleaseSalesHeader(var SalesHdr: Record "Sales Header"; Preview: Boolean) LinesWereModified: Boolean
    begin
        PreviewMode := Preview;
        SalesHeader.Copy(SalesHdr);
        OnReleaseSalesHeaderOnAfterCopySalesHeader(SalesHdr, SalesHeader);
        LinesWereModified := Code();
        SalesHdr := SalesHeader;
    end;

    /// <summary>
    /// Skips checking release restrictions during the release process.
    /// </summary>
    procedure SetSkipCheckReleaseRestrictions()
    begin
        SkipCheckReleaseRestrictions := true;
    end;

    /// <summary>
    /// Specifies whether to skip warehouse request operations during release and reopen.
    /// </summary>
    /// <param name="NewSkipWhseRequestOperations">True to skip warehouse request operations; false to process them.</param>
    procedure SetSkipWhseRequestOperations(NewSkipWhseRequestOperations: Boolean)
    begin
        SkipWhseRequestOperations := NewSkipWhseRequestOperations;
    end;

    /// <summary>
    /// Calculates and updates VAT amounts on all sales lines for the document.
    /// </summary>
    /// <param name="SalesHeader">The sales header for VAT calculation.</param>
    /// <param name="SalesLine">The sales lines to update with calculated VAT.</param>
    /// <returns>True if lines were modified; otherwise, false.</returns>
    procedure CalcAndUpdateVATOnLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line") LinesWereModified: Boolean
    var
        TempVATAmountLine0: Record "VAT Amount Line" temporary;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
    begin
        SalesLine.SetSalesHeader(SalesHeader);
        // 0 = General, 1 = Invoicing, 2 = Shipping
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, TempVATAmountLine0, false);
        SalesLine.CalcVATAmountLines(1, SalesHeader, SalesLine, TempVATAmountLine1, false);
        LinesWereModified :=
          SalesLine.UpdateVATOnLines(0, SalesHeader, SalesLine, TempVATAmountLine0) or
          SalesLine.UpdateVATOnLines(1, SalesHeader, SalesLine, TempVATAmountLine1);
    end;

    /// <summary>
    /// Raised before calculating the invoice discount for a sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header for which to calculate the discount.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="LinesWereModified">Indicates if sales lines were modified.</param>
    /// <param name="SalesLine">The sales lines for the document.</param>
    /// <param name="IsHandled">Set to true to skip the default discount calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscount(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var LinesWereModified: Boolean; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before manually releasing a sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header to release.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before testing the Sell-to Customer No. field on the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header to validate.</param>
    /// <param name="IsHandled">Set to true to skip the default validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSellToCustomerNo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before the OnRun trigger executes for the Release Sales Document codeunit.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before releasing a sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header to release.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip the default release logic.</param>
    /// <param name="SkipCheckReleaseRestrictions">Set to true to skip release restriction checks.</param>
    /// <param name="SkipWhseRequestOperations">Indicates if warehouse request operations should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean; var SkipCheckReleaseRestrictions: Boolean; SkipWhseRequestOperations: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after releasing a sales document.
    /// </summary>
    /// <param name="SalesHeader">The released sales header.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="LinesWereModified">Indicates if sales lines were modified during release.</param>
    /// <param name="SkipWhseRequestOperations">Indicates if warehouse request operations were skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var LinesWereModified: Boolean; SkipWhseRequestOperations: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after manually releasing a sales document.
    /// </summary>
    /// <param name="SalesHeader">The released sales header.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking if a sales header has pending approval.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    /// <param name="IsHandled">Set to true to skip the default approval check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesHeaderPendingApproval(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking sales lines during document release.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="SalesLine">The sales lines to check.</param>
    /// <param name="IsHandled">Set to true to skip the default sales line check.</param>
    /// <param name="LinesWereModified">Indicates if sales lines were modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var LinesWereModified: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before manually reopening a sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header to reopen.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReOpenSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before reopening a sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header to reopen.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip the default reopen logic.</param>
    /// <param name="SkipWhseRequestOperations">Indicates if warehouse request operations should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean; SkipWhseRequestOperations: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before modifying the sales document during the release process.
    /// </summary>
    /// <param name="SalesHeader">The sales header being modified.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip the default modification.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before performing the manual release of a sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header to release.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip the default manual release.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before the PerformManualRelease procedure executes.
    /// </summary>
    /// <param name="SalesHeader">The sales header to release.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip the default procedure execution.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualReleaseProcedure(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before finding sales lines during document release validation.
    /// </summary>
    /// <param name="SalesLine">The sales line record with filters applied.</param>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="LinesWereModified">Indicates if sales lines were modified.</param>
    /// <param name="IsHandled">Set to true to skip the default sales line finding.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineFind(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var LinesWereModified: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after reopening a sales document.
    /// </summary>
    /// <param name="SalesHeader">The reopened sales header.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="SkipWhseRequestOperations">Indicates if warehouse request operations were skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; SkipWhseRequestOperations: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after manually reopening a sales document.
    /// </summary>
    /// <param name="SalesHeader">The reopened sales header.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReOpenSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after performing the manual check and release of a sales document.
    /// </summary>
    /// <param name="SalesHeader">The released sales header.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPerformManualCheckAndRelease(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after releasing assemble-to-order documents for the sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="SalesLine">The sales lines with assemble-to-order items.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseATOs(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after updating sales document lines during the release process.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="LinesWereModified">Indicates if sales lines were modified.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesDocLines(var SalesHeader: Record "Sales Header"; var LinesWereModified: Boolean; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after checking the sales document during the release process.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="SalesLine">The sales lines that were checked.</param>
    /// <param name="LinesWereModified">Indicates if sales lines were modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheck(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var LinesWereModified: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after checking a sales line during mandatory field validation.
    /// </summary>
    /// <param name="SalesLine">The sales line that was checked.</param>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="Item">The item on the sales line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterSalesLineCheck(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var Item: Record "Item")
    begin
    end;

    /// <summary>
    /// Raised before checking a sales line during mandatory field validation.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <param name="IsHandled">Set to true to skip the default sales line check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeSalesLineCheck(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after calculating whether to set the status to Pending Prepayment.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="ShouldSetStatusPrepayment">Set to control whether the status should be set to Pending Prepayment.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcShouldSetStatusPrepayment(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var ShouldSetStatusPrepayment: Boolean)
    begin
    end;

    /// <summary>
    /// Raised when checking item tracking during the release process.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="SalesLine">The sales lines to check for item tracking.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnCheckTracking(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised before checking if a customer was created from a quote.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    /// <param name="IsHandled">Set to true to skip the default customer creation check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerCreated(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking the status when reopening a sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    /// <param name="IsHandled">Set to true to skip the default status check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReopenStatus(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before performing the manual check and release of a sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header to release.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip the default check and release logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualCheckAndRelease(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before modifying the sales header during the reopen process.
    /// </summary>
    /// <param name="SalesHeader">The sales header being reopened.</param>
    [IntegrationEvent(false, false)]
    local procedure OnReopenOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before testing for sales prepayment during manual release.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip the default prepayment test.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPerformManualReleaseOnBeforeTestSalesPrepayment(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before modifying the sales header during manual check and release.
    /// </summary>
    /// <param name="SalesHeader">The sales header being modified.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPerformManualCheckAndReleaseOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after checking if a customer was created from a quote.
    /// </summary>
    /// <param name="SalesHeader">The sales header that was checked.</param>
    /// <param name="PreviewMode">Indicates if running in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip further processing.</param>
    /// <param name="LinesWereModified">Indicates if sales lines were modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheckCustomerCreated(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean; var LinesWereModified: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after modifying the sales document during the release process.
    /// </summary>
    /// <param name="SalesHeader">The sales header that was modified.</param>
    /// <param name="LinesWereModified">Indicates if sales lines were modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterModifySalesDoc(var SalesHeader: Record "Sales Header"; var LinesWereModified: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking mandatory fields on sales lines.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="IsHandled">Set to true to skip the default mandatory field check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMandatoryFields(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting the sales document status to Released.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeSetStatusReleased(var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before releasing assemble-to-order documents for the sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header being released.</param>
    /// <param name="IsHandled">Set to true to skip the default ATO release logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseATOs(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after copying the sales header in the OnRun trigger.
    /// </summary>
    /// <param name="SalesHeader">The original sales header passed to OnRun.</param>
    /// <param name="SalesHeaderCopy">The copy of the sales header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCopy(var SalesHeader: Record "Sales Header"; var SalesHeaderCopy: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised after copying the sales header in the ReleaseSalesHeader procedure.
    /// </summary>
    /// <param name="SalesHeader">The original sales header passed to ReleaseSalesHeader.</param>
    /// <param name="SalesHeaderCopy">The copy of the sales header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnReleaseSalesHeaderOnAfterCopySalesHeader(var SalesHeader: Record "Sales Header"; var SalesHeaderCopy: Record "Sales Header")
    begin
    end;
}

