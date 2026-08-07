// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment.Configuration;
using System.Reflection;

/// <summary>
/// Administrative list over the platform Tenant Report Layout Cfg table, used to configure default header/footer and theme parts that apply to body layouts during the Composite Layout Merge.
/// </summary>
/// <remarks>
/// Report ID 0 acts as a global wildcard. Empty Layout Name applies to all layouts for the given Report ID. Empty Company Name applies to all companies. The platform validates on insert and modify that any Header Part Name resolves to a Header/Footer-subtype layout and any Theme Part Name resolves to a Theme-subtype layout.
/// </remarks>
page 9663 "Tenant Report Layout Cfg"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tenant Report Layout Configuration';
    AdditionalSearchTerms = 'Composite Layout, Document Theme, Header Footer Part';
    PageType = List;
    SourceTable = "Tenant Report Layout Cfg";
    UsageCategory = Administration;
    Editable = true;
    Extensible = false;
    Permissions = tabledata "Tenant Report Layout Cfg" = RIMD;
    AboutTitle = 'About report layout configuration';
    AboutText = 'Configure which theme and header/footer parts apply to report layouts during the Composite Layout Merge. Use Report ID 0 as a global wildcard for all reports.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report this configuration applies to. Use 0 as a global wildcard that applies to all reports; in that case Layout Name must be empty.';

                    trigger OnValidate()
                    begin
                        ValidateGlobalWildcardRule();
                    end;
                }
                field("Layout Name"; Rec."Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the body layout this configuration applies to. Empty applies to all layouts for the given Report ID.';

                    trigger OnValidate()
                    begin
                        ValidateGlobalWildcardRule();
                    end;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company this configuration applies to. Empty applies to all companies.';
                }
                field("Header Part Name"; Rec."Header Part Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Header/Footer Part';
                    Editable = false;
                    ToolTip = 'Specifies the header/footer layout part. Use the assist-edit (...) to pick an approved part.';

                    trigger OnAssistEdit()
                    begin
                        SetHeaderPart();
                    end;
                }
                field("Theme Part Name"; Rec."Theme Part Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Theme Part';
                    Editable = false;
                    ToolTip = 'Specifies the theme layout part. Use the assist-edit (...) to pick an approved part.';

                    trigger OnAssistEdit()
                    begin
                        SetThemePart();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        if not FeatureKeyManagement.IsDocumentReportExperienceEnabled() then
            Error(FeatureNotEnabledErr);
    end;

    local procedure SetHeaderPart()
    var
        Composite: Text;
    begin
        if not LookupHelper.LookupCompositePart(Enum::"Report Layout Subtype"::HeaderFooter, Composite) then
            exit;
        Rec."Header Part Name" := CopyStr(Composite, 1, MaxStrLen(Rec."Header Part Name"));
        CurrPage.Update(true);
    end;

    local procedure SetThemePart()
    var
        Composite: Text;
    begin
        if not LookupHelper.LookupCompositePart(Enum::"Report Layout Subtype"::Theme, Composite) then
            exit;
        Rec."Theme Part Name" := CopyStr(Composite, 1, MaxStrLen(Rec."Theme Part Name"));
        CurrPage.Update(true);
    end;

    local procedure ValidateGlobalWildcardRule()
    begin
        if (Rec."Report ID" = 0) and (Rec."Layout Name" <> '') then
            Error(GlobalWildcardCannotHaveLayoutNameErr);
    end;

    var
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        FeatureNotEnabledErr: Label 'The Composite Layout feature is gated by the Document Report Experience preview. Enable it in Feature Management before opening this page.';
        GlobalWildcardCannotHaveLayoutNameErr: Label 'When Report ID is 0 (global wildcard), Layout Name must be empty.';
}
