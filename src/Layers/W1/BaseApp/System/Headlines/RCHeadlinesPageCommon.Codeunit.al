namespace System.Visualization;

codeunit 1440 "RC Headlines Page Common"
{

    var
        Headlines: Codeunit Headlines;
        RCHeadlinesExecutor: Codeunit "RC Headlines Executor";
        DefaultFieldsVisible: Boolean;
        DocumentationTxt: Label 'Want to learn more about %1?', Comment = '%1 is the Business Central short product name.';
        GreetingText: Text[250];
        DocumentationText: Text[250];
        UserGreetingVisible: Boolean;

    procedure HeadlineOnOpenPage(RoleCenterPageID: Integer)
    var
        RCHeadlinesUserData: Record "RC Headlines User Data";
        [SecurityFiltering(SecurityFilter::Ignored)]
        RCHeadlinesUserData2: Record "RC Headlines User Data";
    begin
        if RCHeadlinesUserData2.WritePermission() then begin
            if not RCHeadlinesUserData.Get(UserSecurityId(), RoleCenterPageID) then begin
                RCHeadlinesUserData.Init();
                RCHeadlinesUserData."Role Center Page ID" := RoleCenterPageID;
                RCHeadlinesUserData."User ID" := UserSecurityId();
                RCHeadlinesUserData.Insert();
            end;
            RCHeadlinesUserData."User workdate" := WorkDate();
            if ShouldCreateAComputeJob(RCHeadlinesUserData) then begin
                RCHeadlinesUserData."Last Computed" := CurrentDateTime();
                RCHeadlinesUserData.Modify();
                RCHeadlinesExecutor.ScheduleTask(RoleCenterPageID);
            end else
                RCHeadlinesUserData.Modify();
        end;
        GreetingText := Headlines.GetUserGreetingText();
        DocumentationText := CreateDocumentationText();
        ComputeDefaultFieldsVisibility(RoleCenterPageID);

        Commit(); // not to mess up the other page parts that may do IF CODEUNIT.RUN()
    end;

    local procedure CreateDocumentationText() DocumentationText: Text[250]
    begin
        DocumentationText := StrSubstNo(DocumentationTxt, PRODUCTNAME.Short());
        OnAfterCreateDocumentationText(DocumentationText);
    end;

    local procedure ShouldCreateAComputeJob(RCHeadlinesUserData: Record "RC Headlines User Data"): Boolean
    var
        OneHour: Duration;
    begin
        if RCHeadlinesUserData."Last Computed" = 0DT then
            exit(true);
        OneHour := 60 * 60 * 1000;
        exit(CurrentDateTime() - RCHeadlinesUserData."Last Computed" > OneHour);
    end;

    procedure ComputeDefaultFieldsVisibility(RoleCenterPageID: Integer)
    var
        ExtensionHeadlinesVisible: Boolean;
    begin
        OnIsAnyExtensionHeadlineVisible(ExtensionHeadlinesVisible, RoleCenterPageID);
        DefaultFieldsVisible := not ExtensionHeadlinesVisible;
        UserGreetingVisible := Headlines.ShouldUserGreetingBeVisible();
    end;

    procedure DocumentationUrlTxt() Result: Text
    begin
        Result := 'https://go.microsoft.com/fwlink/?linkid=2152979';
        OnAfterDocumentationUrlTxt(Result);
    end;

    procedure IsUserGreetingVisible(): Boolean
    begin
        exit(UserGreetingVisible);
    end;

    procedure GetGreetingText(): Text
    begin
        exit(GreetingText);
    end;

    procedure AreDefaultFieldsVisible(): Boolean
    begin
        exit(DefaultFieldsVisible);
    end;

    procedure GetDocumentationText(): Text
    begin
        exit(DocumentationText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDocumentationText(var DocumentationText: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDocumentationUrlTxt(var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsAnyExtensionHeadlineVisible(var ExtensionHeadlinesVisible: Boolean; RoleCenterPageID: Integer)
    begin
    end;
}
