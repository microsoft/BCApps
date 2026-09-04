// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8209 "Create Expense SubCategories"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpCategories: Codeunit "Create Expense Categories DM";
    begin
        // AIRLINE subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Airline(), CreateExpCategories.Airline(), AirlineTicketsLbl, AirlineTicketsPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(AirFees(), CreateExpCategories.Airline(), AirFeesLbl, AirFeesPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Upgrade(), CreateExpCategories.Airline(), AirUpgradeLbl, AirUpgradePostingLbl, false, true, false);

        // CAR subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Alcohol(), CreateExpCategories.Car(), PurchasedAlcoholDrinksLbl, PurchasedAlcoholDrinksPostingLbl, false, false, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Fuel(), CreateExpCategories.Car(), FuelForCarUsageLbl, FuelForCarUsagePostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Maintenance(), CreateExpCategories.Car(), CarMaintenanceLbl, CarMaintenancePostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Snack(), CreateExpCategories.Car(), PurchasedSnackLbl, PurchasedSnackPostingLbl, false, false, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(SoftDrink(), CreateExpCategories.Car(), PurchasedSoftDrinkLbl, PurchasedSoftDrinkPostingLbl, false, false, false);

        // COURIER subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Courier(), CreateExpCategories.Courier(), DeliveryExpenseLbl, DeliveryExpensePostingLbl, false, true, false);

        // ENTERTAIN subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Alcohol(), CreateExpCategories.Entertain(), OrderedAlcoholDrinksLbl, OrderedAlcoholDrinksPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Employee(), CreateExpCategories.Entertain(), EmployeeParticipantLbl, EmployeeParticipantPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(External(), CreateExpCategories.Entertain(), ExternalGuestLbl, ExternalGuestPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Food(), CreateExpCategories.Entertain(), OrderedFoodLbl, OrderedFoodPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(SoftDrink(), CreateExpCategories.Entertain(), OrderedSoftDrinkAndWaterLbl, OrderedSoftDrinkAndWaterPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Tips(), CreateExpCategories.Entertain(), TipsEntertainLbl, TipsPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Tax(), CreateExpCategories.Entertain(), EntertainTaxLbl, TaxPostingLbl, false, true, false);

        // EVENTS subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Events(), CreateExpCategories.Events(), ConferencesAndOtherEventsLbl, ConferencesAndOtherEventsPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Other(), CreateExpCategories.Events(), EventsOtherLbl, EventsOtherPostingLbl, false, true, false);

        // GARAGE-SERVICE subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(GarageService(), CreateExpCategories.GarageService(), GarageRepairServicesLbl, GarageRepairServicesPostingLbl, false, true, false);

        // GIFTS subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Gifts(), CreateExpCategories.Gifts(), GiftCertificatesOrTangibleGiftsLbl, GiftCertificatesOrTangibleGiftsPostingLbl, false, true, false);

        // GROUND-TRANS subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(GroundTrans(), CreateExpCategories.GroundTransportation(), GroundTransportationLbl, GroundTransportationPostingLbl, false, true, false);

        // HOTELS subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Breakfast(), CreateExpCategories.Hotels(), DailyBreakfastLbl, DailyBreakfastPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Deposit(), CreateExpCategories.Hotels(), HotelDepositLbl, HotelDepositPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(HotelOther(), CreateExpCategories.Hotels(), HotelOtherLbl, HotelOtherPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(HotelPark(), CreateExpCategories.Hotels(), ValetOrRegularParkingLbl, ValetOrRegularParkingPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Incidents(), CreateExpCategories.Hotels(), HotelIncidentsLbl, HotelIncidentsPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Laundry(), CreateExpCategories.Hotels(), HotelLaundryLbl, HotelLaundryPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Phone(), CreateExpCategories.Hotels(), HotelTelephoneLbl, HotelTelephonePostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Room(), CreateExpCategories.Hotels(), DailyRoomRateLbl, DailyRoomRatePostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(RoomService(), CreateExpCategories.Hotels(), RoomServiceMinibarMealsLbl, RoomServiceMinibarMealsPostingLbl, false, false, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Tax(), CreateExpCategories.Hotels(), HotelTaxLbl, HotelTaxPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Fee(), CreateExpCategories.Hotels(), HotelFeeLbl, HotelFeePostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Internet(), CreateExpCategories.Hotels(), HotelInternetLbl, HotelInternetPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Tips(), CreateExpCategories.Hotels(), HotelTipsLbl, TipsPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Transport(), CreateExpCategories.Hotels(), HotelTransportLbl, HotelTransportPostingLbl, false, true, false);

        // INTERNET subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Internet(), CreateExpCategories.Internet(), InternetFeesTravelLbl, InternetFeesTravelPostingLbl, false, true, false);

        // MEALS subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Alcohol(), CreateExpCategories.Meals(), MealsAlcoholLbl, OrderedAlcoholDrinksPostingLbl, false, false, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Food(), CreateExpCategories.Meals(), MealsFoodLbl, OrderedFoodPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(SoftDrink(), CreateExpCategories.Meals(), MealsSoftDrinkLbl, OrderedSoftDrinksAndWaterPostingLbl, false, false, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Tips(), CreateExpCategories.Meals(), MealsTipsLbl, TipsPostingLbl, false, false, false);

        // MISC subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Misc(), CreateExpCategories.Misc(), MiscellaneousExpensesLbl, MiscellaneousExpensesPostingLbl, false, true, false);

        // MORALE subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Alcohol(), CreateExpCategories.Morale(), MoraleAlcoholLbl, OrderedAlcoholDrinksPostingLbl, false, false, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Employee(), CreateExpCategories.Morale(), EmployeeParticipantLbl, EmployeeParticipantPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Food(), CreateExpCategories.Morale(), MoraleFoodLbl, OrderedFoodPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(SoftDrink(), CreateExpCategories.Morale(), MoraleSoftDrinkLbl, OrderedSoftDrinkAndWaterPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Tips(), CreateExpCategories.Morale(), MoraleTipsLbl, TipsPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Tax(), CreateExpCategories.Morale(), MoraleTaxLbl, TaxPostingLbl, false, true, false);

        // PARKING subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Parking(), CreateExpCategories.Parking(), ParkingLbl, ParkingPostingLbl, false, true, false);

        // PASSPORT subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Passport(), CreateExpCategories.Passport(), PassportVisaFeesLbl, PassportVisaFeesPostingLbl, false, true, false);

        // PERSONAL subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Personal(), CreateExpCategories.Personal(), PersonalExpensesLbl, PersonalExpensesPostingLbl, false, false, false);

        // PHARMACY subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Bandages(), CreateExpCategories.Pharmacy(), BandagesGauzeLbl, BandagesGauzePostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Drugs(), CreateExpCategories.Pharmacy(), DrugsOrSupplementsLbl, DrugsOrSupplementsPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Other(), CreateExpCategories.Pharmacy(), OtherItemsLbl, OtherItemsPostingLbl, false, false, false);

        // RENTALCARS subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(CarUsage(), CreateExpCategories.RentalCars(), CarRentingLbl, CarRentingPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Fuel(), CreateExpCategories.RentalCars(), BilledFuelLbl, BilledFuelPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Insurance(), CreateExpCategories.RentalCars(), CarInsuranceLbl, CarInsurancePostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Other(), CreateExpCategories.RentalCars(), OtherExpensesRelatedToServiceLbl, OtherExpensesRelatedToServicePostingLbl, false, false, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Charges(), CreateExpCategories.RentalCars(), RentalChargesLbl, RentalChargesPostingLbl, false, true, false);

        // SUBSCRIPTIONS subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Subscriptions(), CreateExpCategories.Subscription(), ProfessionalSubscriptionsLbl, ProfessionalSubscriptionsPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Personal(), CreateExpCategories.Subscription(), SubscriptionsPersonalLbl, SubscriptionsPersonalPostingLbl, false, true, false);

        // TIPS subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Tips(), CreateExpCategories.Tips(), TipsLbl, TipsPostingLbl, false, false, false);

        // TOLLS subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Tolls(), CreateExpCategories.Tolls(), TollRoadUsageFeeLbl, TollRoadUsageFeePostingLbl, false, true, false);

        // FINES subcategory
        ContosoExpenseAgent.InsertExpenseSubcategory(Fines(), CreateExpCategories.Fines(), FinesLbl, FinesPostingLbl, false, true, false);
    end;

    var
        AirlineTok: Label 'AIRLINE', MaxLength = 20, Locked = true;
        AlcoholTok: Label 'ALCOHOL', MaxLength = 20, Locked = true;
        FuelTok: Label 'FUEL', MaxLength = 20, Locked = true;
        MaintenanceTok: Label 'MAINTENANCE', MaxLength = 20, Locked = true;
        SnackTok: Label 'SNACK', MaxLength = 20, Locked = true;
        SoftDrinkTok: Label 'SOFT DRINK', MaxLength = 20, Locked = true;
        CourierTok: Label 'COURIER', MaxLength = 20, Locked = true;
        EmployeeTok: Label 'EMPLOYEE', MaxLength = 20, Locked = true;
        ExternalTok: Label 'EXTERNAL', MaxLength = 20, Locked = true;
        FoodTok: Label 'FOOD', MaxLength = 20, Locked = true;
        TipsTok: Label 'TIPS', MaxLength = 20, Locked = true;
        EventsTok: Label 'EVENTS', MaxLength = 20, Locked = true;
        GarageServiceTok: Label 'GARAGE-SERVICE', MaxLength = 20, Locked = true;
        GiftsTok: Label 'GIFTS', MaxLength = 20, Locked = true;
        GroundTransTok: Label 'GROUND-TRANS', MaxLength = 20, Locked = true;
        BreakfastTok: Label 'BREAKFAST', MaxLength = 20, Locked = true;
        DepositTok: Label 'DEPOSIT', MaxLength = 20, Locked = true;
        HotelOtherTok: Label 'HOTELOTHER', MaxLength = 20, Locked = true;
        HotelParkTok: Label 'HOTEL-PARK', MaxLength = 20, Locked = true;
        IncidentsTok: Label 'INCIDENTS', MaxLength = 20, Locked = true;
        LaundryTok: Label 'LAUNDRY', MaxLength = 20, Locked = true;
        PhoneTok: Label 'PHONE', MaxLength = 20, Locked = true;
        RoomTok: Label 'ROOM', MaxLength = 20, Locked = true;
        RoomServiceTok: Label 'ROOM-SERVICE', MaxLength = 20, Locked = true;
        TaxTok: Label 'TAX', MaxLength = 20, Locked = true;
        InternetTok: Label 'INTERNET', MaxLength = 20, Locked = true;
        MiscTok: Label 'MISC', MaxLength = 20, Locked = true;
        ParkingTok: Label 'PARKING', MaxLength = 20, Locked = true;
        PassportTok: Label 'PASSPORT', MaxLength = 20, Locked = true;
        PersonalTok: Label 'PERSONAL', MaxLength = 20, Locked = true;
        BandagesTok: Label 'BANDAGES', MaxLength = 20, Locked = true;
        DrugsTok: Label 'DRUGS', MaxLength = 20, Locked = true;
        OtherTok: Label 'OTHER', MaxLength = 20, Locked = true;
        CarUsageTok: Label 'CAR USAGE', MaxLength = 20, Locked = true;
        InsuranceTok: Label 'INSURANCE', MaxLength = 20, Locked = true;
        SubscriptionsTok: Label 'SUBSCRIPTIONS', MaxLength = 20, Locked = true;
        TollsTok: Label 'TOLLS', MaxLength = 20, Locked = true;
        FeeTok: Label 'FEE', MaxLength = 20, Locked = true;
        TransportTok: Label 'TRANSPORT', MaxLength = 20, Locked = true;
        AirlineFeesTok: Label 'AIR-FEES', MaxLength = 20, Locked = true;
        UpgradeTok: Label 'UPGRADE', MaxLength = 20, Locked = true;
        ChargesTok: Label 'CHARGES', MaxLength = 20, Locked = true;
        FinesTok: Label 'FINES', MaxLength = 20, Locked = true;
        AirlineTicketsLbl: Label 'Base airfare for commercial air travel. Includes ticket price covering passenger, route, fare class, and mandatory airline charges, excluding optional fees or upgrades.', MaxLength = 250;
        AirFeesLbl: Label 'Additional airline-related fees such as baggage fees, seat selection, booking changes, service fees, or other ancillary airline charges.', MaxLength = 250;
        AirUpgradeLbl: Label 'Charges for airline class upgrades or preferred seating upgrades paid in addition to the original airfare.', MaxLength = 250;
        PurchasedAlcoholDrinksLbl: Label 'Expenses for alcoholic beverages purchased during car travel stops, where allowed by company policy.', MaxLength = 250;
        FuelForCarUsageLbl: Label 'Expenses for fuel or charging related to company car usage. Includes gasoline, diesel, or electric charging costs incurred during business use.', MaxLength = 250;
        CarMaintenanceLbl: Label 'Expenses for minor car maintenance or consumables outside garage services. Includes car washes, fluids, bulbs, or small tools related to vehicle upkeep.', MaxLength = 250;
        PurchasedSnackLbl: Label 'Expenses for snacks purchased during business travel or company car trips, excluding full meals or restaurant dining.', MaxLength = 250;
        PurchasedSoftDrinkLbl: Label 'Expenses for non-alcoholic beverages purchased during company car usage or road travel.', MaxLength = 250;
        DeliveryExpenseLbl: Label 'Expenses for courier, delivery, or shipping services used to send or receive documents, parcels, or goods for business purposes.', MaxLength = 250;
        OrderedAlcoholDrinksLbl: Label 'Expenses for alcoholic beverages ordered during external entertainment with customers or business partners.', MaxLength = 250;
        MealsAlcoholLbl: Label 'Expenses for alcoholic drinks consumed in connection with employee meals during business travel or approved business meals.', MaxLength = 250;
        MoraleAlcoholLbl: Label 'Expenses for alcoholic beverages purchased for internal employee morale or team-building events. Includes beer, wine, and spirits consumed during company events.', MaxLength = 250;
        EmployeeParticipantLbl: Label 'Employee participant', MaxLength = 250;
        ExternalGuestLbl: Label 'External guest', MaxLength = 250;
        OrderedFoodLbl: Label 'Expenses for food ordered during external entertainment with customers or business partners at restaurants, cafes, or similar venues.', MaxLength = 250;
        MealsFoodLbl: Label 'Expenses for food consumed by employees during working hours or business travel. Includes breakfasts, lunches, dinners, or catered meals provided for business purposes.', MaxLength = 250;
        OrderedSoftDrinkAndWaterLbl: Label 'Expenses for non-alcoholic beverages such as soft drinks or water ordered during external business entertainment.', MaxLength = 250;
        MoraleSoftDrinkLbl: Label 'Expenses for non-alcoholic beverages such as water, soft drinks, juice, or coffee purchased for employee morale or internal team-building events.', MaxLength = 250;
        MealsSoftDrinkLbl: Label 'Expenses for non-alcoholic beverages consumed with employee meals during business activities or business travel.', MaxLength = 250;
        MoraleFoodLbl: Label 'Expenses for food ordered as part of internal employee morale or team-building activities. Includes meals provided during team lunches, dinners, offsites, or internal social events.', MaxLength = 250;
        TipsEntertainLbl: Label 'Expenses for tips or gratuities paid for service during external business entertainment.', MaxLength = 250;
        MealsTipsLbl: Label 'Tips or gratuities paid in connection with employee meals during business travel or work-related dining.', MaxLength = 250;
        MoraleTipsLbl: Label 'Tips or gratuities paid in connection with food, beverage, or service expenses incurred during employee morale or internal team-building events.', MaxLength = 250;
        MoraleTaxLbl: Label 'Sales tax, VAT or similar consumption tax charged on morale-related food, beverage, or service expenses for internal employee events.', MaxLength = 250;
        EntertainTaxLbl: Label 'Expenses for applicable taxes charged on food, drinks, or services during external entertainment.', MaxLength = 250;
        ConferencesAndOtherEventsLbl: Label 'Expenses related to attending or participating in business events such as conferences, trade fairs, summits, or exhibitions, including tickets and registration fees.', MaxLength = 250;
        EventsOtherLbl: Label 'Expenses for non-business or personal events not related to professional activities. Includes leisure or personal events such as museum visits, amusement parks, circus shows, political or private events.', MaxLength = 250;
        GarageRepairServicesLbl: Label 'Professional repair, servicing, or maintenance performed by a garage on company cars or trucks, including labor, diagnostics, parts, and inspections.', MaxLength = 250;
        GiftCertificatesOrTangibleGiftsLbl: Label 'Expenses for gift certificates or tangible gifts given to current or potential business partners for business relationship purposes.', MaxLength = 250;
        GroundTransportationLbl: Label 'Expenses for ground transportation during business travel, including taxis, ride-hailing services, public transport, trains, ferries, or similar services.', MaxLength = 250;
        DailyBreakfastLbl: Label 'Expenses for breakfast charged by the hotel during a business stay. Includes hotel-provided breakfast billed separately or as part of room service. Excludes external dining outside the hotel.', MaxLength = 250;
        HotelDepositLbl: Label 'Expenses for refundable or non-refundable hotel deposits required to secure a reservation or cover potential incidentals during a business stay.', MaxLength = 250;
        HotelOtherLbl: Label 'Hotel-related expenses incurred during a business stay that do not fall into defined hotel subcategories.', MaxLength = 250;
        ValetOrRegularParkingLbl: Label 'Expenses for valet or self-parking services provided by the hotel during a business stay.', MaxLength = 250;
        HotelIncidentsLbl: Label 'Expenses charged by the hotel for damages, penalties, or incident-related costs incurred during the stay, such as broken items or cleaning charges.', MaxLength = 250;
        HotelLaundryLbl: Label 'Expenses for laundry, dry-cleaning, or pressing services provided by the hotel during a business trip.', MaxLength = 250;
        HotelTelephoneLbl: Label 'Expenses for telephone calls or phone usage billed by the hotel during a business stay, including local or international calls placed from the room.', MaxLength = 250;
        DailyRoomRateLbl: Label 'Expenses for the daily hotel room rate during business travel. Includes nightly accommodation charges for standard or upgraded rooms. Excludes meals, taxes, and additional in-stay services billed separately.', MaxLength = 250;
        RoomServiceMinibarMealsLbl: Label 'Expenses for meals, minibar items, and beverages provided via hotel room service during a business stay.', MaxLength = 250;
        HotelTaxLbl: Label 'Expenses for mandatory hotel-related taxes such as city tax, tourist tax, occupancy tax, or similar government-imposed accommodation levies.', MaxLength = 250;
        HotelFeeLbl: Label 'Expenses for hotel-imposed fees other than room rate or tax, such as resort fees, service fees, facility fees, or mandatory surcharges.', MaxLength = 250;
        HotelInternetLbl: Label 'Expenses for hotel internet or Wi-Fi services charged during a business stay, including premium or high-speed access fees.', MaxLength = 250;
        HotelTipsLbl: Label 'Expenses for tips paid to hotel staff such as bell services, housekeeping, or concierge during a business stay.', MaxLength = 250;
        HotelTransportLbl: Label 'Expenses for transportation services arranged or provided by the hotel, such as hotel shuttles, transfers, or arranged rides.', MaxLength = 250;
        InternetFeesTravelLbl: Label 'Expenses for internet or data access incurred during business travel, such as roaming data charges, or temporary internet services.', MaxLength = 250;
        MiscellaneousExpensesLbl: Label 'Business-related expenses that do not clearly fit any other defined category and require individual review for policy compliance.', MaxLength = 250;
        ParkingLbl: Label 'Expenses for parking incurred during business travel or work activities, including street parking, garages, airport parking, or parking meters.', MaxLength = 250;
        PassportVisaFeesLbl: Label 'Fees for obtaining or renewing passports, visas, or other travel documents required for business travel.', MaxLength = 250;
        PersonalExpensesLbl: Label 'Expenses of a personal or non-business nature that are not eligible for reimbursement under company policy.', MaxLength = 250;
        BandagesGauzeLbl: Label 'Expenses for first-aid or medical supplies such as bandages, gauze, plasters, or similar healthcare consumables.', MaxLength = 250;
        DrugsOrSupplementsLbl: Label 'Expenses for medicines, drugs, or supplements purchased during business travel or for work-related health needs.', MaxLength = 250;
        OtherItemsLbl: Label 'Other pharmacy-related purchases not classified as drugs or bandages, including health or medical items related to travel or work.', MaxLength = 250;
        CarRentingLbl: Label 'Base rental charges for renting a car for business travel, excluding insurance, fuel, fines, or additional services.', MaxLength = 250;
        BilledFuelLbl: Label 'Fuel charges billed by the rental car provider or paid for refueling a rental car used for business travel.', MaxLength = 250;
        CarInsuranceLbl: Label 'Charges for insurance coverage related to rental cars, including damage, theft, or liability insurance options.', MaxLength = 250;
        OtherExpensesRelatedToServiceLbl: Label 'Other expenses related to rental car services not covered by base rental, insurance, fuel, or charges.', MaxLength = 250;
        RentalChargesLbl: Label 'Additional rental-related charges such as fines, penalties, cleaning fees, late return fees, or administrative charges.', MaxLength = 250;
        ProfessionalSubscriptionsLbl: Label 'Expenses for professional or business-related subscriptions, including software services, digital tools, memberships, or online publications.', MaxLength = 250;
        SubscriptionsPersonalLbl: Label 'Expenses for personal subscriptions not related to business use. Includes streaming services, personal magazines, entertainment platforms, or non-business memberships and services.', MaxLength = 250;
        TollRoadUsageFeeLbl: Label 'Fees charged for using toll roads, bridges, tunnels, congestion zones, or paid road infrastructure during business travel.', MaxLength = 250;
        TipsLbl: Label 'Tips or gratuities paid to service providers in connection with business activities or travel.', MaxLength = 250;
        FinesLbl: Label 'Expenses for fines, penalties, or sanctions imposed by authorities due to violations or non-compliance during business activities.', MaxLength = 250;
        AirlineTicketsPostingLbl: Label 'Airline tickets', MaxLength = 100;
        AirFeesPostingLbl: Label 'Other airline fees', MaxLength = 100;
        AirUpgradePostingLbl: Label 'Class upgrades', MaxLength = 100;
        PurchasedAlcoholDrinksPostingLbl: Label 'Purchased alcohol drinks', MaxLength = 100;
        FuelForCarUsagePostingLbl: Label 'Fuel for the car usage', MaxLength = 100;
        CarMaintenancePostingLbl: Label 'Car maintenance or tools for car', MaxLength = 100;
        PurchasedSnackPostingLbl: Label 'Purchased snack', MaxLength = 100;
        PurchasedSoftDrinkPostingLbl: Label 'Purchased soft drink', MaxLength = 100;
        DeliveryExpensePostingLbl: Label 'Delivery expense', MaxLength = 100;
        OrderedAlcoholDrinksPostingLbl: Label 'Ordered alcohol drinks', MaxLength = 100;
        EmployeeParticipantPostingLbl: Label 'Employee participant', MaxLength = 100;
        ExternalGuestPostingLbl: Label 'External guest', MaxLength = 100;
        OrderedFoodPostingLbl: Label 'Ordered food', MaxLength = 100;
        OrderedSoftDrinkAndWaterPostingLbl: Label 'Ordered soft drink and water', MaxLength = 100;
        OrderedSoftDrinksAndWaterPostingLbl: Label 'Ordered soft drinks and water', MaxLength = 100;
        TipsPostingLbl: Label 'Tips', MaxLength = 100;
        TaxPostingLbl: Label 'Tax', MaxLength = 100;
        ConferencesAndOtherEventsPostingLbl: Label 'Conferences and Other Events', MaxLength = 100;
        EventsOtherPostingLbl: Label 'Other non business events', MaxLength = 100;
        GarageRepairServicesPostingLbl: Label 'Garage (car and trucks) repair services', MaxLength = 100;
        GiftCertificatesOrTangibleGiftsPostingLbl: Label 'Gift certificates or Tangible gifts', MaxLength = 100;
        GroundTransportationPostingLbl: Label 'Ground transportation', MaxLength = 100;
        DailyBreakfastPostingLbl: Label 'Daily breakfast', MaxLength = 100;
        HotelDepositPostingLbl: Label 'Hotel Deposit', MaxLength = 100;
        HotelOtherPostingLbl: Label 'Hotel Other', MaxLength = 100;
        ValetOrRegularParkingPostingLbl: Label 'Valet or regular parking', MaxLength = 100;
        HotelIncidentsPostingLbl: Label 'Hotel Incidents', MaxLength = 100;
        HotelLaundryPostingLbl: Label 'Hotel Laundry', MaxLength = 100;
        HotelTelephonePostingLbl: Label 'Hotel Telephone', MaxLength = 100;
        DailyRoomRatePostingLbl: Label 'Daily Room Rate', MaxLength = 100;
        RoomServiceMinibarMealsPostingLbl: Label 'Room Service, Minibar & Meals', MaxLength = 100;
        HotelTaxPostingLbl: Label 'Hotel Tax', MaxLength = 100;
        HotelFeePostingLbl: Label 'Hotel fees', MaxLength = 100;
        HotelInternetPostingLbl: Label 'Hotel Internet', MaxLength = 100;
        HotelTransportPostingLbl: Label 'Hotel transportation', MaxLength = 100;
        InternetFeesTravelPostingLbl: Label 'Internet fees - Travel', MaxLength = 100;
        MiscellaneousExpensesPostingLbl: Label 'Miscellaneous expenses', MaxLength = 100;
        ParkingPostingLbl: Label 'Parking', MaxLength = 100;
        PassportVisaFeesPostingLbl: Label 'Passport/Visa Fees', MaxLength = 100;
        PersonalExpensesPostingLbl: Label 'Personal expenses', MaxLength = 100;
        BandagesGauzePostingLbl: Label 'Bandages, gauze...', MaxLength = 100;
        DrugsOrSupplementsPostingLbl: Label 'Drugs or supplements', MaxLength = 100;
        OtherItemsPostingLbl: Label 'Other items', MaxLength = 100;
        CarRentingPostingLbl: Label 'Car renting', MaxLength = 100;
        BilledFuelPostingLbl: Label 'Billed fuel', MaxLength = 100;
        CarInsurancePostingLbl: Label 'Car insurance', MaxLength = 100;
        OtherExpensesRelatedToServicePostingLbl: Label 'Other expenses related to service', MaxLength = 100;
        RentalChargesPostingLbl: Label 'Charges and fines related to the service', MaxLength = 100;
        ProfessionalSubscriptionsPostingLbl: Label 'Professional Subscriptions', MaxLength = 100;
        SubscriptionsPersonalPostingLbl: Label 'Personal Subscriptions', MaxLength = 100;
        TollRoadUsageFeePostingLbl: Label 'Toll / Road Usage Fee', MaxLength = 100;
        FinesPostingLbl: Label 'Fines and penalties', MaxLength = 100;

    procedure Airline(): Code[20]
    begin
        exit(AirlineTok);
    end;

    procedure Alcohol(): Code[20]
    begin
        exit(AlcoholTok);
    end;

    procedure Fuel(): Code[20]
    begin
        exit(FuelTok);
    end;

    procedure Maintenance(): Code[20]
    begin
        exit(MaintenanceTok);
    end;

    procedure Snack(): Code[20]
    begin
        exit(SnackTok);
    end;

    procedure SoftDrink(): Code[20]
    begin
        exit(SoftDrinkTok);
    end;

    procedure Courier(): Code[20]
    begin
        exit(CourierTok);
    end;

    procedure Employee(): Code[20]
    begin
        exit(EmployeeTok);
    end;

    procedure External(): Code[20]
    begin
        exit(ExternalTok);
    end;

    procedure Food(): Code[20]
    begin
        exit(FoodTok);
    end;

    procedure Tips(): Code[20]
    begin
        exit(TipsTok);
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

    procedure GroundTrans(): Code[20]
    begin
        exit(GroundTransTok);
    end;

    procedure Breakfast(): Code[20]
    begin
        exit(BreakfastTok);
    end;

    procedure Deposit(): Code[20]
    begin
        exit(DepositTok);
    end;

    procedure HotelOther(): Code[20]
    begin
        exit(HotelOtherTok);
    end;

    procedure HotelPark(): Code[20]
    begin
        exit(HotelParkTok);
    end;

    procedure Incidents(): Code[20]
    begin
        exit(IncidentsTok);
    end;

    procedure Laundry(): Code[20]
    begin
        exit(LaundryTok);
    end;

    procedure Phone(): Code[20]
    begin
        exit(PhoneTok);
    end;

    procedure Room(): Code[20]
    begin
        exit(RoomTok);
    end;

    procedure RoomService(): Code[20]
    begin
        exit(RoomServiceTok);
    end;

    procedure Tax(): Code[20]
    begin
        exit(TaxTok);
    end;

    procedure Internet(): Code[20]
    begin
        exit(InternetTok);
    end;

    procedure Misc(): Code[20]
    begin
        exit(MiscTok);
    end;

    procedure Parking(): Code[20]
    begin
        exit(ParkingTok);
    end;

    procedure Passport(): Code[20]
    begin
        exit(PassportTok);
    end;

