// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Service.Posting;

page 5914 "Service Order Statistics"
{
    Caption = 'Service Order Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Service Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Amount_General; TotalServLine[1]."Line Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    ToolTip = 'Specifies the line amount.';
                    Editable = false;
                }
                field("Inv. Discount Amount_General"; TotalServLine[1]."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the entire service order.';

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::General;
                        UpdateInvDiscAmount(1);
                    end;
                }
                field("TotalAmount1[1]"; TotalAmount1[1])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::General;
                        UpdateTotalAmount(1);
                    end;
                }
                field("VAT Amount_General"; VATAmount[1])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[1]);
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the service order.';
                }
                field("Total Incl. VAT_General"; TotalAmount2[1])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Editable = false;

                    trigger OnValidate()
                    begin
                        TotalAmount21OnAfterValidate();
                    end;
                }
                field("Sales (LCY)_General"; TotalServLineLCY[1].Amount)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total service sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open service sales invoices and credit memos.';
                }
                field(Original_ProfitLCY_Gen; ProfitLCY[1])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, costs, items and/or resources in the service order. The cost is calculated as a product of unit cost multiplied by quantity of the relevant items or resources.';
                }
                field(Adj_ProfitLCY_Gen; AdjProfitLCY[1])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount of profit for the service order, in LCY, adjusted for any changes in the original item costs.';
                }
                field(Original_ProfitPct_Gen; ProfitPct[1])
                {
                    ApplicationArea = Service;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the profit percentage prior to any item cost adjustments on the service order.';
                }
                field(Adj_ProfitPct_Gen; AdjProfitPct[1])
                {
                    ApplicationArea = Service;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the adjusted profit on the service order, expressed as percentage of the amount in the Amount Excl. VAT (Amount Incl. VAT) field.';
                }
                field("TotalServLine[1].Quantity"; TotalServLine[1].Quantity)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service order.';
                }
#pragma warning disable AA0100
                field("TotalServLine[1].""Units per Parcel"""; TotalServLine[1]."Units per Parcel")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of parcels of the items specified on the service lines in the order.';
                }
#pragma warning disable AA0100
                field("TotalServLine[1].""Net Weight"""; TotalServLine[1]."Net Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the net weight of the items specified on the service lines in the order.';
                }
#pragma warning disable AA0100
                field("TotalServLine[1].""Gross Weight"""; TotalServLine[1]."Gross Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of the items on the service lines in the order.';
                }
#pragma warning disable AA0100
                field("TotalServLine[1].""Unit Volume"""; TotalServLine[1]."Unit Volume")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the volume of the items on the service lines in the order.';
                }
                field(OriginalCostLCY; TotalServLineLCY[1]."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, costs, items and/or resources in the service order. The cost is calculated as a product of unit cost multiplied by quantity of the relevant items.';
                }
                field(AdjustedCostLCY; TotalAdjCostLCY[1])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the service order, adjusted for any changes in the original costs of these items';
                }
