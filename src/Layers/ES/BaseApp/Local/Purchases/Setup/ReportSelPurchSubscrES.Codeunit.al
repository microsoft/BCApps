// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using Microsoft.Foundation.Reporting;

codeunit 7000087 "Report Sel. Purch. Subscr. ES"
{
    [EventSubscriber(ObjectType::Page, Page::"Report Selection - Purchase", 'OnSetUsageFilterOnAfterSetFiltersByReportUsage', '', false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Purchase")
    begin
        case ReportUsage2 of
            ReportUsage2::"Auto Invoice":
                Rec.SetRange(Usage, Rec.Usage::"P.AutoInvoice");
            ReportUsage2::"Auto Credit Memo":
                Rec.SetRange(Usage, Rec.Usage::"P.AutoCr.Memo");
        end;
    end;
}
