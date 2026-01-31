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
    /// To identify the card for custom table, which in turns helps Graphical Scheduler know to use the card with 'Details'
    /// </summary>
    /// <param name="RecRef"></param>
    /// <param name="CardPageID"></param>
    /// <param name="IsHandled"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnBeforeGetConditionalCardPageID', '', true, true)]
    local procedure HandleOnBeforeGetConditionalCardPageID(RecRef: RecordRef; var CardPageID: Integer; var IsHandled: Boolean)
    begin
        if RecRef.Number() <> Database::"Qlty. Inspection Header" then
            exit;

        CardPageID := Page::"Qlty. Inspection";
        IsHandled := true;
    end;

    /// <summary>
    /// Required for use with Business Central approval integration.
    /// </summary>
    /// <param name="RecRef"></param>
    /// <param name="PageID"></param>
    /// <param name="IsHandled"></param>
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
