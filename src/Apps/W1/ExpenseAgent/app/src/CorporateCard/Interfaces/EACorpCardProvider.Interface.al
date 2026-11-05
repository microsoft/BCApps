// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

interface "EA Corp Card Provider"
{
    procedure Download(var CorpCardStatement: Record "EA Corp Card Statement");
    procedure ParseToStaging(StatementEntryNo: Integer);
    procedure Ack(StatementEntryNo: Integer);
}