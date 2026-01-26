// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;


pageextension 10730 "Service Order ES" extends "Service Order"
{
    layout
    {
        addafter("VAT Bus. Posting Group")
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
                    ToolTip = 'Specifies the Special Scheme Code.';
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