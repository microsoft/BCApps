// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Setup;

enum 842 "Cash Flow Table Name"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Cash Flow Forecast") { Caption = 'Cash Flow Forecast'; }
    value(1; "Cash Flow Account") { Caption = 'Cash Flow Account'; }
}
