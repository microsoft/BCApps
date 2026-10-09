// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

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
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

codeunit 8452 "IC Purch.-Post"
{
    SingleInstance = true;

    var
        TempICGenJnlLine: Record "Gen. Journal Line" temporary;
#if not CLEAN29
        PurchPost: Codeunit "Purch.-Post";
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterClearAllVariables, '', true, false)]
    local procedure OnAfterClearAllVariables()
    begin
        TempICGenJnlLine.DeleteAll();
        ICGenJnlLineNo := 0;
        Clear(SalesTaxICOutboxAmt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnCheckAndUpdateOnBeforeLockTables, '', true, false)]
    local procedure OnCheckAndUpdateOnBeforeLockTables(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean)
    begin
        CheckICPartnerBlocked(PurchHeader);
        SendICDocument(PurchHeader, ModifyHeader);
        UpdateHandledICInboxTransaction(PurchHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterCheckPostrestrictions, '', true, false)]
    local procedure OnAfterCheckPostrestrictions(var PurchHeader: Record "Purchase Header")
    begin
        if ((PurchHeader."Buy-from IC Partner Code" <> '') or (PurchHeader."Pay-to IC Partner Code" <> '')) then
            CheckICDocumentDuplicatePosting(PurchHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnPostPurchLineOnGLAccount, '', true, false)]
    local procedure OnPostPurchLineOnGLAccount(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line" temporary; var PurchLineACY: Record "Purchase Line"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var InvoicePostingInterface: Interface "Invoice Posting"; var InvoicePostingParameters: Record "Invoice Posting Parameters"; SuppressCommit: Boolean)
    begin
        PostGLAccICLine(
            PurchHeader, PurchLine, xPurchLine, PurchLineACY, PurchInvHeader, PurchCrMemoHeader,
            InvoicePostingInterface, InvoicePostingParameters, SuppressCommit);
    end;

    local procedure PostGLAccICLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line" temporary; PurchLineACY: Record "Purchase Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var InvoicePostingInterface: Interface "Invoice Posting"; InvoicePostingParameters: Record "Invoice Posting Parameters"; SuppressCommit: Boolean)
    var
        JobPurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostGLAccICLine(PurchHeader, PurchLine, ICGenJnlLineNo, IsHandled);
#if not CLEAN29
        PurchPost.RunOnBeforePostGLAccICLine(PurchHeader, PurchLine, ICGenJnlLineNo, IsHandled);
#endif
        if IsHandled then
            exit;

        if (PurchLine."No." <> '') and not PurchLine."System-Created Entry" then begin
            CheckGLAccDirectPosting(PurchLine);
            if (PurchLine."Job No." <> '') and (PurchLine."Qty. to Invoice" <> 0) then begin
                IsHandled := false;
                OnPostGLAccICLineOnBeforeCreateJobPurchLine(PurchHeader, PurchLine, IsHandled);
#if not CLEAN29
                PurchPost.RunOnPostGLAccICLineOnBeforeCreateJobPurchLine(PurchHeader, PurchLine, IsHandled);
#endif
                if not IsHandled then begin
                    CreateJobPurchLine(JobPurchLine, PurchLine, PurchHeader."Prices Including VAT");
                    OnPostGLAccICLineOnAfterCreateJobPurchLine(PurchHeader);
#if not CLEAN29
                    PurchPost.RunOnPostGLAccICLineOnAfterCreateJobPurchLine(PurchHeader);
#endif
                    InvoicePostingInterface.PrepareJobLine(PurchHeader, JobPurchLine, PurchLineACY);
                end;
            end;
            OnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine(PurchHeader, PurchLine, xPurchLine, ICGenJnlLineNo);
#if not CLEAN29
            PurchPost.RunOnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine(PurchHeader, PurchLine, xPurchLine, ICGenJnlLineNo);
#endif
            if (PurchLine."IC Partner Code" <> '') and PurchHeader.Invoice then
                InsertICGenJnlLine(PurchHeader, xPurchLine, InvoicePostingParameters, SuppressCommit);

            OnAfterPostAccICLine(PurchLine, SuppressCommit, PurchHeader, PurchInvHeader, PurchCrMemoHeader);
#if not CLEAN29
            PurchPost.RunOnAfterPostAccICLine(PurchLine, SuppressCommit, PurchHeader, PurchInvHeader, PurchCrMemoHeader);
