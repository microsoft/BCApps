// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;

page 243 "Consolidation Setup"
{
    ApplicationArea = All;
    Caption = 'Consolidation Setup';
    PageType = Card;
    SourceTable = "Consolidation Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(API)
            {
                Caption = 'Cross Environment';
                field(ApiUrl; ApiUrl)
                {
                    Caption = 'Current environment''s API Endpoint';
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'The URL of the API for the current environment. Copy this value to set up the business unit in the consolidation company';
                    Editable = false;
                }
                field(AllowQuery; AllowQueryConsolidations)
                {
                    Caption = 'Enable company as subsidiary';
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this company can be queried for financial consolidations by other companies';

                    trigger OnValidate()
                    begin
                        GeneralLedgerSetup.Validate("Allow Query From Consolid.", AllowQueryConsolidations);
                        GeneralLedgerSetup.Modify();
                    end;
                }
                field(MaxAttempts; Rec.MaxAttempts)
                {
                    Caption = 'Maximum number of retries';
                    ApplicationArea = All;
                    ToolTip = 'Maximum number of retries for the complete consolidation process';
                    Visible = false;
                }
                field(PageSize; Rec.PageSize)
                {
                    ApplicationArea = All;
                    ToolTip = 'The number of records to import in each API call';
                    Caption = 'API page size';
                    Visible = false;
                }
                field(MaxAttempts429; Rec.MaxAttempts429)
                {
                    ApplicationArea = All;
                    ToolTip = 'The maximum number of times to retry API calls that return a 429 error';
                    Caption = 'Maximum attempts when receiving HTTP 429 responses';
                    Visible = false;
                }
                field(WaitMsRetries; Rec.WaitMsRetries)
                {
                    ApplicationArea = All;
                    ToolTip = 'The number of milliseconds to wait between retries';
                    Caption = 'Wait between retries (ms)';
                    Visible = false;
                }
            }
        }
    }

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ApiUrl: Text;
        AllowQueryConsolidations: Boolean;

    trigger OnOpenPage()
    begin
        GeneralLedgerSetup.GetRecordOnce();
        AllowQueryConsolidations := GeneralLedgerSetup."Allow Query From Consolid.";
        Rec.GetOrCreateWithDefaults();
        ApiUrl := GetUrl(ClientType::Api);
    end;
}
