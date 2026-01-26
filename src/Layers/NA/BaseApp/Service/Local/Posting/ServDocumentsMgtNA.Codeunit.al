// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 10288 "Serv-Documents Mgt. NA"
{
    Permissions = TableData "Service Header" = rimd,
                  TableData "Service Line" = rimd;
    SingleInstance = true;

    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        HeaderTaxArea: Record "Tax Area";
        TempServiceLineForSalesTax: Record "Service Line" temporary;
        TempServiceLineForSpread: Record "Service Line" temporary;
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        ServSalesTaxCalculate: Codeunit "Serv. Sales Tax Calculate";
#if not CLEAN28
        ServDocumentsMgt: Codeunit "Serv-Documents Mgt.";
        ServPostingJournalsMgt: Codeunit "Serv-Posting Journals Mgt.";
#endif
        SalesTaxCalculationOverridden: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        DifferentLineTaxSetupErr: Label 'Every document line must have same VAT Calculation Type.';
        GenProdPostingGroupErr: Label 'You must enter a value in %1 for %2 %3 if you want to post discounts for that line.', Comment = '%1 = field name of Gen. Prod. Posting Group, %2 = field name of Line No., %3 = value of Line No.';
#pragma warning restore AA0074
#pragma warning restore AA0470

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnAfterInitialize', '', false, false)]
    local procedure OnAfterInitialize()
    begin
        TempServiceLineForSalesTax.Reset();
        TempServiceLineForSalesTax.DeleteAll();
        TempSalesTaxAmtLine.Reset();
        TempSalesTaxAmtLine.DeleteAll();
        TempServiceLineForSpread.DeleteAll();
        ClearAll();
        SalesTaxCalculationOverridden := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnBeforePostDocumentLines', '', false, false)]
    local procedure OnBeforePostDocumentLines(var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
    var
        IsHandled: Boolean;
    begin
        if ServHeader."Tax Area Code" <> '' then begin
            HeaderTaxArea.Get(ServHeader."Tax Area Code");
            TestSalesTaxGroup(ServHeader);
        end else
            Clear(HeaderTaxArea);

        SetTaxType(ServHeader, ServLine, Invoice, Ship);

        if ServHeader."Tax Area Code" <> '' then begin
            IsHandled := false;
            OnBeforeCalculateSalesTax(SalesTaxCalculationOverridden, ServHeader, TempServiceLineForSalesTax, TempSalesTaxAmtLine, IsHandled, Ship, Consume, Invoice);
#if not CLEAN28
            ServDocumentsMgt.RunOnBeforeCalculateSalesTax(SalesTaxCalculationOverridden, ServHeader, TempServiceLineForSalesTax, TempSalesTaxAmtLine, IsHandled, Ship, Consume, Invoice);
#endif
            if not IsHandled then
                if not SalesTaxCalculationOverridden then begin
                    if HeaderTaxArea."Use External Tax Engine" then
                        ServSalesTaxCalculate.CallExternalTaxEngineForServ(ServHeader, false)
                    else
                        ServSalesTaxCalculate.EndSalesTaxCalculation(ServHeader."Posting Date");
                    ServSalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxAmtLine);
                    ServSalesTaxCalculate.DistTaxOverServLines(TempServiceLineForSalesTax);
                end;
        end;
    end;

    local procedure SetTaxType(var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; Invoice: Boolean; Ship: Boolean)
    var
        LineTaxArea: Record "Tax Area";
        NoOfLinesToInvoice: Integer;
        NoOfSalesTaxLinesToInvoice: Integer;
        FirstLine: Boolean;
    begin
        // Sales Tax must be calculated on a "whole invoice" basis
        if Invoice or (ServHeader."Document Type" = ServHeader."Document Type"::"Credit Memo") then begin
            ServLine.SetFilter("Qty. to Invoice", '<>0');
            NoOfLinesToInvoice := ServLine.Count();
            ServLine.SetRange("VAT Calculation Type", ServLine."VAT Calculation Type"::"Sales Tax");
            NoOfSalesTaxLinesToInvoice := ServLine.Count();
            if (NoOfLinesToInvoice <> NoOfSalesTaxLinesToInvoice) and (NoOfSalesTaxLinesToInvoice <> 0) then
                Error(DifferentLineTaxSetupErr);

            if NoOfSalesTaxLinesToInvoice > 0 then
                ServHeader."Tax System Type" := ServHeader."Tax System Type"::"Sales Tax";

            ServLine.SetRange("VAT Calculation Type");
            FirstLine := true;
            if ServLine.Find('-') then
                repeat
                    ServLine.TestField(Description);
                    OnPostDocumentLinesOnBeforeSalesTaxLineToSalesTaxCalc(ServLine, ServHeader);
#if not CLEAN28
                    ServDocumentsMgt.RunOnPostDocumentLinesOnBeforeSalesTaxLineToSalesTaxCalc(ServLine, ServHeader);
#endif
                    if (ServLine."Tax Area Code" <> '') and (ServHeader."Tax System Type" = ServHeader."Tax System Type"::"Sales Tax") then begin
                        LineTaxArea.Get(ServLine."Tax Area Code");
                        LineTaxArea.TestField("Country/Region", HeaderTaxArea."Country/Region");
                        LineTaxArea.TestField("Use External Tax Engine", HeaderTaxArea."Use External Tax Engine");
                        AddSalesTaxLineToSalesTaxCalc(ServHeader, ServLine, FirstLine, Ship);
                        FirstLine := false;
                    end;
                until ServLine.Next() = 0;
            ServLine.SetRange("Qty. to Invoice");
        end;
    end;

    local procedure TestSalesTaxGroup(ServHeader: Record "Service Header")
    var
        ServLine2: Record "Service Line";
    begin
        ServLine2.SetRange("Document Type", ServHeader."Document Type");
        ServLine2.SetRange("Document No.", ServHeader."No.");
        ServLine2.SetFilter(Type, '<>%1', ServLine2.Type::" ");
        if ServLine2.FindSet() then
            repeat
                ServLine2.TestField("Tax Group Code");
            // added to compensate for no Release function in Service
            until ServLine2.Next() = 0;
    end;

    local procedure AddSalesTaxLineToSalesTaxCalc(ServHeader: Record "Service Header"; ServLine: Record "Service Line"; FirstLine: Boolean; Ship: Boolean)
    var
        MaxInvQty: Decimal;
        MaxInvQtyBase: Decimal;
    begin
        if FirstLine then begin
            TempServiceLineForSalesTax.Reset();
            TempServiceLineForSalesTax.DeleteAll();
            TempSalesTaxAmtLine.Reset();
            TempSalesTaxAmtLine.DeleteAll();
            ServSalesTaxCalculate.StartSalesTaxCalculation();
        end;
        Currency.Initialize(ServHeader."Currency Code");
        TempServiceLineForSalesTax := ServLine;
        if TempServiceLineForSalesTax."Qty. per Unit of Measure" = 0 then
            TempServiceLineForSalesTax."Qty. per Unit of Measure" := 1;
        if (TempServiceLineForSalesTax."Document Type" = TempServiceLineForSalesTax."Document Type"::Invoice) and (TempServiceLineForSalesTax."Shipment No." <> '') then begin
            TempServiceLineForSalesTax."Quantity Shipped" := TempServiceLineForSalesTax.Quantity;
            TempServiceLineForSalesTax."Qty. Shipped (Base)" := TempServiceLineForSalesTax."Quantity (Base)";
            TempServiceLineForSalesTax."Qty. to Ship" := 0;
            TempServiceLineForSalesTax."Qty. to Ship (Base)" := 0;
        end;

        if TempServiceLineForSalesTax."Document Type" = TempServiceLineForSalesTax."Document Type"::"Credit Memo" then begin
            MaxInvQty := (TempServiceLineForSalesTax."Qty. to Invoice" - TempServiceLineForSalesTax."Quantity Invoiced");
            MaxInvQtyBase := (TempServiceLineForSalesTax."Qty. to Invoice (Base)" - TempServiceLineForSalesTax."Qty. Invoiced (Base)");
        end else begin
            MaxInvQty := (TempServiceLineForSalesTax."Quantity Shipped" - TempServiceLineForSalesTax."Quantity Invoiced");
            MaxInvQtyBase := (TempServiceLineForSalesTax."Qty. Shipped (Base)" - TempServiceLineForSalesTax."Qty. Invoiced (Base)");
            if Ship then begin
                MaxInvQty := MaxInvQty + TempServiceLineForSalesTax."Qty. to Ship";
                MaxInvQtyBase := MaxInvQtyBase + TempServiceLineForSalesTax."Qty. to Ship (Base)";
            end;
        end;
        if Abs(TempServiceLineForSalesTax."Qty. to Invoice") > Abs(MaxInvQty) then begin
            TempServiceLineForSalesTax."Qty. to Invoice" := MaxInvQty;
            TempServiceLineForSalesTax."Qty. to Invoice (Base)" := MaxInvQtyBase;
        end;
        if TempServiceLineForSalesTax.Quantity = 0 then
            TempServiceLineForSalesTax."Inv. Disc. Amount to Invoice" := 0
        else
            TempServiceLineForSalesTax."Inv. Disc. Amount to Invoice" :=
              Round(
                TempServiceLineForSalesTax."Inv. Discount Amount" * TempServiceLineForSalesTax."Qty. to Invoice" / TempServiceLineForSalesTax.Quantity,
                Currency."Amount Rounding Precision");
        TempServiceLineForSalesTax.Quantity := TempServiceLineForSalesTax."Qty. to Invoice";
        TempServiceLineForSalesTax."Quantity (Base)" := TempServiceLineForSalesTax."Qty. to Invoice (Base)";
        TempServiceLineForSalesTax."Line Amount" := Round(TempServiceLineForSalesTax."Qty. to Invoice" * TempServiceLineForSalesTax."Unit Price", Currency."Amount Rounding Precision");
        TempServiceLineForSalesTax."Line Discount Amount" :=
          Round(TempServiceLineForSalesTax."Line Amount" * TempServiceLineForSalesTax."Line Discount %" / 100, Currency."Amount Rounding Precision");
        TempServiceLineForSalesTax."Line Amount" := TempServiceLineForSalesTax."Line Amount" - TempServiceLineForSalesTax."Line Discount Amount";
        TempServiceLineForSalesTax."Inv. Discount Amount" := TempServiceLineForSalesTax."Inv. Disc. Amount to Invoice";
        TempServiceLineForSalesTax.Amount := TempServiceLineForSalesTax."Line Amount" - TempServiceLineForSalesTax."Inv. Discount Amount";
        TempServiceLineForSalesTax."VAT Base Amount" := TempServiceLineForSalesTax.Amount;
        TempServiceLineForSalesTax.Insert();
        if not HeaderTaxArea."Use External Tax Engine" then
            ServSalesTaxCalculate.AddServiceLine(TempServiceLineForSalesTax);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Posting Journals Mgt.", 'OnPostSalesTaxLines', '', false, false)]
    local procedure OnPostSalesTaxLines(var ServHeader: Record "Service Header"; var TotalServiceLineLCY: Record "Service Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; Invoice: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line");
    var
        SalesTaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        if (ServHeader."Tax Area Code" <> '') and (ServHeader."Tax System Type" = ServHeader."Tax System Type"::"Sales Tax") then begin
            PostSalesTaxToGL(ServHeader, TotalServiceLineLCY, InvoicePostingParameters, GenJnlPostLine);
            if Invoice then
                SalesTaxAmountDifference.ClearDocDifference(
                    Enum::"Sales Tax Document Area"::Service.AsInteger(), ServHeader."Document Type".AsInteger(), ServHeader."No.");
        end;
    end;

    local procedure PostSalesTaxToGL(var ServiceHeader: Record "Service Header"; var TotalServiceLineLCY: Record "Service Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        GenJnlLine: Record "Gen. Journal Line";
        TaxLineCount: Integer;
        RemSalesTaxAmt: Decimal;
        RemSalesTaxSrcAmt: Decimal;
        UseDate: Date;
    begin
        TaxLineCount := 0;
        RemSalesTaxAmt := 0;
        RemSalesTaxSrcAmt := 0;
        GLSetup.Get();

        if ServiceHeader."Currency Code" <> '' then
            TotalServiceLineLCY."Amount Including VAT" := TotalServiceLineLCY.Amount;

        if TempSalesTaxAmtLine.IsEmpty() then
            error('No sales tax lines found.');

        if TempSalesTaxAmtLine.Find('-') then
            repeat
                TaxLineCount := TaxLineCount + 1;
                if ((TempSalesTaxAmtLine."Tax Base Amount" <> 0) and
                    (TempSalesTaxAmtLine."Tax Type" = TempSalesTaxAmtLine."Tax Type"::"Sales and Use Tax")) or
                   ((TempSalesTaxAmtLine.Quantity <> 0) and
                    (TempSalesTaxAmtLine."Tax Type" = TempSalesTaxAmtLine."Tax Type"::"Excise Tax"))
                then begin
                    GenJnlLine.Init();
                    GenJnlLine."Posting Date" := ServiceHeader."Posting Date";
                    GenJnlLine."Document Date" := ServiceHeader."Document Date";
                    GenJnlLine."VAT Reporting Date" := ServiceHeader."VAT Reporting Date";
                    GenJnlLine.Description := ServiceHeader."Posting Description";
                    GenJnlLine."Reason Code" := ServiceHeader."Reason Code";
                    GenJnlLine."Document Type" := InvoicePostingParameters."Document Type";
                    GenJnlLine."Document No." := InvoicePostingParameters."Document No.";
                    GenJnlLine."External Document No." := InvoicePostingParameters."External Document No.";
                    GenJnlLine."System-Created Entry" := true;
                    GenJnlLine.Amount := 0;
                    GenJnlLine."Source Currency Code" := ServiceHeader."Currency Code";
                    GenJnlLine."Source Currency Amount" := 0;
                    GenJnlLine.Correction := ServiceHeader.Correction;
                    GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
                    GenJnlLine."Tax Area Code" := TempSalesTaxAmtLine."Tax Area Code";
                    GenJnlLine."Tax Type" := TempSalesTaxAmtLine."Tax Type";
                    GenJnlLine."Tax Exemption No." := ServiceHeader."Tax Exemption No.";
                    GenJnlLine."Tax Group Code" := TempSalesTaxAmtLine."Tax Group Code";
                    GenJnlLine."Tax Liable" := TempSalesTaxAmtLine."Tax Liable";
                    GenJnlLine.Quantity := TempSalesTaxAmtLine.Quantity;
                    GenJnlLine."VAT Calculation Type" := GenJnlLine."VAT Calculation Type"::"Sales Tax";
                    GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                    GenJnlLine."Shortcut Dimension 1 Code" := ServiceHeader."Shortcut Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := ServiceHeader."Shortcut Dimension 2 Code";
                    GenJnlLine."Dimension Set ID" := ServiceHeader."Dimension Set ID";
                    GenJnlLine."Source Code" := InvoicePostingParameters."Source Code";
                    GenJnlLine."EU 3-Party Trade" := ServiceHeader."EU 3-Party Trade";
                    GenJnlLine."Bill-to/Pay-to No." := ServiceHeader."Bill-to Customer No.";
                    GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                    GenJnlLine."Source No." := ServiceHeader."Bill-to Customer No.";
                    GenJnlLine."Posting No. Series" := ServiceHeader."Posting No. Series";
                    GenJnlLine."STE Transaction ID" := ServiceHeader."STE Transaction ID";
                    GenJnlLine."Source Curr. VAT Base Amount" := TempSalesTaxAmtLine."Tax Base Amount";
                    GenJnlLine."VAT Base Amount (LCY)" :=
                      Round(TempSalesTaxAmtLine."Tax Base Amount");
                    GenJnlLine."VAT Base Amount" := GenJnlLine."VAT Base Amount (LCY)";

                    if TaxJurisdiction.Code <> TempSalesTaxAmtLine."Tax Jurisdiction Code" then begin
                        TaxJurisdiction.Get(TempSalesTaxAmtLine."Tax Jurisdiction Code");
                        if HeaderTaxArea."Country/Region" = HeaderTaxArea."Country/Region"::CA then begin
                            RemSalesTaxAmt := 0;
                            RemSalesTaxSrcAmt := 0;
                        end;
                    end;
                    if (ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Quote]) and
                        (ServiceHeader."Posting Date" = 0D)
                    then
                        UseDate := WorkDate()
                    else
                        UseDate := ServiceHeader."Posting Date";
                    if TaxJurisdiction."Unrealized VAT Type" > 0 then begin
                        TaxJurisdiction.TestField("Unreal. Tax Acc. (Sales)");
                        GenJnlLine."Account No." := TaxJurisdiction."Unreal. Tax Acc. (Sales)";
                    end else begin
                        TaxJurisdiction.TestField("Tax Account (Sales)");
                        GenJnlLine."Account No." := TaxJurisdiction."Tax Account (Sales)";
                    end;
                    GenJnlLine."Tax Jurisdiction Code" := TempSalesTaxAmtLine."Tax Jurisdiction Code";
                    if TempSalesTaxAmtLine."Tax Amount" <> 0 then begin
                        RemSalesTaxSrcAmt := RemSalesTaxSrcAmt +
                          CurrExchRate.ExchangeAmtLCYToFCY(
                            UseDate, ServiceHeader."Currency Code", TempSalesTaxAmtLine."Tax Amount", ServiceHeader."Currency Factor");
                        GenJnlLine."Source Curr. VAT Amount" := Round(RemSalesTaxSrcAmt, Currency."Amount Rounding Precision");
                        RemSalesTaxSrcAmt := RemSalesTaxSrcAmt - GenJnlLine."Source Curr. VAT Amount";
                        RemSalesTaxAmt := RemSalesTaxAmt + TempSalesTaxAmtLine."Tax Amount";
                        GenJnlLine."VAT Amount (LCY)" := Round(RemSalesTaxAmt, GLSetup."Amount Rounding Precision");
                        RemSalesTaxAmt := RemSalesTaxAmt - GenJnlLine."VAT Amount (LCY)";
                        GenJnlLine."VAT Amount" := GenJnlLine."VAT Amount (LCY)";
                    end;
                    GenJnlLine."VAT Difference" := TempSalesTaxAmtLine."Tax Difference";

                    if not
                      (ServiceHeader."Document Type" in
                        [ServiceHeader."Document Type"::"Credit Memo"])
                    then begin
                        GenJnlLine."Source Curr. VAT Base Amount" := -GenJnlLine."Source Curr. VAT Base Amount";
                        GenJnlLine."VAT Base Amount (LCY)" := -GenJnlLine."VAT Base Amount (LCY)";
                        GenJnlLine."VAT Base Amount" := -GenJnlLine."VAT Base Amount";
                        GenJnlLine."Source Curr. VAT Amount" := -GenJnlLine."Source Curr. VAT Amount";
                        GenJnlLine."VAT Amount (LCY)" := -GenJnlLine."VAT Amount (LCY)";
                        GenJnlLine."VAT Amount" := -GenJnlLine."VAT Amount";
                        GenJnlLine.Quantity := -GenJnlLine.Quantity;
                        GenJnlLine."VAT Difference" := -GenJnlLine."VAT Difference";
                    end;

                    if ServiceHeader."Currency Code" <> '' then
                        TotalServiceLineLCY."Amount Including VAT" :=
                          TotalServiceLineLCY."Amount Including VAT" + GenJnlLine."VAT Amount (LCY)";

                    OnPostSalesTaxToGLOnBeforeGenJnlPostLineRunWithCheck(GenJnlLine, ServiceHeader, TempSalesTaxAmtLine);
#if not CLEAN28
                    ServPostingJournalsMgt.RunOnPostSalesTaxToGLOnBeforeGenJnlPostLineRunWithCheck(GenJnlLine, ServiceHeader, TempSalesTaxAmtLine);
#endif
                    GenJnlPostLine.RunWithCheck(GenJnlLine);
                end;
            until TempSalesTaxAmtLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTax(var SalesTaxCalculationOverridden: Boolean; var ServiceHeader: Record "Service Header"; var TempServiceLine: Record "Service Line" temporary; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var IsHandled: Boolean; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentLinesOnBeforeSalesTaxLineToSalesTaxCalc(ServiceLine: Record "Service Line" temporary; ServiceHeader: Record "Service Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesTaxToGLOnBeforeGenJnlPostLineRunWithCheck(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Post Invoice Events", 'OnPrepareLineOnAfterGetGenPostingSetup', '', false, false)]
    local procedure OnPrepareLineOnAfterGetGenPostingSetup(ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var GenPostingSetup: Record "General Posting Setup")
    begin
        GetGenPostingSetupForServiceLine(ServiceLine, GenPostingSetup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnPostDocumentLinesOnAfterCheckCloseCondition', '', false, false)]
    local procedure OnPostDocumentLinesOnAfterCheckCloseCondition(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceItemLine: Record "Service Item Line")
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GetGenPostingSetupForServiceLine(ServiceLine, GenPostingSetup);
    end;

    local procedure GetGenPostingSetupForServiceLine(var ServiceLine: Record "Service Line"; var GenPostingSetup: Record "General Posting Setup")
    begin
        GLSetup.Get();
        SalesSetup.Get();
        if not GLSetup.UseVat() then
            if (ServiceLine.Type.AsInteger() >= ServiceLine.Type::Item.AsInteger()) and
                ((ServiceLine."Qty. to Invoice" <> 0) or (ServiceLine."Qty. to Ship" <> 0))
            then
                if ServiceLine.Type = ServiceLine.Type::"G/L Account" then
                    if (((SalesSetup."Discount Posting" = SalesSetup."Discount Posting"::"Invoice Discounts") and
                            (ServiceLine."Inv. Discount Amount" <> 0)) or
                        ((SalesSetup."Discount Posting" = SalesSetup."Discount Posting"::"Line Discounts") and
                            (ServiceLine."Line Discount Amount" <> 0)) or
                        ((SalesSetup."Discount Posting" = SalesSetup."Discount Posting"::"All Discounts") and
                            ((ServiceLine."Inv. Discount Amount" <> 0) or (ServiceLine."Line Discount Amount" <> 0))))
                    then begin
                        if not GenPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group") then
                            if ServiceLine."Gen. Prod. Posting Group" = '' then
                                Error(
                                    GenProdPostingGroupErr,
                                    ServiceLine.FieldCaption(ServiceLine."Gen. Prod. Posting Group"), ServiceLine.FieldCaption(ServiceLine."Line No."), ServiceLine."Line No.")
                            else
                                GenPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group");
                    end else
                        Clear(GenPostingSetup)
                else
                    if (ServiceLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
                       (ServiceLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                    then
                        GenPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnFinalizeOnAfterFinalizeDocuments', '', false, false)]
    local procedure OnFinalizeOnAfterFinalizeDocuments(var ServiceHeader: Record "Service Header"; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceInvoiceLine: Record "Service Invoice Line"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceCrMemoLine: Record "Service Cr.Memo Line"; Invoice: Boolean)
    begin
        if SalesTaxCalculationOverridden then
            OnFinalize(ServiceHeader, ServiceInvoiceHeader, ServiceInvoiceLine, ServiceCrMemoHeader, ServiceCrMemoLine, Invoice);
#if not CLEAN28
        if SalesTaxCalculationOverridden then
            OnFinalize(ServiceHeader, ServiceInvoiceHeader, ServiceInvoiceLine, ServiceCrMemoHeader, ServiceCrMemoLine, Invoice);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalize(var ServiceHeader: Record "Service Header"; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceInvoiceLine: Record "Service Invoice Line"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceCrMemoLine: Record "Service Cr.Memo Line"; IsInvoice: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnCheckAndSetPostingConstantsOnBeforeCalcPassedInvoice', '', false, false)]
    local procedure OnCheckAndSetPostingConstantsOnBeforeCalcPassedInvoice(var ServiceHeader: Record "Service Header")
    begin
        if SalesTaxCalculationOverridden then
            OnCheckAndSetPostingConstants(ServiceHeader);
#if not CLEAN28
        if SalesTaxCalculationOverridden then
            ServDocumentsMgt.RunOnCheckAndSetPostingConstants(ServiceHeader);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndSetPostingConstants(var ServiceHeader: Record "Service Header")
    begin
    end;

    procedure GetUseExternalTaxEngine(): Boolean
    begin
        exit(HeaderTaxArea."Use External Tax Engine");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Amounts Mgt.", 'OnDivideAmountOnSalesTaxCalculation', '', false, false)]
    local procedure OnDivideAmountOnSalesTaxCalculation(var ServiceLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping; ServLineQty: Decimal)
    begin
        if (QtyType = QtyType::Invoicing) and
            TempServiceLineForSalesTax.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.")
        then begin
            ServiceLine."Line Amount" := TempServiceLineForSalesTax."Line Amount";
            ServiceLine."Line Discount Amount" := TempServiceLineForSalesTax."Line Discount Amount";
            ServiceLine.Amount := TempServiceLineForSalesTax.Amount;
            ServiceLine."Amount Including VAT" := TempServiceLineForSalesTax."Amount Including VAT";
            ServiceLine."Inv. Discount Amount" := TempServiceLineForSalesTax."Inv. Discount Amount";
            ServiceLine."VAT Base Amount" := TempServiceLineForSalesTax."VAT Base Amount";
        end else begin
            ServiceLine."Line Amount" := Round(ServLineQty * ServiceLine."Unit Price", Currency."Amount Rounding Precision");
            ServiceLine."Line Discount Amount" :=
                Round(ServiceLine."Line Amount" * ServiceLine."Line Discount %" / 100, Currency."Amount Rounding Precision");
            ServiceLine."Line Amount" := ServiceLine."Line Amount" - ServiceLine."Line Discount Amount";
            if ServiceLine."Allow Invoice Disc." then
                if QtyType = QtyType::Invoicing then
                    ServiceLine."Inv. Discount Amount" := ServiceLine."Inv. Disc. Amount to Invoice"
                else begin
                    TempServiceLineForSpread."Inv. Discount Amount" :=
                        TempServiceLineForSpread."Inv. Discount Amount" +
                        ServiceLine."Inv. Discount Amount" * Abs(ServLineQty / ServiceLine.Quantity);
                    ServiceLine."Inv. Discount Amount" :=
                        Round(TempServiceLineForSpread."Inv. Discount Amount", Currency."Amount Rounding Precision");
                    TempServiceLineForSpread."Inv. Discount Amount" :=
                        TempServiceLineForSpread."Inv. Discount Amount" - ServiceLine."Inv. Discount Amount";
                end;
            ServiceLine.Amount := ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount";
            ServiceLine."VAT Base Amount" := ServiceLine.Amount;
            ServiceLine."Amount Including VAT" := ServiceLine.Amount;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Amounts Mgt.", 'OnDivideAmountOnAfterGetTempVATAmountLine', '', false, false)]
    local procedure OnDivideAmountOnAfterGetTempVATAmountLine(var ServiceLine: Record "Service Line"; var TempVATAmountLine: Record "VAT Amount Line")
    begin
        if TempVATAmountLine.Get(ServiceLine."VAT Identifier", ServiceLine."VAT Calculation Type", ServiceLine."Tax Group Code", '', false, ServiceLine."Line Amount" >= 0) then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnPostDocumentLinesOnAfterReverseAmount', '', false, false)]
    local procedure OnPostDocumentLinesOnAfterReverseAmount(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header")
    var
        ServAmountsMgt: Codeunit "Serv-Amounts Mgt.";
    begin
        if (ServiceHeader."Tax Area Code" <> '') and (ServiceHeader."Tax System Type" = ServiceHeader."Tax System Type"::"Sales Tax") then
            if TempServiceLineForSalesTax.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.") then begin
                ServAmountsMgt.ReverseAmount(TempServiceLineForSalesTax);
                TempServiceLineForSalesTax.Modify();
            end;
    end;

    internal procedure SetTempServiceLineForSalesTax(var TempServiceLineForSalesTax2: Record "Service Line" temporary)
    begin
        TempServiceLineForSalesTax := TempServiceLineForSalesTax2;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnAfterPostServiceDoc', '', false, false)]
    local procedure OnAfterPostServiceDoc(var ServiceHeader: Record "Service Header"; Invoice: Boolean)
    begin
        if Invoice and HeaderTaxArea."Use External Tax Engine" then
            if ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Order, ServiceHeader."Document Type"::Invoice] then
                SalesTaxCalculate.FinalizeExternalTaxCalcForDoc(DATABASE::"Service Invoice Header", ServiceHeader."Last Posting No.")
            else
                SalesTaxCalculate.FinalizeExternalTaxCalcForDoc(DATABASE::"Service Cr.Memo Header", ServiceHeader."Last Posting No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnAfterInitialize', '', false, false)]
    local procedure ServicePostOnAfterInitialize(var ServiceHeader: Record "Service Header")
    begin
        GLSetup.Get();
        if GLSetup."PAC Environment" <> GLSetup."PAC Environment"::Disabled then
            ServiceHeader.TestField(ServiceHeader."Payment Method Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnAfterFinalizePostingOnBeforeCommit', '', false, false)]
    local procedure OnAfterFinalizePostingOnBeforeCommit(var ServiceHeader: Record "Service Header"; ServInvoiceNo: Code[20]; ServCrMemoNo: Code[20])
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        EInvoiceMgt.InsertServiceInvoiceCFDIRelations(ServiceHeader, ServInvoiceNo);
        EInvoiceMgt.InsertServiceCreditMemoCFDIRelations(ServiceHeader, ServCrMemoNo);
    end;
}
