// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.SalesTax;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Service.Posting;

page 10053 "Service Stats."
{
    Caption = 'Service Stats.';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Service Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("TotalServLine[1].""Line Amount"""; TotalServLine[1]."Line Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Editable = false;
                }
                field("TotalServLine[1].""Inv. Discount Amount"""; TotalServLine[1]."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the service item.';

                    trigger OnValidate()
                    begin
                        UpdateInvDiscAmount(1);
                    end;
                }
                field("TotalServLine[1].Quantity"; TotalServLine[1].Quantity)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the item quantity.';
                }
                field("TotalAmount1[1]"; TotalAmount1[1])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Editable = false;

                    trigger OnValidate()
                    begin
                        UpdateTotalAmount(1);
                    end;
                }
                field(VATAmount; VATAmount[1])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Tax Amount';
                    Editable = false;
                    ToolTip = 'Specifies the tax amount.';
                }
                field("TotalAmount2[1]"; TotalAmount2[1])
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
                field("TotalServLineLCY[1].Amount"; TotalServLineLCY[1].Amount)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Sales ($)';
                    Editable = false;
                    ToolTip = 'Specifies the sales amount, in dollars.';
                }
                field("TotalServLineLCY[1].""Unit Cost (LCY)"""; TotalServLineLCY[1]."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Original Cost ($)';
                    Editable = false;
                    ToolTip = 'Specifies the original cost of the items on the service order.';
                }
                field("ProfitLCY[1]"; ProfitLCY[1])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit ($)';
                    Editable = false;
                    ToolTip = 'Specifies the profit, expressed as an amount.  ';
                }
                field("ProfitPct[1]"; ProfitPct[1])
                {
                    ApplicationArea = Service;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the profit, expressed as a percentage, which was associated with the service item when it was originally posted.';
                }
                field("TotalServLine[1].""Units per Parcel"""; TotalServLine[1]."Units per Parcel")
                {
                    ApplicationArea = Service;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the number of parcels on the document.';
                }
                field("TotalServLine[1].""Net Weight"""; TotalServLine[1]."Net Weight")
                {
                    ApplicationArea = Service;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total net weight of items in the service item.';
                }
                field("TotalServLine[1].""Gross Weight"""; TotalServLine[1]."Gross Weight")
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of items listed on the document.';
                }
                field("TotalServLine[1].""Unit Volume"""; TotalServLine[1]."Unit Volume")
                {
                    ApplicationArea = Service;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the volume of the invoiced items.';
                }
                label(BreakdownTitle)
                {
                    CaptionClass = Format(BreakdownTitle);
                    Editable = false;
                }
                field(BreakdownAmt; BreakdownAmt[1, 1])
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1, 1]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt2; BreakdownAmt[1, 2])
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1, 2]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt3; BreakdownAmt[1, 3])
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1, 3]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt4; BreakdownAmt[1, 4])
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1, 4]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
            }
            part(SubForm; "Sales Tax Lines Serv. Subform")
            {
            }
            group("Service Line")
            {
                Caption = 'Service Line';
                label(Control1480055)
                {
                    CaptionClass = Text19041261;
                    ShowCaption = false;
                }
                label(Control1480056)
                {
                    CaptionClass = Text19014898;
                    ShowCaption = false;
                }
                field("TotalServLine[5].Quantity"; TotalServLine[5].Quantity)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the item quantity.';
                }
                label(Control1480057)
                {
                    CaptionClass = Text19016980;
                    ShowCaption = false;
                }
                field("TotalServLine[6].Quantity"; TotalServLine[6].Quantity)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the item quantity.';
                }
                field("TotalServLine[5].""Line Amount"""; TotalServLine[5]."Line Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Editable = false;
                    ShowCaption = false;
                }
                field("TotalServLine[6].""Line Amount"""; TotalServLine[6]."Line Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Editable = false;
                    ShowCaption = false;
                }
                field("TotalServLine[5].""Inv. Discount Amount"""; TotalServLine[5]."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the service item.';
                }
                field("TotalServLine[6].""Inv. Discount Amount"""; TotalServLine[6]."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the service item.';
                }
                field("TotalAmount1[5]"; TotalAmount1[5])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Editable = false;
                    ShowCaption = false;
                }
                field("TotalAmount1[6]"; TotalAmount1[6])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Editable = false;
                    ShowCaption = false;
                }
                field("VATAmount[5]"; VATAmount[5])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[1]);
                    Editable = false;
                    ShowCaption = false;
                }
                field("TotalAmount2[5]"; TotalAmount2[5])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Editable = false;
                    ShowCaption = false;
                }
                field("TotalServLineLCY[5].Amount"; TotalServLineLCY[5].Amount)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the sales amount, in local currency.';
                }
                field("ProfitLCY[5]"; ProfitLCY[5])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the profit, expressed as an amount in local currency, which was associated with the service  item, when it was originally posted.';
                }
                field("AdjProfitLCY[5]"; AdjProfitLCY[5])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the adjusted profit, in local currency.';
                }
                field("ProfitPct[5]"; ProfitPct[5])
                {
                    ApplicationArea = Service;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the profit, expressed as a percentage, which was associated with the service item when it was originally posted.';
                }
                field("AdjProfitPct[5]"; AdjProfitPct[5])
                {
                    ApplicationArea = Service;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the adjusted profit of the contents of the entire service order, in local currency.';
                }
                field("TotalServLineLCY[5].""Unit Cost (LCY)"""; TotalServLineLCY[5]."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the original cost of the items on the service order.';
                }
                field("TotalAdjCostLCY[5]"; TotalAdjCostLCY[5])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the adjusted cost of the service order, in local currency.';
                }
                field("TotalAdjCostLCY[5] - TotalServLineLCY[5].""Unit Cost (LCY)"""; TotalAdjCostLCY[5] - TotalServLineLCY[5]."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the cost adjustment amount, in local currency.';

                    trigger OnDrillDown()
                    begin
                        Rec.LookupAdjmtValueEntries(1);
                    end;
                }
                field("TotalServLine[7].Quantity"; TotalServLine[7].Quantity)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the item quantity.';
                }
                field("TotalServLine[7].""Line Amount"""; TotalServLine[7]."Line Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Editable = false;
                    ShowCaption = false;
                }
                field("TotalServLine[7].""Inv. Discount Amount"""; TotalServLine[7]."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the service item.';
                }
                field("TotalAmount1[7]"; TotalAmount1[7])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Editable = false;
                    ShowCaption = false;
                }
                field("VATAmount[6]"; VATAmount[6])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[1]);
                    Editable = false;
                    ShowCaption = false;
                }
                field("VATAmount[7]"; VATAmount[7])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[1]);
                    Editable = false;
                    ShowCaption = false;
                }
                field("TotalAmount2[6]"; TotalAmount2[6])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Editable = false;
                    ShowCaption = false;
                }
                field("TotalAmount2[7]"; TotalAmount2[7])
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Editable = false;
                    ShowCaption = false;
                }
                field("TotalServLineLCY[6].Amount"; TotalServLineLCY[6].Amount)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount of the service items, in local currency.';
                }
                field("TotalServLineLCY[7].Amount"; TotalServLineLCY[7].Amount)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount of the service items, in local currency.';
                }
                field("ProfitLCY[6]"; ProfitLCY[6])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the profit in LCY.';
                }
                field("ProfitLCY[7]"; ProfitLCY[7])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the profit in LCY.';
                }
                field("AdjProfitLCY[6]"; AdjProfitLCY[6])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the profit in LCY.';
                }
                field("AdjProfitLCY[7]"; AdjProfitLCY[7])
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the profit in LCY.';
                }
                field("ProfitPct[6]"; ProfitPct[6])
                {
                    ApplicationArea = Service;
                    Caption = 'Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the profit, expressed as a percentage.  ';
                }
                field("ProfitPct[7]"; ProfitPct[7])
                {
                    ApplicationArea = Service;
                    Caption = 'Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the profit, expressed as a percentage.  ';
                }
                field("TotalServLineLCY[6].""Unit Cost (LCY)"""; TotalServLineLCY[6]."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the cost of the service item, in local currency.';
                }
                field("TotalServLineLCY[7].""Unit Cost (LCY)"""; TotalServLineLCY[7]."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the cost of the service item, in local currency.';
                }
            }
            group(Customer)
            {
                Caption = 'Customer';
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Balance ($)';
                    Editable = false;
                    ToolTip = 'Specifies the customer''s balance. ';
                }
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit ($)';
                    Editable = false;
                    ToolTip = 'Specifies the customer''s credit limit, in dollars.';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Service;
                    Caption = 'Expended % of Credit Limit ($)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the Expended Percentage of Credit Limit ($).';
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
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
    begin
        CurrPage.Caption(StrSubstNo(Text000, Rec."Document Type"));

        if PrevNo = Rec."No." then
            exit;
        PrevNo := Rec."No.";
        Rec.FilterGroup(2);
        Rec.SetRange("No.", PrevNo);
        Rec.FilterGroup(0);

        ClearObjects(ServLine, TotalServLine, TotalServLineLCY, ServAmtsMgt, BreakdownLabel, BreakdownAmt);

        for i := 1 to 7 do begin
            TempServLine.DeleteAll();
            Clear(TempServLine);
            ServAmtsMgt.GetServiceLines(Rec, TempServLine, i - 1);
            ServSalesTaxCalculate.StartSalesTaxCalculation();
            if not TaxArea."Use External Tax Engine" then begin
                TempServLine.SetFilter(Type, '>0');
                TempServLine.SetFilter(Quantity, '<>0');
                if TempServLine.Find('-') then
                    repeat
                        ServSalesTaxCalculate.AddServiceLine(TempServLine);
                    until TempServLine.Next() = 0;
            end;
            OnAfterCalculateSalesTax(
              SalesTaxCalculationOverridden, Rec, TempServLine, i, TempSalesTaxLine1, TempSalesTaxLine2, TempSalesTaxLine3, TempSalesTaxAmtLine);
            if not SalesTaxCalculationOverridden then
                case i of
                    1:
                        begin
                            TempSalesTaxLine1.DeleteAll();
                            if TaxArea."Use External Tax Engine" then
                                ServSalesTaxCalculate.CallExternalTaxEngineForServ(Rec, true)
                            else
                                ServSalesTaxCalculate.EndSalesTaxCalculation(Rec."Posting Date");
                            ServSalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine1);
                        end;
                    2:
                        begin
                            TempSalesTaxLine2.DeleteAll();
                            if TaxArea."Use External Tax Engine" then
                                ServSalesTaxCalculate.CallExternalTaxEngineForServ(Rec, true)
                            else
                                ServSalesTaxCalculate.EndSalesTaxCalculation(Rec."Posting Date");
                            ServSalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine2);
                        end;
                    3:
                        begin
                            TempSalesTaxLine3.DeleteAll();
                            if TaxArea."Use External Tax Engine" then
                                ServSalesTaxCalculate.CallExternalTaxEngineForServ(Rec, true)
                            else
                                ServSalesTaxCalculate.EndSalesTaxCalculation(Rec."Posting Date");
                            ServSalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine3);
                        end;
                end;

            ServAmtsMgt.SumServiceLinesTemp(
              Rec, TempServLine, i - 1, TotalServLine[i], TotalServLineLCY[i],
              VATAmount[i], VATAmountText[i], ProfitLCY[i], ProfitPct[i], TotalAdjCostLCY[i]);
            // IF Status = Status::Open THEN
            ServSalesTaxCalculate.DistTaxOverServLines(TempServLine);
            // SalesPost.SumSalesLinesTemp(
            // Rec,TempSalesLine,i - 1,TotalServLine[i],TotalServLineLCY[i],
            // VATAmount[i],VATAmountText[i],ProfitLCY[i],ProfitPct[i],TotalAdjCostLCY[i]);
            if i = 3 then
                TotalAdjCostLCY[i] := TotalServLineLCY[i]."Unit Cost (LCY)";

            AdjProfitLCY[i] := TotalServLineLCY[i].Amount - TotalAdjCostLCY[i];
            if TotalServLineLCY[i].Amount <> 0 then
                AdjProfitPct[i] := Round(AdjProfitLCY[i] / TotalServLineLCY[i].Amount * 100, 0.1);
            TotalAmount1[i] := TotalServLine[i].Amount;
            TotalAmount2[i] := TotalAmount1[i];
            VATAmount[i] := 0;

            if not SalesTaxCalculationOverridden then
                ServSalesTaxCalculate.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);

            BrkIdx := 0;
            PrevPrintOrder := 0;
            PrevTaxPercent := 0;
            if TaxArea."Country/Region" = TaxArea."Country/Region"::CA then
                BreakdownTitle := Text1020010
            else
                BreakdownTitle := Text1020011;
            TempSalesTaxAmtLine.Reset();
            TempSalesTaxAmtLine.SetCurrentKey("Print Order", "Tax Area Code for Key", "Tax Jurisdiction Code");
            if TempSalesTaxAmtLine.Find('-') then
                repeat
                    if (TempSalesTaxAmtLine."Print Order" = 0) or
                       (TempSalesTaxAmtLine."Print Order" <> PrevPrintOrder) or
                       (TempSalesTaxAmtLine."Tax %" <> PrevTaxPercent)
                    then begin
                        BrkIdx := BrkIdx + 1;
                        if BrkIdx > ArrayLen(BreakdownAmt) then begin
                            BrkIdx := BrkIdx - 1;
                            BreakdownLabel[i, BrkIdx] := Text1020012;
                        end else
                            BreakdownLabel[i, BrkIdx] := CopyStr(StrSubstNo(TempSalesTaxAmtLine."Print Description", TempSalesTaxAmtLine."Tax %"), 1, MaxStrLen(BreakdownLabel[i, BrkIdx]));
                    end;
                    BreakdownAmt[i, BrkIdx] := BreakdownAmt[i, BrkIdx] + TempSalesTaxAmtLine."Tax Amount";
                    VATAmount[i] := VATAmount[i] + TempSalesTaxAmtLine."Tax Amount";
                until TempSalesTaxAmtLine.Next() = 0;
            TotalAmount2[i] := TotalAmount2[i] + VATAmount[i];
            OnAfterCalculateSalesTaxValidate(i);
        end;
        TempServLine.DeleteAll();
        Clear(TempServLine); // ?????

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

        TempSalesTaxLine1.ModifyAll(Modified, false);
        TempSalesTaxLine2.ModifyAll(Modified, false);
        TempSalesTaxLine3.ModifyAll(Modified, false);

        PrevTab := NullTab;
        SetVATSpecification(ActiveTab);

        SubformIsReady := true;
        OnActivateForm();
    end;

    trigger OnOpenPage()
    begin
        SalesSetup.Get();
        NullTab := -1;
        AllowInvDisc := not (SalesSetup."Calc. Inv. Discount" and CustInvDiscRecExists(Rec."Invoice Disc. Code"));
        AllowVATDifference :=
          SalesSetup."Allow VAT Difference" and
          not (Rec."Document Type" in [Rec."Document Type"::Quote]);
        SubformIsEditable := AllowVATDifference or AllowInvDisc or (Rec."Tax Area Code" <> '');
        CurrPage.Editable := SubformIsEditable;
        TaxArea.Get(Rec."Tax Area Code");
        SetVATSpecification(ActiveTab);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification(PrevTab);
        if TempSalesTaxLine1.GetAnyLineModified() or TempSalesTaxLine2.GetAnyLineModified() then
            UpdateTaxonServLines();
        exit(true);
    end;

    var
        Text000: Label 'Service %1 Statistics';
        Text001: Label 'Total';
        Text002: Label 'Amount';
        Text003: Label '%1 must not be 0.';
        Text004: Label '%1 must not be greater than %2.';
        Text005: Label 'You cannot change the invoice discount because there is a %1 record for %2 %3.';
        TotalServLine: array[7] of Record "Service Line";
        TotalServLineLCY: array[7] of Record "Service Line";
        Cust: Record Customer;
        TempSalesTaxLine1: Record "Sales Tax Amount Line" temporary;
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        TempSalesTaxLine3: Record "Sales Tax Amount Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        SalesTaxDifference: Record "Sales Tax Amount Difference";
        TaxArea: Record "Tax Area";
        ServSalesTaxCalculate: Codeunit "Serv. Sales Tax Calculate";
        ServAmtsMgt: Codeunit "Serv-Amounts Mgt.";
        VATLinesForm: Page "Sales Tax Lines Subform";
        TotalAmount1: array[7] of Decimal;
        TotalAmount2: array[7] of Decimal;
        VATAmount: array[7] of Decimal;
        VATAmountText: array[7] of Text[30];
        ProfitLCY: array[7] of Decimal;
        ProfitPct: array[7] of Decimal;
        AdjProfitLCY: array[7] of Decimal;
        AdjProfitPct: array[7] of Decimal;
        TotalAdjCostLCY: array[7] of Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        i: Integer;
        PrevNo: Code[20];
        ActiveTab: Option General,Invoicing,Shipping,Prepayment;
        PrevTab: Option General,Invoicing,Shipping;
        NullTab: Integer;
        SubformIsReady: Boolean;
        SubformIsEditable: Boolean;
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;
        BreakdownTitle: Text[35];
        BreakdownLabel: array[3, 4] of Text[30];
        BreakdownAmt: array[3, 4] of Decimal;
        BrkIdx: Integer;
        Text1020010: Label 'Tax Breakdown:';
        Text1020011: Label 'Sales Tax Breakdown:';
        Text1020012: Label 'Other Taxes';
        Text19041261: Label 'Items';
        Text19014898: Label 'Resources';
        Text19016980: Label 'Costs && G/L Accounts';
        SalesTaxCalculationOverridden: Boolean;

    local procedure UpdateHeaderInfo(IndexNo: Integer; var SalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalServLine[IndexNo]."Inv. Discount Amount" := SalesTaxAmountLine.GetTotalInvDiscAmount();
        TotalAmount1[IndexNo] :=
          TotalServLine[IndexNo]."Line Amount" - TotalServLine[IndexNo]."Inv. Discount Amount";
        VATAmount[IndexNo] := SalesTaxAmountLine.GetTotalTaxAmountFCY();
        if Rec."Prices Including VAT" then
            TotalAmount2[IndexNo] := TotalServLine[IndexNo].Amount
        else
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] + VATAmount[IndexNo];

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
            ProfitPct[IndexNo] := Round(100 * ProfitLCY[IndexNo] / TotalServLineLCY[IndexNo].Amount, 0.01);

        AdjProfitLCY[IndexNo] := TotalServLineLCY[IndexNo].Amount - TotalAdjCostLCY[IndexNo];
        if TotalServLineLCY[IndexNo].Amount = 0 then
            AdjProfitPct[IndexNo] := 0
        else
            AdjProfitPct[IndexNo] := Round(100 * AdjProfitLCY[IndexNo] / TotalServLineLCY[IndexNo].Amount, 0.01);
    end;

    local procedure GetVATSpecification(QtyType: Option General,Invoicing,Shipping)
    begin
        case QtyType of
            QtyType::General:
                begin
                    CurrPage.SubForm.PAGE.GetTempTaxAmountLine(TempSalesTaxLine1);
                    UpdateHeaderInfo(1, TempSalesTaxLine1);
                end;
            QtyType::Invoicing:
                begin
                    CurrPage.SubForm.PAGE.GetTempTaxAmountLine(TempSalesTaxLine2);
                    UpdateHeaderInfo(2, TempSalesTaxLine2);
                end;
            QtyType::Shipping:
                CurrPage.SubForm.PAGE.GetTempTaxAmountLine(TempSalesTaxLine3);
        end;
    end;

    local procedure SetVATSpecification(QtyType: Option General,Invoicing,Shipping,Prepayment)
    begin
        if not SubformIsReady then
            exit;

        ActiveTab := QtyType;

        if PrevTab >= 0 then
            GetVATSpecification(PrevTab);
        PrevTab := ActiveTab;

        case QtyType of
            QtyType::General:
                begin
                    CurrPage.SubForm.PAGE.SetTempTaxAmountLine(TempSalesTaxLine1);
                    CurrPage.SubForm.PAGE.InitGlobals(
                      Rec."Currency Code", AllowVATDifference, false,
                      Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
                end;
            QtyType::Invoicing:
                begin
                    CurrPage.SubForm.PAGE.SetTempTaxAmountLine(TempSalesTaxLine2);
                    CurrPage.SubForm.PAGE.InitGlobals(
                      Rec."Currency Code", AllowVATDifference, AllowVATDifference,
                      Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
                end;
            QtyType::Shipping:
                CurrPage.SubForm.PAGE.SetTempTaxAmountLine(TempSalesTaxLine3);
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
            InvDiscBaseAmount := TempSalesTaxLine1.GetTotalInvDiscBaseAmount(false, Rec."Currency Code")
        else
            InvDiscBaseAmount := TempSalesTaxLine2.GetTotalInvDiscBaseAmount(false, Rec."Currency Code");

        if InvDiscBaseAmount = 0 then
            Error(Text003, TempSalesTaxLine2.FieldCaption("Inv. Disc. Base Amount"));

        if TotalServLine[ModifiedIndexNo]."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalServLine[ModifiedIndexNo].FieldCaption("Inv. Discount Amount"),
              TempSalesTaxLine2.FieldCaption("Inv. Disc. Base Amount"));

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
                    TempSalesTaxLine1.SetInvoiceDiscountAmount(
                      TotalServLine[IndexNo[i]]."Inv. Discount Amount", TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %")
                else
                    TempSalesTaxLine2.SetInvoiceDiscountAmount(
                      TotalServLine[IndexNo[i]]."Inv. Discount Amount", TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");

            if (i = 2) and PartialInvoicing then
                if IndexNo[i] = 1 then begin
                    InvDiscBaseAmount := TempSalesTaxLine2.GetTotalInvDiscBaseAmount(false, TotalServLine[IndexNo[i]]."Currency Code");
                    if InvDiscBaseAmount = 0 then
                        TempSalesTaxLine1.SetInvoiceDiscountPercent(
                          0, TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                    else
                        TempSalesTaxLine1.SetInvoiceDiscountPercent(
                          100 * TempSalesTaxLine2.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                          TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                end else begin
                    InvDiscBaseAmount := TempSalesTaxLine1.GetTotalInvDiscBaseAmount(false, TotalServLine[IndexNo[i]]."Currency Code");
                    if InvDiscBaseAmount = 0 then
                        TempSalesTaxLine2.SetInvoiceDiscountPercent(
                          0, TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                    else
                        TempSalesTaxLine2.SetInvoiceDiscountPercent(
                          100 * TempSalesTaxLine1.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                          TotalServLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                end;
        end;

        UpdateHeaderInfo(1, TempSalesTaxLine1);
        UpdateHeaderInfo(2, TempSalesTaxLine2);

        if ModifiedIndexNo = 1 then
            VATLinesForm.SetTempTaxAmountLine(TempSalesTaxLine1)
        else
            VATLinesForm.SetTempTaxAmountLine(TempSalesTaxLine2);

        Rec."Invoice Discount Calculation" := Rec."Invoice Discount Calculation"::Amount;
        Rec."Invoice Discount Value" := TotalServLine[1]."Inv. Discount Amount";
        Rec.Modify();

        UpdateTaxonServLines();
    end;

    local procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if Rec."Prices Including VAT" xor ReverseCaption then
            exit('2,1,' + FieldCaption);
        exit('2,0,' + FieldCaption);
    end;

    local procedure UpdateTaxonServLines()
    var
        ServLine: Record "Service Line";
    begin
        GetVATSpecification(ActiveTab);

        ServLine.Reset();
        ServLine.SetRange("Document Type", Rec."Document Type");
        ServLine.SetRange("No.", Rec."No.");
        ServLine.FindFirst();

        if TempSalesTaxLine1.GetAnyLineModified() then begin
            ServSalesTaxCalculate.StartSalesTaxCalculation();
            ServSalesTaxCalculate.PutSalesTaxAmountLineTable(
              TempSalesTaxLine1,
              SalesTaxDifference."Document Product Area"::Service.AsInteger(),
              Rec."Document Type".AsInteger(), Rec."No.");
            ServSalesTaxCalculate.DistTaxOverServLines(ServLine);
            ServSalesTaxCalculate.SaveTaxDifferences();
        end;
        if TempSalesTaxLine2.GetAnyLineModified() then begin
            ServSalesTaxCalculate.StartSalesTaxCalculation();
            ServSalesTaxCalculate.PutSalesTaxAmountLineTable(
              TempSalesTaxLine2,
              SalesTaxDifference."Document Product Area"::Service.AsInteger(),
              Rec."Document Type".AsInteger(), Rec."No.");
            ServSalesTaxCalculate.DistTaxOverServLines(ServLine);
            ServSalesTaxCalculate.SaveTaxDifferences();
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

    procedure VATLinesDrillDown(var VATLinesToDrillDown: Record "Sales Tax Amount Line"; ThisTabAllowsVATEditing: Boolean)
    begin
        Clear(VATLinesForm);
        VATLinesForm.SetTempTaxAmountLine(VATLinesToDrillDown);
        VATLinesForm.InitGlobals(
          Rec."Currency Code", AllowVATDifference, AllowVATDifference and ThisTabAllowsVATEditing,
          Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
        VATLinesForm.RunModal();
        VATLinesForm.GetTempTaxAmountLine(VATLinesToDrillDown);
    end;

    procedure GetDetailsTotal(): Decimal
    begin
        if TotalServLineLCY[2].Amount = 0 then
            exit(0);
        exit(Round(100 * (ProfitLCY[2] + ProfitLCY[4]) / TotalServLineLCY[2].Amount, 0.01));
    end;

    procedure GetAdjDetailsTotal(): Decimal
    begin
        if TotalServLineLCY[2].Amount = 0 then
            exit(0);
        exit(Round(100 * (AdjProfitLCY[2] + AdjProfitLCY[4]) / TotalServLineLCY[2].Amount, 0.01));
    end;

    procedure UpdateHeaderServLine()
    var
        TempServLine: Record "Service Line" temporary;
    begin
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
                    AdjProfitPct[i] := Round(100 * AdjProfitLCY[i] / TotalServLineLCY[i].Amount, 0.1);

                if Rec."Prices Including VAT" then begin
                    TotalAmount2[i] := TotalServLine[i].Amount;
                    TotalAmount1[i] := TotalAmount2[i] + VATAmount[i];
                    TotalServLine[i]."Line Amount" := TotalAmount1[i] + TotalServLine[i]."Inv. Discount Amount";
                end else begin
                    TotalAmount1[i] := TotalServLine[i].Amount;
                    TotalAmount2[i] := TotalServLine[i]."Amount Including VAT";
                end;
            end;
    end;

    local procedure TotalAmount21OnAfterValidate()
    begin
        if Rec."Prices Including VAT" then
            TotalServLine[1]."Inv. Discount Amount" := TotalServLine[1]."Line Amount" - TotalServLine[1]."Amount Including VAT"
        else
            TotalServLine[1]."Inv. Discount Amount" := TotalServLine[1]."Line Amount" - TotalServLine[1].Amount;
        UpdateInvDiscAmount(1);
    end;

    local procedure ClearObjects(var ServiceLine: Record "Service Line"; var TotalServiceLine: array[7] of Record "Service Line"; var TotalServiceLineLCY: array[7] of Record "Service Line"; var ServAmountsMgt: Codeunit "Serv-Amounts Mgt."; BreakdownLabel: array[3, 4] of Text[30]; BreakdownAmt: array[3, 4] of Decimal)
    begin
        Clear(ServiceLine);
        Clear(TotalServiceLine);
        Clear(TotalServiceLineLCY);
        Clear(ServAmountsMgt);
        Clear(BreakdownLabel);
        Clear(BreakdownAmt);
    end;

    local procedure OnActivateForm()
    begin
        SetVATSpecification(ActiveTab);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateSalesTax(var Handled: Boolean; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var i: Integer; var TempSalesTaxAmountLine1: Record "Sales Tax Amount Line" temporary; var TempSalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary; var TempSalesTaxAmountLine3: Record "Sales Tax Amount Line" temporary; var SalesTaxAmountLineParm: Record "Sales Tax Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateSalesTaxValidate(var i: Integer)
    begin
    end;
}

