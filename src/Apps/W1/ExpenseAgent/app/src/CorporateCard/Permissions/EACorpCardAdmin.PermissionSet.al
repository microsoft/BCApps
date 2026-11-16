// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 7423 EACorpCardAdmin
{
    Access = Internal;
    Assignable = false;
    Caption = 'Corp Card Admin';

    IncludedPermissionSets = EACorpCardEdit;

    Permissions =
        page "EA Corp Card Details" = X,
        page "EA Corp Card JQ Schedule" = X,
        page "EA Corp Card JQ Schedule Sub" = X,
        page "EA Corp Card Statement" = X,
        page "EA Corp Card Statement Trans" = X,
        page "EA Corp Card Statements" = X,
        page "EA Corp Card Settlement" = X,
        page "EA Corp Card Settlement Lines" = X,
        page "EA Corp Card Settlements" = X,
        codeunit "EA Create Corp Card Setup" = X,
        codeunit "EA Corp Card DE Noop" = X,
        tabledata "EA Corp Card Provider" = D,
        tabledata "EA Corp Card" = D,
        tabledata "EA Corp Card Trans" = D,
        tabledata "EA Corp Card Trans Detail" = D,
        tabledata "EA Corp Card Statement" = D,
        tabledata "EA Corp Card Settlement" = D,
        tabledata "EA Corp Card Settlement Line" = D,
        tabledata "EA Corp Card Exception" = D,
        tabledata "EA Corp Card MCC Map" = D,
        tabledata "EA Corp Card Merchant Rule" = D,
        tabledata "Expense Agent Setup" = D;
}