#endif
        end;
    end;

    local procedure InsertICGenJnlLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; SuppressCommit: Boolean)
    var
        ICGLAccount: Record "IC G/L Account";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        ICPartner: Record "IC Partner";
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertICGenJnlLine(PurchHeader, PurchLine, ICGenJnlLineNo, IsHandled);
#if not CLEAN29
        PurchPost.RunOnBeforeInsertICGenJnlLine(PurchHeader, PurchLine, ICGenJnlLineNo, IsHandled);
#endif
        if IsHandled then
            exit;

        PurchHeader.TestField("Buy-from IC Partner Code", '');
        PurchHeader.TestField("Pay-to IC Partner Code", '');
        PurchLine.TestField("IC Partner Ref. Type", PurchLine."IC Partner Ref. Type"::"G/L Account");
        ICGLAccount.Get(PurchLine."IC Partner Reference");
        ICGenJnlLineNo := ICGenJnlLineNo + 1;

        TempICGenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", PurchHeader."Posting Description",
            PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code", PurchLine."Dimension Set ID",
            PurchHeader."Reason Code");
        TempICGenJnlLine."Line No." := ICGenJnlLineNo;

        TempICGenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.", InvoicePostingParameters."External Document No.",
            InvoicePostingParameters."Source Code", PurchHeader."Posting No. Series");
        OnInsertICGenJnlLineOnAfterCopyDocumentFields(PurchHeader, PurchLine, TempICGenJnlLine);
#if not CLEAN29
        PurchPost.RunOnInsertICGenJnlLineOnAfterCopyDocumentFields(PurchHeader, PurchLine, TempICGenJnlLine);
#endif

        TempICGenJnlLine."Account Type" := TempICGenJnlLine."Account Type"::"IC Partner";
        TempICGenJnlLine.Validate("Account No.", PurchLine."IC Partner Code");
        TempICGenJnlLine."Source Currency Code" := PurchHeader."Currency Code";
        TempICGenJnlLine."Source Currency Amount" := TempICGenJnlLine.Amount;
        TempICGenJnlLine.Correction := PurchHeader.Correction;
        TempICGenJnlLine."Country/Region Code" := PurchHeader."VAT Country/Region Code";
        TempICGenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
        TempICGenJnlLine."Source No." := PurchHeader."Pay-to Vendor No.";
        TempICGenJnlLine."Source Line No." := PurchLine."Line No.";
        TempICGenJnlLine.Validate("Bal. Account Type", TempICGenJnlLine."Bal. Account Type"::"G/L Account");
        TempICGenJnlLine.Validate("Bal. Account No.", PurchLine."No.");
        TempICGenJnlLine."Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        TempICGenJnlLine."Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        TempICGenJnlLine."Dimension Set ID" := PurchLine."Dimension Set ID";

        ValidateICPartnerBusPostingGroups(PurchLine);
        TempICGenJnlLine.Validate("Bal. VAT Prod. Posting Group", PurchLine."VAT Prod. Posting Group");
        TempICGenJnlLine."IC Partner Code" := PurchLine."IC Partner Code";
        TempICGenJnlLine."IC Account Type" := TempICGenJnlLine."IC Account Type"::"G/L Account";
        TempICGenJnlLine."IC Account No." := PurchLine."IC Partner Reference";
        TempICGenJnlLine."IC Direction" := TempICGenJnlLine."IC Direction"::Outgoing;
        ICPartner.Get(PurchLine."IC Partner Code");
        if ICPartner."Cost Distribution in LCY" and (PurchLine."Currency Code" <> '') then begin
            TempICGenJnlLine."Currency Code" := '';
            TempICGenJnlLine."Currency Factor" := 0;
            Currency.Get(PurchLine."Currency Code");
            if PurchHeader.IsCreditDocType() then
                TempICGenJnlLine.Amount :=
                  -Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PurchHeader."Posting Date", PurchLine."Currency Code",
                      PurchLine.Amount, PurchHeader."Currency Factor"))
            else
                TempICGenJnlLine.Amount :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PurchHeader."Posting Date", PurchLine."Currency Code",
                      PurchLine.Amount, PurchHeader."Currency Factor"));
        end else begin
            Currency.InitRoundingPrecision();
            TempICGenJnlLine."Currency Code" := PurchHeader."Currency Code";
            TempICGenJnlLine."Currency Factor" := PurchHeader."Currency Factor";
            if PurchHeader.IsCreditDocType() then
                TempICGenJnlLine.Amount := -PurchLine.Amount
            else
                TempICGenJnlLine.Amount := PurchLine.Amount;
        end;
        if TempICGenJnlLine."Bal. VAT %" <> 0 then
            TempICGenJnlLine.Amount := Round(TempICGenJnlLine.Amount * (1 + TempICGenJnlLine."Bal. VAT %" / 100), Currency."Amount Rounding Precision");
        StoreSalesTaxICOutboxAmount(PurchLine, PurchHeader, ICPartner);
        TempICGenJnlLine.Validate(Amount);
        TempICGenJnlLine."Journal Template Name" := PurchLine.GetJnlTemplateName();
        OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(TempICGenJnlLine, PurchHeader, PurchLine, SuppressCommit);
