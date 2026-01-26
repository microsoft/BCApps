// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.CRM.Opportunity;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Automation;
using System.Utilities;

codeunit 86 "Sales-Quote to Order"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        Cust: Record Customer;
        SalesCommentLine: Record "Sales Comment Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        RecordLinkManagement: Codeunit "Record Link Management";
        ShouldRedistributeInvoiceAmount: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(Rec);

        Rec.TestField("Document Type", Rec."Document Type"::Quote);
        ShouldRedistributeInvoiceAmount := SalesCalcDiscountByType.ShouldRedistributeInvoiceDiscountAmount(Rec);

        Rec.CheckSalesPostRestrictions();

        Cust.Get(Rec."Sell-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, Rec."Document Type"::Order, true, false);
        if Rec."Sell-to Customer No." <> Rec."Bill-to Customer No." then begin
            Cust.Get(Rec."Bill-to Customer No.");
            Cust.CheckBlockedCustOnDocs(Cust, Rec."Document Type"::Order, true, false);
        end;
        Rec.CalcFields("Amount Including VAT", "Work Description");
        OnRunOnAfterCalcAmountIncludingVAT(Rec);

        Rec.ValidateSalesPersonOnSalesHeader(Rec, true, false);

        Rec.CheckForBlockedLines();

        CheckInProgressOpportunities(Rec);

        CreateSalesHeader(Rec, Cust);

        TransferQuoteToOrderLines(SalesQuoteLine, Rec, SalesOrderLine, SalesOrderHeader, Cust);
        OnAfterInsertAllSalesOrderLines(SalesOrderLine, Rec, SalesOrderHeader);

        SalesSetup.Get();
        ArchiveSalesQuote(Rec);

        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then begin
            SalesOrderHeader."Posting Date" := 0D;
            SalesOrderHeader.Modify();
        end;

        SalesCommentLine.CopyComments(Rec."Document Type".AsInteger(), SalesOrderHeader."Document Type".AsInteger(), Rec."No.", SalesOrderHeader."No.");
        RecordLinkManagement.CopyLinks(Rec, SalesOrderHeader);

        AssignItemCharges(Rec."Document Type", Rec."No.", SalesOrderHeader."Document Type", SalesOrderHeader."No.");

        MoveWonLostOpportunites(Rec, SalesOrderHeader);

        CopyApprovalEntryQuoteToOrder(Rec, SalesOrderHeader);

        IsHandled := false;
        OnBeforeDeleteSalesQuote(Rec, SalesOrderHeader, IsHandled, SalesQuoteLine);
        if not IsHandled then begin
            ApprovalsMgmt.DeleteApprovalEntries(Rec.RecordId);
            SalesCommentLine.DeleteComments(Rec."Document Type".AsInteger(), Rec."No.");
            Rec.DeleteLinks();
            Rec.Delete();
            SalesQuoteLine.DeleteAll();
            OnRunOnAfterSalesQuoteLineDeleteAll(Rec, SalesOrderHeader, SalesQuoteLine);
        end;

        if not ShouldRedistributeInvoiceAmount then
            SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(SalesOrderHeader);

        OnAfterOnRun(Rec, SalesOrderHeader);
    end;

    var
        SalesQuoteLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        Text1130000: Label '%1 cannot be greater than %2.', Comment = '%1 = Document Date; %2 = Posting Date';

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'An open %1 is linked to this %2. The %1 has to be closed before the %2 can be converted to an %3. Do you want to close the %1 now and continue the conversion?', Comment = 'An open Opportunity is linked to this Quote. The Opportunity has to be closed before the Quote can be converted to an Order. Do you want to close the Opportunity now and continue the conversion?';
        Text001: Label 'An open %1 is still linked to this %2. The conversion to an %3 was aborted.', Comment = 'An open Opportunity is still linked to this Quote. The conversion to an Order was aborted.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CopyApprovalEntryQuoteToOrder(SalesHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyApprovalEntryQuoteToOrder(SalesHeader, SalesOrderHeader, IsHandled);
        if not IsHandled then
            ApprovalsMgmt.CopyApprovalEntryQuoteToOrder(SalesHeader.RecordId, SalesOrderHeader."No.", SalesOrderHeader.RecordId);
    end;

    local procedure CreateSalesHeader(SalesHeader: Record "Sales Header"; Customer: Record Customer)
    var
        GlSetup: Record "General Ledger Setup";
    begin
        OnBeforeCreateSalesHeader(SalesHeader);

        SalesOrderHeader := SalesHeader;
        SalesOrderHeader."Document Type" := SalesOrderHeader."Document Type"::Order;

        SalesOrderHeader."No. Printed" := 0;
        SalesOrderHeader.Status := SalesOrderHeader.Status::Open;
        SalesOrderHeader."No." := '';
        SalesOrderHeader."Quote No." := SalesHeader."No.";
        OnCreateSalesHeaderOnBeforeSalesOrderLineLockTable(SalesOrderHeader, SalesHeader);
        SalesOrderLine.LockTable();
        OnBeforeInsertSalesOrderHeader(SalesOrderHeader, SalesHeader);
        SalesOrderHeader.Insert(true);
        OnAfterInsertSalesOrderHeader(SalesOrderHeader, SalesHeader);

        SalesOrderHeader."Order Date" := SalesHeader."Order Date";
        if SalesHeader."Posting Date" <> 0D then
            SalesOrderHeader."Posting Date" := SalesHeader."Posting Date";

        SalesOrderHeader.InitFromSalesHeader(SalesHeader);
        if SalesOrderHeader."Document Date" > SalesOrderHeader."Posting Date" then
            Error(Text1130000, SalesHeader.FieldCaption("Document Date"), SalesHeader.FieldCaption("Posting Date"));
        SalesOrderHeader.Validate("Operation Type", SalesHeader."Operation Type");
        SalesOrderHeader."Fattura Document Type" := SalesHeader."Fattura Document Type";
        SalesOrderHeader."Outbound Whse. Handling Time" := SalesHeader."Outbound Whse. Handling Time";
        SalesOrderHeader.Reserve := SalesHeader.Reserve;

        SalesOrderHeader."Prepayment %" := Customer."Prepayment %";
        if SalesOrderHeader."Posting Date" = 0D then
            SalesOrderHeader."Posting Date" := WorkDate();

        if SalesOrderHeader."VAT Registration No." = '' then
            SalesOrderHeader."VAT Registration No." := Customer."VAT Registration No.";

        SalesOrderHeader."VAT Reporting Date" := GlSetup.GetVATDate(SalesOrderHeader."Posting Date", SalesOrderHeader."Document Date");
        SalesOrderHeader.Validate("Posting Date");

        SalesHeader.CalcFields("Work Description");
        SalesOrderHeader."Work Description" := SalesHeader."Work Description";

        OnBeforeModifySalesOrderHeader(SalesOrderHeader, SalesHeader);
        SalesOrderHeader.Modify();

        OnAfterCreateSalesHeader(SalesOrderHeader, SalesHeader);
    end;

    local procedure ArchiveSalesQuote(var SalesHeader: Record "Sales Header")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchiveSalesQuote(SalesHeader, SalesOrderHeader, IsHandled);
        if IsHandled then
            exit;

        case SalesSetup."Archive Quotes" of
            SalesSetup."Archive Quotes"::Always:
                ArchiveManagement.ArchSalesDocumentNoConfirm(SalesHeader);
            SalesSetup."Archive Quotes"::Question:
                ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        end;
    end;

    local procedure AssignItemCharges(FromDocType: Enum "Sales Document Type"; FromDocNo: Code[20]; ToDocType: Enum "Sales Document Type"; ToDocNo: Code[20])
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignItemCharges(FromDocType.AsInteger(), FromDocNo, ToDocType.AsInteger(), ToDocNo, IsHandled);
        if IsHandled then
            exit;
        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", FromDocType);
        ItemChargeAssgntSales.SetRange("Document No.", FromDocNo);
        OnAssignItemChargesOnAfterItemChargeAssgntSalesSetFilters(ItemChargeAssgntSales, FromDocType, FromDocNo, ToDocType, ToDocNo);
        while ItemChargeAssgntSales.FindFirst() do begin
            ItemChargeAssgntSales.Delete();
            ItemChargeAssgntSales."Document Type" := SalesOrderHeader."Document Type";
            ItemChargeAssgntSales."Document No." := SalesOrderHeader."No.";
            if not (ItemChargeAssgntSales."Applies-to Doc. Type" in
                    [ItemChargeAssgntSales."Applies-to Doc. Type"::Shipment,
                     ItemChargeAssgntSales."Applies-to Doc. Type"::"Return Receipt"])
            then begin
                ItemChargeAssgntSales."Applies-to Doc. Type" := ToDocType;
                ItemChargeAssgntSales."Applies-to Doc. No." := ToDocNo;
            end;
            ItemChargeAssgntSales.Insert();
        end;
    end;

    procedure GetSalesOrderHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader2 := SalesOrderHeader;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        if NewHideValidationDialog then
            exit;
    end;

    local procedure CheckInProgressOpportunities(var SalesHeader: Record "Sales Header")
    var
        Opp: Record Opportunity;
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInProgressOpportunities(Opp, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        FilterOpportunityForQuote(Opp, SalesHeader, true);
        if Opp.FindFirst() then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text000, Opp.TableCaption(), Opp."Sales Document Type"::Quote,
                   Opp."Sales Document Type"::Order), true)
            then
                Error('');
            TempOpportunityEntry.DeleteAll();
            TempOpportunityEntry.Init();
            TempOpportunityEntry.Validate("Opportunity No.", Opp."No.");
            TempOpportunityEntry."Sales Cycle Code" := Opp."Sales Cycle Code";
            TempOpportunityEntry."Contact No." := Opp."Contact No.";
            TempOpportunityEntry."Contact Company No." := Opp."Contact Company No.";
            TempOpportunityEntry."Salesperson Code" := Opp."Salesperson Code";
            TempOpportunityEntry."Campaign No." := Opp."Campaign No.";
            TempOpportunityEntry."Action Taken" := TempOpportunityEntry."Action Taken"::Won;
            TempOpportunityEntry."Calcd. Current Value (LCY)" := TempOpportunityEntry.GetSalesDocValue(SalesHeader);
            TempOpportunityEntry."Cancel Old To Do" := true;
            TempOpportunityEntry."Wizard Step" := 1;
            OnBeforeTempOpportunityEntryInsert(TempOpportunityEntry, SalesHeader);
            TempOpportunityEntry.Insert();
            TempOpportunityEntry.SetRange("Action Taken", TempOpportunityEntry."Action Taken"::Won);

            IsHandled := false;
            OnCheckInProgressOpportunitiesOnBeforeRunCloseOpportunityPage(TempOpportunityEntry, Opp, SalesHeader, IsHandled);
            if IsHandled then
                exit;
            PAGE.RunModal(PAGE::"Close Opportunity", TempOpportunityEntry);
            FilterOpportunityForQuote(Opp, SalesHeader, true);
            if Opp.FindFirst() then
                Error(Text001, Opp.TableCaption(), Opp."Sales Document Type"::Quote, Opp."Sales Document Type"::Order);
            Commit();
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        end;
    end;

    local procedure MoveWonLostOpportunites(var SalesQuoteHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    var
        Opp: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMoveWonLostOpportunites(SalesQuoteHeader, SalesOrderHeader, IsHandled);
        if not IsHandled then begin
            FilterOpportunityForQuote(Opp, SalesQuoteHeader, false);
            if Opp.FindFirst() then
                if Opp.Status = Opp.Status::Won then begin
                    Opp."Sales Document Type" := Opp."Sales Document Type"::Order;
                    Opp."Sales Document No." := SalesOrderHeader."No.";
                    Opp.Modify();
                    OpportunityEntry.Reset();
                    OpportunityEntry.SetCurrentKey(Active, "Opportunity No.");
                    OpportunityEntry.SetRange(Active, true);
                    OpportunityEntry.SetRange("Opportunity No.", Opp."No.");
                    if OpportunityEntry.FindFirst() then begin
                        OpportunityEntry."Calcd. Current Value (LCY)" := OpportunityEntry.GetSalesDocValue(SalesOrderHeader);
                        OpportunityEntry.Modify();
                    end;
                end else
                    if Opp.Status = Opp.Status::Lost then begin
                        Opp."Sales Document Type" := Opp."Sales Document Type"::" ";
                        Opp."Sales Document No." := '';
                        Opp.Modify();
                    end;
        end;
        OnAfterMoveWonLostOpportunity(SalesQuoteHeader, SalesOrderHeader, Opp);
    end;

    local procedure FilterOpportunityForQuote(var Opportunity: Record Opportunity; SalesHeader: Record "Sales Header"; InProgress: Boolean)
    begin
        Opportunity.Reset();
        Opportunity.SetCurrentKey("Sales Document Type", "Sales Document No.");
        Opportunity.SetRange("Sales Document Type", Opportunity."Sales Document Type"::Quote);
        Opportunity.SetRange("Sales Document No.", SalesHeader."No.");
        if InProgress then
            Opportunity.SetRange(Status, Opportunity.Status::"In Progress");
        OnAfterFilterOpportunityForQuote(Opportunity, SalesHeader);
    end;

    local procedure TransferQuoteToOrderLines(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header"; var SalesOrderLine: Record "Sales Line"; var SalesOrderHeader: Record "Sales Header"; Customer: Record Customer)
    var
        ATOLink: Record "Assemble-to-Order Link";
        PrepmtMgt: Codeunit "Prepayment Mgt.";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
    begin
        SalesQuoteLine.Reset();
        SalesQuoteLine.SetRange("Document Type", SalesQuoteHeader."Document Type");
        SalesQuoteLine.SetRange("Document No.", SalesQuoteHeader."No.");
        OnTransferQuoteToOrderLinesOnAfterSetFilters(SalesQuoteLine, SalesQuoteHeader);
        if SalesQuoteLine.FindSet() then
            repeat
                IsHandled := false;
                OnBeforeTransferQuoteLineToOrderLineLoop(SalesQuoteLine, SalesQuoteHeader, SalesOrderHeader, IsHandled);
                if not IsHandled then begin
                    SalesOrderLine := SalesQuoteLine;
                    SalesOrderLine."Document Type" := SalesOrderHeader."Document Type";
                    SalesOrderLine."Document No." := SalesOrderHeader."No.";
                    SalesOrderLine."Shortcut Dimension 1 Code" := SalesQuoteLine."Shortcut Dimension 1 Code";
                    SalesOrderLine."Shortcut Dimension 2 Code" := SalesQuoteLine."Shortcut Dimension 2 Code";
                    SalesOrderLine."Dimension Set ID" := SalesQuoteLine."Dimension Set ID";
                    SalesOrderLine."Transaction Type" := SalesOrderHeader."Transaction Type";
                    OnTransferQuoteToOrderLinesOnBeforeUpdatePrepaymentPct(SalesQuoteLine, SalesQuoteHeader, SalesOrderLine, SalesOrderHeader, Customer);
                    if Customer."Prepayment %" <> 0 then
                        SalesOrderLine."Prepayment %" := Customer."Prepayment %";
                    PrepmtMgt.SetSalesPrepaymentPct(SalesOrderLine, SalesOrderHeader."Posting Date");
                    SalesOrderLine.Validate("Prepayment %");
                    IsHandled := false;
                    OnTransferQuoteToOrderLinesOnBeforeDefaultDeferralCode(SalesOrderLine, SalesOrderHeader, SalesQuoteLine, IsHandled);
                    if not IsHandled then
                        if SalesOrderLine."No." <> '' then
                            SalesOrderLine.DefaultDeferralCode();
                    OnBeforeInsertSalesOrderLine(SalesOrderLine, SalesOrderHeader, SalesQuoteLine, SalesQuoteHeader);
                    SalesOrderLine.Insert();
                    OnAfterInsertSalesOrderLine(SalesOrderLine, SalesOrderHeader, SalesQuoteLine, SalesQuoteHeader);
                    ATOLink.MakeAsmOrderLinkedToSalesOrderLine(SalesQuoteLine, SalesOrderLine);
                    OnTransferQuoteToOrderLinesOnAfterATOLinkMakeAsmOrderLinkedToSalesOrderLine(SalesQuoteLine, SalesOrderLine);
                    SalesLineReserve.TransferSaleLineToSalesLine(
                      SalesQuoteLine, SalesOrderLine, SalesQuoteLine."Outstanding Qty. (Base)");
                    SalesLineReserve.VerifyQuantity(SalesOrderLine, SalesQuoteLine);
                    if SalesOrderLine.Reserve = SalesOrderLine.Reserve::Always then
                        SalesOrderLine.AutoReserve();
                    OnTransferQuoteToOrderLinesOnAfterSalesOrderLineReserve(SalesOrderLine, SalesQuoteLine);
                end;
            until SalesQuoteLine.Next() = 0;
        OnAfterTransferQuoteToOrderLines(SalesQuoteLine, SalesQuoteHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterOpportunityForQuote(var Opportunity: Record Opportunity; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferQuoteToOrderLines(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInProgressOpportunities(Opp: Record Opportunity; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesQuote(var QuoteSalesHeader: Record "Sales Header"; var OrderSalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesQuoteLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; var SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllSalesOrderLines(var SalesOrderLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveWonLostOpportunity(var SalesQuoteHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; var Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignItemChargesOnAfterItemChargeAssgntSalesSetFilters(var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; FromDocType: Enum "Sales Document Type"; FromDocNo: Code[20]; ToDocType: Enum "Sales Document Type"; ToDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveSalesQuote(var SalesQuoteHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignItemCharges(FromDocType: Option; FromDocNo: Code[20]; ToDocType: Option; ToDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyApprovalEntryQuoteToOrder(var QuoteSalesHeader: Record "Sales Header"; var OrderSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempOpportunityEntryInsert(var TempOpportunityEntry: Record "Opportunity Entry" temporary; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferQuoteLineToOrderLineLoop(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckInProgressOpportunitiesOnBeforeRunCloseOpportunityPage(var TempOpportunityEntry: Record "Opportunity Entry" temporary; Opp: Record Opportunity; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferQuoteToOrderLinesOnAfterSetFilters(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesHeader(var SalesOrderHeader: Record "Sales Header"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesQuoteLineDeleteAll(var SalesHeaderRec: Record "Sales Header"; SalesOrderHeader: Record "Sales Header"; SalesQuoteLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferQuoteToOrderLinesOnBeforeUpdatePrepaymentPct(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header"; var SalesOrderLine: Record "Sales Line"; var SalesOrderHeader: Record "Sales Header"; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferQuoteToOrderLinesOnBeforeDefaultDeferralCode(var SalesLineOrder: Record "Sales Line"; var SalesHeaderOrder: Record "Sales Header"; var SalesLineQuote: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferQuoteToOrderLinesOnAfterATOLinkMakeAsmOrderLinkedToSalesOrderLine(var SalesLineQuote: Record "Sales Line"; var SalesLineOrder: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesHeaderOnBeforeSalesOrderLineLockTable(var SalesHeaderOrder: Record "Sales Header"; var SalesHeaderQuote: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveWonLostOpportunites(var QuoteSalesHeader: Record "Sales Header"; var OrderSalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferQuoteToOrderLinesOnAfterSalesOrderLineReserve(var SalesLineOrder: Record "Sales Line"; SalesLineQuote: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCalcAmountIncludingVAT(var SalesHeader: Record "Sales Header")
    begin
    end;
}