#pragma warning disable AA0100
                field("TotalAdjCostLCY[1] - TotalServLineLCY[1].""Unit Cost (LCY)"""; TotalAdjCostLCY[1] - TotalServLineLCY[1]."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the service order.';

                    trigger OnDrillDown()
                    begin
                        Rec.LookupAdjmtValueEntries(0);
                    end;
                }
                field("No. of VAT Lines_General"; TempVATAmountLine1.Count)
                {
                    ApplicationArea = Service;
                    Caption = 'No. of VAT Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of service order lines that are associated with the VAT ledger line.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine1, false);
                        UpdateHeaderInfo(1, TempVATAmountLine1);
                    end;
                }
                field("Reserved From Stock"; Rec.GetQtyReservedFromStockState())
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    Caption = 'Reserved from stock';
                    ToolTip = 'Specifies what part of the service order is reserved from inventory.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                fixed(Control1904230801)
                {
                    ShowCaption = false;
                    group(Invoicing)
                    {
                        Caption = 'Invoicing';
                        field("TotalServLine[2].Quantity"; TotalServLine[2].Quantity)
                        {
                            ApplicationArea = Service;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service order.';
                        }
                        field(Amount_Invoicing; TotalServLine[2]."Line Amount")
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            Editable = false;
                            ToolTip = 'Specifies the amount for the relevant service order.';
                        }
                        field("Inv. Discount Amount_Invoicing"; TotalServLine[2]."Inv. Discount Amount")
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Inv. Discount Amount';
                            ToolTip = 'Specifies the invoice discount amount for the entire service order.';

                            trigger OnValidate()
                            begin
                                ActiveTab := ActiveTab::Details;
                                UpdateInvDiscAmount(2);
                            end;
                        }
                        field(Total; TotalAmount1[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total';
                            ToolTip = 'Specifies the total amount.';

                            trigger OnValidate()
                            begin
                                ActiveTab := ActiveTab::Details;
                                UpdateTotalAmount(2);
                            end;
                        }
                        field("VAT Amount_Invoicing"; VATAmount[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'VAT Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the service order.';
                        }
                        field("Total Incl. VAT_Invoicing"; TotalAmount2[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total amounts on the service order that result from adding the invoicing amounts to the consuming amounts.';
                        }
                        field("Sales (LCY)_Invoicing"; TotalServLineLCY[2].Amount)
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Sales (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies your total service sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open service sales invoices and credit memos.';
                        }
                        field("ProfitLCY[2]"; ProfitLCY[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Original Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, costs, items and/or resources in the service order. The cost is calculated as a product of unit cost multiplied by quantity of the relevant items or resources.';
                        }
                        field("AdjProfitLCY[2]"; AdjProfitLCY[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the amount of profit for the service order, in LCY, adjusted for any changes in the original item costs.';
                        }
                        field("ProfitPct[2]"; ProfitPct[2])
                        {
                            ApplicationArea = Service;
                            Caption = 'Original Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the profit percentage prior to any item cost adjustments on the service order.';
                        }
                        field("AdjProfitPct[2]"; AdjProfitPct[2])
                        {
                            ApplicationArea = Service;
                            Caption = 'Adjusted Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the amount of the adjusted profit on the service order, expressed as percentage of the amount in the Amount Excl. VAT (Amount Incl. VAT) field.';
                        }
#pragma warning disable AA0100
                        field("TotalServLineLCY[2].""Unit Cost (LCY)"""; TotalServLineLCY[2]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Original Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, costs, items and/or resources in the service order. The cost is calculated as a product of unit cost multiplied by quantity of the relevant items or resources.';
                        }
                        field("TotalAdjCostLCY[2]"; TotalAdjCostLCY[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the items in the service order, adjusted for any changes in the original costs of these items';
                        }
#pragma warning disable AA0100
                        field("TotalAdjCostLCY[2] - TotalServLineLCY[2].""Unit Cost (LCY)"""; TotalAdjCostLCY[2] - TotalServLineLCY[2]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost Adjmt. Amount (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the service order.';

                            trigger OnDrillDown()
                            begin
                                Rec.LookupAdjmtValueEntries(1);
                            end;
                        }
                    }
                    group(Consuming)
                    {
                        Caption = 'Consuming';
                        field(Quantity_Consuming; TotalServLine[4].Quantity)
                        {
                            ApplicationArea = Service;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service order.';
                        }
                        field(Text006; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder2; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder3; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(placeholder5; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder6; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder7; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field("ProfitLCY[4]"; ProfitLCY[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Original Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, costs, items and/or resources in the service order. The cost is calculated as a product of unit cost multiplied by quantity of the relevant items or resources.';
                        }
                        field("AdjProfitLCY[4]"; AdjProfitLCY[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the amount of profit for the service order, in LCY, adjusted for any changes in the original item costs.';
                        }
                        field("ProfitPct[4]"; ProfitPct[4])
                        {
                            ApplicationArea = Service;
                            Caption = 'Original Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the amount of original profit for the service order (in LCY), prior to any item cost adjustment. The program calculates the amount as the difference between the values in the Amount Excl. VAT (Amount Incl. VAT) and the Original Cost (LCY) fields.';
                        }
                        field("AdjProfitPct[4]"; AdjProfitPct[4])
                        {
                            ApplicationArea = Service;
                            Caption = 'Adjusted Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the amount of the adjusted profit on the service order, expressed as percentage of the amount in the Amount Excl. VAT (Amount Incl. VAT) field.';
                        }
#pragma warning disable AA0100
                        field("TotalServLineLCY[4].""Unit Cost (LCY)"""; TotalServLineLCY[4]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost of the service in LCY.';
                        }
                        field("TotalAdjCostLCY[4]"; TotalAdjCostLCY[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the items in the service order, adjusted for any changes in the original costs of these items';
                        }
#pragma warning disable AA0100
                        field("TotalAdjCostLCY[4] - TotalServLineLCY[4].""Unit Cost (LCY)"""; TotalAdjCostLCY[4] - TotalServLineLCY[4]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Adjustment Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the items in the service order, adjusted for any changes in the original costs of these items.';

                            trigger OnDrillDown()
                            begin
                                Rec.LookupAdjmtValueEntries(1);
                            end;
                        }
                    }
                    group(Control1906106001)
                    {
                        Caption = 'Total';
                        field("TotalServLine[2].Quantity + TotalServLine[4].Quantity"; TotalServLine[2].Quantity + TotalServLine[4].Quantity)
                        {
                            ApplicationArea = Service;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service order.';
                        }
#pragma warning disable AA0100
                        field("TotalServLine[2].""Line Amount"""; TotalServLine[2]."Line Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text002, false);
                            Editable = false;
                        }
#pragma warning disable AA0100
                        field("TotalServLine[2].""Inv. Discount Amount"""; TotalServLine[2]."Inv. Discount Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Inv. Discount Amount';
                            Editable = false;
                            ToolTip = 'Specifies the invoice discount amount for the entire service order.';

                            trigger OnValidate()
                            begin
                                ActiveTab := ActiveTab::Details;
                                UpdateInvDiscAmount(2);
                            end;
                        }
                        field("TotalAmount1[2]"; TotalAmount1[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text001, false);
                            Editable = false;

                            trigger OnValidate()
                            begin
                                ActiveTab := ActiveTab::Details;
                                UpdateTotalAmount(2);
                            end;
                        }
                        field("VATAmount[2]"; VATAmount[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("TotalAmount2[2]"; TotalAmount2[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text001, true);
                            Editable = false;
                        }
                        field("TotalServLineLCY[2].Amount"; TotalServLineLCY[2].Amount)
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Amount (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the ledger entry, in the local currency.';
                        }
                        field("AdjProfitLCY[2] + AdjProfitLCY[4]"; AdjProfitLCY[2] + AdjProfitLCY[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the profit related to the service order, in local currency.';
                        }
                        field("ProfitLCY[2] + ProfitLCY[4]"; ProfitLCY[2] + ProfitLCY[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the profit related to the service order, in local currency.';
                        }
                        field(DetailsTotalAmt; GetDetailsTotalAmt())
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the percent of profit related to the service order.';
                        }
                        field(AdjDetailsTotalAmt; GetAdjDetailsTotalAmt())
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the percent of profit related to the service order.';
                        }
#pragma warning disable AA0100
                        field("TotalServLineLCY[2].""Unit Cost (LCY)"" + TotalServLineLCY[4].""Unit Cost (LCY)"""; TotalServLineLCY[2]."Unit Cost (LCY)" + TotalServLineLCY[4]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost of the service in LCY.';
                        }
                        field("TotalAdjCostLCY[2] + TotalAdjCostLCY[4]"; TotalAdjCostLCY[2] + TotalAdjCostLCY[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost of the service in LCY.';
                        }
                        field(DetailedTotalLCYCost; (TotalAdjCostLCY[2] - TotalServLineLCY[2]."Unit Cost (LCY)") + (TotalAdjCostLCY[4] - TotalServLineLCY[4]."Unit Cost (LCY)"))
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost of the service in LCY.';
                        }
                    }
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field(Amount_Shipping; TotalServLine[3]."Line Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Editable = false;
                }
                field("Inv. Discount Amount_Shipping"; TotalServLine[3]."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the entire service order.';
                }
                field("TotalAmount1[3]"; TotalAmount1[3])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Editable = false;
                }
                field("VAT Amount_Shipping"; VATAmount[3])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[3]);
                    Editable = false;
                }
                field("Total Incl. VAT_Shipping"; TotalAmount2[3])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Editable = false;
                }
                field("Sales (LCY)_Shipping"; TotalServLineLCY[3].Amount)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total service sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open service sales invoices and credit memos.';
                }
#pragma warning disable AA0100
                field("TotalServLineLCY[3].""Unit Cost (LCY)"""; TotalServLineLCY[3]."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost of the service in LCY.';
                }
                field("ProfitLCY[3]"; ProfitLCY[3])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the profit related to the service order, in local currency.';
                }
                field("ProfitPct[3]"; ProfitPct[3])
                {
                    ApplicationArea = Service;
                    Caption = 'Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the percent of profit related to the service order.';
                }
                field("TotalServLine[3].Quantity"; TotalServLine[3].Quantity)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service order.';
                }
#pragma warning disable AA0100
                field("TotalServLine[3].""Units per Parcel"""; TotalServLine[3]."Units per Parcel")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of parcels of the items specified on the service lines in the order.';
                }
#pragma warning disable AA0100
                field("TotalServLine[3].""Net Weight"""; TotalServLine[3]."Net Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the net weight of the items specified on the service lines in the order.';
                }
#pragma warning disable AA0100
                field("TotalServLine[3].""Gross Weight"""; TotalServLine[3]."Gross Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of the items on the service lines in the order.';
                }
#pragma warning disable AA0100
                field("TotalServLine[3].""Unit Volume"""; TotalServLine[3]."Unit Volume")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the volume of the items on the service lines in the order.';
                }
                field("No. of VAT Lines_Shipping"; TempVATAmountLine3.Count)
                {
                    ApplicationArea = Service;
                    Caption = 'No. of VAT Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of service order lines that are associated with the VAT ledger line.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine3, false);
                    end;
                }
            }
            group("Service Line")
            {
                Caption = 'Service Line';
                fixed(Control1903442601)
                {
                    ShowCaption = false;
                    group(Items)
                    {
                        Caption = 'Items';
                        field("TotalServLine[5].Quantity"; TotalServLine[5].Quantity)
                        {
                            ApplicationArea = Service;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service order.';
                        }
                        field(Amount_Items; TotalServLine[5]."Line Amount")
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            Editable = false;
                            ToolTip = 'Specifies the amount for the relevant service order.';
                        }
                        field("Inv. Discount Amount_Items"; TotalServLine[5]."Inv. Discount Amount")
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Inv. Discount Amount';
                            Editable = false;
                            ToolTip = 'Specifies the invoice discount amount for the entire service order.';
                        }
                        field(Total2; TotalAmount1[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total';
                            Editable = false;
                            ToolTip = 'Specifies the total amount.';
                        }
                        field("VAT Amount_Items"; VATAmount[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'VAT Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the service order.';
                        }
                        field("Total Incl. VAT_Items"; TotalAmount2[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total amount minus any invoice discount amount for the service order. The value does not include VAT.';
                        }
                        field("Sales (LCY)_Items"; TotalServLineLCY[5].Amount)
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Sales (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies your total service sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open service sales invoices and credit memos.';
                        }
                        field("ProfitLCY[5]"; ProfitLCY[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Original Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, costs, items and/or resources in the service order. The cost is calculated as a product of unit cost multiplied by quantity of the relevant items or resources.';
                        }
                        field("AdjProfitLCY[5]"; AdjProfitLCY[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the amount of profit for the service order, in LCY, adjusted for any changes in the original item costs.';
                        }
                        field("ProfitPct[5]"; ProfitPct[5])
                        {
                            ApplicationArea = Service;
                            Caption = 'Original Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the amount of original profit for the service order (in LCY), prior to any item cost adjustment. The program calculates the amount as the difference between the values in the Amount Excl. VAT (Amount Incl. VAT) and the Original Cost (LCY) fields.';
                        }
                        field("AdjProfitPct[5]"; AdjProfitPct[5])
                        {
                            ApplicationArea = Service;
                            Caption = 'Adjusted Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the amount of the adjusted profit on the service order, expressed as percentage of the amount in the Amount Excl. VAT (Amount Incl. VAT) field.';
                        }
#pragma warning disable AA0100
                        field("TotalServLineLCY[5].""Unit Cost (LCY)"""; TotalServLineLCY[5]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Original Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, costs, items and/or resources in the service order. The cost is calculated as a product of unit cost multiplied by quantity of the relevant items.';
                        }
                        field("TotalAdjCostLCY[5]"; TotalAdjCostLCY[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the items in the service order, adjusted for any changes in the original costs of these items';
                        }
#pragma warning disable AA0100
                        field("TotalAdjCostLCY[5] - TotalServLineLCY[5].""Unit Cost (LCY)"""; TotalAdjCostLCY[5] - TotalServLineLCY[5]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost Adjmt. Amount (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the service order.';

                            trigger OnDrillDown()
                            begin
                                Rec.LookupAdjmtValueEntries(1);
                            end;
                        }
                    }
                    group(Resources)
                    {
                        Caption = 'Resources';
                        field("TotalServLine[6].Quantity"; TotalServLine[6].Quantity)
                        {
                            ApplicationArea = Service;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service order.';
                        }
                        field(Amount_Resources; TotalServLine[6]."Line Amount")
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text002, false);
                            Editable = false;
                        }
                        field("Inv. Discount Amount_Resources"; TotalServLine[6]."Inv. Discount Amount")
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Inv. Discount Amount';
                            Editable = false;
                            ToolTip = 'Specifies the invoice discount amount for the entire service order.';
                        }
                        field("TotalAmount1[6]"; TotalAmount1[6])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text001, false);
                            Editable = false;
                        }
                        field("VAT Amount_Resources"; VATAmount[6])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("Total Incl. VAT_Resources"; TotalAmount2[6])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text001, true);
                            Editable = false;
                        }
                        field("Sales (LCY)_Resources"; TotalServLineLCY[6].Amount)
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Amount (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the ledger entry, in the local currency.';
                        }
                        field("ProfitLCY[6]"; ProfitLCY[6])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the profit related to the service order, in local currency.';
                        }
                        field("AdjProfitLCY[6]"; AdjProfitLCY[6])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the profit related to the service order, in local currency.';
                        }
                        field("ProfitPct[6]"; ProfitPct[6])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the percent of profit related to the service order.';
                        }
                        field(Placeholder9; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
#pragma warning disable AA0100
                        field("TotalServLineLCY[6].""Unit Cost (LCY)"""; TotalServLineLCY[6]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost of the service in LCY.';
                        }
                        field(Placeholder10; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder11; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                    }
                    group("Costs && G/L Accounts")
                    {
                        Caption = 'Costs && G/L Accounts';
                        field("TotalServLine[7].Quantity"; TotalServLine[7].Quantity)
                        {
                            ApplicationArea = Service;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service order.';
                        }
                        field(Amount_Costs; TotalServLine[7]."Line Amount")
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text002, false);
                            Editable = false;
                        }
                        field("Inv. Discount Amount_Costs"; TotalServLine[7]."Inv. Discount Amount")
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Inv. Discount Amount';
                            Editable = false;
                            ToolTip = 'Specifies the invoice discount amount for the entire service order.';
                        }
                        field("TotalAmount1[7]"; TotalAmount1[7])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text001, false);
                            Editable = false;
                        }
                        field("VAT Amount_Costs"; VATAmount[7])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("Total Incl. VAT_Costs"; TotalAmount2[7])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text001, true);
                            Editable = false;
                        }
                        field("Sales (LCY)_Costs"; TotalServLineLCY[7].Amount)
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Amount (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the ledger entry, in the local currency.';
                        }
                        field("ProfitLCY[7]"; ProfitLCY[7])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the profit related to the service order, in local currency.';
                        }
                        field("AdjProfitLCY[7]"; AdjProfitLCY[7])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the profit related to the service order, in local currency.';
                        }
                        field("ProfitPct[7]"; ProfitPct[7])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the percent of profit related to the service order.';
                        }
                        field(Placeholder12; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
#pragma warning disable AA0100
                        field("TotalServLineLCY[7].""Unit Cost (LCY)"""; TotalServLineLCY[7]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost of the service in LCY.';
                        }
                        field(Placeholder14; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                        field(Placeholder15; Text006)
                        {
                            ApplicationArea = Service;
                            Visible = false;
                        }
                    }
                }
            }
            group(Customer)
            {
                Caption = 'Customer';
#pragma warning disable AA0100
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the balance in LCY on the customer''s account.';
                }
                field("Credit Limit (LCY)_Customer"; Cust."Credit Limit (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the credit limit of the customer on the service document. The value 0 represents unlimited credit.';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Service;
                    Caption = 'Expended % of Credit Limit (LCY)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the expended percentage of the credit limit in (LCY).';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        ServLine: Record "Service Line";
        TempServLine: Record "Service Line" temporary;
        OptionValueOutOfRange: Integer;
    begin
        CurrPage.Caption(StrSubstNo(Text000, Rec."Document Type"));

        if PrevNo = Rec."No." then
            exit;
        PrevNo := Rec."No.";
        Rec.FilterGroup(2);
        Rec.SetRange("No.", PrevNo);
        Rec.FilterGroup(0);

        Clear(ServLine);
        Clear(TotalServLine);
        Clear(TotalServLineLCY);
        Clear(ServAmtsMgt);

        for i := 1 to 7 do begin
            TempServLine.DeleteAll();
            Clear(TempServLine);
            ServAmtsMgt.GetServiceLines(Rec, TempServLine, i - 1);

            case i of
                1:
                    ServLine.CalcVATAmountLines(0, Rec, TempServLine, TempVATAmountLine1, false);
                2:
                    ServLine.CalcVATAmountLines(0, Rec, TempServLine, TempVATAmountLine2, false);
                3:
                    ServLine.CalcVATAmountLines(0, Rec, TempServLine, TempVATAmountLine3, false);
            end;

            ServAmtsMgt.SumServiceLinesTemp(
              Rec, TempServLine, i - 1, TotalServLine[i], TotalServLineLCY[i],
              VATAmount[i], VATAmountText[i], ProfitLCY[i], ProfitPct[i], TotalAdjCostLCY[i]);

            if i = 3 then
                TotalAdjCostLCY[i] := TotalServLineLCY[i]."Unit Cost (LCY)";

            if TotalServLineLCY[i].Amount = 0 then
                ProfitPct[i] := 0
            else
                ProfitPct[i] := Round(100 * ProfitLCY[i] / TotalServLineLCY[i].Amount, 0.1);

            AdjProfitLCY[i] := TotalServLineLCY[i].Amount - TotalAdjCostLCY[i];

            if TotalServLineLCY[i].Amount <> 0 then
                AdjProfitPct[i] := Round(100 * AdjProfitLCY[i] / TotalServLineLCY[i].Amount, 0.1);

            OnBeforeCalcTotalAmount(TempServLine);
            if Rec."Prices Including VAT" then begin
                TotalAmount2[i] := TotalServLine[i].Amount;
                TotalAmount1[i] := TotalAmount2[i] + VATAmount[i];
                TotalServLine[i]."Line Amount" := TotalAmount1[i] + TotalServLine[i]."Inv. Discount Amount";
            end else begin
                TotalAmount1[i] := TotalServLine[i].Amount;
                TotalAmount2[i] := TotalServLine[i]."Amount Including VAT";
            end;
            OnAfterCalcTotalAmount();
        end;

        if Cust.Get(Rec."Bill-to Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);

        case true of
            Cust."Credit Limit (LCY)" = 0:
                CreditLimitLCYExpendedPct := 0;
            Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" < 0:
                CreditLimitLCYExpendedPct := 0;
            Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" > 1:
                CreditLimitLCYExpendedPct := 10000;
            else
                CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);
        end;

        TempVATAmountLine1.ModifyAll(Modified, false);
        TempVATAmountLine2.ModifyAll(Modified, false);
        TempVATAmountLine3.ModifyAll(Modified, false);

        OptionValueOutOfRange := -1;
        PrevTab := OptionValueOutOfRange;
    end;

    trigger OnOpenPage()
    var
        ServiceLine: Record "Service Line";
    begin
        SalesSetup.Get();

#if not CLEAN27
        if not Rec.SkipStatisticsPreparation() then
#endif
            if SalesSetup."Calc. Inv. Discount" then begin
                ServiceLine.SetRange("Document Type", Rec."Document Type");
                ServiceLine.SetRange("Document No.", Rec."No.");
                if ServiceLine.FindFirst() then begin
                    CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);
                    Commit();
                end;
            end;
