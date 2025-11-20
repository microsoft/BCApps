// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Integration.Graph;

page 5493 "Cash Flow Statement Entity"
{
    Caption = 'cashFlowStatement', Locked = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Acc. Schedule Line Entity";
    PageType = List;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(lineNumber; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Line No..';
                    Caption = 'LineNumber', Locked = true;
                }
                field(display; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Description.';
                    Caption = 'Description', Locked = true;
                }
                field(netChange; Rec."Net Change")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Net Change.';
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'NetChange', Locked = true;
                }
                field(lineType; Rec."Line Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Line Type.';
                    Caption = 'LineType', Locked = true;
                }
                field(indentation; Rec.Indentation)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Indentation.';
                    Caption = 'Indentation', Locked = true;
                }
                field(dateFilter; Rec."Date Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Date Filter.';
                    Caption = 'DateFilter', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        GraphMgtReports: Codeunit "Graph Mgt - Reports";
        RecVariant: Variant;
        ReportAPIType: Option "Balance Sheet","Income Statement","Trial Balance","CashFlow Statement","Aged Accounts Payable","Aged Accounts Receivable","Retained Earnings";
    begin
        RecVariant := Rec;
        GraphMgtReports.SetUpAccountScheduleBaseAPIDataWrapper(RecVariant, ReportAPIType::"CashFlow Statement");
    end;
}
