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
                    ToolTip = 'Specifies the FA posting date of the first posted acquisition cost.';
                }
                field("G/L Acquisition Date"; Rec."G/L Acquisition Date")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'G/L Acquisition Date';
                    ToolTip = 'Specifies the G/L posting date of the first posted acquisition cost.';
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
                    ToolTip = 'Specifies the FA posting date of the first posted disposal amount.';
                    Visible = DisposalDateVisible;
                }
                field("Proceeds on Disposal"; Rec."Proceeds on Disposal")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total proceeds on disposal for the fixed asset.';
                    Visible = ProceedsOnDisposalVisible;
                }
                field("Gain/Loss"; Rec."Gain/Loss")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total gain (credit) or loss (debit) for the fixed asset.';
                    Visible = GainLossVisible;
                }
                field(DisposalValue; Rec."Book Value on Disposal")
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Book Value after Disposal';
                    Editable = false;
                    ToolTip = 'Specifies the total LCY amount of entries posted with the Book Value on Disposal posting type. Entries of this kind are created when you post disposal of a fixed asset to a depreciation book where the Gross method has been selected in the Disposal Calculation Method field.';
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
                            ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
                        }
                        field("Last Depreciation Date"; Rec."Last Depreciation Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Depreciation';
                            ToolTip = 'Specifies the FA posting date of the last posted depreciation.';
                        }
                        field("Last Write-Down Date"; Rec."Last Write-Down Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Write-Down';
                            ToolTip = 'Specifies the FA posting date of the last posted write-down.';
                        }
                        field("Last Appreciation Date"; Rec."Last Appreciation Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Appreciation';
                            ToolTip = 'Specifies the sum that applies to appreciations.';
                        }
                        field("Last Custom 1 Date"; Rec."Last Custom 1 Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 1';
                            ToolTip = 'Specifies the FA posting date of the last posted custom 1 entry.';
                        }
                        field("Last Salvage Value Date"; Rec."Last Salvage Value Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Salvage Value';
                            ToolTip = 'Specifies if related salvage value entries are included in the batch job .';
                        }
                        field("Last Custom 2 Date"; Rec."Last Custom 2 Date")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 2';
                            ToolTip = 'Specifies the FA posting date of the last posted custom 2 entry.';
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
                        field("Acquisition Cost"; Rec."Acquisition Cost")
                        {
                            ApplicationArea = FixedAssets;
                            ToolTip = 'Specifies the total acquisition cost for the fixed asset.';
                        }
                        field(Depreciation; Rec.Depreciation)
                        {
                            ApplicationArea = FixedAssets;
                            ToolTip = 'Specifies the total depreciation for the fixed asset.';
                        }
                        field("Write-Down"; Rec."Write-Down")
                        {
                            ApplicationArea = FixedAssets;
                            ToolTip = 'Specifies the total LCY amount of write-down entries for the fixed asset.';
                        }
                        field(Appreciation; Rec.Appreciation)
                        {
                            ApplicationArea = FixedAssets;
                            ToolTip = 'Specifies the total appreciation for the fixed asset.';
                        }
                        field("Custom 1"; Rec."Custom 1")
                        {
                            ApplicationArea = FixedAssets;
                            ToolTip = 'Specifies the total LCY amount for custom 1 entries for the fixed asset.';
                        }
                        field("Salvage Value"; Rec."Salvage Value")
                        {
                            ApplicationArea = FixedAssets;
                            ToolTip = 'Specifies the estimated residual value of a fixed asset when it can no longer be used.';
                        }
                        field("Custom 2"; Rec."Custom 2")
                        {
                            ApplicationArea = FixedAssets;
                            ToolTip = 'Specifies the total LCY amount for custom 2 entries for the fixed asset.';
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
                            ToolTip = 'Specifies the book value for the fixed asset.';
                        }
                        field("Depreciable Basis"; Rec."Depreciable Basis")
                        {
                            ApplicationArea = FixedAssets;
                            ToolTip = 'Specifies the depreciable basis amount for the fixed asset.';
                        }
                        field(Maintenance; Rec.Maintenance)
                        {
                            ApplicationArea = FixedAssets;
                            ToolTip = 'Specifies the total maintenance cost for the fixed asset.';
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

