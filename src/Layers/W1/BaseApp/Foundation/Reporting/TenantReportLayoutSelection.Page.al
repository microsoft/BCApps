// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment.Configuration;

/// <summary>
/// Read-only administrative view over the platform Tenant Report Layout Selection table, used to inspect per-report/company/user body layout selections and the optional header/footer and theme part references that drive the Composite Layout Merge.
/// </summary>
page 9664 "Tenant Report Layout Selection"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tenant Report Layout Selection';
    AdditionalSearchTerms = 'Header, Footer, Theme, Composite Layout';
    PageType = List;
    SourceTable = "Tenant Report Layout Selection";
    UsageCategory = Administration;
    Editable = false;
    Extensible = false;
    Permissions = tabledata "Tenant Report Layout Selection" = R;
    AboutTitle = 'About report layout selections';
    AboutText = 'View per-report and per-company body layout selections and inspect which header/footer and theme parts are configured for the Composite Layout Merge.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report this selection applies to.';
                }
                field("Layout Name"; Rec."Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the body layout selected for this report, company, and user combination.';
                }
                field("App ID"; Rec."App ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the application id that owns the body layout, or the empty guid for a user-defined layout.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company this selection applies to. Empty applies to all companies.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user this selection applies to. Empty applies to all users (tenant-wide selection).';
                }
                field(HeaderPartDisplay; HeaderPartDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Header/Footer Part';
                    Visible = DocumentReportExperienceEnabled;
                    ToolTip = 'Specifies the header/footer layout part composed on top of the body layout when this report is rendered. Configured via the Tenant Report Layout Configuration page.';
                }
                field(ThemePartDisplay; ThemePartDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Theme Part';
                    Visible = DocumentReportExperienceEnabled;
                    ToolTip = 'Specifies the theme layout part whose styles override the merged result when this report is rendered. Configured via the Tenant Report Layout Configuration page.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestCompositeRender)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test composite render';
                Image = TestReport;
                Visible = DocumentReportExperienceEnabled;
                ToolTip = 'Runs the selected report so the Composite Layout Merge can be verified end-to-end against the configured Header/Footer and Theme parts.';

                trigger OnAction()
                begin
                    if Rec."Report ID" = 0 then
                        Error(SelectReportFirstErr);
                    Report.Run(Rec."Report ID");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(TestCompositeRender_Promoted; TestCompositeRender) { }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        HeaderPartDisplay := LookupHelper.DecodeLayoutName(Rec."Header Part Name");
        ThemePartDisplay := LookupHelper.DecodeLayoutName(Rec."Theme Part Name");
    end;

    trigger OnOpenPage()
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        DocumentReportExperienceEnabled := FeatureKeyManagement.IsDocumentReportExperienceEnabled();
    end;

    var
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        DocumentReportExperienceEnabled: Boolean;
        HeaderPartDisplay: Text;
        ThemePartDisplay: Text;
        SelectReportFirstErr: Label 'Select a row with a Report ID before running a test render.';
}
