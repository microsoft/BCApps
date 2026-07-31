// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7222 EACorpCardImportOrch
{
    Access = Internal;

    internal procedure RunProvider(CorpCardProvider: Record EACorpCardProvider)
    var
        CorpCardBatch: Record EACorpCardBatch;
        CorpCardProvReg: Codeunit EACorpCardProvReg;
        AuditSubscribers: Codeunit EACorpCardAuditSubscribers;
        CorpCardProviderImpl: Interface EACorpCardProviderInterface;
    begin
        CorpCardProvReg.ResolveProvider(CorpCardProvider, CorpCardProviderImpl);

        CorpCardBatch.Init();
        CorpCardBatch."Provider Code" := CorpCardProvider.Code;
        CorpCardBatch."Started DT" := CurrentDateTime();
        CorpCardBatch.Status := CorpCardBatch.Status::Started;
        CorpCardBatch.Insert(true);

        AuditSubscribers.LogImportStarted(CorpCardProvider.Code, CorpCardBatch."Batch No.");

        CorpCardProviderImpl.Download(CorpCardBatch);
        CorpCardProviderImpl.ParseToStaging(CorpCardBatch."Batch No.");
        CorpCardProviderImpl.Ack(CorpCardBatch."Batch No.");

        CorpCardBatch.Get(CorpCardBatch."Batch No.");
        if CorpCardBatch.Status <> CorpCardBatch.Status::Failed then
            CorpCardBatch.Status := CorpCardBatch.Status::Completed;

        CorpCardBatch."Ended DT" := CurrentDateTime();
        CorpCardBatch.Modify();

        if CorpCardBatch.Status = CorpCardBatch.Status::Completed then
            AuditSubscribers.LogImportCompleted(CorpCardProvider.Code, CorpCardBatch."Batch No.", CorpCardBatch.Imported, CorpCardBatch.Exceptions, CorpCardBatch.Duplicates);

        CorpCardProvider."Last Import DT" := CurrentDateTime();
        CorpCardProvider."Last Batch No." := CorpCardBatch."Batch No.";
        CorpCardProvider.Modify();
    end;
}