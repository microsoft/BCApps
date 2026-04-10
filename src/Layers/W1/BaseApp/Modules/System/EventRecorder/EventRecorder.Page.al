namespace System.Tooling;

using System.Reflection;

page 9845 "Event Recorder"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Event Recorder';
    Editable = false;
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "Recorded Event Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting("Call Order")
                      order(ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'All Recorded Events';
                Editable = false;
                field(CallOrder; Rec."Call Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Call Order';
                    ToolTip = 'Specifies the order in which the events are called.';
                }
                field(EventType; Rec."Event Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Event Type';
                    StyleExpr = EventTypeStyleExpr;
                    ToolTip = 'Specifies the type of the event that is called.';
                }
                field(HitCount; Rec."Hit Count")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Hit Count';
                    ToolTip = 'Specifies the number of time this event is called consecutively.';
                }
                field(ObjectType; Rec."Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Type';
                    ToolTip = 'Specifies the type of object that contains the called event.';
                }
                field(ObjectID; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object ID';
                    HideValue = (Rec."Object ID" = 0);
                    LookupPageID = "All Objects with Caption";
                    ToolTip = 'Specifies the ID of the object that contains the called event.';
                    Visible = false;
                }
                field(ObjectName; Rec."Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the object that contains the called event.';
                }
                field(EventName; Rec."Event Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Event Name';
                    ToolTip = 'Specifies the name of the called event.';
                }
                field(ElementName; Rec."Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Element Name';
                    ToolTip = 'Specifies the name of the element in which the event is called.';
                }
                field(CallingObjectType; Rec."Calling Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calling Object Type';
                    HideValue = (Rec."Calling Object Type" = 0);
                    ToolTip = 'Specifies the type of the object that calls the event.';
                }
                field(CallingObjectID; Rec."Calling Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calling Object ID';
                    HideValue = (Rec."Calling Object ID" = 0);
                    ToolTip = 'Specifies the ID of the object that calls the event.';
                    Visible = false;
                }
                field(CallingObjectName; Rec."Calling Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calling Object Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the object that calls the event.';
                }
                field(CallingMethod; Rec."Calling Method")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calling Method';
                    ToolTip = 'Specifies the name of method that calls the event.';
                }
                field(GetALSnippet; GetAlSnippetLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Get AL Snippet';
                    ToolTip = 'Specifies the AL snippet to subscribe to this event.';

                    trigger OnDrillDown()
                    begin
                        Message(DisplaySnippet());
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Recording)
            {
                Caption = 'Record Events';
                action(Start)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start';
                    Enabled = not EventLoggingRunning;
                    Image = Start;
                    ToolTip = 'Start recording UI activities to generate the list of events that are called. The new recording will erase any events that have previously been recorded.';

                    trigger OnAction()
                    var
                        FiltersCopy: Record "Recorded Event Buffer";
                    begin
                        if not Confirm(StartRecordingQst) then
                            exit;

                        // Delete all events from the current table, this implies reseting the filters too.
                        FiltersCopy.CopyFilters(Rec);
                        Rec.Reset();
                        Rec.DeleteAll();
                        Rec.CopyFilters(FiltersCopy);

                        LogRecordedEvents.Start();
                        EventLoggingRunning := true;
                    end;
                }
                action(Stop)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Stop';
                    Enabled = EventLoggingRunning;
                    Image = Stop;
                    ToolTip = 'Stop recording and generate the list of events that are recorded.';

                    trigger OnAction()
                    begin
                        EventLoggingRunning := false;
                        LogRecordedEvents.Stop(TempRecordedEventBuffer);

                        if TempRecordedEventBuffer.Count = 0 then begin
                            Message(NoEventsRecordedMsg);
                            exit;
                        end;

                        if not Confirm(AddRecordingQst, false, TempRecordedEventBuffer.Count) then
                            exit;

                        // Add elements to the source table of the page to display them in the repeater.
                        if TempRecordedEventBuffer.FindSet() then
                            repeat
                                Rec.Init();
                                Rec := TempRecordedEventBuffer;
                                Rec.Insert();
                            until TempRecordedEventBuffer.Next() = 0;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Record Events', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Start_Promoted; Start)
                {
                }
                actionref(Stop_Promoted; Stop)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Event Type" = Rec."Event Type"::"Custom Event" then
            EventTypeStyleExpr := 'Attention'
        else
            EventTypeStyleExpr := 'AttentionAccent';
    end;

    var
        TempRecordedEventBuffer: Record "Recorded Event Buffer" temporary;
        LogRecordedEvents: Codeunit "Log Recorded Events";
        AddRecordingQst: Label '%1 events have been recorded. Do you want to display them?', Comment = '%1 represents the number of events recorded.';
        StartRecordingQst: Label 'Do you want to start the recording now?';
        NoEventsRecordedMsg: Label 'No events have been recorded.';
        GetAlSnippetLbl: Label 'Get AL Snippet.';
        EventLoggingRunning: Boolean;
        EventTypeStyleExpr: Text;

    local procedure DisplaySnippet() Snippet: Text
    var
        ObjectTypeForId: Text[30];
    begin
        // In AL, the ID of a table is accessed as Database::MyTable.
        if Rec."Object Type" = Rec."Object Type"::Table then
            ObjectTypeForId := 'Database'
        else
            ObjectTypeForId := GetObjectType(Rec."Object Type");

        Snippet := '[EventSubscriber(ObjectType::' + GetObjectType(Rec."Object Type") + ', ' +
          ObjectTypeForId + '::' + '"' + Rec."Object Name" + '"' + ', ' +
          '''' + Rec."Event Name" + '''' + ', ' +
          '''' + Rec."Element Name" + '''' + ', ' +
          'true, true)] ' + '\' +
          'local procedure MyProcedure()\' +
          'begin\' +
          'end;\';
    end;

    local procedure GetObjectType(objectType: Option "Object Type"): Text
    begin
        // In AL, the object type is always in English.
        case objectType of
            Rec."Object Type"::Codeunit:
                exit('Codeunit');
            Rec."Object Type"::Page:
                exit('Page');
            Rec."Object Type"::Query:
                exit('Query');
            Rec."Object Type"::Report:
                exit('Report');
            Rec."Object Type"::Table:
                exit('Table');
            Rec."Object Type"::XMLport:
                exit('XmlPort');
        end;
    end;
}
