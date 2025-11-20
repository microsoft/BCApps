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

page 6030 "Service Statistics"
{
    Caption = 'Service Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
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
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount for the relevant service order.';
                }
                field("Inv. Discount Amount_General"; TotalServLine[1]."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the entire service document.';

                    trigger OnValidate()
                    begin
                        UpdateInvDiscAmount();
                    end;
                }
                field(PmtDiscGivenAmount; TotalServLine[1]."Pmt. Discount Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Pmt. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the payment discount amount that you have granted to customers. ';
                }
                field("TotalAmount1[1]"; TotalAmount1[1])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount on the service lines (including and excluding VAT), VAT part, cost, and profit on the service lines.';

                    trigger OnValidate()
                    begin
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
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the service document.';
                }
                field("Total Incl. VAT_General"; TotalAmount2[1])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Caption = 'Total Incl. VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total amount on the service document, including VAT. This is the amount that will be posted to the customer''s account for all the lines in the service document.';
                }
                field("Sales (LCY)_General"; TotalServLineLCY[1].Amount)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total service sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open service sales invoices and credit memos.';
                }
                field("ProfitLCY[1]"; ProfitLCY[1])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the original profit that was associated with the service document.';
                }
                field("AdjProfitLCY[1]"; AdjProfitLCY[1])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount of profit for the service document, in LCY, adjusted for any changes in the original item costs.';
                }
                field("ProfitPct[1]"; ProfitPct[1])
                {
                    ApplicationArea = Service;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original profit on the service document, expressed as percentage of the amount in the Amount field.';
                }
                field("AdjProfitPct[1]"; AdjProfitPct[1])
                {
                    ApplicationArea = Service;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the adjusted profit on the service document, expressed as percentage of the amount in the Amount field.';
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
                    ToolTip = 'Specifies the total number of parcels in the posted service credit memo.';
                }
#pragma warning disable AA0100
                field("TotalServLine[1].""Net Weight"""; TotalServLine[1]."Net Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the net weight of the items specified on the service lines in the document.';
                }
#pragma warning disable AA0100
                field("TotalServLine[1].""Gross Weight"""; TotalServLine[1]."Gross Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of the items on the service lines in the document.';
                }
#pragma warning disable AA0100
                field("TotalServLine[1].""Unit Volume"""; TotalServLine[1]."Unit Volume")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the volume of the items on the service lines in the document.';
                }
#pragma warning disable AA0100
                field("TotalServLineLCY[1].""Unit Cost (LCY)"""; TotalServLineLCY[1]."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost (in LCY) of the G/L account entries, costs, items and/or resource hours on the service document. The cost is calculated as a product of unit cost multiplied by quantity of the relevant items, resources and/or costs.';
                }
                field("TotalAdjCostLCY[1]"; TotalAdjCostLCY[1])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the service document, adjusted for any changes in the original costs of these items.';
                }
