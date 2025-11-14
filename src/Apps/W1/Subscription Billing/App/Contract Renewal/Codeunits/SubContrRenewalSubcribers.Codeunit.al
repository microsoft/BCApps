namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;
using System.Utilities;

codeunit 8001 "Sub. Contr. Renewal Subcribers"
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnBeforeUpdateUnitPrice, '', false, false)]
    local procedure BlankUnitPriceForContractRenewal(var SalesLine: Record "Sales Line")
    begin
        if SalesLine.IsContractRenewal() and (SalesLine."Unit Price" <> 0) then
            SalesLine.Validate("Unit Price", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnBeforeValidateEvent, "Qty. to Ship", false, false)]
    local procedure ErrorIfQtyToShipIsNotEqualToQuantity(var Rec: Record "Sales Line")
    var
        ContractRenewalCanOnlyBeShippedCompletelyErr: Label 'Contract Renewals can only be shipped completely.';
    begin
        if not Rec.IsContractRenewal() then
            exit;
        if (Rec."Qty. to Ship" <> 0) and ((Rec."Qty. to Ship" <> Rec.Quantity)) then
            Error(ContractRenewalCanOnlyBeShippedCompletelyErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeSalesLineInsert, '', false, false)]
    local procedure SalesHeaderOnBeforeInsertRecreatesSalesLines(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line")
    begin
        if (not TempSalesLine.IsContractRenewal()) or (SalesLine."Document Type" <> SalesLine."Document Type"::Quote) then
            exit;
        SalesLine."Discount" := TempSalesLine."Discount";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Invoice", OnBeforeOnRun, '', false, false)]
    local procedure DisallowQuoteToInvoiceForContractRenewalQuote(var SalesHeader: Record "Sales Header")
    var
        ContractRenewalMgt: Codeunit "Sub. Contract Renewal Mgt.";
    begin
        if ContractRenewalMgt.IsContractRenewal(SalesHeader) then
            Error(ActionNotPermittedForContractRenewalQuoteErr);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Quote", OnBeforeActionEvent, MakeInvoice, false, false)]
    local procedure PageSalesQuoteDisallowActionQuoteToInvoiceForContractRenewal(var Rec: Record "Sales Header")
    var
        ContractRenewalMgt: Codeunit "Sub. Contract Renewal Mgt.";
    begin
        if ContractRenewalMgt.IsContractRenewal(Rec) then
            Error(ActionNotPermittedForContractRenewalQuoteErr);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Quotes", OnBeforeActionEvent, MakeInvoice, false, false)]
    local procedure PageSalesQuotesDisallowActionQuoteToInvoiceForContractRenewal(var Rec: Record "Sales Header")
    var
        ContractRenewalMgt: Codeunit "Sub. Contract Renewal Mgt.";
    begin
        if ContractRenewalMgt.IsContractRenewal(Rec) then
            Error(ActionNotPermittedForContractRenewalQuoteErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeDeleteAfterPosting, '', false, false)]
    local procedure SalesPostOnBeforeSalesLineDeleteAll(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        PostContractRenewal: Codeunit "Post Sub. Contract Renewal";
    begin
        case SalesHeader."Document Type" of
            "Sales Document Type"::Invoice:
                PostContractRenewal.ProcessPlannedServCommsForPostedSalesInvoice(SalesInvoiceHeader);
            "Sales Document Type"::"Credit Memo":
                PostContractRenewal.ProcessPlannedServCommsForPostedSalesCreditMemo(SalesCrMemoHeader)
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeDeleteAfterPosting, '', false, false)]
    local procedure PurchPostOnBeforeDeleteAfterPosting(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PostContractRenewal: Codeunit "Post Sub. Contract Renewal";
    begin
        case PurchaseHeader."Document Type" of
            "Purchase Document Type"::Invoice:
                PostContractRenewal.ProcessPlannedServCommsForPostedPurchaseInvoice(PurchInvHeader);
            "Purchase Document Type"::"Credit Memo":
                PostContractRenewal.ProcessPlannedServCommsForPostedPurchaseCreditMemo(PurchCrMemoHdr)
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Totals", OnCalculateSalesSubPageTotalsOnAfterSetFilters, '', true, true)]
    local procedure ExcludeLinesFromSalesDocumentTotal(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Exclude from Doc. Total", false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", OnCopySalesDocSalesLineOnAfterCalcShouldRunIteration, '', false, false)]
    local procedure OnCopySalesDocSalesLineOnAfterCalcShouldRunIteration(FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line")
    var
        ContractRenewalWillNotBeCopiedNotification: Notification;
    begin
        if not FromSalesLine.IsContractRenewal() then
            exit;
        if not FromSalesLine.IsEmpty() then begin
            ContractRenewalWillNotBeCopiedNotification.Id := CreateGuid();
            ContractRenewalWillNotBeCopiedNotification.Message(ContractRenewalLineWillNotBeCopiedMsg);
            ContractRenewalWillNotBeCopiedNotification.Scope(NotificationScope::LocalScope);
            ContractRenewalWillNotBeCopiedNotification.Send();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostSalesLineOnAfterTestSalesLine, '', false, false)]
    local procedure PerformRenewalForSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; WhseShip: Boolean; PreviewMode: Boolean; var CostBaseAmount: Decimal)
    begin
        if not SalesLine.IsContractRenewal() then
            exit;
        if not (SalesLine.Type = "Sales Line Type"::"Service Object") then
            exit;

        SalesLine."Quantity Invoiced" := SalesLine."Quantity Shipped";
        SalesLine."Qty. Invoiced (Base)" := SalesLine."Qty. Shipped (Base)";
        SalesLine."Qty. Shipped Not Invoiced" := 0;
        SalesLine."Qty. Shipped Not Invd. (Base)" := 0;
        SalesLine."Shipped Not Invoiced" := 0;
        SalesLine."Shipped Not Invoiced (LCY)" := 0;
        SalesLine."Shipped Not Inv. (LCY) No VAT" := 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforePostSalesLines, '', false, false)]
    local procedure OnBeforePostSalesLines(var SalesHeader: Record "Sales Header"; var TempSalesLineGlobal: Record "Sales Line" temporary)
    var
        ContractRenewalMgt: Codeunit "Sub. Contract Renewal Mgt.";
        PostContractRenewal: Codeunit "Post Sub. Contract Renewal";
    begin
        if not ContractRenewalMgt.IsContractRenewal(SalesHeader) then
            exit;
        PostContractRenewal.Run(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", OnCopySalesDocLineOnAfterCalcCopyThisLine, '', false, false)]
    local procedure ExcludeRenewalForSalesLine(var ToSalesLine: Record "Sales Line"; var CopyThisLine: Boolean)
    begin
        //NOTE: In Standard BC parameter is called ToSalesLine, but FromSalesLine is actually passed to event
        if CopyThisLine then
            CopyThisLine := ToSalesLine.Type <> "Sales Line Type"::"Service Object";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnBeforeInitType, '', false, false)]
    local procedure OnBeforeInitType(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
        if xSalesLine.Type = "Sales Line Type"::"Service Object" then begin
            SalesLine.Type := "Sales Line Type"::" ";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeUpdatePostingNo, '', false, false)]
    local procedure SkipInitializingPostingNo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        if not SalesHeader.Invoice then
            exit;
        if SalesHeader.HasOnlyContractRenewalLines() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnInsertPostedHeadersOnBeforeInsertInvoiceHeader, '', false, false)]
    local procedure SkipInsertingSalesInvoiceHeader(SalesHeader: Record "Sales Header"; var IsHandled: Boolean; SalesInvHeader: Record "Sales Invoice Header"; var GenJnlLineDocType: Enum "Gen. Journal Document Type"; var GenJnlLineDocNo: Code[20]; var GenJnlLineExtDocNo: Code[35])
    begin
        if not SalesHeader.Invoice then
            exit;
        if SalesHeader.HasOnlyContractRenewalLines() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnInsertPostedHeadersOnAfterCalcInsertShipmentHeaderNeeded, '', false, false)]
    local procedure SkipInsertShipmentHeaderNeededOnPostSalesOrderWithContractRenewal(var SalesHeader: Record "Sales Header"; var InsertShipmentHeaderNeeded: Boolean)
    begin
        if not SalesHeader.Ship then
            exit;
        if SalesHeader.HasOnlyContractRenewalLines() then
            InsertShipmentHeaderNeeded := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostSalesLineOnBeforeInsertInvoiceLine, '', false, false)]
    local procedure SkipInsertSalesInvoiceLineOnPostSalesLineOnBeforeInsertInvoiceLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() or SalesHeader.HasOnlyContractRenewalLines() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeSalesInvLineInsert, '', false, false)]
    local procedure SkipInsertSalesInvoiceLineOnBeforeSalesInvLineInsert(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() or SalesHeader.HasOnlyContractRenewalLines() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostSalesLineOnBeforeInsertShipmentLine, '', false, false)]
    local procedure SkipInsertSalesShipmentLineOnPostSalesLineOnBeforeInsertShipmentLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() or SalesHeader.HasOnlyContractRenewalLines() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostSalesLineOnBeforeInsertReturnReceiptLine, '', false, false)]
    local procedure SkipInsertReturnReceiptLineOnPostSalesLineOnBeforeInsertReturnReceiptLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() or SalesHeader.HasOnlyContractRenewalLines() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostSalesLineOnBeforeInsertCrMemoLine, '', false, false)]
    local procedure SkipInsertSalesCrMemoLineOnPostSalesLineOnBeforeInsertCrMemoLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() or SalesHeader.HasOnlyContractRenewalLines() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostItemTrackingForShipmentOnBeforeShipmentInvoiceErr, '', false, false)]
    local procedure OnPostItemTrackingForShipmentOnBeforeShipmentInvoiceErr(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforePostItemTrackingCheckShipment, '', false, false)]
    local procedure OnBeforePostItemTrackingCheckShipment(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeTestUpdatedSalesLine, '', false, false)]
    local procedure OnBeforeTestUpdatedSalesLine(SalesLine: Record "Sales Line"; var IsHandled: Boolean; var ErrorMessageManagement: Codeunit "Error Message Management")
    begin
        if SalesLine.IsContractRenewal() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", OnBeforePrepareLine, '', false, false)]
    local procedure OnBeforePrepareLine(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostSalesLineOnBeforePostSalesLine, '', false, false)]
    local procedure OnPostSalesLineOnBeforePostSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; SrcCode: Code[10]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() then
            IsHandled := false; //IsHandled = ShouldPostLine
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeTestSalesLine, '', false, false)]
    local procedure OnBeforeTestSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    begin
        if SalesLine.IsContractRenewal() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", OnBeforePostLedgerEntry, '', false, false)]
    local procedure OnBeforePostLedgerEntry(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        if not SalesHeader.Ship then
            exit;
        if SalesHeader.HasOnlyContractRenewalLines() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnBeforeDocAttachForPostedSalesDocs, '', false, false)]
    local procedure SkipDocumentAttachmentForContractRenewalLines(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
        if not SalesHeader.Ship then
            exit;
        if SalesHeader.HasOnlyContractRenewalLines() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnBeforeValidateVATProdPostingGroup, '', false, false)]
    local procedure OnBeforeValidateVATProdPostingGroup(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine.Type = "Sales Line Type"::"Service Object" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostSalesLineOnAfterSetEverythingInvoiced, '', false, false)]
    local procedure SetEverythingInvoicedOnPostSalesLineOnAfterSetEverythingInvoiced(SalesLine: Record "Sales Line"; var EverythingInvoiced: Boolean; var IsHandled: Boolean)
    begin
        if not SalesLine.IsContractRenewal() then
            exit;
        EverythingInvoiced := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnRoundAmountOnBeforeIncrAmount, '', false, false)]
    local procedure OnRoundAmountOnBeforeIncrAmount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineQty: Decimal; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if not SalesLine.IsContractRenewal() then
            exit;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeRoundAmount, '', false, false)]
    local procedure OnBeforeRoundAmount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineQty: Decimal; var CurrExchRate: Record "Currency Exchange Rate")
    begin
        if not SalesLine.IsContractRenewal() then
            exit;
        SalesLine."Line Amount" := 0;
        SalesLine.Amount := 0;
        SalesLine."VAT Base Amount" := 0;
        SalesLine."VAT Difference" := 0;
        SalesLine."Amount Including VAT" := 0;
        SalesLine."Line Discount Amount" := 0;
        SalesLine."Inv. Discount Amount" := 0;
        SalesLine."Inv. Disc. Amount to Invoice" := 0;
        SalesLine."Prepmt. Line Amount" := 0;
        SalesLine."Prepmt. Amt. Inv." := 0;
        SalesLine."Prepmt Amt to Deduct" := 0;
        SalesLine."Prepmt Amt Deducted" := 0;
        SalesLine."Prepayment VAT Difference" := 0;
        SalesLine."Prepmt VAT Diff. to Deduct" := 0;
        SalesLine."Prepmt VAT Diff. Deducted" := 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeSumSalesLines2, '', false, false)]
    local procedure OnBeforeSumSalesLines2(SalesHeader: Record "Sales Header"; var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; InsertSalesLine: Boolean; CalcAdCostLCY: Boolean; var TotalAdjCostLCY: Decimal; IncludePrepayments: Boolean; var IsHandled: Boolean)
    begin
        if not NewSalesLine.IsContractRenewal() then
            exit;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeValidateEvent, 'Responsibility Center', false, false)]
    local procedure AllowChangingResponsibilityCenter(var Rec: Record "Sales Header")
    var
        ResponsibilityCenter: Record "Responsibility Center";
        SubContractRenewalMgt: Codeunit "Sub. Contract Renewal Mgt.";
        DocumentChangeManagement: Codeunit "Document Change Management";
        GetShortcutDimensionValues: Codeunit "Get Shortcut Dimension Values";
        ShortcutDimCode: array[2] of Code[20];
    begin
        if Rec.IsTemporary then
            exit;
        if not (Rec."Document Type" in ["Sales Document Type"::Quote, "Sales Document Type"::"Order"]) then
            exit;
        if not SubContractRenewalMgt.IsContractRenewal(Rec) then
            exit;

        // Allow setting the Responsibility Center to empty
        if Rec."Responsibility Center" = '' then begin
            Rec.SetHideValidationDialog(true);
            DocumentChangeManagement.SetSkipContractSalesHeaderModifyCheck(true);
            UpdateResponsibilityCenterOnSalesLines(Rec);
            exit;
        end;

        if not ResponsibilityCenter.Get(Rec."Responsibility Center") then
            exit;

        // Allow the change if the Responsibility Center has no dimensions set
        if (ResponsibilityCenter."Global Dimension 1 Code" = '') and (ResponsibilityCenter."Global Dimension 2 Code" = '') then begin
            Rec.SetHideValidationDialog(true);
            DocumentChangeManagement.SetSkipContractSalesHeaderModifyCheck(true);
            UpdateResponsibilityCenterOnSalesLines(Rec);
        end;

        // Get the Dimension Set IDs
        GetShortcutDimensionValues.GetGlobalDimensions(Rec."Dimension Set ID", ShortcutDimCode);
        if (ResponsibilityCenter."Global Dimension 1 Code" = ShortcutDimCode[1]) and (ResponsibilityCenter."Global Dimension 2 Code" = ShortcutDimCode[2]) then begin
            Rec.SetHideValidationDialog(true);
            DocumentChangeManagement.SetSkipContractSalesHeaderModifyCheck(true);
            UpdateResponsibilityCenterOnSalesLines(Rec);
        end;
    end;

    local procedure UpdateResponsibilityCenterOnSalesLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, "Sales Line Type"::"Service Object");
        SalesLine.ModifyAll("Responsibility Center", SalesHeader."Responsibility Center", false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeRecreateSalesLinesHandler, '', false, false)]
    local procedure SkipDeletingExistingSalesLines(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ChangedFieldName: Text[100]; var IsHandled: Boolean)
    var
        SubContractRenewalMgt: Codeunit "Sub. Contract Renewal Mgt.";
    begin
        if SalesHeader.IsTemporary then
            exit;
        if not (SalesHeader."Document Type" in ["Sales Document Type"::Quote, "Sales Document Type"::"Order"]) then
            exit;
        if not SubContractRenewalMgt.IsContractRenewal(SalesHeader) then
            exit;

        if ChangedFieldName = SalesHeader.FieldName("Responsibility Center") then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterValidateEvent, 'Responsibility Center', false, false)]
    local procedure ClearAllowChangingResponsibilityCenter()
    var
        DocumentChangeManagement: Codeunit "Document Change Management";
    begin
        DocumentChangeManagement.SetSkipContractSalesHeaderModifyCheck(false);
    end;

    var
        ActionNotPermittedForContractRenewalQuoteErr: Label 'This action is not allowed for contract Renewal Quotes.';
        ContractRenewalLineWillNotBeCopiedMsg: Label 'One or more document lines were not copied since they are marked as "Contract Renewal".';
}
