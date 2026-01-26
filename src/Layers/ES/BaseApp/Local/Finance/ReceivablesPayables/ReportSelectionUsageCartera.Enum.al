// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

enum 7000045 "Report Selection Usage Cartera"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Bill Group") { Caption = 'Bill Group'; }
    value(1; "Posted Bill Group") { Caption = 'Posted Bill Group'; }
    value(2; "Closed Bill Group") { Caption = 'Closed Bill Group'; }
    value(3; "Bill") { Caption = 'Bill'; }
    value(4; "Bill Group - Test") { Caption = 'Bill Group - Test'; }
    value(5; "Payment Order") { Caption = 'Payment Order'; }
    value(6; "Posted Payment Order") { Caption = 'Posted Payment Order'; }
    value(7; "Payment Order - Test") { Caption = 'Payment Order - Test'; }
    value(8; "Closed Payment Order") { Caption = 'Closed Payment Order'; }
}
