// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Intercompany.GLAccount;

page 536 Dimensions
{
    ApplicationArea = Dimensions;
    Caption = 'Dimensions';
    PageType = List;
    AboutTitle = 'About Dimensions';
    AboutText = 'Define and manage dimensions to categorize financial data, transactions, and documents for detailed analysis and reporting across your organization. Set up dimension codes, names, and values to enable flexible breakdowns by project, department, or other categories, supporting company-wide consistency and granular filtering.';
    SourceTable = Dimension;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the name of the dimension code.';
                }
                field("Code Caption"; Rec."Code Caption")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the caption of the dimension code. This is displayed as the name of dimension code fields.';
                }
                field("Filter Caption"; Rec."Filter Caption")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the caption of the dimension code when used as a filter. This is displayed as the name of dimension filter fields.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a description of the dimension code.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Map-to IC Dimension Code"; Rec."Map-to IC Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which intercompany dimension corresponds to the dimension on the line.';
                    Visible = false;
                }
                field("Consolidation Code"; Rec."Consolidation Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code that is used for consolidation.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Dimension")
            {
                Caption = '&Dimension';
                Image = Dimensions;
                action("Dimension &Values")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimension &Values';
                    Image = Dimensions;
                    RunObject = Page "Dimension Values";
                    RunPageLink = "Dimension Code" = field(Code);
                    ToolTip = 'View or edit the dimension values for the current dimension.';
                }
                action("Account Type De&fault Dim.")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Account Type De&fault Dim.';
                    Image = DefaultDimension;
                    RunObject = Page "Account Type Default Dim.";
                    RunPageLink = "Dimension Code" = field(Code),
                                  "No." = const('');
                    ToolTip = 'Specify default dimension settings for account types such as customers, vendors, or items. For example, you can make a dimension required.';
                }
                action("Allowed Dimension Values per Account")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Allowed Dimension Values per Account';
                    Image = DefaultDimension;
                    RunObject = Page "Dim. Values per Account";
                    RunPageLink = "Dimension Code" = field(Code);
                    ToolTip = 'Specify allowed dimension values settings for accounts such as customers, vendors, or items.';
                }
                action(Translations)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Translations';
                    Image = Translations;
                    RunObject = Page "Dimension Translations";
                    RunPageLink = Code = field(Code);
                    ToolTip = 'View or edit translated dimensions. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(MapToICDimWithSameCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Map to IC Dim. with Same Code';
                    Image = MapDimensions;
                    ToolTip = 'Specify which intercompany dimension corresponds to the dimension on the line. When you enter a dimension code on an intercompany sales or purchase line, the program will put the corresponding intercompany dimension code on the line that is sent to your intercompany partner.';

                    trigger OnAction()
                    var
                        Dimension: Record Dimension;
                        ICMapping: Codeunit "IC Mapping";
                    begin
                        CurrPage.SetSelectionFilter(Dimension);
                        if Dimension.Find('-') and Confirm(Text000) then
                            repeat
                                ICMapping.MapOutgoingICDimensions(Dimension);
                            until Dimension.Next() = 0;
                    end;
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
                Caption = 'Dimension', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Dimension &Values_Promoted"; "Dimension &Values")
                {
                }
                actionref("Account Type De&fault Dim._Promoted"; "Account Type De&fault Dim.")
                {
                }
                actionref("Allowed Dimension Values per Account_Promoted"; "Allowed Dimension Values per Account")
                {
                }
                actionref(Translations_Promoted; Translations)
                {
                }
            }
        }
    }

    var
#pragma warning disable AA0074
        Text000: Label 'Are you sure you want to map the selected lines?';
#pragma warning restore AA0074
}

