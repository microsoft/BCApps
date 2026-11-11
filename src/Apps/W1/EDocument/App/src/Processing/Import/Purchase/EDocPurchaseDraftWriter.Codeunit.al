// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

/// <summary>
/// Provides a public entry point for persisting purchase drafts from structured E-Document readers.
/// </summary>
codeunit 6540 "E-Doc. Purchase Draft Writer"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Replaces an existing incoming E-Document's purchase draft with the supplied temporary header and lines.
    /// Existing lines are deleted with their triggers, removing their purchase-order matches.
    /// The internal draft utility assigns the E-Document linkage and new line numbers.
    /// Only lines visible under the temporary line buffer's current filters are persisted.
    /// The writer does not change import-processing status or run Prepare Draft / Finish Draft.
    /// This low-level writer does not enforce import-processing states; lifecycle transitions belong to the import orchestrator.
    /// Direct callers must coordinate reruns or resets before replacing prepared or finalized drafts.
    /// Any existing draft edits are lost unless they are represented in the supplied buffers.
    /// </summary>
    /// <param name="EDocument">An existing incoming E-Document for which to replace the purchase draft.</param>
    /// <param name="TempEDocPurchaseHeader">The temporary header's current values; it does not need to be inserted.</param>
    /// <param name="TempEDocPurchaseLine">The temporary line buffer. All visible lines are persisted in key order; an empty selection removes the existing lines.</param>
    procedure PersistDraft(EDocument: Record "E-Document"; var TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary; var TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary)
    var
        ExistingEDocument: Record "E-Document";
        EDocPurchaseDraftUtility: Codeunit "E-Doc. Purchase Draft Utility";
        InvalidEDocumentErr: Label 'The E-Document must exist before its purchase draft can be persisted.';
        IncomingEDocumentRequiredErr: Label 'Purchase draft persistence requires an incoming E-Document.';
    begin
        if EDocument."Entry No" = 0 then
            Error(InvalidEDocumentErr);

        if EDocument.Direction <> EDocument.Direction::Incoming then
            Error(IncomingEDocumentRequiredErr);

        if not ExistingEDocument.Get(EDocument."Entry No") then
            Error(InvalidEDocumentErr);

        if ExistingEDocument.Direction <> ExistingEDocument.Direction::Incoming then
            Error(IncomingEDocumentRequiredErr);

        EDocPurchaseDraftUtility.PersistDraft(ExistingEDocument, TempEDocPurchaseHeader, TempEDocPurchaseLine);
    end;
}
