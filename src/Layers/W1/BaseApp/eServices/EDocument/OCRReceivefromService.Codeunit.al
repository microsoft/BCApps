// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Company;
using System.Environment;
using System.Threading;

codeunit 881 "OCR - Receive from Service"
{

    trigger OnRun()
    var
        IncomingDocument: Record "Incoming Document";
        CompanyInformation: Record "Company Information";
        JobQueueEntry: Record "Job Queue Entry";
        EnvironmentInfo: Codeunit "Environment Information";
        JobQueueEntryFound: Boolean;
    begin
        GetDocuments();
        JobQueueEntryFound :=
          JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"OCR - Receive from Service");
        if JobQueueEntryFound then begin
            CompanyInformation.Get();
            IncomingDocument.SetFilter(
              "OCR Status", '%1|%2',
              IncomingDocument."OCR Status"::Sent,
              IncomingDocument."OCR Status"::"Awaiting Verification");
            if IncomingDocument.IsEmpty() and EnvironmentInfo.IsSaaS() and CompanyInformation."Demo Company" then
                JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold")
            else
                if JobQueueEntry.Status = JobQueueEntry.Status::"On Hold" then
                    JobQueueEntry.Restart();
        end;
    end;

    var
        DownloadCountMsg: Label '%1 documents have been received.', Comment = '%1 = a number, e.g. 0, 1, 4.';
        AwaitingCountMsg: Label 'You have %1 documents that require you to manually verify the OCR values before the documents can be received.', Comment = '%1 = a number, e.g. 0, 1, 4.';

    [Scope('OnPrem')]
    procedure GetDocuments()
    var
        IncomingDocument: Record "Incoming Document";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        ResultMsg: Text;
        DownloadedDocCount: Integer;
        AwaitingDocCount: Integer;
    begin
        DownloadedDocCount := OCRServiceMgt.GetDocuments('');

        IncomingDocument.SetRange("OCR Status", IncomingDocument."OCR Status"::"Awaiting Verification");
        AwaitingDocCount := IncomingDocument.Count();

        ResultMsg := StrSubstNo(DownloadCountMsg, DownloadedDocCount);
        if AwaitingDocCount > 0 then
            ResultMsg := StrSubstNo('%1\\%2', ResultMsg, StrSubstNo(AwaitingCountMsg, AwaitingDocCount));
        Message(ResultMsg);
    end;
}

