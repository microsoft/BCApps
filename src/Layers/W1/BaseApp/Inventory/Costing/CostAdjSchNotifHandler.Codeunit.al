// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Setup;

codeunit 2847 "Cost Adj. Sch. Notif. Handler"
{
    var
        SchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        LearnMoreLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2148858';

    procedure ShouldDisplayNotification(Rec: Record "Inventory Setup"; xRec: Record "Inventory Setup"): Boolean
    begin
        if
            xRec."Automatic Cost Posting" and
            not Rec."Automatic Cost Posting" and
            not SchedulingManager.PostInvCostToGLJobQueueExists()
        then
            exit(true);

        if
            (xRec."Automatic Cost Adjustment" <> Rec."Automatic Cost Adjustment"::Never) and
            (Rec."Automatic Cost Adjustment" = Rec."Automatic Cost Adjustment"::Never) and
            not SchedulingManager.AdjCostJobQueueExists()
        then
            exit(true);

        exit(false);
    end;

    procedure OnActionSchedule()
    begin
        Page.RunModal(Page::"Cost Adj. Scheduling Wizard");
    end;

    procedure OnActionLearnMore()
    begin
        Hyperlink(LearnMoreLinkLbl);
    end;
}
