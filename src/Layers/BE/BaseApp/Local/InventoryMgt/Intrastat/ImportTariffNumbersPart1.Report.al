// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using System.IO;

report 11333 "Import Tariff Numbers Part 1"
{
    Caption = 'Import Tariff Numbers Part 1';
    ProcessingOnly = true;
    UseRequestPage = false;

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
    begin
        while TxtFile.Pos < TxtFile.Len do begin
            TxtFile.Read(Text);
            ImportNo := CopyStr(CopyStr(Text, 1, StrPos(Text, ';') - 2), 2, 9);
            ImportDesc :=
              ConvertStr(CopyStr(CopyStr(CopyStr(Text, StrPos(Text, ';') + 2, MaxStrLen(Text)), 1,
                    StrPos(CopyStr(Text, StrPos(Text, ';') + 2, MaxStrLen(Text)), ';') - 2), 1, 50), '""', ''' ');

            Suppl :=
              CopyStr(CopyStr(Text, StrPos(Text, ';') + 2, MaxStrLen(Text)), StrPos(CopyStr(Text, StrPos(Text, ';') + 2, MaxStrLen(Text)),
                  ';') + 2, MaxStrLen(Suppl));
            if Suppl <> '' then
                Suppl2 := CopyStr(CopyStr(Suppl, 1, StrPos(Suppl, ';') - 2), 1, 10);
            if StrLen(Suppl2) > 0 then
                Suppl2 := CopyStr(Suppl2, 1, StrLen(Suppl2) - 1);
            InsertLines();
        end;
    end;

    trigger OnPreReport()
    begin
        if FileName = '' then
            FileName := FileManagement.UploadFile('', '*.txt');
        Clear(TxtFile);
        TxtFile.TextMode := true;
        TxtFile.Open(FileName)
    end;

    var
        TariffNumber: Record "Tariff Number";
        TariffNumber2: Record "Tariff Number";
        FileManagement: Codeunit "File Management";
        TxtFile: File;
        FileName: Text;
        ImportDesc: Text[50];
        Text: Text[1024];
        Suppl: Text[1024];
        Suppl2: Text[10];
        ImportNo: Code[10];

    [Scope('OnPrem')]
    procedure InsertLines()
    begin
        TariffNumber.Validate("No.", ImportNo);
        TariffNumber.Validate(Description, ImportDesc);
        if Suppl2 <> '-' then begin
            TariffNumber."Supplementary Units" := true;
            TariffNumber."Unit of Measure" := Suppl2
        end else begin
            TariffNumber."Supplementary Units" := false;
            TariffNumber."Unit of Measure" := '';
        end;
        TariffNumber."Weight Mandatory" := true;
        if not TariffNumber2.Get(TariffNumber."No.") then
            TariffNumber.Insert();
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

