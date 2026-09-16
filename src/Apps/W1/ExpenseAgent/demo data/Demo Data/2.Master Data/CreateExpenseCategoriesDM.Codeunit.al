// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8204 "Create Expense Categories DM"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ExpenseCategory: Record "Expense Category";
        CreateExpenseGroup: Codeunit "Create Expense Group";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        ContosoExpenseAgent.InsertExpenseCategory(Airline(), AirlineTicketsLbl, AirlineTicketsPostingLbl, CreateExpensePostingGroup.ExpenseTravel(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Car(), CarUsageFuelMaintenanceLbl, CarUsageFuelMaintenancePostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Courier(), DeliveryExpenseLbl, DeliveryExpensePostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Entertain(), EntertainmentExternalCafeRestaurantLbl, EntertainmentExternalCafeRestaurantPostingLbl, CreateExpensePostingGroup.ExpenseEntertainment(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.FoodBeverage(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::Participants);
        ContosoExpenseAgent.InsertExpenseCategory(Morale(), MoraleEventLbl, MoraleEventPostingLbl, CreateExpensePostingGroup.ExpenseEntertainment(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.FoodBeverage(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::Participants);
        ContosoExpenseAgent.InsertExpenseCategory(Events(), ConferencesAndOtherEventsLbl, ConferencesAndOtherEventsPostingLbl, CreateExpensePostingGroup.ExpenseTravel(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Fines(), FinesLbl, FinesPostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(GarageService(), GarageRepairServicesLbl, GarageRepairServicesPostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Gifts(), GiftCertificatesOrTangibleGiftsLbl, GiftCertificatesOrTangibleGiftsPostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(GroundTransportation(), GroundTransportationLbl, GroundTransportationPostingLbl, CreateExpensePostingGroup.ExpenseTravel(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Hotels(), HotelStayAccommodationLodgingLbl, HotelStayAccommodationLodgingPostingLbl, CreateExpensePostingGroup.ExpenseTravel(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::Itemize);
        ContosoExpenseAgent.InsertExpenseCategory(Internet(), InternetFeesTravelLbl, InternetFeesTravelPostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Meals(), MealsLbl, MealsPostingLbl, CreateExpensePostingGroup.ExpenseMeals(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.FoodBeverage(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Mileage(), MileageLbl, MileagePostingLbl, CreateExpensePostingGroup.ExpenseMileage(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.Personal(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::Mileage);
        ContosoExpenseAgent.InsertExpenseCategory(Misc(), MiscellaneousExpensesLbl, MiscellaneousExpensesPostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.FoodBeverage(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Parking(), ParkingLbl, ParkingPostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Passport(), PassportVisaFeesLbl, PassportVisaFeesPostingLbl, CreateExpensePostingGroup.ExpenseTravel(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Pharmacy(), PharmacyDrugsBandagesGauzeLbl, PharmacyDrugsBandagesGauzePostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Personal(), PersonalExpensesLbl, PersonalExpensesPostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.Personal(), false, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Prepayment(), PrepaymentsCashAdvanceLbl, PrepaymentsCashAdvancePostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), true, false, CreateExpenseGroup.Prepayment(), false, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(RentalCars(), CarRentalsLbl, CarRentalsPostingLbl, CreateExpensePostingGroup.ExpenseRentalCars(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Subscription(), ProfessionalSubscriptionsLbl, ProfessionalSubscriptionsPostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Card(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Credit Card", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Tips(), TipsLbl, TipsPostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.FoodBeverage(), false, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        ContosoExpenseAgent.InsertExpenseCategory(Tolls(), TollRoadUsageFeeLbl, TollRoadUsageFeePostingLbl, CreateExpensePostingGroup.ExpenseOther(), Enum::"Expense Attachment Enforcement"::Warning, CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.DayExpense(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::" ");
        if not ExpenseCategory.Get(PerDiem()) then
            ContosoExpenseAgent.InsertExpenseCategory(PerDiem(), PerDiemLbl, PerDiemPostingLbl, CreateExpensePostingGroup.ExpenseTravel(), Enum::"Expense Attachment Enforcement"::" ", '', false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::" ", Enum::"Expense Detail Needed"::" ");
    end;

    var
        AirlineTok: Label 'AIRLINE', MaxLength = 20, Locked = true;
        CarTok: Label 'CAR', MaxLength = 20, Locked = true;
        CourierTok: Label 'COURIER', MaxLength = 20, Locked = true;
        EntertainTok: Label 'ENTERTAIN', MaxLength = 20, Locked = true;
        EventsTok: Label 'EVENTS', MaxLength = 20, Locked = true;
        GarageServiceTok: Label 'GARAGE-SERVICE', MaxLength = 20, Locked = true;
        GiftsTok: Label 'GIFTS', MaxLength = 20, Locked = true;
        GroundTransportationTok: Label 'GROUNDTRAN', MaxLength = 20, Locked = true;
        HotelsTok: Label 'HOTELS', MaxLength = 20, Locked = true;
        InternetTok: Label 'INTERNET', MaxLength = 20, Locked = true;
        MealsTok: Label 'MEALS', MaxLength = 20, Locked = true;
        MileageTok: Label 'MILEAGE', MaxLength = 20, Locked = true;
        MiscTok: Label 'MISC', MaxLength = 20, Locked = true;
        MoraleTok: Label 'MORALE', MaxLength = 20, Locked = true;
        ParkingTok: Label 'PARKING', MaxLength = 20, Locked = true;
        PassportTok: Label 'PASSPORT', MaxLength = 20, Locked = true;
        PersonalTok: Label 'PERSONAL', MaxLength = 20, Locked = true;
        PharmacyTok: Label 'PHARMACY', MaxLength = 20, Locked = true;
        PrepaymentTok: Label 'PREPAYMENT', MaxLength = 20, Locked = true;
        RentalCarsTok: Label 'RENTALCARS', MaxLength = 20, Locked = true;
        SubscriptionTok: Label 'SUBSCRIPTION', MaxLength = 20, Locked = true;
        TipsTok: Label 'TIPS', MaxLength = 20, Locked = true;
        TollsTok: Label 'TOLLS', MaxLength = 20, Locked = true;
        FinesTok: Label 'FINES', MaxLength = 20, Locked = true;
        PerDiemTok: Label 'PER-DIEM', MaxLength = 20, Locked = true;
        AirlineTicketsLbl: Label 'Expenses for commercial air travel, including airline tickets and airfare. Covers flights, passenger names, routes, carriers, booking references, fares, taxes, seat selection, baggage or change fees, and boarding passes.', MaxLength = 250;
        CarUsageFuelMaintenanceLbl: Label 'Expenses related to company car usage, including fuel, charging, car washes, small tools, consumables, and minor maintenance or repairs performed outside garage service. Excludes major servicing, leasing, and insurance.', MaxLength = 250;
        DeliveryExpenseLbl: Label 'Expenses for courier, delivery, and parcel services used to send or receive documents, packages, or goods. Includes postal services, express couriers, same-day delivery, shipping fees, and related surcharges.', MaxLength = 250;
        EntertainmentExternalCafeRestaurantLbl: Label 'Expenses for external entertainment with current or potential customers or business partners. Includes cafes, restaurants, bars, meals, beverages, and similar hospitality costs incurred for business relationship building.', MaxLength = 250;
        MoraleEventLbl: Label 'Expenses for employee morale and team-building activities, including company or team lunches, dinners, offsites, excursions, social events, and similar internal gatherings intended to improve teamwork, engagement, and company culture.', MaxLength = 250;
        ConferencesAndOtherEventsLbl: Label 'Expenses for business events such as conferences, summits, trade fairs, and exhibitions. Includes registration or entry fees, tickets, booths, badges, event materials, and other costs directly related to event participation.', MaxLength = 250;
        FinesLbl: Label 'Expenses for fines, penalties, and sanctions imposed by authorities or regulators due to violations or non-compliance. Includes traffic fines, regulatory penalties, late fees, and administrative sanctions. Excludes normal taxes and interest.', MaxLength = 250;
        GarageRepairServicesLbl: Label 'Professional garage repair and maintenance services for company cars and trucks. Includes labor and parts for repairs, servicing, diagnostics, inspections, tire services, and routine maintenance performed by authorized or independent garages.', MaxLength = 250;
        GiftCertificatesOrTangibleGiftsLbl: Label 'Expenses for gift certificates or tangible gifts provided to current or potential business partners. Includes vouchers, gift cards, branded or non-branded items, and other physical gifts given for business relationship purposes.', MaxLength = 250;
        GroundTransportationLbl: Label 'Expenses for ground transportation related to business travel, including buses, taxis and cabs, ride-hailing services, trains, metro or subway, trams, ferries or boats, limo services, and similar local or regional transport.', MaxLength = 250;
        HotelStayAccommodationLodgingLbl: Label 'Expenses for hotel and accommodation stays related to business travel. Includes room charges, mandatory hotel fees, city or tourist taxes, and in-stay services charged to the room.', MaxLength = 250;
        InternetFeesTravelLbl: Label 'Expenses for internet and data access related to business activities or travel. Includes hotel Wi-Fi charges, mobile data roaming fees, hotspot usage, prepaid data packages, and temporary internet services incurred while traveling.', MaxLength = 250;
        MealsLbl: Label 'Expenses for meals provided to employees during working hours or business travel. Includes breakfasts, lunches, dinners, and meal allowances consumed during business-related activities. Excludes external entertainment and purely personal meals.', MaxLength = 250;
        MileageLbl: Label 'Expenses for business mileage using a privately owned vehicle. Includes distance-based mileage claims for business travel, calculated per approved mileage rates. Excludes fuel receipts and company car expenses.', MaxLength = 250;
        MiscellaneousExpensesLbl: Label 'Expenses that do not clearly fit into any other defined expense category. Used for infrequent or exceptional business-related costs not covered elsewhere, subject to review and company policy.', MaxLength = 250;
        ParkingLbl: Label 'Expenses for parking related to business travel or work activities. Includes street parking, parking garages, airport parking, meters, and parking fees incurred while using a vehicle for business purposes.', MaxLength = 250;
        PassportVisaFeesLbl: Label 'Expenses for passport, visa, and other travel document fees required for business trips. Includes application, processing, service, and government fees directly related to obtaining travel authorization.', MaxLength = 250;
        PharmacyDrugsBandagesGauzeLbl: Label 'Expenses for pharmacy purchases related to business activities or travel, including medicines, drugs, bandages, gauze, first-aid supplies, and similar medical or health-related items.', MaxLength = 250;
        PersonalExpensesLbl: Label 'Expenses of a personal nature that are not related to business activities or work duties. Includes personal purchases, private travel, leisure activities, and other non-reimbursable costs.', MaxLength = 250;
        PrepaymentsCashAdvanceLbl: Label 'Paid cash allowance for the business trip.', MaxLength = 250;
        CarRentalsLbl: Label 'Expenses for renting cars for business travel. Includes short- or long-term vehicle rental charges, mandatory rental fees, and basic insurance associated with the rental.', MaxLength = 250;
        ProfessionalSubscriptionsLbl: Label 'Expenses for professional or business-related subscriptions. Includes software licenses, online services, professional memberships, journals, publications, and recurring digital services required for work purposes.', MaxLength = 250;
        TipsLbl: Label 'Expenses for tips or gratuities paid in connection with business activities or travel. Includes tips for taxis, restaurants, hotels, delivery, luggage handling, and similar service-related gratuities.', MaxLength = 250;
        TollRoadUsageFeeLbl: Label 'Expenses for tolls and road usage fees incurred during business travel. Includes highway and bridge tolls, congestion charges, road pricing fees, vignettes, and similar charges for using public roads.', MaxLength = 250;
        PerDiemLbl: Label 'Category to be used for automatic per-diem calculations during business travel.', MaxLength = 250;
        PerDiemPostingLbl: Label 'Per Diem', MaxLength = 100;
        AirlineTicketsPostingLbl: Label 'Airline tickets', MaxLength = 100;
        CarUsageFuelMaintenancePostingLbl: Label 'Car usage, Fuel & Maintenance', MaxLength = 100;
        DeliveryExpensePostingLbl: Label 'Delivery expense', MaxLength = 100;
        EntertainmentExternalCafeRestaurantPostingLbl: Label 'Entertainment External, Caffe, Restaurant', MaxLength = 100;
        MoraleEventPostingLbl: Label 'Morale Event', MaxLength = 100;
        ConferencesAndOtherEventsPostingLbl: Label 'Conferences and Other Events', MaxLength = 100;
        FinesPostingLbl: Label 'Fines and penalties', MaxLength = 100;
        GarageRepairServicesPostingLbl: Label 'Garage (car and trucks) repair services', MaxLength = 100;
        GiftCertificatesOrTangibleGiftsPostingLbl: Label 'Gift certificates or Tangible gifts', MaxLength = 100;
        GroundTransportationPostingLbl: Label 'Ground Transportation', MaxLength = 100;
        HotelStayAccommodationLodgingPostingLbl: Label 'Hotel stay, Accommodation & Lodging', MaxLength = 100;
        InternetFeesTravelPostingLbl: Label 'Internet fees - Travel', MaxLength = 100;
        MealsPostingLbl: Label 'Meals', MaxLength = 100;
        MileagePostingLbl: Label 'Mileage - using private car for business purpose', MaxLength = 100;
        MiscellaneousExpensesPostingLbl: Label 'Miscellaneous expenses', MaxLength = 100;
        ParkingPostingLbl: Label 'Parking', MaxLength = 100;
        PassportVisaFeesPostingLbl: Label 'Passport/Visa Fees', MaxLength = 100;
        PharmacyDrugsBandagesGauzePostingLbl: Label 'Pharmacy (drugs, bandages, gauze...)', MaxLength = 100;
        PersonalExpensesPostingLbl: Label 'Personal expenses', MaxLength = 100;
        PrepaymentsCashAdvancePostingLbl: Label 'Prepayments - Cash Advance', MaxLength = 100;
        CarRentalsPostingLbl: Label 'Car Rentals', MaxLength = 100;
        ProfessionalSubscriptionsPostingLbl: Label 'Professional Subscriptions', MaxLength = 100;
        TipsPostingLbl: Label 'Tips', MaxLength = 100;
        TollRoadUsageFeePostingLbl: Label 'Toll / Road Usage Fee', MaxLength = 100;

    procedure Airline(): Code[20]
    begin
        exit(AirlineTok);
    end;

    procedure Car(): Code[20]
    begin
        exit(CarTok);
    end;

    procedure Courier(): Code[20]
    begin
        exit(CourierTok);
    end;

    procedure Entertain(): Code[20]
    begin
        exit(EntertainTok);
    end;

    procedure Events(): Code[20]
    begin
        exit(EventsTok);
    end;

    procedure GarageService(): Code[20]
    begin
        exit(GarageServiceTok);
    end;

    procedure Gifts(): Code[20]
    begin
        exit(GiftsTok);
    end;

    procedure GroundTransportation(): Code[20]
    begin
        exit(GroundTransportationTok);
    end;

    procedure Hotels(): Code[20]
    begin
        exit(HotelsTok);
    end;

    procedure Internet(): Code[20]
    begin
        exit(InternetTok);
    end;

    procedure Meals(): Code[20]
    begin
        exit(MealsTok);
    end;

    procedure Mileage(): Code[20]
    begin
        exit(MileageTok);
    end;

    procedure Misc(): Code[20]
    begin
        exit(MiscTok);
    end;

    procedure Morale(): Code[20]
    begin
        exit(MoraleTok);
    end;

    procedure Parking(): Code[20]
    begin
        exit(ParkingTok);
    end;

    procedure Passport(): Code[20]
    begin
        exit(PassportTok);
    end;

    procedure PerDiem(): Code[20]
    begin
        exit(PerDiemTok);
    end;

    procedure Personal(): Code[20]
    begin
        exit(PersonalTok);
    end;

    procedure Pharmacy(): Code[20]
    begin
        exit(PharmacyTok);
    end;

    procedure Prepayment(): Code[20]
    begin
        exit(PrepaymentTok);
    end;

    procedure RentalCars(): Code[20]
    begin
        exit(RentalCarsTok);
    end;

    procedure Subscription(): Code[20]
    begin
        exit(SubscriptionTok);
    end;

    procedure Tips(): Code[20]
    begin
        exit(TipsTok);
    end;

    procedure Tolls(): Code[20]
    begin
        exit(TollsTok);
    end;

    procedure Fines(): Code[20]
    begin
        exit(FinesTok);
    end;
}