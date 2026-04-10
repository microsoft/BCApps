// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Handles background processing of analysis view updates triggered by posting operations.
/// Automatically updates analysis views configured for real-time posting integration.
/// </summary>
/// <remarks>
/// Called automatically by posting routines when analysis views are configured with "Update on Posting" enabled.
/// Processes only non-blocked analysis views to maintain data consistency during transaction posting.
/// </remarks>
codeunit 406 "Update Analysis View Backgr."
{
    Permissions = TableData "Analysis View" = r;
    InherentPermissions = X;

    trigger OnRun()
    var
        AnalysisView: Record "Analysis View";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        AnalysisView.SetRange(Blocked, false);
        AnalysisView.SetRange("Update on Posting", true);
        if AnalysisView.IsEmpty() then
            exit;
        UpdateAnalysisView.UpdateAll(AnalysisView, 0, true);
    end;
}
