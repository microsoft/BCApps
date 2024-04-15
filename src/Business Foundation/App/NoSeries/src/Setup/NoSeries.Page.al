// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 456 "No. Series"
{
    AdditionalSearchTerms = 'numbering,number series';
    ApplicationArea = Basic, Suite;
    Caption = 'No. Series';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "No. Series";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    Caption = 'Code';
                    ToolTip = 'Specifies a number series code.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the number series.';
                }
                field(StartDate; StartDate)
                {
                    Caption = 'Starting Date';
                    Editable = false;
                    ToolTip = 'Specifies the date from which you want this number series to apply. You use this field if you want to start a new series at the beginning of a new period. You set up a number series line for each period. The program will automatically switch to the new series on the starting date.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
                    begin
                        NoSeriesSetupImpl.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(StartNo; StartNo)
                {
                    Caption = 'Starting No.';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the first number in the series.';

                    trigger OnDrillDown()
                    var
                        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
                    begin
                        NoSeriesSetupImpl.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(EndNo; EndNo)
                {
                    Caption = 'Ending No.';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the last number in the series.';

                    trigger OnDrillDown()
                    var
                        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
                    begin
                        NoSeriesSetupImpl.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(LastDateUsed; LastDateUsed)
                {
                    Caption = 'Last Date Used';
                    Editable = false;
                    ToolTip = 'Specifies the date when a number was most recently assigned from the number series.';

                    trigger OnDrillDown()
                    var
                        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
                    begin
                        NoSeriesSetupImpl.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(LastNoUsed; LastNoUsed)
                {
                    Caption = 'Last No. Used';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the last number that was used from the number series.';

                    trigger OnDrillDown()
                    var
                        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
                    begin
                        NoSeriesSetupImpl.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(WarningNo; WarningNo)
                {
                    Caption = 'Warning No.';
                    Editable = false;
                    ToolTip = 'Specifies when you want to receive a warning that the number series is running out. You enter a number from the series. The program will provide a warning when this number is reached. You can enter a maximum of 20 characters, both numbers and letters.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
                    begin
                        NoSeriesSetupImpl.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(IncrementByNo; IncrementByNo)
                {
                    Caption = 'Increment-by No.';
                    Editable = false;
                    ToolTip = 'Specifies the value for incrementing the numeric part of the series.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
                    begin
                        NoSeriesSetupImpl.DrillDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field("Default Nos."; Rec."Default Nos.")
                {
                    Caption = 'Default Nos.';
                    ToolTip = 'Specifies whether this number series will be used to assign numbers automatically.';
                }
                field("Manual Nos."; Rec."Manual Nos.")
                {
                    Caption = 'Manual Nos.';
                    ToolTip = 'Specifies that you can enter numbers manually instead of using this number series.';
                }
                field("Date Order"; Rec."Date Order")
                {
                    Caption = 'Date Order';
                    ToolTip = 'Specifies to check that numbers are assigned chronologically.';
                }
                field(AllowGapsCtrl; AllowGaps)
                {
                    Caption = 'Allow Gaps in Nos.';
                    ToolTip = 'Specifies that a number assigned from the number series can later be deleted. This is practical for records, such as item cards and warehouse documents that, unlike financial transactions, can be deleted and cause gaps in the number sequence. This setting also means that new numbers will be generated and assigned in a faster, non-blocking way. NOTE: If an error occurs on a new record that will be assigned a number from such a number series when it is completed, the number in question will be lost, causing a gap in the sequence.';
#if CLEAN24
                    Editable = false;
#else
#pragma warning disable AL0432
                    trigger OnValidate()
                    var
                        NoSeriesManagement: Codeunit NoSeriesManagement;
                    begin
                        Rec.TestField(Code);
                        NoSeriesManagement.SetAllowGaps(Rec, AllowGaps);
                        UpdateLineActionOnPage();
                    end;
#pragma warning restore AL0432
#endif
                }
                field(Implementation; Implementation)
                {
                    Caption = 'Implementation';
                    ToolTip = 'Specifies the implementation to use for getting numbers.';

                    trigger OnValidate()
                    var
                        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
                    begin
                        Rec.TestField(Code);
                        NoSeriesSetupImpl.SetImplementation(Rec, Implementation);
                        UpdateLineActionOnPage();
                    end;
                }
            }
        }
        area(FactBoxes)
        {
            part(NoSeriesLinesPart; "No. Series Lines Part")
            {
                Caption = 'Open Lines';
                SubPageLink = "Series Code" = field(Code), Open = const(true);
            }
            part(NoSeriesRelationsPart; "No. Series Relationships Part")
            {
                Caption = 'Relationships';
                SubPageLink = Code = field(Code);
            }
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
        area(Navigation)
        {
            group("&Series")
            {
                Caption = 'Series';
                Image = SerialNo;

                action(Lines)
                {
                    Caption = 'Lines';
                    Image = AllLines;
                    ToolTip = 'View or edit additional information about the number series lines.';
                    RunObject = Page "No. Series Lines";
                    RunPageLink = "Series Code" = field(Code);
                    Scope = Repeater;
                }
                action(Relationships)
                {
                    Caption = 'Relationships';
                    Image = Relationship;
                    RunObject = page "No. Series Relationships";
                    RunPageLink = Code = field(Code);
                    ToolTip = 'View or edit relationships between number series.';
                    Scope = Repeater;
                }
            }
        }
        area(Processing)
        {
            action(TestNoSeriesSingle)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test No. Series';
                Image = TestFile;
                ToolTip = 'Test whether the number series can generate new numbers.';

                trigger OnAction()
                var
                    NoSeries: Codeunit "No. Series";
                    NextNo: Code[20];
                begin
                    NextNo := NoSeries.PeekNextNo(Rec.Code, WorkDate());
                    if NextNo <> '' then
                        Message(CheckNoSucceededTxt, NextNo, WorkDate())
                    else
                        Message(CheckNoFailedTxt, WorkDate());
                end;
            }
            group(View)
            {
                Caption = 'View';
                ShowAs = SplitButton;

                action(ShowAll)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All';
                    Image = List;
                    ToolTip = 'Show all number series.';

                    trigger OnAction()
                    begin
                        Rec.ClearMarks();
                        Rec.MarkedOnly(false);
                        CurrPage.Update(false);
                    end;
                }

                action(ShowExpiring)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Expiring';
                    Image = ShowList;
                    ToolTip = 'Show number series that require your attention, such as, number series that have no lines or an have open lines which have reached the warning threshold.';

                    trigger OnAction()
                    var
                        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
                    begin
                        NoSeriesSetupImpl.ShowNoSeriesWithWarningsOnly(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
#if not CLEAN24
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
                ObsoleteReason = 'This promoted group is no longer used, please create a group manually.';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
                ObsoleteReason = 'This promoted group is no longer used, please create a group manually.';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';
            }
#endif
            actionref(Lines_Promoted; Lines)
            {
            }
            actionref(Relationships_Promoted; Relationships)
            {
            }
            group(View_Promoted)
            {
                ShowAs = SplitButton;
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
                actionref(ShowExpiring_Promoted; ShowExpiring)
                {
                }
            }
            actionref(TestNoSeriesSingle_Promoted; TestNoSeriesSingle)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateLineActionOnPage();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateLineActionOnPage();
    end;

    var
        StartDate: Date;
        StartNo: Code[20];
        EndNo: Code[20];
        LastNoUsed: Code[20];
        WarningNo: Code[20];
        IncrementByNo: Integer;
        LastDateUsed: Date;
        AllowGaps: Boolean;
        Implementation: Enum "No. Series Implementation";
        CheckNoSucceededTxt: Label 'The test was successful. Number %1 for date %2 was returned.', Comment = '%1 = A No. Series number, %2 = a date';
        CheckNoFailedTxt: Label 'The test failed. No number was returned for date %1.', Comment = '%1 = a date';

    protected procedure UpdateLineActionOnPage()
    var
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
        NoSeriesSingle: Interface "No. Series - Single";
    begin
        NoSeriesSetupImpl.UpdateLine(Rec, StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, Implementation);
        NoSeriesSingle := Implementation;
        AllowGaps := NoSeriesSingle.MayProduceGaps();
    end;
}
