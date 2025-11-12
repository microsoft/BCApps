// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;

page 187 "VAT Setup"
{
    ApplicationArea = Basic, Suite;
    DeleteAllowed = false;
    PageType = Card;
    SourceTable = "VAT Setup";
    UsageCategory = Administration;
    PromotedActionCategories = 'New,Process,Report,VAT Posting Groups,VAT Reporting,Other';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Enable Non-Deductible VAT"; Rec."Enable Non-Deductible VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Non-Deductible VAT feature is enabled.';
                    Editable = not Rec."Non-Deductible VAT Is Enabled";
                }
            }
            group(VATDate)
            {
                Caption = 'VAT Date';
                Visible = IsVATDateEnabled;
                field("Allow VAT From"; Rec."Allow VAT Date From")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the earliest date on which VAT posting to the company books is allowed.';
                }
                field("Allow VAT To"; Rec."Allow VAT Date To")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the last date on which VAT posting to the company books is allowed.';
                }
            }
            group(NonDeductibleVAT)
            {
                Caption = 'Non-Deductible VAT';
                Visible = Rec."Enable Non-Deductible VAT";

                field(UseForItemCost; Rec."Use For Item Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the non-deductible VAT must be added to the item cost.';
                }
                field(UseForFixedAssetCost; Rec."Use For Fixed Asset Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the non-deductible VAT must be added to the fixed asset cost.';
                }
                field(UseForJobCost; Rec."Use For Job Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the non-deductible VAT must be added to the project cost.';
                }
                field("Show Non-Ded. VAT In Lines"; Rec."Show Non-Ded. VAT In Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the non-deductible VAT must be shown in document lines pages.';
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksPart; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesPart; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(VATPostingGroups)
            {
                Caption = 'VAT Posting Groups';
                action(VATPostingSetup)
                {
                    Caption = 'VAT Posting Setup';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category4;
                    Image = VATPostingSetup;
                    RunObject = page "VAT Posting Setup";
                    ToolTip = 'View or edit combinations of Tax business posting groups and Tax product posting groups.';
                }
                action(VATBusinessPostingGroups)
                {
                    Caption = 'VAT Business Posting Groups';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category4;
                    Image = Company;
                    RunObject = page "VAT Business Posting Groups";
                    ToolTip = 'Set up the trade-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
                }
                action(VATProductPostingGroups)
                {
                    Caption = 'VAT Product Posting Groups';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category4;
                    Image = Item;
                    RunObject = page "VAT Product Posting Groups";
                    ToolTip = 'Set up the item-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
                }
                action(VATClauses)
                {
                    Caption = 'VAT Clauses';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category4;
                    Image = ElectronicVATExemption;
                    RunObject = page "VAT Clauses";
                    Tooltip = 'Open the VAT Clauses page.';
                }
            }
            group(VATReporting)
            {
                Caption = 'VAT Reporting';
                action(VATReportSetup)
                {
                    Caption = 'VAT Report Setup';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = Report;
                    RunObject = page "VAT Report Setup";
                    ToolTip = 'Set up number series and options for the report that you periodically send to the authorities to declare your VAT.';
                }
                action(VATReportsConfiguration)
                {
                    Caption = 'VAT Reports Configuration';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = Setup;
                    RunObject = page "VAT Reports Configuration";
                    Tooltip = 'Open the VAT Reports Configuration page.';
                }
                action(VATReturnPeriod)
                {
                    Caption = 'VAT Return Periods';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = Period;
                    RunObject = page "VAT Return Period List";
                    Tooltip = 'Open the VAT return periods page.';
                }
                action(VATReturn)
                {
                    Caption = 'VAT Returns';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = Return;
                    RunObject = page "VAT Report List";
                    ToolTip = 'Prepare the VAT Return report so you can submit VAT amounts to a tax authority.';
                }
                action(VATStatementTemplates)
                {
                    Caption = 'VAT Statement Templates';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = Template;
                    RunObject = page "VAT Statement Templates";
                    ToolTip = 'Prepare the VAT statement template for your VAT Return report that you can submit VAT amounts to a tax authority.';
                }
                action(VATStatement)
                {
                    Caption = 'VAT Statements';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = Worksheet;
                    RunObject = page "VAT Statement";
                    ToolTip = 'Prepare the VAT statement template for your VAT Return report that you can submit VAT amounts to a tax authority.';
                }
                action(VATVIESDeclarationDisk)
                {
                    Caption = 'VAT- VIES Declaration Disk';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = MakeDiskette;
                    RunObject = report "VAT- VIES Declaration Disk";
                    ToolTip = 'Report your sales to other EU countries or regions to the customs and tax authorities. If the information must be printed out on a printer, you can use the VAT- VIES Declaration Tax Auth report. The information is shown in the same format as in the declaration list from the customs and tax authorities.';
                }
                action(VATVIESDeclarationTaxAuth)
                {
                    Caption = 'VAT- VIES Declaration Tax Auth';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = Report2;
                    RunObject = report "VAT- VIES Declaration Tax Auth";
                    ToolTip = 'View information to the customs and tax authorities for sales to other EU countries/regions. If the information must be printed to a file, you can use the VAT- VIES Declaration Disk report.';
                }
            }
            group(Other)
            {
                Caption = 'Other';
                action(VATRateChangeSetup)
                {
                    Caption = 'VAT Rate Change Setup';
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Image = NumberSetup;
                    RunObject = page "VAT Rate Change Setup";
                    ToolTip = 'Opens the VAT rate change setup';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        IsVATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;


    var
        IsVATDateEnabled: Boolean;
}

