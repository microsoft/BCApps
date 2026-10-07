// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Compensations;

using Microsoft.Foundation.Reporting;

enumextension 11710 "Report Selection Usage CZC" extends "Report Selection Usage"
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
