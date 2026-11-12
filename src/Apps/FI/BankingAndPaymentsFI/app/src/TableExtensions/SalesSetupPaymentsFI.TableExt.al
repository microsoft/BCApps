// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Sales.Setup;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Upgrade;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Environment;
using System.Threading;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;

tableextension 13555 "Sales Setup Payments FI" extends "Sales & Receivables Setup"
{
    fields
    {
        field(13523; "Use Invoice No. in Reference"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Invoice No.';
        }
        field(13524; "Use Customer No. in Reference"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Customer No.';
        }
        field(13525; "Use Date in Reference"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Date';
        }
        field(13526; "Payment Reference Nos."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Reference Nos.';
            TableRelation = "No. Series".Code;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
#if not CLEAN30
                if not Feature.IsEnabled() then
                    exit;
#endif
                if "Payment Reference Nos." <> '' then begin
                    NoSeriesLine.LockTable();

                    if not NoSeries.GetNoSeriesLine(NoSeriesLine, "Payment Reference Nos.", WorkDate(), true) then begin
                        NoSeriesLine.SetRange("Starting Date");
                        if not NoSeriesLine.FindFirst() then
                            Error(Text1090000, "Payment Reference Nos.", WorkDate());
                    end else
                        if not Evaluate(TestNo, NoSeriesLine."Starting No.") then
                            Error(Text1090001, "Payment Reference Nos.");
                end;
            end;
        }
        field(13527; "Default Reference Number"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Number';
        }
        field(13528; "Print Payment Reference"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Print Reference No.';
        }
    }

    var
        NoSeriesLine: Record "No. Series Line";
        TestNo: Decimal;
        Text1090000: Label 'You cannot assign new numbers from the number series %1 on %2.';
        Text1090001: Label 'Illegal characters in No. Series %1; only numbers between 0-9 allowed.';
#if not CLEAN30
        Feature: Codeunit "Banking Payments Feature FI";
#endif
}
