namespace System.Tooling;

using System;

codeunit 9804 "Log Recorded Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempRecordedEventBuffer: Record "Recorded Event Buffer" temporary;
        [WithEvents]
        EventReceiver: DotNet NavEventEventReceiver;
        RecordingErrorMsg: Label 'An internal error has occurred. The recording of events has been stopped.';
        CallOrder: Integer;

    procedure Start()
    begin
        CallOrder := 0;
        TempRecordedEventBuffer.DeleteAll();

        if IsNull(EventReceiver) then
            EventReceiver := EventReceiver.NavEventEventReceiver();

        EventReceiver.RegisterForEvents();
    end;

    procedure Stop(var TempRecordedEventBufferVar: Record "Recorded Event Buffer" temporary)
    begin
        // Returns the list of all events collected.
        EventReceiver.UnregisterEvents();

        TempRecordedEventBufferVar.Copy(TempRecordedEventBuffer, true);
    end;

    trigger EventReceiver::OnEventCheckEvent(sender: Variant; e: DotNet EventCheckEventArgs)
    var
        IsEventLogged: Boolean;
    begin
        // Do not record the usages related to the recorder itself.
        if (((e.ObjectType = TempRecordedEventBuffer."Object Type"::Codeunit) and (e.ObjectId = CODEUNIT::"Log Recorded Events")) or
            ((e.ObjectType = TempRecordedEventBuffer."Object Type"::Table) and (e.ObjectId = DATABASE::"Recorded Event Buffer")) or
            ((e.ObjectType = TempRecordedEventBuffer."Object Type"::Page) and (e.ObjectId = PAGE::"Event Recorder")))
        then
            exit;

        if not (SessionId = e.SessionId) then begin
            // We should not be recording events in other sessions, but in case it happens,
            // sending a telemetry event and not adding it.
            EventReceiver.OnWrongSessionRecorded(SessionId, e.SessionId);
            exit;
        end;

        TempRecordedEventBuffer."Object Type" := e.ObjectType;
        TempRecordedEventBuffer."Object ID" := e.ObjectId;
        TempRecordedEventBuffer."Event Name" := e.EventName;
        TempRecordedEventBuffer."Element Name" := e.ElementName;
        TempRecordedEventBuffer."Event Type" := e.EventType;
        TempRecordedEventBuffer."Calling Object Type" := e.CallingObjectType;
        TempRecordedEventBuffer."Calling Object ID" := e.CallingObjectId;
        TempRecordedEventBuffer."Calling Method" := e.CallingMethodName;

        IsEventLogged := TempRecordedEventBuffer.Get(
            TempRecordedEventBuffer."Object Type", TempRecordedEventBuffer."Object ID",
            TempRecordedEventBuffer."Event Name", TempRecordedEventBuffer."Element Name", TempRecordedEventBuffer."Event Type",
            TempRecordedEventBuffer."Calling Object Type", TempRecordedEventBuffer."Calling Object ID",
            TempRecordedEventBuffer."Calling Method", CallOrder);

        if not IsEventLogged then begin
            CallOrder := CallOrder + 1;
            TempRecordedEventBuffer.Init();
            TempRecordedEventBuffer."Session ID" := e.SessionId;
            TempRecordedEventBuffer."Call Order" := CallOrder;
            TempRecordedEventBuffer."Hit Count" := 0;
            TempRecordedEventBuffer.Insert();
        end;

        // Update the hit count of the event.
        TempRecordedEventBuffer."Hit Count" += 1;
        TempRecordedEventBuffer.Modify();
    end;

    trigger EventReceiver::OnRecordingErrorOccurred(sender: Variant; e: DotNet EventArgs)
    begin
        // Warn the user that the recording of events has been stopped.
        Message(RecordingErrorMsg);
    end;
}

