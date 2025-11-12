// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Pricing.PriceList;

page 7027 "Price Calculation Setup Lines"
{
    Caption = 'Setup Lines';
    PageType = ListPart;
    SourceTable = "Price Calculation Setup";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = true;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Asset Type"; Rec."Asset Type")
                {
                    ToolTip = 'Specifies the type of the product for price calculation.';
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                }
                field(Implementation; Rec.Implementation)
                {
                    Caption = 'Implementation Used';
                    ToolTip = 'Specifies the name of the implementation codeunit or extension that will do the price calculation.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    AssistEdit = true;

                    trigger OnAssistEdit()
                    begin
                        PriceUXManagement.PickImplementation(Rec);
                    end;
                }
                field(EnabledExceptions; EnabledExceptions)
                {
                    Caption = 'Enabled Exceptions';
                    ToolTip = 'Specifies the number of enabled exceptions.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        PriceUXManagement.ShowExceptions(Rec);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Exceptions)
            {
                Caption = 'Exceptions';
                ApplicationArea = Basic, Suite;
                Image = SetupLines;
                ToolTip = 'Opens the page for setting combinations of products and sources that should be handled by alternative implementations.';

                trigger OnAction()
                begin
                    PriceUXManagement.ShowExceptions(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        EnabledExceptions := Rec.CountEnabledExeptions();
    end;

    var
        PriceUXManagement: Codeunit "Price UX Management";
        EnabledExceptions: Integer;

    procedure SetData(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        Rec.Copy(TempPriceCalculationSetup, true);
    end;

}