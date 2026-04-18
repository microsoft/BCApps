// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

permissionset 685 "Paym. Prac. Objects"
{
    Access = Public;
    Assignable = false;

    Permissions =
#if NOT CLEAN29
#pragma warning disable AL0432
        table "Payment Period" = X,
#pragma warning restore AL0432
#endif
        table "Payment Period Header" = X,
        table "Payment Period Line" = X,
        table "Payment Practice Data" = X,
        table "Payment Practice Line" = X,
        table "Payment Practice Header" = X,
        table "Paym. Prac. Dispute Ret. Data" = X,
        report "Payment Practice" = X,
        report "Paym. Prac. AU Declaration" = X,
#if NOT CLEAN29
#pragma warning disable AL0432
        page "Payment Periods" = X,
#pragma warning restore AL0432
#endif
        page "Payment Period Card" = X,
        page "Payment Period List" = X,
        page "Payment Period Subpage" = X,
        page "Payment Practice Data List" = X,
        page "Payment Practice Card" = X,
        page "Paym. Prac. Dispute Ret. Card" = X,
        page "Payment Practice Lines" = X,
        page "Payment Practice List" = X,
        codeunit "Paym. Prac. Cust. Generator" = X,
        codeunit "Paym. Prac. CV Generator" = X,
        codeunit "Paym. Prac. Period Aggregator" = X,
        codeunit "Paym. Prac. Size Aggregator" = X,
        codeunit "Paym. Prac. Vendor Generator" = X,
        codeunit "Paym. Prac. Standard Handler" = X,
        codeunit "Paym. Prac. Dispute Ret. Hdlr" = X,
        codeunit "Paym. Prac. Small Bus. Handler" = X,
        codeunit "Paym. Prac. GB CSV Export" = X,
        codeunit "Paym. Prac. AU CSV Export" = X,
        codeunit "Upgrade Payment Practices" = X,
        codeunit "Install Payment Practices" = X,
        codeunit "Payment Practice Builders" = X,
        codeunit "Payment Practice Math" = X,
        codeunit "Payment Practices" = X;
}
