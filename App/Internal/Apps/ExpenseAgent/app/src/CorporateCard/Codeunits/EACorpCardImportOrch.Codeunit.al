// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7242 EACorpCardImportOrch
{
    Access = Internal;

    internal procedure RunProvider(CorpCardProvider: Record EACorpCardProvider)
    var
        CorpCardBatch: Record EACorpCardBatch;
        CorpCardProvReg: Codeunit EACorpCardProvReg;
        CorpCardProviderImpl: Interface IEACorpCardProvider;
    begin
        CorpCardProvReg.ResolveProvider(CorpCardProvider, CorpCardProviderImpl);

        CorpCardBatch.Init();
        CorpCardBatch."Provider Code" := CorpCardProvider.Code;
        CorpCardBatch."Started DT" := CurrentDateTime();
        CorpCardBatch.Status := CorpCardBatch.Status::Started;
        CorpCardBatch.Insert(true);

        CorpCardProviderImpl.Download(CorpCardBatch);
        CorpCardProviderImpl.ParseToStaging(CorpCardBatch."Batch No.");
        CorpCardProviderImpl.Ack(CorpCardBatch."Batch No.");

        CorpCardBatch."Ended DT" := CurrentDateTime();
        CorpCardBatch.Status := CorpCardBatch.Status::Completed;
        CorpCardBatch.Modify();

        CorpCardProvider."Last Import DT" := CurrentDateTime();
        CorpCardProvider."Last Batch No." := CorpCardBatch."Batch No.";
        CorpCardProvider.Modify();
    end;
}