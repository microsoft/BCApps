// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Telemetry;

page 11002 "Data Exports"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Data Exports';
    PageType = List;
    SourceTable = "Data Export";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for a data export.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a short description of the data export.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Export)
            {
                Caption = 'Export';
                action("Data Export Record Definition")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record Definitions';
                    Image = XMLFile;
                    RunObject = Page "Data Export Record Definitions";
                    RunPageLink = "Data Export Code" = field(Code);
                    RunPageView = sorting("Data Export Code", "Data Exp. Rec. Type Code");
                    ToolTip = 'Add record definitions to the data export. Each record definition represents a set of data that will be exported.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Export', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Data Export Record Definition_Promoted"; "Data Export Record Definition")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DataExportManagement: Codeunit "Data Export Management";
        DataTok: Label 'DACH Data Export', Locked = true;
    begin
        FeatureTelemetry.LogUptake('0001Q0M', DataTok, Enum::"Feature Uptake Status"::Discovered);
        DataExportManagement.CreateDataExportForPersonalAndGLAccounting();
        DataExportManagement.CreateDataExportForFAAccounting();
        DataExportManagement.CreateDataExportForInvoiceAndItemAccounting();
    end;
}

