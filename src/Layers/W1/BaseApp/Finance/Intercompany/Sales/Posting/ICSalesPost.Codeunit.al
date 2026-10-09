// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Intercompany;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;

codeunit 8505 "IC Sales-Post"
{
    SingleInstance = true;

    var
        TempICGenJnlLine: Record "Gen. Journal Line" temporary;
#if not CLEAN29
        SalesPost: Codeunit "Sales-Post";
#endif
        SalesTaxICOutboxAmt: Dictionary of [Integer, Decimal];
        ICGenJnlLineNo: Integer;

        UnpostedInvoiceDuplicateQst: Label 'An unposted invoice for order %1 exists. To avoid duplicate postings, delete order %1 or invoice %2.\Do you still want to post order %1?', Comment = '%1 = Order No.,%2 = Invoice No.';
#pragma warning disable AA0470
        InvoiceDuplicateInboxQst: Label 'An invoice for order %1 exists in the IC inbox. To avoid duplicate postings, cancel invoice %2 in the IC inbox.\Do you still want to post order %1?', Comment = '%1 = Order No.';
#pragma warning restore AA0470
        PostedInvoiceDuplicateQst: Label 'Posted invoice %1 already exists for order %2. To avoid duplicate postings, do not post order %2.\Do you still want to post order %2?', Comment = '%1 = Invoice No., %2 = Order No.';
        OrderFromSameTransactionQst: Label 'Order %1 originates from the same IC transaction as invoice %2. To avoid duplicate postings, delete order %1 or invoice %2.\Do you still want to post invoice %2?', Comment = '%1 = Order No., %2 = Invoice No.';
        DocumentFromSameTransactionQst: Label 'A document originating from the same IC transaction as document %1 exists in the IC inbox. To avoid duplicate postings, cancel document %2 in the IC inbox.\Do you still want to post document %1?', Comment = '%1 and %2 = Document No.';
        PostedInvoiceFromSameTransactionQst: Label 'Posted invoice %1 originates from the same IC transaction as invoice %2. To avoid duplicate postings, do not post invoice %2.\Do you still want to post invoice %2?', Comment = '%1 and %2 = Invoice No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterClearSalesAllVariables, '', true, false)]
    local procedure OnAfterClearSalesAllVariables()
    begin
        TempICGenJnlLine.DeleteAll();
        ICGenJnlLineNo := 0;
        Clear(SalesTaxICOutboxAmt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnCheckAndUpdateOnBeforeCheckICPartnerBlocked, '', true, false)]
    local procedure OnCheckAndUpdateOnBeforeCheckICPartnerBlockedSub(var SalesHeader: Record "Sales Header")
    begin
        CheckICPartnerBlocked(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnProcessPostingLinesOnBeforeSendICDocument, '', true, false)]
    local procedure OnProcessPostingLinesOnBeforeSendICDocumentSub(var SalesHeader: Record "Sales Header")
    begin
        SendICDocument(SalesHeader);
        UpdateHandledICInboxTransaction(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterCheckSalesDoc, '', true, false)]
    local procedure OnAfterCheckSalesDocSub(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean; PreviewMode: Boolean; var ErrorMessageMgt: Codeunit "Error Message Management")
    begin
        if ((SalesHeader."Sell-to IC Partner Code" <> '') or (SalesHeader."Bill-to IC Partner Code" <> '')) then
            CheckICDocumentDuplicatePosting(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostSalesLineOnGLAccount, '', true, false)]
    local procedure OnPostSalesLineOnGLAccount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line" temporary; InvoicePostingParameters: Record "Invoice Posting Parameters"; SuppressCommit: Boolean)
    begin
        PostGLAccICLine(SalesHeader, SalesLine, xSalesLine, InvoicePostingParameters, SuppressCommit);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnRunOnBeforePostICGenJnl, '', true, false)]
    local procedure OnRunOnBeforePostICGenJnl(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var SrcCode: Code[10]; var GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; var ReturnReceiptHeader: Record "Return Receipt Header"; var PreviewMode: Boolean)
    begin
        if ICGenJnlLineNo > 0 then
            PostICGenJnl(GenJnlPostLine);
    end;

    local procedure PostGLAccICLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; SuppressCommit: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostGLAccICLine(SalesHeader, SalesLine, ICGenJnlLineNo, IsHandled);
        if IsHandled then
            exit;

        if (SalesLine."No." <> '') and not SalesLine."System-Created Entry" then begin
            CheckGLAccDirectPosting(SalesLine);
            OnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine(SalesHeader, SalesLine, xSalesLine, ICGenJnlLineNo);
            if (SalesLine."IC Partner Code" <> '') and SalesHeader.Invoice then
                InsertICGenJnlLine(SalesHeader, xSalesLine, InvoicePostingParameters, SuppressCommit);

            OnAfterPostAccICLine(SalesLine, SuppressCommit, SalesHeader);
        end;
    end;

    local procedure InsertICGenJnlLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; SuppressCommit: Boolean)
    var
        ICGLAccount: Record "IC G/L Account";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        ICPartner: Record "IC Partner";
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertICGenJnlLine(TempICGenJnlLine, SalesHeader, SalesLine, IsHandled);
#if not CLEAN29
        SalesPost.RunOnBeforeInsertICGenJnlLine(TempICGenJnlLine, SalesHeader, SalesLine, IsHandled);
