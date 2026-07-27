// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 7212 EACorpCardRead
{
    Access = Internal;
    Assignable = false;
    Caption = 'Corp Card Read';

    Permissions =
        tabledata EACorpCardProvider = R,
        tabledata EACorpCard = R,
        tabledata EACorpCardTrans = R,
        tabledata EACorpCardTransDetail = R,
        tabledata EACorpCardBatch = R,
        tabledata EACorpCardException = R,
        tabledata EACorpCardMCCMap = R,
        tabledata EACorpCardMerchantRule = R,
        tabledata EACorpCardSetup = R;
}