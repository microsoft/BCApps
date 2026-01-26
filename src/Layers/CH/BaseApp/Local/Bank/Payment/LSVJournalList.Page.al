// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.Receivables;
using System.Telemetry;

page 3010832 "LSV Journal List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'LSV Journal List';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "LSV Journal";
    SourceTableView = sorting("No.")
                      order(ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the journal number that identifies the collection uniquely.';
                }
                field("LSV Bank Code"; Rec."LSV Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = LSVBankCodeEditable;
                    ToolTip = 'Specifies the code for the bank that should carry out the collection.';

                    trigger OnValidate()
                    begin
                        FeatureTelemetry.LogUptake('1000HZ1', CHLSVTok, Enum::"Feature Uptake Status"::"Set up");
                    end;
                }
                field("LSV Status"; Rec."LSV Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the LSV journal line.';
                }
                field("LSV Journal Description"; Rec."LSV Journal Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = LSVJournalDescriptionEditable;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("No. Of Entries Plus"; Rec."No. Of Entries Plus")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of entries for the collection.';
                }
                field("Amount Plus"; Rec."Amount Plus")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount for the customer ledger entries for the collection.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code for the collection entries.';
                }
                field("Credit Date"; Rec."Credit Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the invoice amounts should be collected by the bank on this date.';
                }
                field("Collection Completed On"; Rec."Collection Completed On")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the collection was closed.';
                }
                field("File Written On"; Rec."File Written On")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the collection file was generated for the first time.';
                }
                field("Collection Completed By"; Rec."Collection Completed By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the user who closed the collection is stored in this field.';
                }
                field("DebitDirect Orderno."; Rec."DebitDirect Orderno.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the DebitDirect Orderno., which identifies the collection uniquely.';
                }
                field("Partner Type"; Rec."Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the LSV collection is a person or company.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Journal")
            {
                Caption = '&Journal';
                action("LSV Journal Line")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV Journal Line';
                    Image = ListPage;
                    RunObject = Page "LSV Journal";
                    RunPageLink = "LSV Journal No." = field("No.");
                    ToolTip = 'Open the related LSV journal line.';
                }
                action("C&ollected Cust. Ledg. Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ollected Cust. Ledg. Entries';
                    Image = CustomerLedger;
                    RunObject = Page "Customer Ledger Entries";
                    RunPageLink = "LSV No." = field("No.");
                    RunPageView = sorting("LSV No.");
                    ToolTip = 'View customer ledger entries that represent LSV collections.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action(LSVSuggestCollection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&LSV Suggest Collection';
                    Image = SuggestCustomerPayments;
                    ToolTip = 'Transfers open invoices to the LSV Journal. Customer entries are only suggested in CHF and EUR. Only invoices from customers that have a payment method code that matches the code entered in the LSV Payment Method Code field in the LSV Setup window are considered.';

                    trigger OnAction()
                    begin
                        Clear(LSVCollectSuggestion);
                        LSVCollectSuggestion.SetGlobals(Rec."No.");
                        LSVCollectSuggestion.RunModal();
                    end;
                }
                action("P&rint Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&rint Journal';
                    Image = Print;
                    ToolTip = 'View the journal contents in a report.';

                    trigger OnAction()
                    begin
                        Clear(LSVCollectionJournal);
                        LsvJournalLine.Reset();
                        LsvJournalLine.SetRange("LSV Journal No.", Rec."No.");
                        LsvJournalLine.FindFirst();
                        LSVCollectionJournal.SetGlobals(LsvJournalLine);
                        LSVCollectionJournal.RunModal();
                    end;
                }
                action(LSVCloseCollection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV &Close Collection';
                    Image = ReleaseDoc;
                    ToolTip = 'Complete the payment collection.';

                    trigger OnAction()
                    begin
                        Clear(LsvCloseCollection);
                        LsvCloseCollection.SetGlobals(Rec);
                        LsvCloseCollection.RunModal();
                        Clear(LsvCloseCollection);
                    end;
                }
                separator(Action103)
                {
                }
                action("Modify &Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Modify &Posting Date';
                    Image = ChangeDate;
                    ToolTip = 'Change one or more posting dates in the journal.';

                    trigger OnAction()
                    begin
                        LsvJournalLine.Reset();
                        LsvJournalLine.SetRange("LSV Journal No.", Rec."No.");
                        LsvJournalLine.FindFirst();
                        LsvMgt.ModifyPostingDate(LsvJournalLine);
                    end;
                }
                action("LSV Re&open Collection")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV Re&open Collection';
                    Image = ReOpen;
                    ToolTip = 'Reopen the payment collection. You can only reopen the collection if you have not yet submitted the LSV+ file to the bank.';

                    trigger OnAction()
                    begin
                        LsvMgt.ReopenJournal(Rec);
                    end;
                }
                separator(Action105)
                {
                }
                action(WriteLSVFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Write LSV File';
                    Image = Export;
                    ToolTip = 'Export the LSV payment collection file.';

                    trigger OnAction()
                    begin
                        FeatureTelemetry.LogUptake('1000HZ2', CHLSVTok, Enum::"Feature Uptake Status"::"Used");
                        Clear(WriteLSVFile);
                        WriteLSVFile.SetGlobals(Rec);
                        WriteLSVFile.RunModal();
                        FeatureTelemetry.LogUsage('1000HZ3', CHLSVTok, 'CH LSV Payment Collection File Exported');
                    end;
                }
                action("&Send LSV File")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Send LSV File';
                    Image = Web;
                    ToolTip = 'Submit the LSV payment collection file to the bank.';

                    trigger OnAction()
                    begin
                        LsvSetup.Get(Rec."LSV Bank Code");
                        LsvSetup.TestField("LSV Bank Transfer Hyperlink");
                        HyperLink(LsvSetup."LSV Bank Transfer Hyperlink");
                    end;
                }
                separator(Action108)
                {
                }
                action(WriteDebitDirectFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Write &Debit Direct File';
                    Image = Export;
                    ToolTip = 'Export the Direct Debit payment collection file.';

                    trigger OnAction()
                    begin
                        Clear(WriteDebitDirect);
                        WriteDebitDirect.SetGlobals(Rec."No.");
                        WriteDebitDirect.RunModal();
                    end;
                }
                action("Start &Yellownet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start &Yellownet';
                    Image = Web;
                    ToolTip = 'Transfer the debit direct file via YellowNet.';

                    trigger OnAction()
                    begin
                        LsvSetup.Get(Rec."LSV Bank Code");
                        LsvSetup.TestField("Yellownet Home Page");
                        HyperLink(LsvSetup."Yellownet Home Page");
                    end;
                }
                separator(Action1150000)
                {
                }
                action(WriteSEPAFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Write SEPA File';
                    Image = Export;
                    ToolTip = 'Export the SEPA Direct Debit payment collection file.';

                    trigger OnAction()
                    begin
                        Rec.CreateDirectDebitFile();
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                action("LSV &Collection Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV &Collection Order';
                    Image = "Report";
                    ToolTip = 'Open the related collection order.';

                    trigger OnAction()
                    begin
                        LsvJournal.SetRange("No.", Rec."No.");
                        REPORT.RunModal(REPORT::"LSV Collection Order", true, false, LsvJournal);
                    end;
                }
                action("LSV Collection &Advice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV Collection &Advice';
                    Image = "Report";
                    ToolTip = 'View the summarized payments for each customer from the current journal.';

                    trigger OnAction()
                    begin
                        Clear(LsvCollectionAdvice);
                        LsvCollectionAdvice.DefineJournalName(Rec);
                        LsvCollectionAdvice.RunModal();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(LSVSuggestCollection_Promoted; LSVSuggestCollection)
                {
                }
                actionref(LSVCloseCollection_Promoted; LSVCloseCollection)
                {
                }
                actionref("P&rint Journal_Promoted"; "P&rint Journal")
                {
                }
                actionref(WriteLSVFile_Promoted; WriteLSVFile)
                {
                }
                actionref(WriteDebitDirectFile_Promoted; WriteDebitDirectFile)
                {
                }
                actionref(WriteSEPAFile_Promoted; WriteSEPAFile)
                {
                }
                actionref("LSV Journal Line_Promoted"; "LSV Journal Line")
                {
                }
                actionref("C&ollected Cust. Ledg. Entries_Promoted"; "C&ollected Cust. Ledg. Entries")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        xRec := Rec;
        LSVJournalDescriptionEditable := true;
        LSVBankCodeEditable := true;

        if Rec."LSV Status" = Rec."LSV Status"::Released then
            LSVJournalDescriptionEditable := false;
        if Rec."No. Of Entries Plus" > 0 then
            LSVBankCodeEditable := false;
    end;

    trigger OnInit()
    begin
        LSVBankCodeEditable := true;
        LSVJournalDescriptionEditable := true;
    end;

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('1000HZ0', CHLSVTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    var
        LsvSetup: Record "LSV Setup";
        LsvJournal: Record "LSV Journal";
        LsvJournalLine: Record "LSV Journal Line";
        LsvCollectionAdvice: Report "LSV Collection Advice";
        LSVCollectSuggestion: Report "LSV Suggest Collection";
        LSVCollectionJournal: Report "LSV Collection Journal";
        LsvCloseCollection: Report "LSV Close Collection";
        WriteLSVFile: Report "Write LSV File";
        WriteDebitDirect: Report "LSV Write DebitDirect File";
        LsvMgt: Codeunit LSVMgt;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CHLSVTok: Label 'CH Process an LSV Collection', Locked = true;
        LSVJournalDescriptionEditable: Boolean;
        LSVBankCodeEditable: Boolean;
}

