// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7246 EACorpCardDedupMgt
{
    Access = Internal;

    internal procedure IsDuplicate(CorpCardTrans: Record EACorpCardTrans): Boolean
    var
        ExistingCorpCardTrans: Record EACorpCardTrans;
    begin
        ExistingCorpCardTrans.SetRange("Provider Code", CorpCardTrans."Provider Code");
        ExistingCorpCardTrans.SetRange("Provider Trans Id", CorpCardTrans."Provider Trans Id");
        ExistingCorpCardTrans.SetRange("Card Id", CorpCardTrans."Card Id");
        ExistingCorpCardTrans.SetRange("Trans Date", CorpCardTrans."Trans Date");
        ExistingCorpCardTrans.SetRange(Amount, CorpCardTrans.Amount);
        ExistingCorpCardTrans.SetRange("Currency Code", CorpCardTrans."Currency Code");

        exit(not ExistingCorpCardTrans.IsEmpty());
    end;
}