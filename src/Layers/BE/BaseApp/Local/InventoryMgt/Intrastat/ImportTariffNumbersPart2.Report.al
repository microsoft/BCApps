// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using System.IO;

report 11332 "Import Tariff Numbers Part 2"
{
    Caption = 'Import Tariff Numbers Part 2';
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
        Field_No_Start := 2;
        Field_No_Len := 10;
        Field_Weight_Start := 15;
        Field_Weight_Len := 3;
        while TxtFile.Pos < TxtFile.Len do begin
            TxtFile.Read(Text);
            TariffNumber."Weight Mandatory" := false;
            PutRecordInDatabase();
        end;
    end;

    trigger OnPreReport()
    begin
        if FileName = '' then
            FileName := FileMgt.UploadFile('', '*.txt');
        Clear(TxtFile);
        TxtFile.TextMode := true;
        TxtFile.Open(FileName);
    end;

    var
        TariffNumber: Record "Tariff Number";
        FileMgt: Codeunit "File Management";
        TxtFile: File;
        FileName: Text;
        Text: Text[1024];
        Field_No_Start: Integer;
        Field_No_Len: Integer;
        Field_Weight_Start: Integer;
        Field_Weight_Len: Integer;

    [Scope('OnPrem')]
    procedure PutRecordInDatabase()
    begin
        TariffNumber."No." := CopyStr(Text, Field_No_Start, Field_No_Len);
        if CopyStr(Text, Field_Weight_Start, Field_Weight_Len) = 'Yes' then
            TariffNumber."Weight Mandatory" := true;
        TariffNumber.Insert();
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

