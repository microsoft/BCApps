// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

interface IEACorpCardProvider
{
    procedure Download(var CorpCardBatch: Record EACorpCardBatch);
    procedure ParseToStaging(BatchNo: Integer);
    procedure Ack(BatchNo: Integer);
}