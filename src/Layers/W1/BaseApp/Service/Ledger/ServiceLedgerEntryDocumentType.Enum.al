// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Ledger;

#pragma warning disable AL0659
enum 5909 "Service Ledger Entry Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Payment") { Caption = 'Payment'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(4; "Finance Charge Memo") { Caption = 'Finance Charge Memo'; }
    value(5; "Reminder") { Caption = 'Reminder'; }
    value(6; "Refund") { Caption = 'Refund'; }
    value(7; "Shipment") { Caption = 'Shipment'; }
}
