// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Document;

using Microsoft.Purchases.Document;
using System.Environment;

codeunit 6405 "E-Doc Reporting Triggers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", SubstituteReport, '', false, false)]
    local procedure SubstituteStandardPurchaseOrder(ReportId: Integer; var NewReportId: Integer)
    begin
        if ReportId = Report::"Standard Purchase - Order" then
            NewReportId := Report::"E-Doc Standard Purchase Order";
    end;
}
