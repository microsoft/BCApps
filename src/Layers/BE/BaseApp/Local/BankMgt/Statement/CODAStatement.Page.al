// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;
using System.Telemetry;

page 2000040 "CODA Statement"
{
    Caption = 'CODA Statement';
    InsertAllowed = false;
    PageType = Document;
    SaveValues = true;
    SourceTable = "CODA Statement";

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the bank account that the statement has been made for.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the statement.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the statement was created.';
                }
                field("Balance Last Statement"; Rec."Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ending balance of the last bank account statement, which you have imported for this bank account.';
                }
                field("Statement Ending Balance"; Rec."Statement Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ending balance of the bank account statement.';
                }
                field(InformationText; InformationText)
                {
                    ApplicationArea = All;
                    CaptionClass = Rec.FieldCaption(Information);
                    Editable = false;
                    Visible = InformationVisible;
                }
            }
            part(StmtLines; "CODA Statement Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bank Account No." = field("Bank Account No."),
                              "Statement No." = field("Statement No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("St&atement")
            {
                Caption = 'St&atement';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = field("Bank Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the statement.';
                }
            }
        }
        area(processing)
        {
            action("Apply Entries...")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Apply Entries...';
                Image = Apply;
                ShortCutKey = 'Shift+F11';
                ToolTip = 'Apply the selected entries to a sales or purchase document that was already posted for a customer or vendor. This updates the amount on the posted document, and the document can either be partially paid, or closed as paid or refunded.';

                trigger OnAction()
                begin
                    CurrPage.StmtLines.PAGE.Apply();
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Process CODA Statement Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Process CODA Statement Lines';
                    Image = RefreshLines;
                    ToolTip = 'Automatically apply the CODA statement lines.';

                    trigger OnAction()
                    begin
                        CodBankStmt.SetRange("Bank Account No.", Rec."Bank Account No.");
                        CodBankStmt.SetRange("Statement No.", Rec."Statement No.");
                        REPORT.RunModal(REPORT::"Post CODA Stmt. Lines", true, false, CodBankStmt);
                    end;
                }
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = List;
                    ToolTip = 'Open the list of CODA statements.';

                    trigger OnAction()
                    begin
                        CodBankStmt.SetRange("Bank Account No.", Rec."Bank Account No.");
                        CodBankStmt.SetRange("Statement No.", Rec."Statement No.");
                        REPORT.RunModal(REPORT::"CODA Statement - List", true, false, CodBankStmt);
                        Clear(CodBankStmt)
                    end;
                }
                action("Transfer to General Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transfer to General Ledger';
                    Image = Export;
                    ShortCutKey = 'F9';
                    ToolTip = 'Transfer the lines from the current window to the general journal.';

                    trigger OnAction()
                    begin
                        CodBankStmtLine.SetRange("Bank Account No.", Rec."Bank Account No.");
                        CodBankStmtLine.SetRange("Statement No.", Rec."Statement No.");
                        CODEUNIT.Run(CODEUNIT::"Post Coded Bank Statement", CodBankStmtLine);
                        CodBankStmtLine.Reset();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Apply Entries..._Promoted"; "Apply Entries...")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        InformationVisible := (Rec.Information > 0);
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Information);
        InformationText := Format(Rec.Information);
        InformationTextOnFormat(InformationText);
    end;

    trigger OnInit()
    begin
        InformationVisible := true;
    end;

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('1000HM2', BECODATok, Enum::"Feature Uptake Status"::Discovered);
    end;

    var
        CodBankStmt: Record "CODA Statement";
        CodBankStmtLine: Record "CODA Statement Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        BECODATok: Label 'BE CODA Bank Statement', Locked = true;
        InformationVisible: Boolean;
        InformationText: Text[1024];

    local procedure InformationTextOnFormat(var Text: Text[1024])
    begin
        if Rec.Information > 0 then
            Text := '***';
    end;
}

