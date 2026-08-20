// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Vendor;

codeunit 6403 "EDoc Prepare Cr. Memo Draft" implements IProcessStructuredData
{
    Access = Internal;

    var
        PrepareDraftHelper: Codeunit "EDoc Prepare Purch. Draft";

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    begin
        PrepareDraftHelper.PrepareDraft(EDocument, EDocImportParameters);
        exit("E-Document Type"::"Purchase Credit Memo");
    end;

    procedure OpenDraftPage(var EDocument: Record "E-Document")
    begin
        PrepareDraftHelper.OpenDraftPage(EDocument);
    end;

    procedure CleanUpDraft(EDocument: Record "E-Document")
    begin
        PrepareDraftHelper.CleanUpDraft(EDocument);
    end;

    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations") Vendor: Record Vendor
    begin
        Vendor := PrepareDraftHelper.GetVendor(EDocument, Customizations);
    end;
}
