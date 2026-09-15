// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 7213 EACorpCardAdmin
{
    Access = Internal;
    Assignable = false;
    Caption = 'Corp Card Admin';

    IncludedPermissionSets = EACorpCardEdit;

    Permissions =
        page "EA Corp Card Details" = X,
        page "EA Corp Card JQ Schedule" = X,
        page "EA Corp Card JQ Schedule Sub" = X,
        codeunit "EA Create Corp Card Setup" = X,
        codeunit "EA Create Corp Card L3 Demo" = X,
        codeunit "EA Corp Card DE Noop" = X,
        tabledata "EA Corp Card Provider" = D,
        tabledata "EA Corp Card" = D,
        tabledata "EA Corp Card Trans" = D,
        tabledata "EA Corp Card Trans Detail" = D,
        tabledata "EA Corp Card Batch" = D,
        tabledata "EA Corp Card Exception" = D,
        tabledata "EA Corp Card MCC Map" = D,
        tabledata "EA Corp Card Merchant Rule" = D,
        tabledata "Expense Agent Setup" = D;
}