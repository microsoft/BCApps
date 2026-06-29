// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

using Microsoft.Sales.Setup;

enumextension 11714 "Custom Report Sel. Sales CZP" extends "Custom Report Selection Sales"
{
    value(11710; "Cash Receipt CZP")
    {
        Caption = 'Cash Receipt';
    }
    value(11711; "Posted Cash Receipt CZP")
    {
        Caption = 'Posted Cash Receipt';
    }
}
