// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Compensations;

using Microsoft.Sales.Setup;

enumextension 11711 "Custom Report Sel. Sales CZC" extends "Custom Report Selection Sales"
{
    value(11700; "Compensation CZC")
    {
        Caption = 'Compensation';
    }
    value(11701; "Posted Compensation CZC")
    {
        Caption = 'Posted Compensation';
    }
}
