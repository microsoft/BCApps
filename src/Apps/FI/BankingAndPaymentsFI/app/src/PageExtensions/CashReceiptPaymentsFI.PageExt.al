// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Reports;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Privacy;
using System.Threading;

pageextension 13557 "Cash Receipt Payments FI" extends "Cash Receipt Journal"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Reference No.")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(Control1)
        {
            field("Payment Reference No."; Rec."Payment Reference No.")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference number that is calculated from a reference number sequence.';
                }
        }
    }
    actions
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Read Reference File")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
#if not CLEAN30
#pragma warning disable AL0432
        modify("Transfer Report")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
#if not CLEAN30
#pragma warning disable AL0432
        modify("Apply Reference Lines")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(navigation)
        {
            action("Read Reference File FI")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    Caption = 'Read Reference File';
                    Image = SuggestCustomerPayments;
                    ToolTip = 'Import the bank''s reference transfer file. Then specify the bank account whose material you want to use. If the transfer file contains material from several bank accounts, all transactions for all accounts are imported. After the file is imported, all payments for which an open customer transaction with the same reference number are available in the Cash Receipt Journal window.';

                    trigger OnAction()
                    begin
#pragma warning disable AL0432
                        Clear(ReadBankFile);
                        ReadBankFile.SetLedgerNames(Rec."Journal Batch Name", Rec."Journal Template Name");
                        ReadBankFile.RunModal();
#pragma warning restore AL0432
                    end;
                }
            action("Transfer Report FI")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transfer Report';
                    Image = PrintForm;
                    ToolTip = 'Print the Reference Payment report, which contains all transactions imported that have not been posted. The first row shows data from the bank file. The second row shows data that is based on the reference number. If the reference transfer file has transactions without corresponding transaction rows, the transaction''s second row displays TRANSACTION COULD NOT BE AUTOMATICALLY APPLIED. ';

                    trigger OnAction()
                    begin
#pragma warning disable AL0432
                        Clear(ReferenceReport);
                        ReferenceReport.Run();
#pragma warning restore AL0432
                    end;
                }
            action("Apply Reference Lines FI")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Reference Lines';
                    Image = ApplyEntries;

                    trigger OnAction()
                    begin
#pragma warning disable AL0432
                        Clear(ApplyReperenceLines);
                        Clear(PostRefLines);
                        if ApplyReperenceLines.RunModal() = ACTION::LookupOK then
                            PostRefLines.MatchLines(Rec."Journal Template Name", Rec."Journal Batch Name");
#pragma warning restore AL0432
                    end;
                }
        }
        addlast(Category_Process)
        {
            actionref("Read Reference File FI Promoted"; "Read Reference File FI") { }
            actionref("Transfer Report FI Promoted"; "Transfer Report FI") { }
            actionref("Apply Reference Lines FI Promoted"; "Apply Reference Lines FI") { }
        }
    }
#if not CLEAN30
    trigger OnOpenPage()
    var
        Feature: Codeunit "Banking Payments Feature FI";
    begin
        FeatureEnabled := Feature.IsEnabled();
    end;

    var
        FeatureEnabled: Boolean;
#endif

    var
        ReadBankFile: Report "Import Ref. Payment FI";
        ReferenceReport: Report "Ref. Payment Imported FI";
        ApplyReperenceLines: Page "Apply Ref. Payment FI";
        PostRefLines: Codeunit "Ref. Payment Management FI";
}
