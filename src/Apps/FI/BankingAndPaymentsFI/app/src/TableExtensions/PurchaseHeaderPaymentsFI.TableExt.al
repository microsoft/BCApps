// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Document;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.SpendRequest;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Intercompany;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using Microsoft.Warehouse.Request;
using System.Automation;
using System.Environment.Configuration;
using System.Globalization;
using System.Reflection;
using System.Security.User;
using System.Threading;
using System.Utilities;

tableextension 13539 "Purchase Header Payments FI" extends "Purchase Header"
{
    fields
    {
        field(13512; "Bank Message Type"; Option)
        {
            DataClassification = CustomerContent;
            Caption = 'Message Type';
            InitValue = "Reference No.";
            OptionCaption = 'Reference No.,Invoice Information,Message,Long Message,Tax Message';
            OptionMembers = "Reference No.","Invoice Information",Message,"Long Message","Tax Message";

            trigger OnValidate()
            begin
#if not CLEAN30
                if not Feature.IsEnabled() then
                    exit;
#endif

                BankNosCheck.PurchMessageCheck(Rec);
            end;
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

                if ("Payment Message" <> '') and ("Bank Message Type" = "Bank Message Type"::"Reference No.") then begin
                    if StrLen("Payment Message") > 20 then
                        Error(Text1090000, FieldCaption("Payment Message"), 20);
                    BankNosCheck.InvReferenceCheck("Payment Message");
                end;

                if "Bank Message Type" = "Bank Message Type"::Message then
                    if StrLen("Payment Message") > 70 then
                        Error(Text1090000, FieldCaption("Payment Message"), 70);

                if ("Payment Message" <> '') and ("Bank Message Type" = "Bank Message Type"::"Tax Message") then begin
                    if StrLen("Payment Message") > 20 then
                        Error(Text1090000, FieldCaption("Payment Message"), 20);
                    BankNosCheck.InvReferenceCheck("Payment Message");
                end;
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
                        Error(Text1090003, FieldCaption("Payment Message"), FieldCaption("Payment Message 2"), 420);
            end;
        }
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
