// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

codeunit 135 "Retrieve Document From OCR"
{
    TableNo = "Incoming Document";

    trigger OnRun()
    var
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
    begin
        SendIncomingDocumentToOCR.RetrieveDocFromOCR(Rec);
    end;
}

