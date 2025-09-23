// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Receive;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using System.Utilities;

/// <summary>
/// Codeunit to run ReceiveDocuments from Receive Interface
/// </summary>
codeunit 6179 "Receive Documents"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        GlobalEDocumentService.TestField(Code);
        IDocumentReceiver.ReceiveDocuments(this.GlobalEDocumentService, this.GlobalDocumentsMetadata, this.GlobalReceiveContext);
    end;

    procedure SetInstance(Reciver: Interface IDocumentReceiver)
    begin
        this.IDocumentReceiver := Reciver;
    end;

    procedure SetContext(ReceiveContext: Codeunit ReceiveContext)
    begin
        this.GlobalReceiveContext := ReceiveContext;
    end;

    procedure SetDocuments(DocumentsMetadata: Codeunit "Temp Blob List")
    begin
        this.GlobalDocumentsMetadata := DocumentsMetadata
    end;

    procedure SetService(var EDocumentService: Record "E-Document Service")
    begin
        this.GlobalEDocumentService.Copy(EDocumentService);
    end;


    var
        GlobalEDocumentService: Record "E-Document Service";
        GlobalDocumentsMetadata: Codeunit "Temp Blob List";
        GlobalReceiveContext: Codeunit ReceiveContext;
        IDocumentReceiver: Interface IDocumentReceiver;

}
