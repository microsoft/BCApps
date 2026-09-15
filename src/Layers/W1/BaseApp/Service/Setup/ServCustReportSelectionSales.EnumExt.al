// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Service.Setup;

using Microsoft.Sales.Setup;

enumextension 5900 "Serv.Cust.ReportSelectionSales" extends "Custom Report Selection Sales"
{
    value(5900; "Service Quote") { Caption = 'Service Quote'; }
    value(5901; "Service Order") { Caption = 'Service Order'; }
    value(5902; "Service Invoice") { Caption = 'Service Invoice'; }
    value(5903; "Service Credit Memo") { Caption = 'Service Credit Memo'; }
}
