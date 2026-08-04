// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Security.Encryption;
using System.Utilities;

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

    procedure GenerateChecksumFromBlob(var PaymentHistory: Record "Payment History"; var TempBlob: Codeunit "Temp Blob"; ExportProtocolCode: Code[20])
    var
        ExportProtocol: Record "Export Protocol";
        CryptographyManagement: Codeunit "Cryptography Management";
        ContentInStream: InStream;
        Checksum: Text;
    begin
        ExportProtocol.Get(ExportProtocolCode);

        if not ExportProtocol."Generate Checksum" then
            exit;

        TempBlob.CreateInStream(ContentInStream);
        Checksum := CryptographyManagement.GenerateHash(ContentInStream, ExportProtocol."Checksum Algorithm");

        PaymentHistory.Validate(Checksum, Checksum);
        PaymentHistory.Modify(true);

        if ExportProtocol."Append Checksum to File" then
            AppendChecksumToBlob(TempBlob, Checksum);
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

    local procedure AppendChecksumToBlob(var TempBlob: Codeunit "Temp Blob"; Checksum: Text)
    var
        ResultTempBlob: Codeunit "Temp Blob";
        ContentInStream: InStream;
        ResultOutStream: OutStream;
        CRLF: Text[2];
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        TempBlob.CreateInStream(ContentInStream);
        ResultTempBlob.CreateOutStream(ResultOutStream);
        CopyStream(ResultOutStream, ContentInStream);
        ResultOutStream.WriteText(CRLF + Checksum);
        TempBlob := ResultTempBlob;
    end;
}
