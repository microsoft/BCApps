// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8481 "Expense GL Account Names CH"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        RoundingDifferencesPurchaseTok: Label 'Rounding Differences Purchase', MaxLength = 100;
        OtherPersonnelCostsTok: Label 'Other Personnel Costs', MaxLength = 100;
        TravelCostsCustomerServiceTok: Label 'Travel Costs, Customer Service', MaxLength = 100;
        MiscCostsTok: Label 'Misc. Costs', MaxLength = 100;
        JobSalesAppliedAccountTok: Label 'Job Sales Applied Account', MaxLength = 100;

    procedure RoundingDifferencesPurchaseName(): Text[100]
    begin
        exit(RoundingDifferencesPurchaseTok);
    end;

    procedure OtherPersonnelCostsName(): Text[100]
    begin
        exit(OtherPersonnelCostsTok);
    end;

    procedure TravelCostsCustomerServiceName(): Text[100]
    begin
        exit(TravelCostsCustomerServiceTok);
    end;

    procedure MiscCostsName(): Text[100]
    begin
        exit(MiscCostsTok);
    end;

    procedure JobSalesAppliedAccountName(): Text[100]
    begin
        exit(JobSalesAppliedAccountTok);
    end;
}
