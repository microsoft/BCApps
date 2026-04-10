page 130150 "Generate Test Data"
{
    InsertAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Generate Test Data Line";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(RecordsToAdd; RecordsToAdd)
                {
                    ApplicationArea = All;
                    Caption = 'Records to Add';
                    MinValue = 1;
                }
            }
            repeater(Group)
            {
                Editable = false;
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = All;
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = All;
                }
                field("Total Records"; "Total Records")
                {
                    ApplicationArea = All;
                }
                field("Records To Add"; "Records To Add")
                {
                    ApplicationArea = All;
                }
                field(Progress; Progress)
                {
                    ApplicationArea = All;
                }
                field(Status; Status)
                {
                    ApplicationArea = All;
                }
                field("Task ID"; "Task ID")
                {
                    ApplicationArea = All;
                }
                field("Session ID"; "Session ID")
                {
                    ApplicationArea = All;
                }
                field("Last Error Message"; "Last Error Message")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ReloadTables)
            {
                ApplicationArea = All;
                Caption = 'Reload Tables';
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Updates the list of tables.';

                trigger OnAction()
                begin
                    GenerateTestDataMgt.GetLines();
                    CurrPage.Update(false);
                end;
            }
            action(Generate)
            {
                ApplicationArea = All;
                Caption = 'Generate Data';
                Enabled = TableIsEnabled;
                Image = CreateDocuments;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Starts background jobs generating data.';

                trigger OnAction()
                var
                    GenerateTestDataLine: Record "Generate Test Data Line";
                begin
                    CurrPage.SetSelectionFilter(GenerateTestDataLine);
                    GenerateTestDataMgt.ScheduleJobs(GenerateTestDataLine, RecordsToAdd);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        TableIsEnabled := Enabled;
    end;

    trigger OnAfterGetRecord()
    begin
        if "Added Records" <> "Records To Add" then
            UpdateStatus();
    end;

    trigger OnOpenPage()
    begin
        RecordsToAdd := 100;
        if IsEmpty() then
            GenerateTestDataMgt.GetLines();
    end;

    var
        GenerateTestDataMgt: Codeunit "Generate Test Data Mgt.";
        RecordsToAdd: Integer;
        TableIsEnabled: Boolean;
}

