// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Job Queue runner for corporate card imports.
/// Executes provider imports via Job Queue scheduler with error handling and telemetry.
/// </summary>
codeunit 7223 EACorpCardJQRunner
{
    Access = Internal;

    procedure RunImport()
    var
        CorpCardFeedMgt: Codeunit EACorpCardFeedMgt;
        ErrorMsg: Text;
    begin
        ErrorMsg := '';
        CorpCardFeedMgt.RunAllEnabledProviders();
    end;
}