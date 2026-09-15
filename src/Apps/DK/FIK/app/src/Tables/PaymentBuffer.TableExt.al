// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Purchases.Payables;

#pragma warning disable AL0520 // Accepted: the base table is obsolete but this extension must remain for upgrade compatibility.
tableextension 13621 PaymentBuffer extends "Payment Buffer"
#pragma warning restore AL0520
{
    fields
    {
        field(13651; GiroAccNo; Code[8]) { Caption = 'Giro Acc No.'; MaskType = Concealed; }
    }
}
