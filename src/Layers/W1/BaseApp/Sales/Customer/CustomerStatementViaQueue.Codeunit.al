// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Utilities;
using System.Threading;
using System.Utilities;

codeunit 8811 "Customer Statement via Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
        XmlContent: Text;
    begin
        Rec.CalcFields("Object Caption to Run");
        ErrorMessageManagement.Activate(ErrorMessageHandler);
        ErrorMessageManagement.PushContext(ErrorContextElement, Rec.RecordId, 0, Rec."Object Caption to Run");

        XmlContent := Rec.GetXmlContent();
        if XmlContent = '' then
            ErrorMessageManagement.LogErrorMessage(0, RequestParametersHasNotBeenSetErr, Rec, Rec.FieldNo(XML), '')
        else
            CustomerLayoutStatement.RunReportWithParameters(XmlContent);

        ErrorMessageHandler.AppendTo(TempErrorMessage);
        LogErrors(TempErrorMessage, Rec);
        ErrorMessageManagement.PopContext(ErrorContextElement);
    end;

    var
        RequestParametersHasNotBeenSetErr: Label 'Request parameters for the Standard Statement report have not been set up.';

    local procedure LogActivityFailed(RelatedRecordID: RecordID; ActivityTitle: Text; ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(
            RelatedRecordID, ActivityLog.Status::Failed, ActivityTitle,
            ActivityMessage, '');
    end;

    local procedure LogErrors(var TempErrorMessage: Record "Error Message" temporary; var JobQueueEntry: Record "Job Queue Entry")
    begin
        if TempErrorMessage.FindSet() then
            repeat
                LogActivityFailed(JobQueueEntry.RecordID, JobQueueEntry."Object Caption to Run", TempErrorMessage."Message");
            until TempErrorMessage.Next() = 0;
    end;
}

