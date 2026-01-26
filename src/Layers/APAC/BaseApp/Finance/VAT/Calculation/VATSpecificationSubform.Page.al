// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using System.Reflection;

/// <summary>
/// Subform displaying VAT specification lines with detailed VAT breakdown and calculation information.
/// Provides read-only view of VAT amounts, bases, and percentages for document analysis and reporting.
/// </summary>
/// <remarks>
/// Used as part page in various document forms to show VAT details.
/// Supports integration with sales, purchase, and service documents for VAT transparency.
/// </remarks>
page 576 "VAT Specification Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Amount Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("VAT Identifier"; Rec."VAT Identifier")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the contents of this field from the VAT Identifier field in the VAT Posting Setup table.';
                    Visible = false;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT percentage that was used on the sales or purchase lines with this VAT Identifier.';
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total amount for sales or purchase lines with a specific VAT identifier.';
                }
                field("Inv. Disc. Base Amount"; Rec."Inv. Disc. Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the invoice discount base amount.';
                    Visible = false;
                }
                field("Invoice Discount Amount"; Rec."Invoice Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Editable = InvoiceDiscountAmountEditable;
                    ToolTip = 'Specifies the invoice discount amount for a specific VAT identifier.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.CalcVATFields(CurrencyCode, PricesIncludingVAT, VATBaseDiscPct);
                        ModifyRec();
                    end;
                }
                field("VAT Base"; Rec."VAT Base")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total net amount (amount excluding VAT) for sales or purchase lines with a specific VAT Identifier.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Editable = VATAmountEditable;
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';

                    trigger OnValidate()
                    begin
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            CheckAmountChange(Rec.FieldCaption("VAT Amount"));

                        CalculateACYVATAmounts();
                    end;
                }
                field("Calculated VAT Amount"; Rec."Calculated VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the calculated VAT amount and is only used for reference when the user changes the VAT Amount manually.';
                    Visible = false;
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the net amount, including VAT, for this line.';

                    trigger OnValidate()
                    begin
                        FormCheckVATDifference();
                    end;
                }
                field(NonDeductibleBase; Rec."Non-Deductible VAT Base")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount of the transaction for which VAT is not applied due to the type of goods or services purchased.';
                    Visible = NonDeductibleVATVisible;
                }
                field(CalcNonDedVATAmount; Rec."Calc. Non-Ded. VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the calculated Non-Deductible VAT amount and is only used for reference when the user changes the Non-Deductible VAT Amount manually.';
                    Visible = false;
                }
                field(NonDeductibleAmount; Rec."Non-Deductible VAT Amount")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount of VAT that is not deducted due to the type of goods or services purchased.';
                    Visible = NonDeductibleVATVisible;
                    Editable = VATAmountEditable;

                    trigger OnValidate()
                    begin
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            CheckAmountChange(Rec.FieldCaption("Non-Deductible VAT Amount"));
                        NonDeductibleVAT.CheckNonDeductibleVATAmountDiff(Rec, xRec, AllowVATDifference, Currency);
                        ModifyRec();
                    end;
                }
                field(DeductibleBase; Rec."Deductible VAT Base")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount of the transaction for which VAT is applied due to the type of goods or services purchased.';
                    Visible = NonDeductibleVATVisible;
                }
                field(DeductibleAmount; Rec."Deductible VAT Amount")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount of VAT that is deducted due to the type of goods or services purchased.';
                    Visible = NonDeductibleVATVisible;
                }
                field("VAT Base (ACY)"; Rec."VAT Base (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net amount (amount excluding VAT) in your additional reporting currency.';
                    Visible = VATBaseACYVisible;
                }
                field("VAT Amount (ACY)"; Rec."VAT Amount (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount in your additional reporting currency.';
                    Visible = "VAT Amount (ACY)Visible";

                    trigger OnValidate()
                    begin
                        Rec."Amount Including VAT (ACY)" := Rec."VAT Amount (ACY)" + Rec."VAT Base (ACY)";
                        FormCheckVATDifference();
                        ModifyRec();
                    end;
                }
                field("Amount Including VAT (ACY)"; Rec."Amount Including VAT (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount including VAT in additional currency.';
                    Visible = AmountIncludingVATACYVisible;
                }
                field("Amount (ACY)"; Rec."Amount (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net amount (excluding VAT) in additional currency.';
                    Visible = "Amount (ACY)Visible";
                }
                field("VAT Difference (ACY)"; Rec."VAT Difference (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT difference for one VAT identifier in your additional reporting currency.';
                    Visible = "VAT Difference (ACY)Visible";
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if MainFormActiveTab = MainFormActiveTab::Other then
            VATAmountEditable := AllowVATDifference and not Rec."Includes Prepayment"
        else
            VATAmountEditable := AllowVATDifference;
        InvoiceDiscountAmountEditable := AllowInvDisc and not Rec."Includes Prepayment";
    end;

    trigger OnInit()
    begin
        "VAT Difference (ACY)Visible" := true;
        "Amount (ACY)Visible" := true;
        AmountIncludingVATACYVisible := true;
        "VAT Amount (ACY)Visible" := true;
        VATBaseACYVisible := true;
        InvoiceDiscountAmountEditable := true;
        VATAmountEditable := true;
        NonDeductibleVATVisible := NonDeductibleVAT.IsNonDeductibleVATEnabled();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ModifyRec();
        exit(false);
    end;

    var
        Currency: Record Currency;
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        SourceHeader: Variant;
        PricesIncludingVAT: Boolean;
        VATBaseDiscPct: Decimal;
        ParentControl: Integer;
        CurrentTabNo: Integer;
        MainFormActiveTab: Option Other,Prepayment;
        PurchHeader1: Record "Purchase Header";
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        AddCurrency: Record Currency;
        CurrencyFactor: Decimal;
        VATAmountEditable: Boolean;
        NonDeductibleVATVisible: Boolean;
        VATBaseACYVisible: Boolean;
        "VAT Amount (ACY)Visible": Boolean;
        AmountIncludingVATACYVisible: Boolean;
        "Amount (ACY)Visible": Boolean;
        "VAT Difference (ACY)Visible": Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 can only be modified on the %2 tab.';
        Text001: Label 'The total %1 for a document must not exceed the value %2 in the %3 field.';
#pragma warning restore AA0470
        Text003: Label 'Invoicing';
#pragma warning restore AA0074

    protected var
        AllowInvDisc, InvoiceDiscountAmountEditable : Boolean;
        AllowVATDifference: Boolean;
        AllowVATDifferenceOnThisTab: Boolean;
        CurrencyCode: Code[10];

    /// <summary>
    /// Sets the VAT amount line data for display in the specification subform.
    /// </summary>
    /// <param name="NewVATAmountLine">VAT amount line record set to display in the subform</param>
    procedure SetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        Rec.DeleteAll();
        if NewVATAmountLine.Find('-') then
            repeat
                Rec.Copy(NewVATAmountLine);
                Rec.Insert();
            until NewVATAmountLine.Next() = 0;
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Retrieves the current VAT amount line data from the specification subform.
    /// </summary>
    /// <param name="NewVATAmountLine">VAT amount line record set to receive the subform data</param>
    procedure GetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        NewVATAmountLine.DeleteAll();
        if Rec.Find('-') then
            repeat
                NewVATAmountLine.Copy(Rec);
                NewVATAmountLine.Insert();
            until Rec.Next() = 0;
    end;

    /// <summary>
    /// Initializes global variables for VAT specification subform display and behavior control.
    /// </summary>
    /// <param name="NewCurrencyCode">Currency code for amount formatting</param>
    /// <param name="NewAllowVATDifference">Whether VAT differences are allowed</param>
    /// <param name="NewAllowVATDifferenceOnThisTab">Whether VAT differences are allowed on current tab</param>
    /// <param name="NewPricesIncludingVAT">Whether prices include VAT</param>
    /// <param name="NewAllowInvDisc">Whether invoice discount is allowed</param>
    /// <param name="NewVATBaseDiscPct">VAT base discount percentage</param>
    procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
        OnBeforeInitGlobals(NewCurrencyCode, NewAllowVATDifference, NewAllowVATDifferenceOnThisTab, NewPricesIncludingVAT, NewAllowInvDisc, NewVATBaseDiscPct);
        CurrencyCode := NewCurrencyCode;
        AllowVATDifference := NewAllowVATDifference;
        AllowVATDifferenceOnThisTab := NewAllowVATDifferenceOnThisTab;
        PricesIncludingVAT := NewPricesIncludingVAT;
        AllowInvDisc := NewAllowInvDisc;
        VATBaseDiscPct := NewVATBaseDiscPct;
        VATAmountEditable := AllowVATDifference;
        InvoiceDiscountAmountEditable := AllowInvDisc;
        Currency.Initialize(CurrencyCode);
        CurrPage.Update(false);
    end;

    procedure ShowGSTAmountACY()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        VATBaseACYVisible := PurchSetup."Enable Vendor GST Amount (ACY)";
        "VAT Amount (ACY)Visible" := PurchSetup."Enable Vendor GST Amount (ACY)";
        AmountIncludingVATACYVisible := PurchSetup."Enable Vendor GST Amount (ACY)";
        "Amount (ACY)Visible" := PurchSetup."Enable Vendor GST Amount (ACY)";
        "VAT Difference (ACY)Visible" := PurchSetup."Enable Vendor GST Amount (ACY)";
        CurrPage.Update(false);
    end;

    local procedure FormCheckVATDifference()
    var
        VATAmountLine2: Record "VAT Amount Line";
        TotalVATDifference: Decimal;
        TotalVATDifferenceACY: Decimal;
        Factor: Decimal;
        ShowVATDifferenceError: Boolean;
    begin
        Rec.CheckVATDifference(CurrencyCode, AllowVATDifference);
        VATAmountLine2 := Rec;
        TotalVATDifference := Abs(Rec."VAT Difference") - Abs(xRec."VAT Difference");
        TotalVATDifferenceACY := Abs(Rec."VAT Difference (ACY)") - Abs(xRec."VAT Difference (ACY)");
        if Rec.Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs(Rec."VAT Difference");
                TotalVATDifferenceACY := TotalVATDifferenceACY + Abs(Rec."VAT Difference (ACY)");
            until Rec.Next() = 0;
        Rec := VATAmountLine2;
        ShowVATDifferenceError := TotalVATDifference > Currency."Max. VAT Difference Allowed";
        OnFormCheckVATDifferenceOnAfterCalcShowVATDifferenceError(Rec, TotalVATDifference, Currency, ShowVATDifferenceError);
        if ShowVATDifferenceError then
            Error(
              Text001, Rec.FieldCaption("VAT Difference"),
              Currency."Max. VAT Difference Allowed", Currency.FieldCaption("Max. VAT Difference Allowed"));

        Factor := PurchHeader1."Vendor Exchange Rate (ACY)";
        if Factor = 0 then
            Factor := 1;
        if TotalVATDifferenceACY > (Currency."Max. VAT Difference Allowed" * Factor) then
            Error(
              Text001, Rec.FieldCaption("VAT Difference (ACY)"),
              Currency."Max. VAT Difference Allowed" * Factor,
              Currency.FieldCaption("Max. VAT Difference Allowed"));
    end;

    local procedure CheckAmountChange(AmountFieldCaption: Text)
    begin
        OnBeforeCheckAmountChange(ParentControl, AmountFieldCaption);
        Error(Text000, AmountFieldCaption, Text003);
    end;

    local procedure ModifyRec()
    begin
        Rec.Modified := true;
        Rec.Modify();

        if SourceHeader.IsRecord() then
            OnAfterModifyRec(SourceHeader, Rec, ParentControl, CurrentTabNo);
    end;

    local procedure CalculateACYVATAmounts()
    var
        SalesHeader: Record "Sales Header";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then
            AddCurrency.Get(GLSetup."Additional Reporting Currency");

        if DataTypeManagement.GetRecordRef(SourceHeader, RecRef) then begin
            if SalesHeader.Get(RecRef.RecordId) then
                UpdateVATAmountACY(SalesHeader."Posting Date", SalesHeader."Currency Code", SalesHeader."Currency Factor", 0)
        end else
            UpdateVATAmountACY(PurchHeader1."Posting Date", PurchHeader1."Currency Code", PurchHeader1."Currency Factor", PurchHeader1."Vendor Exchange Rate (ACY)");

        if PricesIncludingVAT then begin
            Rec."VAT Base" := Rec."Amount Including VAT" - Rec."VAT Amount";
            Rec."VAT Base (ACY)" := Rec."Amount Including VAT (ACY)" - Rec."VAT Amount (ACY)";
        end else begin
            Rec."Amount Including VAT" := Rec."VAT Amount" + Rec."VAT Base";
            Rec."Amount Including VAT (ACY)" := Rec."VAT Amount (ACY)" + Rec."VAT Base (ACY)";
        end;

        FormCheckVATDifference();
        ModifyRec();
    end;

    /// <summary>
    /// Sets the parent control identifier for the VAT specification subform.
    /// </summary>
    /// <param name="ID">Parent control identifier for form integration</param>
    procedure SetParentControl(ID: Integer)
    begin
        ParentControl := ID;
        OnAfterSetParentControl(ParentControl);
    end;

    /// <summary>
    /// Sets the source header record for VAT specification context and integration.
    /// </summary>
    /// <param name="NewSourceHeader">Source header record (sales, purchase, or service header)</param>
    procedure SetSourceHeader(NewSourceHeader: Variant)
    begin
        SourceHeader := NewSourceHeader;
    end;

    /// <summary>
    /// Sets the current tab number for context-aware VAT processing and validation.
    /// </summary>
    /// <param name="TabNo">Tab number identifier for form navigation context</param>
    procedure SetCurrentTabNo(TabNo: Integer)
    begin
        CurrentTabNo := TabNo;
    end;

    local procedure UpdateVATAmountACY(PostingDate: Date; HeaderCurrencyCode: Code[10]; HeaderCurrencyFactor: Decimal; VendorExchangeRateACY: Decimal)
    begin
        if PostingDate = 0D then
            exit;

        if (VendorExchangeRateACY <> 0) and (HeaderCurrencyCode = '') then
            CurrencyFactor :=
              CurrExchRate.ExchangeRateFactorFRS21(
                PostingDate, GLSetup."Additional Reporting Currency", VendorExchangeRateACY)
        else
            CurrencyFactor :=
              CurrExchRate.ExchangeRate(
               PostingDate, GLSetup."Additional Reporting Currency");

        Rec."VAT Amount (ACY)" :=
            Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
                PostingDate, GLSetup."Additional Reporting Currency",
                Round(CurrExchRate.ExchangeAmtFCYToLCY(
                    PostingDate, HeaderCurrencyCode, Rec."VAT Amount",
                    HeaderCurrencyFactor), AddCurrency."Amount Rounding Precision"), CurrencyFactor),
            AddCurrency."Amount Rounding Precision");
        Rec."Calculated VAT Amount (ACY)" :=
            Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                PostingDate, GLSetup."Additional Reporting Currency",
                Round(CurrExchRate.ExchangeAmtFCYToLCY(
                    PostingDate, HeaderCurrencyCode, Rec."Calculated VAT Amount",
                    HeaderCurrencyFactor), AddCurrency."Amount Rounding Precision"), CurrencyFactor),
                AddCurrency."Amount Rounding Precision");
        Rec."VAT Difference (ACY)" := Rec."VAT Amount (ACY)" - Rec."Calculated VAT Amount (ACY)";
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterSetParentControl(var ParentControl: integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnBeforeInitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAmountChange(ParentControl: Integer; AmountFieldCaption: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyRec(var SourceHeader: Variant; var VATAmountLine: Record "VAT Amount Line"; ParentControl: Integer; CurrentTabNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFormCheckVATDifferenceOnAfterCalcShowVATDifferenceError(VATAmountLine: Record "VAT Amount Line"; TotalVATDifference: Decimal; Currency: Record Currency; var ShowVATDifferenceError: Boolean)
    begin
    end;

    [Scope('OnPrem')]
    procedure SetPurchHeader(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader1.Get(PurchHeader."Document Type", PurchHeader."No.");
    end;
}


