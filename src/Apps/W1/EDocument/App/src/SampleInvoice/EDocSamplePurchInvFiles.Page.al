// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

/// <summary>
/// Page for viewing and downloading sample purchase invoice files.
/// </summary>
page 6132 "E-Doc Sample Purch. Inv. Files"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = None;
    Caption = 'E-Doc Sample Purchase Invoice Files';
    PageType = List;
    SourceTable = "E-Doc Sample Purch. Inv File";
    InsertAllowed = true;
    DeleteAllowed = true;
    ModifyAllowed = true;
    Editable = false;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor associated with the demo file.';
                }
                field(Scenario; Rec.Scenario)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the scenario.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file name.';
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
        InStream: InStream;
        FileName: Text;
        DownloadingSampleFileLbl: Label 'Downloading sample file...';
    begin
        Rec.TestField("File Name");
        Rec.CalcFields("File Content");
        if not Rec."File Content".HasValue() then
            error(NoFileContentErr);
        Rec."File Content".CreateInStream(InStream);
        FileName := Rec."File Name" + '.pdf';
        DownloadFromStream(InStream, DownloadingSampleFileLbl, '', '', FileName);
    end;
}
