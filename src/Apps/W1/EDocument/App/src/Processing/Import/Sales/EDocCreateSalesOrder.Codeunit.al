// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Sales.Document;

codeunit 50003 "E-Doc. Create Sales Order" implements IEDocumentFinishDraft, IEDocumentCreateSalesOrder
{
    Access = Internal;

    procedure ApplyDraftToBC(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): RecordId
    begin
    end;

    procedure RevertDraftActions(EDocument: Record "E-Document")
    begin
    end;

    procedure CreateSalesOrder(EDocument: Record "E-Document"): Record "Sales Header"
    begin
    end;
}
