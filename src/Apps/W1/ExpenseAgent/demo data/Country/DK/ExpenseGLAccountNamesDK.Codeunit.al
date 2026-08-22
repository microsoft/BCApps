// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8289 "Expense GL Account Names DK"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EntwinetobaccospiritsTok: Label 'Ent., Wine / Tobacco / Spirits', MaxLength = 100;
        PrepaymentsAccruedCostsTok: Label 'Prepayments - Accrued Costs', MaxLength = 100;
        CentdiscrepanciesTok: Label 'Cent Discrepancies', MaxLength = 100;
        RestaurantdiningTok: Label 'Restaurant Dining', MaxLength = 100;
        MileagerateTok: Label 'Mileage Rate', MaxLength = 100;
        TravelingtradefairsetcTok: Label 'Traveling, Trade Fairs etc.', MaxLength = 100;
        AccountsPayablePostingTok: Label 'Accounts Payables', MaxLength = 100;
        BankTok: Label 'Bank', MaxLength = 100;
        DomesticsalesofgoodsandservicesTok: Label 'Domestic Sales of Goods and Services', MaxLength = 100;

    procedure EntwinetobaccospiritsName(): Text[100]
    begin
        exit(EntwinetobaccospiritsTok);
    end;

    procedure PrepaymentsAccruedCostsName(): Text[100]
    begin
        exit(PrepaymentsAccruedCostsTok);
    end;

    procedure CentdiscrepanciesName(): Text[100]
    begin
        exit(CentdiscrepanciesTok);
    end;

    procedure RestaurantdiningName(): Text[100]
    begin
        exit(RestaurantdiningTok);
    end;

    procedure MileagerateName(): Text[100]
    begin
        exit(MileagerateTok);
    end;

    procedure TravelingtradefairsetcName(): Text[100]
    begin
        exit(TravelingtradefairsetcTok);
    end;

    procedure AccountsPayablePostingName(): Text[100]
    begin
        exit(AccountsPayablePostingTok);
    end;

    procedure BankName(): Text[100]
    begin
        exit(BankTok);
    end;

    procedure DomesticsalesofgoodsandservicesName(): Text[100]
    begin
        exit(DomesticsalesofgoodsandservicesTok);
    end;
}
