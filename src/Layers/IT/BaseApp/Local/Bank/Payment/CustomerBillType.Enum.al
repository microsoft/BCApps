// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

enum 12174 "Customer Bill Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Bills For Collection") { Caption = 'Bills For Collection'; }
    value(2; "Bills For Discount") { Caption = 'Bills For Discount'; }
    value(3; "Bills Subject To Collection") { Caption = 'Bills Subject To Collection'; }
}
