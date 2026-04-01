// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports;

codeunit 4406 "EXT Aged Acc. Caption Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"EXR Aging Report Buffer", 'OnOverrideAgedBy', '', false, false)]
    local procedure HandleOverrideAgedBy(var EXRAgingReportBuffer: Record "EXR Aging Report Buffer" temporary)
    begin
        EXRAgingReportBuffer."Aged By" := TempGlobalEXRAgingReportBuffer."Aged By";
    end;

    internal procedure SetGlobalEXRAgingReportBuffer(var EXRAgingReportBuffer: Record "EXR Aging Report Buffer" temporary)
    begin
        TempGlobalEXRAgingReportBuffer.Copy(EXRAgingReportBuffer);
    end;

    var
        TempGlobalEXRAgingReportBuffer: Record "EXR Aging Report Buffer";
}