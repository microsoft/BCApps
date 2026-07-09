// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.History;

pageextension 7000105 "SII Posted Purchase Invoice" extends "Posted Purchase Invoice"
{
    layout
    {
        addafter("Expected Receipt Date")
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
                        ToolTip = 'Indicates that this document has multiple regime codes. Click the Special Scheme Codes action to view details.';

                        trigger OnDrillDown()
                        var
                            SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
                        begin
                            SIISchemeCodeMgt.PurchDrillDownRegimeCodes(Rec);
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
        addafter(Approvals)
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
                    SIISchemeCodeMgt.PurchDrillDownRegimeCodes(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        addafter(Dimensions_Promoted)
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

    local procedure UpdateDocHasRegimeCode()
    var
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        DocHasMultipleRegimeCode := SIISchemeCodeMgt.PurchDocHasRegimeCodes(Rec);
    end;
}
