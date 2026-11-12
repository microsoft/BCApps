// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

interface "EA Corp Card Expense Match"
{
    Access = Internal;

    procedure MatchExistingExpense(CorpCardTrans: Record "EA Corp Card Trans"; var MatchedDocumentId: RecordId): Boolean;
    procedure LinkExpense(var CorpCardTrans: Record "EA Corp Card Trans"; MatchedDocumentId: RecordId);
    procedure LinkExpense(var CorpCardTrans: Record "EA Corp Card Trans"; ExpenseNo: Code[20]);
}
