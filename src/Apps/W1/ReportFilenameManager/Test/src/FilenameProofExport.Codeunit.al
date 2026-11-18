// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using System.IO;

codeunit 149546 "Filename Proof Export"
{
    // Export for the proof's own electronic document format: a fixed XML, so the name proof does not
    // depend on the company passing a real format's checks.

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
