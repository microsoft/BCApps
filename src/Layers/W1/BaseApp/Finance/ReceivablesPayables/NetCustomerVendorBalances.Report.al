// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;

report 199 "Net Customer/Vendor Balances"
{
    Caption = 'Net Customer/Vendor Balances';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.") where("Blocked" = const(" "));
            RequestFilterFields = "No.";

            trigger OnPreDataItem()
            var
                NetCustVendBalancesMgt: Codeunit "Net Cust/Vend Balances Mgt.";
            begin
                NetCustVendBalancesMgt.NetCustVendBalances(Vendor, NetBalancesParameters);
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                field("Posting Date"; NetBalancesParameters."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the date on which the netted balance will be posted.';
                    trigger OnValidate()
                    begin
                        NetBalancesParameters.Validate("Posting Date");
                    end;
                }
                field("Document No."; NetBalancesParameters."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number for the G/L entries. This number will be incremented for each vendor, so be sure that the first document number ends with a number, for example, 001.';
                    trigger OnValidate()
                    begin
                        NetBalancesParameters.Validate("Posting Date");
                    end;
                }
                field(Description; NetBalancesParameters.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a short description of the netted balance. This can make it easier to find general ledger entries for netted amounts.';
                    trigger OnValidate()
                    begin
                        NetBalancesParameters.Validate(Description);
                    end;
                }
                field("On Hold"; NetBalancesParameters."On Hold")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'On Hold';
                    ToolTip = 'Specifies that related entries should not be modified or applied. This helps prevent problems with posting journal lines for netted amounts.';
                    trigger OnValidate()
                    begin
                        NetBalancesParameters.Validate("On Hold");
                    end;
                }
                field("Order of suggestion"; NetBalancesParameters."Order of Suggestion")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Order of suggestion';
                    ToolTip = 'Specifies the type of document to apply first.';
                    trigger OnValidate()
                    begin
                        NetBalancesParameters.Validate("Order of Suggestion");
                    end;
                }
            }
        }
        trigger OnOpenPage()
        begin
            NetBalancesParameters.Initialize();
        end;
    }

    var
        NetBalancesParameters: Record "Net Balances Parameters";

    procedure SetGenJnlLine(GenJournalLine: Record "Gen. Journal Line")
    begin
        NetBalancesParameters.Validate("Journal Template Name", GenJournalLine."Journal Template Name");
        NetBalancesParameters.Validate("Journal Batch Name", GenJournalLine."Journal Batch Name");
    end;
}

