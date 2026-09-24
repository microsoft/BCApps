namespace Tour.UnixTimestamp;

/// <summary>
/// Exists only so the probe can be driven from a WEB CLIENT session.
///
/// A SOAP session takes its time zone from ServicesDefaultTimeZone, not from the user's
/// personal Time Zone - measured. To show that an ordinary user reaches the same behaviour,
/// the probe has to run in a session that takes its zone from User Personalization, and the
/// web client is the only such session available here.
/// </summary>
page 50101 "Tour Unix Results"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Tour Unix Result";
    Editable = false;
    Caption = 'Tour Unix Results';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Probe; Rec.Probe) { ApplicationArea = All; }
                field("Case Name"; Rec."Case Name") { ApplicationArea = All; }
                field("Tz Setting"; Rec."Tz Setting") { ApplicationArea = All; }
                field("Offset Ms"; Rec."Offset Ms") { ApplicationArea = All; }
                field("Old Result"; Rec."Old Result") { ApplicationArea = All; }
                field("New Result"; Rec."New Result") { ApplicationArea = All; }
                field("Irs Epoch Ts"; Rec."Irs Epoch Ts") { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunTourProbe)
            {
                ApplicationArea = All;
                Caption = 'Run Tour Probe';
                Image = Start;
                ToolTip = 'Runs the Unix timestamp probe in this web client session.';

                trigger OnAction()
                var
                    TourUnixProbe: Codeunit "Tour Unix Probe";
                begin
                    TourUnixProbe.RunAll();
                    Commit();
                    CurrPage.Update(false);
                    Message('Tour probe finished.');
                end;
            }
        }
    }
}
