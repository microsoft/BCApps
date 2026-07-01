codeunit 101221 "Create No Series SaaS"
{

    trigger OnRun()
    var
        JJnlNoSeries: Code[20];
    begin
        if not NoSeries.Get(XJOBTxt) then
            CreateNoSeries.InitBaseSeries(DummyJobsSetup."Job Nos.", XJOBTxt, XJOBTxt, XJ10Txt, XJ99990Txt, '', '', 10, Enum::"No. Series Implementation"::Sequence);

        if not NoSeries.Get(XJOBWIPTxt) then
            CreateNoSeries.InitBaseSeries(DummyJobsSetup."Job WIP Nos.", XJOBWIPTxt, XJobWIPDescTxt, XDefaultJobWIPNoTxt, XDefaultJobWIPEndNoTxt, '', '', 1, Enum::"No. Series Implementation"::Sequence);

        JJnlNoSeries := '';
        if not NoSeries.Get(XJJNL) then
            CreateNoSeries.InitBaseSeries(JJnlNoSeries, XJJNL, XJJNLDescTxt, XJJNLNoTxt, XJJNLEndNoTxt, '', '', 1, Enum::"No. Series Implementation"::Sequence);

        if not NoSeries.Get(XRES) then
            CreateNoSeries.InitBaseSeries(DummyResourcesSetup."Resource Nos.", XRES, XRESDescTxt, XRESNoTxt, XResEndNoTxt, '', '', 10, Enum::"No. Series Implementation"::Sequence);

        if not NoSeries.Get(XTS) then
            CreateNoSeries.InitBaseSeries(DummyResourcesSetup."Time Sheet Nos.", XTS, XTSDescTxt, XTSNoTxt, XTSEndNoTxt, '', '', 1, Enum::"No. Series Implementation"::Sequence);
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        DummyResourcesSetup: Record "Resources Setup";
        NoSeries: Record "No. Series";
        CreateNoSeries: Codeunit "Create No. Series";
        XJOBTxt: Label 'JOB';
        XJ10Txt: Label 'J10';
        XJ99990Txt: Label 'J99990';
        XJOBWIPTxt: Label 'JOB-WIP', Comment = 'Cashflow is a name of Cash Flow Forecast No. Series.';
        XDefaultJobWIPNoTxt: Label 'WIP0000001', Comment = 'CF stands for Cash Flow.';
        XDefaultJobWIPEndNoTxt: Label 'WIP9999999';
        XJobWIPDescTxt: Label 'Job-WIP';
        XRES: Label 'RES';
        XRESDescTxt: Label 'Resource';
        XRESNoTxt: Label 'R0010';
        XResEndNoTxt: Label 'R9990';
        XTS: Label 'TS';
        XTSDescTxt: Label 'Time Sheet';
        XTSNoTxt: Label 'TS00001';
        XTSEndNoTxt: Label 'TS99999';
        XJJNL: Label 'JJNL-GEN';
        XJJNLDescTxt: Label 'Job Journal';
        XJJNLNoTxt: Label 'J00001';
        XJJNLEndNoTxt: Label 'J01000';
}

