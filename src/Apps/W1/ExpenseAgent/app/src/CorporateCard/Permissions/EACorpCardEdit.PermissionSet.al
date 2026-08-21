// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 7211 EACorpCardEdit
{
    Access = Internal;
    Assignable = false;
    Caption = 'Corp Card Edit';

    IncludedPermissionSets = EACorpCardRead;

    Permissions =
        page "EA Corp Card Details" = X,
        page "EA Corp Card JQ Schedule" = X,
        page "EA Corp Card JQ Schedule Sub" = X,
        codeunit "EA Create Corp Card Setup" = X,
        codeunit "EA Create Corp Card L3 Demo" = X,
        codeunit "EA Corp Card DE Noop" = X,
        tabledata "EA Corp Card Provider" = M,
        tabledata "EA Corp Card" = M,
        tabledata "EA Corp Card Trans" = M,
        tabledata "EA Corp Card Trans Detail" = M,
        tabledata "EA Corp Card Batch" = M,
        tabledata "EA Corp Card Exception" = M,
        tabledata "EA Corp Card MCC Map" = M,
        tabledata "EA Corp Card Merchant Rule" = M,
        tabledata "Expense Agent Setup" = M;
}