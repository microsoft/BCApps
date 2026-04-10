// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 131 "Incoming Doc. Selection Action"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "CreateGenJnlLine") { }
    value(1; "CreatePurchInvoice") { }
    value(2; "CreatePurchCreditMemo") { }
    value(3; "CreateSalesInvoice") { }
    value(4; "CreateSalesCreditMemo") { }
    value(5; "Release") { }
    value(6; "Reopen") { }
    value(7; "Reject") { }
    value(8; "CreateDocument") { }
    value(9; "SetReadyForOcr") { }
    value(10; "UndoReadyForOcr") { }
    value(11; "SendToOcr") { }
    value(12; "CreateGenJnlLineWithDataExchange") { }
    value(13; "CreateManually") { }
}
