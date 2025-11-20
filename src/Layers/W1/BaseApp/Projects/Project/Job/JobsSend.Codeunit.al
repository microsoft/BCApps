// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.CRM.Outlook;
using Microsoft.Projects.Project.Archive;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;

codeunit 1016 "Jobs-Send"
{
    TableNo = Job;

    trigger OnRun()
    begin
        Job.Copy(Rec);
        Code();
        Rec := Job;
    end;

    var
        Job: Record Job;
        JobArchiveManagement: Codeunit "Job Archive Management";

    local procedure "Code"()
    var
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
    begin
        if not ConfirmSend(Job, TempDocumentSendingProfile) then
            exit;

        ValidateElectronicFormats(TempDocumentSendingProfile);

        Job.Get(Job."No.");
        Job.SetRecFilter();
        Job.SendProfile(TempDocumentSendingProfile);
        JobArchiveManagement.AutoArchiveJob(Job);
    end;

    local procedure ConfirmSend(Job: Record Job; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary): Boolean
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        OfficeMgt: Codeunit "Office Management";
    begin
        Customer.Get(Job."Bill-to Customer No.");
        if OfficeMgt.IsAvailable() then
            DocumentSendingProfile.GetOfficeAddinDefault(TempDocumentSendingProfile, OfficeMgt.AttachAvailable())
        else begin
            if not DocumentSendingProfile.Get(Customer."Document Sending Profile") then
                DocumentSendingProfile.GetDefault(DocumentSendingProfile);

            Commit();
            TempDocumentSendingProfile.Copy(DocumentSendingProfile);
            TempDocumentSendingProfile.SetDocumentUsage(Job);
            TempDocumentSendingProfile.Insert();
            if PAGE.RunModal(PAGE::"Post and Send Confirmation", TempDocumentSendingProfile) <> ACTION::Yes then
                exit(false);
        end;

        exit(true);
    end;

    local procedure ValidateElectronicFormats(DocumentSendingProfile: Record "Document Sending Profile")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if (DocumentSendingProfile."E-Mail" <> DocumentSendingProfile."E-Mail"::No) and
           (DocumentSendingProfile."E-Mail Attachment" <> DocumentSendingProfile."E-Mail Attachment"::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."E-Mail Format");
            ElectronicDocumentFormat.ValidateElectronicJobsDocument(Job, DocumentSendingProfile."E-Mail Format");
        end;

        if (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::No) and
           (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Disk Format");
            ElectronicDocumentFormat.ValidateElectronicJobsDocument(Job, DocumentSendingProfile."Disk Format");
        end;

        if DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Electronic Format");
            ElectronicDocumentFormat.ValidateElectronicJobsDocument(Job, DocumentSendingProfile."Electronic Format");
        end;
    end;
}

