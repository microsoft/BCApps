// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;

/// <summary>
/// Stores VAT product posting group templates and configurations used during VAT assisted setup process.
/// Provides predefined VAT rates, account assignments, and classification options for standardized VAT configuration.
/// </summary>
/// <remarks>
/// Used by VAT Setup Wizard to create standardized VAT posting group combinations with appropriate account assignments.
/// Supports both item and service classifications with default templates for common VAT scenarios.
/// Extensible through events for custom initialization and validation logic.
/// </remarks>
table 1877 "VAT Setup Posting Groups"
{
    Caption = 'VAT Setup Posting Groups';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// VAT product posting group code for categorizing taxable products and services.
        /// </summary>
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            NotBlank = true;
        }
        /// <summary>
        /// VAT percentage rate applied to transactions using this posting group configuration.
        /// </summary>
        field(4; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            ToolTip = 'Specifies the VAT percentage used.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// G/L account for posting sales VAT amounts for this product posting group.
        /// </summary>
        field(7; "Sales VAT Account"; Code[20])
        {
            Caption = 'Sales VAT Account';
            ToolTip = 'Specifies the general ledger account number to which to post sales VAT, for the particular combination of VAT business posting group and VAT product posting group.';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for posting purchase VAT amounts for this product posting group.
        /// </summary>
        field(9; "Purchase VAT Account"; Code[20])
        {
            Caption = 'Purchase VAT Account';
            ToolTip = 'Specifies the general ledger account number to which to post purchase VAT.';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for posting reverse charge VAT amounts for this product posting group.
        /// </summary>
        field(11; "Reverse Chrg. VAT Acc."; Code[20])
        {
            Caption = 'Reverse Chrg. VAT Acc.';
            ToolTip = 'Specifies the general ledger account number to which you want to post reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// Description text for the VAT product posting group displayed in setup interfaces.
        /// </summary>
        field(18; "VAT Prod. Posting Grp Desc."; Text[100])
        {
            Caption = 'VAT Prod. Posting Grp Desc.';
            ToolTip = 'Specifies a description of the VAT product posting group.';
        }
        /// <summary>
        /// VAT clause description text providing additional information about VAT treatment.
        /// </summary>
        field(19; "VAT Clause Desc"; Text[250])
        {
            Caption = 'VAT Clause Desc';
            ToolTip = 'Specifies a description of the VAT clause.';
        }
        /// <summary>
        /// Indicates whether this posting group template is selected for use during VAT setup.
        /// </summary>
        field(22; Selected; Boolean)
        {
            Caption = 'Selected';
            ToolTip = 'Specifies whether to include the VAT product posting group on the line.';
            FieldClass = Normal;
        }
        /// <summary>
        /// Specifies whether this template applies to items, services, or both types of transactions.
        /// </summary>
        field(23; "Application Type"; Option)
        {
            Caption = 'Application Type';
            ToolTip = 'Specifies how a cost recipient is linked to its cost source to provide cost forwarding according to the costing method.';
            OptionCaption = ',Items,Services';
            OptionMembers = ,Items,Services;
        }
        /// <summary>
        /// Indicates whether this is a default template provided by the system for standard VAT scenarios.
        /// </summary>
        field(24; Default; Boolean)
        {
            Caption = 'Default';
        }
    }

    keys
    {
        key(Key1; "VAT Prod. Posting Group", Default)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        FULLNORMTok: Label 'FULL NORM', Comment = 'the same as values in Product posting group';
        FULLREDTok: Label 'FULL RED', Comment = 'the same as values in Product posting group';
        REDUCEDTok: Label 'REDUCED', Comment = 'the same as values in Product posting group';
        SERVNORMTok: Label 'SERV NORM', Comment = 'the same as values in Product posting group';
        SERVREDTok: Label 'SERV RED', Comment = 'the same as values in Product posting group';
        STANDARDTok: Label 'STANDARD', Comment = 'the same as values in Product posting group';
        ZEROTok: Label 'ZERO', Comment = 'the same as values in Product posting group';
        FULLNORMTxt: Label 'VAT Only Invoices 25%';
        FULLREDTxt: Label 'VAT Only Invoices 10%';
        REDUCEDTxt: Label 'Reduced VAT (10%)';
        SERVNORMTxt: Label 'Miscellaneous 25 VAT';
        SERVREDTxt: Label 'Miscellaneous 10 VAT';
        STANDARDTxt: Label 'Standard VAT (25%)';
        ZEROTxt: Label 'No VAT';
        InvalidGLAccountsTxt: Label '%1 is not valid G/L Account.', Comment = '%1 is placeholder for the invalid gl account code';
        VATAssistedAccountsMsg: Label 'You have not assigned general ledger accounts for sales and purchases for all VAT amounts. You won''t be able to calculate and post VAT for the missing accounts. If you''re skipping this step on purpose, you can manually assign accounts later in the VAT Posting Setup page.';

    /// <summary>
    /// Validates that at least one non-default VAT setup posting group is selected for configuration.
    /// Used by VAT setup process to ensure user has made meaningful selections.
    /// </summary>
    /// <returns>True if selected non-default groups exist, false otherwise</returns>
    procedure ValidateVATRates(): Boolean
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        VATSetupPostingGroups.Reset();
        VATSetupPostingGroups.SetRange(Selected, true);
        VATSetupPostingGroups.SetRange(Default, false);
        exit(not VATSetupPostingGroups.IsEmpty);
    end;

    /// <summary>
    /// Populates working VAT product posting group records from default templates for setup configuration.
    /// Creates non-default copies of default templates for user modification during VAT setup process.
    /// </summary>
    procedure PopulateVATProdGroups()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        Handled: Boolean;
    begin
        SetRange(Default, false);
        DeleteAll();

        SetRange(Default, true);
        if not FindSet() then begin
            OnInitWithStandardValues(Handled, Rec);

            if not Handled then
                InitWithStandardValues();

            FindSet();
        end;

        repeat
            VATSetupPostingGroups.TransferFields(Rec);
            VATSetupPostingGroups.Default := false;
            VATSetupPostingGroups.Insert();
        until Next() = 0;
    end;

    /// <summary>
    /// Adds or updates a VAT product posting group template with specified configuration parameters.
    /// Creates new template or modifies existing one with VAT rate, account assignments, and classification.
    /// </summary>
    /// <param name="ProdGrpCode">VAT product posting group code</param>
    /// <param name="GrpDesc">Description for the posting group</param>
    /// <param name="VatRate">VAT percentage rate to apply</param>
    /// <param name="SalesAccount">G/L account for sales VAT posting</param>
    /// <param name="PurchAccount">G/L account for purchase VAT posting</param>
    /// <param name="IsService">Whether template applies to services instead of items</param>
    /// <param name="IsDefault">Whether this is a system default template</param>
    /// <returns>True if template was successfully modified, false otherwise</returns>
    procedure AddOrUpdateProdPostingGrp(ProdGrpCode: Code[20]; GrpDesc: Text[100]; VatRate: Decimal; SalesAccount: Code[20]; PurchAccount: Code[20]; IsService: Boolean; IsDefault: Boolean): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if not Get(ProdGrpCode, IsDefault) then begin
            Init();
            "VAT Prod. Posting Group" := ProdGrpCode;
            Default := IsDefault;
            Insert();
        end;

        "VAT Prod. Posting Grp Desc." := GrpDesc;
        if VatRate <> 0 then
            "VAT %" := VatRate;
        if GLAccount.Get(SalesAccount) then
            "Sales VAT Account" := SalesAccount;
        if GLAccount.Get(PurchAccount) then
            "Purchase VAT Account" := PurchAccount;
        "Application Type" := "Application Type"::Items;
        if IsService then
            "Application Type" := "Application Type"::Services;
        Selected := true;
        exit(Modify());
    end;

    /// <summary>
    /// Checks whether existing items or services are already configured with the specified VAT product posting group.
    /// Validates impact of VAT configuration changes on existing master data.
    /// </summary>
    /// <param name="VATProdPostingGroupCode">VAT product posting group code to check</param>
    /// <param name="IsService">Whether to check services instead of items</param>
    /// <returns>True if existing items/services use this posting group, false otherwise</returns>
    procedure CheckExistingItemAndServiceWithVAT(VATProdPostingGroupCode: Code[20]; IsService: Boolean): Boolean
    var
        Item: Record Item;
        Result: Boolean;
    begin
        if IsService then begin
            OnBeforeCheckExistingItemAndServiceWithVAT(VATProdPostingGroupCode, Result);
            exit(Result);
        end;
        Item.SetRange("VAT Prod. Posting Group", VATProdPostingGroupCode);
        exit(not Item.IsEmpty);
    end;

    /// <summary>
    /// Validates that all selected VAT posting group templates have valid G/L account assignments.
    /// Ensures VAT setup completion by checking required account configurations for posting.
    /// </summary>
    /// <param name="ErrorMessage">Returns detailed error message if validation fails</param>
    /// <returns>True if all accounts are valid and assigned, false if validation errors exist</returns>
    procedure ValidateGLAccountsExist(var ErrorMessage: Text): Boolean
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        GLAccount: Record "G/L Account";
    begin
        if ValidateVATRates() = false then
            exit(false);
        VATSetupPostingGroups.SetRange(Selected, true);
        if not VATSetupPostingGroups.FindSet() then
            exit;

        repeat
            if
               (DelChr(VATSetupPostingGroups."Sales VAT Account", '<>') = '') or
               (DelChr(VATSetupPostingGroups."Purchase VAT Account", '<>') = '')
            then begin
                ErrorMessage := VATAssistedAccountsMsg;
                exit(false);
            end;

            if not GLAccount.Get(VATSetupPostingGroups."Sales VAT Account") then begin
                ErrorMessage := StrSubstNo(InvalidGLAccountsTxt, VATSetupPostingGroups."Sales VAT Account");
                exit(false);
            end;
            if not GLAccount.Get(VATSetupPostingGroups."Purchase VAT Account") then begin
                ErrorMessage := StrSubstNo(InvalidGLAccountsTxt, VATSetupPostingGroups."Purchase VAT Account");
                exit(false);
            end;
        until VATSetupPostingGroups.Next() = 0;
        ErrorMessage := '';
        exit(true);
    end;

    /// <summary>
    /// Retrieves predefined label token codes used for standard VAT product posting group setup.
    /// Provides consistent codes for creating standardized VAT configurations across implementations.
    /// </summary>
    /// <param name="LabelName">Name of the label token to retrieve</param>
    /// <returns>Code value for the specified label token</returns>
    procedure GetLabelTok(LabelName: Text): Code[20]
    begin
        case LabelName of
            'FULLNORMTok':
                exit(FULLNORMTok);
            'FULLREDTok':
                exit(FULLREDTok);
            'SERVNORMTok':
                exit(SERVNORMTok);
            'STANDARDTok':
                exit(STANDARDTok);
            'ZEROTok':
                exit(ZEROTok);
            else
                Error('Labels not found in VATSetupPostingGroups');
        end
    end;

    /// <summary>
    /// Retrieves predefined label text descriptions used for standard VAT product posting group setup.
    /// Provides consistent descriptions for creating standardized VAT configurations across implementations.
    /// </summary>
    /// <param name="LabelName">Name of the label text to retrieve</param>
    /// <returns>Description text for the specified label</returns>
    procedure GetLabelTxt(LabelName: Text): Text[100]
    begin
        case LabelName of
            'FULLNORMTxt':
                exit(FULLNORMTxt);
            'FULLREDTxt':
                exit(FULLREDTxt);
            'SERVNORMTxt':
                exit(SERVNORMTxt);
            'STANDARDTxt':
                exit(STANDARDTxt);
            'ZEROTxt':
                exit(ZEROTxt);
            else
                Error('Labels not found in VATSetupPostingGroups');
        end
    end;

    local procedure InitWithStandardValues()
    begin
        AddOrUpdateProdPostingGrp(FULLNORMTok, FULLNORMTxt, 100, '', '', false, true);
        AddOrUpdateProdPostingGrp(FULLREDTok, FULLREDTxt, 100, '', '', false, true);
        AddOrUpdateProdPostingGrp(REDUCEDTok, REDUCEDTxt, 10, '5611', '5631', false, true);
        AddOrUpdateProdPostingGrp(SERVNORMTok, SERVNORMTxt, 25, '5611', '5631', true, true);
        AddOrUpdateProdPostingGrp(SERVREDTok, SERVREDTxt, 10, '5611', '5631', true, true);
        AddOrUpdateProdPostingGrp(STANDARDTok, STANDARDTxt, 25, '5610', '5630', false, true);
        AddOrUpdateProdPostingGrp(ZEROTok, ZEROTxt, 0, '5610', '5630', false, true);
    end;

    /// <summary>
    /// Integration event raised before initializing VAT setup posting groups with standard values.
    /// Enables extensions to provide custom default VAT configurations instead of system defaults.
    /// </summary>
    /// <param name="Handled">Set to true to skip standard initialization logic</param>
    /// <param name="VATSetupPostingGroups">VAT setup posting groups record for custom initialization</param>
    [IntegrationEvent(false, false)]
    local procedure OnInitWithStandardValues(var Handled: Boolean; VATSetupPostingGroups: Record "VAT Setup Posting Groups")
    begin
    end;

    /// <summary>
    /// Integration event raised before checking existing items and services with VAT product posting group.
    /// Enables extensions to provide custom validation logic for VAT group usage verification.
    /// </summary>
    /// <param name="VATProdPostingGroupCode">VAT product posting group code being checked</param>
    /// <param name="Result">Custom result for the existence check</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExistingItemAndServiceWithVAT(VATProdPostingGroupCode: Code[20]; var Result: Boolean)
    begin
    end;
}
