// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.Reporting;

using Microsoft.Purchases.Setup;

codeunit 11004 "Report Sel. Purch. Subscribers"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Page, Page::"Report Selection - Purchase", 'OnSetUsageFilterOnAfterSetFiltersByReportUsage', '', false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Purchase")
    begin
        case ReportUsage2 of
            ReportUsage2::"Delivery Reminder Test":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Delivery Reminder Test");
            ReportUsage2::"Issued Delivery Reminder":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Issued Delivery Reminder");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Report Selection - Purchase", 'OnInitUsageFilterOnElseCase', '', false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Purchase")
    begin
        case ReportUsage of
            ReportUsage::"Delivery Reminder Test":
                ReportUsage2 := ReportUsage2::"Delivery Reminder Test";
            ReportUsage::"Issued Delivery Reminder":
                ReportUsage2 := ReportUsage2::"Issued Delivery Reminder";
        end;
    end;
}