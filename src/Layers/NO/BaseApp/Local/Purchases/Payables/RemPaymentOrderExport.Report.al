// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using System.IO;

report 15000061 "Rem. Payment Order  - Export"
{
    Caption = 'Rem. Payment Order  - Export';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Payment Order Data"; "Payment Order Data")
        {
            DataItemTableView = sorting("Payment Order No.", "Line No");

            trigger OnAfterGetRecord()
            begin
                DataOut := PadStr("Payment Order Data".Data, 80);
                Ostr.WriteText(DataOut);
                Ostr.WriteText();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Payment Order No.", RemPmtOrder.ID);
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

    trigger OnPostReport()
    begin
        OFile.Close();
        Clear(Ostr);
        FileMgt.DownloadHandler(ServerFileName, '', '', '', CurrentFilename);
    end;

    trigger OnPreReport()
    begin
        ServerFileName := FileMgt.ServerTempFileName('txt');
        OFile.Create(ServerFileName);
        OFile.TextMode(true);
        OFile.CreateOutStream(Ostr);
    end;

    var
        RemPmtOrder: Record "Remittance Payment Order";
        FileMgt: Codeunit "File Management";
        Ostr: OutStream;
        OFile: File;
        CurrentFilename: Text[250];
        DataOut: Text[80];
        ServerFileName: Text;

    [Scope('OnPrem')]
    procedure SetPmtOrder(RemPmtOrder2: Record "Remittance Payment Order")
    begin
        RemPmtOrder := RemPmtOrder2;
    end;

    [Scope('OnPrem')]
    procedure SetFilename(FileName: Text[250])
    begin
        CurrentFilename := FileName;
    end;
}

