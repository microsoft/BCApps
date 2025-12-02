// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using System.Utilities;
using System.Environment;
using System.IO;

/// <summary>
/// Page for viewing and downloading sample purchase invoice files.
/// </summary>
page 6132 "E-Doc Sample Purch. Inv. Files"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;
    Caption = 'E-Doc Sample Purchase Invoice Files';
    PageType = List;
    SourceTable = "E-Doc Sample Purch. Inv File";
    InsertAllowed = true;
    DeleteAllowed = true;
    ModifyAllowed = true;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field("File Name"; Rec."File Name")
                {
                    ToolTip = 'Specifies the file name.';
                }
                field("File Content"; Rec."File Content")
                {
                    ToolTip = 'Specifies the file content.';
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(DownloadFileRef; DownloadFile)
            {
            }
        }
        area(processing)
        {
            action(DownloadFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download File';
                ToolTip = 'Downloads the file and displays it in the browser.';
                Image = Download;

                trigger OnAction()
                begin
                    DownloadAndViewFile();
                end;
            }
        }
    }

    var
        NoFileContentErr: Label 'There is no file content to download.';

    local procedure DownloadAndViewFile()
    var
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        Rec.TestField("File Name");
        if Rec."File Content".HasValue() then begin
            TenantMedia.Get(Rec."File Content".MediaId());
            if not TenantMedia.Content.HasValue() then
                Error(NoFileContentErr);

            TempBlob.FromRecord(TenantMedia, TenantMedia.FieldNo(Content));
            FileManagement.BLOBExport(TempBlob, Rec."File Name" + '.pdf', false);
        end else
            Error(NoFileContentErr);
    end;
}
