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
        page "EA Corp Card Statement" = X,
        page "EA Corp Card Statement Trans" = X,
        page "EA Corp Card Statements" = X,
        page "EA Corp Card Settlement" = X,
        page "EA Corp Card Settlement Lines" = X,
        page "EA Corp Card Settlements" = X,
        codeunit "EA Create Corp Card Setup" = X,
        codeunit "EA Corp Card Post Mgt" = X,
        codeunit "EA Corp Card Statement Mgt" = X,
        codeunit "EA Corp Card Settlement Mgt" = X,
        codeunit "EA Corp Card DE Noop" = X,
        tabledata "EA Corp Card Provider" = IM,
        tabledata "EA Corp Card" = IM,
        tabledata "EA Corp Card Trans" = IM,
        tabledata "EA Corp Card Trans Detail" = IM,
        tabledata "EA Corp Card Statement" = IM,
        tabledata "EA Corp Card Settlement" = IM,
        tabledata "EA Corp Card Settlement Line" = IM,
        tabledata "EA Corp Card Exception" = IM,
        tabledata "EA Corp Card MCC Map" = IM,
        tabledata "EA Corp Card Merchant Rule" = IM,
        tabledata "Expense Agent Setup" = IM;
}