// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50196 "Filename Proof Export"
{
    // The export of the proof's own electronic document format: a fixed, minimal XML in place of a
    // real format's document, so a proof of the file's name does not depend on the demonstration
    // company passing a real format's checks.

    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        OutStr: OutStream;
    begin
        Rec."File Content".CreateOutStream(OutStr);
        OutStr.WriteText(ProofDocumentTok);
        Rec.Modify();
    end;

    var
        ProofDocumentTok: Label '<ProofDocument/>', Locked = true;
}