#if not CLEAN27
        Rec.ResetSkipStatisticsPreparationFlag();
#endif
        AllowInvDisc := not (SalesSetup."Calc. Inv. Discount" and CustInvDiscRecExists(Rec."Invoice Disc. Code"));
        AllowVATDifference := SalesSetup."Allow VAT Difference" and (Rec."Document Type" <> Rec."Document Type"::Quote);
        VATLinesFormIsEditable := AllowVATDifference or AllowInvDisc;
        CurrPage.Editable := VATLinesFormIsEditable;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification(PrevTab);
        if TempVATAmountLine1.GetAnyLineModified() or TempVATAmountLine2.GetAnyLineModified() then
            UpdateVATOnServLines();
        exit(true);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Service %1 Statistics';
#pragma warning restore AA0470
        Text001: Label 'Total';
        Text002: Label 'Amount';
#pragma warning disable AA0470
        Text003: Label '%1 must not be 0.';
        Text004: Label '%1 must not be greater than %2.';
        Text005: Label 'You cannot change the invoice discount because there is a %1 record for %2 %3.', Comment = 'You cannot change the invoice discount because there is a Cust. Invoice Disc. record for Invoice Disc. Code 10000.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Cust: Record Customer;
        SalesSetup: Record "Sales & Receivables Setup";
        ServAmtsMgt: Codeunit "Serv-Amounts Mgt.";
        AdjProfitLCY: array[7] of Decimal;
        AdjProfitPct: array[7] of Decimal;
        TotalAdjCostLCY: array[7] of Decimal;
        VATAmount: array[7] of Decimal;
        VATAmountText: array[7] of Text[30];
        ProfitLCY: array[7] of Decimal;
        ProfitPct: array[7] of Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        PrevNo: Code[20];
        ActiveTab: Option General,Details,Shipping;
        PrevTab: Option General,Details,Shipping;
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;
#pragma warning disable AA0074
        Text006: Label 'Placeholder';
