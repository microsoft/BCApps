// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.GLAccount;
using System.Threading;
using System.Telemetry;

codeunit 536 "IC Auto Accept JR"
{
    Permissions = tabledata "IC Inbox Transaction" = m;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ICPartner: Record "IC Partner";
        ICInboxTransaction: Record "IC Inbox Transaction";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        if not ICPartner.Get(Rec."Record ID to Process") then
            Error(ICPartnerNotFoundErr);

        if not ICPartner."Auto. Accept Transactions" then
            exit;

        ICInboxTransaction.SetRange("IC Partner Code", ICPartner.Code);
        ICInboxTransaction.SetRange("Transaction Source", ICInboxTransaction."Transaction Source"::"Created by Partner");
        if not ICInboxTransaction.FindSet() then
            exit;

        repeat
            if LaunchAutoAccept(ICInboxTransaction) then
                FeatureTelemetry.LogUsage('0000MV5', ICMapping.GetFeatureTelemetryName(), AutoAcceptEventNameTok)
            else
                FeatureTelemetry.LogError('0000MV4', ICMapping.GetFeatureTelemetryName(), AutoAcceptEventNameTok, GetLastErrorText(), GetLastErrorCallStack());
        until ICInboxTransaction.Next() = 0;
    end;

    local procedure LaunchAutoAccept(var SelectedICInboxTransaction: Record "IC Inbox Transaction"): Boolean
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
    begin
        ICInboxTransaction.SetRange("Transaction No.", SelectedICInboxTransaction."Transaction No.");
        ICInboxTransaction.SetRange("IC Partner Code", SelectedICInboxTransaction."IC Partner Code");
        ICInboxTransaction.SetRange("Transaction Source", SelectedICInboxTransaction."Transaction Source");
        ICInboxTransaction.SetRange("Document Type", SelectedICInboxTransaction."Document Type");
        Codeunit.Run(Codeunit::"IC Inbox Outbox Subscribers", SelectedICInboxTransaction);
        if ICInboxTransaction.IsEmpty() then
            exit(true);
        exit(false);
    end;

    var
        AutoAcceptEventNameTok: Label 'IC Crossenvironment Auto Accept', Locked = true;
        ICPartnerNotFoundErr: Label 'IC Partner not found';
}

