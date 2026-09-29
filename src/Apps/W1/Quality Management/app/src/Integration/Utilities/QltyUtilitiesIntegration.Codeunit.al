// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Utilities;

using Microsoft.QualityManagement.Document;
using Microsoft.Utilities;

codeunit 20418 "Qlty. Utilities Integration"
{
    InherentPermissions = X;

    /// <summary>
    /// Provides the quality inspection card page for quality inspection header records.
    /// </summary>
    /// <param name="RecRef">The record for which to resolve a card page.</param>
    /// <param name="CardPageID">The resolved card page ID.</param>
    /// <param name="IsHandled">Set to true when the card page ID is resolved.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnBeforeGetConditionalCardPageID', '', true, true)]
    local procedure HandleOnBeforeGetConditionalCardPageID(RecRef: RecordRef; var CardPageID: Integer; var IsHandled: Boolean)
    begin
        if RecRef.Number() <> Database::"Qlty. Inspection Header" then
            exit;

        CardPageID := Page::"Qlty. Inspection";
        IsHandled := true;
    end;

    /// <summary>
    /// Provides the quality inspection list page for non-temporary quality inspection header records.
    /// </summary>
    /// <param name="RecRef">The record for which to resolve a list page.</param>
    /// <param name="PageID">The resolved list page ID.</param>
    /// <param name="IsHandled">Set to true when the list page ID is resolved.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnBeforeGetConditionalListPageID', '', true, true)]
    local procedure HandleOnBeforeGetConditionalListPageID(RecRef: RecordRef; var PageID: Integer; var IsHandled: Boolean);
    begin
        if RecRef.IsTemporary() then
            exit;

        if RecRef.Number() <> Database::"Qlty. Inspection Header" then
            exit;

        PageID := Page::"Qlty. Inspection List";
        IsHandled := true;
    end;
}
