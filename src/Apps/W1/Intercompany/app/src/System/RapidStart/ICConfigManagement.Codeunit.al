// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using Microsoft.Intercompany.Partner;

/// <summary>
/// Extends Config. Management with Intercompany-specific page ID resolution.
/// Handles the IC Partner table when resolving the default page via OnFindPage event.
/// </summary>
codeunit 8531 "IC Config. Management"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Management", 'OnFindPage', '', false, false)]
    local procedure OnFindPage(TableID: Integer; var PageID: Integer)
    begin
        if TableID <> Database::"IC Partner" then
            exit;

        PageID := Page::"IC Partner List";
    end;
}
