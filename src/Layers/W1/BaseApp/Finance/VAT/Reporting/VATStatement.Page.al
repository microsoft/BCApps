// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Reporting;

page 317 "VAT Statement"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'VAT Statements';
    MultipleNewLines = true;
    PageType = Worksheet;
    AboutTitle = 'About VAT Statements';
    AboutText = 'Define and manage VAT statement formats to calculate VAT settlement amounts for specific periods, customize statement lines by posting groups and totaling types, and ensure compliance with official VAT reporting requirements.';
    SaveValues = true;
    SourceTable = "VAT Statement Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentStmtName; CurrentStmtName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the VAT statement.';

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
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT statement line.';
                }
                field("Box No."; Rec."Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number on the box that the VAT statement applies to.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what the VAT statement line will include.';
                }
                field("Account Totaling"; Rec."Account Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an account interval or a series of account numbers.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccountList: Page "G/L Account List";
                    begin
                        GLAccountList.LookupMode(true);
                        if not (GLAccountList.RunModal() = ACTION::LookupOK) then
                            exit(false);
                        Text := GLAccountList.GetSelectionFilter();
                        exit(true);
                    end;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of transaction.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT statement line shows the VAT amounts or the base amounts on which the VAT is calculated.';
                }
                field("Row Totaling"; Rec."Row Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a row-number interval or a series of row numbers.';
                }
                field("Calculate with"; Rec."Calculate with")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether amounts on the VAT statement will be calculated with their original sign or with the sign reversed.';
                }
                field(Control22; Rec.Print)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the VAT statement line will be printed on the report that contains the finished VAT statement.';
                }
                field("Print with"; Rec."Print with")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether amounts on the VAT statement will be printed with their original sign or with the sign reversed.';
                }
                field("New Page"; Rec."New Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether a new page should begin immediately after this line when the VAT statement is printed. To start a new page after this line, place a check mark in the field.';
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
        area(navigation)
        {
            group("VAT &Statement")
            {
                Caption = 'VAT &Statement';
                Image = Suggest;
                action("P&review")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&review';
                    Image = View;
                    RunObject = Page "VAT Statement Preview";
                    RunPageLink = "Statement Template Name" = field("Statement Template Name"),
                                  Name = field("Statement Name");
                    ToolTip = 'Preview the VAT statement report.';
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
                    ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintVATStmtLine(Rec);
                    end;
                }
                action("Calc. and Post VAT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate and Post VAT Settlement';
                    Ellipsis = true;
                    Image = SettleOpenTransactions;
                    RunObject = Report "Calc. and Post VAT Settlement";
                    ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account.';
                }
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
                actionref("Calc. and Post VAT Settlement_Promoted"; "Calc. and Post VAT Settlement")
                {
                }
                actionref("P&review_Promoted"; "P&review")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        StmtSelected: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnOpenPage(Rec, IsHandled);
        if IsHandled then
            exit;

        OpenedFromBatch := (Rec."Statement Name" <> '') and (Rec."Statement Template Name" = '');
        if OpenedFromBatch then begin
            CurrentStmtName := Rec."Statement Name";
            VATStmtManagement.OpenStmt(CurrentStmtName, Rec);
            exit;
        end;
        VATStmtManagement.TemplateSelection(PAGE::"VAT Statement", Rec, StmtSelected);
        if not StmtSelected then
            Error('');
        VATStmtManagement.OpenStmt(CurrentStmtName, Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        VATStmtManagement: Codeunit VATStmtManagement;
        CurrentStmtName: Code[10];
        OpenedFromBatch: Boolean;

    local procedure CurrentStmtNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        VATStmtManagement.SetName(CurrentStmtName, Rec);
        CurrPage.Update(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOpenPage(var VATStatementLine: Record "VAT Statement Line"; var IsHandled: Boolean)
    begin
    end;
}

