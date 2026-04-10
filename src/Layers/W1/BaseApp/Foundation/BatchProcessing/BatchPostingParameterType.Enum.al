// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

enum 1370 "Batch Posting Parameter Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Invoice") { Caption = 'Invoice'; }
    value(1; "Ship") { Caption = 'Ship'; }
    value(2; "Receive") { Caption = 'Receive'; }
    value(3; "Posting Date") { Caption = 'Posting Date'; }
    value(4; "Replace Posting Date") { Caption = 'Replace Posting Date'; }
    value(5; "Replace Document Date") { Caption = 'Replace Document Date'; }
    value(6; "Calculate Invoice Discount") { Caption = 'Calculate Invoice Discount'; }
    value(7; "Print") { Caption = 'Print'; }
    value(8; "VAT Date") { Caption = 'VAT Date'; }
    value(9; "Replace VAT Date") { Caption = 'Replace VAT Date'; }
}