#endif
        if IsHandled then
            exit;

        SalesHeader.TestField("Sell-to IC Partner Code", '');
        SalesHeader.TestField("Bill-to IC Partner Code", '');
        SalesLine.TestField("IC Partner Ref. Type", SalesLine."IC Partner Ref. Type"::"G/L Account");
        ICGLAccount.Get(SalesLine."IC Partner Reference");
        ICGenJnlLineNo := ICGenJnlLineNo + 1;

        TempICGenJnlLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", SalesHeader."Posting Description",
            SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code", SalesLine."Dimension Set ID",
            SalesHeader."Reason Code");
        TempICGenJnlLine."Line No." := ICGenJnlLineNo;

        TempICGenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.", InvoicePostingParameters."External Document No.",
            InvoicePostingParameters."Source Code", SalesHeader."Posting No. Series");
        OnInsertICGenJnlLineOnAfterCopyDocumentFields(SalesHeader, SalesLine, TempICGenJnlLine);

        TempICGenJnlLine."Account Type" := TempICGenJnlLine."Account Type"::"IC Partner";
        TempICGenJnlLine.Validate("Account No.", SalesLine."IC Partner Code");
        TempICGenJnlLine."Source Currency Code" := SalesHeader."Currency Code";
        TempICGenJnlLine."Source Currency Amount" := TempICGenJnlLine.Amount;
        TempICGenJnlLine.Correction := SalesHeader.Correction;
        TempICGenJnlLine."Country/Region Code" := SalesHeader."VAT Country/Region Code";
        TempICGenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
        TempICGenJnlLine."Source No." := SalesHeader."Bill-to Customer No.";
        TempICGenJnlLine."Source Line No." := SalesLine."Line No.";
        TempICGenJnlLine.Validate("Bal. Account Type", TempICGenJnlLine."Bal. Account Type"::"G/L Account");
        TempICGenJnlLine.Validate("Bal. Account No.", SalesLine."No.");
        TempICGenJnlLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        TempICGenJnlLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        TempICGenJnlLine."Dimension Set ID" := SalesLine."Dimension Set ID";

        ValidateICPartnerBusPostingGroups(SalesLine);
        TempICGenJnlLine.Validate("Bal. VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        TempICGenJnlLine."IC Partner Code" := SalesLine."IC Partner Code";
        TempICGenJnlLine."IC Account Type" := TempICGenJnlLine."IC Account Type"::"G/L Account";
        TempICGenJnlLine."IC Account No." := SalesLine."IC Partner Reference";
        TempICGenJnlLine."IC Direction" := TempICGenJnlLine."IC Direction"::Outgoing;
        ICPartner.Get(SalesLine."IC Partner Code");
        if ICPartner."Cost Distribution in LCY" and (SalesLine."Currency Code" <> '') then begin
            TempICGenJnlLine."Currency Code" := '';
            TempICGenJnlLine."Currency Factor" := 0;
            Currency.Get(SalesLine."Currency Code");
            if SalesHeader.IsCreditDocType() then
                TempICGenJnlLine.Amount :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      SalesHeader."Posting Date", SalesLine."Currency Code",
                      SalesLine.Amount, SalesHeader."Currency Factor"))
            else
                TempICGenJnlLine.Amount :=
                  -Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      SalesHeader."Posting Date", SalesLine."Currency Code",
                      SalesLine.Amount, SalesHeader."Currency Factor"));
        end else begin
            Currency.InitRoundingPrecision();
            TempICGenJnlLine."Currency Code" := SalesHeader."Currency Code";
            TempICGenJnlLine."Currency Factor" := SalesHeader."Currency Factor";
            if SalesHeader.IsCreditDocType() then
                TempICGenJnlLine.Amount := SalesLine.Amount
            else
                TempICGenJnlLine.Amount := -SalesLine.Amount;
        end;
        if TempICGenJnlLine."Bal. VAT %" <> 0 then
            TempICGenJnlLine.Amount := Round(TempICGenJnlLine.Amount * (1 + TempICGenJnlLine."Bal. VAT %" / 100), Currency."Amount Rounding Precision");
        StoreSalesTaxICOutboxAmount(SalesLine, SalesHeader, ICPartner);
        TempICGenJnlLine.Validate(Amount);
        TempICGenJnlLine."Journal Template Name" := SalesLine.GetJnlTemplateName();
        OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(TempICGenJnlLine, SalesHeader, SalesLine, SuppressCommit);
        TempICGenJnlLine.Insert();
    end;

    local procedure StoreSalesTaxICOutboxAmount(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ICPartner: Record "IC Partner")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        GrossAmount: Decimal;
    begin
        if SalesLine."VAT Calculation Type" <> SalesLine."VAT Calculation Type"::"Sales Tax" then
            exit;

        GrossAmount := SalesLine."Amount Including VAT";
        if ICPartner."Cost Distribution in LCY" and (SalesLine."Currency Code" <> '') then begin
            if SalesHeader.IsCreditDocType() then
                SalesTaxICOutboxAmt.Set(ICGenJnlLineNo, Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                        SalesHeader."Posting Date", SalesLine."Currency Code",
                        GrossAmount, SalesHeader."Currency Factor")))
            else
                SalesTaxICOutboxAmt.Set(ICGenJnlLineNo, -Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                        SalesHeader."Posting Date", SalesLine."Currency Code",
                        GrossAmount, SalesHeader."Currency Factor")));
        end else
            if SalesHeader.IsCreditDocType() then
                SalesTaxICOutboxAmt.Set(ICGenJnlLineNo, GrossAmount)
            else
                SalesTaxICOutboxAmt.Set(ICGenJnlLineNo, -GrossAmount);
    end;

    local procedure ValidateICPartnerBusPostingGroups(var SalesLine: Record "Sales Line")
    var
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateICPartnerBusPostingGroups(TempICGenJnlLine, SalesLine, IsHandled);
#if not CLEAN29
        SalesPost.RunOnBeforeValidateICPartnerBusPostingGroups(TempICGenJnlLine, SalesLine, IsHandled);
