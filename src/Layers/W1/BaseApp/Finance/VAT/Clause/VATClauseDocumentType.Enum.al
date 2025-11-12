// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

enum 562 "VAT Clause Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(2; Invoice) { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(4; Reminder) { Caption = 'Reminder'; }
    value(5; "Finance Charge Memo") { Caption = 'Finance Charge Memo'; }
}
