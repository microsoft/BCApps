// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Provides interface for managing standard general journal templates including header information and line definitions.
/// Enables users to configure reusable journal patterns with predefined account assignments and posting parameters.
/// </summary>
/// <remarks>
/// Standard journal template management interface combining header information with line details in a single view.
/// Supports creation and maintenance of reusable journal templates for common business transaction patterns.
/// Key features: Template code and description management, line detail configuration, template reuse workflows.
/// Integration: Works with standard journal creation processes and journal line generation from templates.
/// </remarks>
page 751 "Standard General Journal"
{
    Caption = 'Standard General Journal';
    PageType = ListPlus;
    SourceTable = "Standard General Journal";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
            }
            part(StdGenJnlLines; "Standard Gen. Journal Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Standard Journal Code" = field(Code);
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if xRec.Code = '' then
            Rec.SetRange(Code, Rec.Code);
    end;
}

