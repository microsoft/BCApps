// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Security.Encryption;

codeunit 11000012 "Report Checksum"
{
    trigger OnRun()
    begin

    end;

    procedure GenerateChecksum(var PaymentHistory: Record "Payment History"; ServerTempFileName: Text; ExportProtocolCode: Code[20])
    var
        ExportProtocol: Record "Export Protocol";
        CryptographyManagement: Codeunit "Cryptography Management";
        InStreamFile: InStream;
        ServerTempFile: File;
        Checksum: Text;
    begin
        if (ServerTempFileName = '') then
            exit;
        ExportProtocol.Get(ExportProtocolCode);

        if not ExportProtocol."Generate Checksum" then
            exit;
        ServerTempFile.Open(ServerTempFileName);
        ServerTempFile.CreateInStream(InStreamFile);

        Checksum := CryptographyManagement.GenerateHash(InStreamFile, ExportProtocol."Checksum Algorithm");
        ServerTempFile.Close();

        PaymentHistory.Validate(Checksum, Checksum);
        PaymentHistory.Modify(true);

        if ExportProtocol."Append Checksum to File" then
            AppendChecksumToFile(ServerTempFileName, Checksum);
    end;

    local procedure AppendChecksumToFile(ServerTempFileName: Text; Checksum: Text)
    var
        ServerTempFile: File;
        CRLF: Text[2];
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        ServerTempFile.TextMode := true;
        ServerTempFile.WriteMode := true;
        ServerTempFile.Open(ServerTempFileName);
        ServerTempFile.Seek(ServerTempFile.Len);
        ServerTempFile.Write(CRLF + Checksum);
        ServerTempFile.Seek(ServerTempFile.POS - 2);
        ServerTempFile.Trunc();
        ServerTempFile.Close();
    end;
}
