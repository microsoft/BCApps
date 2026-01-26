// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Dimension;
using System.Telemetry;

page 2000022 "Domiciliation Journal"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Domiciliation Journals';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Domiciliation Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the batch name of the domiciliation journal.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    if Rec.GetFilter("Journal Template Name") = '' then
                        Rec.SetRange("Journal Template Name", Rec."Journal Template Name");
                    DoLookup := DomJnlManagement.LookupName(Rec.GetRangeMax("Journal Template Name"), CurrentJnlBatchName, Text);
                    CurrPage.Update();
                    exit(DoLookup);
                end;

                trigger OnValidate()
                begin
                    DomJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you want the payment to be posted.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer linked to the journal line.';

                    trigger OnValidate()
                    begin
                        DomJnlManagement.GetAccounts(Rec, CustName, BankAccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Message 1"; Rec."Message 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a message for the domiciliation.';
                }
                field("Message 2"; Rec."Message 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a second message for the domiciliation.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the outstanding amount. The payment discounts are automatically subtracted from this amount.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the domiciliation.';
                }
                field("Pmt. Disc. Possible"; Rec."Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment discount that is subtracted from the remaining amount of the outstanding entry.';
                    Visible = false;
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date used to determine the payment discount.';
                    Visible = false;
                }
                field(Reference; Rec.Reference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the standard format message for the domiciliation.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the bank account on which you want the domiciliations to be made.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        BankAccountNoOnAfterValidate();
                    end;
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification of the direct-debit mandate that is being used on the journal lines to process a direct debit collection.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that to see the available status, click the AssistButton.';
                }
            }
            group(Control60)
            {
                ShowCaption = false;
                fixed(Control1901775801)
                {
                    ShowCaption = false;
                    group("Bank Account Name")
                    {
                        Caption = 'Bank Account Name';
                        field(BankAccName; BankAccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                        }
                    }
                    group("Customer Name")
                    {
                        Caption = 'Customer Name';
                        field(CustName; CustName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Name';
                            Editable = false;
                            ToolTip = 'Specifies the name of the customer who has been entered on the domiciliation journal line.';
                        }
                    }
                    group("Total Customer")
                    {
                        Caption = 'Total Customer';
                        field(BalanceRem; Amt + Rec.Amount - xRec.Amount)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Total Customer';
                            Editable = false;
                            ToolTip = 'Specifies the total amount of the domiciliations of the customer who has been entered on the domiciliation journal line.';
                            Visible = BalanceRemVisible;
                        }
                    }
                    group("Total Balance")
                    {
                        Caption = 'Total Balance';
                        field(TotalBalance; TotalAmount + Rec.Amount - xRec.Amount)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Total Balance';
                            Editable = false;
                            ToolTip = 'Specifies the total balance in the domiciliation journal.';
                            Visible = TotalBalanceVisible;
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(Control1900919607; "Dimension Set Entries FactBox")
            {
                ApplicationArea = Dimensions;
                SubPageLink = "Dimension Set ID" = field("Dimension Set ID");
                Visible = false;
            }
            part("Domiciliation File Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Domiciliation File Errors';
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Journal Batch Name" = field("Journal Batch Name"),
                              "Journal Line No." = field("Line No.");
            }
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
            group("&Line")
            {
                Caption = '&Line';
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        DomJnlManagement.ShowCard(Rec);
                    end;
                }
                action(LedgerEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    begin
                        DomJnlManagement.ShowEntries(Rec);
                    end;
                }
            }
            group("D&omicil.")
            {
                Caption = 'D&omicil.';
                action(SuggestDomiciliations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Domiciliations';
                    Ellipsis = true;
                    Image = Suggest;
                    ToolTip = 'Let the program create the journal lines based on a number of criteria. ';

                    trigger OnAction()
                    begin
                        SuggestDomiciliations.SetJournal(Rec);
                        SuggestDomiciliations.RunModal();
                        Clear(SuggestDomiciliations);
                    end;
                }
                action(FileDomiciliations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'File Domiciliations';
                    Image = Document;
                    ToolTip = 'Generate a report that contains the domiciliations to be made by the bank that you have selected. Only euro domiciliations will be included in the report. You must create a separate file for each currency. In addition, this report generates an accompanying document that you can submit with a disk. You can also send the generated file to the bank by data modem or by using the Isabel third-party software program. For this purpose neither the file nor the Isabel program must be modified.';

                    trigger OnAction()
                    begin
                        FeatureTelemetry.LogUptake('1000HL9', BEDirectDebtTok, Enum::"Feature Uptake Status"::"Used");
                        Rec.ExportToFile();
                        CurrPage.Update(false);
                        FeatureTelemetry.LogUsage('1000HM0', BEDirectDebtTok, 'BE Direct Debit Generated With Domiciliations');
                    end;
                }
            }
        }
        area(processing)
        {
            group(Print)
            {
                Caption = 'Print';
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        DomJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
                        DomJnlManagement.PrintTestReport(DomJnlBatch);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(SuggestDomiciliations_Promoted; SuggestDomiciliations)
                {
                }
                actionref(FileDomiciliations_Promoted; FileDomiciliations)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DomJnlManagement.GetAccounts(Rec, CustName, BankAccName);
        UpdateAmount();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        TotalBalanceVisible := true;
        BalanceRemVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        DomJnlManagement.SetUpNewLine(Rec, xRec);
        Clear(ShortcutDimCode);
        Clear(CustName);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
        OpenedFromBatch: Boolean;
    begin
        FeatureTelemetry.LogUptake('1000HL8', BEDirectDebtTok, Enum::"Feature Uptake Status"::Discovered);
        OpenedFromBatch := (Rec."Journal Batch Name" <> '') and (Rec."Journal Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            DomJnlManagement.OpenJournal(CurrentJnlBatchName, Rec);
            exit;
        end;
        DomJnlManagement.TemplateSelection(Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        DomJnlManagement.OpenJournal(CurrentJnlBatchName, Rec);
    end;

    var
        DomJnlBatch: Record "Domiciliation Journal Batch";
        SuggestDomiciliations: Report "Suggest domicilations";
        DomJnlManagement: Codeunit DomiciliationJnlManagement;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        BEDirectDebtTok: Label 'BE Direct Debit Using Domiciliation', Locked = true;
        CurrentJnlBatchName: Code[10];
        CustName: Text[100];
        BankAccName: Text[100];
        Amt: Decimal;
        TotalAmount: Decimal;
        ShowAmount: Boolean;
        ShowTotalAmount: Boolean;
        DoLookup: Boolean;
        BankAccount: Code[20];
        ShortcutDimCode: array[8] of Code[20];
        BalanceRemVisible: Boolean;
        TotalBalanceVisible: Boolean;

    local procedure UpdateAmount()
    begin
        DomJnlManagement.CalculateTotals(Rec, xRec, Amt, TotalAmount, ShowAmount, ShowTotalAmount);
        BalanceRemVisible := ShowAmount;
        TotalBalanceVisible := ShowTotalAmount;
    end;

    local procedure BankAccountNoOnAfterValidate()
    begin
        if not (Rec.Status = Rec.Status::Posted) then begin
            BankAccount := xRec."Bank Account No.";
            CurrPage.SaveRecord();
            DomJnlManagement.AssignBankAccount(Rec, BankAccount);
            CurrPage.Update(false);
        end;
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        DomJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;
}

