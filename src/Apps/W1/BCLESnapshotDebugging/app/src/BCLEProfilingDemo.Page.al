namespace Microsoft.Samples.BCLESnapshotDebugging;

page 70950 "BCLE Profiling Demo"
{
    PageType = Card;
    SourceTable = "BCLE Profiling Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'BCLE Sampling Profiler Demo';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Control)
            {
                Caption = 'Workload control';

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Interval; Rec."Interval (ms)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the delay between fresh scheduled background sessions. Use 10000 for the demo.';
                }
                field(RowsToSeed; Rec."Rows to Seed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many large BLOB rows are stored and scanned. Use 10000 for the demo.';
                }
                field(MaximumRuntime; Rec."Maximum Runtime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how long fresh background workload passes continue to be scheduled.';
                }
                field(RunUntil; Rec."Run Until")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(TaskId; Rec."Task ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(ActiveSessionId; Rec."Active Session ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the long-lived anchor NST session ID to pass to the Sampling Profiling MCP.';
                }
                field(WorkloadSessionId; Rec."Workload Session ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the fresh background session currently executing a workload pass.';
                }
            }
            group(Status)
            {
                Caption = 'Latest run';

                field(Phase; Rec.Phase)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Progress; Rec."Progress %")
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Editable = false;
                    ExtendedDatatype = Ratio;
                    MinValue = 0;
                    MaxValue = 100;
                    ToolTip = 'Shows the current workload phase as a progress bar. Use Refresh progress to update it without creating extra background sessions.';
                }
                field(ProcessedRows; Rec."Processed Rows")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(TotalRows; Rec."Total Rows")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(LastStartedAt; Rec."Last Started At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(LastCompletedAt; Rec."Last Completed At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(LastDuration; Rec."Last Duration")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(RunCount; Rec."Run Count")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(LastResult; Rec."Last Result")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(LastError; Rec."Last Error")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Seed)
            {
                ApplicationArea = All;
                Caption = '1. Seed heavy SQL data';
                Image = Insert;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Controller: Codeunit "BCLE Profiling Controller";
                begin
                    Controller.SeedWorkload();
                    CurrPage.Update(false);
                end;
            }
            action(Start)
            {
                ApplicationArea = All;
                Caption = '2. Start scheduled workload';
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    Controller: Codeunit "BCLE Profiling Controller";
                begin
                    Controller.Start();
                    CurrPage.Update(false);
                end;
            }
            action(Stop)
            {
                ApplicationArea = All;
                Caption = 'Stop scheduled workload';
                Image = Stop;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Controller: Codeunit "BCLE Profiling Controller";
                begin
                    Controller.Stop();
                    CurrPage.Update(false);
                end;
            }
            action(RunOnce)
            {
                ApplicationArea = All;
                Caption = 'Run once in web session';
                Image = ExecuteBatch;

                trigger OnAction()
                var
                    Controller: Codeunit "BCLE Profiling Controller";
                begin
                    Controller.RunOnce();
                    CurrPage.Update(false);
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh progress';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.Get(Rec."Primary Key");
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Controller: Codeunit "BCLE Profiling Controller";
    begin
        Controller.EnsureSetup(Rec);
    end;
}