#if not CLEAN29
        PurchPost.RunOnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(TempICGenJnlLine, PurchHeader, PurchLine, SuppressCommit);
#endif
        TempICGenJnlLine.Insert();
    end;

    local procedure StoreSalesTaxICOutboxAmount(PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; ICPartner: Record "IC Partner")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        GrossAmount: Decimal;
    begin
        if PurchLine."VAT Calculation Type" <> PurchLine."VAT Calculation Type"::"Sales Tax" then
            exit;

        GrossAmount := PurchLine."Amount Including VAT" + PurchLine."Tax To Be Expensed";
        if ICPartner."Cost Distribution in LCY" and (PurchLine."Currency Code" <> '') then begin
            if PurchHeader.IsCreditDocType() then
                SalesTaxICOutboxAmt.Set(ICGenJnlLineNo, -Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                        PurchHeader."Posting Date", PurchLine."Currency Code",
                        GrossAmount, PurchHeader."Currency Factor")))
            else
                SalesTaxICOutboxAmt.Set(ICGenJnlLineNo, Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                        PurchHeader."Posting Date", PurchLine."Currency Code",
                        GrossAmount, PurchHeader."Currency Factor")));
        end else
            if PurchHeader.IsCreditDocType() then
                SalesTaxICOutboxAmt.Set(ICGenJnlLineNo, -GrossAmount)
            else
                SalesTaxICOutboxAmt.Set(ICGenJnlLineNo, GrossAmount);
    end;

    local procedure ValidateICPartnerBusPostingGroups(var PurchaseLine: Record "Purchase Line")
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateICPartnerBusPostingGroups(TempICGenJnlLine, PurchaseLine, IsHandled);
#if not CLEAN29
        PurchPost.RunOnBeforeValidateICPartnerBusPostingGroups(TempICGenJnlLine, PurchaseLine, IsHandled);