#pragma warning disable AA0100
                field("TotalAdjCostLCY[1] - TotalServLineLCY[1].""Unit Cost (LCY)"""; TotalAdjCostLCY[1] - TotalServLineLCY[1]."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the service document.';

                    trigger OnDrillDown()
                    begin
                        Rec.LookupAdjmtValueEntries(0);
                    end;
                }
            }
            part(SubForm; "VAT Specification Subform")
            {
                ApplicationArea = Service;
            }
            group("Service Line")
            {
                Caption = 'Service Line';
                fixed(Control1904230801)
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
                            ToolTip = 'Specifies the invoice discount amount for the entire service document.';
                        }
                        field(Total; TotalAmount1[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total';
                            Editable = false;
                            ToolTip = 'Specifies the total amount on the service lines (including and excluding VAT), VAT part, cost, and profit on the service lines.';

                            trigger OnValidate()
                            begin
                                UpdateTotalAmount(2);
                            end;
                        }
                        field("VAT Amount_Items"; VATAmount[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'VAT Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the service document.';
                        }
                        field("Total Incl. VAT_Items"; TotalAmount2[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total amount on the service lines including and excluding VAT, VAT part, cost, and profit on the service lines.';
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
                            ToolTip = 'Specifies the original profit that was associated with the service document.';
                        }
                        field("AdjProfitLCY[5]"; AdjProfitLCY[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the amount of profit for the service document, in LCY, adjusted for any changes in the original item costs.';
                        }
                        field("ProfitPct[5]"; ProfitPct[5])
                        {
                            ApplicationArea = Service;
                            Caption = 'Original Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the amount of the original profit on the service document, expressed as percentage of the amount in the Amount field.';
                        }
                        field("AdjProfitPct[5]"; AdjProfitPct[5])
                        {
                            ApplicationArea = Service;
                            Caption = 'Adjusted Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the amount of the adjusted profit on the service document, expressed as percentage of the amount in the Amount field.';
                        }
#pragma warning disable AA0100
                        field("TotalServLineLCY[5].""Unit Cost (LCY)"""; TotalServLineLCY[5]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Original Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost (in LCY) of the G/L account entries, costs, items and/or resource hours on the service document. The cost is calculated as a product of unit cost multiplied by quantity of the relevant items, resources and/or costs.';
                        }
                        field("TotalAdjCostLCY[5]"; TotalAdjCostLCY[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Cost (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total cost, in LCY, of the items in the service document, adjusted for any changes in the original costs of these items.';
                        }
#pragma warning disable AA0100
                        field("TotalAdjCostLCY[5] - TotalServLineLCY[5].""Unit Cost (LCY)"""; TotalAdjCostLCY[5] - TotalServLineLCY[5]."Unit Cost (LCY)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost Adjmt. Amount (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the service document.';

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
                            ToolTip = 'Specifies the invoice discount amount for the entire service document.';
                        }
                        field("TotalAmount1[6]"; TotalAmount1[6])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text001, false);
                            Editable = false;
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                UpdateTotalAmount(2);
                            end;
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
                            ToolTip = 'Specifies the profit related to the service document, in local currency.';
                        }
                        field("AdjProfitLCY[6]"; AdjProfitLCY[6])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the profit related to the service document, in local currency.';
                        }
                        field("ProfitPct[6]"; ProfitPct[6])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the amount of profit as percentage of the invoiced amount.';
                        }
                        field(Text006; Text006)
                        {
                            ApplicationArea = Service;
                            ShowCaption = false;
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
                        field(Control85; Text006)
                        {
                            ApplicationArea = Service;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field(Placeholder2; Text006)
                        {
                            ApplicationArea = Service;
                            ShowCaption = false;
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
                            ToolTip = 'Specifies the invoice discount amount for the entire service document.';
                        }
                        field("TotalAmount1[7]"; TotalAmount1[7])
                        {
                            ApplicationArea = Service;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            CaptionClass = GetCaptionClass(Text001, false);
                            Editable = false;
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                UpdateTotalAmount(2);
                            end;
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
                            ToolTip = 'Specifies the profit related to the service document, in local currency.';
                        }
                        field("AdjProfitLCY[7]"; AdjProfitLCY[7])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the profit related to the service document, in local currency.';
                        }
                        field("ProfitPct[7]"; ProfitPct[7])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            Editable = false;
                            ToolTip = 'Specifies the amount of profit as percentage of the invoiced amount.';
                        }
                        field(Placeholder3; Text006)
                        {
                            ApplicationArea = Service;
                            ShowCaption = false;
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
                        field(Placeholder5; Text006)
                        {
                            ApplicationArea = Service;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field(Placeholder7; Text006)
                        {
                            ApplicationArea = Service;
                            ShowCaption = false;
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
                field("Credit Limit (LCY)"; Cust."Credit Limit (LCY)")
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
        IsHandled: Boolean;
    begin
        CurrPage.Caption(StrSubstNo(Text000, Rec."Document Type"));

        if PrevNo = Rec."No." then begin
            GetVATSpecification();
            exit;
        end;
        PrevNo := Rec."No.";
        Rec.FilterGroup(2);
        Rec.SetRange("No.", PrevNo);
        Rec.FilterGroup(0);

        Clear(ServLine);
        Clear(TotalServLine);
        Clear(TotalServLineLCY);
        Clear(ServAmtsMgt);

        for i := 1 to 7 do
            if i in [1, 5, 6, 7] then begin
                TempServLine.DeleteAll();
                Clear(TempServLine);
                ServAmtsMgt.GetServiceLines(Rec, TempServLine, i - 1);

                ServAmtsMgt.SumServiceLinesTemp(
                  Rec, TempServLine, i - 1, TotalServLine[i], TotalServLineLCY[i],
                  VATAmount[i], VATAmountText[i], ProfitLCY[i], ProfitPct[i], TotalAdjCostLCY[i]);

                if TotalServLineLCY[i].Amount = 0 then
                    ProfitPct[i] := 0
                else
                    ProfitPct[i] := Round(100 * ProfitLCY[i] / TotalServLineLCY[i].Amount, 0.1);

                AdjProfitLCY[i] := TotalServLineLCY[i].Amount - TotalAdjCostLCY[i];
                if TotalServLineLCY[i].Amount <> 0 then
                    AdjProfitPct[i] := Round(AdjProfitLCY[i] / TotalServLineLCY[i].Amount * 100, 0.1);

                IsHandled := false;
                OnAfterGetRecordAfterCalcProfit(Rec, IsHandled);
                if not IsHandled then
                    if Rec."Prices Including VAT" then begin
                        TotalAmount2[i] := TotalServLine[i].Amount;
                        TotalAmount1[i] := TotalAmount2[i] + VATAmount[i];
                        TotalServLine[i]."Line Amount" :=
                            TotalAmount1[i] + TotalServLine[i]."Inv. Discount Amount" + TotalServLine[i]."Pmt. Discount Amount";
                    end else begin
                        TotalAmount1[i] := TotalServLine[i].Amount;
                        TotalAmount2[i] := TotalServLine[i]."Amount Including VAT";
                    end;
            end;

        if Cust.Get(Rec."Bill-to Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);
        if Cust."Credit Limit (LCY)" = 0 then
            CreditLimitLCYExpendedPct := 0
        else
            if Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" < 0 then
                CreditLimitLCYExpendedPct := 0
            else
                if Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" > 1 then
                    CreditLimitLCYExpendedPct := 10000
                else
                    CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);

        TempServLine.DeleteAll();
        Clear(TempServLine);
        ServAmtsMgt.GetServiceLines(Rec, TempServLine, 0);
        ServLine.CalcVATAmountLines(0, Rec, TempServLine, TempVATAmountLine, false);
        TempVATAmountLine.ModifyAll(Modified, false);

        SetVATSpecification();
    end;

    trigger OnOpenPage()
    var
        ServiceCalcDiscount: Codeunit "Service-Calc. Discount";
    begin
#if not CLEAN27
        if not Rec.SkipStatisticsPreparation() then
#endif
            ServiceCalcDiscount.CalculateIncDiscForHeader(Rec);
#if not CLEAN27
        Rec.ResetSkipStatisticsPreparationFlag();
#endif
        SalesSetup.Get();
        AllowInvDisc := not (SalesSetup."Calc. Inv. Discount" and CustInvDiscRecExists(Rec."Invoice Disc. Code"));
        AllowVATDifference := SalesSetup."Allow VAT Difference" and (Rec."Document Type" <> Rec."Document Type"::Quote);
        CurrPage.Editable := AllowVATDifference or AllowInvDisc;
        SetVATSpecification();
        CurrPage.SubForm.PAGE.SetParentControl := PAGE::"Service Statistics";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification();
        if TempVATAmountLine.GetAnyLineModified() then
            UpdateVATOnServLines();
        exit(true);
    end;

    var
        TotalServLine: array[7] of Record "Service Line";
        TotalServLineLCY: array[7] of Record "Service Line";
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        ServAmtsMgt: Codeunit "Serv-Amounts Mgt.";
        TotalAmount1: array[7] of Decimal;
        TotalAmount2: array[7] of Decimal;
        AdjProfitPct: array[7] of Decimal;
        AdjProfitLCY: array[7] of Decimal;
        TotalAdjCostLCY: array[7] of Decimal;
        VATAmount: array[7] of Decimal;
        VATAmountText: array[7] of Text[30];
        ProfitLCY: array[7] of Decimal;
        ProfitPct: array[7] of Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        i: Integer;
        PrevNo: Code[20];
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;

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
        Text006: Label 'Placeholder';
#pragma warning restore AA0074

    local procedure UpdateHeaderInfo(IndexNo: Integer; var VATAmountLine: Record "VAT Amount Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalServLine[IndexNo]."Inv. Discount Amount" := VATAmountLine.GetTotalInvDiscAmount();
        TotalAmount1[IndexNo] :=
          TotalServLine[IndexNo]."Line Amount" - TotalServLine[IndexNo]."Inv. Discount Amount" -
          TotalServLine[IndexNo]."Pmt. Discount Amount";
        VATAmount[IndexNo] := VATAmountLine.GetTotalVATAmount();
        if Rec."Prices Including VAT" then begin
            TotalAmount1[IndexNo] := VATAmountLine.GetTotalAmountInclVAT();
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] - VATAmount[IndexNo];
            TotalServLine[IndexNo]."Line Amount" :=
              TotalAmount1[IndexNo] + TotalServLine[IndexNo]."Inv. Discount Amount" +
              TotalServLine[IndexNo]."Pmt. Discount Amount";
        end else
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] + VATAmount[IndexNo];

        OnUpdateHeaderInfoOnAfterCalcTotalAmount(Rec);

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

    local procedure GetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.GetTempVATAmountLine(TempVATAmountLine);
        UpdateHeaderInfo(1, TempVATAmountLine);
    end;

    local procedure SetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.SetSourceHeader(Rec);
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.SubForm.PAGE.InitGlobals(
          Rec."Currency Code", AllowVATDifference, AllowVATDifference,
          Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
    end;

    local procedure UpdateTotalAmount(IndexNo: Integer)
    var
        SaveTotalAmount: Decimal;
    begin
        CheckAllowInvDisc();
        if Rec."Prices Including VAT" then begin
            SaveTotalAmount := TotalAmount1[IndexNo];
            UpdateInvDiscAmount();
            TotalAmount1[IndexNo] := SaveTotalAmount;
        end;

        TotalServLine[IndexNo]."Inv. Discount Amount" := TotalServLine[IndexNo]."Line Amount" - TotalAmount1[IndexNo];
        UpdateInvDiscAmount();
    end;

    local procedure UpdateInvDiscAmount()
    var
        InvDiscBaseAmount: Decimal;
    begin
        CheckAllowInvDisc();
        InvDiscBaseAmount := TempVATAmountLine.GetTotalInvDiscBaseAmount(false, Rec."Currency Code");
        if InvDiscBaseAmount = 0 then
            Error(Text003, TempVATAmountLine.FieldCaption("Inv. Disc. Base Amount"));

        if TotalServLine[1]."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalServLine[1].FieldCaption("Inv. Discount Amount"),
              TempVATAmountLine.FieldCaption("Inv. Disc. Base Amount"));

        TempVATAmountLine.SetInvoiceDiscountAmount(
          TotalServLine[1]."Inv. Discount Amount", Rec."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");
        UpdateHeaderInfo(1, TempVATAmountLine);
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine);

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
        GetVATSpecification();
        if TempVATAmountLine.GetAnyLineModified() then begin
            ServLine.UpdateVATOnLines(0, Rec, ServLine, TempVATAmountLine);
            ServLine.UpdateVATOnLines(1, Rec, ServLine, TempVATAmountLine);
        end;
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

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateHeaderInfo(var TotalServLineLCY: array[7] of Record "Service Line"; var IndexNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordAfterCalcProfit(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateHeaderInfoOnAfterCalcTotalAmount(var ServiceHeader: Record "Service Header")
    begin
    end;
}
