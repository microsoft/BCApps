// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Utilities;
using System.Text;

page 12127 "Annual VAT Comm. Preview"
{
    Caption = 'Annual VAT Comm. Preview';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "VAT Statement Name";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Statement Template Name"; Rec."Statement Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the template.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name.';
                }
                field("Activity Code"; ActivityCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Activity Code';
                    TableRelation = "Activity Code".Code;
                    ToolTip = 'Specifies a code that describes a primary activity for the company.';

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Activity Code Filter", ActivityCode);
                        CurrPage.Update();
                    end;
                }
                field("Date Filter"; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the date filter.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        Rec.SetFilter("Date Filter", DateFilter);
                        CurrPage.Update();
                    end;
                }
            }
            part(VATStatementLineSubForm; "VAT Statement Preview Line")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Statement Template Name" = field("Statement Template Name"),
                              "Statement Name" = field(Name);
                SubPageView = sorting("Statement Template Name", "Statement Name", "Line No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export the document.';

                    trigger OnAction()
                    begin
                        Rec.Export();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Export_Promoted; Export)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSubForm();
    end;

    trigger OnInit()
    begin
        Selection := Selection::"Open and Closed";
        PeriodSelection := PeriodSelection::"Within Period";
    end;

    trigger OnOpenPage()
    begin
        UpdateSubForm();
    end;

    var
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        ActivityCode: Code[6];
        DateFilter: Text;

    [Scope('OnPrem')]
    procedure UpdateSubForm()
    begin
        CurrPage.VATStatementLineSubForm.PAGE.UpdateForm(Rec, Selection, PeriodSelection, false, '');
    end;
}

