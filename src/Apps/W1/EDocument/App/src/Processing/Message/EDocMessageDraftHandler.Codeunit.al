// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Vendor;

/// <summary>
/// No-op IProcessStructuredData implementation for inbound E-Document messages (e.g. PEPPOL Order Response).
/// When ReadIntoDraft returns "E-Document Message", the pipeline calls PrepareDraft which returns None
/// so that FinishDraft exits early without creating a BC document.
/// </summary>
codeunit 50005 "E-Doc. Message Draft Handler" implements IProcessStructuredData
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    begin
        exit("E-Document Type"::None);
    end;

    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations"): Record Vendor
    var
        EmptyVendor: Record Vendor;
    begin
        exit(EmptyVendor);
    end;

    procedure OpenDraftPage(var EDocument: Record "E-Document")
    begin
    end;

    procedure CleanUpDraft(EDocument: Record "E-Document")
    begin
    end;
}
