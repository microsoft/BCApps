// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

enum 7000025 "Cartera Document Doc. Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Invoice") { Caption = 'Invoice'; }
    value(1; "Credit Memo") { Caption = 'Credit Memo'; }
    value(2; "Bill") { Caption = 'Bill'; }
}