#endif
        if IsHandled then
            exit;

        Vendor.SetLoadFields("Gen. Bus. Posting Group", "VAT Bus. Posting Group");
        Vendor.SetCurrentKey("IC Partner Code");
        Vendor.SetRange("IC Partner Code", SalesLine."IC Partner Code");
        if Vendor.FindFirst() then begin
            TempICGenJnlLine.Validate("Bal. Gen. Bus. Posting Group", Vendor."Gen. Bus. Posting Group");
            TempICGenJnlLine.Validate("Bal. VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        end;
    end;

    local procedure PostICGenJnl(var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        ICInOutBoxMgt: Codeunit ICInboxOutboxMgt;
        ICOutboxExport: Codeunit "IC Outbox Export";
        ICTransactionNo: Integer;
        OriginalAmount: Decimal;
        OutboxAmount: Decimal;
    begin
        TempICGenJnlLine.Reset();
        TempICGenJnlLine.SetFilter(Amount, '<>%1', 0);
        if TempICGenJnlLine.Find('-') then
            repeat
                ICTransactionNo := ICInOutBoxMgt.CreateOutboxJnlTransaction(TempICGenJnlLine, false);
                OriginalAmount := TempICGenJnlLine.Amount;
                if SalesTaxICOutboxAmt.Get(TempICGenJnlLine."Line No.", OutboxAmount) then
                    TempICGenJnlLine.Amount := OutboxAmount;
                ICInOutBoxMgt.CreateOutboxJnlLine(ICTransactionNo, 1, TempICGenJnlLine);
                TempICGenJnlLine.Amount := OriginalAmount;
                ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICTransactionNo);
                if TempICGenJnlLine.Amount <> 0 then
                    GenJnlPostLine.RunWithCheck(TempICGenJnlLine);
            until TempICGenJnlLine.Next() = 0;
    end;

    local procedure CheckICDocumentDuplicatePosting(SalesHeader: Record "Sales Header")
    var
        SalesHeader2: Record "Sales Header";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        SalesInvHeader2: Record "Sales Invoice Header";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
        ShouldCheckPosted: Boolean;
        ShouldCheckUnposted: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckICDocumentDuplicatePosting(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if not SalesHeader.Invoice then
            exit;

        ShouldCheckPosted := SalesHeader."IC Direction" = SalesHeader."IC Direction"::Outgoing;
        OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted(SalesHeader, ShouldCheckPosted);
        if ShouldCheckPosted then begin
            SalesInvHeader2.SetRange("Your Reference", SalesHeader."No.");
            SalesInvHeader2.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
            SalesInvHeader2.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
            if SalesInvHeader2.FindFirst() then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(PostedInvoiceDuplicateQst, SalesInvHeader2."No.", SalesHeader."No."), true)
                then
                    Error('');
        end;

        ShouldCheckUnposted := SalesHeader."IC Direction" = SalesHeader."IC Direction"::Incoming;
        OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted(SalesHeader, ShouldCheckUnposted);
        if ShouldCheckUnposted then begin
            if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
                SalesHeader2.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                SalesHeader2.SetRange("External Document No.", SalesHeader."External Document No.");
                if SalesHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(UnpostedInvoiceDuplicateQst, SalesHeader."No.", SalesHeader2."No."), true)
                    then
                        Error('');
                ICInboxSalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                ICInboxSalesHeader.SetRange("No.", SalesHeader."External Document No.");
                if ICInboxSalesHeader.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(InvoiceDuplicateInboxQst, SalesHeader."No.", ICInboxSalesHeader."No."), true)
                    then
                        Error('');
                SalesInvHeader2.SetRange("External Document No.", SalesHeader."External Document No.");
                if SalesInvHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostedInvoiceDuplicateQst, SalesInvHeader2."No.", SalesHeader."No."), true)
                    then
                        Error('');
            end;
            if (SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice) and (SalesHeader."External Document No." <> '') then begin
                SalesHeader2.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader2.SetRange("External Document No.", SalesHeader."External Document No.");
                if SalesHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(OrderFromSameTransactionQst, SalesHeader2."No.", SalesHeader."No."), true)
                    then
                        Error('');
                ICInboxSalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                ICInboxSalesHeader.SetRange("No.", SalesHeader."External Document No.");
                if ICInboxSalesHeader.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(DocumentFromSameTransactionQst, SalesHeader."No.", ICInboxSalesHeader."No."), true)
                    then
                        Error('');
                SalesInvHeader2.SetRange("External Document No.", SalesHeader."External Document No.");
                if SalesInvHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostedInvoiceFromSameTransactionQst, SalesInvHeader2."No.", SalesHeader."No."), true)
                    then
                        Error('');
                if (SalesHeader."Your Reference" <> '') and (StrLen(SalesHeader."Your Reference") <= MaxStrLen(SalesInvHeader2."Order No.")) then begin
                    SalesInvHeader2.Reset();
                    SalesInvHeader2.SetRange("Order No.", SalesHeader."Your Reference");
                    SalesInvHeader2.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
                    SalesInvHeader2.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
                    if SalesInvHeader2.FindFirst() then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(PostedInvoiceFromSameTransactionQst, SalesInvHeader2."No.", SalesHeader."No."), true)
                        then
                            Error('');
                end;
            end;
        end;
    end;

    local procedure CheckICPartnerBlocked(SalesHeader: Record "Sales Header")
    var
        ICPartner: Record "IC Partner";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckICPartnerBlocked(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader."Sell-to IC Partner Code" <> '' then
            if ICPartner.Get(SalesHeader."Sell-to IC Partner Code") then
                ICPartner.TestField(Blocked, false);
        if SalesHeader."Bill-to IC Partner Code" <> '' then
            if ICPartner.Get(SalesHeader."Bill-to IC Partner Code") then
                ICPartner.TestField(Blocked, false);
    end;

    local procedure SendICDocument(var SalesHeader: Record "Sales Header")
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        IsHandled: Boolean;
        ModifyHeader: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendICDocument(SalesHeader, ModifyHeader, IsHandled);
#if not CLEAN29
        SalesPost.RunOnBeforeSendICDocument(SalesHeader, ModifyHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        if SalesHeader."Send IC Document" and (SalesHeader."IC Status" = SalesHeader."IC Status"::New) and (SalesHeader."IC Direction" = SalesHeader."IC Direction"::Outgoing) and
            (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order"])
        then begin
            SalesHeader.Modify();
            ICInboxOutboxMgt.SendSalesDoc(SalesHeader, true);
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
            IsHandled := false;
            OnSendICDocumentOnBeforeSetICStatus(SalesHeader, IsHandled);
#if not CLEAN29
            SalesPost.RunOnSendICDocumentOnBeforeSetICStatus(SalesHeader, IsHandled);
#endif
            if not IsHandled then
                SalesHeader."IC Status" := SalesHeader."IC Status"::Pending;
            ModifyHeader := true;
        end;
    end;

    local procedure UpdateHandledICInboxTransaction(SalesHeader: Record "Sales Header")
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateHandledICInboxTransaction(SalesHeader, IsHandled);
#if not CLEAN29
        SalesPost.RunOnBeforeUpdateHandledICInboxTransaction(SalesHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        if SalesHeader."IC Direction" = SalesHeader."IC Direction"::Incoming then begin
            HandledICInboxTrans.SetRange("Document No.", SalesHeader."IC Reference Document No.");
            Customer.Get(SalesHeader."Sell-to Customer No.");
            HandledICInboxTrans.SetRange("IC Partner Code", Customer."IC Partner Code");
            HandledICInboxTrans.LockTable();
            if HandledICInboxTrans.FindFirst() then begin
                HandledICInboxTrans.Status := HandledICInboxTrans.Status::Posted;
                HandledICInboxTrans.Modify();
            end;
        end;
    end;

    local procedure CheckGLAccDirectPosting(SalesLine: Record "Sales Line")
    var
        GLAccount: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccDirectPosting(SalesLine, IsHandled);
        if IsHandled then
            exit;

        GLAccount.Get(SalesLine."No.");
        GLAccount.TestField("Direct Posting", true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterFinalizePostingOnBeforeCommit, '', true, false)]
    local procedure OnAfterFinalizePostingOnBeforeCommit(var SalesHeader: Record "Sales Header")
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        ICInboxOutboxMgt.CheckPermissionToSendICTransaction(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnFinalizePostingOnCreateOutboxSalesTrans, '', true, false)]
    local procedure OnFinalizePostingOnCreateOutboxSalesTrans(var SalesHeader: Record "Sales Header"; EverythingInvoiced: Boolean; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        if SalesHeader.Invoice and SalesHeader."Send IC Document" then
            if SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice] then
                ICInboxOutboxMgt.CreateOutboxSalesInvTrans(SalesInvoiceHeader)
            else
                ICInboxOutboxMgt.CreateOutboxSalesCrMemoTrans(SalesCrMemoHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAccICLine(SalesLine: Record "Sales Line"; CommitIsSupressed: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccDirectPosting(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICDocumentDuplicatePosting(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertICGenJnlLine(var ICGenJnlLine: Record "Gen. Journal Line" temporary; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGLAccICLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ICGenJnlLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendICDocument(var SalesHeader: Record "Sales Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateHandledICInboxTransaction(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICGenJnlLineOnAfterCopyDocumentFields(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempICGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(var TempICGenJournalLine: Record "Gen. Journal Line" temporary; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; ICGenJnlLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateICPartnerBusPostingGroups(var TempICGenJnlLine: Record "Gen. Journal Line" temporary; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted(SalesHeader: Record "Sales Header"; var ShouldCheckPosted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted(SalesHeader: Record "Sales Header"; var ShouldCheckUnposted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICPartnerBlocked(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendICDocumentOnBeforeSetICStatus(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}