#pragma warning restore AA0074

    protected var
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
        TempVATAmountLine2: Record "VAT Amount Line" temporary;
        TempVATAmountLine3: Record "VAT Amount Line" temporary;
        TotalServLine: array[7] of Record "Service Line";
        TotalServLineLCY: array[7] of Record "Service Line";
        VATLinesForm: Page "VAT Amount Lines";
        TotalAmount1: array[7] of Decimal;
        TotalAmount2: array[7] of Decimal;
        i: Integer;
        VATLinesFormIsEditable: Boolean;

    protected procedure UpdateHeaderInfo(IndexNo: Integer; var VATAmountLine: Record "VAT Amount Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalServLine[IndexNo]."Inv. Discount Amount" := VATAmountLine.GetTotalInvDiscAmount();
        TotalAmount1[IndexNo] :=
          TotalServLine[IndexNo]."Line Amount" - TotalServLine[IndexNo]."Inv. Discount Amount";
        VATAmount[IndexNo] := VATAmountLine.GetTotalVATAmount();
        if Rec."Prices Including VAT" then begin
            TotalAmount1[IndexNo] := VATAmountLine.GetTotalAmountInclVAT();
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] - VATAmount[IndexNo];
            TotalServLine[IndexNo]."Line Amount" :=
              TotalAmount1[IndexNo] + TotalServLine[IndexNo]."Inv. Discount Amount";
        end else
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] + VATAmount[IndexNo];

        OnUpdateHeaderInfoOnAfterCalcTotalAmount2();
        if Rec."Prices Including VAT" then
            TotalServLineLCY[IndexNo].Amount := TotalAmount2[IndexNo]
        else
            TotalServLineLCY[IndexNo].Amount := TotalAmount1[IndexNo];
        if Rec."Currency Code" <> '' then
            if (Rec."Document Type" = Rec."Document Type"::Quote) and
               (Rec."Posting Date" = 0D)
            then
                UseDate := WorkDate()
            else
                UseDate := Rec."Posting Date";

        TotalServLineLCY[IndexNo].Amount :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            UseDate, Rec."Currency Code", TotalServLineLCY[IndexNo].Amount, Rec."Currency Factor");

        ProfitLCY[IndexNo] := TotalServLineLCY[IndexNo].Amount - TotalServLineLCY[IndexNo]."Unit Cost (LCY)";

        if TotalServLineLCY[IndexNo].Amount = 0 then
            ProfitPct[IndexNo] := 0
        else
            ProfitPct[IndexNo] := Round(100 * ProfitLCY[IndexNo] / TotalServLineLCY[IndexNo].Amount, 0.1);

        AdjProfitLCY[IndexNo] := TotalServLineLCY[IndexNo].Amount - TotalAdjCostLCY[IndexNo];

        if TotalServLineLCY[IndexNo].Amount = 0 then
            AdjProfitPct[IndexNo] := 0
        else
            AdjProfitPct[IndexNo] := Round(100 * AdjProfitLCY[IndexNo] / TotalServLineLCY[IndexNo].Amount, 0.1);

        OnAfterUpdateHeaderInfo(TotalServLineLCY, IndexNo);
    end;

    local procedure GetVATSpecification(QtyType: Option General,Details,Shipping)
    begin
        case QtyType of
            QtyType::General:
                begin
                    VATLinesForm.GetTempVATAmountLine(TempVATAmountLine1);
                    UpdateHeaderInfo(1, TempVATAmountLine1);
                end;
            QtyType::Details:
                begin
                    VATLinesForm.GetTempVATAmountLine(TempVATAmountLine2);
                    UpdateHeaderInfo(2, TempVATAmountLine2);
                end;
            QtyType::Shipping:
                VATLinesForm.GetTempVATAmountLine(TempVATAmountLine3);
        end;
    end;

    local procedure UpdateTotalAmount(IndexNo: Integer)
    var
        SaveTotalAmount: Decimal;
    begin
        CheckAllowInvDisc();
        if Rec."Prices Including VAT" then begin
            SaveTotalAmount := TotalAmount1[IndexNo];
            UpdateInvDiscAmount(IndexNo);
            TotalAmount1[IndexNo] := SaveTotalAmount;
        end;

        TotalServLine[IndexNo]."Inv. Discount Amount" := TotalServLine[IndexNo]."Line Amount" - TotalAmount1[IndexNo];
        UpdateInvDiscAmount(IndexNo);
    end;

    local procedure UpdateInvDiscAmount(ModifiedIndexNo: Integer)
    var
        PartialInvoicing: Boolean;
        MaxIndexNo: Integer;
        IndexNo: array[2] of Integer;
        i: Integer;
        InvDiscBaseAmount: Decimal;
    begin
        CheckAllowInvDisc();
        if not (ModifiedIndexNo in [1, 2]) then
            exit;

        if ModifiedIndexNo = 1 then
            InvDiscBaseAmount := TempVATAmountLine1.GetTotalInvDiscBaseAmount(false, Rec."Currency Code")
        else
            InvDiscBaseAmount := TempVATAmountLine2.GetTotalInvDiscBaseAmount(false, Rec."Currency Code");

        if InvDiscBaseAmount = 0 then
            Error(Text003, TempVATAmountLine2.FieldCaption("Inv. Disc. Base Amount"));

        if TotalServLine[ModifiedIndexNo]."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalServLine[ModifiedIndexNo].FieldCaption("Inv. Discount Amount"),
              TempVATAmountLine2.FieldCaption("Inv. Disc. Base Amount"));

        PartialInvoicing := (TotalServLine[1]."Line Amount" <> TotalServLine[2]."Line Amount");

        IndexNo[1] := ModifiedIndexNo;
        IndexNo[2] := 3 - ModifiedIndexNo;
        if (ModifiedIndexNo = 2) and PartialInvoicing then
            MaxIndexNo := 1
        else
            MaxIndexNo := 2;

        if not PartialInvoicing then
            if ModifiedIndexNo = 1 then
                TotalServLine[2]."Inv. Discount Amount" := TotalServLine[1]."Inv. Discount Amount"
            else
                TotalServLine[1]."Inv. Discount Amount" := TotalServLine[2]."Inv. Discount Amount";

        for i := 1 to MaxIndexNo do begin
            if (i = 1) or not PartialInvoicing then
                if IndexNo[i] = 1 then
                    TempVATAmountLine1.SetInvoiceDiscountAmount(
                      TotalServLine[IndexNo[i]]."Inv. Discount Amount", TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %")
                else
                    TempVATAmountLine2.SetInvoiceDiscountAmount(
                      TotalServLine[IndexNo[i]]."Inv. Discount Amount", TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");

            if (i = 2) and PartialInvoicing then
                if IndexNo[i] = 1 then begin
                    InvDiscBaseAmount := TempVATAmountLine2.GetTotalInvDiscBaseAmount(false, TotalServLine[IndexNo[i]]."Currency Code");
                    if InvDiscBaseAmount = 0 then
                        TempVATAmountLine1.SetInvoiceDiscountPercent(
                          0, TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                    else
                        TempVATAmountLine1.SetInvoiceDiscountPercent(
                          100 * TempVATAmountLine2.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                          TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                end else begin
                    InvDiscBaseAmount := TempVATAmountLine1.GetTotalInvDiscBaseAmount(false, TotalServLine[IndexNo[i]]."Currency Code");
                    if InvDiscBaseAmount = 0 then
                        TempVATAmountLine2.SetInvoiceDiscountPercent(
                          0, TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                    else
                        TempVATAmountLine2.SetInvoiceDiscountPercent(
                          100 * TempVATAmountLine1.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                          TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                end;
        end;

        UpdateHeaderInfo(1, TempVATAmountLine1);
        UpdateHeaderInfo(2, TempVATAmountLine2);

        if ModifiedIndexNo = 1 then
            VATLinesForm.SetTempVATAmountLine(TempVATAmountLine1)
        else
            VATLinesForm.SetTempVATAmountLine(TempVATAmountLine2);

        Rec."Invoice Discount Calculation" := Rec."Invoice Discount Calculation"::Amount;
        Rec."Invoice Discount Value" := TotalServLine[1]."Inv. Discount Amount";
        Rec.Modify();

        UpdateVATOnServLines();
    end;

    local procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if Rec."Prices Including VAT" xor ReverseCaption then
            exit('2,1,' + FieldCaption);
        exit('2,0,' + FieldCaption);
    end;

    local procedure UpdateVATOnServLines()
    var
        ServLine: Record "Service Line";
    begin
        GetVATSpecification(ActiveTab);
        if TempVATAmountLine1.GetAnyLineModified() then
            ServLine.UpdateVATOnLines(0, Rec, ServLine, TempVATAmountLine1);
        if TempVATAmountLine2.GetAnyLineModified() then
            ServLine.UpdateVATOnLines(1, Rec, ServLine, TempVATAmountLine2);
        PrevNo := '';
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(CustInvDisc.FindFirst())
    end;

    local procedure CheckAllowInvDisc()
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        if not AllowInvDisc then
            Error(
              Text005,
              CustInvDisc.TableCaption(), Rec.FieldCaption("Invoice Disc. Code"), Rec."Invoice Disc. Code");
    end;

    local procedure GetDetailsTotalAmt(): Decimal
    begin
        if TotalServLineLCY[2].Amount = 0 then
            exit(0);
        exit(Round(100 * (ProfitLCY[2] + ProfitLCY[4]) / TotalServLineLCY[2].Amount, 0.01));
    end;

    local procedure GetAdjDetailsTotalAmt(): Decimal
    begin
        if TotalServLineLCY[2].Amount = 0 then
            exit(0);
        exit(Round(100 * (AdjProfitLCY[2] + AdjProfitLCY[4]) / TotalServLineLCY[2].Amount, 0.01));
    end;

    protected procedure VATLinesDrillDown(var VATLinesToDrillDown: Record "VAT Amount Line"; ThisTabAllowsVATEditing: Boolean)
    begin
        Clear(VATLinesForm);
        VATLinesForm.SetTempVATAmountLine(VATLinesToDrillDown);
        VATLinesForm.InitGlobals(
          Rec."Currency Code", AllowVATDifference, AllowVATDifference and ThisTabAllowsVATEditing,
          Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
        OnVATLinesDrillDownOnBeforeRunVATLinesForm();
        VATLinesForm.RunModal();
        VATLinesForm.GetTempVATAmountLine(VATLinesToDrillDown);
    end;

    local procedure TotalAmount21OnAfterValidate()
    begin
        if Rec."Prices Including VAT" then
            TotalServLine[1]."Inv. Discount Amount" := TotalServLine[1]."Line Amount" - TotalServLine[1]."Amount Including VAT"
        else
            TotalServLine[1]."Inv. Discount Amount" := TotalServLine[1]."Line Amount" - TotalServLine[1].Amount;
        ActiveTab := ActiveTab::General;
        UpdateInvDiscAmount(1);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcTotalAmount()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateHeaderInfo(var TotalServLineLCY: array[7] of Record "Service Line"; var IndexNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcTotalAmount(var TempServLine: Record "Service Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnVATLinesDrillDownOnBeforeRunVATLinesForm()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateHeaderInfoOnAfterCalcTotalAmount2()
    begin
    end;
}
