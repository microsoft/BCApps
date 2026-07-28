// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 7211 EACorpCardEdit
{
    Access = Internal;
    Assignable = false;
    Caption = 'Corp Card Edit';

    IncludedPermissionSets = EACorpCardRead;

    Permissions =
        page EACorpCardJQSchedule = X,
        page EACorpCardJQScheduleSubpage = X,
        tabledata EACorpCardProvider = M,
        tabledata EACorpCard = M,
        tabledata EACorpCardTrans = M,
        tabledata EACorpCardTransDetail = M,
        tabledata EACorpCardBatch = M,
        tabledata EACorpCardException = M,
        tabledata EACorpCardMCCMap = M,
        tabledata EACorpCardMerchantRule = M,
        tabledata EACorpCardSetup = M;
}