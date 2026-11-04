// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7436 "EA Corp Card Stmt Status"
{
    Caption = 'Corp Card Statement Status';

    value(0; Importing)
    {
        Caption = 'Importing';
    }
    value(1; Imported)
    {
        Caption = 'Imported';
    }
    value(2; Failed)
    {
        Caption = 'Failed';
    }
    value(3; Validated)
    {
        Caption = 'Validated';
    }
    value(4; Closed)
    {
        Caption = 'Closed';
    }
    value(5; ReconciliationRequired)
    {
        Caption = 'Reconciliation Required';
    }
}