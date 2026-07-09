// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.Document;

pageextension 7000107 "SII Sales Invoice" extends "Sales Invoice"
{
    layout
    {
        addafter("Location Code")
        {
            group("SII Information")
            {
                Caption = 'SII Information';
                field(OperationDescription; OperationDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Operation Description';
                    MultiLine = true;
                    ToolTip = 'Specifies the Operation Description.';

                    trigger OnValidate()
                    var
                        SIIManagement: Codeunit "SII Management";
                    begin
                        SIIManagement.SplitOperationDescription(OperationDescription, Rec."Operation Description", Rec."Operation Description 2");
                        Rec.Validate("Operation Description");
                        Rec.Validate("Operation Description 2");
                        Rec.Modify(true);
                    end;
                }
                group(Control1100009)
                {
                    ShowCaption = false;
                    Visible = DocHasMultipleRegimeCode;
                    field(MultipleSchemeCodesControl; MultipleSchemeCodesLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        Style = StandardAccent;
                        StyleExpr = true;

                        trigger OnDrillDown()
                        var
                            SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
                        begin
                            SIISchemeCodeMgt.SalesDrillDownRegimeCodes(Rec);
                        end;
                    }
                }
                field("Special Scheme Code"; Rec."Special Scheme Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = not DocHasMultipleRegimeCode;
                    ToolTip = 'Specifies the Special Scheme Code.';
                }
                field("Invoice Type"; Rec."Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Invoice Type.';

                    trigger OnValidate()
                    begin
                        SIIFirstSummaryDocNo := '';
                        SIILastSummaryDocNo := '';
                    end;
                }
                field("ID Type"; Rec."ID Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID Type.';
                }
                field("Succeeded Company Name"; Rec."Succeeded Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company successor in connection with corporate restructuring.';
                }
                field("Succeeded VAT Registration No."; Rec."Succeeded VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number of the company successor in connection with corporate restructuring.';
                }
                field("Issued By Third Party"; Rec."Issued By Third Party")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the invoice was issued by a third party.';
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
                field("Do Not Send To SII"; Rec."Do Not Send To SII")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the document must not be sent to SII.';
                }
            }
        }
    }
    actions
    {
        addafter(DocAttach)
        {
            action(SpecialSchemeCodes)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Special Scheme Codes';
                Image = Allocations;
                ToolTip = 'View or edit the list of special scheme codes that related to the current document for VAT reporting.';

                trigger OnAction()
                var
                    SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
                begin
                    SIISchemeCodeMgt.SalesDrillDownRegimeCodes(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        addafter(Approvals_Promoted)
        {
            actionref(SpecialSchemeCodes_Promoted; SpecialSchemeCodes)
            {
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
        UpdateDocHasRegimeCode();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateDocHasRegimeCode();
        SIIFirstSummaryDocNo := CopyStr(Rec.GetSIIFirstSummaryDocNo(), 1, 35);
        SIILastSummaryDocNo := CopyStr(Rec.GetSIILastSummaryDocNo(), 1, 35);
    end;

    trigger OnOpenPage()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
        UpdateDocHasRegimeCode();
    end;

    var
        OperationDescription: Text[500];
        DocHasMultipleRegimeCode: Boolean;
#pragma warning disable AA0074
        MultipleSchemeCodesLbl: Label 'Multiple scheme codes';
#pragma warning restore AA0074
        SIIFirstSummaryDocNo: Text[35];
        SIILastSummaryDocNo: Text[35];

    local procedure UpdateDocHasRegimeCode()
    var
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        DocHasMultipleRegimeCode := SIISchemeCodeMgt.SalesDocHasRegimeCodes(Rec);
    end;
}
