// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

enum 1254 "Bank Acc. Rec. Stmt. Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Bank Reconciliation") { Caption = 'Bank Reconciliation'; }
    value(1; "Payment Application") { Caption = 'Payment Application'; }
}
