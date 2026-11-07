// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Compensations;

using Microsoft.Purchases.Setup;

enumextension 11709 "Report Sel. Usage Vendor CZC" extends "Report Selection Usage Vendor"
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
