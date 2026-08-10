// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

interface "EA Corp Card Exp Writer"
{
    procedure CreateDraftFromTrans(var CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20]);
    procedure LinkPosted(var CorpCardTrans: Record "EA Corp Card Trans"; PostedDocNo: Code[20]);
}