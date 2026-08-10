// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.Foundation;
using Microsoft.DemoData.HumanResources;
using Microsoft.DemoData.Sales;
using Microsoft.DemoTool.Helpers;

codeunit 8216 "Create Expense"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Expense Per Diem" = rim;

    trigger OnRun()
    begin
        CreateOpenExpense();

        UpdateLastExpenseNo();

        CreateReleasedExpense();
        ReleaseExpense();
    end;

    local procedure CreateOpenExpense()
    var
        Expense: Record Expense;
        CreateEmployee: Codeunit "Create Employee";
        CreateCountryRegion: Codeunit "Create Country/Region";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.LT(), CreateExpCategories.Tips(), '', TipsForCourierLbl, '', ContosoUtility.AdjustDate(19021115D), '', 10, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), false, false, '', 0DT, 0DT, 0, 0, '', '', '', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.LT(), CreateExpCategories.GroundTransportation(), '', TaxiDriveClientLocationLbl, '', ContosoUtility.AdjustDate(19030129D), '', 28, TailwindTradersLbl, CreateExpensePaymentMethod.Cash(), false, false, '', 0DT, 0DT, 0, 0, '', '', 'QWC4574556657', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Personal(), '', PersonalPurchaseLbl, '', ContosoUtility.AdjustDate(19030129D), '', 30, SouthridgeVideoLbl, CreateExpensePaymentMethod.Card(), false, false, '', 0DT, 0DT, 0, 0, '', '', '5643345644', '', '');

        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Entertain(), '', BusinessDinnerWithPartnersLbl, NegotiatingContractLbl, ContosoUtility.AdjustDate(19030116D), '', 650, FourthCoffeeLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'YJ87680099531', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 10000, CreateExpCategories.Entertain(), Enum::"Expense Participant Type"::Employee, CreateEmployee.SalesManager(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 20000, CreateExpCategories.Entertain(), Enum::"Expense Participant Type"::Employee, CreateEmployee.Secretary(), '', '', '', '', '');
        ContosoExpenseAgent.InsertExpenseParticipant(Expense."No.", 30000, CreateExpCategories.Entertain(), Enum::"Expense Participant Type"::External, '', RaymondHillardLbl, NodPublishersLbl, CreateCountryRegion.US(), GeneralManagerLbl, 'raymond.hillard@contoso.com');
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);

        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Airline(), '', FlightTicketNYParisNYLbl, '', ContosoUtility.AdjustDate(19030127D), '', 1985.6, MargiesTravelLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'KL5J6L', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Airline(), '', FlightTicketNYParisNYLbl, '', ContosoUtility.AdjustDate(19030127D), '', 1985.6, MargiesTravelLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'KASDIG', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Airline(), '', UpgradeToBusinessClassLbl, '', ContosoUtility.AdjustDate(19030128D), '', 1084.25, MargiesTravelLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'KL5J6L', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Events(), '', TreyResearchConferenceLbl, '', ContosoUtility.AdjustDate(19030202D), CreateCurrency.DKK(), 12500, TreyResearchLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'JHKJY8784', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Events(), '', TreyResearchConferenceLbl, '', ContosoUtility.AdjustDate(19030202D), CreateCurrency.DKK(), 12500, TreyResearchLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'KLUJF8467', '', '');
    end;

    local procedure CreateReleasedExpense()
    var
        Expense: Record Expense;
        CreateCustomer: Codeunit "Create Customer";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpenseSubcategories: Codeunit "Create Expense SubCategories";
    begin
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Car(), '', PetrolLbl, '', ContosoUtility.AdjustDate(19030106D), '', 26.8, LakeshoreRetailLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '9806345567686678', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.MH(), CreateExpCategories.Gifts(), '', CorporateGiftForRelecloudLbl, '', ContosoUtility.AdjustDate(19030106D), '', 45, TailspinToysLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'JU67KL0954002', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Meals(), '', LunchLbl, '', ContosoUtility.AdjustDate(19030107D), '', 24, BestForYouOrganicsCompanyLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'K54734767765K96', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Meals(), '', LunchLbl, '', ContosoUtility.AdjustDate(19030113D), CreateCurrency.EUR(), 20, LibertyDelightfulSinfulBakeryCafeLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'OP4364576455-83', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.LT(), CreateExpCategories.GroundTransportation(), '', TaxiDriveClientLocationLbl, '', ContosoUtility.AdjustDate(19030107D), '', 46.5, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'JU84735675687', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Meals(), '', LunchLbl, '', ContosoUtility.AdjustDate(19030114D), CreateCurrency.EUR(), 25, LibertyDelightfulSinfulBakeryCafeLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'PR5667543646-16', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Tolls(), '', TollChargesDuringTravelLbl, '', ContosoUtility.AdjustDate(19030114D), '', 7, '', CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '34654N764356456', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Meals(), '', LunchLbl, '', ContosoUtility.AdjustDate(19030114D), '', 19.5, BestForYouOrganicsCompanyLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'UIM453675675557', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser."OF"(), CreateExpCategories.Gifts(), '', CorporateGiftForLamnaHealthcareLbl, '', ContosoUtility.AdjustDate(19030116D), '', 60, LakeshoreRetailLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '555787891', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.GroundTransportation(), '', TaxiDriveClientLocationLbl, '', ContosoUtility.AdjustDate(19030116D), '', 19.5, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'RT675456886865', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.GroundTransportation(), '', TaxiDriveAirportHotelLbl, '', ContosoUtility.AdjustDate(19030116D), CreateCurrency.EUR(), 20, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'VF576756856788', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Meals(), '', LunchLbl, '', ContosoUtility.AdjustDate(19030116D), '', 26.3, BestForYouOrganicsCompanyLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'QTR223687600256', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.RB(), CreateExpCategories.Mileage(), '', UsingPrivateCarForBusinessTripLbl, TransportExpensesCoveredByCustomerLbl, ContosoUtility.AdjustDate(19030118D), '', 0, '', CreateExpensePaymentMethod.Cash(), true, true, CreateCustomer.DomesticRelecloud(), 0DT, 0DT, 0, 124, 'NY', 'NJ', '', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Car(), '', PetrolLbl, '', ContosoUtility.AdjustDate(19030118D), '', 19.9, LakeshoreRetailLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 0, 0, '', '', '2247999965686705', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.Subscription(), '', SchoolOfFineArtsLbl, '', ContosoUtility.AdjustDate(19030118D), '', 42, SchoolOfFineArtsLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'SUB003873530', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.TD(), CreateExpCategories.Gifts(), '', CorporateGiftForThePhoneCompanyLbl, CEOBirthdayLbl, ContosoUtility.AdjustDate(19030122D), '', 180, TailspinToysLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '594672100', '', '');

        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.JO(), CreateExpCategories.Hotels(), '', HotelStayInWashingtonDCLbl, '', ContosoUtility.AdjustDate(19030122D), '', 990, AlpineSkiHouseLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', '687FF8989-655-0057674', 'PR00010', '240');
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 10000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Room(), DailyRoomRateLbl, ContosoUtility.AdjustDate(19030120D), 385);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 20000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Breakfast(), BreakfastLbl, ContosoUtility.AdjustDate(19030121D), 36);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 30000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Room(), DailyRoomRateLbl, ContosoUtility.AdjustDate(19030121D), 385);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 40000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Breakfast(), BreakfastLbl, ContosoUtility.AdjustDate(19030122D), 36);
        ContosoExpenseAgent.InsertExpenseItemization(Expense."No.", 50000, CreateExpCategories.Hotels(), CreateExpenseSubcategories.Tax(), TaxesLbl, ContosoUtility.AdjustDate(19030122D), 148);

        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategories.GroundTransportation(), '', TaxiDriveClientLocationLbl, '', ContosoUtility.AdjustDate(19030122D), '', 30, TailwindTradersLbl, CreateExpensePaymentMethod.Card(), true, false, '', 0DT, 0DT, 0, 0, '', '', 'VFM53675733367', '', '');
        ContosoExpenseAgent.InsertExpense(CreateExpenseUser.TD(), CreateExpCategories.Pharmacy(), '', PharmacyExpenseForHealthNeedsLbl, '', ContosoUtility.AdjustDate(19030122D), '', 49, LamnaHealthcareCompanyLbl, CreateExpensePaymentMethod.Cash(), true, false, '', 0DT, 0DT, 19, 0, '', '', 'UG45756485653466', '', '');
    end;

    var
        ContosoUtility: Codeunit "Contoso Utilities";
        CreateCurrency: Codeunit "Create Currency";
        CreateExpenseUser: Codeunit "Create Expense User";
        CreateExpCategories: Codeunit "Create Expense Categories DM";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
        LastExpenseNo: Code[20];
        TipsForCourierLbl: Label 'Tips for courier', MaxLength = 100;
        TailwindTradersLbl: Label 'Tailwind Traders', MaxLength = 100;
        PersonalPurchaseLbl: Label 'Personal purchase', MaxLength = 100;
        TaxiDriveClientLocationLbl: Label 'Taxi drive to the client location', MaxLength = 100;
        SouthridgeVideoLbl: Label 'Southridge Video', MaxLength = 100;
        BusinessDinnerWithPartnersLbl: Label 'Business dinner with partners', MaxLength = 100;
        NegotiatingContractLbl: Label 'Negotiating the $3M contract', MaxLength = 100;
        FlightTicketNYParisNYLbl: Label 'Flight ticket NY/PARIS/NY', MaxLength = 100;
        UpgradeToBusinessClassLbl: Label 'Upgrade to business class', MaxLength = 100;
        TreyResearchConferenceLbl: Label 'Tickets for the Trey Research Yearly Conference', MaxLength = 100;
        FourthCoffeeLbl: Label 'Fourth Coffee', MaxLength = 100;
        RaymondHillardLbl: Label 'Raymond Hillard', MaxLength = 100;
        NodPublishersLbl: Label 'Nod Publishers', MaxLength = 100;
        MargiesTravelLbl: Label 'Margie''s Travel', MaxLength = 100;
        TreyResearchLbl: Label 'Trey Research', MaxLength = 100;
        PetrolLbl: Label 'Petrol', MaxLength = 100;
        CorporateGiftForRelecloudLbl: Label 'Corporate gift for Relecloud', MaxLength = 100;
        LakeshoreRetailLbl: Label 'Lakeshore Retail', MaxLength = 100;
        TailspinToysLbl: Label 'Tailspin Toys', MaxLength = 100;
        LunchLbl: Label 'Lunch', MaxLength = 100;
        BestForYouOrganicsCompanyLbl: Label 'Best For You Organics Company', MaxLength = 100;
        LibertyDelightfulSinfulBakeryCafeLbl: Label 'Liberty''s Delightful Sinful Bakery & Cafe', MaxLength = 100;
        TollChargesDuringTravelLbl: Label 'Toll charges during travel', MaxLength = 100;
        CorporateGiftForLamnaHealthcareLbl: Label 'Corporate gift purchase for Lamna Healthcare Company', MaxLength = 100;
        TaxiDriveAirportHotelLbl: Label 'Taxi drive airport-hotel', MaxLength = 100;
        UsingPrivateCarForBusinessTripLbl: Label 'Using private car for a business trip', MaxLength = 100;
        TransportExpensesCoveredByCustomerLbl: Label 'Transport expenses covered by customer', MaxLength = 100;
        SchoolOfFineArtsLbl: Label 'School of Fine Arts', MaxLength = 100;
        CorporateGiftForThePhoneCompanyLbl: Label 'Corporate gift for The Phone Company', MaxLength = 100;
        CEOBirthdayLbl: Label 'CEO birthday', MaxLength = 100;
        HotelStayInWashingtonDCLbl: Label 'Hotel stay in Washington DC', MaxLength = 100;
        AlpineSkiHouseLbl: Label 'Alpine Ski House', MaxLength = 100;
        PharmacyExpenseForHealthNeedsLbl: Label 'Pharmacy expense for health needs', MaxLength = 100;
        LamnaHealthcareCompanyLbl: Label 'Lamna Healthcare Company', MaxLength = 100;
        DailyRoomRateLbl: Label 'Daily room rate', MaxLength = 100;
        BreakfastLbl: Label 'Breakfast', MaxLength = 100;
        TaxesLbl: Label 'Taxes', MaxLength = 100;
        GeneralManagerLbl: Label 'General Manager', MaxLength = 30;

    local procedure UpdateLastExpenseNo()
    var
        Expense: Record Expense;
    begin
        if Expense.FindLast() then
            LastExpenseNo := Expense."No.";
    end;

    local procedure ReleaseExpense()
    var
        Expense: Record Expense;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        if LastExpenseNo <> '' then
            Expense.SetFilter("No.", '>%1', LastExpenseNo);

        if Expense.FindSet() then
            repeat
                ReleaseExpenseDocument.Run(Expense);
            until Expense.Next() = 0;
    end;
}