// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Setup;

using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;

page 463 "Jobs Setup"
{
    AccessByPermission = TableData Job = R;
    AdditionalSearchTerms = 'project setup, Jobs Setup';
    ApplicationArea = Jobs;
    Caption = 'Projects Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Jobs Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Automatic Update Job Item Cost"; Rec."Automatic Update Job Item Cost")
                {
                    ApplicationArea = Jobs;
                }
                field("Apply Usage Link by Default"; Rec."Apply Usage Link by Default")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Sched/Contract Lines Def"; Rec."Allow Sched/Contract Lines Def")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Allow Budget/Billable Lines Def';
                }
                field("Default WIP Method"; Rec."Default WIP Method")
                {
                    ApplicationArea = Jobs;
                }
                field("Default WIP Posting Method"; Rec."Default WIP Posting Method")
                {
                    ApplicationArea = Jobs;
                }
                field("Default Job Posting Group"; Rec."Default Job Posting Group")
                {
                    ApplicationArea = Jobs;
                }
                field("Default Task Billing Method"; Rec."Default Task Billing Method")
                {
                    ApplicationArea = Jobs;
                }
                field("Logo Position on Documents"; Rec."Logo Position on Documents")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                }
                field("Document No. Is Job No."; Rec."Document No. Is Job No.")
                {
                    ApplicationArea = Jobs;
                }
            }
            group(Prices)
            {
                Caption = 'Prices';
                Visible = ExtendedPriceEnabled;
                field("Default Sales Price List Code"; Rec."Default Sales Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Default Purch Price List Code"; Rec."Default Purch Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Job Nos."; Rec."Job Nos.")
                {
                    ApplicationArea = Jobs;
                }
                field("Job WIP Nos."; Rec."Job WIP Nos.")
                {
                    ApplicationArea = Jobs;
                }
                field("Price List Nos."; Rec."Price List Nos.")
                {
                    ApplicationArea = Jobs;
                    Visible = ExtendedPriceEnabled;
                }
            }
            group(Archiving)
            {
                Caption = 'Archiving';

                field("Archive Orders"; Rec."Archive Jobs")
                {
                    ApplicationArea = Jobs;
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
    }

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        ExtendedPriceEnabled: Boolean;
}

