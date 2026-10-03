// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.PostingHandler;

permissionset 20334 "TAX ENGINE POSTING"
{
    Access = Public;
    Assignable = true;
    Caption = 'Tax Engine Posting Handler';

    Permissions = tabledata "Tax Insert Record" = RIMD,
                  tabledata "Tax Insert Record Field" = RIMD,
                  tabledata "Transaction Posting Buffer" = RIMD,
                  tabledata "Tax Posting Keys Buffer" = RIMD,
                  tabledata "Tax Posting Setup" = RIMD;
}
