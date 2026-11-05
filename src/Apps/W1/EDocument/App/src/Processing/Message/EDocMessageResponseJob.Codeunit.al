// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using System.Telemetry;
using System.Threading;

codeunit 6539 "E-Doc. Message Response Job"
{
    Access = Internal;
    TableNo = "Job Queue Entry";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        EDocumentMessage: Record "E-Document Message";
        Telemetry: Codeunit Telemetry;
        TelemetryDimensions: Dictionary of [Text, Text];
        LastErrorInfo: ErrorInfo;
        LastErrorText: Text;
    begin
        EDocumentMessage.Get(Rec."Record ID to Process");
        if Codeunit.Run(Codeunit::"E-Doc. Message Resp. Runner", EDocumentMessage) then
            exit;

        LastErrorText := GetLastErrorText();
        LastErrorInfo := ErrorInfo.Create(LastErrorText);
        EDocumentMessage.Get(EDocumentMessage."Entry No.");
        EDocumentMessage.Status := EDocumentMessage.Status::"Response Error";
        EDocumentMessage."Last Attempt At" := CurrentDateTime();
        EDocumentMessage."Retry Count" += 1;
        EDocumentMessage."Last Error" := CopyStr(LastErrorText, 1, MaxStrLen(EDocumentMessage."Last Error"));
        EDocumentMessage.Modify();
        TelemetryDimensions.Add('Message Entry No.', Format(EDocumentMessage."Entry No."));
        TelemetryDimensions.Add('Message Type', Format(EDocumentMessage."Message Type"));
        TelemetryDimensions.Add('Service', EDocumentMessage.Service);
        TelemetryDimensions.Add('Retry Count', Format(EDocumentMessage."Retry Count"));
        TelemetryDimensions.Add('Job Queue Entry ID', Format(Rec.ID));
        Telemetry.LogMessage('0000LC8', MessageResponseFailureTelemetryLbl, Verbosity::Error, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, TelemetryDimensions);
        Commit();
        Error(LastErrorInfo);
    end;

    var
        MessageResponseFailureTelemetryLbl: Label 'E-Document child message response polling failed', Locked = true;
}