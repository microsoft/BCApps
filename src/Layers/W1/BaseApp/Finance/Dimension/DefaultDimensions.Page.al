// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Configuration page for setting up default dimensions for master record entities.
/// Enables users to define automatic dimension assignments for customers, vendors, items, and other master data.
/// </summary>
/// <remarks>
/// Central interface for default dimension management: defines dimension values automatically applied to transactions.
/// Supports various posting rules including mandatory, same code, and blocked dimension value enforcements.
/// Used across all areas where master records require consistent dimension assignment for reporting and analysis.
/// </remarks>
page 540 "Default Dimensions"
{
    Caption = 'Default Dimensions';
    DataCaptionExpression = Rec.GetCaption();
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Default Dimension";
    AboutTitle = 'About default dimensions';
    AboutText = 'Default dimensions help make reports more consistent. Their values are always added to documents for specific accounts, customers, vendors, or items.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    AboutTitle = 'Enter default values';
                    AboutText = 'Default values could be departments or teams, geographic regions or area codes, customers or vendors, salespeople or purchasers, and so on. Use them to filter, total, and do other types of analyses on reports.';
                }
                field("Dimension Value Name"; Rec."Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                }
                field("Value Posting"; Rec."Value Posting")
                {
                    ApplicationArea = Dimensions;
                    AboutTitle = 'Control value selection';
                    AboutText = 'You can require a dimension, but let people choose a value when they create documents. For example, this allows for exceptions to default values. For mandatory dimensions, you can provide specific values or ranges of values.';
                }
                field(AllowedValuesFilter; Rec."Allowed Values Filter")
                {
                    ApplicationArea = Dimensions;
                    AboutTitle = 'Allow specific values';
                    AboutText = 'You can make a dimension mandatory and provide the values that people can choose. For example, you might provide certain geographic areas or a range of accounts.';
                    Editable = IsAllowedValuesFilterEditable;

                    trigger OnAssistEdit()
                    var
                        DimMgt: Codeunit DimensionManagement;
                    begin
                        if Rec."Value Posting" = Enum::"Default Dimension Value Posting Type"::"Code Mandatory" then begin
                            CurrPage.SaveRecord();
                            DimMgt.OpenAllowedDimValuesPerAccount(Rec);
                            CurrPage.Update();
                        end;
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsAllowedValuesFilterEditable := Rec."Value Posting" = Enum::"Default Dimension Value Posting Type"::"Code Mandatory";
    end;

    var
        IsAllowedValuesFilterEditable: Boolean;
}

