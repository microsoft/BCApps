namespace System.IO;

using Microsoft.Inventory.Setup;

page 8645 "Costing Method Configuration"
{
    Caption = 'Costing Method Configuration';
    SourceTable = "Inventory Setup";
    PageType = Card;

    layout
    {
        area(content)
        {
            group(Control57)
            {
                ShowCaption = false;

                group("Specify the costing method for your inventory valuation.")
                {
                    Caption = 'Specify the costing method for your inventory valuation.';
                    group(Control122)
                    {
                        InstructionalText = 'The costing method works together with the posting date and sequence to determine how to record the cost flow.';
                        ShowCaption = false;
                        field("Cost Method"; CostMethodeLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Link to Costing Method help.';

                            trigger OnDrillDown()
                            begin
                                HyperLink(CostMethodUrlTxt);
                            end;
                        }
                        field("Costing Method"; Rec."Default Costing Method")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Costing Method';
                            ShowMandatory = true;
                            ToolTip = 'Change costing method.';

                            trigger OnValidate()
                            var
                                ExistingInventorySetup: Record "Inventory Setup";
                            begin
                                if not ExistingInventorySetup.Get() then begin
                                    Rec."Automatic Cost Adjustment" := Rec."Automatic Cost Adjustment"::Always;
                                    Rec."Automatic Cost Posting" := true;
                                end;

                                if Rec."Default Costing Method" = Rec."Default Costing Method"::Average then begin
                                    Rec."Average Cost Period" := Rec."Average Cost Period"::Day;
                                    Rec."Average Cost Calc. Type" := Rec."Average Cost Calc. Type"::Item;
                                end;

                                CurrPage.Update(true);
                            end;
                        }
                    }
                }
            }

        }
    }

    var
        CostMethodUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=858295', Locked = true;
        CostMethodeLbl: Label 'Learn more';
}