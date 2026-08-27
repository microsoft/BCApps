// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// MCC code mapping and validation for corporate card transactions.
/// Maps Merchant Category Codes to Expense Categories.
/// </summary>
codeunit 7217 "EA Corp Card MCC Mgt"
{
    Access = Internal;

    /// <summary>
    /// Validates MCC code format and returns mapped expense category.
    /// </summary>
    internal procedure ValidateAndMapMCC(MCC: Code[4]; var ExpenseCategory: Code[20]): Boolean
    var
        MCCMap: Record "EA Corp Card MCC Map";
    begin
        if MCC = '' then
            exit(false);

        if not IsValidMCC(MCC) then
            exit(false);

        if not MCCMap.Get(MCC) then
            exit(false);

        ExpenseCategory := MCCMap."Expense Category";
        exit(MCCMap.Active);
    end;

    /// <summary>
    /// Populates MCC mapping cache with default industry categories.
    /// Can be called during setup or upgrade.
    /// </summary>
    internal procedure InitializeDefaultMCCMappings()
    begin
        EnsureMCCMapping('4112', 'Rail Passenger Transport', 'GROUNDTRAN', 'Ground Transportation');
        EnsureMCCMapping('4121', 'Taxicabs and Limousines', 'GROUNDTRAN', 'Ground Transportation');
        EnsureMCCMapping('4511', 'Airlines', 'AIRLINE', 'Airline');
        EnsureMCCMapping('4722', 'Travel Agencies', 'TRAVELAGENCY', 'Travel Agency');
        EnsureMCCMapping('5111', 'Office Supplies', 'OFFICESUPPLIES', 'Office Supplies');
        EnsureMCCMapping('5541', 'Service Stations', 'CAR', 'Car');
        EnsureMCCMapping('5812', 'Restaurants', 'MEALS', 'Meals');
        EnsureMCCMapping('5943', 'Stationery and Office Stores', 'OFFICESUPPLIES', 'Office Supplies');
        EnsureMCCMapping('7011', 'Hotels and Lodging', 'HOTELS', 'Hotels');
        EnsureMCCMapping('7523', 'Parking Lots and Garages', 'PARKING', 'Parking');

        // Keep legacy defaults that may already be used in existing test/demo setups.
        EnsureMCCMapping('7394', 'Car Rental', 'RENTALCARS', 'Rental Cars');
        EnsureMCCMapping('7399', 'Business Services', 'MISC', 'Miscellaneous');
        EnsureMCCMapping('5542', 'Fuel Dispensers', 'CAR', 'Car');
    end;

    local procedure EnsureMCCMapping(MCC: Code[4]; Description: Text[100]; CategoryCode: Code[20]; CategoryDescription: Text[100])
    var
        MCCMap: Record "EA Corp Card MCC Map";
    begin
        EnsureCategoryExists(CategoryCode, CategoryDescription);

        if MCCMap.Get(MCC) then
            exit;

        MCCMap.Init();
        MCCMap.MCC := MCC;
        MCCMap.Description := Description;
        MCCMap."Expense Category" := CategoryCode;
        MCCMap.Active := true;
        MCCMap.Insert();
    end;

    /// <summary>
    /// Returns mapped expense category for MCC, or empty if not found.
    /// </summary>
    internal procedure GetExpenseCategoryForMCC(MCC: Code[4]): Code[20]
    var
        MCCMap: Record "EA Corp Card MCC Map";
    begin
        if MCCMap.Get(MCC) then
            exit(MCCMap."Expense Category");
        exit('');
    end;

    /// <summary>
    /// Validates MCC format: must be 4 digits.
    /// </summary>
    local procedure IsValidMCC(MCC: Code[4]): Boolean
    var
        i: Integer;
        CharCode: Integer;
    begin
        if StrLen(MCC) <> 4 then
            exit(false);

        for i := 1 to 4 do begin
            CharCode := MCC[i];
            if (CharCode < 48) or (CharCode > 57) then  // ASCII codes for '0'-'9'
                exit(false);
        end;

        exit(true);
    end;

    local procedure EnsureCategoryExists(CategoryCode: Code[20]; CategoryDescription: Text[100])
    var
        ExpenseCategory: Record "Expense Category";
    begin
        if ExpenseCategory.Get(CategoryCode) then begin
            if (ExpenseCategory.Description = '') and (CategoryDescription <> '') then begin
                ExpenseCategory.Validate(Description, CategoryDescription);
                ExpenseCategory.Modify(true);
            end;
            exit;
        end;

        ExpenseCategory.Init();
        ExpenseCategory.Validate(Code, CategoryCode);
        ExpenseCategory.Validate(Description, CategoryDescription);
        ExpenseCategory.Insert(true);
    end;
}
