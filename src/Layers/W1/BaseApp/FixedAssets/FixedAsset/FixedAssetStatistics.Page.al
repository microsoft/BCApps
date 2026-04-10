// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.FixedAssets.Depreciation;

page 5602 "Fixed Asset Statistics"
{
    Caption = 'Fixed Asset Statistics';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "FA Depreciation Book";
    AboutTitle = 'About Fixed Asset Statistics';
    AboutText = 'Here you overview the total acquisition cost, depreciation, and book value for the asset.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Acquisition Date"; Rec."Acquisition Date")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Acquisition Date';
                }
                field("G/L Acquisition Date"; Rec."G/L Acquisition Date")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'G/L Acquisition Date';
                }
                field(Disposed; Disposed)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Disposed Of';
                    ToolTip = 'Specifies whether the fixed asset has been disposed of.';
                }
                field("Disposal Date"; Rec."Disposal Date")
                {
                    ApplicationArea = All;
                    Visible = DisposalDateVisible;
                }
                field("Proceeds on Disposal"; Rec."Proceeds on Disposal")
                {
                    ApplicationArea = All;
                    Visible = ProceedsOnDisposalVisible;
                }
                field("Gain/Loss"; Rec."Gain/Loss")
                {
                    ApplicationArea = All;
                    Visible = GainLossVisible;
                }
                field(DisposalValue; Rec."Book Value on Disposal")
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Book Value after Disposal';
                    Editable = false;
                    Visible = DisposalValueVisible;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowBookValueAfterDisposal();
                    end;
                }
                fixed(Control1903895301)
                {
                    ShowCaption = false;
                    group("Last FA Posting Date")
                    {
                        Caption = 'Last FA Posting Date';
                        field("Last Acquisition Cost Date"; Rec."Last Acquisition Cost Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Acquisition Cost';
                        }
                        field("Last Depreciation Date"; Rec."Last Depreciation Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Depreciation';
                        }
                        field("Last Write-Down Date"; Rec."Last Write-Down Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Write-Down';
                        }
                        field("Last Appreciation Date"; Rec."Last Appreciation Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Appreciation';
                        }
                        field("Last Custom 1 Date"; Rec."Last Custom 1 Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 1';
                        }
                        field("Last Salvage Value Date"; Rec."Last Salvage Value Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Salvage Value';
                        }
                        field("Last Custom 2 Date"; Rec."Last Custom 2 Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 2';
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
                        field("Acquisition Cost"; Rec."Acquisition Cost")
                        {
                            ApplicationArea = FixedAssets;
                        }
                        field(Depreciation; Rec.Depreciation)
                        {
                            ApplicationArea = FixedAssets;
                        }
                        field("Write-Down"; Rec."Write-Down")
                        {
                            ApplicationArea = FixedAssets;
                        }
                        field(Appreciation; Rec.Appreciation)
                        {
                            ApplicationArea = FixedAssets;
                        }
                        field("Custom 1"; Rec."Custom 1")
                        {
                            ApplicationArea = FixedAssets;
                        }
                        field("Salvage Value"; Rec."Salvage Value")
                        {
                            ApplicationArea = FixedAssets;
                        }
                        field("Custom 2"; Rec."Custom 2")
                        {
                            ApplicationArea = FixedAssets;
                        }
                    }
                }
                fixed(Control2)
                {
                    ShowCaption = false;
                    group(Control3)
                    {
                        ShowCaption = false;
                        field("Book Value"; Rec."Book Value")
                        {
                            ApplicationArea = FixedAssets;
                        }
                        field("Depreciable Basis"; Rec."Depreciable Basis")
                        {
                            ApplicationArea = FixedAssets;
                        }
                        field(Maintenance; Rec.Maintenance)
                        {
                            ApplicationArea = FixedAssets;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Disposed := Rec."Disposal Date" > 0D;
        DisposalValueVisible := Disposed;
        ProceedsOnDisposalVisible := Disposed;
        GainLossVisible := Disposed;
        DisposalDateVisible := Disposed;
        Rec.CalcBookValue();
    end;

    trigger OnInit()
    begin
        DisposalDateVisible := true;
        GainLossVisible := true;
        ProceedsOnDisposalVisible := true;
        DisposalValueVisible := true;
    end;

    var
        Disposed: Boolean;
        DisposalValueVisible: Boolean;
        ProceedsOnDisposalVisible: Boolean;
        GainLossVisible: Boolean;
        DisposalDateVisible: Boolean;
}

