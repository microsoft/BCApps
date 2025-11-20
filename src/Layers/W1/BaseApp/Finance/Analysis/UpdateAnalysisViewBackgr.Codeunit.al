// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

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
