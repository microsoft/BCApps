// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 334 "Column Layout Show"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Always") { Caption = 'Always'; }
    value(1; "Never") { Caption = 'Never'; }
    value(2; "When Positive") { Caption = 'When Positive'; }
    value(3; "When Negative") { Caption = 'When Negative'; }
}
