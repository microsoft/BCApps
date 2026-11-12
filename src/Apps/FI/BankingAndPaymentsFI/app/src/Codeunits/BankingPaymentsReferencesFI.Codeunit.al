// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Service.History;

codeunit 13580 "Banking Payments References FI"
{
    Access = Internal;
    SingleInstance = true;

    var
        PreviewModes: Dictionary of [Guid, Boolean];
#if not CLEAN30
        Feature: Codeunit "Banking Payments Feature FI";
#endif

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Header", 'OnGetPaymentReference', '', false, false)]
    local procedure GetSalesReference(var Sender: Record "Sales Invoice Header"; var PaymentReference: Text)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        PaymentReference := '';
        if SalesSetup.Get() then
            if SalesSetup."Print Payment Reference" then
                PaymentReference := Sender."Payment Reference No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Header", 'OnGetPaymentReferenceLbl', '', false, false)]
    local procedure GetSalesReferenceCaption(var PaymentReferenceLbl: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        PaymentReferenceLbl := SalesInvoiceHeader.FieldCaption("Payment Reference No.");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Service - Invoice (FI)", 'OnAfterGetPaymentReference', '', false, false)]
    local procedure GetServiceReference(ServiceInvoiceHeader: Record "Service Invoice Header"; var PaymentReference: Code[20]; var PaymentReferenceCaption: Text)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        Clear(PaymentReference);
        Clear(PaymentReferenceCaption);
        if SalesSetup.Get() then
            if SalesSetup."Print Payment Reference" and (ServiceInvoiceHeader."Payment Reference No." <> '') then begin
                PaymentReference := ServiceInvoiceHeader."Payment Reference No.";
                PaymentReferenceCaption := ServiceInvoiceHeader.FieldCaption("Payment Reference No.");
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesInvHeaderInsert', '', false, false)]
    local procedure CreateSalesReference(var SalesInvHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    var
        BankNosCheck: Codeunit "Bank Nos Check FI";
        PreviewMode: Boolean;
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if not PreviewModes.Get(SalesHeader.SystemId, PreviewMode) then
            PreviewMode := false;
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                if not PreviewMode then
                    SalesInvHeader."Payment Reference No." :=
                        BankNosCheck.CreateSalesInvReference(SalesInvHeader."No.", SalesHeader."Bill-to Customer No.");
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesInvHeader."Payment Reference No." :=
                        BankNosCheck.CreateSalesInvReference(SalesHeader."No.", SalesHeader."Bill-to Customer No.");
                    if not PreviewMode then
                        SalesInvHeader."Payment Reference No." :=
                            BankNosCheck.CreateSalesInvReference(SalesInvHeader."No.", SalesHeader."Bill-to Customer No.");
                end;
        end;
        if PreviewModes.ContainsKey(SalesHeader.SystemId) then
            PreviewModes.Remove(SalesHeader.SystemId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure CapturePreview(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if PreviewModes.ContainsKey(SalesHeader.SystemId) then
            PreviewModes.Set(SalesHeader.SystemId, PreviewMode)
        else
            PreviewModes.Add(SalesHeader.SystemId, PreviewMode);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post Prepayments", 'OnBeforeSalesInvHeaderInsert', '', false, false)]
    local procedure CreatePrepaymentReference(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header")
    var
        BankNosCheck: Codeunit "Bank Nos Check FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        SalesInvHeader."Payment Reference No." :=
            BankNosCheck.CreateSalesInvReference(SalesInvHeader."No.", SalesHeader."Bill-to Customer No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnPostLedgerEntryOnBeforeGenJnlPostLine', '', false, false)]
    local procedure CopySalesReferenceToJournal(var GenJnlLine: Record "Gen. Journal Line")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        CopyPostedReference(GenJnlLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post Prepayments", 'OnBeforeRunGenJnlPostLine', '', false, false)]
    local procedure CopyPrepaymentReferenceToJournal(var GenJnlLine: Record "Gen. Journal Line")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        CopyPostedReference(GenJnlLine);
    end;

    local procedure CopyPostedReference(var GenJournalLine: Record "Gen. Journal Line")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if GenJournalLine."Document Type" = GenJournalLine."Document Type"::Invoice then
            if SalesInvoiceHeader.Get(GenJournalLine."Document No.") then
                GenJournalLine."Payment Reference No." := SalesInvoiceHeader."Payment Reference No.";
    end;
}
