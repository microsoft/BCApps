// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Finance.GeneralLedger.Journal;

page 6406 "Gen. Journal Batch Entity"
{
    Caption = 'workflowGenJournalBatches', Locked = true;
    DelayedInsert = true;
    SourceTable = "Gen. Journal Batch";
    PageType = List;
    ODataKeyFields = SystemId;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(journalTemplateName; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Template Name', Locked = true;
                }
                field(name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name', Locked = true;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                }
                field(reasonCode; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Reason Code', Locked = true;
                }
                field(balAccountType; Rec."Bal. Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account Type', Locked = true;
                }
                field(balAccountNumber; Rec."Bal. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account No.', Locked = true;
                }
                field(numberSeries; Rec."No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'No. Series', Locked = true;
                }
                field(postingNumberSeries; Rec."Posting No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No. Series', Locked = true;
                }
                field(copyVatSetupToJnlLines; Rec."Copy VAT Setup to Jnl. Lines")
                {
                    ApplicationArea = All;
                    Caption = 'Copy VAT Setup to Jnl. Lines', Locked = true;
                }
                field(allowVatDifference; Rec."Allow VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'Allow VAT Difference', Locked = true;
                }
                field(allowPaymentExport; Rec."Allow Payment Export")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Payment Export', Locked = true;
                }
                field(bankStatementImportFormat; Rec."Bank Statement Import Format")
                {
                    ApplicationArea = All;
                    Caption = 'Bank Statement Import Format', Locked = true;
                }
                field(templateType; Rec."Template Type")
                {
                    ApplicationArea = All;
                    Caption = 'Template Type', Locked = true;
                }
                field(recurring; Rec.Recurring)
                {
                    ApplicationArea = All;
                    Caption = 'Recurring', Locked = true;
                }
                field(suggestBalancingAmount; Rec."Suggest Balancing Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Suggest Balancing Amount', Locked = true;
                }
                field(lastModifiedDatetime; Rec."Last Modified DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modified DateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}

