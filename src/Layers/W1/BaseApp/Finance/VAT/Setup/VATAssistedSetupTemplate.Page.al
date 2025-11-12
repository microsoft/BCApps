// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

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
                    ToolTip = 'Specifies a description of the VAT assisted setup.';
                }
                field("Default VAT Bus. Posting Grp"; Rec."Default VAT Bus. Posting Grp")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default VAT business posting group for the customers and vendors.';
                    Visible = VATBusPostingVisible;
                }
                field("Default VAT Prod. Posting Grp"; Rec."Default VAT Prod. Posting Grp")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default VAT production posting group for the customers and vendors.';
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

    procedure ShowCustomerTemplate()
    begin
        ResetVisibility();
        VATBusPostingVisible := true;
        Rec.SetRange("Table ID", Database::Customer);
        CurrPage.Update();
    end;

    procedure ShowVendorTemplate()
    begin
        ResetVisibility();
        VATBusPostingVisible := true;
        Rec.SetRange("Table ID", Database::Vendor);
        CurrPage.Update();
    end;

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

