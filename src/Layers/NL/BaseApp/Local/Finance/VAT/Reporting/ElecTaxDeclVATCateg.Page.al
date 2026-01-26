// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 11414 "Elec. Tax Decl. VAT Categ."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Electronic Tax Declaration VAT Categories';
    PageType = List;
    SourceTable = "Elec. Tax Decl. VAT Category";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a category code.';
                }
                field(Category; Rec.Category)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the five main categories of the VAT statement.';

                    trigger OnValidate()
                    begin
                        CategoryOnAfterValidate();
                    end;
                }
                field("By Us (Domestic)"; Rec."By Us (Domestic)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "By Us (Domestic)Editable";
                    ToolTip = 'Specifies the subcategory for the main category By Us (Domestic) of the VAT Statement.';
                }
                field("To Us (Domestic)"; Rec."To Us (Domestic)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "To Us (Domestic)Editable";
                    ToolTip = 'Specifies the subcategory for the main category To Us (Domestic) of the VAT Statement.';
                }
                field("By Us (Foreign)"; Rec."By Us (Foreign)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "By Us (Foreign)Editable";
                    ToolTip = 'Specifies the subcategory for the main category By Us (Foreign) of the VAT Statement.';
                }
                field("To Us (Foreign)"; Rec."To Us (Foreign)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "To Us (Foreign)Editable";
                    ToolTip = 'Specifies the subcategory for the main category To Us (Foreign) of the VAT Statement.';
                }
                field(Calculation; Rec.Calculation)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = CalculationEditable;
                    ToolTip = 'Specifies the subcategory for the main category Calculation of the VAT Statement.';
                }
                field(Optional; Rec.Optional)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the XML element is not required in the electronic VAT declaration.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnInit()
    begin
        CalculationEditable := true;
        "To Us (Foreign)Editable" := true;
        "By Us (Foreign)Editable" := true;
        "To Us (Domestic)Editable" := true;
        "By Us (Domestic)Editable" := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateControls();
    end;

    var
        "By Us (Domestic)Editable": Boolean;
        "To Us (Domestic)Editable": Boolean;
        "By Us (Foreign)Editable": Boolean;
        "To Us (Foreign)Editable": Boolean;
        CalculationEditable: Boolean;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        "By Us (Domestic)Editable" := (Rec.Category = Rec.Category::"1. By Us (Domestic)");
        "To Us (Domestic)Editable" := (Rec.Category = Rec.Category::"2. To Us (Domestic)");
        "By Us (Foreign)Editable" := (Rec.Category = Rec.Category::"3. By Us (Foreign)");
        "To Us (Foreign)Editable" := (Rec.Category = Rec.Category::"4. To Us (Foreign)");
        CalculationEditable := (Rec.Category = Rec.Category::"5. Calculation");
    end;

    local procedure CategoryOnAfterValidate()
    begin
        UpdateControls();
    end;
}

