// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.Currency;

/// <summary>
/// Displays and allows editing of VAT amount lines for document processing and validation.
/// Provides user interface for reviewing and adjusting VAT calculations, differences, and amounts.
/// </summary>
/// <remarks>
/// Used in sales, purchase, and service documents for VAT amount review and adjustment.
/// Supports VAT difference validation and currency-specific formatting.
/// </remarks>
page 9401 "VAT Amount Lines"
{
    Caption = 'VAT Amount Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
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
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the net VAT amount that must be paid for products on the line.';
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
                    var
                        IsHandled: Boolean;
                    begin
                        if Rec.Insert() then;
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            Error(Text000, Rec.FieldCaption("VAT Amount"));

                        if PricesIncludingVAT then
                            Rec."VAT Base" := Rec."Amount Including VAT" - Rec."VAT Amount"
                        else
                            Rec."Amount Including VAT" := Rec."VAT Amount" + Rec."VAT Base";

                        IsHandled := false;
                        OnBeforeFormCheckVATDifference(Rec, IsHandled);
                        if not IsHandled then
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
                    ToolTip = 'Specifies the total of the amounts, including VAT, on all the lines on the document.';

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
                            Error(Text000, Rec.FieldCaption("Non-Deductible VAT Amount"));
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
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        VATAmountEditable := AllowVATDifference and not Rec."Includes Prepayment";
        InvoiceDiscountAmountEditable := AllowInvDisc and not Rec."Includes Prepayment";
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TempVATAmountLine.Copy(Rec);
        if TempVATAmountLine.Find(Which) then begin
            Rec := TempVATAmountLine;
            exit(true);
        end;
        exit(false);
    end;

    trigger OnInit()
    begin
        InvoiceDiscountAmountEditable := true;
        VATAmountEditable := true;
        NonDeductibleVATVisible := NonDeductibleVAT.IsNonDeductibleVATEnabled();
    end;


    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        TempVATAmountLine.Copy(Rec);
        ResultSteps := TempVATAmountLine.Next(Steps);
        if ResultSteps <> 0 then
            Rec := TempVATAmountLine;
        exit(ResultSteps);
    end;

    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        Currency: Record Currency;
        CurrencyCode: Code[10];
        PricesIncludingVAT: Boolean;
        VATBaseDiscPct: Decimal;
        VATAmountEditable: Boolean;
        InvoiceDiscountAmountEditable: Boolean;
        NonDeductibleVATVisible: Boolean;

    protected var
        AllowVATDifference: Boolean;
        AllowVATDifferenceOnThisTab: Boolean;
        AllowInvDisc: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 can only be modified on the Invoicing tab.';
        Text001: Label 'The total %1 for a document must not exceed the value %2 in the %3 field.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    /// <summary>
    /// Sets the temporary VAT amount line buffer with data from the provided VAT amount line record set.
    /// </summary>
    /// <param name="NewVATAmountLine">VAT amount line record set to copy into temporary buffer</param>
    procedure SetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        TempVATAmountLine.DeleteAll();
        if NewVATAmountLine.Find('-') then
            repeat
                TempVATAmountLine.Copy(NewVATAmountLine);
                TempVATAmountLine.Insert();
            until NewVATAmountLine.Next() = 0;
    end;

    /// <summary>
    /// Retrieves the current temporary VAT amount line buffer data into the provided VAT amount line record set.
    /// </summary>
    /// <param name="NewVATAmountLine">VAT amount line record set to receive the temporary buffer data</param>
    procedure GetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        NewVATAmountLine.DeleteAll();
        if TempVATAmountLine.Find('-') then
            repeat
                NewVATAmountLine.Copy(TempVATAmountLine);
                NewVATAmountLine.Insert();
            until TempVATAmountLine.Next() = 0;
    end;

    /// <summary>
    /// Initializes page global variables for VAT amount line processing and display control.
    /// </summary>
    /// <param name="NewCurrencyCode">Currency code for amount formatting and calculations</param>
    /// <param name="NewAllowVATDifference">Whether VAT differences are allowed for modification</param>
    /// <param name="NewAllowVATDifferenceOnThisTab">Whether VAT differences are allowed on current tab</param>
    /// <param name="NewPricesIncludingVAT">Whether prices include VAT or VAT is calculated on top</param>
    /// <param name="NewAllowInvDisc">Whether invoice discount is allowed</param>
    /// <param name="NewVATBaseDiscPct">VAT base discount percentage from document header</param>
    procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
        CurrencyCode := NewCurrencyCode;
        AllowVATDifference := NewAllowVATDifference;
        AllowVATDifferenceOnThisTab := NewAllowVATDifferenceOnThisTab;
        PricesIncludingVAT := NewPricesIncludingVAT;
        AllowInvDisc := NewAllowInvDisc;
        VATBaseDiscPct := NewVATBaseDiscPct;
        VATAmountEditable := AllowVATDifference;
        InvoiceDiscountAmountEditable := AllowInvDisc;
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(CurrencyCode);
    end;

    local procedure FormCheckVATDifference()
    var
        VATAmountLine2: Record "VAT Amount Line";
        TotalVATDifference: Decimal;
    begin
        Rec.CheckVATDifference(CurrencyCode, AllowVATDifference);
        VATAmountLine2 := TempVATAmountLine;
        TotalVATDifference := Abs(Rec."VAT Difference") - Abs(xRec."VAT Difference");
        if TempVATAmountLine.Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs(TempVATAmountLine."VAT Difference");
            until TempVATAmountLine.Next() = 0;
        TempVATAmountLine := VATAmountLine2;
        if TotalVATDifference > Currency."Max. VAT Difference Allowed" then
            Error(
              Text001, Rec.FieldCaption("VAT Difference"),
              Currency."Max. VAT Difference Allowed", Currency.FieldCaption("Max. VAT Difference Allowed"));
    end;

    local procedure ModifyRec()
    begin
        TempVATAmountLine := Rec;
        TempVATAmountLine.Modified := true;
        TempVATAmountLine.Modify();
    end;

    /// <summary>
    /// Integration event raised before performing VAT difference validation on the form.
    /// Enables custom VAT difference validation logic or bypassing standard validation.
    /// </summary>
    /// <param name="VATAmountLine">VAT amount line being validated</param>
    /// <param name="IsHandled">Set to true to skip standard VAT difference validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormCheckVATDifference(VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean)
    begin
    end;
}


