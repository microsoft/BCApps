// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.IO;

report 28167 "BAS - Import/Export Setup"
{
    Caption = 'BAS - Import/Export Setup';
    ProcessingOnly = true;

    dataset
    {
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

    trigger OnPostReport()
    var
        ToFile: Text[1024];
    begin
        if BASDirection = BASDirection::Export then begin
            ToFile := Text013 + '.xml';
            Download(BASFileName, Text011, '', Text035, ToFile);
        end;

        Clear(BASMngmt);
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
    begin
        if (BASDirection = BASDirection::Import) or (BASDirection = BASDirection::"Update BAS XML Field ID") then begin
            ReadFromFile(BASFileName);
            if BASFileName = '' then
                Error(Text001);
        end;
        if BASDirection = BASDirection::Export then
            BASFileName := FileMgt.ServerTempFileName('xml');

        case BASDirection of
            BASDirection::Import:
                BASMngmt.ImportBAS(BASCalcSheet, BASFileName);
            BASDirection::Export:
                BASMngmt.ExportBAS(BASCalcSheet);
            BASDirection::"Update BAS XML Field ID":
                BASMngmt.UpdateXMLFieldSetup(BASFileName, CurrentBASSetupName);
            else
                CurrReport.Quit();
        end;
    end;

    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASMngmt: Codeunit "BAS Management";
        BASDirection: Option Import,Export,"Update BAS XML Field ID";
        BASFileName: Text[250];
        CurrentBASSetupName: Code[20];
        Text034: Label 'Import from XML File';
        Text001: Label 'Enter the file name.';
        Text035: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        Text011: Label 'Export to XML File';
        Text013: Label 'Default';

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
    procedure SetCurrentBASSetupName(OldCurrentBASSetupName: Code[20])
    begin
        CurrentBASSetupName := OldCurrentBASSetupName;
    end;

    [Scope('OnPrem')]
    procedure ReadFromFile(var FileName2: Text[1024])
    var
        FileMgt: Codeunit "File Management";
        NewFileName: Text[1024];
    begin
        if FileName2 = '' then
            FileName2 := '.xml';
        NewFileName := FileMgt.UploadFile(Text034, FileName2);
        if NewFileName <> '' then
            FileName2 := NewFileName;
    end;
}

