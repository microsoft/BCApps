#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;
using Microsoft.DemoTool.Helpers;

codeunit 11609 "Create Posted Exp. Report US"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';
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

        PostExpenseReport();
    end;

    local procedure CreateExpenseReportToPost()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        CreateEmployee: Codeunit "Create Employee";
        CreateCurrency: Codeunit "Create Currency";
        ContosoUtility: Codeunit "Contoso Utilities";
        CreateExpenseUser: Codeunit "Create Expense User";
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpCategories: Codeunit "Create Expense Categories DM";
        CreateExpCategoriesUS: Codeunit "Create Expense Categories US";
        CreateExpenseSubcategories: Codeunit "Create Expense Subcategories";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
    begin
        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.JO(), ContosoUtility.AdjustDate(19021104D), ContosoUtility.AdjustDate(19021104D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategoriesUS.PerDiem(), CreateExpenseLocation.GermanyAll(), BusinessTripToHamburgLbl, '', ContosoUtility.AdjustDate(19021103D), '', 0, '', CreateExpensePaymentMethod.Cash(), true, false, '', CreateDateTime(ContosoUtility.AdjustDate(19021024D), 064500T), CreateDateTime(ContosoUtility.AdjustDate(19021027D), 161500T), 0, 0, '', '', '', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Airline(), '', AirlineTicketsLbl, '', ContosoUtility.AdjustDate(19021010D), '', 2042, MargieTravelLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'TY6HJO', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);

        ExpenseReportHeader := ContosoExpenseAgent.InsertExpenseReportHeader(CreateExpenseUser.EH(), ContosoUtility.AdjustDate(19021204D), ContosoUtility.AdjustDate(19021204D));
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Airline(), '', AirlineTicketsDublinLbl, TravelToConferenceLbl, ContosoUtility.AdjustDate(19021106D), '', 3120, MargieTravelLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'FIUXHJT', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Events(), '', ITConferenceLbl, '', ContosoUtility.AdjustDate(19021107D), CreateCurrency.EUR(), 1990, ProsewareIncLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'G574576HJ656', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.GroundTransportation(), '', TaxiLbl, '', ContosoUtility.AdjustDate(19021114D), CreateCurrency.EUR(), 45, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '456845856867', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Entertain(), '', BusinessDinnerLbl, BusinessDinnerWithBigPotentialCustomersLbl, ContosoUtility.AdjustDate(19021116D), CreateCurrency.EUR(), 842, FourthCoffeeLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'RT6457560034', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 10000, CreateExpCategories.Entertain(), Enum::"Expense Participant Type"::Employee, CreateEmployee.ManagingDirector(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 20000, CreateExpCategories.Entertain(), Enum::"Expense Participant Type"::Employee, CreateEmployee.SalesManager(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 30000, CreateExpCategories.Entertain(), Enum::"Expense Participant Type"::External, '', JesseHomerLbl, RelecloudLbl, '', CEOLbl, 'jesse.homer@contoso.com');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 40000, CreateExpCategories.Entertain(), Enum::"Expense Participant Type"::External, '', RobertTownesLbl, AdatumCorporationLbl, '', CEOLbl, 'robert.townes@contoso.com');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Hotels(), '', HotelStayLbl, '', ContosoUtility.AdjustDate(19021118D), CreateCurrency.EUR(), 2150, ContosoSuitesLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '64675S879CT987990004', '', '');
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 10000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Room(), AccommodationLbl, ContosoUtility.AdjustDate(19021114D), 390);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 20000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Breakfast(), BreakfastLbl, ContosoUtility.AdjustDate(19021115D), 35);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 30000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Room(), AccommodationLbl, ContosoUtility.AdjustDate(19021115D), 390);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 40000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Breakfast(), BreakfastLbl, ContosoUtility.AdjustDate(19021116D), 35);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 50000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Room(), AccommodationLbl, ContosoUtility.AdjustDate(19021116D), 390);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 60000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.RoomService(), RoomServiceLbl, ContosoUtility.AdjustDate(19021116D), 145);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 70000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Breakfast(), BreakfastLbl, ContosoUtility.AdjustDate(19021117D), 35);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 80000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Room(), AccommodationLbl, ContosoUtility.AdjustDate(19021117D), 390);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 90000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Breakfast(), BreakfastLbl, ContosoUtility.AdjustDate(19021118D), 35);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 100000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Tax(), HotelTaxesLbl, ContosoUtility.AdjustDate(19021118D), 305);
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.RentalCars(), '', CarRentalsLbl, '', ContosoUtility.AdjustDate(19021118D), CreateCurrency.EUR(), 622.45, VanArsdelLtdLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'H6584769867J9J95789', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.GroundTransportation(), '', TaxiLbl, '', ContosoUtility.AdjustDate(19021118D), CreateCurrency.EUR(), 71, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '7456875687568', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategoriesUS.PerDiem(), CreateExpenseLocation.UKOther(), TripToUKLbl, '', ContosoUtility.AdjustDate(19021121D), '', 0, '', CreateExpensePaymentMethod.Cash(), true, false, '', CreateDateTime(ContosoUtility.AdjustDate(19021114D), 053000T), CreateDateTime(ContosoUtility.AdjustDate(19021118D), 220500T), 0, 0, '', '', '', '', '');
        UpdateExpensePerDiem(Expense."No.", 20000, false, false, true);
        UpdateExpensePerDiem(Expense."No.", 40000, false, true, false);
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategoriesUS.PerDiem(), CreateExpenseLocation.Domestic(), TripToDoverLbl, '', ContosoUtility.AdjustDate(19021204D), '', 0, '', CreateExpensePaymentMethod.Cash(), true, false, '', CreateDateTime(ContosoUtility.AdjustDate(19021127D), 070000T), CreateDateTime(ContosoUtility.AdjustDate(19021129D), 145500T), 0, 0, '', '', '', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Mileage(), '', MileageLbl, '', ContosoUtility.AdjustDate(19031101D), '', 0, VanArsdelLtdLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 249, 'New York', 'Dover', 'H6584769867J9J95789', '', '');
        ReleaseAndAddExpenseToExpenseReport(Expense, ExpenseReportHeader);
    end;

    var
        FromExpenseReportNo: Code[20];
        BusinessTripToHamburgLbl: Label 'Business trip to Hamburg, DE', MaxLength = 100;
        AirlineTicketsLbl: Label 'Airline tickets NY/FRANKFURT/HAMBURG/FRANKFURT/NY', MaxLength = 100;
        MargieTravelLbl: Label 'Margie''s Travel', MaxLength = 100;
        AirlineTicketsDublinLbl: Label 'Airline tickets NY/DUBLIN/NY', MaxLength = 100;
        TravelToConferenceLbl: Label 'Travel to the conference', MaxLength = 100;
        ITConferenceLbl: Label 'IT Conference', MaxLength = 100;
        ProsewareIncLbl: Label 'Proseware, Inc.', MaxLength = 100;
        TaxiLbl: Label 'Taxi', MaxLength = 100;
        TailwindTradersLbl: Label 'Tailwind Traders', MaxLength = 100;
        BusinessDinnerLbl: Label 'Business Dinner', MaxLength = 100;
        BusinessDinnerWithBigPotentialCustomersLbl: Label 'Business dinner with a big potential customers', MaxLength = 100;
        FourthCoffeeLbl: Label 'Fourth Coffee', MaxLength = 100;
        JesseHomerLbl: Label 'Jesse Homer', MaxLength = 100;
        RelecloudLbl: Label 'Relecloud', MaxLength = 100;
        RobertTownesLbl: Label 'Robert Townes', MaxLength = 100;
        AdatumCorporationLbl: Label 'Adatum Corporation', MaxLength = 100;
        HotelStayLbl: Label 'Hotel stay', MaxLength = 100;
        ContosoSuitesLbl: Label 'Contoso Suites', MaxLength = 100;
        AccommodationLbl: Label 'Accommodation', MaxLength = 100;
        BreakfastLbl: Label 'Breakfast', MaxLength = 100;
        HotelTaxesLbl: Label 'Hotel Taxes', MaxLength = 100;
        RoomServiceLbl: Label 'Room service', MaxLength = 100;
        CarRentalsLbl: Label 'Car Rentals', MaxLength = 100;
        VanArsdelLtdLbl: Label 'VanArsdel, Ltd.', MaxLength = 100;
        TripToUKLbl: Label 'Trip to UK', MaxLength = 100;
        TripToDoverLbl: Label 'Trip to Dover', MaxLength = 100;
        MileageLbl: Label 'Mileage', MaxLength = 100;
        CEOLbl: Label 'CEO', MaxLength = 30;

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

    local procedure UpdateExpensePerDiem(ExpenseNo: Code[20]; LineNo: Integer; Breakfast: Boolean; Lunch: Boolean; Dinner: Boolean)
    var
        ExpensePerDiem: Record "Expense Per Diem";
    begin
        ExpensePerDiem.Get(ExpenseNo, LineNo);

        ExpensePerDiem.Validate(Breakfast, Breakfast);
        ExpensePerDiem.Validate(Lunch, Lunch);
        ExpensePerDiem.Validate(Dinner, Dinner);
        ExpensePerDiem.Modify();
    end;
}
#endif