// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.IO;
using System.Telemetry;

page 15000100 "OCR Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'OCR Setup';
    PageType = Card;
    SourceTable = "OCR Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Format; Rec.Format)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an OCR payment file format.';
                }
                field(FileName; OCRSetupFileName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'FileName';
                    ToolTip = 'Specifies the full path of the OCR payment file.';

                    trigger OnAssistEdit()
                    begin
                        ComDlgFilename := FileMgt.UploadFile(Rec.FieldCaption(FileName), Rec.FileName);
                        if ComDlgFilename <> '' then begin
                            Rec.Validate(FileName, ComDlgFilename);
                            OCRSetupFileName := FileMgt.GetFileName(ComDlgFilename);
                        end;
                    end;
                }
                field("Delete Return File"; Rec."Delete Return File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to rename the file after import and prevent the file from being imported more than once.';
                }
            }
            group("Gen. Ledger")
            {
                Caption = 'Gen. Ledger';
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a balance account type.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a balance account.';
                }
                field("Max. Divergence"; Rec."Max. Divergence")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a maximum divergence value.';
                }
                field("Divergence Account No."; Rec."Divergence Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the divergence account number that will receive posting.';
                }
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template.';
                }
                field("Journal Name"; Rec."Journal Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FeatureTelemetry.LogUptake('0000HU6', NOOCRReportTok, Enum::"Feature Uptake Status"::"Set up");
        OCRSetupFileName := FileMgt.GetFileName(Rec.FileName);
    end;

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('0000HU5', NOOCRReportTok, Enum::"Feature Uptake Status"::Discovered);
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        FileMgt: Codeunit "File Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NOOCRReportTok: Label 'NO OCR Set Up Payments', Locked = true;
        ComDlgFilename: Text[200];
        OCRSetupFileName: Text;
}

