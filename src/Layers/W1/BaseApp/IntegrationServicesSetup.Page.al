// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration;

using Microsoft.API;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Integration.Graph;

page 1876 "Integration Services Setup"
{
    Caption = 'Integration Services Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "API Entities Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group("Customer Payments Service")
            {
                field("Customer Payments Batch Name"; Rec."Customer Payments Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Default Customer Payments Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the default customer payments batch name of the integration journal.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenJournalLine: Record "Gen. Journal Line";
                        GraphMgtCustomerPaymentsLines: Codeunit "Graph Mgt - Customer Payments";
                    begin
                        GraphMgtCustomerPaymentsLines.SetCustomerPaymentsFilters(GenJournalLine);

                        CurrPage.SaveRecord();
                        GenJnlManagement.LookupName(Rec."Customer Payments Batch Name", GenJournalLine);
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.SafeGet();
    end;

    var
        GenJnlManagement: Codeunit GenJnlManagement;
}

