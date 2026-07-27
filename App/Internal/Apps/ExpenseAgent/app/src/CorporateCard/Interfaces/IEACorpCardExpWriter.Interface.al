// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

interface IEACorpCardExpWriter
{
    procedure CreateDraftFromTrans(var CorpCardTrans: Record EACorpCardTrans; var ExpenseNo: Code[20]);
    procedure LinkPosted(var CorpCardTrans: Record EACorpCardTrans; PostedDocNo: Code[20]);
}