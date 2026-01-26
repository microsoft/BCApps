// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Vendor;
using System.Telemetry;
using System.Utilities;

page 12112 "Withholding Tax Card"
{
    Caption = 'Withholding Tax Card';
    PageType = Card;
    SourceTable = "Withholding Tax";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the withholding tax entry is posted.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identification number of the vendor that is related to the withholding tax entry.';

                    trigger OnValidate()
                    begin
                        if Vendor.Get(Rec."Vendor No.") then;
                    end;
                }
                field("Vendor.Name"; Vendor.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Name';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the vendor name.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique identification number that refers to the source document that generated the withholding tax entry.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identification number, using the numbering system of the vendor, that links the vendor''s source document to the withholding tax entry.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the source document that generated the withholding tax entry.';
                }
                field("Related Date"; Rec."Related Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the purchase that generated the withholding tax entry.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the withholding tax amount was paid to the tax authority.';
                }
                field(Month; Rec.Month)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the month of the withholding tax entry in numeric format.';
                }
                field(Year; Rec.Year)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the year of the withholding tax entry in numeric format. ';
                }
                field("Tax Code"; Rec."Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique four-digit code that is used to reference the fiscal withholding tax that is applied to this entry.';
                }
                field(Reason; Rec.Reason)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code.';
                }
                field(Paid; Rec.Paid)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the withholding tax amount for this entry has been paid to the tax authority.';
                }
                field(Reported; Rec.Reported)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the withholding tax amount from this entry has been reported to the tax authority.';
                }
            }
            group("Withholding Tax")
            {
                Caption = 'Withholding Tax';
                field("Withholding Tax Code"; Rec."Withholding Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the withholding code that is applied to this purchase. ';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to withholding tax.';
                }
                field("Base - Excluded Amount"; Rec."Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Unfavorable;
                    StyleExpr = BaseExcludedStyleExpr;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation, based on exclusions allowed by law.';

                    trigger OnDrillDown()
                    var
                        WithholdingTaxLine: Record "Withholding Tax Line";
                        ConfirmManagement: Codeunit "Confirm Management";
                        WithholdingTaxLinesPage: Page "Withholding Tax Lines";
                    begin
                        if Rec."Non-Taxable Income Type" <> "Non-Taxable Income Type"::" " then begin
                            if not ConfirmManagement.GetResponse(ClearNonTaxableIncomeTypeQst, false) then
                                exit;
                            Rec.Validate("Non-Taxable Income Type", "Non-Taxable Income Type"::" ");
                        end;

                        WithholdingTaxLine.SetRange("Withholding Tax Entry No.", Rec."Entry No.");
                        WithholdingTaxLinesPage.SetTableView(WithholdingTaxLine);
                        Rec.Modify(true);
                        Commit();
                        WithholdingTaxLinesPage.SetTotalAmount(Rec."Base - Excluded Amount");
                        WithholdingTaxLinesPage.RunModal();
                        SetBaseExcludedStyleExpr();
                    end;

                    trigger OnValidate()
                    begin
                        SetBaseExcludedStyleExpr();
                    end;
                }
                field("Non Taxable Amount By Treaty"; Rec."Non Taxable Amount By Treaty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation based on residency. ';
                    trigger OnValidate()
                    begin
                        SetBaseExcludedStyleExpr();
                    end;
                }
                field("Non Taxable Amount %"; Rec."Non Taxable Amount %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percent of the original purchase transaction that is not taxable due to provisions in the law.';
                }
                field("Non Taxable Amount"; Rec."Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is not taxable due to provisions in the law.';
                }
                field("Taxable Base"; Rec."Taxable Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to withholding tax after non-taxable and excluded amounts have been subtracted.';
                }
                field("Withholding Tax %"; Rec."Withholding Tax %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to withholding tax.';
                }
                field("Withholding Tax Amount"; Rec."Withholding Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of withholding tax for this purchase. ';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Vendor.Get(Rec."Vendor No.") then;
        SetBaseExcludedStyleExpr();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Vendor.Init();
    end;

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('1000HQ2', ITTaxTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    var
        Vendor: Record Vendor;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ClearNonTaxableIncomeTypeQst: Label 'To distribute Non-Taxable Amount between several Income Types you must have Non-Taxable Income Type on this Withholding Tax Entry empty. \\ Do you want to clear Non-Taxable Income Type and continue?';
        ITTaxTok: Label 'IT Withholding Tax', Locked = true;
        BaseExcludedStyleExpr: Boolean;

    local procedure SetBaseExcludedStyleExpr()
    var
        WithholdingTaxLine: Record "Withholding Tax Line";
    begin
        if Rec."Non-Taxable Income Type" <> "Non-Taxable Income Type"::" " then
            BaseExcludedStyleExpr := false
        else
            BaseExcludedStyleExpr := not (WithholdingTaxLine.GetAmountForEntryNo(Rec."Entry No.") = Rec."Base - Excluded Amount");
    end;
}

