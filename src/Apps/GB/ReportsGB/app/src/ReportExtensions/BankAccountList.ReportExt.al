// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

reportextension 10582 "Bank Account - List" extends "Bank Account - List"
{
    RDLCLayout = './src/ReportExtensions/BankAccountList.rdlc';
    dataset
    {
        add("Bank Account")
        {
            column(Bank_Account__Bank_Branch_No___; "Bank Branch No.")
            {
            }
            column(Bank_Account__Bank_Branch_No___Caption; FieldCaption("Bank Branch No."))
            {
            }
        }
    }

}
