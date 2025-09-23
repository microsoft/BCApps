// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Receive;

using System.Utilities;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;

/// <summary>
/// Codeunit to run DownloadDocument from IDocumentReceiver Interface
/// </summary>
codeunit 6180 "Download Document"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        this.GlobalEDocumentService.TestField(Code);
        IDocumentReceiver.DownloadDocument(this.GlobalEDocument, this.GlobalEDocumentService, this.GlobalDocumentMetadata, this.GlobalReceiveContext);
    end;

    procedure SetContext(ReceiveContext: Codeunit ReceiveContext)
    begin
        this.GlobalReceiveContext := ReceiveContext;
    end;

    procedure SetInstance(Reciver: Interface IDocumentReceiver)
    begin
        this.IDocumentReceiver := Reciver;
    end;

    procedure SetParameters(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob")
    begin
        this.GlobalEDocument.Copy(EDocument);
        this.GlobalEDocumentService.Copy(EDocumentService);
        this.GlobalDocumentMetadata := DocumentMetadata;
    end;

    var
        GlobalEDocument: Record "E-Document";
        GlobalEDocumentService: Record "E-Document Service";
        GlobalDocumentMetadata: Codeunit "Temp Blob";
        GlobalReceiveContext: Codeunit ReceiveContext;
        IDocumentReceiver: Interface IDocumentReceiver;
}