#endif
        if IsHandled then
            exit;

        Customer.SetLoadFields("Gen. Bus. Posting Group", "VAT Bus. Posting Group");
        Customer.SetCurrentKey("IC Partner Code");
        Customer.SetRange("IC Partner Code", PurchaseLine."IC Partner Code");
        if Customer.FindFirst() then begin
            TempICGenJnlLine.Validate("Bal. Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
            TempICGenJnlLine.Validate("Bal. VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnRunOnAfterPostInvoice, '', true, false)]
    local procedure OnRunOnAfterPostInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var ReturnShipmentHeader: Record "Return Shipment Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PreviewMode: Boolean; var Window: Dialog; SrcCode: Code[10]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        if ICGenJnlLineNo > 0 then
            PostICGenJnl(GenJnlPostLine);
    end;

    local procedure PostICGenJnl(var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICOutboxExport: Codeunit "IC Outbox Export";
        ICTransactionNo: Integer;
        OriginalAmount: Decimal;
        OutboxAmount: Decimal;
    begin
        TempICGenJnlLine.Reset();
        if TempICGenJnlLine.Find('-') then
            repeat
                ICTransactionNo := ICInboxOutboxMgt.CreateOutboxJnlTransaction(TempICGenJnlLine, false);
                OriginalAmount := TempICGenJnlLine.Amount;
                if SalesTaxICOutboxAmt.Get(TempICGenJnlLine."Line No.", OutboxAmount) then
                    TempICGenJnlLine.Amount := OutboxAmount;
                ICInboxOutboxMgt.CreateOutboxJnlLine(ICTransactionNo, 1, TempICGenJnlLine);
                TempICGenJnlLine.Amount := OriginalAmount;
                ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICTransactionNo);
                if TempICGenJnlLine.Amount <> 0 then
                    GenJnlPostLine.RunWithCheck(TempICGenJnlLine);
            until TempICGenJnlLine.Next() = 0;
    end;

    local procedure CheckICDocumentDuplicatePosting(PurchHeader: Record "Purchase Header")
    var
        PurchHeader2: Record "Purchase Header";
        ICInboxPurchHeader: Record "IC Inbox Purchase Header";
        PurchInvHeader2: Record "Purch. Inv. Header";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
        ShouldCheckPosted: Boolean;
        ShouldCheckUnposted: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckICDocumentDuplicatePosting(PurchHeader, IsHandled);
#if not CLEAN29
        PurchPost.RunOnBeforeCheckICDocumentDuplicatePosting(PurchHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        if not PurchHeader.Invoice then
            exit;

        ShouldCheckPosted := PurchHeader."IC Direction" = PurchHeader."IC Direction"::Outgoing;
        OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted(PurchHeader, ShouldCheckPosted);
#if not CLEAN29
        PurchPost.RunOnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted(PurchHeader, ShouldCheckPosted);
#endif
        if ShouldCheckPosted then begin
            PurchInvHeader2.SetRange("Your Reference", PurchHeader."No.");
            PurchInvHeader2.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
            PurchInvHeader2.SetRange("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
            if PurchInvHeader2.FindFirst() then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(PostedInvoiceDuplicateQst, PurchInvHeader2."No.", PurchHeader."No."), true)
                then
                    Error('');
        end;

        ShouldCheckUnposted := PurchHeader."IC Direction" = PurchHeader."IC Direction"::Incoming;
        OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted(PurchHeader, ShouldCheckUnposted);
#if not CLEAN29
        PurchPost.RunOnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted(PurchHeader, ShouldCheckUnposted);
#endif
        if ShouldCheckUnposted then begin
            if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then begin
                PurchHeader2.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
                PurchHeader2.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if PurchHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(UnpostedInvoiceDuplicateQst, PurchHeader."No.", PurchHeader2."No."), true)
                    then
                        Error('');
                ICInboxPurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
                ICInboxPurchHeader.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if ICInboxPurchHeader.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(InvoiceDuplicateInboxQst, PurchHeader."No.", ICInboxPurchHeader."No."), true)
                    then
                        Error('');
                PurchInvHeader2.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if PurchInvHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostedInvoiceDuplicateQst, PurchInvHeader2."No.", PurchHeader."No."), true)
                    then
                        Error('');
            end;
            if (PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice) and (PurchHeader."Vendor Order No." <> '') then begin
                PurchHeader2.SetRange("Document Type", PurchHeader."Document Type"::Order);
                PurchHeader2.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if PurchHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(OrderFromSameTransactionQst, PurchHeader2."No.", PurchHeader."No."), true)
                    then
                        Error('');
                ICInboxPurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                ICInboxPurchHeader.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if ICInboxPurchHeader.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(DocumentFromSameTransactionQst, PurchHeader."No.", ICInboxPurchHeader."No."), true)
                    then
                        Error('');
                PurchInvHeader2.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if PurchInvHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostedInvoiceFromSameTransactionQst, PurchInvHeader2."No.", PurchHeader."No."), true)
                    then
                        Error('');
                if (PurchHeader."Your Reference" <> '') and (StrLen(PurchHeader."Your Reference") <= MaxStrLen(PurchInvHeader2."Order No.")) then begin
                    PurchInvHeader2.Reset();
                    PurchInvHeader2.SetRange("Order No.", PurchHeader."Your Reference");
                    PurchInvHeader2.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
                    PurchInvHeader2.SetRange("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
                    if PurchInvHeader2.FindFirst() then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(PostedInvoiceFromSameTransactionQst, PurchInvHeader2."No.", PurchHeader."No."), true)
                        then
                            Error('');
                end;
            end;
        end;
    end;

    local procedure CheckICPartnerBlocked(PurchHeader: Record "Purchase Header")
    var
        ICPartner: Record "IC Partner";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckICPartnerBlocked(PurchHeader, IsHandled);
