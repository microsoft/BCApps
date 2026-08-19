// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

codeunit 1421 "Doc. Exch. Serv. - Recv. Docs."
{

    trigger OnRun()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
    begin
        DocExchServiceSetup.Get();
        DocExchServiceMgt.ReceiveDocuments(DocExchServiceSetup.RecordId);
    end;
}

