// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 7421 EACorpCardEdit
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
        tabledata "EA Corp Card Provider" = IM,
        tabledata "EA Corp Card" = IM,
        tabledata "EA Corp Card Trans" = IM,
        tabledata "EA Corp Card Trans Detail" = IM,
        tabledata "EA Corp Card Batch" = IM,
        tabledata "EA Corp Card Exception" = IM,
        tabledata "EA Corp Card MCC Map" = IM,
        tabledata "EA Corp Card Merchant Rule" = IM,
        tabledata "Expense Agent Setup" = IM;
}