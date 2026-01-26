// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;


pageextension 10738 "Posted Service Invoice ES" extends "Posted Service Invoice"
{
    layout
    {
        addafter("Tax Area Code")
        {
            group("SII Information")
            {
                Caption = 'SII Information';
                field(OperationDescription; OperationDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Operation Description';
                    Editable = false;
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
                group(Control1100013)
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
                    Editable = false;
                    ToolTip = 'Specifies the Special Scheme Code.';
                }
                field("Invoice Type"; Rec."Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the Invoice Type.';
                }
                field("ID Type"; Rec."ID Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID Type.';
                }
                field("Succeeded Company Name"; Rec."Succeeded Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the company successor in connection with corporate restructuring.';
                }
                field("Succeeded VAT Registration No."; Rec."Succeeded VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT registration number of the company successor in connection with corporate restructuring.';
                }
                field("Issued By Third Party"; Rec."Issued By Third Party")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the credit memo was issued by a third party.';
                }
                field("SII First Summary Doc. No."; Rec.GetSIIFirstSummaryDocNo())
                {
                    Caption = 'First Summary Doc. No.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the first number in the series of the summary entry. This field applies to F4-type invoices only.';
                }
                field("SII Last Summary Doc. No."; Rec.GetSIILastSummaryDocNo())
                {
                    Caption = 'Last Summary Doc. No.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the last number in the series of the summary entry. This field applies to F4-type invoices only.';
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
        addafter("&Navigate")
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(FindCorrectiveInvoices)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Find Corrective Invoices';
                    Image = FindCreditMemo;
                    RunObject = Page "Posted Service Credit Memos";
                    RunPageLink = "Corrected Invoice No." = field("No.");
                    ToolTip = 'View related corrective invoices. You can send a corrective invoice when there is an error or dispute that affects a VAT amount or fiscal data. This invoice includes all legally required data and refers to the original invoice or invoices.';
                }
            }
        }
        addafter(DocAttach_Promoted)
        {
            actionref(SpecialSchemeCodes_Promoted; SpecialSchemeCodes)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDocHasRegimeCode();
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

    local procedure UpdateDocHasRegimeCode()
    var
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        DocHasMultipleRegimeCode := SIISchemeCodeMgt.SalesDocHasRegimeCodes(Rec);
    end;

    local procedure UpdateSIIFields()
    begin
        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
        UpdateDocHasRegimeCode();
    end;
}