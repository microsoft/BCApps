// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 7213 EACorpCardAdmin
{
    Access = Internal;
    Assignable = false;
    Caption = 'Corp Card Admin';

    IncludedPermissionSets = EACorpCardEdit;

    Permissions =
        page EACorpCardJQSchedule = X,
        page EACorpCardJQScheduleSubpage = X,
        codeunit "Create Corp Card Setup" = X,
        codeunit EACorpCardDENoop = X,
        tabledata EACorpCardProvider = D,
        tabledata EACorpCard = D,
        tabledata EACorpCardTrans = D,
        tabledata EACorpCardTransDetail = D,
        tabledata EACorpCardBatch = D,
        tabledata EACorpCardException = D,
        tabledata EACorpCardMCCMap = D,
        tabledata EACorpCardMerchantRule = D,
        tabledata "Expense Agent Setup" = D;
}