// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

interface "Expense Agent Country Data"
{
    procedure CreateSetupData();
    procedure CreateMasterData();
    procedure CreateTransactionalData();
    procedure CreateHistoricalData();
}