#if not CLEAN29
        PurchPost.RunOnBeforeCheckICPartnerBlocked(PurchHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        if PurchHeader."Buy-from IC Partner Code" <> '' then
            if ICPartner.Get(PurchHeader."Buy-from IC Partner Code") then
                ICPartner.TestField(Blocked, false);
        if PurchHeader."Pay-to IC Partner Code" <> '' then
            if ICPartner.Get(PurchHeader."Pay-to IC Partner Code") then
                ICPartner.TestField(Blocked, false);
    end;

    local procedure SendICDocument(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean)
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        IsHandled: Boolean;
    begin
        OnBeforeSendICDocument(PurchHeader, ModifyHeader, IsHandled);
#if not CLEAN29
        PurchPost.RunOnBeforeSendICDocument(PurchHeader, ModifyHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        if PurchHeader."Send IC Document" and (PurchHeader."IC Status" = PurchHeader."IC Status"::New) and (PurchHeader."IC Direction" = PurchHeader."IC Direction"::Outgoing) and
            (PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"])
        then begin
            ICInboxOutboxMgt.SendPurchDoc(PurchHeader, true);
            PurchHeader."IC Status" := PurchHeader."IC Status"::Pending;
            ModifyHeader := true;
        end;
    end;

    local procedure UpdateHandledICInboxTransaction(PurchHeader: Record "Purchase Header")
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateHandledICInboxTransaction(PurchHeader, IsHandled);
#if not CLEAN29
        PurchPost.RunOnBeforeUpdateHandledICInboxTransaction(PurchHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        if PurchHeader."IC Direction" = PurchHeader."IC Direction"::Incoming then begin
            case PurchHeader."Document Type" of
                PurchHeader."Document Type"::Invoice:
                    HandledICInboxTrans.SetRange("Document No.", PurchHeader."Vendor Invoice No.");
                PurchHeader."Document Type"::Order:
                    HandledICInboxTrans.SetRange("Document No.", PurchHeader."Vendor Order No.");
                PurchHeader."Document Type"::"Credit Memo":
                    HandledICInboxTrans.SetRange("Document No.", PurchHeader."Vendor Cr. Memo No.");
                PurchHeader."Document Type"::"Return Order":
                    HandledICInboxTrans.SetRange("Document No.", PurchHeader."Vendor Order No.");
            end;
            Vendor.Get(PurchHeader."Buy-from Vendor No.");
            HandledICInboxTrans.SetRange("IC Partner Code", Vendor."IC Partner Code");
            HandledICInboxTrans.LockTable();
            if HandledICInboxTrans.FindFirst() then begin
                HandledICInboxTrans.Status := HandledICInboxTrans.Status::Posted;
                HandledICInboxTrans.Modify();
            end;
        end;
    end;

    local procedure CheckGLAccDirectPosting(PurchaseLine: Record "Purchase Line")
    var
        GLAccount: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccDirectPosting(PurchaseLine, IsHandled);
#if not CLEAN29
        PurchPost.RunOnBeforeCheckGLAccDirectPosting(PurchaseLine, IsHandled);
#endif
        if IsHandled then
            exit;

        GLAccount.Get(PurchaseLine."No.");
        GLAccount.TestField("Direct Posting");
    end;

    /// <summary>
    /// Recalculates and updates Direct Unit Cost of the purchase line related to a job
    /// </summary>
    /// <remarks>
    /// PurchLine2 should have a job no. specified
    /// When purchase document has prices with VAT and VAT Posting Setup on the purchase line is not "Full VAT", field "Direct Unit Cost" is re-calculated. Otherwise it's 0 (zero)
    /// </remarks>
    /// <param name="JobPurchLine2">Return Value: Record to store information of purchase line related to a job</param>
    /// <param name="PurchLine2">The purchase line of the document that is being posted.</param>
    /// <param name="PricesIncludingVAT">Specifies if the purchase document that is being posted has prices with VAT</param>
    procedure CreateJobPurchLine(var JobPurchLine2: Record "Purchase Line"; PurchLine2: Record "Purchase Line"; PricesIncludingVAT: Boolean)
    begin
        JobPurchLine2 := PurchLine2;
        if PricesIncludingVAT then
            if JobPurchLine2."VAT Calculation Type" = JobPurchLine2."VAT Calculation Type"::"Full VAT" then
                JobPurchLine2."Direct Unit Cost" := 0
            else
                JobPurchLine2."Direct Unit Cost" := JobPurchLine2."Direct Unit Cost" / (1 + JobPurchLine2."VAT %" / 100);

        OnAfterCreateJobPurchLine(JobPurchLine2, PurchLine2);
#if not CLEAN29
        PurchPost.RunOnAfterCreateJobPurchLine(JobPurchLine2, PurchLine2);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAccICLine(PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean; var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccDirectPosting(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICDocumentDuplicatePosting(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertICGenJnlLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGLAccICLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendICDocument(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateHandledICInboxTransaction(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICGenJnlLineOnAfterCopyDocumentFields(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var TempICGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(var TempICGenJournalLine: Record "Gen. Journal Line" temporary; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; ICGenJnlLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGLAccICLineOnAfterCreateJobPurchLine(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateICPartnerBusPostingGroups(var TempICGenJnlLine: Record "Gen. Journal Line" temporary; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted(PurchHeader: Record "Purchase Header"; var ShouldCheckPosted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted(PurchHeader: Record "Purchase Header"; var ShouldCheckUnposted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGLAccICLineOnBeforeCreateJobPurchLine(var PurchHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICPartnerBlocked(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateJobPurchLine(var JobPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;
}
