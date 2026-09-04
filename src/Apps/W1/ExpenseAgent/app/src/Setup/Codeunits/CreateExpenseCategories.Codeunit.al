// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;

codeunit 6973 "Create Expense Categories"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Currency: Record Currency;
        ExpenseCategory: Record "Expense Category";
        ExpenseGroup: Record "Expense Group";
        ExpenseLocation: Record "Expense Location";
        ExpensePostingGroup: Record "Expense Posting Group";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        CreateExpenseGLAccount: Codeunit "Create Expense GL Account";
        DeleteCategoriesQst: Label 'Expense Categories already exist. Do you want to reset and recreate them?';

    trigger OnRun()
    var
    begin
        // Check if Expense Categories already exist and ask for reset
        ExpenseCategory.Reset();
        if not ExpenseCategory.IsEmpty then begin
            if not Confirm(DeleteCategoriesQst, false) then
                exit;

            ExpenseCategory.DeleteAll();
            ExpenseSubcategory.DeleteAll();
            ExpenseGroup.DeleteAll();
            ExpenseLocation.DeleteAll();
            ExpenseRuleHeader.DeleteAll();
            ExpenseRuleCondition.DeleteAll();
        end;

        InsertAccountingDefaults();
        InsertManagementDefaults();

        Codeunit.Run(Codeunit::"Create Expense VAT Rates");
    end;

    internal procedure InsertAccountingDefaults()
    begin
        InsertDefaultPostingGroups();
        InsertDefaultExpenseCategories();
    end;

    internal procedure InsertManagementDefaults()
    begin
        InsertDefaultExpenseLocations();
        InsertDefaultManagementRules();
    end;

    internal procedure InsertDefaultPostingGroups()
    var
        TempPostingGroupSeed: Record "Expense Posting Group" temporary;
    begin
        // Expense Groups are shared between posting groups and categories.
        InsertDefaultExpenseGroups();

        // Insert Expense Posting Groups
        BuildPostingGroupSeeds(TempPostingGroupSeed);
        if TempPostingGroupSeed.FindSet() then
            repeat
                InsertExpensePostingGroup(
                    TempPostingGroupSeed.Code,
                    TempPostingGroupSeed.Description,
                    TempPostingGroupSeed."Refundable Debit Account",
                    TempPostingGroupSeed."Non-Refundable Debit Account",
                    TempPostingGroupSeed."Prepayment Credit Account",
                    TempPostingGroupSeed."Debit Rounding Account",
                    TempPostingGroupSeed."Credit Rounding Account");
            until TempPostingGroupSeed.Next() = 0;

        // Update Employee Posting Groups with Expense related GL Accounts
        UpdateEmployeePostingGroup(XEMPLEXPTxt, CreateExpenseGLAccount.ExpenseReportPayableAccountNo(), CreateExpenseGLAccount.ExpensePayableBankPaidAccountNo(), CreateExpenseGLAccount.ExpensePayableCardPaidAccountNo(), CreateExpenseGLAccount.ExpenseReportPrepaymentAccountNo());
    end;

    /// <summary>
    /// Returns the catalogue of default expense posting groups without writing anything to the database.
    /// Use this for previewing what InsertDefaultPostingGroups would create.
    /// </summary>
    internal procedure BuildPostingGroupSeeds(var TempPostingGroup: Record "Expense Posting Group" temporary)
    begin
        TempPostingGroup.Reset();
        TempPostingGroup.DeleteAll();

        AddPostingGroupSeed(TempPostingGroup, XEXPENSETRAVELTxt, XExpenseTravelDescTxt, CreateExpenseGLAccount.ExpenseTravelRefundableDebitAccountNo());
        AddPostingGroupSeed(TempPostingGroup, XEXPENSEPERDIEMTxt, XExpensePerDiemDescTxt, CreateExpenseGLAccount.ExpensePerDiemRefundableDebitAccountNo());
        AddPostingGroupSeed(TempPostingGroup, XEXPENSEOTHERTxt, XExpenseOtherDescTxt, CreateExpenseGLAccount.ExpenseOtherRefundableDebitAccountNo());
        AddPostingGroupSeed(TempPostingGroup, XEXPENSEMILEAGETxt, XExpenseMileageDescTxt, CreateExpenseGLAccount.ExpenseMileageRefundableDebitAccountNo());
        AddPostingGroupSeed(TempPostingGroup, XEXPENSEMEALSTxt, XExpenseMealsDescTxt, CreateExpenseGLAccount.ExpenseMealsRefundableDebitAccountNo());
        AddPostingGroupSeed(TempPostingGroup, XEXPENSEENTERTAINTxt, XExpenseEntertainDescTxt, CreateExpenseGLAccount.ExpenseEntertainRefundableDebitAccountNo());

        if GetCountryCode() = 'AT' then begin
            AddPostingGroupSeed(TempPostingGroup, XEXPENSEPERDIEMITxt, XExpensePerDiemInCountryDescTxt, CreateExpenseGLAccount.ExpensePerDiemIRefundableDebitAccountNo());
            AddPostingGroupSeed(TempPostingGroup, XEXPENSEPERDIEMATxt, XExpensePerDiemAbroadDescTxt, CreateExpenseGLAccount.ExpensePerDiemARefundableDebitAccountNo());
        end;

        OnAfterBuildPostingGroupSeeds(TempPostingGroup);
    end;

    /// <summary>
    /// Builds the preview record set for expense posting groups: existing rows plus seeds that
    /// do not yet exist. No database writes are performed.
    /// </summary>
    internal procedure LoadPostingGroupsPreview(var TempPostingGroup: Record "Expense Posting Group" temporary)
    var
        ExistingPostingGroup: Record "Expense Posting Group";
        TempSeed: Record "Expense Posting Group" temporary;
    begin
        TempPostingGroup.Reset();
        TempPostingGroup.DeleteAll();

        // 1) Existing rows from the database.
        if ExistingPostingGroup.FindSet() then
            repeat
                TempPostingGroup := ExistingPostingGroup;
                TempPostingGroup.Insert();
            until ExistingPostingGroup.Next() = 0;

        // 2) Seeds not yet present.
        BuildPostingGroupSeeds(TempSeed);
        if TempSeed.FindSet() then
            repeat
                if not TempPostingGroup.Get(TempSeed.Code) then begin
                    TempPostingGroup := TempSeed;
                    TempPostingGroup.Insert();
                end;
            until TempSeed.Next() = 0;
    end;

    internal procedure AddPostingGroupSeed(var TempPostingGroup: Record "Expense Posting Group" temporary; Code: Code[20]; Description: Text[100]; RefundableDebitAccount: Code[20])
    var
        IsHandled: Boolean;
    begin
        OnBeforeAddPostingGroupSeed(Code, Description, RefundableDebitAccount, IsHandled);
        if IsHandled then
            exit;

        if (GetCountryCode() = 'AT') and (Code = XEXPENSEPERDIEMTxt) then
            exit;

        TempPostingGroup.Init();
        TempPostingGroup.Code := Code;
        TempPostingGroup.Description := Description;
        TempPostingGroup."Refundable Debit Account" := RefundableDebitAccount;
        if (Code <> XEXPENSEPERDIEMTxt) and (Code <> XEXPENSEMILEAGETxt) then
            TempPostingGroup."Non-Refundable Debit Account" := CreateExpenseGLAccount.ExpenseNonRefundableDebitAccountNo();
        TempPostingGroup."Prepayment Credit Account" := CreateExpenseGLAccount.ExpensePrepaymentDebitAccountNo();
        TempPostingGroup."Debit Rounding Account" := CreateExpenseGLAccount.ExpenseDebitRoundingAccountNo();
        TempPostingGroup."Credit Rounding Account" := CreateExpenseGLAccount.ExpenseCreditRoundingAccountNo();
        if GetCountryCode() = 'AT' then
            case Code of
                XEXPENSEMEALSTxt:
                    TempPostingGroup."Non-Refundable Debit Account" := CreateExpenseGLAccount.ExpenseMealNonRefundableDebitAccountNo();
                XEXPENSEENTERTAINTxt, XEXPENSEPERDIEMITxt, XEXPENSEPERDIEMATxt:
                    TempPostingGroup."Non-Refundable Debit Account" := '';
            end;
        if (GetCountryCode() in ['DE', 'DK', 'ES', 'FR']) and (Code = XEXPENSEMEALSTxt) then
            TempPostingGroup."Non-Refundable Debit Account" := CreateExpenseGLAccount.ExpenseMealNonRefundableDebitAccountNo();
        OnBeforeInsertPostingGroupSeed(TempPostingGroup);
        TempPostingGroup.Insert();
    end;

    internal procedure InsertDefaultExpenseCategories()
    var
        TempCategorySeed: Record "Expense Category" temporary;
        TempSubcategorySeed: Record "Expense Subcategory" temporary;
        TempPreExistingCategory: Record "Expense Category" temporary;
        ExistingCategory: Record "Expense Category";
    begin
        // Expense Groups are shared between posting groups and categories.
        InsertDefaultExpenseGroups();

        BuildCategorySeeds(TempCategorySeed);

        // Snapshot which seed-coded categories already exist in the DB. Their subcategories
        // are considered customer-owned and must not be touched by the defaults run.
        if TempCategorySeed.FindSet() then
            repeat
                if ExistingCategory.Get(TempCategorySeed.Code) then begin
                    TempPreExistingCategory := ExistingCategory;
                    TempPreExistingCategory.Insert();
                end;
            until TempCategorySeed.Next() = 0;

        if TempCategorySeed.FindSet() then
            repeat
                InsertExpenseCategory(
                    TempCategorySeed.Code,
                    TempCategorySeed.Description,
                    TempCategorySeed."Posting Description",
                    TempCategorySeed."Expense Group",
                    TempCategorySeed."Posting Group",
                    TempCategorySeed."Default Payment Method",
                    TempCategorySeed.Refundable,
                    TempCategorySeed."Prepayment-Cash Advance",
                    TempCategorySeed."Attachment Enforcement",
                    TempCategorySeed."Expense Detail Required");
            until TempCategorySeed.Next() = 0;

        BuildSubcategorySeeds(TempSubcategorySeed);
        if TempSubcategorySeed.FindSet() then
            repeat
                if not TempPreExistingCategory.Get(TempSubcategorySeed."Expense Category Code") then
                    InsertExpenseSubcategory(
                        TempSubcategorySeed.Code,
                        TempSubcategorySeed."Expense Category Code",
                        TempSubcategorySeed.Description,
                        TempSubcategorySeed."Posting Description",
                        TempSubcategorySeed.Refundable,
                        TempSubcategorySeed."Expense Description Mandatory");
            until TempSubcategorySeed.Next() = 0;
    end;

    /// <summary>
    /// Returns the catalogue of default expense categories without writing anything to the database.
    /// </summary>
    internal procedure BuildCategorySeeds(var TempCategory: Record "Expense Category" temporary)
    begin
        TempCategory.Reset();
        TempCategory.DeleteAll();

        AddCategorySeed(TempCategory, XAIRLINETxt, XAirlineTicketsTxt, XAirlinePostingTxt, XTRAVELTxt, XEXPENSETRAVELTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XCARTxt, XCarUsageTxt, XCarPostingTxt, XDAYEXPENSETxt, XEXPENSEMILEAGETxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XCOURIERTxt, XDeliveryExpenseTxt, XCourierPostingTxt, XDAYEXPENSETxt, XEXPENSEOTHERTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XENTERTAINTxt, XEntertainmentTxt, XEntertainPostingTxt, XFOODBEVERAGETxt, XEXPENSEENTERTAINTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::Participants);
        AddCategorySeed(TempCategory, XMORALETxt, XMoraleEventTxt, XMoralePostingTxt, XFOODBEVERAGETxt, XEXPENSEENTERTAINTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::Participants);
        AddCategorySeed(TempCategory, XEVENTSTxt, XConferencesandOtherEventsTxt, XEventsPostingTxt, XTRAVELTxt, XEXPENSETRAVELTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XFINESTxt, XFinesDescTxt, XFinesPostingTxt, XDAYEXPENSETxt, XEXPENSEOTHERTxt, XCASHTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XGARAGESERVICETxt, XGarageServiceDescTxt, XGarageServicePostingTxt, XDAYEXPENSETxt, XEXPENSEOTHERTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XGIFTSTxt, XGiftCertificatesTxt, XGiftsPostingTxt, XDAYEXPENSETxt, XEXPENSEOTHERTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XGROUNDTRANSTxt, XGroundTransportationTxt, XGroundTransPostingTxt, XTRAVELTxt, XEXPENSETRAVELTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XHOTELSTxt, XHotelStayTxt, XHotelsPostingTxt, XTRAVELTxt, XEXPENSETRAVELTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::Itemize);
        AddCategorySeed(TempCategory, XINTERNETTxt, XInternetFeesTxt, XInternetPostingTxt, XDAYEXPENSETxt, XEXPENSEOTHERTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XMEALSTxt, XMealsDescTxt, XMealsPostingTxt, XFOODBEVERAGETxt, XEXPENSEMEALSTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XMILEAGETxt, XMileageDescTxt, XMileagePostingTxt, XPERSONALTxt, XEXPENSEMILEAGETxt, XCASHTxt, false, false, "Expense Attachment Enforcement"::" ", "Expense Detail Needed"::Mileage);
        AddCategorySeed(TempCategory, XMISCTxt, XMiscellaneousExpensesTxt, XMiscPostingTxt, XFOODBEVERAGETxt, XEXPENSEOTHERTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XPARKINGTxt, XParkingDescTxt, XParkingPostingTxt, XDAYEXPENSETxt, XEXPENSEOTHERTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XPASSPORTTxt, XPassportVisaFeesTxt, XPassportPostingTxt, XTRAVELTxt, XEXPENSETRAVELTxt, XCASHTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XPERDIEMTxt, XPerDiemDescTxt, XPerDiemPostingTxt, XTRAVELTxt, XEXPENSEPERDIEMTxt, XCASHTxt, true, false, "Expense Attachment Enforcement"::" ", "Expense Detail Needed"::"Per Diem");
        AddCategorySeed(TempCategory, XPHARMACYTxt, XPharmacyDescTxt, XPharmacyPostingTxt, XDAYEXPENSETxt, XEXPENSEOTHERTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XPERSONALTxt, XPersonalExpensesTxt, XPersonalPostingTxt, XPERSONALTxt, XEXPENSEOTHERTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XPREPAYMENTTxt, XPrepaymentsCashAdvanceTxt, XPrepaymentPostingTxt, XPREPAYMENTTxt, XEXPENSEOTHERTxt, XCARDTxt, false, true, "Expense Attachment Enforcement"::" ", "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XRENTALCARSTxt, XCarRentalsDescTxt, XRentalCarsPostingTxt, XTRAVELTxt, XEXPENSETRAVELTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XSUBSCRIPTIONTxt, XProfessionalSubscriptionsTxt, XSubscriptionsPostingTxt, XDAYEXPENSETxt, XEXPENSEOTHERTxt, XCARDTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XTIPSTxt, XTipsDescTxt, XTipsPostingTxt, XFOODBEVERAGETxt, XEXPENSEOTHERTxt, XCASHTxt, false, false, "Expense Attachment Enforcement"::" ", "Expense Detail Needed"::" ");
        AddCategorySeed(TempCategory, XTOLLSTxt, XTollRoadUsageFeeTxt, XTollsPostingTxt, XDAYEXPENSETxt, XEXPENSEOTHERTxt, XCASHTxt, true, false, "Expense Attachment Enforcement"::Warning, "Expense Detail Needed"::" ");

        if GetCountryCode() = 'AT' then begin
            AddCategorySeed(TempCategory, XPERDIEMITxt, XPerDiemDescTxt, XPerDiemIByAssignedPolicyPostingTxt, XTRAVELTxt, XEXPENSEPERDIEMITxt, XCASHTxt, true, false, "Expense Attachment Enforcement"::" ", "Expense Detail Needed"::"Per Diem");
            AddCategorySeed(TempCategory, XPERDIEMATxt, XPerDiemDescTxt, XPerDiemAByAssignedPolicyPostingTxt, XTRAVELTxt, XEXPENSEPERDIEMATxt, XCASHTxt, true, false, "Expense Attachment Enforcement"::" ", "Expense Detail Needed"::"Per Diem");
        end;

        OnAfterBuildCategorySeeds(TempCategory);
    end;

    /// <summary>
    /// Returns the catalogue of default expense subcategories without writing anything to the database.
    /// </summary>
    internal procedure BuildSubcategorySeeds(var TempSubcategory: Record "Expense Subcategory" temporary)
    begin
        TempSubcategory.Reset();
        TempSubcategory.DeleteAll();

        // HOTELS
        AddSubcategorySeed(TempSubcategory, XROOMTxt, XHOTELSTxt, XHotelRoomDescTxt, XSubRoomPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XBREAKFASTTxt, XHOTELSTxt, XHotelBreakfastDescTxt, XSubBreakfastPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XDEPOSITTxt, XHOTELSTxt, XHotelDepositDescTxt, XSubDepositPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XTAXTxt, XHOTELSTxt, XHotelTaxDescTxt, XSubHotelTaxPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XFEETxt, XHOTELSTxt, XHotelFeeDescTxt, XSubHotelFeePostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XPHONETxt, XHOTELSTxt, XHotelPhoneDescTxt, XSubHotelPhonePostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XINTERNETTxt, XHOTELSTxt, XHotelInternetDescTxt, XSubHotelInternetPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XINCIDENTSTxt, XHOTELSTxt, XHotelIncidentsDescTxt, XSubHotelIncidentsPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XLAUNDRYTxt, XHOTELSTxt, XHotelLaundryDescTxt, XSubLaundryPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XROOMSERVICETxt, XHOTELSTxt, XHotelRoomServiceDescTxt, XSubRoomServicePostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XHOTELPARKTxt, XHOTELSTxt, XHotelParkingDescTxt, XSubHotelParkingPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XHOTELOTHERTxt, XHOTELSTxt, XHotelOtherDescTxt, XSubOtherPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XTIPSTxt, XHOTELSTxt, XHotelTipsDescTxt, XTipsPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XTRANSPORTTxt, XHOTELSTxt, XHotelTransportDescTxt, XSubHotelTransportPostingTxt, true, false);

        // ENTERTAIN
        AddSubcategorySeed(TempSubcategory, XFOODTxt, XENTERTAINTxt, XEntertainFoodDescTxt, XSubOrderedFoodPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XSOFTDRINKTxt, XENTERTAINTxt, XEntertainSoftDrinkDescTxt, XSubOrderedSoftDrinkPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XALCOHOLTxt, XENTERTAINTxt, XEntertainAlcoholDescTxt, XSubOrderedAlcoholPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XTIPSTxt, XENTERTAINTxt, XEntertainTipsDescTxt, XTipsPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XTAXTxt, XENTERTAINTxt, XEntertainTaxDescTxt, XSubTaxPostingTxt, true, false);

        // MORALE
        AddSubcategorySeed(TempSubcategory, XFOODTxt, XMORALETxt, XMoraleFoodDescTxt, XSubOrderedFoodPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XSOFTDRINKTxt, XMORALETxt, XMoraleSoftDrinkDescTxt, XSubOrderedSoftDrinkPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XALCOHOLTxt, XMORALETxt, XMoraleAlcoholDescTxt, XSubOrderedAlcoholPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XTIPSTxt, XMORALETxt, XMoraleTipsDescTxt, XTipsPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XTAXTxt, XMORALETxt, XMoraleTaxDescTxt, XSubTaxPostingTxt, true, false);

        // MEALS
        AddSubcategorySeed(TempSubcategory, XFOODTxt, XMEALSTxt, XMealsFoodDescTxt, XSubOrderedFoodPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XSOFTDRINKTxt, XMEALSTxt, XMealsSoftDrinkDescTxt, XSubOrderedSoftDrinkPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XALCOHOLTxt, XMEALSTxt, XMealsAlcoholDescTxt, XSubOrderedAlcoholPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XTIPSTxt, XMEALSTxt, XMealsTipsDescTxt, XTipsPostingTxt, true, false);

        // AIRLINE
        AddSubcategorySeed(TempSubcategory, XAIRLINETxt, XAIRLINETxt, XAirlineSubDescTxt, XSubAirlineFarePostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XAIRFEESTxt, XAIRLINETxt, XAirFeesDescTxt, XSubAirFeesPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XUPGRADETxt, XAIRLINETxt, XAirUpgradeDescTxt, XSubAirUpgradePostingTxt, true, false);

        // CAR
        AddSubcategorySeed(TempSubcategory, XFUELTxt, XCARTxt, XCarFuelDescTxt, XSubCarFuelPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XMAINTENANCETxt, XCARTxt, XCarMaintenanceDescTxt, XSubCarMaintenancePostingTxt, true, false);

        // COURIER
        AddSubcategorySeed(TempSubcategory, XCOURIERTxt, XCOURIERTxt, XCourierSubDescTxt, XCourierPostingTxt, true, false);

        // EVENTS
        AddSubcategorySeed(TempSubcategory, XEVENTSTxt, XEVENTSTxt, XEventsSubDescTxt, XEventsPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XOTHERTxt, XEVENTSTxt, XEventsOtherDescTxt, XSubEventsOtherPostingTxt, true, false);

        // GARAGE-SERVICE
        AddSubcategorySeed(TempSubcategory, XGARAGESERVICETxt, XGARAGESERVICETxt, XGarageServiceSubDescTxt, XGarageServicePostingTxt, true, false);

        // GIFTS
        AddSubcategorySeed(TempSubcategory, XGIFTSTxt, XGIFTSTxt, XGiftsSubDescTxt, XGiftsPostingTxt, true, false);

        // GROUND-TRANS
        AddSubcategorySeed(TempSubcategory, XGROUNDTRANSTxt, XGROUNDTRANSTxt, XGroundTransSubDescTxt, XGroundTransPostingTxt, true, false);

        // INTERNET
        AddSubcategorySeed(TempSubcategory, XINTERNETTxt, XINTERNETTxt, XInternetSubDescTxt, XInternetPostingTxt, true, false);

        // MISC
        AddSubcategorySeed(TempSubcategory, XMISCTxt, XMISCTxt, XMiscSubDescTxt, XMiscPostingTxt, true, false);

        // PARKING
        AddSubcategorySeed(TempSubcategory, XPARKINGTxt, XPARKINGTxt, XParkingSubDescTxt, XParkingPostingTxt, true, false);

        // PASSPORT
        AddSubcategorySeed(TempSubcategory, XPASSPORTTxt, XPASSPORTTxt, XPassportSubDescTxt, XPassportPostingTxt, true, false);

        // PERSONAL
        AddSubcategorySeed(TempSubcategory, XPERSONALTxt, XPERSONALTxt, XPersonalSubDescTxt, XPersonalPostingTxt, true, false);

        // PHARMACY
        AddSubcategorySeed(TempSubcategory, XDRUGSTxt, XPHARMACYTxt, XPharmacyDrugsDescTxt, XSubDrugsPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XBANDAGESTxt, XPHARMACYTxt, XPharmacyBandagesDescTxt, XSubBandagesPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XOTHERTxt, XPHARMACYTxt, XPharmacyOtherDescTxt, XSubOtherItemsPostingTxt, true, false);

        // RENTALCARS
        AddSubcategorySeed(TempSubcategory, XCARUSAGESubTxt, XRENTALCARSTxt, XRentalCarUsageDescTxt, XSubRentalBasePostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XINSURANCETxt, XRENTALCARSTxt, XRentalInsuranceDescTxt, XSubRentalInsurancePostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XFUELTxt, XRENTALCARSTxt, XRentalFuelDescTxt, XSubRentalFuelPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XCHARGESTxt, XRENTALCARSTxt, XRentalChargesDescTxt, XSubRentalChargesPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XOTHERTxt, XRENTALCARSTxt, XRentalOtherDescTxt, XSubRentalOtherPostingTxt, true, false);

        // SUBSCRIPTIONS
        AddSubcategorySeed(TempSubcategory, XSUBSCRIPTIONTxt, XSUBSCRIPTIONTxt, XSubscriptionsSubDescTxt, XSubscriptionsPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XPERSONALTxt, XSUBSCRIPTIONTxt, XSubscriptionsPersonalDescTxt, XSubPersonalSubsPostingTxt, true, false);

        // TOLLS
        AddSubcategorySeed(TempSubcategory, XTOLLSTxt, XTOLLSTxt, XTollsSubDescTxt, XTollsPostingTxt, true, false);

        // TIPS
        AddSubcategorySeed(TempSubcategory, XTIPSTxt, XTIPSTxt, XTipsSubDescTxt, XTipsPostingTxt, true, false);

        // PER-DIEM
        AddSubcategorySeed(TempSubcategory, XCOUNTRYTxt, XPERDIEMTxt, XCountryPerDiemDescTxt, XSubCountryPerDiemPostingTxt, true, false);
        AddSubcategorySeed(TempSubcategory, XINTERNATIONALTxt, XPERDIEMTxt, XIntlPerDiemDescTxt, XSubIntlPerDiemPostingTxt, true, false);

        // FINES
        AddSubcategorySeed(TempSubcategory, XFINESTxt, XFINESTxt, XFinesSubDescTxt, XFinesPostingTxt, true, false);

        if GetCountryCode() = 'AT' then begin
            AddSubcategorySeed(TempSubcategory, XCOUNTRYTxt, XPERDIEMATxt, XCountryPerDiemDescTxt, XSubCountryPerDiemPostingTxt, true, false);
            AddSubcategorySeed(TempSubcategory, XINTLTxt, XPERDIEMITxt, XIntlPerDiemDescTxt, XSubIntlPerDiemPostingTxt, true, false);
        end;

        OnAfterBuildSubcategorySeeds(TempSubcategory);
    end;

    internal procedure GetTRAVELTxt(): Code[20]
    begin
        exit(XTRAVELTxt);
    end;

    internal procedure GetCASHTxt(): Code[10]
    begin
        exit(XCASHTxt);
    end;

    internal procedure GetPERDIEMTxt(): Code[20]
    begin
        exit(XPERDIEMTxt);
    end;

    internal procedure GetCANADAALLTxt(): Code[20]
    begin
        exit(XCANADAALLTxt);
    end;

    internal procedure GetDENMARKALLTxt(): Code[20]
    begin
        exit(XDENMARKALLTxt);
    end;

    internal procedure GetDOMESTICTxt(): Code[20]
    begin
        exit(XDOMESTICTxt);
    end;

    internal procedure GetFRANCEALLTxt(): Code[20]
    begin
        exit(XFRANCEALLTxt);
    end;

    internal procedure GetGERMANYALLTxt(): Code[20]
    begin
        exit(XGERMANYALLTxt);
    end;

    internal procedure GetUKOTHERTxt(): Code[20]
    begin
        exit(XUKOTHERTxt);
    end;

    internal procedure GetEXPENSETRAVELTxt(): Code[20]
    begin
        exit(XEXPENSETRAVELTxt);
    end;

    internal procedure GetUSAOTHERTxt(): Code[20]
    begin
        exit(XUSAOTHERTxt);
    end;

    internal procedure GetEXPENSEPERDIEMTxt(): Code[20]
    begin
        exit(XEXPENSEPERDIEMTxt);
    end;

    internal procedure GetEXPENSEOTHERTxt(): Code[20]
    begin
        exit(XEXPENSEOTHERTxt);
    end;

    internal procedure GetEXPENSEMILEAGETxt(): Code[20]
    begin
        exit(XEXPENSEMILEAGETxt);
    end;

    internal procedure GetEXPENSEMEALSTxt(): Code[20]
    begin
        exit(XEXPENSEMEALSTxt);
    end;

    internal procedure GetEXPENSEENTERTAINTxt(): Code[20]
    begin
        exit(XEXPENSEENTERTAINTxt);
    end;

    internal procedure GetHOTELSTxt(): Code[20]
    begin
        exit(XHOTELSTxt);
    end;

    internal procedure GetMEALSTxt(): Code[20]
    begin
        exit(XMEALSTxt);
    end;

    internal procedure GetAIRLINETxt(): Code[20]
    begin
        exit(XAIRLINETxt);
    end;

    internal procedure GetGROUNDTRANSTxt(): Code[20]
    begin
        exit(XGROUNDTRANSTxt);
    end;

    internal procedure GetRENTALCARSTxt(): Code[20]
    begin
        exit(XRENTALCARSTxt);
    end;

    internal procedure GetCARTxt(): Code[20]
    begin
        exit(XCARTxt);
    end;

    internal procedure GetEVENTSTxt(): Code[20]
    begin
        exit(XEVENTSTxt);
    end;

    internal procedure GetENTERTAINTxt(): Code[20]
    begin
        exit(XENTERTAINTxt);
    end;

    internal procedure GetFOODTxt(): Code[20]
    begin
        exit(XFOODTxt);
    end;

    internal procedure GetALCOHOLTxt(): Code[20]
    begin
        exit(XALCOHOLTxt);
    end;

    internal procedure GetROOMTxt(): Code[20]
    begin
        exit(XROOMTxt);
    end;

    internal procedure GetBREAKFASTTxt(): Code[20]
    begin
        exit(XBREAKFASTTxt);
    end;

    internal procedure GetDEPOSITTxt(): Code[20]
    begin
        exit(XDEPOSITTxt);
    end;

    internal procedure GetTAXTxt(): Code[20]
    begin
        exit(XTAXTxt);
    end;

    internal procedure GetFEETxt(): Code[20]
    begin
        exit(XFEETxt);
    end;

    internal procedure GetPHONETxt(): Code[20]
    begin
        exit(XPHONETxt);
    end;

    internal procedure GetINTERNETTxt(): Code[20]
    begin
        exit(XINTERNETTxt);
    end;

    internal procedure GetINCIDENTSTxt(): Code[20]
    begin
        exit(XINCIDENTSTxt);
    end;

    internal procedure GetLAUNDRYTxt(): Code[20]
    begin
        exit(XLAUNDRYTxt);
    end;

    internal procedure GetROOMSERVICETxt(): Code[20]
    begin
        exit(XROOMSERVICETxt);
    end;

    internal procedure GetHOTELPARKTxt(): Code[20]
    begin
        exit(XHOTELPARKTxt);
    end;

    internal procedure GetHOTELOTHERTxt(): Code[20]
    begin
        exit(XHOTELOTHERTxt);
    end;

    internal procedure GetPARKINGTxt(): Code[20]
    begin
        exit(XPARKINGTxt);
    end;

    internal procedure GetOTHERTxt(): Code[20]
    begin
        exit(XOTHERTxt);
    end;

    internal procedure GetTIPSTxt(): Code[20]
    begin
        exit(XTIPSTxt);
    end;

    internal procedure GetTRANSPORTTxt(): Code[20]
    begin
        exit(XTRANSPORTTxt);
    end;

    /// <summary>
    /// Builds the preview record set for expense categories and subcategories: existing rows
    /// plus seeds that do not yet exist. Seed subcategories are only proposed for categories
    /// that the defaults run will actually create; pre-existing categories are left alone, and
    /// so are their children. No database writes are performed.
    /// </summary>
    internal procedure LoadCategoriesPreview(var TempCategory: Record "Expense Category" temporary; var TempSubcategory: Record "Expense Subcategory" temporary)
    var
        ExistingCategory: Record "Expense Category";
        ExistingSubcategory: Record "Expense Subcategory";
        TempCategorySeed: Record "Expense Category" temporary;
        TempSubcategorySeed: Record "Expense Subcategory" temporary;
        TempPreExistingSeedCategory: Record "Expense Category" temporary;
    begin
        TempCategory.Reset();
        TempCategory.DeleteAll();
        TempSubcategory.Reset();
        TempSubcategory.DeleteAll();

        if ExistingCategory.FindSet() then
            repeat
                TempCategory := ExistingCategory;
                TempCategory.Insert();
            until ExistingCategory.Next() = 0;

        if ExistingSubcategory.FindSet() then
            repeat
                TempSubcategory := ExistingSubcategory;
                TempSubcategory.Insert();
            until ExistingSubcategory.Next() = 0;

        BuildCategorySeeds(TempCategorySeed);
        if TempCategorySeed.FindSet() then
            repeat
                if TempCategory.Get(TempCategorySeed.Code) then begin
                    TempPreExistingSeedCategory := TempCategory;
                    TempPreExistingSeedCategory.Insert();
                end else begin
                    TempCategory := TempCategorySeed;
                    TempCategory.Insert();
                end;
            until TempCategorySeed.Next() = 0;

        BuildSubcategorySeeds(TempSubcategorySeed);
        if TempSubcategorySeed.FindSet() then
            repeat
                // Skip seed subcategories whose parent category already exists — the defaults
                // run will not touch children of a customer-owned category.
                if not TempPreExistingSeedCategory.Get(TempSubcategorySeed."Expense Category Code") then
                    if not TempSubcategory.Get(TempSubcategorySeed."Expense Category Code", TempSubcategorySeed.Code) then begin
                        TempSubcategory := TempSubcategorySeed;
                        TempSubcategory.Insert();
                    end;
            until TempSubcategorySeed.Next() = 0;
    end;

    internal procedure AddCategorySeed(var TempCategory: Record "Expense Category" temporary; Code: Code[20]; Description: Text[250]; PostingDescription: Text[100]; ExpenseGroupCode: Code[20]; PostingGroupCode: Code[20]; PaymentMethod: Code[10]; IsRefundable: Boolean; IsPrepayment: Boolean; AttachmentEnforcement: Enum "Expense Attachment Enforcement"; DetailRequired: Enum "Expense Detail Needed")
    var
        IsHandled: Boolean;
    begin
        OnBeforeAddCategorySeed(Code, Description, PostingDescription, ExpenseGroupCode, PostingGroupCode, PaymentMethod, IsRefundable, IsPrepayment, AttachmentEnforcement, DetailRequired, IsHandled);
        if IsHandled then
            exit;

        if (GetCountryCode() = 'AT') and (Code = XPERDIEMTxt) then
            exit;

        TempCategory.Init();
        TempCategory.Code := Code;
        TempCategory.Description := Description;
        TempCategory."Posting Description" := PostingDescription;
        TempCategory."Expense Group" := ExpenseGroupCode;
        TempCategory."Posting Group" := PostingGroupCode;
        TempCategory."Default Payment Method" := PaymentMethod;
        TempCategory.Refundable := IsRefundable;
        TempCategory."Prepayment-Cash Advance" := IsPrepayment;
        TempCategory."Attachment Enforcement" := AttachmentEnforcement;
        TempCategory."Expense Detail Required" := DetailRequired;
        TempCategory.Insert();
    end;

    internal procedure AddSubcategorySeed(var TempSubcategory: Record "Expense Subcategory" temporary; SubcategoryCode: Code[20]; CategoryCode: Code[20]; Description: Text[250]; PostingDescription: Text[100]; Refundable: Boolean; DescriptionMandatory: Boolean)
    var
        IsHandled: Boolean;
    begin
        OnBeforeAddSubcategorySeed(SubcategoryCode, CategoryCode, Description, PostingDescription, Refundable, DescriptionMandatory, IsHandled);
        if IsHandled then
            exit;

        if (GetCountryCode() = 'AT') and (CategoryCode = XPERDIEMTxt) then
            exit;

        TempSubcategory.Init();
        TempSubcategory."Expense Category Code" := CategoryCode;
        TempSubcategory.Code := SubcategoryCode;
        TempSubcategory.Description := Description;
        TempSubcategory."Posting Description" := PostingDescription;
        TempSubcategory.Refundable := Refundable;
        TempSubcategory."Expense Description Mandatory" := DescriptionMandatory;
        TempSubcategory.Insert();
    end;

    internal procedure InsertDefaultExpenseLocations()
    var
        TempLocationSeed: Record "Expense Location" temporary;
    begin
        BuildLocationSeeds(TempLocationSeed);
        if TempLocationSeed.FindSet() then
            repeat
                if not SeedLocationShouldBeSkipped(TempLocationSeed) then
                    InsertExpenseLocation(TempLocationSeed."No.", TempLocationSeed."Country/Region Code", TempLocationSeed.Description);
            until TempLocationSeed.Next() = 0;
    end;

    internal procedure SeedLocationShouldBeSkipped(SeedLocation: Record "Expense Location"): Boolean
    var
        ConflictingLocation: Record "Expense Location";
    begin
        if ConflictingLocation.Get(SeedLocation."No.") then
            exit(false);

        ConflictingLocation.Reset();
        ConflictingLocation.SetFilter("No.", '<>%1', SeedLocation."No.");
        ConflictingLocation.SetRange("Country/Region Code", SeedLocation."Country/Region Code");
        ConflictingLocation.SetRange(County, SeedLocation.County);
        ConflictingLocation.SetRange(City, SeedLocation.City);
        exit(not ConflictingLocation.IsEmpty());
    end;

    internal procedure BuildSkippedSeedLocations(var TempSkippedLocation: Record "Expense Location" temporary)
    var
        TempLocationSeed: Record "Expense Location" temporary;
    begin
        TempSkippedLocation.Reset();
        TempSkippedLocation.DeleteAll();

        BuildLocationSeeds(TempLocationSeed);
        if TempLocationSeed.FindSet() then
            repeat
                if SeedLocationShouldBeSkipped(TempLocationSeed) then begin
                    TempSkippedLocation := TempLocationSeed;
                    TempSkippedLocation.Insert();
                end;
            until TempLocationSeed.Next() = 0;
    end;

    /// <summary>
    /// Returns the catalogue of default expense locations without writing anything to the database.
    /// </summary>
    internal procedure BuildLocationSeeds(var TempExpenseLocation: Record "Expense Location" temporary)
    begin
        TempExpenseLocation.Reset();
        TempExpenseLocation.DeleteAll();

        AddLocationSeed(TempExpenseLocation, XCANADAALLTxt, 'CA', 'Canada - All');
        AddLocationSeed(TempExpenseLocation, XDENMARKALLTxt, 'DK', 'Denmark - All');
        AddLocationSeed(TempExpenseLocation, XDOMESTICTxt, '', 'Domestic');
        AddLocationSeed(TempExpenseLocation, XFRANCEALLTxt, 'FR', 'France - All');
        AddLocationSeed(TempExpenseLocation, XGERMANYALLTxt, 'DE', 'Germany - All');
        AddLocationSeed(TempExpenseLocation, XUKOTHERTxt, 'GB', 'United Kingdom - Other');
        AddLocationSeed(TempExpenseLocation, XUSAOTHERTxt, 'US', 'United States - Other');
    end;

    /// <summary>
    /// Builds the preview record set for expense locations: existing rows plus seeds that
    /// do not yet exist. No database writes are performed.
    /// </summary>
    internal procedure LoadLocationsPreview(var TempExpenseLocation: Record "Expense Location" temporary)
    var
        ExistingLocation: Record "Expense Location";
        TempSeed: Record "Expense Location" temporary;
    begin
        TempExpenseLocation.Reset();
        TempExpenseLocation.DeleteAll();

        if ExistingLocation.FindSet() then
            repeat
                TempExpenseLocation := ExistingLocation;
                TempExpenseLocation.Insert();
            until ExistingLocation.Next() = 0;

        BuildLocationSeeds(TempSeed);
        if TempSeed.FindSet() then
            repeat
                if not SeedLocationShouldBeSkippedInPreview(TempExpenseLocation, TempSeed) then begin
                    TempExpenseLocation := TempSeed;
                    TempExpenseLocation.Insert();
                end;
            until TempSeed.Next() = 0;
    end;

    local procedure SeedLocationShouldBeSkippedInPreview(var TempExpenseLocation: Record "Expense Location" temporary; SeedLocation: Record "Expense Location"): Boolean
    begin
        // Skip if the same seed code already exists in the preview set.
        if TempExpenseLocation.Get(SeedLocation."No.") then
            exit(true);

        // Skip when a different code already occupies the same location dimensions.
        TempExpenseLocation.Reset();
        TempExpenseLocation.SetFilter("No.", '<>%1', SeedLocation."No.");
        TempExpenseLocation.SetRange("Country/Region Code", SeedLocation."Country/Region Code");
        TempExpenseLocation.SetRange(County, SeedLocation.County);
        TempExpenseLocation.SetRange(City, SeedLocation.City);
        exit(not TempExpenseLocation.IsEmpty());
    end;

    local procedure AddLocationSeed(var TempExpenseLocation: Record "Expense Location" temporary; LocationNo: Code[20]; CountryRegionCode: Code[10]; Description: Text[100])
    begin
        TempExpenseLocation.Init();
        TempExpenseLocation."No." := LocationNo;
        TempExpenseLocation."Country/Region Code" := CountryRegionCode;
        TempExpenseLocation.Description := Description;
        TempExpenseLocation.Insert();
    end;

    internal procedure InsertDefaultManagementRules()
    var
        TempRuleHeaderSeed: Record "Expense Rule Header" temporary;
        TempRuleConditionSeed: Record "Expense Rule Condition" temporary;
        TempPreExistingRuleHeader: Record "Expense Rule Header" temporary;
        TempSkippedSeedLocation: Record "Expense Location" temporary;
        ExistingRuleHeader: Record "Expense Rule Header";
    begin
        // Expense Locations are a prerequisite for rules that target a location.
        InsertDefaultExpenseLocations();

        BuildSkippedSeedLocations(TempSkippedSeedLocation);

        BuildRuleSeeds(TempRuleHeaderSeed);

        // Snapshot which seed-coded rule headers already exist in the DB. Their conditions
        // are considered customer-owned and must not be touched by the defaults run.
        if TempRuleHeaderSeed.FindSet() then
            repeat
                if not TempSkippedSeedLocation.Get(TempRuleHeaderSeed."Expense Location") then
                    if ExistingRuleHeader.Get(TempRuleHeaderSeed."Expense Category Code", TempRuleHeaderSeed."Expense Location", TempRuleHeaderSeed."Effective Date") then begin
                        TempPreExistingRuleHeader := ExistingRuleHeader;
                        TempPreExistingRuleHeader.Insert();
                    end;
            until TempRuleHeaderSeed.Next() = 0;

        if TempRuleHeaderSeed.FindSet() then
            repeat
                if not TempSkippedSeedLocation.Get(TempRuleHeaderSeed."Expense Location") then
                    InsertExpenseRule(TempRuleHeaderSeed."Expense Category Code", TempRuleHeaderSeed."Expense Location", TempRuleHeaderSeed."Currency Code", TempRuleHeaderSeed."Justification Required");
            until TempRuleHeaderSeed.Next() = 0;

        BuildRuleConditionSeeds(TempRuleConditionSeed);
        if TempRuleConditionSeed.FindSet() then
            repeat
                if not TempSkippedSeedLocation.Get(TempRuleConditionSeed."Expense Location") then
                    if not TempPreExistingRuleHeader.Get(TempRuleConditionSeed."Expense Category Code", TempRuleConditionSeed."Expense Location", TempRuleConditionSeed."Effective Date") then
                        InsertExpenseRuleCondition(TempRuleConditionSeed."Expense Category Code", TempRuleConditionSeed."Expense Location", TempRuleConditionSeed."Condition Type", TempRuleConditionSeed.Value);
            until TempRuleConditionSeed.Next() = 0;
    end;

    /// <summary>
    /// Returns the catalogue of default expense rule headers without writing anything to the database.
    /// </summary>
    internal procedure BuildRuleSeeds(var TempRuleHeader: Record "Expense Rule Header" temporary)
    begin
        TempRuleHeader.Reset();
        TempRuleHeader.DeleteAll();

        AddRuleSeed(TempRuleHeader, XENTERTAINTxt, '', '', "Expense Justification"::"Against Conditions");
        AddRuleSeed(TempRuleHeader, XHOTELSTxt, '', '', "Expense Justification"::" ");
        AddRuleSeed(TempRuleHeader, XMILEAGETxt, '', '', "Expense Justification"::" ");
        AddRuleSeed(TempRuleHeader, XMORALETxt, '', '', "Expense Justification"::" ");
        AddRuleSeed(TempRuleHeader, XPERDIEMTxt, XCANADAALLTxt, 'CAD', "Expense Justification"::" ");
        AddRuleSeed(TempRuleHeader, XPERDIEMTxt, XDENMARKALLTxt, 'EUR', "Expense Justification"::" ");
        AddRuleSeed(TempRuleHeader, XPERDIEMTxt, XDOMESTICTxt, 'USD', "Expense Justification"::" ");
        AddRuleSeed(TempRuleHeader, XPERDIEMTxt, XFRANCEALLTxt, 'EUR', "Expense Justification"::" ");
        AddRuleSeed(TempRuleHeader, XPERDIEMTxt, XGERMANYALLTxt, 'EUR', "Expense Justification"::" ");
        AddRuleSeed(TempRuleHeader, XPERDIEMTxt, XUKOTHERTxt, 'GBP', "Expense Justification"::" ");
        AddRuleSeed(TempRuleHeader, XPERDIEMTxt, XUSAOTHERTxt, 'USD', "Expense Justification"::" ");

        if GetCountryCode() = 'AT' then begin
            AddRuleSeed(TempRuleHeader, XPERDIEMITxt, XCANADAALLTxt, 'CAD', "Expense Justification"::" ");
            AddRuleSeed(TempRuleHeader, XPERDIEMITxt, XDENMARKALLTxt, 'USD', "Expense Justification"::" ");
            AddRuleSeed(TempRuleHeader, XPERDIEMATxt, XDOMESTICTxt, 'USD', "Expense Justification"::" ");
            AddRuleSeed(TempRuleHeader, XPERDIEMITxt, XFRANCEALLTxt, 'USD', "Expense Justification"::" ");
            AddRuleSeed(TempRuleHeader, XPERDIEMITxt, XGERMANYALLTxt, 'USD', "Expense Justification"::" ");
            AddRuleSeed(TempRuleHeader, XPERDIEMITxt, XUKOTHERTxt, 'GBP', "Expense Justification"::" ");
            AddRuleSeed(TempRuleHeader, XPERDIEMITxt, XUSAOTHERTxt, 'USD', "Expense Justification"::" ");
        end;

        OnAfterBuildRuleSeeds(TempRuleHeader);
    end;

    /// <summary>
    /// Returns the catalogue of default expense rule conditions without writing anything to the database.
    /// </summary>
    internal procedure BuildRuleConditionSeeds(var TempRuleCondition: Record "Expense Rule Condition" temporary)
    begin
        TempRuleCondition.Reset();
        TempRuleCondition.DeleteAll();

        AddRuleConditionSeed(TempRuleCondition, XENTERTAINTxt, '', "Expense Rule Condition Type"::"At Least Justification Needed", 500);
        AddRuleConditionSeed(TempRuleCondition, XENTERTAINTxt, '', "Expense Rule Condition Type"::"Max Amount", 1000);
        AddRuleConditionSeed(TempRuleCondition, XMILEAGETxt, '', "Expense Rule Condition Type"::"Max Amount", 300);
        AddRuleConditionSeed(TempRuleCondition, XPERDIEMTxt, XCANADAALLTxt, "Expense Rule Condition Type"::"Daily Rate", 125);
        AddRuleConditionSeed(TempRuleCondition, XPERDIEMTxt, XDENMARKALLTxt, "Expense Rule Condition Type"::"Daily Rate", 450);
        AddRuleConditionSeed(TempRuleCondition, XPERDIEMTxt, XDOMESTICTxt, "Expense Rule Condition Type"::"Daily Rate", 50);
        AddRuleConditionSeed(TempRuleCondition, XPERDIEMTxt, XFRANCEALLTxt, "Expense Rule Condition Type"::"Daily Rate", 110);
        AddRuleConditionSeed(TempRuleCondition, XPERDIEMTxt, XGERMANYALLTxt, "Expense Rule Condition Type"::"Daily Rate", 105);
        AddRuleConditionSeed(TempRuleCondition, XPERDIEMTxt, XUKOTHERTxt, "Expense Rule Condition Type"::"Daily Rate", 115);
        AddRuleConditionSeed(TempRuleCondition, XPERDIEMTxt, XUSAOTHERTxt, "Expense Rule Condition Type"::"Daily Rate", 120);

        if GetCountryCode() = 'AT' then begin
            AddRuleConditionSeed(TempRuleCondition, XPERDIEMITxt, XCANADAALLTxt, "Expense Rule Condition Type"::"Daily Rate", 125);
            AddRuleConditionSeed(TempRuleCondition, XPERDIEMITxt, XDENMARKALLTxt, "Expense Rule Condition Type"::"Daily Rate", 450);
            AddRuleConditionSeed(TempRuleCondition, XPERDIEMATxt, XDOMESTICTxt, "Expense Rule Condition Type"::"Daily Rate", 50);
            AddRuleConditionSeed(TempRuleCondition, XPERDIEMITxt, XFRANCEALLTxt, "Expense Rule Condition Type"::"Daily Rate", 110);
            AddRuleConditionSeed(TempRuleCondition, XPERDIEMITxt, XGERMANYALLTxt, "Expense Rule Condition Type"::"Daily Rate", 105);
            AddRuleConditionSeed(TempRuleCondition, XPERDIEMITxt, XUKOTHERTxt, "Expense Rule Condition Type"::"Daily Rate", 115);
            AddRuleConditionSeed(TempRuleCondition, XPERDIEMITxt, XUSAOTHERTxt, "Expense Rule Condition Type"::"Daily Rate", 120);
        end;

        OnAfterBuildRuleConditionSeeds(TempRuleCondition);
    end;

    /// <summary>
    /// Builds the preview record set for expense management rules: existing rows plus seeds
    /// that do not yet exist. Seed conditions are only proposed for rule headers that the
    /// defaults run will actually create; pre-existing rule headers are left alone, and so
    /// are their conditions. No database writes are performed.
    /// </summary>
    internal procedure LoadRulesPreview(var TempRuleHeader: Record "Expense Rule Header" temporary; var TempRuleCondition: Record "Expense Rule Condition" temporary)
    var
        ExistingRuleHeader: Record "Expense Rule Header";
        ExistingRuleCondition: Record "Expense Rule Condition";
        TempHeaderSeed: Record "Expense Rule Header" temporary;
        TempConditionSeed: Record "Expense Rule Condition" temporary;
        TempPreExistingSeedHeader: Record "Expense Rule Header" temporary;
        TempSkippedSeedLocation: Record "Expense Location" temporary;
        NextLineNo: Integer;
    begin
        TempRuleHeader.Reset();
        TempRuleHeader.DeleteAll();
        TempRuleCondition.Reset();
        TempRuleCondition.DeleteAll();

        BuildSkippedSeedLocations(TempSkippedSeedLocation);

        // 1) Existing rows from the database.
        if ExistingRuleHeader.FindSet() then
            repeat
                TempRuleHeader := ExistingRuleHeader;
                TempRuleHeader.Insert();
            until ExistingRuleHeader.Next() = 0;

        if ExistingRuleCondition.FindSet() then
            repeat
                TempRuleCondition := ExistingRuleCondition;
                TempRuleCondition.Insert();
            until ExistingRuleCondition.Next() = 0;

        // 2) Seed headers not yet present.
        BuildRuleSeeds(TempHeaderSeed);
        if TempHeaderSeed.FindSet() then
            repeat
                if not TempSkippedSeedLocation.Get(TempHeaderSeed."Expense Location") then
                    if TempRuleHeader.Get(TempHeaderSeed."Expense Category Code", TempHeaderSeed."Expense Location", TempHeaderSeed."Effective Date") then begin
                        TempPreExistingSeedHeader := TempRuleHeader;
                        TempPreExistingSeedHeader.Insert();
                    end else begin
                        TempRuleHeader := TempHeaderSeed;
                        TempRuleHeader.Insert();
                    end;
            until TempHeaderSeed.Next() = 0;

        // 3) Seed conditions — only for headers we will actually create.
        BuildRuleConditionSeeds(TempConditionSeed);
        if TempConditionSeed.FindSet() then
            repeat
                if not TempSkippedSeedLocation.Get(TempConditionSeed."Expense Location") then
                    if not TempPreExistingSeedHeader.Get(TempConditionSeed."Expense Category Code", TempConditionSeed."Expense Location", TempConditionSeed."Effective Date") then begin
                        TempRuleCondition.Reset();
                        TempRuleCondition.SetRange("Expense Category Code", TempConditionSeed."Expense Category Code");
                        TempRuleCondition.SetRange("Expense Location", TempConditionSeed."Expense Location");
                        TempRuleCondition.SetRange("Condition Type", TempConditionSeed."Condition Type");
                        if TempRuleCondition.IsEmpty() then begin
                            TempRuleCondition.Reset();
                            TempRuleCondition.SetRange("Expense Category Code", TempConditionSeed."Expense Category Code");
                            TempRuleCondition.SetRange("Expense Location", TempConditionSeed."Expense Location");
                            if TempRuleCondition.FindLast() then
                                NextLineNo := TempRuleCondition."Line No." + 1
                            else
                                NextLineNo := 1;
                            TempRuleCondition.Reset();
                            TempRuleCondition := TempConditionSeed;
                            TempRuleCondition."Line No." := NextLineNo;
                            TempRuleCondition.Insert();
                        end;
                        TempRuleCondition.Reset();
                    end;
            until TempConditionSeed.Next() = 0;
    end;

    internal procedure AddRuleSeed(var TempRuleHeader: Record "Expense Rule Header" temporary; CategoryCode: Code[20]; ExpenseLocationCode: Code[20]; CurrencyCode: Code[10]; JustificationRequired: Enum "Expense Justification")
    var
        EURCurrency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        IsHandled: Boolean;
    begin
        OnBeforeAddRuleSeed(TempRuleHeader, CategoryCode, ExpenseLocationCode, CurrencyCode, JustificationRequired, IsHandled);
        if IsHandled then
            exit;

        if (GetCountryCode() = 'AT') and (CategoryCode = XPERDIEMTxt) then
            exit;

        if (CurrencyCode = 'EUR') and (not EURCurrency.Get('EUR')) then
            CurrencyCode := 'USD';

        if GeneralLedgerSetup.Get() then
            if CurrencyCode = GeneralLedgerSetup."LCY Code" then
                CurrencyCode := '';

        TempRuleHeader.Init();
        TempRuleHeader."Expense Category Code" := CategoryCode;
        TempRuleHeader."Expense Location" := ExpenseLocationCode;
        TempRuleHeader."Currency Code" := CurrencyCode;
        TempRuleHeader."Justification Required" := JustificationRequired;
        OnBeforeInsertRuleSeed(TempRuleHeader);
        TempRuleHeader.Insert();
    end;

    internal procedure AddRuleConditionSeed(var TempRuleCondition: Record "Expense Rule Condition" temporary; CategoryCode: Code[20]; ExpenseLocationCode: Code[20]; ConditionType: Enum "Expense Rule Condition Type"; Value: Decimal)
    var
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeAddRuleConditionSeed(TempRuleCondition, CategoryCode, ExpenseLocationCode, ConditionType, Value, IsHandled);
        if IsHandled then
            exit;

        if (GetCountryCode() = 'AT') and (CategoryCode = XPERDIEMTxt) then
            exit;

        TempRuleCondition.Reset();
        TempRuleCondition.SetRange("Expense Category Code", CategoryCode);
        TempRuleCondition.SetRange("Expense Location", ExpenseLocationCode);
        if TempRuleCondition.FindLast() then
            NextLineNo := TempRuleCondition."Line No." + 1
        else
            NextLineNo := 1;
        TempRuleCondition.Reset();

        TempRuleCondition.Init();
        TempRuleCondition."Expense Category Code" := CategoryCode;
        TempRuleCondition."Expense Location" := ExpenseLocationCode;
        TempRuleCondition."Line No." := NextLineNo;
        TempRuleCondition."Condition Type" := ConditionType;
        TempRuleCondition.Value := Value;
        TempRuleCondition.Insert();
    end;

    local procedure InsertDefaultExpenseGroups()
    begin
        InsertExpenseGroup(XTRAVELTxt, 'Travel Expenses');
        InsertExpenseGroup(XDAYEXPENSETxt, 'Day-to-Day Expenses');
        InsertExpenseGroup(XFOODBEVERAGETxt, 'Food & Beverage Expenses');
        InsertExpenseGroup(XPERSONALTxt, 'Personal Expenses');
        InsertExpenseGroup(XPREPAYMENTTxt, 'Prepayments - Cash Advance');
    end;

    local procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then
            exit(CompanyInformation."Country/Region Code");
    end;

    var
        XAIRLINETxt: Label 'AIRLINE', Locked = true;
        XAirlineTicketsTxt: Label 'Expenses for commercial air travel, including airline tickets and airfare. Covers flights, passenger names, routes, carriers, booking references, fares, taxes, seat selection, baggage or change fees, and boarding passes.', MaxLength = 250;
        XCARTxt: Label 'CAR', Locked = true;
        XCarUsageTxt: Label 'Expenses related to company car usage, including fuel, charging, car washes, small tools, consumables, and minor maintenance or repairs performed outside garage service. Excludes major servicing, leasing, and insurance.', MaxLength = 250;
        XCOURIERTxt: Label 'COURIER', Locked = true;
        XDeliveryExpenseTxt: Label 'Expenses for courier, delivery, and parcel services used to send or receive documents, packages, or goods. Includes postal services, express couriers, same-day delivery, shipping fees, and related surcharges.', MaxLength = 250;
        XENTERTAINTxt: Label 'ENTERTAIN', Locked = true;
        XEntertainmentTxt: Label 'Expenses for external entertainment with current or potential customers or business partners. Includes cafes, restaurants, bars, meals, beverages, and similar hospitality costs incurred for business relationship building.', MaxLength = 250;
        XMORALETxt: Label 'MORALE', Locked = true;
        XMoraleEventTxt: Label 'Expenses for employee morale and team-building activities, including company or team lunches, dinners, offsites, excursions, social events, and similar internal gatherings intended to improve teamwork, engagement, and company culture.', MaxLength = 250;
        XEVENTSTxt: Label 'EVENTS', Locked = true;
        XConferencesandOtherEventsTxt: Label 'Expenses for business events such as conferences, summits, trade fairs, and exhibitions. Includes registration or entry fees, tickets, booths, badges, event materials, and other costs directly related to event participation.', MaxLength = 250;
        XFINESTxt: Label 'FINES', Locked = true;
        XFinesDescTxt: Label 'Expenses for fines, penalties, and sanctions imposed by authorities or regulators due to violations or non-compliance. Includes traffic fines, regulatory penalties, late fees, and administrative sanctions. Excludes normal taxes and interest.', MaxLength = 250;
        XGARAGESERVICETxt: Label 'GARAGE-SERVICE', Locked = true;
        XGarageServiceDescTxt: Label 'Professional garage repair and maintenance services for company cars and trucks. Includes labor and parts for repairs, servicing, diagnostics, inspections, tire services, and routine maintenance performed by authorized or independent garages.', MaxLength = 250;
        XGIFTSTxt: Label 'GIFTS', Locked = true;
        XGiftCertificatesTxt: Label 'Expenses for gift certificates or tangible gifts provided to current or potential business partners. Includes vouchers, gift cards, branded or non-branded items, and other physical gifts given for business relationship purposes.', MaxLength = 250;
        XGROUNDTRANSTxt: Label 'GROUNDTRAN', Locked = true;
        XGroundTransportationTxt: Label 'Expenses for ground transportation related to business travel, including buses, taxis and cabs, ride-hailing services, trains, metro or subway, trams, ferries or boats, limo services, and similar local or regional transport.', MaxLength = 250;
        XHOTELSTxt: Label 'HOTELS', Locked = true;
        XHotelStayTxt: Label 'Expenses for hotel and accommodation stays related to business travel. Includes room charges, mandatory hotel fees, city or tourist taxes, and in-stay services charged to the room.', MaxLength = 250;
        XINTERNETTxt: Label 'INTERNET', Locked = true;
        XInternetFeesTxt: Label 'Expenses for internet and data access related to business activities or travel. Includes hotel Wi-Fi charges, mobile data roaming fees, hotspot usage, prepaid data packages, and temporary internet services incurred while traveling.', MaxLength = 250;
        XMEALSTxt: Label 'MEALS', Locked = true;
        XMealsDescTxt: Label 'Expenses for meals provided to employees during working hours or business travel. Includes breakfasts, lunches, dinners, and meal allowances consumed during business-related activities. Excludes external entertainment and purely personal meals.', MaxLength = 250;
        XMILEAGETxt: Label 'MILEAGE', Locked = true;
        XMileageDescTxt: Label 'Expenses for business mileage using a privately owned vehicle. Includes distance-based mileage claims for business travel, calculated per approved mileage rates. Excludes fuel receipts and company car expenses.', MaxLength = 250;
        XMISCTxt: Label 'MISC', Locked = true;
        XMiscellaneousExpensesTxt: Label 'Expenses that do not clearly fit into any other defined expense category. Used for infrequent or exceptional business-related costs not covered elsewhere, subject to review and company policy.', MaxLength = 250;
        XPARKINGTxt: Label 'PARKING', Locked = true;
        XParkingDescTxt: Label 'Expenses for parking related to business travel or work activities. Includes street parking, parking garages, airport parking, meters, and parking fees incurred while using a vehicle for business purposes.', MaxLength = 250;
        XPASSPORTTxt: Label 'PASSPORT', Locked = true;
        XPassportVisaFeesTxt: Label 'Expenses for passport, visa, and other travel document fees required for business trips. Includes application, processing, service, and government fees directly related to obtaining travel authorization.', MaxLength = 250;
        XPERDIEMTxt: Label 'PER-DIEM', Locked = true;
        XPerDiemDescTxt: Label 'Expenses for per-diem or daily allowance paid for business trips, typically based on travel itinerary or other proof of travel (e.g., booking or agenda), rather than individual expense receipts.', MaxLength = 250;
        XPHARMACYTxt: Label 'PHARMACY', Locked = true;
        XPharmacyDescTxt: Label 'Expenses for pharmacy purchases related to business activities or travel, including medicines, drugs, bandages, gauze, first-aid supplies, and similar medical or health-related items.', MaxLength = 250;
        XPERSONALTxt: Label 'PERSONAL', Locked = true;
        XPersonalExpensesTxt: Label 'Expenses of a personal nature that are not related to business activities or work duties. Includes personal purchases, private travel, leisure activities, and other non-reimbursable costs.', MaxLength = 250;
        XPREPAYMENTTxt: Label 'PREPAYMENT', Locked = true;
        XPrepaymentsCashAdvanceTxt: Label 'Paid cash allowance for the business trip.', MaxLength = 250;
        XRENTALCARSTxt: Label 'RENTALCARS', Locked = true;
        XCarRentalsDescTxt: Label 'Expenses for renting cars for business travel. Includes short- or long-term vehicle rental charges, mandatory rental fees, and basic insurance associated with the rental.', MaxLength = 250;
        XSUBSCRIPTIONTxt: Label 'SUBSCRIPTION', Locked = true;
        XProfessionalSubscriptionsTxt: Label 'Expenses for professional or business-related subscriptions. Includes software licenses, online services, professional memberships, journals, publications, and recurring digital services required for work purposes.', MaxLength = 250;
        XTIPSTxt: Label 'TIPS', Locked = true;
        XTipsDescTxt: Label 'Expenses for tips or gratuities paid in connection with business activities or travel. Includes tips for taxis, restaurants, hotels, delivery, luggage handling, and similar service-related gratuities.', MaxLength = 250;
        XTOLLSTxt: Label 'TOLLS', Locked = true;
        XTollRoadUsageFeeTxt: Label 'Expenses for tolls and road usage fees incurred during business travel. Includes highway and bridge tolls, congestion charges, road pricing fees, vignettes, and similar charges for using public roads.', MaxLength = 250;

        // Category posting descriptions
        XAirlinePostingTxt: Label 'Airline tickets', MaxLength = 100;
        XCarPostingTxt: Label 'Car usage, Fuel & Maintenance', MaxLength = 100;
        XCourierPostingTxt: Label 'Delivery expense', MaxLength = 100;
        XEntertainPostingTxt: Label 'Entertainment External, Caffe, Restaurant', MaxLength = 100;
        XMoralePostingTxt: Label 'Morale Event', MaxLength = 100;
        XEventsPostingTxt: Label 'Conferences and Other Events', MaxLength = 100;
        XFinesPostingTxt: Label 'Fines and penalties', MaxLength = 100;
        XGarageServicePostingTxt: Label 'Garage (car and trucks) repair services', MaxLength = 100;
        XGiftsPostingTxt: Label 'Gift certificates or Tangible gifts', MaxLength = 100;
        XGroundTransPostingTxt: Label 'Ground Transportation', MaxLength = 100;
        XHotelsPostingTxt: Label 'Hotel stay', MaxLength = 100;
        XInternetPostingTxt: Label 'Internet fees - Travel', MaxLength = 100;
        XMealsPostingTxt: Label 'Meals', MaxLength = 100;
        XMileagePostingTxt: Label 'Mileage - using private car for business purpose', MaxLength = 100;
        XMiscPostingTxt: Label 'Miscellaneous expenses', MaxLength = 100;
        XParkingPostingTxt: Label 'Parking', MaxLength = 100;
        XPassportPostingTxt: Label 'Passport/Visa Fees', MaxLength = 100;
        XPerDiemPostingTxt: Label 'Per Diems', MaxLength = 100;
        XPharmacyPostingTxt: Label 'Pharmacy (drugs, bandages, gauze...)', MaxLength = 100;
        XPersonalPostingTxt: Label 'Personal expenses', MaxLength = 100;
        XPrepaymentPostingTxt: Label 'Prepayments - Cash Advance', MaxLength = 100;
        XRentalCarsPostingTxt: Label 'Car Rentals', MaxLength = 100;
        XSubscriptionsPostingTxt: Label 'Professional Subscriptions', MaxLength = 100;
        XTipsPostingTxt: Label 'Tips', MaxLength = 100;
        XTollsPostingTxt: Label 'Toll / Road Usage Fee', MaxLength = 100;

        // Subcategory posting descriptions
        XSubRoomPostingTxt: Label 'Daily Room Rate', MaxLength = 100;
        XSubBreakfastPostingTxt: Label 'Daily breakfast', MaxLength = 100;
        XSubDepositPostingTxt: Label 'Hotel Deposit', MaxLength = 100;
        XSubHotelTaxPostingTxt: Label 'Hotel Tax', MaxLength = 100;
        XSubHotelFeePostingTxt: Label 'Hotel fees', MaxLength = 100;
        XSubHotelPhonePostingTxt: Label 'Hotel Telephone', MaxLength = 100;
        XSubHotelInternetPostingTxt: Label 'Hotel Internet', MaxLength = 100;
        XSubHotelIncidentsPostingTxt: Label 'Hotel Incidents', MaxLength = 100;
        XSubLaundryPostingTxt: Label 'Laundry', MaxLength = 100;
        XSubRoomServicePostingTxt: Label 'Room Service, Minibar & Meals', MaxLength = 100;
        XSubHotelParkingPostingTxt: Label 'Valet or regular parking', MaxLength = 100;
        XSubOtherPostingTxt: Label 'Other', MaxLength = 100;
        XSubHotelTransportPostingTxt: Label 'Hotel transportation', MaxLength = 100;
        XSubOrderedFoodPostingTxt: Label 'Ordered food', MaxLength = 100;
        XSubOrderedSoftDrinkPostingTxt: Label 'Ordered soft-drink or water', MaxLength = 100;
        XSubOrderedAlcoholPostingTxt: Label 'Ordered alcohol drinks', MaxLength = 100;
        XSubTaxPostingTxt: Label 'Tax', MaxLength = 100;
        XSubAirlineFarePostingTxt: Label 'Total airline fare', MaxLength = 100;
        XSubAirFeesPostingTxt: Label 'Other airline fees', MaxLength = 100;
        XSubAirUpgradePostingTxt: Label 'Class upgrades', MaxLength = 100;
        XSubCarFuelPostingTxt: Label 'Fuel for the car usage', MaxLength = 100;
        XSubCarMaintenancePostingTxt: Label 'Car maintenance or tools for car', MaxLength = 100;
        XSubEventsOtherPostingTxt: Label 'Other non business events', MaxLength = 100;
        XSubDrugsPostingTxt: Label 'Drugs or supplements', MaxLength = 100;
        XSubBandagesPostingTxt: Label 'Bandages, gauze...', MaxLength = 100;
        XSubOtherItemsPostingTxt: Label 'Other items', MaxLength = 100;
        XSubRentalBasePostingTxt: Label 'Base rental amount', MaxLength = 100;
        XSubRentalInsurancePostingTxt: Label 'Car insurance', MaxLength = 100;
        XSubRentalFuelPostingTxt: Label 'Billed fuel', MaxLength = 100;
        XSubRentalChargesPostingTxt: Label 'Charges and fines related to the service', MaxLength = 100;
        XSubRentalOtherPostingTxt: Label 'Other expenses related to service', MaxLength = 100;
        XSubPersonalSubsPostingTxt: Label 'Personal Subscriptions', MaxLength = 100;
        XSubCountryPerDiemPostingTxt: Label 'Local country per-diem', MaxLength = 100;
        XSubIntlPerDiemPostingTxt: Label 'International per-diem', MaxLength = 100;

        // Shared subcategory code labels
        XFOODTxt: Label 'FOOD', Locked = true;
        XSOFTDRINKTxt: Label 'SOFT DRINK', Locked = true;
        XALCOHOLTxt: Label 'ALCOHOL', Locked = true;
        XOTHERTxt: Label 'OTHER', Locked = true;
        XFUELTxt: Label 'FUEL', Locked = true;
        XFEETxt: Label 'FEE', Locked = true;
        XTRANSPORTTxt: Label 'TRANSPORT', Locked = true;
        XMAINTENANCETxt: Label 'MAINTENANCE', Locked = true;
        XAIRFEESTxt: Label 'AIR-FEES', Locked = true;
        XUPGRADETxt: Label 'UPGRADE', Locked = true;
        XDRUGSTxt: Label 'DRUGS', Locked = true;
        XBANDAGESTxt: Label 'BANDAGES', Locked = true;
        XCARUSAGESubTxt: Label 'CAR USAGE', Locked = true;
        XINSURANCETxt: Label 'INSURANCE', Locked = true;
        XCHARGESTxt: Label 'CHARGES', Locked = true;

        // HOTELS subcategory codes and descriptions
        XROOMTxt: Label 'ROOM', Locked = true;
        XHotelRoomDescTxt: Label 'Expenses for the daily hotel room rate during business travel. Includes nightly accommodation charges for standard or upgraded rooms. Excludes meals, taxes, and additional in-stay services billed separately.', MaxLength = 250;
        XBREAKFASTTxt: Label 'BREAKFAST', Locked = true;
        XHotelBreakfastDescTxt: Label 'Expenses for breakfast charged by the hotel during a business stay. Includes hotel-provided breakfast billed separately or as part of room service. Excludes external dining outside the hotel.', MaxLength = 250;
        XDEPOSITTxt: Label 'DEPOSIT', Locked = true;
        XHotelDepositDescTxt: Label 'Expenses for refundable or non-refundable hotel deposits required to secure a reservation or cover potential incidentals during a business stay.', MaxLength = 250;
        XTAXTxt: Label 'TAX', Locked = true;
        XHotelTaxDescTxt: Label 'Expenses for mandatory hotel-related taxes such as city tax, tourist tax, occupancy tax, or similar government-imposed accommodation levies.', MaxLength = 250;
        XHotelFeeDescTxt: Label 'Expenses for hotel-imposed fees other than room rate or tax, such as resort fees, service fees, facility fees, or mandatory surcharges.', MaxLength = 250;
        XPHONETxt: Label 'PHONE', Locked = true;
        XHotelPhoneDescTxt: Label 'Expenses for telephone calls or phone usage billed by the hotel during a business stay, including local or international calls placed from the room.', MaxLength = 250;
        XHotelInternetDescTxt: Label 'Expenses for hotel internet or Wi-Fi services charged during a business stay, including premium or high-speed access fees.', MaxLength = 250;
        XINCIDENTSTxt: Label 'INCIDENTS', Locked = true;
        XHotelIncidentsDescTxt: Label 'Expenses charged by the hotel for damages, penalties, or incident-related costs incurred during the stay, such as broken items or cleaning charges.', MaxLength = 250;
        XLAUNDRYTxt: Label 'LAUNDRY', Locked = true;
        XHotelLaundryDescTxt: Label 'Expenses for laundry, dry-cleaning, or pressing services provided by the hotel during a business trip.', MaxLength = 250;
        XROOMSERVICETxt: Label 'ROOM-SERVICE', Locked = true;
        XHotelRoomServiceDescTxt: Label 'Expenses for meals, minibar items, and beverages provided via hotel room service during a business stay.', MaxLength = 250;
        XHOTELPARKTxt: Label 'HOTEL-PARK', Locked = true;
        XHotelParkingDescTxt: Label 'Expenses for valet or self-parking services provided by the hotel during a business stay.', MaxLength = 250;
        XHOTELOTHERTxt: Label 'HOTELOTHER', Locked = true;
        XHotelOtherDescTxt: Label 'Hotel-related expenses incurred during a business stay that do not fall into defined hotel subcategories.', MaxLength = 250;
        XHotelTipsDescTxt: Label 'Expenses for tips paid to hotel staff such as bell services, housekeeping, or concierge during a business stay.', MaxLength = 250;
        XHotelTransportDescTxt: Label 'Expenses for transportation services arranged or provided by the hotel, such as hotel shuttles, transfers, or arranged rides.', MaxLength = 250;

        // ENTERTAIN subcategory descriptions
        XEntertainFoodDescTxt: Label 'Expenses for food ordered during external entertainment with customers or business partners at restaurants, cafes, or similar venues.', MaxLength = 250;
        XEntertainSoftDrinkDescTxt: Label 'Expenses for non-alcoholic beverages such as soft drinks or water ordered during external business entertainment.', MaxLength = 250;
        XEntertainAlcoholDescTxt: Label 'Expenses for alcoholic beverages ordered during external entertainment with customers or business partners.', MaxLength = 250;
        XEntertainTipsDescTxt: Label 'Expenses for tips or gratuities paid for service during external business entertainment.', MaxLength = 250;
        XEntertainTaxDescTxt: Label 'Expenses for applicable taxes charged on food, drinks, or services during external entertainment.', MaxLength = 250;

        // MORALE subcategory descriptions
        XMoraleFoodDescTxt: Label 'Expenses for food ordered as part of internal employee morale or team-building activities. Includes meals provided during team lunches, dinners, offsites, or internal social events.', MaxLength = 250;
        XMoraleSoftDrinkDescTxt: Label 'Expenses for non-alcoholic beverages such as water, soft drinks, juice, or coffee purchased for employee morale or internal team-building events.', MaxLength = 250;
        XMoraleAlcoholDescTxt: Label 'Expenses for alcoholic beverages purchased for internal employee morale or team-building events. Includes beer, wine, and spirits consumed during company events.', MaxLength = 250;
        XMoraleTipsDescTxt: Label 'Tips or gratuities paid in connection with food, beverage, or service expenses incurred during employee morale or internal team-building events.', MaxLength = 250;
        XMoraleTaxDescTxt: Label 'Sales tax, VAT or similar consumption tax charged on morale-related food, beverage, or service expenses for internal employee events.', MaxLength = 250;

        // MEALS subcategory descriptions
        XMealsFoodDescTxt: Label 'Expenses for food consumed by employees during working hours or business travel. Includes breakfasts, lunches, dinners, or catered meals provided for business purposes.', MaxLength = 250;
        XMealsSoftDrinkDescTxt: Label 'Expenses for non-alcoholic beverages consumed with employee meals during business activities or business travel.', MaxLength = 250;
        XMealsAlcoholDescTxt: Label 'Expenses for alcoholic drinks consumed in connection with employee meals during business travel or approved business meals.', MaxLength = 250;
        XMealsTipsDescTxt: Label 'Tips or gratuities paid in connection with employee meals during business travel or work-related dining.', MaxLength = 250;

        // AIRLINE subcategory descriptions
        XAirlineSubDescTxt: Label 'Base airfare for commercial air travel. Includes ticket price covering passenger, route, fare class, and mandatory airline charges, excluding optional fees or upgrades.', MaxLength = 250;
        XAirFeesDescTxt: Label 'Additional airline-related fees such as baggage fees, seat selection, booking changes, service fees, or other ancillary airline charges.', MaxLength = 250;
        XAirUpgradeDescTxt: Label 'Charges for airline class upgrades or preferred seating upgrades paid in addition to the original airfare.', MaxLength = 250;

        // CAR subcategory descriptions
        XCarFuelDescTxt: Label 'Expenses for fuel or charging related to company car usage. Includes gasoline, diesel, or electric charging costs incurred during business use.', MaxLength = 250;
        XCarMaintenanceDescTxt: Label 'Expenses for minor car maintenance or consumables outside garage services. Includes car washes, fluids, bulbs, or small tools related to vehicle upkeep.', MaxLength = 250;

        // COURIER subcategory description
        XCourierSubDescTxt: Label 'Expenses for courier, delivery, or shipping services used to send or receive documents, parcels, or goods for business purposes.', MaxLength = 250;

        // EVENTS subcategory descriptions
        XEventsSubDescTxt: Label 'Expenses related to attending or participating in business events such as conferences, trade fairs, summits, or exhibitions, including tickets and registration fees.', MaxLength = 250;
        XEventsOtherDescTxt: Label 'Expenses for non-business or personal events not related to professional activities. Includes leisure or personal events such as museum visits, amusement parks, circus shows, political or private events.', MaxLength = 250;

        // GARAGE-SERVICE subcategory description
        XGarageServiceSubDescTxt: Label 'Professional repair, servicing, or maintenance performed by a garage on company cars or trucks, including labor, diagnostics, parts, and inspections.', MaxLength = 250;

        // GIFTS subcategory description
        XGiftsSubDescTxt: Label 'Expenses for gift certificates or tangible gifts given to current or potential business partners for business relationship purposes.', MaxLength = 250;

        // GROUND-TRANS subcategory description
        XGroundTransSubDescTxt: Label 'Expenses for ground transportation during business travel, including taxis, ride-hailing services, public transport, trains, ferries, or similar services.', MaxLength = 250;

        // INTERNET subcategory description
        XInternetSubDescTxt: Label 'Expenses for internet or data access incurred during business travel, such as roaming data charges, or temporary internet services.', MaxLength = 250;

        // MISC subcategory description
        XMiscSubDescTxt: Label 'Business-related expenses that do not clearly fit any other defined category and require individual review for policy compliance.', MaxLength = 250;

        // PARKING subcategory description
        XParkingSubDescTxt: Label 'Expenses for parking incurred during business travel or work activities, including street parking, garages, airport parking, or parking meters.', MaxLength = 250;

        // PASSPORT subcategory description
        XPassportSubDescTxt: Label 'Fees for obtaining or renewing passports, visas, or other travel documents required for business travel.', MaxLength = 250;

        // PERSONAL subcategory description
        XPersonalSubDescTxt: Label 'Expenses of a personal or non-business nature that are not eligible for reimbursement under company policy.', MaxLength = 250;

        // PHARMACY subcategory descriptions
        XPharmacyDrugsDescTxt: Label 'Expenses for medicines, drugs, or supplements purchased during business travel or for work-related health needs.', MaxLength = 250;
        XPharmacyBandagesDescTxt: Label 'Expenses for first-aid or medical supplies such as bandages, gauze, plasters, or similar healthcare consumables.', MaxLength = 250;
        XPharmacyOtherDescTxt: Label 'Other pharmacy-related purchases not classified as drugs or bandages, including health or medical items related to travel or work.', MaxLength = 250;

        // RENTALCARS subcategory descriptions
        XRentalCarUsageDescTxt: Label 'Base rental charges for renting a car for business travel, excluding insurance, fuel, fines, or additional services.', MaxLength = 250;
        XRentalInsuranceDescTxt: Label 'Charges for insurance coverage related to rental cars, including damage, theft, or liability insurance options.', MaxLength = 250;
        XRentalFuelDescTxt: Label 'Fuel charges billed by the rental car provider or paid for refueling a rental car used for business travel.', MaxLength = 250;
        XRentalChargesDescTxt: Label 'Additional rental-related charges such as fines, penalties, cleaning fees, late return fees, or administrative charges.', MaxLength = 250;
        XRentalOtherDescTxt: Label 'Other expenses related to rental car services not covered by base rental, insurance, fuel, or charges.', MaxLength = 250;

        // SUBSCRIPTIONS subcategory descriptions
        XSubscriptionsSubDescTxt: Label 'Expenses for professional or business-related subscriptions, including software services, digital tools, memberships, or online publications.', MaxLength = 250;
        XSubscriptionsPersonalDescTxt: Label 'Expenses for personal subscriptions not related to business use. Includes streaming services, personal magazines, entertainment platforms, or non-business memberships and services.', MaxLength = 250;

        // TOLLS subcategory description
        XTollsSubDescTxt: Label 'Fees charged for using toll roads, bridges, tunnels, congestion zones, or paid road infrastructure during business travel.', MaxLength = 250;

        // TIPS subcategory description
        XTipsSubDescTxt: Label 'Tips or gratuities paid to service providers in connection with business activities or travel.', MaxLength = 250;

        // PER-DIEM subcategory descriptions
        XCOUNTRYTxt: Label 'COUNTRY', Locked = true;
        XCountryPerDiemDescTxt: Label 'Daily per-diem allowance based on domestic travel rates, paid instead of individual meal or incidental expense reimbursements.', MaxLength = 250;
        XINTERNATIONALTxt: Label 'INTERNATIONAL', Locked = true;
        XIntlPerDiemDescTxt: Label 'Daily per-diem allowance for international business travel, based on applicable foreign travel rates.', MaxLength = 250;

        // FINES subcategory description
        XFinesSubDescTxt: Label 'Expenses for fines, penalties, or sanctions imposed by authorities due to violations or non-compliance during business activities.', MaxLength = 250;

        XEXPENSETRAVELTxt: Label 'EXPENSE-TRAVEL', Locked = true;
        XEXPENSEPERDIEMTxt: Label 'EXPENSE-PERDIEM', Locked = true;
        XEXPENSEOTHERTxt: Label 'EXPENSE-OTHER', Locked = true;
        XEXPENSEMILEAGETxt: Label 'EXPENSE MILEAGE', Locked = true;
        XEXPENSEMEALSTxt: Label 'EXPENSE MEALS', Locked = true;
        XEXPENSEENTERTAINTxt: Label 'EXPENSE ENTERT', Locked = true;
        XExpenseTravelDescTxt: Label 'Expense - Travel';
        XExpensePerDiemDescTxt: Label 'Expense - Per Diem';
        XExpenseOtherDescTxt: Label 'Expense - Other';
        XExpenseMileageDescTxt: Label 'Expense - Mileage';
        XExpenseMealsDescTxt: Label 'Expense - Meals';
        XExpenseEntertainDescTxt: Label 'Expense - Entertain';
        XTRAVELTxt: Label 'TRAVEL', Locked = true;
        XDAYEXPENSETxt: Label 'DAY-EXPENSE', Locked = true;
        XFOODBEVERAGETxt: Label 'FOOD-BEVERAGE', Locked = true;
        XCASHTxt: Label 'CASH', Locked = true;
        XCARDTxt: Label 'CARD', Locked = true;
        XCANADAALLTxt: Label 'CANADA-ALL', Locked = true;
        XDENMARKALLTxt: Label 'DENMARK-ALL', Locked = true;
        XDOMESTICTxt: Label 'DOMESTIC', Locked = true;
        XFRANCEALLTxt: Label 'FRANCE-ALL', Locked = true;
        XGERMANYALLTxt: Label 'GERMANY-ALL', Locked = true;
        XUKOTHERTxt: Label 'UK-OTHER', Locked = true;
        XUSAOTHERTxt: Label 'USA-OTHER', Locked = true;
        XEMPLEXPTxt: Label 'EMPLEXP', MaxLength = 20;
        XEXPENSEPERDIEMITxt: Label 'EXPENSE-PERDIEM-I', Locked = true;
        XEXPENSEPERDIEMATxt: Label 'EXPENSE-PERDIEM-A', Locked = true;
        XPERDIEMITxt: Label 'PER-DIEM-I', Locked = true;
        XPERDIEMATxt: Label 'PER-DIEM-A', Locked = true;
        XINTLTxt: Label 'INTL', Locked = true;
        XExpensePerDiemInCountryDescTxt: Label 'Expense - Per Diem in country', MaxLength = 100;
        XExpensePerDiemAbroadDescTxt: Label 'Expense - Per Diem abroad', MaxLength = 100;
        XPerDiemIByAssignedPolicyPostingTxt: Label 'Per-diem (international) by assigned policy', MaxLength = 100;
        XPerDiemAByAssignedPolicyPostingTxt: Label 'Per-diem (local) by assigned policy', MaxLength = 100;

    internal procedure InsertExpenseCategory(Code: Code[20]; Description: Text[250]; PostingDescription: Text[100]; ExpenseGroupCode: Code[20]; PostingGroupCode: Code[20]; PaymentMethod: Code[10]; IsRefundable: Boolean; IsPrepayment: Boolean; AttachmentEnforcement: Enum "Expense Attachment Enforcement"; DetailRequired: Enum "Expense Detail Needed")
    begin
        if ExpenseCategory.Get(Code) then
            exit;

        ExpenseCategory.Init();
        ExpenseCategory.Validate(Code, Code);
        ExpenseCategory.Validate(Description, Description);
        ExpenseCategory.Validate("Posting Description", PostingDescription);
        ExpenseCategory.Validate("Expense Group", ExpenseGroupCode);
        ExpenseCategory.Validate("Posting Group", PostingGroupCode);
        ExpenseCategory.Validate("Default Payment Method", PaymentMethod);
        ExpenseCategory.Validate(Refundable, IsRefundable);
        ExpenseCategory.Validate("Prepayment-Cash Advance", IsPrepayment);
        ExpenseCategory.Validate("Attachment Enforcement", AttachmentEnforcement);
        ExpenseCategory.Validate("Expense Detail Required", DetailRequired);
        ExpenseCategory.Insert(true);
    end;

    internal procedure InsertExpenseSubcategory(SubcategoryCode: Code[20]; CategoryCode: Code[20]; Description: Text[250]; PostingDescription: Text[100]; Refundable: Boolean; DescriptionMandatory: Boolean)
    begin
        if ExpenseSubcategory.Get(CategoryCode, SubcategoryCode) then
            exit;

        ExpenseSubcategory.Init();
        ExpenseSubcategory.Code := SubcategoryCode;
        ExpenseSubcategory."Expense Category Code" := CategoryCode;
        ExpenseSubcategory.Description := Description;
        ExpenseSubcategory."Posting Description" := PostingDescription;
        ExpenseSubcategory."Expense Description Mandatory" := DescriptionMandatory;
        ExpenseSubcategory.Refundable := Refundable;
        ExpenseSubcategory.Insert(true);
    end;

    internal procedure UpdateEmployeePostingGroup(Code: Code[20]; ExpenseReportPayableAccount: Code[20]; ExpensePayableBankPaidAccount: Code[20]; ExpensePayableCardPaidAccount: Code[20]; ExpenseReportPrepaymentAccount: Code[20])
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateEmployeePostingGroup(Code, ExpenseReportPayableAccount, ExpensePayableBankPaidAccount, ExpensePayableCardPaidAccount, ExpenseReportPrepaymentAccount, IsHandled);
        if IsHandled then
            exit;

        if not EmployeePostingGroup.Get(Code) then
            exit;

        EmployeePostingGroup.Validate("Expense Report Payable Account", ExpenseReportPayableAccount);
        EmployeePostingGroup.Validate("Expense Payable Bank Paid Acc.", ExpensePayableBankPaidAccount);
        EmployeePostingGroup.Validate("Expense Payable Card Paid Acc.", ExpensePayableCardPaidAccount);
        EmployeePostingGroup.Validate("Exp. Report Prepayment Account", ExpenseReportPrepaymentAccount);
        EmployeePostingGroup.Modify(true);
    end;

    local procedure InsertExpenseGroup(Code: Code[20]; Description: Text[50])
    begin
        if ExpenseGroup.Get(Code) then
            exit;

        ExpenseGroup.Init();
        ExpenseGroup.Validate(Code, Code);
        ExpenseGroup.Validate("Description", Description);
        ExpenseGroup.Insert(true);
    end;

    local procedure InsertExpensePostingGroup(Code: Code[20]; Description: Text[100]; RefundableDebitAccount: Code[20]; NonRefundableDebitAccount: Code[20]; PrepaymentCreditAccount: Code[20]; ExpenseDebitRoundingAccount: Code[20]; ExpenseCreditRoundingAccount: Code[20])
    begin
        if ExpensePostingGroup.Get(Code) then
            exit;

        ExpensePostingGroup.Init();
        ExpensePostingGroup.Validate(Code, Code);
        ExpensePostingGroup.Validate("Description", Description);
        ExpensePostingGroup.Validate("Refundable Debit Account", RefundableDebitAccount);
        ExpensePostingGroup.Validate("Non-Refundable Debit Account", NonRefundableDebitAccount);
        ExpensePostingGroup.Validate("Prepayment Credit Account", PrepaymentCreditAccount);
        ExpensePostingGroup.Validate("Debit Rounding Account", ExpenseDebitRoundingAccount);
        ExpensePostingGroup.Validate("Credit Rounding Account", ExpenseCreditRoundingAccount);
        ExpensePostingGroup.Insert(true);
    end;

    local procedure InsertExpenseLocation(Code: Code[20]; CountryRegionCode: Code[10]; Description: Text[100])
    begin
        if ExpenseLocation.Get(Code) then
            exit;

        ExpenseLocation.Init();
        ExpenseLocation.Validate("No.", Code);
        ExpenseLocation.Validate("Country/Region Code", CountryRegionCode);
        ExpenseLocation.Validate("Description", Description);
        ExpenseLocation.Insert(true);
    end;

    local procedure InsertExpenseRule(CategoryCode: Code[20]; ExpenseLocationCode: Code[20]; CurrencyCode: Code[10]; JustificationRequired: Enum "Expense Justification")
    begin
        if ExpenseRuleHeader.Get(CategoryCode, ExpenseLocationCode, 0D) then
            exit;

        ExpenseRuleHeader.Init();
        ExpenseRuleHeader.Validate("Expense Category Code", CategoryCode);
        ExpenseRuleHeader.Validate("Expense Location", ExpenseLocationCode);
        if Currency.Get(CurrencyCode) then
            ExpenseRuleHeader.Validate("Currency Code", CurrencyCode);
        ExpenseRuleHeader.Validate("Justification Required", JustificationRequired);
        ExpenseRuleHeader.Insert(true);
    end;

    local procedure InsertExpenseRuleCondition(CategoryCode: Code[20]; ExpenseLocationCode: Code[20]; ConditionType: Enum "Expense Rule Condition Type"; Value: Decimal)
    var
        NextLineNo: Integer;
    begin
        ExpenseRuleCondition.SetRange("Expense Category Code", CategoryCode);
        ExpenseRuleCondition.SetRange("Expense Location", ExpenseLocationCode);
        ExpenseRuleCondition.SetRange("Condition Type", ConditionType);
        if ExpenseRuleCondition.FindFirst() then
            exit;

        ExpenseRuleCondition.Reset();
        if ExpenseRuleCondition.FindLast() then
            NextLineNo := ExpenseRuleCondition."Line No." + 1
        else
            NextLineNo := 1;

        ExpenseRuleCondition.Init();
        ExpenseRuleCondition.Validate("Expense Category Code", CategoryCode);
        ExpenseRuleCondition.Validate("Expense Location", ExpenseLocationCode);
        ExpenseRuleCondition.Validate("Condition Type", ConditionType);
        ExpenseRuleCondition.Validate("Line No.", NextLineNo);
        ExpenseRuleCondition.Validate("Value", Value);
        ExpenseRuleCondition.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildPostingGroupSeeds(var TempPostingGroup: Record "Expense Posting Group" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildCategorySeeds(var TempCategory: Record "Expense Category" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildSubcategorySeeds(var TempSubcategory: Record "Expense Subcategory" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildRuleSeeds(var TempRuleHeader: Record "Expense Rule Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildRuleConditionSeeds(var TempRuleCondition: Record "Expense Rule Condition" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPostingGroupSeed(var TempPostingGroup: Record "Expense Posting Group" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddPostingGroupSeed(Code: Code[20]; Description: Text[100]; RefundableDebitAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateEmployeePostingGroup(Code: Code[20]; ExpenseReportPayableAccount: Code[20]; ExpensePayableBankPaidAccount: Code[20]; ExpensePayableCardPaidAccount: Code[20]; ExpenseReportPrepaymentAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRuleSeed(var TempRuleHeader: Record "Expense Rule Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddCategorySeed(Code: Code[20]; Description: Text[250]; PostingDescription: Text[100]; ExpenseGroupCode: Code[20]; PostingGroupCode: Code[20]; PaymentMethod: Code[10]; IsRefundable: Boolean; IsPrepayment: Boolean; AttachmentEnforcement: Enum "Expense Attachment Enforcement"; DetailRequired: Enum "Expense Detail Needed"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSubcategorySeed(SubcategoryCode: Code[20]; CategoryCode: Code[20]; Description: Text[250]; PostingDescription: Text[100]; Refundable: Boolean; DescriptionMandatory: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddRuleSeed(var TempRuleHeader: Record "Expense Rule Header" temporary; CategoryCode: Code[20]; ExpenseLocationCode: Code[20]; CurrencyCode: Code[10]; JustificationRequired: Enum "Expense Justification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddRuleConditionSeed(var TempRuleCondition: Record "Expense Rule Condition" temporary; CategoryCode: Code[20]; ExpenseLocationCode: Code[20]; ConditionType: Enum "Expense Rule Condition Type"; Value: Decimal; var IsHandled: Boolean)
    begin
    end;
}