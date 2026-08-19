codeunit 101901 "Create Sequence of Actions"
{

    trigger OnRun()
    begin
        "Interface Basis Data".BeforePosting();

        DemoDataSetup.Get();

        Window.Open(
          XDemoDataTool +
          XProcessing1 +
          '@2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\');

        for ActualDate := CA.AdjustDate(19011201D) to CA.AdjustDate(19030126D) do begin
            Window.Update(1, ActualDate);
            Window.Update(
              2, Round(
                (ActualDate - CA.AdjustDate(19011201D)) /
                (CA.AdjustDate(19030120D) - CA.AdjustDate(19011201D)) * 10000, 1));

            "Interface Basis Data".Post(ActualDate);
            if DemoDataSetup.Financials then
                "Interface Finance Management".Post(ActualDate);
            if DemoDataSetup."Relationship Mgt." then
                "Interface Relationship Mgt.".Post(ActualDate);
            if DemoDataSetup."Reserved for future use 1" then
                "Interface CRM".Post(ActualDate);
            if DemoDataSetup."Reserved for future use 2" then
                "Interface Decision Support".Post(ActualDate);
            if DemoDataSetup."Service Management" then
                "Interface Service Management".Post(ActualDate);
            if DemoDataSetup.Distribution then
                "Interface Distribution".Post(ActualDate);
            if DemoDataSetup.Manufacturing then
                "Interface Manufacturing".Post(ActualDate);
            if DemoDataSetup.ADCS then
                "Interface ADCS".Post(ActualDate);
            if DemoDataSetup."Reserved for future use 3" then
                InterfaceReservedForFut3.Post(ActualDate);
            if DemoDataSetup."Reserved for future use 4" then
                "Interface HTML".Post(ActualDate);
        end;

        WorkDate := ActualDate;

        Window.Update(1, XFinalSetup);
        Window.Update(2, 9900);

        "Interface Basis Data".AfterPosting();
        if DemoDataSetup.Financials then
            "Interface Finance Management"."After Posting"();
        if DemoDataSetup.Manufacturing then
            "Interface Manufacturing"."After Posting"();
        if DemoDataSetup."Relationship Mgt." then
            "Interface Relationship Mgt."."After Posting"();
        if DemoDataSetup."Service Management" then
            "Interface Service Management"."After Posting"();

        Window.Close();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        "Interface Basis Data": Codeunit "Interface Basis Data";
        "Interface Finance Management": Codeunit "Interface Financials";
        "Interface Relationship Mgt.": Codeunit "Interface Relationship Mgt.";
        "Interface CRM": Codeunit "Interface Reserved for fut. 1";
        "Interface Decision Support": Codeunit "Interface Reserved for fut. 2";
        "Interface Service Management": Codeunit "Interface Service Management";
        "Interface Distribution": Codeunit "Interface Distribution";
        "Interface Manufacturing": Codeunit "Interface Manufacturing";
        "Interface ADCS": Codeunit "Interface ADCS";
        InterfaceReservedForFut3: Codeunit "Interface Reserved for fut. 3";
        "Interface HTML": Codeunit "Interface Reserved for fut. 4";
        Window: Dialog;
        ActualDate: Date;
        XDemoDataTool: Label 'Demonstration Data Tool\\\';
        XProcessing1: Label 'Processing                   #1########\\';
        XFinalSetup: Label 'Final Setup';
}

