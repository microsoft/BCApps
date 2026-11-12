// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.AutomaticAccounts;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.SpendRequest;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Setup;
using Microsoft.Integration.Entity;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using System.Automation;
using System.DateTime;
using System.Environment.Configuration;
using System.IO;
using System.Threading;
using System.Utilities;

tableextension 13536 "Gen. Journal Payments FI" extends "Gen. Journal Line"
{
    fields
    {
        modify("Due Date")
        {
            trigger OnAfterValidate()
            begin
#if not CLEAN30
                if not Feature.IsEnabled() then
                    exit;
#endif
                Rec."Planned Payment Date" := Rec."Due Date";
            end;
        }
        field(13511; "Payment Reference No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Reference No.';
        }
        field(13512; "Bank Message Type"; Option)
        {
            DataClassification = CustomerContent;
            Caption = 'Message Type';
            InitValue = "Reference No";
            OptionCaption = 'Reference No,Invoice Information,Message,Long Message,Tax Message';
            OptionMembers = "Reference No","Invoice Information",Message,"Long Message","Tax Message";
        }
        field(13513; "Payment Message"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Invoice Message';

            trigger OnValidate()
            begin
#if not CLEAN30
                if not Feature.IsEnabled() then
                    exit;
#endif
                if ("Payment Message" <> '') and ("Bank Message Type" = "Bank Message Type"::"Reference No") then begin
                    if StrLen("Payment Message") > 20 then
                        Error(Text1090006, FieldCaption("Payment Message"), 20);
                    BankNosCheck.InvReferenceCheck("Payment Message");
                end;
                if "Bank Message Type" = "Bank Message Type"::Message then
                    if StrLen("Payment Message") > 70 then
                        Error(Text1090006, FieldCaption("Payment Message"), 70);
            end;
        }
        field(13514; "Payment Message 2"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Invoice Message 2';

            trigger OnValidate()
            begin
#if not CLEAN30
                if not Feature.IsEnabled() then
                    exit;
#endif
                if "Bank Message Type" = "Bank Message Type"::"Long Message" then
                    if StrLen("Payment Message" + "Payment Message 2") > 420 then
                        Error(Text1090008, FieldCaption("Payment Message"), FieldCaption("Payment Message 2"), 420);
            end;
        }
        field(13515; "Planned Payment Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Payment date';
        }
    }

    keys
    {
        key(PaymentReference; "Journal Template Name", "Journal Batch Name", "Applies-to Doc. No.", "Payment Reference No.") { }
    }

    var
        BankNosCheck: Codeunit "Bank Nos Check FI";
        Text1090000: Label '%1 cannot exceed %2 characters.';
        Text1090006: Label '%1 cannot exceed %2 characters.';
        Text1090003: Label 'The combined length of %1 and %2 cannot exceed %3 characters.';
        Text1090008: Label 'The combined length of %1 and %2 cannot exceed %3 characters.';
#if not CLEAN30
        Feature: Codeunit "Banking Payments Feature FI";
#endif
}
