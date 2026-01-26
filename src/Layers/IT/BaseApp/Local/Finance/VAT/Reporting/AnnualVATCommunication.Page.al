// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Reporting;

page 12126 "Annual VAT Communication"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Annual VAT Communication';
    MultipleNewLines = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "VAT Statement Line";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            field(CurrentStmtName; CurrentStmtName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    exit(VATStmtManagement.LookupName(Rec.GetRangeMax("Statement Template Name"), CurrentStmtName, Text));
                end;

                trigger OnValidate()
                begin
                    VATStmtManagement.CheckName(CurrentStmtName, Rec);
                    CurrentStmtNameOnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type.';
                }
                field("Account Totaling"; Rec."Account Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the totalling account.';
                    Visible = false;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group for the line.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group for the line.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the amount that is being reported. If the field is blank, then no information is reported.';
                }
                field("Row Totaling"; Rec."Row Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for the line.';
                }
                field("Calculate with"; Rec."Calculate with")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the amount is calculated with a sign or the opposite sign.';
                }
                field("Round Factor"; Rec."Round Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a rounding factor that is used to round the VAT entry amounts.';
                }
                field(Control22; Rec.Print)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to print the report.';
                }
                field("Annual VAT Comm. Field"; Rec."Annual VAT Comm. Field")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of sales or purchase transaction that created the VAT entry.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Annual VAT Communication")
            {
                Caption = '&Annual VAT Communication';
                action("P&review")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&review';
                    Image = "Report";
                    RunObject = Page "Annual VAT Comm. Preview";
                    RunPageLink = "Statement Template Name" = field("Statement Template Name"),
                                  Name = field("Statement Name");
                    ToolTip = 'Preview the document.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Print)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'Print the document.';

                    trigger OnAction()
                    var
                        VATStatementName: Record "VAT Statement Name";
                    begin
                        VATStatementName.SetFilter("Statement Template Name", '%1', Rec."Statement Template Name");
                        if VATStatementName.FindLast() then
                            ReportPrint.PrintVATStmtName(VATStatementName);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Annual VAT Communication")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Annual VAT Communication';
                ToolTip = 'View detailed information about VAT related transactions carried out during the year. ';

                trigger OnAction()
                var
                    VATStatementName: Record "VAT Statement Name";
                begin
                    VATStatementName.SetFilter("Statement Template Name", '%1', Rec."Statement Template Name");
                    if VATStatementName.FindLast() then
                        ReportPrint.PrintVATStmtName(VATStatementName);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("P&review_Promoted"; "P&review")
                {
                }
                actionref("Annual VAT Communication_Promoted"; "Annual VAT Communication")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        StmtSelected: Boolean;
    begin
        VATStmtManagement.TemplateSelection(PAGE::"Annual VAT Communication", Rec, StmtSelected);
        if not StmtSelected then
            Error('');
        VATStmtManagement.OpenStmt(CurrentStmtName, Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        VATStmtManagement: Codeunit VATStmtManagement;
        CurrentStmtName: Code[10];

    local procedure CurrentStmtNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        VATStmtManagement.SetName(CurrentStmtName, Rec);
        CurrPage.Update(false);
    end;
}

