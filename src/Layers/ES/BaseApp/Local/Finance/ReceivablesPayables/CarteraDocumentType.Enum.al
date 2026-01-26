// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

enum 7000000 "Cartera Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Receivable") { Caption = 'Receivable'; }
    value(1; "Payable") { Caption = 'Payable'; }
}
