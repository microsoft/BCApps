// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

page 5381 "CRM Sales Order Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "CRM Salesorderdetail";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                FreezeColumn = ProductIdName;
                field(ProductIdName; Rec.ProductIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Product Id';
                    Editable = false;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';

                    trigger OnDrillDown()
                    var
                        CRMProduct: Record "CRM Product";
                    begin
                        CRMProduct.SetRange(StateCode, CRMProduct.StateCode::Active);
                        PAGE.Run(PAGE::"CRM Product List", CRMProduct);
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity';
                    ToolTip = 'Specifies the quantity of the item on the sales line.';
                }
                field(UoMIdName; Rec.UoMIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Unit of Measure';
                    Editable = false;
                    ToolTip = 'Specifies the unit in which the item is held in inventory.';

                    trigger OnDrillDown()
                    var
                        CRMUomschedule: Record "CRM Uomschedule";
                    begin
                        CRMUomschedule.SetRange(StateCode, CRMUomschedule.StateCode::Active);
                        PAGE.Run(PAGE::"CRM UnitGroup List", CRMUomschedule);
                    end;
                }
                field(PricePerUnit; Rec.PricePerUnit)
                {
                    ApplicationArea = Suite;
                    Caption = 'Price Per Unit';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(BaseAmount; Rec.BaseAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the net amount of all the lines.';
                }
                field(ExtendedAmount; Rec.ExtendedAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Extended Amount';
                    ToolTip = 'Specifies the sales amount without rounding.';
                }
                field(VolumeDiscountAmount; Rec.VolumeDiscountAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Volume Discount';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(ManualDiscountAmount; Rec.ManualDiscountAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Manual Discount';
                    ToolTip = 'Specifies that the sales order is subject to manual discount.';
                }
                field(Tax; Rec.Tax)
                {
                    ApplicationArea = Suite;
                    Caption = 'Tax';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(CreatedOn; Rec.CreatedOn)
                {
                    ApplicationArea = Suite;
                    Caption = 'Created On';
                    ToolTip = 'Specifies when the sales order was created.';
                }
                field(ModifiedOn; Rec.ModifiedOn)
                {
                    ApplicationArea = Suite;
                    Caption = 'Modified On';
                    ToolTip = 'Specifies when the sales order was last modified.';
                }
                field(SalesRepIdName; Rec.SalesRepIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Rep';
                    Editable = false;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';

                    trigger OnDrillDown()
                    begin
                        PAGE.Run(PAGE::"CRM Systemuser List");
                    end;
                }
                field(TransactionCurrencyIdName; Rec.TransactionCurrencyIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency';
                    Editable = false;
                    ToolTip = 'Specifies the currency that amounts are shown in.';

                    trigger OnDrillDown()
                    var
                        CRMTransactioncurrency: Record "CRM Transactioncurrency";
                    begin
                        CRMTransactioncurrency.SetRange(StateCode, CRMTransactioncurrency.StateCode::Active);
                        PAGE.Run(PAGE::"CRM TransactionCurrency List", CRMTransactioncurrency);
                    end;
                }
                field(ExchangeRate; Rec.ExchangeRate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Exchange Rate';
                    ToolTip = 'Specifies the currency exchange rate.';
                }
                field(QuantityShipped; Rec.QuantityShipped)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity Shipped';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(QuantityBackordered; Rec.QuantityBackordered)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity Back Ordered';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(QuantityCancelled; Rec.QuantityCancelled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity Canceled';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(ProductDescription; Rec.ProductDescription)
                {
                    ApplicationArea = Suite;
                    Caption = 'Write-In Product';
                    Importance = Additional;
                    ToolTip = 'Specifies if the item is a write-in product.';
                }
                field(ShipTo_Name; Rec.ShipTo_Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Name';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(ShipTo_Line1; Rec.ShipTo_Line1)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Street 1';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(ShipTo_Line2; Rec.ShipTo_Line2)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Street 2';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(ShipTo_Line3; Rec.ShipTo_Line3)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Street 3';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(ShipTo_City; Rec.ShipTo_City)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To City';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(ShipTo_StateOrProvince; Rec.ShipTo_StateOrProvince)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To State/Province';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(ShipTo_Country; Rec.ShipTo_Country)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Country/Region';
                    Importance = Additional;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field(ShipTo_PostalCode; Rec.ShipTo_PostalCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To ZIP/Postal Code';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(WillCall; Rec.WillCall)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(ShipTo_Telephone; Rec.ShipTo_Telephone)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Phone';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(ShipTo_Fax; Rec.ShipTo_Fax)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Fax';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
                field(ShipTo_FreightTermsCode; Rec.ShipTo_FreightTermsCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Freight Terms';
                    Importance = Additional;
                    ToolTip = 'Specifies the shipment method.';
                    Visible = false;
                }
                field(ShipTo_ContactName; Rec.ShipTo_ContactName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Contact Name';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

