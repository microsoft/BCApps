// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Foundation.Reporting;

codeunit 13467 "Depreciation Differences FI Subscribers"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnAfterSubstituteReport(ReportId: Integer; var NewReportId: Integer)
#if not CLEAN29
    var
        FeatureCU: Codeunit "Depreciation Differences FI Feature";
#endif
    begin
#if not CLEAN29
        if not FeatureCU.IsEnabled() then
            exit;
#endif
        if ReportId = 13402 then
            NewReportId := Report::"Calc. and Post Depr. Diff.";
    end;
}
