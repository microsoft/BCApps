// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.EServices.EDocument;
using System.Threading;


/// <summary>
/// Processes the FORNAV Incoming Documents
/// </summary>
codeunit 6410 "ForNAV App. Resp. Handler"
{
    Permissions =
        tabledata "E-Document Service Status" = RIMD;
    Access = internal;
    TableNo = "Job Queue Entry";

    local procedure UpdateServiceStatus(EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service"; EDocumentStatus: Enum "E-Document Service Status")
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        if EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code) then begin
            EDocumentServiceStatus.Validate(Status, EDocumentStatus);
            EDocumentServiceStatus.Modify()
        end else begin
            EDocumentServiceStatus.Validate("E-Document Entry No", EDocument."Entry No");
            EDocumentServiceStatus.Validate("E-Document Service Code", EDocumentService.Code);
            EDocumentServiceStatus.Validate(Status, EDocumentStatus);
            EDocumentServiceStatus.Insert();
        end;
    end;

    procedure ProcessApplicationResponse(DocumentType: Enum "E-Document Type"; DocNo: Text; Status: Enum "E-Document Service Status"): Boolean
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        Setup: Record "ForNAV Peppol Setup";
        EDocLogHelper: Codeunit "E-Document Log Helper";
    begin
        if not Setup.GetEDocumentService(EDocumentService) then
            exit(false);

        EDocument.SetRange("Document No.", DocNo);
        EDocument.SetRange("Document Type", DocumentType);
        EDocument.SetRange(Direction, "E-Document Direction"::Outgoing);
        if EDocument.FindFirst() then begin
            EDocLogHelper.InsertLog(EDocument, EDocumentService, Status);
            UpdateServiceStatus(EDocument, EDocumentService, Status);
            exit(true);
        end;
    end;

    trigger OnRun()
    var
        ForNAVIncomingEDocument: Record "ForNAV Incoming E-Document";
    begin
        ForNAVIncomingEDocument.Get(Rec."Record ID to Process");
        if ForNAVIncomingEDocument.DocType = ForNAVIncomingEDocument.DocType::ApplicationResponse then
            if ForNAVIncomingEDocument.EDocumentType <> "E-Document Type"::None then
                if ProcessApplicationResponse(ForNAVIncomingEDocument.EDocumentType, ForNAVIncomingEDocument.DocNo, ForNAVIncomingEDocument.Status = ForNAVIncomingEDocument.Status::Approved ? "E-Document Service Status"::Approved : "E-Document Service Status"::Rejected) then begin
                    ForNAVIncomingEDocument.Status := ForNAVIncomingEDocument.Status::Processed;
                    ForNAVIncomingEDocument.Modify();
                end;
    end;
}