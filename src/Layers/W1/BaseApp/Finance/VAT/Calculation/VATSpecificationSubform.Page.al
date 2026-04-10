// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.Currency;

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
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                }
                field("Inv. Disc. Base Amount"; Rec."Inv. Disc. Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Visible = false;
                }
                field("Invoice Discount Amount"; Rec."Invoice Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Editable = InvoiceDiscountAmountEditable;
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
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Editable = VATAmountEditable;

                    trigger OnValidate()
                    begin
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            CheckAmountChange(Rec.FieldCaption("VAT Amount"));

                        if PricesIncludingVAT then
                            Rec."VAT Base" := Rec."Amount Including VAT" - Rec."VAT Amount"
                        else
                            Rec."Amount Including VAT" := Rec."VAT Amount" + Rec."VAT Base";

                        FormCheckVATDifference();
                        ModifyRec();
                    end;
                }
                field("Calculated VAT Amount"; Rec."Calculated VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Visible = false;
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;

                    trigger OnValidate()
                    begin
                        FormCheckVATDifference();
                    end;
                }
                field(NonDeductibleBase; Rec."Non-Deductible VAT Base")
                {
                    ApplicationArea = VAT;
                    Visible = NonDeductibleVATVisible;
                }
                field(CalcNonDedVATAmount; Rec."Calc. Non-Ded. VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Visible = false;
                }
                field(NonDeductibleAmount; Rec."Non-Deductible VAT Amount")
                {
                    ApplicationArea = VAT;
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
                    Visible = NonDeductibleVATVisible;
                }
                field(DeductibleAmount; Rec."Deductible VAT Amount")
                {
                    ApplicationArea = VAT;
                    Visible = NonDeductibleVATVisible;
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
        VATAmountEditable: Boolean;
        NonDeductibleVATVisible: Boolean;

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

    local procedure FormCheckVATDifference()
    var
        VATAmountLine2: Record "VAT Amount Line";
        TotalVATDifference: Decimal;
        ShowVATDifferenceError: Boolean;
    begin
        Rec.CheckVATDifference(CurrencyCode, AllowVATDifference);
        VATAmountLine2 := Rec;
        TotalVATDifference := Abs(Rec."VAT Difference") - Abs(xRec."VAT Difference");
        if Rec.Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs(Rec."VAT Difference");
            until Rec.Next() = 0;
        Rec := VATAmountLine2;
        ShowVATDifferenceError := TotalVATDifference > Currency."Max. VAT Difference Allowed";
        OnFormCheckVATDifferenceOnAfterCalcShowVATDifferenceError(Rec, TotalVATDifference, Currency, ShowVATDifferenceError);
        if ShowVATDifferenceError then
            Error(
              Text001, Rec.FieldCaption("VAT Difference"),
              Currency."Max. VAT Difference Allowed", Currency.FieldCaption("Max. VAT Difference Allowed"));
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
}
