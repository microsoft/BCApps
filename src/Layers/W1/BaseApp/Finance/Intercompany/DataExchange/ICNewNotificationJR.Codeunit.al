// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Partner;
using System.Telemetry;
using Microsoft.Intercompany.GLAccount;

codeunit 533 "IC New Notification JR"
{
    Permissions = tabledata "IC Outgoing Notification" = m;

    trigger OnRun()
    var
        ICOutgoingNotification: Record "IC Outgoing Notification";
    begin
        ICOutgoingNotification.SetFilter(Status, '=%1|=%2', ICOutgoingNotification.Status::Created, ICOutgoingNotification.Status::Failed);
        if not ICOutgoingNotification.FindSet() then
            exit;

        repeat
            SendNotification(ICOutgoingNotification);
        until ICOutgoingNotification.Next() = 0;
    end;

    local procedure SendNotification(var ICOutgoingNotification: Record "IC Outgoing Notification")
    var
        ICPartner: Record "IC Partner";
        TempICIncomingNotification: Record "IC Incoming Notification" temporary;
        ICDataExchangeAPI: Codeunit "IC Data Exchange API";
        CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ContentJsonText: Text;
    begin
        ICPartner.Get(ICOutgoingNotification."Target IC Partner Code");
        TempICIncomingNotification."Operation ID" := ICOutgoingNotification."Operation ID";
        TempICIncomingNotification."Source IC Partner Code" := ICOutgoingNotification."Source IC Partner Code";
        TempICIncomingNotification."Target IC Partner Code" := ICOutgoingNotification."Target IC Partner Code";
        TempICIncomingNotification."Notified DateTime" := ICOutgoingNotification."Notified DateTime";
        ICDataExchangeAPI.CreateJsonContentFromICIncomingNotification(TempICIncomingNotification, ContentJsonText);
        if CrossIntercompanyConnector.SubmitRecordsToICPartnerFromEntityName(ICPartner, ContentJsonText, 'intercompanyIncomingNotification', 'id', TempICIncomingNotification."Operation ID") then begin
            FeatureTelemetry.LogUsage('0000MV7', ICMapping.GetFeatureTelemetryName(), NewNotificationEventNameTok);
            ICOutgoingNotification.Status := ICOutgoingNotification.Status::Notified;
            ICOutgoingNotification."Notified DateTime" := CurrentDateTime();
            ICOutgoingNotification.Modify();
        end
        else begin
            FeatureTelemetry.LogError('0000MV6', ICMapping.GetFeatureTelemetryName(), NewNotificationEventNameTok, GetLastErrorText(), GetLastErrorCallStack());
            ICOutgoingNotification.Status := ICOutgoingNotification.Status::Failed;
            ICOutgoingNotification.SetErrorMessage(GetLastErrorText());
            ICOutgoingNotification.Modify();
            Commit();
            Error(GetLastErrorText());
        end;
    end;

    var
        NewNotificationEventNameTok: Label 'IC Crossenvironment New Notification', Locked = true;
}