#if not CLEAN29
    [Obsolete('This function is no longer used.', '29.0')]
    procedure Country(): Code[20]
    begin
    end;

    [Obsolete('This function is no longer used.', '29.0')]
    procedure Intl(): Code[20]
    begin
    end;
#endif

    procedure Personal(): Code[20]
    begin
        exit(PersonalTok);
    end;

    procedure Bandages(): Code[20]
    begin
        exit(BandagesTok);
    end;

    procedure Drugs(): Code[20]
    begin
        exit(DrugsTok);
    end;

    procedure Other(): Code[20]
    begin
        exit(OtherTok);
    end;

    procedure CarUsage(): Code[20]
    begin
        exit(CarUsageTok);
    end;

    procedure Insurance(): Code[20]
    begin
        exit(InsuranceTok);
    end;

    procedure Subscriptions(): Code[20]
    begin
        exit(SubscriptionsTok);
    end;

    procedure Tolls(): Code[20]
    begin
        exit(TollsTok);
    end;

    procedure Fee(): Code[20]
    begin
        exit(FeeTok);
    end;

    procedure Transport(): Code[20]
    begin
        exit(TransportTok);
    end;

    procedure AirFees(): Code[20]
    begin
        exit(AirlineFeesTok);
    end;

    procedure Upgrade(): Code[20]
    begin
        exit(UpgradeTok);
    end;

    procedure Charges(): Code[20]
    begin
        exit(ChargesTok);
    end;

    procedure Fines(): Code[20]
    begin
        exit(FinesTok);
    end;
}