// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.IO;
using System.Utilities;

report 28166 "BAS - Import/Export"
{
    Caption = 'BAS - Import/Export';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {

            trigger OnAfterGetRecord()
            begin
                case BASDirection of
                    BASDirection::Import:
                        BASMngmt.ImportBAS(BASCalcSheet, BASFileName);
                    BASDirection::Export:
                        BASMngmt.ExportBAS(BASCalcSheet);
                    BASDirection::"Update BAS XML Field ID":
                        BASMngmt.UpdateXMLFieldIDs(BASFileName);
                    else
                        CurrReport.Quit();
                end;
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(BASFileName; DisplayFileName)
                    {
                        ApplicationArea = Basic, Suite;
                        AssistEdit = true;
                        Caption = 'BAS File Name';
                        ToolTip = 'Specifies the file name.';
                        Visible = FileSelectionVisible;

                        trigger OnAssistEdit()
                        var
                            FileMgt: Codeunit "File Management";
                        begin
                            if BASDirection = BASDirection::Export then
                                DisplayFileName := FileMgt.GetFileName('')
                            else
                                if (BASDirection = BASDirection::Import) or (BASDirection = BASDirection::"Update BAS XML Field ID") then
                                    ReadFromFile(BASFileName);
                        end;
                    }
                    field(PrintBtn; Print)
                    {
                        ApplicationArea = All;
                        Caption = 'Print';
                        ToolTip = 'Specifies that you want to print the BAS.';
                        Visible = PrintBtnVisible;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PrintBtnVisible := true;
            PrintlabelVisible := true;
            FileSelectionVisible := true;
        end;

        trigger OnOpenPage()
        begin
            if BASDirection = BASDirection::Export then begin
                PrintlabelVisible := true;
                PrintBtnVisible := true;
                FileSelectionVisible := false;
            end
            else begin
                PrintBtnVisible := false;
                PrintlabelVisible := false;
                FileSelectionVisible := true;
            end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        FileSelectionVisible := BASDirection = BASDirection::Import;
    end;

    trigger OnPostReport()
    var
        BASCalcSheet1: Record "BAS Calculation Sheet";
    begin
        Clear(BASMngmt);
        if BASDirection = BASDirection::Export then
            if Print then begin
                BASCalcSheet1.SetRange(A1, BASCalcSheet.A1);
                BASCalcSheet1.SetRange("BAS Version", BASCalcSheet."BAS Version");
                REPORT.Run(REPORT::"Print BAS Export File", false, true, BASCalcSheet1);
            end;
    end;

    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASMngmt: Codeunit "BAS Management";
        BASDirection: Option Import,Export,"Update BAS XML Field ID";
        BASFileName: Text;
        DisplayFileName: Text;
        Print: Boolean;
        Text034: Label 'Import from XML File';
        PrintlabelVisible: Boolean;
        PrintBtnVisible: Boolean;
        FileSelectionVisible: Boolean;

    [Scope('OnPrem')]
    procedure SetBASCalcSheetRecord(NewBASCalcSheet: Record "BAS Calculation Sheet")
    begin
        BASCalcSheet := NewBASCalcSheet;
        BASFileName := NewBASCalcSheet."File Name";
    end;

    [Scope('OnPrem')]
    procedure SetDirection(NewBASDirection: Option Import,Export,"Update BAS XML Field ID")
    begin
        BASDirection := NewBASDirection;
    end;

    [Scope('OnPrem')]
    procedure ReturnRecord(var NewBASCalcSheet: Record "BAS Calculation Sheet")
    begin
        NewBASCalcSheet := BASCalcSheet;
    end;

    [Scope('OnPrem')]
    procedure ReadFromFile(var FileName2: Text)
    var
        FileMgt: Codeunit "File Management";
        NewFileName: Text[1024];
    begin
        if FileName2 = '' then
            FileName2 := '.xml';
        Upload(Text034, '', 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*', '', NewFileName);
        DisplayFileName := FileMgt.GetFileName(NewFileName);
        if NewFileName <> '' then
            FileName2 := NewFileName;
    end;
}

