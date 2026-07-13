// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.EServices.EDocument;

/// <summary>
/// Provides editing capabilities for specific fields on posted sales credit memos that can be modified after posting.
/// </summary>
pageextension 7000148 "SII Pstd. Sales Cr.Memo Update" extends "Pstd. Sales Cr. Memo - Update"
{
    layout
    {
        addbefore("Correction Type")
        {
            field(OperationDescription; OperationDescription)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Operation Description';
                Editable = true;
                MultiLine = true;
                ToolTip = 'Specifies the Operation Description.';

                trigger OnValidate()
                var
                    SIIManagement: Codeunit "SII Management";
                begin
                    SIIManagement.SplitOperationDescription(OperationDescription, Rec."Operation Description", Rec."Operation Description 2");
                    Rec.Validate("Operation Description");
                    Rec.Validate("Operation Description 2");
                end;
            }
            field("Special Scheme Code"; Rec."Special Scheme Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = true;
                ToolTip = 'Specifies the Special Scheme Code.';
            }
            field("Cr. Memo Type"; Rec."Cr. Memo Type")
            {
                ApplicationArea = Basic, Suite;
                Editable = true;
                ToolTip = 'Specifies the Credit Memo Type.';

                trigger OnValidate()
                begin
                    SIIFirstSummaryDocNo := '';
                    SIILastSummaryDocNo := '';
                end;
            }
        }
        addafter("Corrected Invoice No.")
        {
            field("ID Type"; Rec."ID Type")
            {
                ApplicationArea = Basic, Suite;
                Editable = true;
                ToolTip = 'Specifies the ID Type.';
            }
            field("Succeeded Company Name"; Rec."Succeeded Company Name")
            {
                ApplicationArea = Basic, Suite;
                Editable = true;
                ToolTip = 'Specifies the name of the company successor in connection with corporate restructuring.';
            }
            field("Succeeded VAT Registration No."; Rec."Succeeded VAT Registration No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = true;
                ToolTip = 'Specifies the VAT registration number of the company successor in connection with corporate restructuring.';
            }
            field("SII First Summary Doc. No."; SIIFirstSummaryDocNo)
            {
                Caption = 'First Summary Doc. No.';
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the first number in the series of the summary entry. This field applies to F4-type invoices only.';
                trigger OnValidate()
                begin
                    Rec.SetSIIFirstSummaryDocNo(SIIFirstSummaryDocNo);
                end;
            }
            field("SII Last Summary Doc. No."; SIILastSummaryDocNo)
            {
                Caption = 'Last Summary Doc. No.';
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the last number in the series of the summary entry. This field applies to F4-type invoices only.';
                trigger OnValidate()
                begin
                    Rec.SetSIILastSummaryDocNo(SIILastSummaryDocNo);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
    end;

    trigger OnAfterGetRecord()
    begin
        SIIFirstSummaryDocNo := CopyStr(Rec.GetSIIFirstSummaryDocNo(), 1, 35);
        SIILastSummaryDocNo := CopyStr(Rec.GetSIILastSummaryDocNo(), 1, 35);
    end;

    var
        OperationDescription: Text[500];
        SIIFirstSummaryDocNo: Text[35];
        SIILastSummaryDocNo: Text[35];
}