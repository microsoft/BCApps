// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Finance.Currency;
using Microsoft.Integration.Dataverse;

page 5345 "CRM TransactionCurrency List"
{
    ApplicationArea = Suite;
    Caption = 'Transaction Currencies - Dataverse';
    AdditionalSearchTerms = 'Transaction Currencies CDS, Transaction Currencies Common Data Service';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Transactioncurrency";
    SourceTableView = sorting(ISOCurrencyCode);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(ISOCurrencyCode; Rec.ISOCurrencyCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'ISO Currency Code';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies the ISO currency code, which is required in Dataverse.';
                }
                field(CurrencyName; Rec.CurrencyName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Name';
                    ToolTip = 'Specifies the name of the currency.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dataverse record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Currencies';
                Image = FilterLines;
                ToolTip = 'Do not show coupled currencies.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Currencies';
                Image = ClearFilter;
                ToolTip = 'Show coupled currencies.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(Rec.TransactionCurrencyId, DATABASE::Currency, RecordID) then
            if CurrentlyCoupledCRMTransactioncurrency.TransactionCurrencyId = Rec.TransactionCurrencyId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Rec.Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Rec.Mark(true);
        end;
    end;

    trigger OnInit()
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        Rec.FilterGroup(4);
        Rec.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Transactioncurrency"));
        Rec.FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMTransactioncurrency: Record "CRM Transactioncurrency";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMTransactioncurrency(CRMTransactioncurrency: Record "CRM Transactioncurrency")
    begin
        CurrentlyCoupledCRMTransactioncurrency := CRMTransactioncurrency;
    end;
}

