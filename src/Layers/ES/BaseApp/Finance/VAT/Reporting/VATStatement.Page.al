// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Reporting;

/// <summary>
/// Worksheet interface for defining and managing VAT statement templates with line-by-line calculation setup.
/// Enables configuration of VAT reporting calculations, formulas, and box mappings for tax authority submissions.
/// </summary>
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Totaling"; Rec."Account Totaling")
                {
                    ApplicationArea = Basic, Suite;

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
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT statement line shows the VAT amounts or the base amounts on which the VAT is calculated.';
                }
                field("Row Totaling"; Rec."Row Totaling")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Calculate with"; Rec."Calculate with")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Control22; Rec.Print)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Print with"; Rec."Print with")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("New Page"; Rec."New Page")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Box; Rec.Box)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number on the packaging box that the VAT statement applies to.';
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
                    var
                        VATStmtLine: Record "VAT Statement Line";
                        VATStmtName: Record "VAT Statement Name";
                    begin
                        VATStmtName.SetRange(Name, CurrentStmtName);
                        if not VATStmtName.Find('-') then
                            Error(Text10700);
                        if VATStmtName."Template Type" = VATStmtName."Template Type"::"One Column Report" then begin
                            VATStmtLine.SetRange("Statement Template Name", Rec."Statement Template Name");
                            VATStmtLine.SetRange("Statement Name", Rec."Statement Name");
                            REPORT.Run(REPORT::"VAT Statement", true, false, VATStmtLine);
                        end else
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
            group("Telematic VAT")
            {
                Caption = 'Telematic VAT';
                Image = ElectronicDoc;
                action("Design txt file")
                {
                    ApplicationArea = VAT;
                    Caption = 'Design txt file';
                    Ellipsis = true;
                    Image = Document;
                    RunObject = Page "Transference Format";
                    RunPageLink = "VAT Statement Name" = field("Statement Name");
                    ToolTip = 'Define the layout of an XML file from the Transference Format template for your company''s VAT statements.';
                }
                action("Generate TXT File")
                {
                    ApplicationArea = VAT;
                    Caption = 'Generate txt file';
                    Ellipsis = true;
                    Image = CreateDocument;
                    ToolTip = 'Create a text file for the selected VAT declaration according to the transference format template defined for the VAT declaration. A window will show all the lines in the template where the Ask check box was selected, so that you can insert or modify the content of the values to be included in the file for these elements.';

                    trigger OnAction()
                    begin
                        TeleVATDecl.CurrentAsign(Rec);
                        TeleVATDecl.RunModal();
                        Clear(TeleVATDecl);
                    end;
                }
                action("Design XML file")
                {
                    ApplicationArea = VAT;
                    Caption = 'Design XML file';
                    Ellipsis = true;
                    Image = XMLFile;
                    RunObject = Page "XML Transference Format";
                    RunPageLink = "VAT Statement Name" = field("Statement Name");
                    ToolTip = 'Define the layout of a text file from the Transference Format template for your company''s VAT statements.';
                }
                action("Generate XML File")
                {
                    ApplicationArea = VAT;
                    Caption = 'Generate XML file';
                    Ellipsis = true;
                    Image = CreateXMLFile;
                    ToolTip = 'Create an XML file for the selected VAT declaration according to the XML Transference Format template defined for the VAT declaration. After accepting, you will be shown a new window with all the lines in the template where the Ask check box was selected, so that you can insert or modify the content of the values to be included in the file for these elements. When you finally accept this window, the text file is created in the specified path.';

                    trigger OnAction()
                    begin
                        TeleVATDeclXML.CurrentAssign(Rec);
                        TeleVATDeclXML.RunModal();
                        Clear(TeleVATDeclXML);
                    end;
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
                actionref("Design txt file_Promoted"; "Design txt file")
                {
                }
                actionref("Generate TXT File_Promoted"; "Generate TXT File")
                {
                }
                actionref("Design XML file_Promoted"; "Design XML file")
                {
                }
                actionref("Generate XML File_Promoted"; "Generate XML File")
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
        TeleVATDecl: Report "Telematic VAT Declaration";
        Text10700: Label 'The Statement name does not exist';
        TeleVATDeclXML: Report "XML VAT Declaration";

    local procedure CurrentStmtNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        VATStmtManagement.SetName(CurrentStmtName, Rec);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Integration event raised before opening the VAT statement page.
    /// Enables custom preprocessing and filtering of VAT statement line records.
    /// </summary>
    /// <param name="VATStatementLine">VAT statement line record for preprocessing</param>
    /// <param name="IsHandled">Set to true to skip standard page opening logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOpenPage(var VATStatementLine: Record "VAT Statement Line"; var IsHandled: Boolean)
    begin
    end;
}

