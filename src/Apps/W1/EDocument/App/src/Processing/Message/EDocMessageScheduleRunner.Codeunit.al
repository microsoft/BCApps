// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using System.Threading;

codeunit 6410 "E-Doc. Message Schedule Runner"
{
    Access = Internal;
    TableNo = "Job Queue Entry";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        EDocumentMessage: Record "E-Document Message";
        EDocumentBackgroundJobs: Codeunit "E-Document Background Jobs";
    begin
        EDocumentMessage.Get(Rec."Record ID to Process");
        case Rec."Object ID to Run" of
            Codeunit::"E-Doc. Message Send Job":
                EDocumentBackgroundJobs.ScheduleMessageSend(EDocumentMessage);
            Codeunit::"E-Doc. Message Response Job":
                EDocumentBackgroundJobs.ScheduleMessageResponse(EDocumentMessage);
            else
                Rec.FieldError("Object ID to Run");
        end;
    end;
}
