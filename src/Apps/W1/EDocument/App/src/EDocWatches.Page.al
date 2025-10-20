// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument.IO;

page 6179 "E-Doc Watches"
{
    Caption = 'E-Doc Watches';
    PageType = List;
    SourceTable = "E-Doc Watch";
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Export ID"; Rec."Export ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the export identification number.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DownloadFile)
            {
                ApplicationArea = Basic, Suite;
                Image = ExportFile;
                Caption = 'Download File';
                ToolTip = 'Download the saved file';

                trigger OnAction()
                var
                    InStream: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("File Content");
                    if not Rec."File Content".HasValue() then
                        error('No file content to download.');
                    Rec."File Content".CreateInStream(InStream);
                    FileName := 'SavedFile.txt';
                    DownloadFromStream(InStream, 'Export file', '', 'Text File (*.txt)|*.txt', FileName);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(DownloadFile_Promoted; DownloadFile) { }
            }
        }
    }
}