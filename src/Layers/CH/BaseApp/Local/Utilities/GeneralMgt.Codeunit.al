// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;

codeunit 11501 GeneralMgt
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'The folder name must end with a slash character, i.e. %1.';

    [Scope('OnPrem')]
    procedure CheckFolderName(_Input: Text[250])
    begin
        // Check for ending slash of folder name
        if _Input = '' then
            exit;

        if not (CopyStr(_Input, StrLen(_Input)) in ['\', '/']) then
            Message(Text001, 'c:\data\');
    end;

    [Scope('OnPrem')]
    procedure CheckCurrency(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not (CurrencyCode = '') then
            exit(CurrencyCode)
        else begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.TestField("LCY Code");
            exit(GeneralLedgerSetup."LCY Code");
        end;
    end;

    [Scope('OnPrem')]
    procedure RemoveCrLf(FileName: Text[1024]; TempFileName: Text[1024]; A2A: Boolean): Text[1024]
    var
        SourceFile: File;
        TargetFile: File;
        Z: Char;
        FileMgt: Codeunit "File Management";
    begin
        // Removes CR/LF in File. Rename Original file and write again w/o CR/LF.
        SourceFile.TextMode := false;
        SourceFile.WriteMode := false;
        SourceFile.Open(TempFileName);

        TargetFile.TextMode := false;
        TargetFile.WriteMode := true;
        TargetFile.Create(FileMgt.ServerTempFileName(''));

        while SourceFile.Read(Z) = 1 do
            if not (Z in [10, 13]) then
                TargetFile.Write(Z);

        SourceFile.Close();
        TempFileName := TargetFile.Name;
        TargetFile.Close();

        exit(TempFileName);
    end;
}

