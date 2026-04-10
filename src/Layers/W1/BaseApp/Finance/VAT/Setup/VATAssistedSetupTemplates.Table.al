// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;

/// <summary>
/// Template definitions for VAT Setup Wizard supporting automated configuration of customer, vendor, and item VAT assignments.
/// Stores predefined templates that specify default VAT posting groups for different types of master data records.
/// </summary>
/// <remarks>
/// Usage context: VAT Setup Wizard template selection and application to master data records.
/// Template types: Customer templates, Vendor templates, Item templates with specific VAT posting group assignments.
/// Integration: Applied during wizard completion to set default VAT posting groups on existing master data.
/// </remarks>
table 1878 "VAT Assisted Setup Templates"
{
    Caption = 'VAT Assisted Setup Templates';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Template identifier code for VAT setup wizard template selection.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name explaining the template's purpose and target scenario.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the VAT assisted setup.';
        }
        /// <summary>
        /// Default VAT business posting group assigned to records using this template.
        /// </summary>
        field(3; "Default VAT Bus. Posting Grp"; Code[20])
        {
            Caption = 'Default VAT Bus. Posting Grp';
            ToolTip = 'Specifies the default VAT business posting group for the customers and vendors.';
            TableRelation = "VAT Assisted Setup Bus. Grp.".Code where(Selected = const(true),
                                                                       Default = const(false));
        }
        /// <summary>
        /// Default VAT product posting group assigned to records using this template.
        /// </summary>
        field(4; "Default VAT Prod. Posting Grp"; Code[20])
        {
            Caption = 'Default VAT Prod. Posting Grp';
            ToolTip = 'Specifies the default VAT production posting group for the customers and vendors.';
            TableRelation = "VAT Setup Posting Groups"."VAT Prod. Posting Group" where(Selected = const(true),
                                                                                        Default = const(false));
        }
        /// <summary>
        /// Table ID identifying the target table type for this template (Customer, Vendor, Item, etc.).
        /// </summary>
        field(5; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Populates template records from configuration templates existing in the system.
    /// Creates VAT setup templates based on existing customer, vendor, and item configuration templates.
    /// </summary>
    procedure PopulateRecFromTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Customer: Record Customer;
        Item: Record Item;
        ConfigTemplateLine: Record "Config. Template Line";
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        DeleteAll();
        if ConfigTemplateHeader.FindSet() then
            repeat
                Code := ConfigTemplateHeader.Code;
                Description := ConfigTemplateHeader.Description;
                "Table ID" := ConfigTemplateHeader."Table ID";

                if
                   (ConfigTemplateHeader."Table ID" = Database::Customer) or
                   (ConfigTemplateHeader."Table ID" = Database::Vendor)
                then
                    if ConfigTemplateLine.GetLine(ConfigTemplateLine, ConfigTemplateHeader.Code, Customer.FieldNo("VAT Bus. Posting Group")) then
                        if
                           VATAssistedSetupBusGrp.Get(
                             CopyStr(ConfigTemplateLine."Default Value", 1, MaxStrLen("Default VAT Bus. Posting Grp")), false)
                        then
                            "Default VAT Bus. Posting Grp" :=
                              CopyStr(ConfigTemplateLine."Default Value", 1, MaxStrLen("Default VAT Bus. Posting Grp"));

                if ConfigTemplateHeader."Table ID" = Database::Item then
                    if ConfigTemplateLine.GetLine(ConfigTemplateLine, ConfigTemplateHeader.Code, Item.FieldNo("VAT Prod. Posting Group")) then
                        if
                           VATSetupPostingGroups.Get(
                             CopyStr(ConfigTemplateLine."Default Value", 1, MaxStrLen("Default VAT Prod. Posting Grp")), false)
                        then
                            "Default VAT Prod. Posting Grp" :=
                              CopyStr(ConfigTemplateLine."Default Value", 1, MaxStrLen("Default VAT Prod. Posting Grp"));

                Insert();
            until ConfigTemplateHeader.Next() = 0;
    end;

    /// <summary>
    /// Validates customer templates against selected VAT posting groups to ensure configuration consistency.
    /// Checks that customer template VAT assignments match wizard selections.
    /// </summary>
    /// <param name="VATValidationError">Error message returned if validation fails</param>
    /// <returns>True if customer templates are valid for current VAT setup selections</returns>
    procedure ValidateCustomerTemplate(var VATValidationError: Text): Boolean
    begin
        exit(ValidateTemplates(Database::Customer, VATValidationError));
    end;

    /// <summary>
    /// Validates vendor templates against selected VAT posting groups to ensure configuration consistency.
    /// Checks that vendor template VAT assignments match wizard selections.
    /// </summary>
    /// <param name="VATValidationError">Error message returned if validation fails</param>
    /// <returns>True if vendor templates are valid for current VAT setup selections</returns>
    procedure ValidateVendorTemplate(var VATValidationError: Text): Boolean
    begin
        exit(ValidateTemplates(Database::Vendor, VATValidationError));
    end;

    /// <summary>
    /// Validates item templates against selected VAT posting groups to ensure configuration consistency.
    /// Checks that item template VAT assignments match wizard selections.
    /// </summary>
    /// <param name="VATValidationError">Error message returned if validation fails</param>
    /// <returns>True if item templates are valid for current VAT setup selections</returns>
    procedure ValidateItemTemplate(var VATValidationError: Text): Boolean
    begin
        exit(ValidateTemplates(Database::Item, VATValidationError));
    end;

    local procedure ValidateTemplates(TableID: Integer; var VATValidationError: Text): Boolean
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates";
    begin
        VATAssistedSetupTemplates.SetRange("Table ID", TableID);
        VATAssistedSetupBusGrp.SetRange(Selected, true);
        VATAssistedSetupBusGrp.SetRange(Default, false);
        VATSetupPostingGroups.SetRange(Selected, true);
        VATSetupPostingGroups.SetRange(Default, false);

        if VATAssistedSetupTemplates.FindSet() then
            repeat
                if (VATAssistedSetupTemplates."Default VAT Bus. Posting Grp" <> '') and
                   ((VATAssistedSetupTemplates."Table ID" = Database::Customer) or (VATAssistedSetupTemplates."Table ID" = Database::Vendor))
                then begin
                    VATAssistedSetupBusGrp.SetRange(Code, VATAssistedSetupTemplates."Default VAT Bus. Posting Grp");
                    if not VATAssistedSetupBusGrp.FindFirst() then begin
                        VATValidationError := VATAssistedSetupTemplates."Default VAT Bus. Posting Grp";
                        exit(false);
                    end;
                end;

                if (VATAssistedSetupTemplates."Default VAT Prod. Posting Grp" <> '') and
                   (VATAssistedSetupTemplates."Table ID" = Database::Item)
                then begin
                    VATSetupPostingGroups.SetRange("VAT Prod. Posting Group", VATAssistedSetupTemplates."Default VAT Prod. Posting Grp");
                    if not VATSetupPostingGroups.FindFirst() then begin
                        VATValidationError := VATAssistedSetupTemplates."Default VAT Prod. Posting Grp";
                        exit(false);
                    end;
                end;
            until VATAssistedSetupTemplates.Next() = 0;
        exit(true);
    end;
}

