// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 7422 EACorpCardRead
{
    Access = Internal;
    Assignable = false;
    Caption = 'Corp Card Read';

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
        tabledata "EA Corp Card Provider" = R,
        tabledata "EA Corp Card" = R,
        tabledata "EA Corp Card Trans" = R,
        tabledata "EA Corp Card Trans Detail" = R,
        tabledata "EA Corp Card Statement" = R,
        tabledata "EA Corp Card Settlement" = R,
        tabledata "EA Corp Card Settlement Line" = R,
        tabledata "EA Corp Card Exception" = R,
        tabledata "EA Corp Card MCC Map" = R,
        tabledata "EA Corp Card Merchant Rule" = R,
        tabledata "Expense Agent Setup" = R;
}