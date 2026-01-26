// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 10744 "340 Declaration Lines"
{
    Caption = '340 Declaration Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "340 Declaration Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the document number on the declaration entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the document type associated with the declaration entry.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document date of the posted document.';
                }
                field("Customer/Vendor No."; Rec."Customer/Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the customer or vendor number that is associated with the posted invoice or credit memo.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total invoice amount, excluding the VAT amount and EC amount on the declaration entry.';
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT percentage on the declaration entry.';
                }
                field("EC %"; Rec."EC %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percent of Equivalence Charge (EC) on the declaration entry.';
                }
                field("VAT Amount / EC Amount"; Rec."VAT Amount / EC Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT amount and Equivalence Charge (EC) amount.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT amount that is calculated from the entries, based on the same VAT percentage.';
                }
                field("EC Amount"; Rec."EC Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the calculated Equivalence Charge (EC) amount.';
                }
                field("Amount Including VAT / EC"; Rec."Amount Including VAT / EC")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount including VAT amount and EC amount on the declaration line.';
                }
                field("Operation Code"; Rec."Operation Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = OperationCodeEditable;
                    ToolTip = 'Specifies the operation code for the posted document.';

                    trigger OnValidate()
                    begin
                        SetRControlsEditable();
                    end;
                }
                field("Property Location"; Rec."Property Location")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PropertyLocationEditable;
                    ToolTip = 'Specifies the property location associated with the declaration entry.';
                }
                field("Property Tax Account No."; Rec."Property Tax Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PropertyTaxAccountNoEditable;
                    ToolTip = 'Specifies the property tax account number for the Property Location for the operation code R.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        OperationCodeEditable := not (Rec."Operation Code" in ['C', 'D', 'I']);
        SetRControlsEditable();
    end;

    trigger OnInit()
    begin
        OperationCodeEditable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        OperationCodeEditable := not (Rec."Operation Code" in ['C', 'D', 'I']);
        SetRControlsEditable();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then begin
            Rec.SetRange("Operation Code", 'R');
            Rec.SetRange("Property Location", Rec."Property Location"::" ");
            Rec.SetRange(Type, Rec.Type::Sale);
            if not Rec.IsEmpty() then begin
                Rec.Reset();
                Error(Text001);
            end;
        end;
    end;

    var
        Text001: Label 'There are lines with empty property location for the operation code R.';
        OperationCodeEditable: Boolean;
        PropertyLocationEditable: Boolean;
        PropertyTaxAccountNoEditable: Boolean;

    local procedure SetRControlsEditable()
    begin
        PropertyLocationEditable := Rec."Operation Code" = 'R';
        PropertyTaxAccountNoEditable := Rec."Operation Code" = 'R';
    end;
}

