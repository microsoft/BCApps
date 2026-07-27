// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7223 EACorpCardJQRunner
{
    Access = Internal;

    trigger OnRun()
    var
        CorpCardFeedMgt: Codeunit EACorpCardFeedMgt;
    begin
        CorpCardFeedMgt.RunAllEnabledProviders();
    end;
}