// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

enum 10722 "ES Bill Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Bill of Exchange") { Caption = 'Bill of Exchange'; }
    value(2; "Receipt") { Caption = 'Receipt'; }
    value(3; "IOU") { Caption = 'IOU'; }
    value(4; "Check") { Caption = 'Check'; }
    value(5; "Transfer") { Caption = 'Transfer'; }
}
