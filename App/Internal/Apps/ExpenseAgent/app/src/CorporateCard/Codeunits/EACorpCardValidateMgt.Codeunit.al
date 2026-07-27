// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7245 EACorpCardValidateMgt
{
    Access = Internal;

    internal procedure ValidateTrans(var CorpCardTrans: Record EACorpCardTrans): Boolean
    begin
        if CorpCardTrans."Provider Code" = '' then
            exit(false);
        if CorpCardTrans."Card Id" = '' then
            exit(false);
        if CorpCardTrans."Provider Trans Id" = '' then
            exit(false);
        if CorpCardTrans."Trans Date" = 0D then
            exit(false);

        exit(true);
    end;
}