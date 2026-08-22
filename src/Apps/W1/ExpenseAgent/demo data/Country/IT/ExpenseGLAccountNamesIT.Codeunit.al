// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8480 "Expense GL Account Names IT"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EntertainmentAndPRTok: Label 'Entertainment and PR', MaxLength = 100;
        TravelTok: Label 'Travel', MaxLength = 100;
        GasolineAndMotorOilTok: Label 'Gasoline and Motor Oil', MaxLength = 100;
        MiscellaneousTok: Label 'Miscellaneous', MaxLength = 100;
        InvoiceRoundingTok: Label 'Invoice Rounding', MaxLength = 100;
        SalesOtherJobExpensesTok: Label 'Sales, Other Job Expenses', MaxLength = 100;

    procedure EntertainmentAndPRName(): Text[100]
    begin
        exit(EntertainmentAndPRTok);
    end;

    procedure TravelName(): Text[100]
    begin
        exit(TravelTok);
    end;

    procedure GasolineAndMotorOilName(): Text[100]
    begin
        exit(GasolineAndMotorOilTok);
    end;

    procedure MiscellaneousName(): Text[100]
    begin
        exit(MiscellaneousTok);
    end;

    procedure InvoiceRoundingName(): Text[100]
    begin
        exit(InvoiceRoundingTok);
    end;

    procedure SalesOtherJobExpensesName(): Text[100]
    begin
        exit(SalesOtherJobExpensesTok);
    end;
}
