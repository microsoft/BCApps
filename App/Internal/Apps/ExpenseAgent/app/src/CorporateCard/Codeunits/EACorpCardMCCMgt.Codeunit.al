// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// MCC code mapping and validation for corporate card transactions.
/// Maps Merchant Category Codes to Expense Categories.
/// </summary>
codeunit 7217 EACorpCardMCCMgt
{
    Access = Internal;

    var
        MCCMapNotFoundMsg: Label 'No expense category mapping found for MCC %1.', Locked = true;
        InvalidMCCMsg: Label 'Invalid MCC code: %1. MCC must be 4 digits.', Locked = true;

    /// <summary>
    /// Validates MCC code format and returns mapped expense category.
    /// </summary>
    internal procedure ValidateAndMapMCC(MCC: Code[4]; var ExpenseCategory: Code[20]): Boolean
    var
        MCCMap: Record EACorpCardMCCMap;
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
    var
        MCCMap: Record EACorpCardMCCMap;
    begin
        // Airlines
        if not MCCMap.Get('4511') then begin
            MCCMap.MCC := '4511';
            MCCMap.Description := 'Airlines';
            MCCMap."Expense Category" := GetOrCreateCategory('Travel');
            MCCMap.Active := true;
            MCCMap.Insert();
        end;

        // Hotel/Lodging
        if not MCCMap.Get('7011') then begin
            MCCMap.MCC := '7011';
            MCCMap.Description := 'Hotels/Lodging';
            MCCMap."Expense Category" := GetOrCreateCategory('Travel');
            MCCMap.Active := true;
            MCCMap.Insert();
        end;

        // Restaurants
        if not MCCMap.Get('5812') then begin
            MCCMap.MCC := '5812';
            MCCMap.Description := 'Restaurants';
            MCCMap."Expense Category" := GetOrCreateCategory('Meals');
            MCCMap.Active := true;
            MCCMap.Insert();
        end;

        // Rental Car
        if not MCCMap.Get('7394') then begin
            MCCMap.MCC := '7394';
            MCCMap.Description := 'Car Rental';
            MCCMap."Expense Category" := GetOrCreateCategory('Travel');
            MCCMap.Active := true;
            MCCMap.Insert();
        end;

        // Office/Business Services
        if not MCCMap.Get('7399') then begin
            MCCMap.MCC := '7399';
            MCCMap.Description := 'Business Services';
            MCCMap."Expense Category" := GetOrCreateCategory('Office Supplies');
            MCCMap.Active := true;
            MCCMap.Insert();
        end;

        // Gas
        if not MCCMap.Get('5542') then begin
            MCCMap.MCC := '5542';
            MCCMap.Description := 'Fuel';
            MCCMap."Expense Category" := GetOrCreateCategory('Transportation');
            MCCMap.Active := true;
            MCCMap.Insert();
        end;
    end;

    /// <summary>
    /// Returns mapped expense category for MCC, or empty if not found.
    /// </summary>
    internal procedure GetExpenseCategoryForMCC(MCC: Code[4]): Code[20]
    var
        MCCMap: Record EACorpCardMCCMap;
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

    local procedure GetOrCreateCategory(CategoryName: Text[100]): Code[20]
    var
        ExpenseCategory: Record "Expense Category";
    begin
        // Try to find existing category
        ExpenseCategory.SetFilter(Description, StrSubstNo('@*%1*', CategoryName));
        if ExpenseCategory.FindFirst() then
            exit(ExpenseCategory.Code);

        // Return first matching or empty if not found
        exit('');
    end;
}
