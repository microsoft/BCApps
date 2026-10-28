// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Threading;

/// <summary>
/// Job Queue runner for corporate card imports.
/// Imports the provider stored in the job queue entry's Record ID to Process, or all enabled providers when none is set.
/// </summary>
codeunit 7433 "EA Corp Card JQ Runner"
{
    Access = Internal;
    TableNo = "Job Queue Entry";
    Permissions = tabledata "EA Corp Card Provider" = r;

    trigger OnRun()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
        ProviderRecordRef: RecordRef;
    begin
        if Format(Rec."Record ID to Process") = '' then begin
            RunImport();
            exit;
        end;

        if Rec."Record ID to Process".TableNo <> Database::"EA Corp Card Provider" then
            exit;
        if not ProviderRecordRef.Get(Rec."Record ID to Process") then
            exit;

        ProviderRecordRef.SetTable(CorpCardProvider);
        if CorpCardProvider.Enabled and not CorpCardProvider.IsFileBasedImport() then
            CorpCardFeedMgt.RunImport(CorpCardProvider.Code);
    end;

    procedure RunImport()
    var
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        CorpCardFeedMgt.RunAllEnabledProviders();
    end;
}