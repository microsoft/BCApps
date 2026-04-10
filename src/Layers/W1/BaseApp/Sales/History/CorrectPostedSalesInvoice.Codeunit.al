// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Request;
using System.Environment.Configuration;

/// <summary>
/// Handles the correction of posted sales invoices by creating a corrective sales credit memo.
/// </summary>
codeunit 1303 "Correct Posted Sales Invoice"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        UnapplyCostApplication(Rec."No.");

        OnBeforeCreateCorrectiveSalesCrMemo(Rec);
        CreateCopyDocument(Rec, SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);
        OnAfterCreateCorrectiveSalesCrMemo(Rec, SalesHeader, CancellingOnly);

        if SalesInvoiceLinesContainJob(Rec."No.") then
            CreateAndProcessJobPlanningLines(SalesHeader);

        SuppressCommit := not NoSeries.IsNoSeriesInDateOrder(SalesHeader."Posting No. Series");

        IsHandled := false;
        OnRunOnBeforePostCorrectiveSalesCrMemo(Rec, SalesHeader, IsHandled, SuppressCommit);
        if not IsHandled then begin
            if not SuppressCommit then
                Commit();
            CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
            SetTrackInfoForCancellation(Rec);
            UpdateSalesOrderLinesFromCancelledInvoice(Rec."No.");
        end;
        OnOnRunOnAfterUpdateSalesOrderLinesFromCancelledInvoice(Rec, SalesHeader);

        Commit();
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CancellingOnly: Boolean;
        SuppressCommit: Boolean;

        PostedInvoiceIsPaidCorrectErr: Label 'You cannot correct this posted sales invoice because it is fully or partially paid.\\To reverse a paid sales invoice, you must manually create a sales credit memo.';
        PostedInvoiceIsPaidCancelErr: Label 'You cannot cancel this posted sales invoice because it is fully or partially paid.\\To reverse a paid sales invoice, you must manually create a sales credit memo.';
        AlreadyCorrectedErr: Label 'You cannot correct this posted sales invoice because it has been canceled.';
        AlreadyCancelledErr: Label 'You cannot cancel this posted sales invoice because it has already been canceled.';
        CorrCorrectiveDocErr: Label 'You cannot correct this posted sales invoice because it represents a correction of a credit memo.';
        CancelCorrectiveDocErr: Label 'You cannot cancel this posted sales invoice because it represents a correction of a credit memo.';
        CustomerIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because customer %1 is blocked.', Comment = '%1 = Customer name';
        CustomerIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because customer %1 is blocked.', Comment = '%1 = Customer name';
        ItemIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        ItemIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        ItemVariantIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because item variant %1 for item %2 %3 is blocked.', Comment = '%1 - Item Variant Code, %2 = Item No. %3 = Item Description';
        ItemVariantIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because item variant %1 for item %2 %3 is blocked.', Comment = '%1 - Item Variant Code, %2 = Item No. %3 = Item Description';
        AccountIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        AccountIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        NoFreeInvoiceNoSeriesCorrectErr: Label 'You cannot correct this posted sales invoice because no unused invoice numbers are available. \\You must extend the range of the number series for sales invoices.';
        NoFreeInvoiceNoSeriesCancelErr: Label 'You cannot cancel this posted sales invoice because no unused invoice numbers are available. \\You must extend the range of the number series for sales invoices.';
        NoFreeCMSeriesCorrectErr: Label 'You cannot correct this posted sales invoice because no unused credit memo numbers are available. \\You must extend the range of the number series for credit memos.';
        NoFreeCMSeriesCancelErr: Label 'You cannot cancel this posted sales invoice because no unused credit memo numbers are available. \\You must extend the range of the number series for credit memos.';
        NoFreePostCMSeriesCorrectErr: Label 'You cannot correct this posted sales invoice because no unused posted credit memo numbers are available. \\You must extend the range of the number series for posted credit memos.';
        NoFreePostCMSeriesCancelErr: Label 'You cannot cancel this posted sales invoice because no unused posted credit memo numbers are available. \\You must extend the range of the number series for posted credit memos.';
        SalesLineFromOrderCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 is used on a sales order.', Comment = '%1 = Item no. %2 = Item description';
        ShippedQtyReturnedCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        ShippedQtyReturnedCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        UsedInJobCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 is used in a project.', Comment = '%1 = Item no. %2 = Item description.';
        UsedInJobCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 is used in a project.', Comment = '%1 = Item no. %2 = Item description.';
        PostingNotAllowedCorrectErr: Label 'You cannot correct this posted sales invoice because it was posted in a posting period that is closed.';
        PostingNotAllowedCancelErr: Label 'You cannot cancel this posted sales invoice because it was posted in a posting period that is closed.';
        LineTypeNotAllowedCorrectErr: Label 'You cannot correct this posted sales invoice because the sales invoice line for %1 %2 is of type %3, which is not allowed on a simplified sales invoice.', Comment = '%1 = Item no. %2 = Item description %3 = Item type.';
        LineTypeNotAllowedCancelErr: Label 'You cannot cancel this posted sales invoice because the sales invoice line for %1 %2 is of type %3, which is not allowed on a simplified sales invoice.', Comment = '%1 = Item no. %2 = Item description %3 = Item type.';
        InvalidDimCodeCorrectErr: Label 'You cannot correct this posted sales invoice because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being canceled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCodeCancelErr: Label 'You cannot cancel this posted sales invoice because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being canceled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCombinationCorrectErr: Label 'You cannot correct this posted sales invoice because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombinationCancelErr: Label 'You cannot cancel this posted sales invoice because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombHeaderCorrectErr: Label 'You cannot correct this posted sales invoice because the combination of dimensions on the invoice is blocked.';
        InvalidDimCombHeaderCancelErr: Label 'You cannot cancel this posted sales invoice because the combination of dimensions on the invoice is blocked.';
        ExternalDocCorrectErr: Label 'You cannot correct this posted sales invoice because the external document number is required on the invoice.';
        ExternalDocCancelErr: Label 'You cannot cancel this posted sales invoice because the external document number is required on the invoice.';
        InventoryPostClosedCorrectErr: Label 'You cannot correct this posted sales invoice because the posting inventory period is already closed.';
        InventoryPostClosedCancelErr: Label 'You cannot cancel this posted sales invoice because the posting inventory period is already closed.';
        FixedAssetNotPossibleToCreateCreditMemoErr: Label 'You cannot cancel this posted sales invoice because it contains lines of type Fixed Asset.\\Use the Cancel Entries function in the FA Ledger Entries window instead.';
#pragma warning disable AA0470
        PostingCreditMemoFailedOpenPostedCMQst: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is posted. Do you want to open the posted credit memo?';
        PostingCreditMemoFailedOpenCMQst: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is created but not posted. Do you want to open the credit memo?';
        CreatingCreditMemoFailedNothingCreatedErr: Label 'Canceling the invoice failed because of the following error: \\%1.';
