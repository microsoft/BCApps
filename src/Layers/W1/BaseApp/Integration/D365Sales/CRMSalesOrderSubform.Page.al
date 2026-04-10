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
                }
                field(UoMIdName; Rec.UoMIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Unit of Measure';
                    Editable = false;

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
                }
                field(BaseAmount; Rec.BaseAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Amount';
                }
                field(ExtendedAmount; Rec.ExtendedAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Extended Amount';
                }
                field(VolumeDiscountAmount; Rec.VolumeDiscountAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Volume Discount';
                }
                field(ManualDiscountAmount; Rec.ManualDiscountAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Manual Discount';
                }
                field(Tax; Rec.Tax)
                {
                    ApplicationArea = Suite;
                    Caption = 'Tax';
                }
                field(CreatedOn; Rec.CreatedOn)
                {
                    ApplicationArea = Suite;
                    Caption = 'Created On';
                }
                field(ModifiedOn; Rec.ModifiedOn)
                {
                    ApplicationArea = Suite;
                    Caption = 'Modified On';
                }
                field(SalesRepIdName; Rec.SalesRepIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Rep';
                    Editable = false;

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
                }
                field(QuantityShipped; Rec.QuantityShipped)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity Shipped';
                }
                field(QuantityBackordered; Rec.QuantityBackordered)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity Back Ordered';
                }
                field(QuantityCancelled; Rec.QuantityCancelled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity Canceled';
                }
                field(ProductDescription; Rec.ProductDescription)
                {
                    ApplicationArea = Suite;
                    Caption = 'Write-In Product';
                    Importance = Additional;
                }
                field(ShipTo_Name; Rec.ShipTo_Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Name';
                    Visible = false;
                }
                field(ShipTo_Line1; Rec.ShipTo_Line1)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Street 1';
                    Importance = Additional;
                    Visible = false;
                }
                field(ShipTo_Line2; Rec.ShipTo_Line2)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Street 2';
                    Importance = Additional;
                    Visible = false;
                }
                field(ShipTo_Line3; Rec.ShipTo_Line3)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Street 3';
                    Importance = Additional;
                    Visible = false;
                }
                field(ShipTo_City; Rec.ShipTo_City)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To City';
                    Importance = Additional;
                    Visible = false;
                }
                field(ShipTo_StateOrProvince; Rec.ShipTo_StateOrProvince)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To State/Province';
                    Importance = Additional;
                    Visible = false;
                }
                field(ShipTo_Country; Rec.ShipTo_Country)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Country/Region';
                    Importance = Additional;
                    Visible = false;
                }
                field(ShipTo_PostalCode; Rec.ShipTo_PostalCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To ZIP/Postal Code';
                    Importance = Additional;
                    Visible = false;
                }
                field(WillCall; Rec.WillCall)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To';
                    Importance = Additional;
                    Visible = false;
                }
                field(ShipTo_Telephone; Rec.ShipTo_Telephone)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Phone';
                    Visible = false;
                }
                field(ShipTo_Fax; Rec.ShipTo_Fax)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Fax';
                    Importance = Additional;
                    Visible = false;
                }
                field(ShipTo_FreightTermsCode; Rec.ShipTo_FreightTermsCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Freight Terms';
                    Importance = Additional;
                    Visible = false;
                }
                field(ShipTo_ContactName; Rec.ShipTo_ContactName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Contact Name';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

