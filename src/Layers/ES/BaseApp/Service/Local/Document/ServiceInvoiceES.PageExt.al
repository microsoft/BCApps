// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;

pageextension 10733 "Service Invoice ES" extends "Service Invoice"
{
    layout
    {
        addafter("Prices Including VAT")
        {
            field("VAT Registration No."; Rec."VAT Registration No.")
            {
                ApplicationArea = VAT;
                ToolTip = 'Specifies the customer''s VAT registration number.';
            }
        }
        addafter("Tax Area Code")
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
                group(Control1100014)
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
                    ToolTip = 'Specifies the Special Scheme Code.';

                    trigger OnValidate()
                    begin
                        SIIFirstSummaryDocNo := Copystr(Rec.GetSIIFirstSummaryDocNo(), 1, 35);
                        SIILastSummaryDocNo := Copystr(Rec.GetSIILastSummaryDocNo(), 1, 35);
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
                    ApplicationArea = VAT;
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
                field("Do Not Send To SII"; Rec."Do Not Send To SII")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the document must not be sent to SII.';
                }
            }
        }
        addafter("Location Code")
        {
            field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
            }
            field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
            }
        }
        addafter("Foreign Trade")
        {
            group(Payment)
            {
                Caption = 'Payment';
                field("Cust. Bank Acc. Code"; Rec."Cust. Bank Acc. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s bank code that was on the sales credit memo.';
                }
            }
        }
    }

    actions
    {
        addafter("Service Document Lo&g")
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
        addafter(DocAttach_Promoted)
        {
            actionref(SpecialSchemeCodes_Promoted; SpecialSchemeCodes)
            {
            }
        }
        modify("Calculate Invoice Discount")
        {
            Caption = 'Calculate &Inv. and Pmt. Discounts';
            ToolTip = 'Update the lines with any payment discount that is specified in the related payment terms.';
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDocHasRegimeCode();
        SIIFirstSummaryDocNo := Copystr(Rec.GetSIIFirstSummaryDocNo(), 1, 35);
        SIILastSummaryDocNo := Copystr(Rec.GetSIILastSummaryDocNo(), 1, 35);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSIIFields();
    end;

    trigger OnOpenPage()
    begin
        UpdateSIIFields();
    end;

    var
        SIIManagement: Codeunit "SII Management";
        DocHasMultipleRegimeCode: Boolean;
        OperationDescription: Text[500];
        MultipleSchemeCodesLbl: Label 'Multiple scheme codes';
        SIIFirstSummaryDocNo: Text[35];
        SIILastSummaryDocNo: Text[35];

    local procedure UpdateDocHasRegimeCode()
    var
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        DocHasMultipleRegimeCode := SIISchemeCodeMgt.SalesDocHasRegimeCodes(Rec);
    end;

    internal procedure UpdateSIIFields()
    begin
        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
        UpdateDocHasRegimeCode();
    end;
}