codeunit 119203 "Create O365 Cronus Company"
{

    trigger OnRun()
    var
        Company: Record Company;
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplyConfiguration: Codeunit "Apply Configuration";
    begin
        CODEUNIT.Run(CODEUNIT::"Company-Initialize");
        ApplyConfiguration.ApplyEvaluationConfiguration();

        // Remove all application areas from cronus, by setting default application area with FALSE in all options
        Company.SetFilter(Name, '<>%1', CompanyName);
        if Company.FindSet() then
            repeat
                ApplicationAreaSetup.Init();
                ApplicationAreaSetup."Company Name" := Company.Name;
                if ApplicationAreaSetup.Insert() then;
            until Company.Next() = 0;
    end;
}

