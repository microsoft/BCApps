#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

page 9653 "Report Layouts Part"
{
    Caption = 'Report Layouts Part';
    Editable = false;
    PageType = ListPart;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the system "Report Layouts" page. This page will be removed in a future version.';
    ObsoleteTag = '29.0';
#pragma warning disable AL0432
    SourceTable = "Custom Report Layout";
#pragma warning restore AL0432
    SourceTableView = sorting("Report ID", "Company Name", Type);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Width = 10;
                }
            }
        }
    }

    actions
    {
    }
}
#endif

