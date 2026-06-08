// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

page 46868 "BC14 Co. Migration Settings"
{
    PageType = ListPart;
    SourceTable = BC14CompanyMigrationInfo;
    SourceTableView = sorting(Name) where(Name = filter(<> ''));
    Caption = 'BC14 Company Migration Settings List';
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Companies)
            {
                ShowCaption = false;

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company name. Click to open the full per-company settings card with detailed status.';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"BC14 Company Migration Status", Rec);
                    end;
                }
                field("Stop On First Error"; Rec."Stop On First Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether migration should stop immediately when a transformation error is found for this company.';
                    Editable = RowEditable;
                }
                field("Migrate GL Module"; Rec."Migrate GL Module")
                {
                    ApplicationArea = All;
                    Caption = 'GL';
                    ToolTip = 'Specifies whether to migrate General Ledger data for this company. Locked after migration has started.';
                    Editable = RowEditable;
                }
                field("Migrate Receivables Module"; Rec."Migrate Receivables Module")
                {
                    ApplicationArea = All;
                    Caption = 'Receivables';
                    ToolTip = 'Specifies whether to migrate Customer data for this company. Locked after migration has started.';
                    Editable = RowEditable;
                }
                field("Migrate Payables Module"; Rec."Migrate Payables Module")
                {
                    ApplicationArea = All;
                    Caption = 'Payables';
                    ToolTip = 'Specifies whether to migrate Vendor data for this company. Locked after migration has started.';
                    Editable = RowEditable;
                }
                field("Migrate Inventory Module"; Rec."Migrate Inventory Module")
                {
                    ApplicationArea = All;
                    Caption = 'Inventory';
                    ToolTip = 'Specifies whether to migrate Item data for this company. Locked after migration has started.';
                    Editable = RowEditable;
                }
                field("Skip Posting Journal Batches"; Rec."Skip Posting Journal Batches")
                {
                    ApplicationArea = All;
                    Caption = 'Skip Posting';
                    ToolTip = 'Specifies whether to skip automatic posting of migration journal batches. Locked after migration has started.';
                    Editable = RowEditable;
                }
                field("Data Migration Started"; Rec."Data Migration Started")
                {
                    ApplicationArea = All;
                    Caption = 'Started';
                    ToolTip = 'Specifies whether data migration has started for this company. Once started, settings on this row are locked.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RowEditable := not Rec."Data Migration Started";
    end;

    var
        RowEditable: Boolean;
}
