// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;
using Microsoft.DemoData.Sales;
using Microsoft.DemoTool.Helpers;

codeunit 8217 "Create Posted Expense Report"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "Expense Per Diem" = rim,
        tabledata "Expense Report Line" = rim;

    trigger OnRun()
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        if ExpenseReportHeader.FindLast() then
            FromExpenseReportNo := ExpenseReportHeader."No.";

        CreateExpenseReportToPost();

        if not SkipPostingExpenseReport() then
            PostExpenseReport();
    end;

    local procedure CreateExpenseReportToPost()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        CreateEmployee: Codeunit "Create Employee";
        CreateCustomer: Codeunit "Create Customer";
        ContosoUtility: Codeunit "Contoso Utilities";
        CreateExpenseUser: Codeunit "Create Expense User";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpCategories: Codeunit "Create Expense Categories DM";
        CreateExpenseSubcategories: Codeunit "Create Expense Subcategories";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
    begin
        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.JO(), ContosoUtility.AdjustDate(19021204D), ContosoUtility.AdjustDate(19021204D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.GarageService(), '', WindshieldReplacementLbl, CashPaymentLbl, ContosoUtility.AdjustDate(19021116D), '', 1020, VanArsdelLtdLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'TY60035601', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Car(), '', PetrolLbl, '', ContosoUtility.AdjustDate(19021123D), '', 72.45, LakeshoreRetailLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '7365856835388002', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Parking(), '', ParkingLbl, '', ContosoUtility.AdjustDate(19021123D), '', 15, '', CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '3457573573456438790', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Tolls(), '', TollRoadUsageFeeLbl, '', ContosoUtility.AdjustDate(19021123D), '', 8.5, '', CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '847963200631045', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);

        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.LT(), ContosoUtility.AdjustDate(19021204D), ContosoUtility.AdjustDate(19021204D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.LT(), CreateExpCategories.Courier(), '', NePhoneDeliveringLbl, '', ContosoUtility.AdjustDate(19021115D), '', 40, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '76FDG900435N67724', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.LT(), CreateExpCategories.Misc(), '', SupportingMaterialLbl, '', ContosoUtility.AdjustDate(19021130D), '', 169.54, BoulderInnovationsLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'TOY7458580025', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);

        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.MH(), ContosoUtility.AdjustDate(19021204D), ContosoUtility.AdjustDate(19021204D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.MH(), CreateExpCategories.GroundTransportation(), '', ToTheClientSiteLbl, '', ContosoUtility.AdjustDate(19021118D), '', 33.5, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '65687534FR87879', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.MH(), CreateExpCategories.Meals(), '', LunchAfterClientSiteLbl, '', ContosoUtility.AdjustDate(19021118D), '', 22.36, BestForYouOrganicsCompanyLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'HJE456481100478', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);

        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.EH(), ContosoUtility.AdjustDate(19030104D), ContosoUtility.AdjustDate(19030104D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021214D), '', 16.5, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'U475685468456', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021214D), '', 28, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'F6456785467', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.GroundTransportation(), '', TaxiDriveToClientLocationLbl, '', ContosoUtility.AdjustDate(19021214D), '', 19.5, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'K75678546875', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Hotels(), '', HotelStayInPhiladelphiaLbl, '', ContosoUtility.AdjustDate(19021216D), '', 450, FabrikamResidencesLbl, CreateExpensePaymentMethod.Card(), true, true, CreateCustomer.DomesticAdatumCorporation(), 0DT, 0DT, 0, 0, '', '', 'FGH6765HUTYRI7583-05', '', '');
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 10000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Breakfast(), BreakfastLbl, 0D, 40);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 20000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Room(), AccommodationDailyRateLbl, 0D, 380);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 30000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Tax(), HotelTaxesLbl, 0D, 30);
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        UpdateExpenseReportLine(ExpenseReportHeader."No.", 40000, Enum::"Expense Line Type"::"G/L Account", '');
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Tolls(), '', TollChargesDuringTravelLbl, '', ContosoUtility.AdjustDate(19021218D), '', 4.5, '', CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '6435K7453644445', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Morale(), '', CelebratingSuccessfulFiscalYearLbl, AllowedBudgetForManagersLbl, ContosoUtility.AdjustDate(19021227D), '', 1200, FourthCoffeeLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'D4563456K45645', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 10000, CreateExpCategories.Morale(), Enum::"Expense Participant Type"::Employee, CreateEmployee.ManagingDirector(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 20000, CreateExpCategories.Morale(), Enum::"Expense Participant Type"::Employee, CreateEmployee.SalesManager(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 30000, CreateExpCategories.Morale(), Enum::"Expense Participant Type"::Employee, CreateEmployee.Designer(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 40000, CreateExpCategories.Morale(), Enum::"Expense Participant Type"::Employee, CreateEmployee.ProductionAssistant(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 50000, CreateExpCategories.Morale(), Enum::"Expense Participant Type"::Employee, CreateEmployee.ProductionManager(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 60000, CreateExpCategories.Morale(), Enum::"Expense Participant Type"::Employee, CreateEmployee.Secretary(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 70000, CreateExpCategories.Morale(), Enum::"Expense Participant Type"::Employee, CreateEmployee.InventoryManager(), '', '', '', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Parking(), '', PublicParkingLbl, '', ContosoUtility.AdjustDate(19021228D), '', 40, '', CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '6.54643566756454E+18', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Car(), '', PetrolForCompanyCarLbl, '', ContosoUtility.AdjustDate(19021228D), '', 64.5, LakeshoreRetailLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '8667856898656767', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Subscription(), '', SubscriptionRenewalLbl, '', ContosoUtility.AdjustDate(19021230D), '', 42, SchoolOfFineArtsLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'SUB003464353', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Tolls(), '', TollRoadUsageFeeLbl, '', ContosoUtility.AdjustDate(19021230D), '', 4.5, '', CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '3653456L6454645', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Car(), '', PetrolForTheCorpCarLbl, '', ContosoUtility.AdjustDate(19021230D), '', 32.55, LakeshoreRetailLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '2768678964568767', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
    end;

    var
        FromExpenseReportNo: Code[20];
        TailwindTradersLbl: Label 'Tailwind Traders', MaxLength = 100;
        FourthCoffeeLbl: Label 'Fourth Coffee', MaxLength = 100;
        BreakfastLbl: Label 'Breakfast', MaxLength = 100;
        HotelTaxesLbl: Label 'Hotel Taxes', MaxLength = 100;
        VanArsdelLtdLbl: Label 'VanArsdel, Ltd.', MaxLength = 100;
        WindshieldReplacementLbl: Label 'Windshield replacement - company car', MaxLength = 100;
        CashPaymentLbl: Label 'Service didn''t accept corp card so had to pay with the cash', MaxLength = 100;
        PetrolLbl: Label 'Petrol', MaxLength = 100;
        LakeshoreRetailLbl: Label 'Lakeshore Retail', MaxLength = 100;
        ParkingLbl: Label 'Parking', MaxLength = 100;
        TollRoadUsageFeeLbl: Label 'Toll / Road usage fee', MaxLength = 100;
        NePhoneDeliveringLbl: Label 'Ne phone delivering', MaxLength = 100;
        SupportingMaterialLbl: Label 'Supporting material for the project', MaxLength = 100;
        BoulderInnovationsLbl: Label 'Boulder Innovations', MaxLength = 100;
        ToTheClientSiteLbl: Label 'To the client site', MaxLength = 100;
        LunchAfterClientSiteLbl: Label 'Lunch after client site', MaxLength = 100;
        BestForYouOrganicsCompanyLbl: Label 'Best For You Organics Company', MaxLength = 100;
        TaxiDriveToClientLocationLbl: Label 'Taxi drive to the client location', MaxLength = 100;
        HotelStayInPhiladelphiaLbl: Label 'Hotel stay in Philadelphia', MaxLength = 100;
        TollChargesDuringTravelLbl: Label 'Toll charges during travel', MaxLength = 100;
        CelebratingSuccessfulFiscalYearLbl: Label 'Celebrating successful fiscal year', MaxLength = 100;
        PublicParkingLbl: Label 'Public parking', MaxLength = 100;
        PetrolForCompanyCarLbl: Label 'Petrol for company car', MaxLength = 100;
        SubscriptionRenewalLbl: Label 'Subscription renewal', MaxLength = 100;
        PetrolForTheCorpCarLbl: Label 'Petrol for the corp car', MaxLength = 100;
        AllowedBudgetForManagersLbl: Label 'Allowed budget for managers', MaxLength = 100;
        FabrikamResidencesLbl: Label 'Fabrikam Residences', MaxLength = 100;
        SchoolOfFineArtsLbl: Label 'School of Fine Arts', MaxLength = 100;
        AccommodationDailyRateLbl: Label 'Accommodation - daily rate', MaxLength = 100;

    local procedure ReleaseAndAddExpenseToExpenseReport(Expense: Record Expense; ExpenseReportHeader: Record "Expense Report Header")
    var
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        Expense.Get(Expense."No.");
        ReleaseExpenseDocument.Run(Expense);

        CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
    end;

    local procedure PostExpenseReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        if FromExpenseReportNo <> '' then
            ExpenseReportHeader.SetFilter("No.", '>%1', FromExpenseReportNo);

        if ExpenseReportHeader.FindSet() then
            repeat
                Codeunit.Run(Codeunit::"Expense Report-Post", ExpenseReportHeader);
            until ExpenseReportHeader.Next() = 0;
    end;

    // Posting fails on localizations because the "Expense GL Account Names" labels are not translated yet, so no G/L account is found.
    // Found during uptake; remove this skip once the translations are generated.
    local procedure SkipPostingExpenseReport(): Boolean
    begin
        exit(true);
    end;

    local procedure UpdateExpenseReportLine(ExpenseReportNo: Code[20]; LineNo: Integer; AccountType: Enum "Expense Line Type"; AccountNo: Code[20])
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        OnDefineExpenseAccountNo(AccountNo);

        ExpenseReportLine.Get(ExpenseReportNo, LineNo);

        ExpenseReportLine.Validate("Account Type", AccountType);
        ExpenseReportLine.Validate("Account No.", AccountNo);
        ExpenseReportLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDefineExpenseAccountNo(var AccountNo: Code[20])
    begin
    end;
}