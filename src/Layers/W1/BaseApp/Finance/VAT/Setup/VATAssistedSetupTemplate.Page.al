// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// VAT assisted setup template page component used within the VAT Setup Wizard for template selection and configuration.
/// Displays available templates for applying default VAT posting groups to customer, vendor, and item master data.
/// </summary>
/// <remarks>
/// Page type: ListPart component integrated into VAT Setup Wizard workflow.
/// Data source: VAT Assisted Setup Templates table with predefined and configuration-derived templates.
/// User interaction: Template selection and VAT posting group assignment for bulk master data configuration.
/// </remarks>
page 1880 "VAT Assisted Setup Template"
{
    Caption = 'VAT Assisted Setup Template';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Assisted Setup Templates";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Default VAT Bus. Posting Grp"; Rec."Default VAT Bus. Posting Grp")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATBusPostingVisible;
                }
                field("Default VAT Prod. Posting Grp"; Rec."Default VAT Prod. Posting Grp")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATProdPostingVisible;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.PopulateRecFromTemplates();
        ShowCustomerTemplate();
    end;

    var
        VATProdPostingVisible: Boolean;
        VATBusPostingVisible: Boolean;

    /// <summary>
    /// Displays customer templates with VAT business posting group assignment options.
    /// Filters template list to show only customer-related templates and enables business posting group field visibility.
    /// </summary>
    procedure ShowCustomerTemplate()
    begin
        ResetVisibility();
        VATBusPostingVisible := true;
        Rec.SetRange("Table ID", Database::Customer);
        CurrPage.Update();
    end;

    /// <summary>
    /// Displays vendor templates with VAT business posting group assignment options.
    /// Filters template list to show only vendor-related templates and enables business posting group field visibility.
    /// </summary>
    procedure ShowVendorTemplate()
    begin
        ResetVisibility();
        VATBusPostingVisible := true;
        Rec.SetRange("Table ID", Database::Vendor);
        CurrPage.Update();
    end;

    /// <summary>
    /// Displays item templates with VAT product posting group assignment options.
    /// Filters template list to show only item-related templates and enables product posting group field visibility.
    /// </summary>
    procedure ShowItemTemplate()
    begin
        ResetVisibility();
        VATProdPostingVisible := true;
        Rec.SetRange("Table ID", Database::Item);
        CurrPage.Update();
    end;

    local procedure ResetVisibility()
    begin
        VATBusPostingVisible := false;
        VATProdPostingVisible := false;
    end;
}