#pragma warning restore AA0470
        WrongDocumentTypeForCopyDocumentErr: Label 'You cannot correct or cancel this type of document.';
        CheckPrepaymentErr: Label 'You cannot correct or cancel a posted sales prepayment invoice.\\Open the related sales order and choose the Post Prepayment Credit Memo.';
        InvoicePartiallyPaidMsg: Label 'Invoice %1 is partially paid or credited. The corrective credit memo may not be fully closed by the invoice.', Comment = '%1 - invoice no.';
        InvoiceClosedMsg: Label 'Invoice %1 is closed. The corrective credit memo will not be applied to the invoice.', Comment = '%1 - invoice no.';
        SkipLbl: Label 'Skip';
        CreateCreditMemoLbl: Label 'Create credit memo anyway';
        ShowEntriesLbl: Label 'Show applied entries';
        WMSLocationCancelCorrectErr: Label 'You cannot cancel or correct this posted sales invoice because Warehouse Receive is required for Line No. = %1.', Comment = '%1 - line number';
        DropShipmentDocumentExistsErr: Label 'You cannot use the cancel or correct functionality because the invoice line is associated with purchase order %1 due to Drop Shipment.', Comment = '%1 - Purchase Order No.';
        CreateCreditMemoQst: Label 'The invoice was posted from an order. A Sales Credit memo will be created which you complete and post manually. The quantities will be corrected in the existing Sales Order.\ \Do you want to continue?';

    /// <summary>
    /// Cancels the posted sales invoice by creating and posting a corrective credit memo.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Specifies the posted sales invoice to cancel.</param>
    /// <returns>True if the invoice was successfully canceled, otherwise false.</returns>
    procedure CancelPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        CancellingOnly := true;
        exit(CreateCreditMemo(SalesInvoiceHeader));
    end;

    local procedure CreateCreditMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
    begin
        TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, CancellingOnly);
        if not CODEUNIT.Run(CODEUNIT::"Correct Posted Sales Invoice", SalesInvoiceHeader) then begin
            SalesCrMemoHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
            if SalesCrMemoHeader.FindFirst() then begin
                if Confirm(StrSubstNo(PostingCreditMemoFailedOpenPostedCMQst, GetLastErrorText)) then begin
                    IsHandled := false;
                    OnCreateCreditMemoOnBeforePostedPageRun(SalesCrMemoHeader, IsHandled);
                    if not IsHandled then
                        PageManagement.PageRun(SalesCrMemoHeader);
                end;
            end else begin
                SalesHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
                if SalesHeader.FindFirst() then begin
                    if Confirm(StrSubstNo(PostingCreditMemoFailedOpenCMQst, GetLastErrorText)) then begin
                        IsHandled := false;
                        OnCreateCreditMemoOnBeforePageRun(SalesHeader, IsHandled);
                        if not IsHandled then
                            PAGE.Run(PAGE::"Sales Credit Memo", SalesHeader);
                    end;
                end else
                    Error(CreatingCreditMemoFailedNothingCreatedErr, GetLastErrorText);
            end;
            exit(false);
        end;
        exit(true);
    end;

    local procedure CreateCopyDocument(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SkipCopyFromDescription: Boolean)
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        Clear(SalesHeader);
        SalesHeader."No." := '';
        SalesHeader."Document Type" := DocumentType;
        SalesHeader.SetAllowSelectNoSeries();
        OnBeforeSalesHeaderInsert(SalesHeader, SalesInvoiceHeader, CancellingOnly);
        SalesHeader.Insert(true);

        case DocumentType of
            SalesHeader."Document Type"::"Credit Memo":
                CopyDocMgt.SetPropertiesForCorrectiveCreditMemo(true);
            SalesHeader."Document Type"::Invoice:
                CopyDocMgt.SetPropertiesForInvoiceCorrection(SkipCopyFromDescription);
            else
                Error(WrongDocumentTypeForCopyDocumentErr);
        end;

        CopyDocMgt.CopySalesDocForInvoiceCancelling(SalesInvoiceHeader."No.", SalesHeader);
        OnAfterCreateCopyDocument(SalesHeader, SalesInvoiceHeader);
    end;

    /// <summary>
    /// Creates a credit memo document as a copy of the posted sales invoice without posting it.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Specifies the posted sales invoice to copy from.</param>
    /// <param name="SalesHeader">Returns the created sales credit memo header.</param>
    /// <returns>True if the credit memo was successfully created, otherwise false.</returns>
    procedure CreateCreditMemoCopyDocument(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"): Boolean
    var
        SalesHdr: Record "Sales Header";
    begin
        OnBeforeCreateCreditMemoCopyDocument(SalesInvoiceHeader);
        TestNoFixedAssetInSalesInvoice(SalesInvoiceHeader);
        TestNotSalesPrepaymentlInvoice(SalesInvoiceHeader);
        TestIfDropShipmentDocument(SalesInvoiceHeader);
        if not SalesInvoiceHeader.IsFullyOpen() then begin
            ShowInvoiceAppliedNotification(SalesInvoiceHeader);
            exit(false);
        end;
        SalesHdr.SetRange("Document Type", SalesHdr."Document Type"::Order);
        SalesHdr.SetRange("No.", SalesInvoiceHeader."Order No.");
        if not SalesHdr.IsEmpty then
            if not Confirm(CreateCreditMemoQst) then
                exit(false);

        CreateCopyDocument(SalesInvoiceHeader, SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);

        if SalesInvoiceLinesContainJob(SalesInvoiceHeader."No.") then
            CreateAndProcessJobPlanningLines(SalesHeader);

        exit(true);
    end;

    /// <summary>
    /// Creates a corrective credit memo from a notification action triggered on a posted sales invoice.
    /// </summary>
    /// <param name="InvoiceNotification">Specifies the notification containing the invoice number to correct.</param>
    procedure CreateCorrectiveCreditMemo(var InvoiceNotification: Notification)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IsHandled: Boolean;
    begin
        SalesInvoiceHeader.Get(InvoiceNotification.GetData(SalesInvoiceHeader.FieldName("No.")));
        InvoiceNotification.Recall();

        CreateCopyDocument(SalesInvoiceHeader, SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);

        if SalesInvoiceLinesContainJob(SalesInvoiceHeader."No.") then
            CreateAndProcessJobPlanningLines(SalesHeader);

        IsHandled := false;
        OnCreateCorrectiveCreditMemoOnBeforePageRun(SalesHeader, IsHandled);
        if not IsHandled then
            PAGE.Run(PAGE::"Sales Credit Memo", SalesHeader);
    end;

    /// <summary>
    /// Shows the applied customer ledger entries for the posted sales invoice referenced in the notification.
    /// </summary>
    /// <param name="InvoiceNotification">Specifies the notification containing the invoice number.</param>
    procedure ShowAppliedEntries(var InvoiceNotification: Notification)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNotification.GetData(SalesInvoiceHeader.FieldName("No.")));
        CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.");
        PAGE.RunModal(PAGE::"Applied Customer Entries", CustLedgerEntry);
    end;

    /// <summary>
    /// Dismisses the corrective credit memo notification without taking any action.
    /// </summary>
    /// <param name="InvoiceNotification">Specifies the notification to dismiss.</param>
    procedure SkipCorrectiveCreditMemo(var InvoiceNotification: Notification)
    begin
        InvoiceNotification.Recall();
    end;

    local procedure CreateAndProcessJobPlanningLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAndProcessJobPlanningLines(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter("Job Contract Entry No.", '<>0');
        if SalesLine.FindSet() then
            repeat
                SalesLine."Job Contract Entry No." := CreateJobPlanningLine(SalesHeader, SalesLine);
                SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    local procedure CreateJobPlanningLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"): Integer
    var
        FromJobPlanningLine: Record "Job Planning Line";
        ToJobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        FromJobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        FromJobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        FromJobPlanningLine.FindFirst();

        ToJobPlanningLine.InitFromJobPlanningLine(FromJobPlanningLine, -SalesLine.Quantity);
        OnCreateJobPlanningLineOnAfterInitFromJobPlanningLine(ToJobPlanningLine, FromJobPlanningLine, SalesLine);
        JobPlanningLineInvoice.InitFromJobPlanningLine(ToJobPlanningLine);
        JobPlanningLineInvoice.InitFromSales(SalesHeader, SalesHeader."Posting Date", SalesLine."Line No.");
        JobPlanningLineInvoice.Insert();

        ToJobPlanningLine.UpdateQtyToTransfer();
        ToJobPlanningLine.Insert();

        exit(ToJobPlanningLine."Job Contract Entry No.");
    end;

    /// <summary>
    /// Cancels the posted sales invoice and creates a new sales invoice as a copy for correction.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Specifies the posted sales invoice to cancel.</param>
    /// <param name="SalesHeader">Returns the newly created sales invoice header for correction.</param>
    procedure CancelPostedInvoiceCreateNewInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
        CancellingOnly := false;

        if CreateCreditMemo(SalesInvoiceHeader) then begin
            CreateCopyDocument(SalesInvoiceHeader, SalesHeader, SalesHeader."Document Type"::Invoice, true);
            OnAfterCreateCorrSalesInvoice(SalesHeader, SalesInvoiceHeader);
            Commit();
        end;
    end;

    /// <summary>
    /// Tests whether the posted sales invoice can be corrected or canceled by checking payment status, customer blocks, and other conditions.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Specifies the posted sales invoice to validate.</param>
    /// <param name="Cancelling">Specifies whether the operation is a cancellation or correction.</param>
    procedure TestCorrectInvoiceIsAllowed(var SalesInvoiceHeader: Record "Sales Invoice Header"; Cancelling: Boolean)
    begin
        CancellingOnly := Cancelling;

        TestIfPostingIsAllowed(SalesInvoiceHeader);
        TestIfInvoiceIsCorrectedOnce(SalesInvoiceHeader);
        TestIfInvoiceIsNotCorrectiveDoc(SalesInvoiceHeader);
        TestIfInvoiceIsPaid(SalesInvoiceHeader);
        TestIfCustomerIsBlocked(SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");
        TestIfCustomerIsBlocked(SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.");
        TestIfJobPostingIsAllowed(SalesInvoiceHeader."No.");
        TestCustomerDimension(SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.");
        TestDimensionOnHeader(SalesInvoiceHeader);
        TestSalesLines(SalesInvoiceHeader);
        TestIfAnyFreeNumberSeries(SalesInvoiceHeader);
        TestExternalDocument(SalesInvoiceHeader);
        TestInventoryPostingClosed(SalesInvoiceHeader);
        TestNotSalesPrepaymentlInvoice(SalesInvoiceHeader);
        TestIfDropShipmentDocument(SalesInvoiceHeader);

        OnAfterTestCorrectInvoiceIsAllowed(SalesInvoiceHeader, Cancelling);
    end;

    local procedure ShowInvoiceAppliedNotification(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        InvoiceNotification: Notification;
        NotificationText: Text;
    begin
        InvoiceNotification.Id := CreateGuid();
        InvoiceNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        InvoiceNotification.SetData(SalesInvoiceHeader.FieldName("No."), SalesInvoiceHeader."No.");
        SalesInvoiceHeader.CalcFields(Closed);
        if SalesInvoiceHeader.Closed then
            NotificationText := StrSubstNo(InvoiceClosedMsg, SalesInvoiceHeader."No.")
        else
            NotificationText := StrSubstNo(InvoicePartiallyPaidMsg, SalesInvoiceHeader."No.");
        InvoiceNotification.Message(NotificationText);
        InvoiceNotification.AddAction(ShowEntriesLbl, CODEUNIT::"Correct Posted Sales Invoice", 'ShowAppliedEntries');
        InvoiceNotification.AddAction(SkipLbl, CODEUNIT::"Correct Posted Sales Invoice", 'SkipCorrectiveCreditMemo');
        InvoiceNotification.AddAction(CreateCreditMemoLbl, CODEUNIT::"Correct Posted Sales Invoice", 'CreateCorrectiveCreditMemo');
        NotificationLifecycleMgt.SendNotification(InvoiceNotification, SalesInvoiceHeader.RecordId);
    end;

    local procedure SetTrackInfoForCancellation(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetTrackInfoForCancellation(SalesInvoiceHeader, IsHandled);
        if IsHandled then
            exit;

        SalesCrMemoHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        if SalesCrMemoHeader.FindLast() then
            CancelledDocument.InsertSalesInvToCrMemoCancelledDocument(SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");
    end;

    local procedure SalesInvoiceLinesContainJob(InvoiceNo: Code[20]): Boolean
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        SalesInvoiceLine.SetFilter("Job No.", '<>%1', '');
        exit(not SalesInvoiceLine.IsEmpty);
    end;

    local procedure TestDimensionOnHeader(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if not DimensionManagement.CheckDimIDComb(SalesInvoiceHeader."Dimension Set ID") then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::DimCombHeaderErr, SalesInvoiceHeader);
    end;

    local procedure TestIfCustomerIsBlocked(SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        if Customer.Blocked in [Customer.Blocked::Invoice, Customer.Blocked::All] then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::CustomerBlocked, SalesInvoiceHeader);
    end;

    local procedure TestCustomerDimension(SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        Customer.Get(CustNo);
        TableID[1] := DATABASE::Customer;
        No[1] := Customer."No.";
        if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesInvoiceHeader."Dimension Set ID") then
            ErrorHelperAccount(Enum::"Correct Sales Inv. Error Type"::DimErr, Customer."No.", Customer.TableCaption(), Customer."No.", Customer.Name);
    end;

    local procedure TestSalesLines(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        DimensionManagement: Codeunit DimensionManagement;
        ShippedQtyNoReturned: Decimal;
        RevUnitCostLCY: Decimal;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        TestNoFixedAssetInSalesLines(SalesInvoiceLine);
        if SalesInvoiceLine.Find('-') then
            repeat
                if not IsCommentLine(SalesInvoiceLine) then begin
                    TestSalesLineType(SalesInvoiceLine);

                    if SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item then begin
                        if (SalesInvoiceLine.Quantity > 0) and (SalesInvoiceLine."Job No." = '') and
                           WasNotCancelled(SalesInvoiceHeader."No.")
                        then begin
                            SalesInvoiceLine.CalcShippedSaleNotReturned(ShippedQtyNoReturned, RevUnitCostLCY, false);
                            OnTestSalesLinesOnAfterCalcShippedQtyNoReturned(SalesInvoiceLine, ShippedQtyNoReturned);
                            if SalesInvoiceLine.Quantity <> ShippedQtyNoReturned then
                                ErrorHelperLine(Enum::"Correct Sales Inv. Error Type"::ItemIsReturned, SalesInvoiceLine);
                        end;

                        Item.Get(SalesInvoiceLine."No.");

                        if Item.Blocked then
                            ErrorHelperLine(Enum::"Correct Sales Inv. Error Type"::ItemBlocked, SalesInvoiceLine);
                        if SalesInvoiceLine."Variant Code" <> '' then begin
                            ItemVariant.SetLoadFields(Blocked);
                            if ItemVariant.Get(SalesInvoiceLine."No.", SalesInvoiceLine."Variant Code") and ItemVariant.Blocked then
                                ErrorHelperLine("Correct Sales Inv. Error Type"::ItemVariantBlocked, SalesInvoiceLine);
                        end;

                        if SalesInvoiceLine.Quantity <> 0 then begin
                            TableID[1] := DATABASE::Item;
                            No[1] := SalesInvoiceLine."No.";
                            if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesInvoiceLine."Dimension Set ID") then
                                ErrorHelperAccount(Enum::"Correct Sales Inv. Error Type"::DimErr, No[1], Item.TableCaption(), Item."No.", Item.Description);
                        end;

                        if Item.Type = Item.Type::Inventory then
                            TestInventoryPostingSetup(SalesInvoiceLine);
                    end;

                    TestGenPostingSetup(SalesInvoiceLine);
                    TestCustomerPostingGroup(SalesInvoiceHeader);
                    TestVATPostingSetup(SalesInvoiceLine);
                    TestWMSLocation(SalesInvoiceLine);

                    if not DimensionManagement.CheckDimIDComb(SalesInvoiceLine."Dimension Set ID") then
                        ErrorHelperLine(Enum::"Correct Sales Inv. Error Type"::DimCombErr, SalesInvoiceLine);
                end;
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure TestGLAccount(AccountNo: Code[20]; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then
            ErrorHelperAccount(Enum::"Correct Sales Inv. Error Type"::AccountBlocked, AccountNo, GLAccount.TableCaption(), '', '');
        TableID[1] := DATABASE::"G/L Account";
        No[1] := AccountNo;

        if SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item then begin
            Item.Get(SalesInvoiceLine."No.");
            if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesInvoiceLine."Dimension Set ID") then
                ErrorHelperAccount(Enum::"Correct Sales Inv. Error Type"::DimErr, AccountNo, GLAccount.TableCaption(), Item."No.", Item.Description);
        end;
    end;

    local procedure TestGLAccount(AccountNo: Code[20]; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GLAccount: Record "G/L Account";
        CustomerPostingGroup: Record "Customer Posting Group";
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then
            ErrorHelperAccount(Enum::"Correct Sales Inv. Error Type"::AccountBlocked, AccountNo, GLAccount.TableCaption(), '', '');
        TableID[1] := DATABASE::"G/L Account";
        No[1] := AccountNo;

        if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesInvoiceHeader."Dimension Set ID") then
            ErrorHelperAccount(
                Enum::"Correct Sales Inv. Error Type"::DimErr, AccountNo, GLAccount.TableCaption(),
                SalesInvoiceHeader."Customer Posting Group", CustomerPostingGroup.TableCaption());
    end;

    local procedure TestIfInvoiceIsPaid(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestIfInvoiceIsPaid(SalesInvoiceHeader, IsHandled);
        if IsHandled then
            exit;

        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        SalesInvoiceHeader.CalcFields("Remaining Amount");
        if SalesInvoiceHeader."Amount Including VAT" <> SalesInvoiceHeader."Remaining Amount" then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::IsPaid, SalesInvoiceHeader);
    end;

    local procedure TestIfInvoiceIsCorrectedOnce(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CancelledDocument: Record "Cancelled Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestIfInvoiceIsCorrectedOnce(SalesInvoiceHeader, IsHandled);
        if IsHandled then
            exit;

        if CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No.") then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::IsCorrected, SalesInvoiceHeader);
    end;

    local procedure TestIfInvoiceIsNotCorrectiveDoc(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if CancelledDocument.FindSalesCorrectiveInvoice(SalesInvoiceHeader."No.") then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::IsCorrective, SalesInvoiceHeader);
    end;

    local procedure TestIfPostingIsAllowed(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(SalesInvoiceHeader."Posting Date") then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::PostingNotAllowed, SalesInvoiceHeader);
    end;

    local procedure TestIfAnyFreeNumberSeries(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PostingDate: Date;
        PostingNoSeries: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestIfAnyFreeNumberSeries(SalesInvoiceHeader, IsHandled);
        if IsHandled then
            exit;

        PostingDate := WorkDate();
        SalesReceivablesSetup.Get();

        if not TryPeekNextNo(SalesReceivablesSetup."Credit Memo Nos.", PostingDate) then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::SerieNumCM, SalesInvoiceHeader);

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            GenJournalTemplate.Get(SalesReceivablesSetup."S. Cr. Memo Template Name");
            PostingNoSeries := GenJournalTemplate."Posting No. Series";
        end else
            PostingNoSeries := SalesReceivablesSetup."Posted Credit Memo Nos.";
        if not TryPeekNextNo(PostingNoSeries, PostingDate) then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::SerieNumPostCM, SalesInvoiceHeader);

        if (not CancellingOnly) and (not TryPeekNextNo(SalesReceivablesSetup."Invoice Nos.", PostingDate)) then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::SerieNumInv, SalesInvoiceHeader);
    end;

    [TryFunction]
    local procedure TryPeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date)
    var
        NoSeries: Codeunit "No. Series";
    begin
        if NoSeries.PeekNextNo(NoSeriesCode, UsageDate) = '' then
            Error('');
    end;

    local procedure TestIfJobPostingIsAllowed(SalesInvoiceNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        Job: Record Job;
    begin
        SalesInvoiceLine.SetFilter("Document No.", SalesInvoiceNo);
        SalesInvoiceLine.SetFilter("Job No.", '<>%1', '');
        if SalesInvoiceLine.FindSet() then
            repeat
                Job.Get(SalesInvoiceLine."Job No.");
                Job.TestBlocked();
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure TestExternalDocument(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if (SalesInvoiceHeader."External Document No." = '') and SalesReceivablesSetup."Ext. Doc. No. Mandatory" then
            ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::ExtDocErr, SalesInvoiceHeader);
    end;

    local procedure TestInventoryPostingClosed(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        InventoryPeriod: Record "Inventory Period";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentHasLineWithRestrictedType: Boolean;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        SalesInvoiceLine.SetFilter(Type, '%1|%2', SalesInvoiceLine.Type::Item, SalesInvoiceLine.Type::"Charge (Item)");
        DocumentHasLineWithRestrictedType := not SalesInvoiceLine.IsEmpty();

        if DocumentHasLineWithRestrictedType then begin
            InventoryPeriod.SetRange(Closed, true);
            InventoryPeriod.SetFilter("Ending Date", '>=%1', SalesInvoiceHeader."Posting Date");
            if not InventoryPeriod.IsEmpty() then
                ErrorHelperHeader(Enum::"Correct Sales Inv. Error Type"::InventoryPostClosed, SalesInvoiceHeader);
        end;
    end;

    local procedure TestSalesLineType(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        IsHandled: Boolean;
    begin
        if SalesInvoiceLine.IsCancellationSupported() then
            exit;

        if (SalesInvoiceLine."Job No." <> '') and (SalesInvoiceLine.Type = SalesInvoiceLine.Type::Resource) then
            exit;

        IsHandled := false;
        OnAfterTestSalesLineType(SalesInvoiceLine, IsHandled);
        if not IsHandled then
            ErrorHelperLine(Enum::"Correct Sales Inv. Error Type"::WrongItemType, SalesInvoiceLine);
    end;

    local procedure TestGenPostingSetup(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        IsHandled: Boolean;
    begin
        if SalesInvoiceLine."VAT Calculation Type" = SalesInvoiceLine."VAT Calculation Type"::"Sales Tax" then
            exit;

        GenPostingSetup.Get(SalesInvoiceLine."Gen. Bus. Posting Group", SalesInvoiceLine."Gen. Prod. Posting Group");
        if SalesInvoiceLine.Type <> SalesInvoiceLine.Type::"G/L Account" then begin
            GenPostingSetup.TestField("Sales Account");
            TestGLAccount(GenPostingSetup."Sales Account", SalesInvoiceLine);
            GenPostingSetup.TestField("Sales Credit Memo Account");
            TestGLAccount(GenPostingSetup."Sales Credit Memo Account", SalesInvoiceLine);
        end;
        if HasLineDiscountSetup(SalesInvoiceLine) then
            if GenPostingSetup."Sales Line Disc. Account" <> '' then
                TestGLAccount(GenPostingSetup."Sales Line Disc. Account", SalesInvoiceLine);

        IsHandled := false;
        OnTestGenPostingSetupOnBeforeTestTypeItem(SalesInvoiceLine, IsHandled);
        if not IsHandled then
            if SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item then begin
                Item.Get(SalesInvoiceLine."No.");
                if Item.IsInventoriableType() then
                    TestGLAccount(GenPostingSetup.GetCOGSAccount(), SalesInvoiceLine);
            end;
    end;

    local procedure TestCustomerPostingGroup(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(SalesInvoiceHeader."Customer Posting Group");
        CustomerPostingGroup.TestField("Receivables Account");
        TestGLAccount(CustomerPostingGroup."Receivables Account", SalesInvoiceHeader);
    end;

    local procedure TestVATPostingSetup(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestVATPostingSetup(SalesInvoiceLine, IsHandled);
        if IsHandled then
            exit;

        VATPostingSetup.Get(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group");
        if VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Sales Tax" then begin
            VATPostingSetup.TestField("Sales VAT Account");
            TestGLAccount(VATPostingSetup."Sales VAT Account", SalesInvoiceLine);
        end;
    end;

    local procedure TestInventoryPostingSetup(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestInventoryPostingSetup(SalesInvoiceLine, IsHandled);
        if IsHandled then
            exit;

        InventoryPostingSetup.Get(SalesInvoiceLine."Location Code", SalesInvoiceLine."Posting Group");
        InventoryPostingSetup.TestField("Inventory Account");
        TestGLAccount(InventoryPostingSetup."Inventory Account", SalesInvoiceLine);
    end;

    local procedure TestNoFixedAssetInSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        TestNoFixedAssetInSalesLines(SalesInvoiceLine);
    end;

    local procedure TestNoFixedAssetInSalesLines(var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.Copy(SalesInvoiceLine);
        SalesInvLine.SetRange(Type, SalesInvLine.Type::"Fixed Asset");
        if not SalesInvLine.IsEmpty() then
            Error(FixedAssetNotPossibleToCreateCreditMemoErr);
    end;

    local procedure TestNotSalesPrepaymentlInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if SalesInvoiceHeader."Prepayment Invoice" then
            Error(CheckPrepaymentErr);
    end;

    local procedure IsCommentLine(SalesInvoiceLine: Record "Sales Invoice Line") Result: Boolean
    begin
        Result := (SalesInvoiceLine.Type = SalesInvoiceLine.Type::" ") or (SalesInvoiceLine."No." = '');
        OnAfterIsCommentLine(SalesInvoiceLine, Result);
    end;

    local procedure WasNotCancelled(InvNo: Code[20]): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeWasNotCancelled(InvNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SalesCrMemoHeader.SetRange("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
        SalesCrMemoHeader.SetRange("Applies-to Doc. No.", InvNo);
        exit(SalesCrMemoHeader.IsEmpty);
    end;

    local procedure UnapplyCostApplication(InvNo: Code[20])
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempItemApplicationEntry: Record "Item Application Entry" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUnapplyCostApplication(InvNo, IsHandled);
        if IsHandled then
            exit;

        FindItemLedgEntries(TempItemLedgEntry, InvNo);
        if FindAppliedInbndEntries(TempItemApplicationEntry, TempItemLedgEntry) then begin
            repeat
                ItemJnlPostLine.UnApply(TempItemApplicationEntry);
            until TempItemApplicationEntry.Next() = 0;
            ItemJnlPostLine.RedoApplications();
        end;
    end;

    /// <summary>
    /// Finds all item ledger entries associated with the specified posted sales invoice.
    /// </summary>
    /// <param name="ItemLedgEntry">Returns the item ledger entries found for the invoice.</param>
    /// <param name="InvNo">Specifies the posted sales invoice number to search for.</param>
    procedure FindItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry"; InvNo: Code[20])
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.SetRange("Document No.", InvNo);
        SalesInvLine.SetRange(Type, SalesInvLine.Type::Item);
        if SalesInvLine.FindSet() then
            repeat
                SalesInvLine.GetItemLedgEntries(ItemLedgEntry, false);
            until SalesInvLine.Next() = 0;
    end;

    local procedure FindAppliedInbndEntries(var TempItemApplicationEntry: Record "Item Application Entry" temporary; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        TempItemApplicationEntry.Reset();
        TempItemApplicationEntry.DeleteAll();
        if ItemLedgEntry.FindSet() then
            repeat
                if ItemApplicationEntry.AppliedInbndEntryExists(ItemLedgEntry."Entry No.", true) then
                    repeat
                        TempItemApplicationEntry := ItemApplicationEntry;
                        if not TempItemApplicationEntry.Find() then
                            TempItemApplicationEntry.Insert();
                    until ItemApplicationEntry.Next() = 0;
            until ItemLedgEntry.Next() = 0;
        exit(TempItemApplicationEntry.FindSet());
    end;

    /// <summary>
    /// Raises an error message based on the header error type encountered during invoice correction validation.
    /// </summary>
    /// <param name="HeaderErrorType">Specifies the type of error that occurred.</param>
    /// <param name="SalesInvoiceHeader">Specifies the posted sales invoice that caused the error.</param>
    procedure ErrorHelperHeader(HeaderErrorType: Enum "Correct Sales Inv. Error Type"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
    begin
        OnBeforeErrorHelperHeader(HeaderErrorType, SalesInvoiceHeader, CancellingOnly);

        if CancellingOnly then
            case HeaderErrorType of
                Enum::"Correct Sales Inv. Error Type"::IsPaid:
                    Error(PostedInvoiceIsPaidCancelErr);
                Enum::"Correct Sales Inv. Error Type"::CustomerBlocked:
                    begin
                        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
                        Error(CustomerIsBlockedCancelErr, Customer.Name);
                    end;
                Enum::"Correct Sales Inv. Error Type"::IsCorrected:
                    Error(AlreadyCancelledErr);
                Enum::"Correct Sales Inv. Error Type"::IsCorrective:
                    Error(CancelCorrectiveDocErr);
                Enum::"Correct Sales Inv. Error Type"::SerieNumInv:
                    Error(NoFreeInvoiceNoSeriesCancelErr);
                Enum::"Correct Sales Inv. Error Type"::SerieNumCM:
                    Error(NoFreeCMSeriesCancelErr);
                Enum::"Correct Sales Inv. Error Type"::SerieNumPostCM:
                    Error(NoFreePostCMSeriesCancelErr);
                Enum::"Correct Sales Inv. Error Type"::PostingNotAllowed:
                    Error(PostingNotAllowedCancelErr);
                Enum::"Correct Sales Inv. Error Type"::ExtDocErr:
                    Error(ExternalDocCancelErr);
                Enum::"Correct Sales Inv. Error Type"::InventoryPostClosed:
                    Error(InventoryPostClosedCancelErr);
                Enum::"Correct Sales Inv. Error Type"::DimCombHeaderErr:
                    Error(InvalidDimCombHeaderCancelErr);
            end
        else
            case HeaderErrorType of
                Enum::"Correct Sales Inv. Error Type"::IsPaid:
                    Error(PostedInvoiceIsPaidCorrectErr);
                Enum::"Correct Sales Inv. Error Type"::CustomerBlocked:
                    begin
                        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
                        Error(CustomerIsBlockedCorrectErr, Customer.Name);
                    end;
                Enum::"Correct Sales Inv. Error Type"::IsCorrected:
                    Error(AlreadyCorrectedErr);
                Enum::"Correct Sales Inv. Error Type"::IsCorrective:
                    Error(CorrCorrectiveDocErr);
                Enum::"Correct Sales Inv. Error Type"::SerieNumInv:
                    Error(NoFreeInvoiceNoSeriesCorrectErr);
                Enum::"Correct Sales Inv. Error Type"::SerieNumPostCM:
                    Error(NoFreePostCMSeriesCorrectErr);
                Enum::"Correct Sales Inv. Error Type"::SerieNumCM:
                    Error(NoFreeCMSeriesCorrectErr);
                Enum::"Correct Sales Inv. Error Type"::PostingNotAllowed:
                    Error(PostingNotAllowedCorrectErr);
                Enum::"Correct Sales Inv. Error Type"::ExtDocErr:
                    Error(ExternalDocCorrectErr);
                Enum::"Correct Sales Inv. Error Type"::InventoryPostClosed:
                    Error(InventoryPostClosedCorrectErr);
                Enum::"Correct Sales Inv. Error Type"::DimCombHeaderErr:
                    Error(InvalidDimCombHeaderCorrectErr);
            end;
    end;

    local procedure ErrorHelperLine(LineErrorType: Enum "Correct Sales Inv. Error Type"; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        Item: Record Item;
    begin
        if CancellingOnly then
            case LineErrorType of
                Enum::"Correct Sales Inv. Error Type"::ItemBlocked:
                    begin
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ItemIsBlockedCancelErr, Item."No.", Item.Description);
                    end;
                "Correct Sales Inv. Error Type"::ItemVariantBlocked:
                    begin
                        Item.SetLoadFields(Description);
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ItemVariantIsBlockedCancelErr, SalesInvoiceLine."Variant Code", Item."No.", Item.Description);
                    end;
                Enum::"Correct Sales Inv. Error Type"::ItemIsReturned:
                    begin
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ShippedQtyReturnedCancelErr, Item."No.", Item.Description);
                    end;
                Enum::"Correct Sales Inv. Error Type"::WrongItemType:
                    Error(LineTypeNotAllowedCancelErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description, SalesInvoiceLine.Type);
                Enum::"Correct Sales Inv. Error Type"::LineFromJob:
                    Error(UsedInJobCancelErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
                Enum::"Correct Sales Inv. Error Type"::DimCombErr:
                    Error(InvalidDimCombinationCancelErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
            end
        else
            case LineErrorType of
                Enum::"Correct Sales Inv. Error Type"::ItemBlocked:
                    begin
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ItemIsBlockedCorrectErr, Item."No.", Item.Description);
                    end;
                "Correct Sales Inv. Error Type"::ItemVariantBlocked:
                    begin
                        Item.SetLoadFields(Description);
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ItemVariantIsBlockedCorrectErr, SalesInvoiceLine."Variant Code", Item."No.", Item.Description);
                    end;
                Enum::"Correct Sales Inv. Error Type"::ItemIsReturned:
                    begin
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ShippedQtyReturnedCorrectErr, Item."No.", Item.Description);
                    end;
                Enum::"Correct Sales Inv. Error Type"::LineFromOrder:
                    Error(SalesLineFromOrderCorrectErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
                Enum::"Correct Sales Inv. Error Type"::WrongItemType:
                    Error(LineTypeNotAllowedCorrectErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description, SalesInvoiceLine.Type);
                Enum::"Correct Sales Inv. Error Type"::LineFromJob:
                    Error(UsedInJobCorrectErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
                Enum::"Correct Sales Inv. Error Type"::DimCombErr:
                    Error(InvalidDimCombinationCorrectErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
            end;
    end;

    local procedure ErrorHelperAccount(AccountErrorType: Enum "Correct Sales Inv. Error Type"; AccountNo: Code[20]; AccountCaption: Text; No: Code[20]; Name: Text)
    begin
        if CancellingOnly then
            case AccountErrorType of
                Enum::"Correct Sales Inv. Error Type"::AccountBlocked:
                    Error(AccountIsBlockedCancelErr, AccountCaption, AccountNo);
                Enum::"Correct Sales Inv. Error Type"::DimErr:
                    Error(InvalidDimCodeCancelErr, AccountCaption, AccountNo, No, Name);
            end
        else
            case AccountErrorType of
                Enum::"Correct Sales Inv. Error Type"::AccountBlocked:
                    Error(AccountIsBlockedCorrectErr, AccountCaption, AccountNo);
                Enum::"Correct Sales Inv. Error Type"::DimErr:
                    Error(InvalidDimCodeCorrectErr, AccountCaption, AccountNo, No, Name);
            end;
    end;

    local procedure HasLineDiscountSetup(SalesInvoiceLine: Record "Sales Invoice Line") Result: Boolean
    begin
        SalesReceivablesSetup.GetRecordOnce();
        Result := SalesReceivablesSetup."Discount Posting" in [SalesReceivablesSetup."Discount Posting"::"Line Discounts", SalesReceivablesSetup."Discount Posting"::"All Discounts"];
        if Result then
            Result := SalesInvoiceLine."Line Discount %" <> 0;
        OnHasLineDiscountSetup(SalesReceivablesSetup, Result);
    end;

    /// <summary>
    /// Updates the related sales order lines when a credit memo exists for the specified credit memo number.
    /// </summary>
    /// <param name="SalesCreditMemoNo">Specifies the posted sales credit memo number.</param>
    internal procedure UpdateSalesOrderLineIfExist(SalesCreditMemoNo: Code[20])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesCrMemoLine.SetLoadFields("Document No.", "No.", "Appl.-from Item Entry", Quantity, "Variant Code");
        SalesCrMemoLine.SetRange("Document No.", SalesCreditMemoNo);
        SalesCrMemoLine.SetFilter("No.", '<>%1', '');
        SalesCrMemoLine.SetFilter(Quantity, '<>%1', 0);
        if SalesCrMemoLine.FindSet() then
            repeat
                Clear(SalesInvoiceLine);
                SalesCrMemoLine.GetSalesInvoiceLine(SalesInvoiceLine);
                if SalesInvoiceLine."Line No." <> 0 then
                    UpdateSalesOrderLinesFromCreditMemo(SalesInvoiceLine, SalesCrMemoLine);
            until SalesCrMemoLine.Next() = 0;
    end;

    local procedure UpdateSalesOrderLinesFromCreditMemo(SalesInvoiceLine: Record "Sales Invoice Line"; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        SalesLine: Record "Sales Line";
        UndoPostingManagement: Codeunit "Undo Posting Management";
    begin
        if SalesLine.Get(SalesLine."Document Type"::Order, SalesInvoiceLine."Order No.", SalesInvoiceLine."Order Line No.") then begin
            SalesInvoiceLine.GetItemLedgEntries(TempItemLedgerEntry, false);
            UpdateSalesOrderLineInvoicedQuantity(SalesLine, SalesCrMemoLine.Quantity, SalesCrMemoLine."Quantity (Base)");
            UpdateSalesOrderLinePrepmtAmount(SalesInvoiceLine);
            if SalesLine."Qty. to Ship" = 0 then
                UpdateWhseRequest(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Location Code");
            TempItemLedgerEntry.SetFilter("Item Tracking", '<>%1', TempItemLedgerEntry."Item Tracking"::None.AsInteger());
            UndoPostingManagement.RevertPostedItemTracking(TempItemLedgerEntry, SalesInvoiceLine."Shipment Date", true);
        end;
    end;

    local procedure UpdateSalesOrderLinesFromCancelledInvoice(SalesInvoiceHeaderNo: Code[20])
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        UndoPostingManagement: Codeunit "Undo Posting Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesOrderLinesFromCancelledInvoice(SalesInvoiceHeaderNo, IsHandled);
        if IsHandled then
            exit;

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeaderNo);
        if SalesInvoiceLine.FindSet() then
            repeat
                TempItemLedgerEntry.Reset();
                TempItemLedgerEntry.DeleteAll();
                SalesInvoiceLine.GetItemLedgEntries(TempItemLedgerEntry, false);
                if SalesLine.Get(SalesLine."Document Type"::Order, SalesInvoiceLine."Order No.", SalesInvoiceLine."Order Line No.") then begin
                    UpdateSalesOrderLineInvoicedQuantity(SalesLine, SalesInvoiceLine.Quantity, SalesInvoiceLine."Quantity (Base)");
                    UpdateSalesOrderLinePrepmtAmount(SalesInvoiceLine);
                    if SalesLine."Qty. to Ship" = 0 then
                        UpdateWhseRequest(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Location Code");
                    TempItemLedgerEntry.SetFilter("Item Tracking", '<>%1', TempItemLedgerEntry."Item Tracking"::None.AsInteger());
                    UndoPostingManagement.RevertPostedItemTracking(TempItemLedgerEntry, SalesInvoiceLine."Shipment Date", true);
                end;
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure UpdateWhseRequest(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetSourceFilter(SourceType, SourceSubType, SourceNo);
        WarehouseRequest.SetRange("Location Code", LocationCode);
        if WarehouseRequest.FindFirst() and WarehouseRequest."Completely Handled" then begin
            WarehouseRequest."Completely Handled" := false;
            WarehouseRequest.Modify();
        end;
    end;

    local procedure UpdateSalesOrderLineInvoicedQuantity(var SalesLine: Record "Sales Line"; CancelledQuantity: Decimal; CancelledQtyBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesOrderLineInvoicedQuantity(SalesLine, CancelledQuantity, CancelledQtyBase, IsHandled);
        if IsHandled then
            exit;

        SalesLine."Quantity Invoiced" -= CancelledQuantity;
        SalesLine."Qty. Invoiced (Base)" -= CancelledQtyBase;
        SalesLine."Quantity Shipped" -= CancelledQuantity;
        SalesLine."Qty. Shipped (Base)" -= CancelledQtyBase;
        SalesLine.InitOutstanding();
        SalesLine.InitQtyToShip();
        SalesLine.UpdateWithWarehouseShip();
        SalesLine.Modify();

        OnAfterUpdateSalesOrderLineInvoicedQuantity(SalesLine, CancelledQuantity, CancelledQtyBase);
    end;

    local procedure TestWMSLocation(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        Item: Record Item;
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWMSLocation(SalesInvoiceLine, IsHandled);
        if IsHandled then
            exit;

        if SalesInvoiceLine.Type <> SalesInvoiceLine.Type::Item then
            exit;
        if SalesInvoiceLine.Quantity = 0 then
            exit;
        if not Item.Get(SalesInvoiceLine."No.") then
            exit;
        if not Item.IsInventoriableType() then
            exit;
        if not Location.Get(SalesInvoiceLine."Location Code") then
            exit;

        if Location."Directed Put-away and Pick" then
            Error(WMSLocationCancelCorrectErr, SalesInvoiceLine."Line No.");
    end;

    local procedure UpdateSalesOrderLinePrepmtAmount(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
    begin
        if not SalesLine.Get(
            SalesLine."Document Type"::Order,
            SalesInvoiceLine."Order No.",
            SalesInvoiceLine."Order Line No.")
        then
            exit;

        if (SalesLine."Prepayment Amount" = 0) or SalesInvoiceLine."Prepayment Line" then
            exit;

        SalesHeader.Get(SalesLine."Document Type"::Order, SalesLine."Document No.");
        Currency.Initialize(SalesHeader."Currency Code", true);

        if SalesHeader."Currency Code" <> '' then
            SalesLine.Validate(
                "Prepmt. Amount Inv. (LCY)",
                SalesLine."Prepmt. Amount Inv. (LCY)" +
                    Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                            SalesHeader."Posting Date",
                            SalesHeader."Currency Code",
                            Round(
                                SalesInvoiceLine.Quantity * (SalesLine."Prepayment Amount" / SalesLine.Quantity),
                                Currency."Amount Rounding Precision"),
                            SalesHeader."Currency Factor"),
                        Currency."Amount Rounding Precision"))
        else
            SalesLine.Validate(
                "Prepmt. Amount Inv. (LCY)",
                SalesLine."Prepmt. Amount Inv. (LCY)" +
                    Round(
                        SalesInvoiceLine.Quantity * (SalesLine."Prepayment Amount" / SalesLine.Quantity),
                        Currency."Amount Rounding Precision"));

        if SalesHeader."Currency Code" <> '' then
            SalesLine.Validate(
                "Prepmt. VAT Amount Inv. (LCY)",
                SalesLine."Prepmt. VAT Amount Inv. (LCY)" +
                    Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                            SalesHeader."Posting Date",
                            SalesHeader."Currency Code",
                            Round(
                                SalesInvoiceLine.Quantity * ((SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepmt. VAT Base Amt.") / SalesLine.Quantity),
                                Currency."Amount Rounding Precision"),
                            SalesHeader."Currency Factor"),
                        Currency."Amount Rounding Precision"))
        else
            SalesLine.Validate(
                "Prepmt. VAT Amount Inv. (LCY)",
                SalesLine."Prepmt. VAT Amount Inv. (LCY)" +
                    Round(
                        SalesInvoiceLine.Quantity * ((SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepmt. VAT Base Amt.") / SalesLine.Quantity),
                        Currency."Amount Rounding Precision"));

        SalesLine.Validate(
            "Prepmt Amt Deducted",
            SalesLine."Prepmt Amt Deducted" -
                Round(
                    SalesInvoiceLine.Quantity * (SalesLine."Prepmt. Line Amount" / SalesLine.Quantity),
                    Currency."Amount Rounding Precision"));

        SalesLine.Validate(
            "Prepmt Amt to Deduct",
            SalesLine."Prepmt Amt to Deduct" +
                Round(
                    SalesInvoiceLine.Quantity * (SalesLine."Prepmt. Line Amount" / SalesLine.Quantity),
                    Currency."Amount Rounding Precision"));

        SalesLine.Modify(true);
    end;

    local procedure TestIfDropShipmentDocument(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempSalesShipmentLine: Record "Sales Shipment Line" temporary;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("Drop Shipment", true);
        if SalesInvoiceLine.FindFirst() then begin
            SalesInvoiceLine.GetSalesShptLines(TempSalesShipmentLine);
            Error(DropShipmentDocumentExistsErr, TempSalesShipmentLine."Purchase Order No.");
        end;
    end;

    /// <summary>
    /// Raised after creating a copy document from a posted sales invoice.
    /// </summary>
    /// <param name="SalesHeader">The newly created sales header.</param>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being copied from.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCopyDocument(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    /// <summary>
    /// Raised after determining whether a sales invoice line is a comment line.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line being checked.</param>
    /// <param name="Result">The result indicating whether it is a comment line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCommentLine(SalesInvoiceLine: Record "Sales Invoice Line"; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after testing whether the invoice correction or cancellation is allowed.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being validated.</param>
    /// <param name="Cancelling">Indicates whether this is a cancellation operation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterTestCorrectInvoiceIsAllowed(var SalesInvoiceHeader: Record "Sales Invoice Header"; Cancelling: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after testing whether the sales invoice line type is allowed for correction.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line being validated.</param>
    /// <param name="IsHandled">Set to true to skip the default line type error.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterTestSalesLineType(SalesInvoiceLine: Record "Sales Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after creating a corrective sales invoice from a posted invoice.
    /// </summary>
    /// <param name="SalesHeader">The newly created corrective sales invoice header.</param>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being corrected.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCorrSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    /// <summary>
    /// Raised after creating a corrective sales credit memo from a posted invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being corrected.</param>
    /// <param name="SalesHeader">The newly created corrective sales credit memo header.</param>
    /// <param name="CancellingOnly">Indicates whether only cancellation is being performed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCorrectiveSalesCrMemo(SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; var CancellingOnly: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after updating the invoiced quantity on a sales order line during cancellation.
    /// </summary>
    /// <param name="SalesLine">The updated sales order line.</param>
    /// <param name="CancelledQuantity">The cancelled quantity.</param>
    /// <param name="CancelledQtyBase">The cancelled quantity in base unit of measure.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesOrderLineInvoicedQuantity(var SalesLine: Record "Sales Line"; CancelledQuantity: Decimal; CancelledQtyBase: Decimal)
    begin
    end;

    /// <summary>
    /// Raised before creating a corrective sales credit memo from a posted invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice to correct.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCorrectiveSalesCrMemo(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    /// <summary>
    /// Raised before creating a credit memo copy document from a posted invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice to copy from.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCreditMemoCopyDocument(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    /// <summary>
    /// Raised before inserting the sales header during invoice correction.
    /// </summary>
    /// <param name="SalesHeader">The sales header to be inserted.</param>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being corrected.</param>
    /// <param name="CancellingOnly">Indicates whether only cancellation is being performed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderInsert(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; CancellingOnly: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting tracking information for invoice cancellation.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being cancelled.</param>
    /// <param name="IsHandled">Set to true to skip default tracking setup.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTrackInfoForCancellation(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

#pragma warning disable AS0018
#pragma warning restore AS0018

    /// <summary>
    /// Raised before testing whether there are free number series for the correction.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being corrected.</param>
    /// <param name="IsHandled">Set to true to skip default number series validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestIfAnyFreeNumberSeries(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised to determine whether line discount setup is configured.
    /// </summary>
    /// <param name="SalesReceivablesSetup">The sales and receivables setup record.</param>
    /// <param name="Result">The result indicating whether line discount setup exists.</param>
    [IntegrationEvent(false, false)]
    local procedure OnHasLineDiscountSetup(SalesReceivablesSetup: Record "Sales & Receivables Setup"; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before testing inventory posting setup for the sales invoice line.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line being validated.</param>
    /// <param name="IsHandled">Set to true to skip default inventory posting setup validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestInventoryPostingSetup(SalesInvoiceLine: Record "Sales Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating the invoiced quantity on a sales order line during cancellation.
    /// </summary>
    /// <param name="SalesLine">The sales order line to be updated.</param>
    /// <param name="CancelledQuantity">The cancelled quantity.</param>
    /// <param name="CancelledQtyBase">The cancelled quantity in base unit of measure.</param>
    /// <param name="IsHandled">Set to true to skip default quantity update.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesOrderLineInvoicedQuantity(var SalesLine: Record "Sales Line"; CancelledQuantity: Decimal; CancelledQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before opening the credit memo page during invoice correction.
    /// </summary>
    /// <param name="SalesHeader">The sales credit memo header to display.</param>
    /// <param name="IsHandled">Set to true to skip opening the default page.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateCreditMemoOnBeforePageRun(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before opening the posted credit memo page during invoice correction.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The posted sales credit memo header to display.</param>
    /// <param name="IsHandled">Set to true to skip opening the default page.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateCreditMemoOnBeforePostedPageRun(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before unapplying cost applications for the invoice.
    /// </summary>
    /// <param name="InvNo">The invoice number to unapply cost applications for.</param>
    /// <param name="IsHandled">Set to true to skip default cost unapplication.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnapplyCostApplication(InvNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after calculating the shipped quantity not returned during sales line validation.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line being validated.</param>
    /// <param name="ShippedQtyNoReturned">The calculated shipped quantity not returned.</param>
    [IntegrationEvent(false, false)]
    local procedure OnTestSalesLinesOnAfterCalcShippedQtyNoReturned(SalesInvoiceLine: Record "Sales Invoice Line"; var ShippedQtyNoReturned: Decimal)
    begin
    end;

    /// <summary>
    /// Raised after updating sales order lines from a cancelled invoice during the OnRun trigger.
    /// </summary>
    /// <param name="Rec">The posted sales invoice header being cancelled.</param>
    /// <param name="SalesHeader">The credit memo header created for cancellation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnOnRunOnAfterUpdateSalesOrderLinesFromCancelledInvoice(var Rec: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before testing whether the invoice has been paid.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being validated.</param>
    /// <param name="IsHandled">Set to true to skip default payment validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestIfInvoiceIsPaid(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before opening the corrective credit memo page from a notification action.
    /// </summary>
    /// <param name="SalesHeader">The corrective sales credit memo header to display.</param>
    /// <param name="IsHandled">Set to true to skip opening the default page.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateCorrectiveCreditMemoOnBeforePageRun(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before testing VAT posting setup for the sales invoice line.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line being validated.</param>
    /// <param name="IsHandled">Set to true to skip default VAT posting setup validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestVATPostingSetup(SalesInvoiceLine: Record "Sales Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before raising a header-level error during invoice correction validation.
    /// </summary>
    /// <param name="HeaderErrorType">The type of header error being raised.</param>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being validated.</param>
    /// <param name="CancellingOnly">Indicates whether only cancellation is being performed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorHelperHeader(HeaderErrorType: Enum "Correct Sales Inv. Error Type"; SalesInvoiceHeader: Record "Sales Invoice Header"; CancellingOnly: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before testing whether the invoice has already been corrected.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being validated.</param>
    /// <param name="IsHandled">Set to true to skip default correction validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestIfInvoiceIsCorrectedOnce(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking whether the invoice was not cancelled.
    /// </summary>
    /// <param name="InvNo">The invoice number to check.</param>
    /// <param name="Result">The result indicating whether the invoice was not cancelled.</param>
    /// <param name="IsHandled">Set to true to skip default cancellation check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeWasNotCancelled(InvNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before posting the corrective sales credit memo during the OnRun trigger.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice being corrected.</param>
    /// <param name="SalesHeader">The corrective credit memo header to be posted.</param>
    /// <param name="IsHandled">Set to true to skip default posting.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress the commit operation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforePostCorrectiveSalesCrMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before testing warehouse management system location for the sales invoice line.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line being validated.</param>
    /// <param name="IsHandled">Set to true to skip default WMS location validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWMSLocation(var SalesInvoiceLine: Record "Sales Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before creating and processing project planning lines during invoice correction.
    /// </summary>
    /// <param name="SalesHeader">The sales header for which project planning lines are being created.</param>
    /// <param name="IsHandled">Set to true to skip default project planning line processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAndProcessJobPlanningLines(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before testing general posting setup for item type lines.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line being validated.</param>
    /// <param name="IsHandled">Set to true to skip default item type posting setup test.</param>
    [IntegrationEvent(false, false)]
    local procedure OnTestGenPostingSetupOnBeforeTestTypeItem(SalesInvoiceLine: Record "Sales Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating sales order lines from a cancelled invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeaderNo">The cancelled invoice number.</param>
    /// <param name="IsHandled">Set to true to skip default order line update.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesOrderLinesFromCancelledInvoice(SalesInvoiceHeaderNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after initializing a project planning line from another project planning line during correction.
    /// </summary>
    /// <param name="ToJobPlanningLine">The newly created project planning line.</param>
    /// <param name="FromJobPlanningLine">The source project planning line.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateJobPlanningLineOnAfterInitFromJobPlanningLine(var ToJobPlanningLine: Record "Job Planning Line"; FromJobPlanningLine: Record "Job Planning Line"; SalesLine: Record "Sales Line")
    begin
    end;
}
