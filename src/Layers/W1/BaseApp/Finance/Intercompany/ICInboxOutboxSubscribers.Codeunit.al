// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using System.Telemetry;

codeunit 790 "IC Inbox Outbox Subscribers"
{
    TableNo = "IC Inbox Transaction";

    trigger OnRun()
    begin
        Rec.SetRecFilter();
        Rec."Line Action" := Rec."Line Action"::Accept;
        Rec.Modify();
        REPORT.Run(REPORT::"Complete IC Inbox Action", false, false, Rec);
        Rec.Reset();
    end;

    var
        ICOutboxExport: Codeunit "IC Outbox Export";

    local procedure IsICInboxTransactionReturnedByPartner(TransactionSource: Option): Boolean
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
    begin
        exit(TransactionSource = ICInboxTransaction."Transaction Source"::"Returned by Partner");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Move IC Trans. to Partner Comp", 'OnICInboxTransactionCreated', '', false, false)]
    local procedure AcceptOnAfterInsertICInboxTransaction(var Sender: Report "Move IC Trans. to Partner Comp"; var ICInboxTransaction: Record "IC Inbox Transaction"; PartnerCompanyName: Text)
    var
        ICPartner: Record "IC Partner";
        TempRegisteredPartner: Record "IC Partner" temporary;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ICDataExchange: Interface "IC Data Exchange";
    begin
        ICPartner.SetRange("Inbox Details", PartnerCompanyName);
        if not ICPartner.FindFirst() then
            exit;

        ICDataExchange := ICPartner."Data Exchange Type";
        ICDataExchange.GetICPartnerFromICPartner(ICPartner, TempRegisteredPartner);

        FeatureTelemetry.LogUptake('0000IIX', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IIY', ICMapping.GetFeatureTelemetryName(), 'IC Inbox Transaction Created');

        if TempRegisteredPartner."Auto. Accept Transactions" then
            if not IsICInboxTransactionReturnedByPartner(ICInboxTransaction."Transaction Source") then
                ICDataExchange.EnqueueAutoAcceptedICInboxTransaction(ICPartner, ICInboxTransaction);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ICInboxOutboxMgt", 'OnInsertICOutboxPurchDocTransaction', '', false, false)]
    local procedure AutoSendOnInsertICOutboxPurchDocTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICOutboxTransaction."Transaction No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ICInboxOutboxMgt", 'OnInsertICOutboxSalesDocTransaction', '', false, false)]
    local procedure AutoSendOnInsertICOutboxSalesDocTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICOutboxTransaction."Transaction No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ICInboxOutboxMgt", 'OnInsertICOutboxSalesInvTransaction', '', false, false)]
    local procedure AutoSendOnInsertICOutboxSalesInvTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICOutboxTransaction."Transaction No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ICInboxOutboxMgt", 'OnInsertICOutboxSalesCrMemoTransaction', '', false, false)]
    local procedure AutoSendOnInsertICOutboxSalesCrMemoTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICOutboxTransaction."Transaction No.");
    end;
}

