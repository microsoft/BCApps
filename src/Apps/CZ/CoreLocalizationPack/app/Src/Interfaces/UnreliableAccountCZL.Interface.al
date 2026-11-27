// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Purchases.Vendor;

interface "Unreliable Account CZL"
{
    procedure CreateBankAccount(UnreliablePayerEntryCZL: Record "Unreliable Payer Entry CZL"; AccountNo: Code[20]; BankAccountCode: Code[10]; BankAccountName: Text[100]; PreferredBankAccount: Boolean): RecordId;
    procedure CheckBankAccountNotExists(UnreliablePayerEntryCZL: Record "Unreliable Payer Entry CZL"; AccountNo: Code[20]);
}
