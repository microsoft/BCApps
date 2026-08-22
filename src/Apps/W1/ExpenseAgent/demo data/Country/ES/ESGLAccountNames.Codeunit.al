// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8276 "ES GL Account Names"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        OtherBusinessExpensesTok: Label 'Other Business Expenses', MaxLength = 100;
        RemunerationAdvancesTok: Label 'Remuneration Advances', MaxLength = 100;
        BanksEuroTok: Label 'Banks Euro', MaxLength = 100;
        InternalResourcesTok: Label 'Internal Resources', MaxLength = 100;
        ProfitOrLossTok: Label 'Profit or Loss', MaxLength = 100;

    procedure OtherBusinessExpensesName(): Text[100]
    begin
        exit(OtherBusinessExpensesTok);
    end;

    procedure RemunerationAdvancesName(): Text[100]
    begin
        exit(RemunerationAdvancesTok);
    end;

    procedure BanksEuroName(): Text[100]
    begin
        exit(BanksEuroTok);
    end;

    procedure InternalResourcesName(): Text[100]
    begin
        exit(InternalResourcesTok);
    end;

    procedure ProfitOrLossName(): Text[100]
    begin
        exit(ProfitOrLossTok);
    end;
}
