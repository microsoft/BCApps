// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Setup;
using System.IO;

report 5181 "Relocate Attachments"
{
    Caption = 'Relocate Attachments';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Attachment; Attachment)
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            var
                FromDiskFileName: Text[250];
                ServerFileName: Text;
            begin
                LineCount := LineCount + 1;
                Window.Update(1, Round(LineCount / NoOfRecords * 10000, 1));

                // Copy DiskFile to DiskFile
                if ("Storage Type" = "Storage Type"::"Disk File") and
                   (RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File")
                then begin
                    RMSetup.TestField("Attachment Storage Location");
                    if "Storage Pointer" <> RMSetup."Attachment Storage Location" then begin
                        FromDiskFileName := ConstDiskFileName();
                        "Storage Pointer" := RMSetup."Attachment Storage Location";
                        Modify();
                        FileManagement.CopyServerFile(FromDiskFileName, ConstDiskFileName(), false); // Copy from UNC location to another UNC location
                        Commit();
                        FileManagement.DeleteServerFile(FromDiskFileName);
                    end;
                    CurrReport.Skip();
                end;

                // Export Embedded Blob to Diskfile
                if ("Storage Type" = "Storage Type"::Embedded) and
                   (RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File")
                then begin
                    RMSetup.TestField("Attachment Storage Location");
                    CalcFields("Attachment File");
                    if "Attachment File".HasValue() then begin
                        "Storage Pointer" := RMSetup."Attachment Storage Location";
                        ServerFileName := ConstDiskFileName();
                        ExportAttachmentToServerFile(ServerFileName); // Export blob to UNC location
                        "Storage Type" := "Storage Type"::"Disk File";
                        Clear("Attachment File");
                        Modify();
                        Commit();
                        CurrReport.Skip();
                    end;
                end;

                // Import DiskFile to Embedded Blob
                if ("Storage Type" = "Storage Type"::"Disk File") and
                   (RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::Embedded)
                then begin
                    FromDiskFileName := ConstDiskFileName();
                    ImportAttachmentFromServerFile(GetServerFileName(ConstDiskFileName()), false, true); // Import file from UNC location
                    Commit();
                    FileManagement.DeleteServerFile(FromDiskFileName);
                    CurrReport.Skip();
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if not Confirm(Text000, true) then
            CurrReport.Quit();
    end;

    trigger OnPreReport()
    begin
        RMSetup.Get();
        NoOfRecords := Attachment.Count();
        Window.Open(Text001);
    end;

    var
        RMSetup: Record "Marketing Setup";
#pragma warning disable AA0074
        Text000: Label 'Do you want to relocate existing attachments?';
#pragma warning restore AA0074
        FileManagement: Codeunit "File Management";
        Window: Dialog;
#pragma warning disable AA0074
        Text001: Label 'Relocating attachments @1@@@@@@@@@@@@@';
#pragma warning restore AA0074
        NoOfRecords: Integer;
        LineCount: Integer;
}

