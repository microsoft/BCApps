// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy Payment Methods Mapping(ID 30132).
/// </summary>
page 30132 "Shpfy Payment Methods Mapping"
{

    Caption = 'Shopify Payment Methods Mapping';
    PageType = List;
    SourceTable = "Shpfy Payment Method Mapping";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Gateway; Rec.Gateway)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Shopify Transaction Gateway.';
                }
                field(CreditCardCompany; Rec."Credit Card Company")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Shopify Credit Card Company.';
                }
                field(PaymentMethod; Rec."Payment Method Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the corresponding payment method in D365BC.';
                }
                field(AutoPostJnlTemplate; Rec."Auto-Post Jnl. Template")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the general journal template to use for automatically posting payment transactions.';
                    ShowMandatory = Rec."Post Automatically";
                }
                field(AutoPostJnlBatch; Rec."Auto-Post Jnl. Batch")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the general journal batch to use for automatically posting payment transactions.';
                    ShowMandatory = Rec."Post Automatically";
                }
                field(PostAutomatically; Rec."Post Automatically")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether payment transactions using this gateway should be automatically posted when the related invoice or credit memo is posted. Set the journal template and batch first.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DiscoverPaymentMethods)
            {
                ApplicationArea = All;
                Caption = 'Discover Payment Methods';
                Image = Refresh;
                ToolTip = 'Find payment methods used on recent Shopify orders and add new entries to Payment Method Mapping. Existing entries aren''t changed.';

                trigger OnAction()
                var
                    PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
                    Shop: Record "Shpfy Shop";
                    DiscoverPaymentMethods: Codeunit "Shpfy Discover Payment Methods";
                    ShopCodeFilter: Text;
                    HasOrders: Boolean;
                    CreatedMappingCount: Integer;
                    ShopContextRequiredErr: Label 'Open this page from a Shopify Shop Card to discover payment methods.';
                    ShopNotFoundErr: Label 'The Shopify Shop %1 could not be found.', Comment = '%1 = Shopify Shop code';
                    MappingModificationPermissionErr: Label 'You do not have permission to modify payment method mappings.';
                    NoNewPaymentMethodsMsg: Label 'No new Shopify payment methods were found in the 100 most recent orders.';
                    NoOrdersFoundMsg: Label 'No Shopify orders are available for payment method discovery.';
                begin
                    ShopCodeFilter := Rec.GetFilter("Shop Code");
                    if ShopCodeFilter = '' then
                        Error(ShopContextRequiredErr);
                    if not Shop.Get(ShopCodeFilter) then
                        Error(ShopNotFoundErr, ShopCodeFilter);
                    if not PaymentMethodMapping.WritePermission() then
                        Error(MappingModificationPermissionErr);

                    DiscoverPaymentMethods.Discover(Shop.Code, HasOrders, CreatedMappingCount);
                    if not HasOrders then
                        Message(NoOrdersFoundMsg)
                    else
                        if CreatedMappingCount = 0 then
                            Message(NoNewPaymentMethodsMsg)
                        else
                            CurrPage.Update(false);
                end;
            }
        }
    }
}