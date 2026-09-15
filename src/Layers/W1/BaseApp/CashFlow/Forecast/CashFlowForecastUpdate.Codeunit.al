// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using System.Environment;
using System.Security.User;
using System.Threading;

codeunit 842 "Cash Flow Forecast Update"
{

    trigger OnRun()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        [SecurityFiltering(SecurityFilter::Ignored)]
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowManagement: Codeunit "Cash Flow Management";
        OriginalWorkDate: Date;
    begin
        if (not CashFlowForecast.WritePermission) or
           (not CashFlowWorksheetLine.WritePermission)
        then
            exit;

        RemoveScheduledTaskIfUserInactive();

        OriginalWorkDate := WorkDate();
        WorkDate := LogInManagement.GetDefaultWorkDate();
        if CashFlowSetup.Get() then
            CashFlowManagement.UpdateCashFlowForecast(CashFlowSetup."Azure AI Enabled");
        WorkDate := OriginalWorkDate;
    end;

    var
        LogInManagement: Codeunit LogInManagement;

    local procedure RemoveScheduledTaskIfUserInactive()
    var
        JobQueueEntry: Record "Job Queue Entry";
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
        JobQueueManagement: Codeunit "Job Queue Management";
        FromDate: Date;
    begin
        FromDate := CalcDate('<-2W>');

        if not UserLoginTimeTracker.AnyUserLoggedInSinceDate(FromDate) then
            JobQueueManagement.DeleteJobQueueEntries(JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"Cash Flow Forecast Update");
    end;
}

