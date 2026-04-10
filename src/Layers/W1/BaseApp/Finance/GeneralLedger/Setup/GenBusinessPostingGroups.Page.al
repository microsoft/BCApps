// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using System.Utilities;

/// <summary>
/// List page for managing General Business Posting Groups used in posting setup combinations.
/// Provides interface for creating and maintaining business posting group codes that represent different business sectors or customer types.
/// </summary>
/// <remarks>
/// Business posting groups combine with product posting groups in General Posting Setup to determine G/L account assignments.
/// Used extensively across sales, purchase, and service modules for automated posting of transactions.
/// Essential setup for multi-dimensional posting group configurations and automated account determination.
/// </remarks>
page 312 "Gen. Business Posting Groups"
{
    AdditionalSearchTerms = 'posting setup,general business posting group';
    ApplicationArea = Basic, Suite;
    Caption = 'Gen. Business Posting Groups';
    PageType = List;
    SourceTable = "Gen. Business Posting Group";
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
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Def. VAT Bus. Posting Group"; Rec."Def. VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if Rec."Def. VAT Bus. Posting Group" <> xRec."Def. VAT Bus. Posting Group" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text000, Rec.Code, xRec."Def. VAT Bus. Posting Group"), true)
                            then
                                Error('');
                    end;
                }
                field("Auto Insert Default"; Rec."Auto Insert Default")
                {
                    ApplicationArea = Basic, Suite;
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
        area(processing)
        {
            action("&Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                RunObject = Page "General Posting Setup";
                RunPageLink = "Gen. Bus. Posting Group" = field(Code);
                ToolTip = 'View or edit how you want to set up combinations of general business and general product posting groups.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Setup_Promoted"; "&Setup")
                {
                }
            }
        }
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'This will change all occurrences of VAT Bus. Posting Group in G/L Account, Customer, and Vendor tables\where Gen. Bus. Posting Group is %1\and VAT Bus. Posting Group is %2. Are you sure that you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

