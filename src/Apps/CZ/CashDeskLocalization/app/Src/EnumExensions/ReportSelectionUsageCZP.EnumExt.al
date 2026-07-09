// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

using Microsoft.Foundation.Reporting;

enumextension 11713 "Report Selection Usage CZP" extends "Report Selection Usage"
{
    value(11710; "Cash Receipt CZP")
    {
        Caption = 'Cash Receipt';
    }
    value(11711; "Cash Withdrawal CZP")
    {
        Caption = 'Cash Withdrawal';
    }
    value(11712; "Posted Cash Receipt CZP")
    {
        Caption = 'Posted Cash Receipt';
    }
    value(11713; "Posted Cash Withdrawal CZP")
    {
        Caption = 'Posted Cash Withdrawal';
    }
}
