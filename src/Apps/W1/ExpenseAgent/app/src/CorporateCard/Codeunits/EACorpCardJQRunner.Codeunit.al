// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Job Queue runner for corporate card imports.
/// Executes provider imports via Job Queue scheduler with error handling and telemetry.
/// </summary>
codeunit 7433 "EA Corp Card JQ Runner"
{
    Access = Internal;

    trigger OnRun()
    begin
        RunImport();
    end;

    procedure RunImport()
    var
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        CorpCardFeedMgt.RunAllEnabledProviders();
    end;
}