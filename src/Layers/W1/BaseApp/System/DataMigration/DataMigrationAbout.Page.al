namespace System.Integration;

page 1798 "Data Migration About"
{
    Caption = 'About Data Migration';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = StandardDialog;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            label(Line1)
            {
                ApplicationArea = All;
                Caption = 'We''re migrating data to Dynamics 365. Depending on what was chosen, this can be customers, vendors, items, G/L accounts, or all of these entities, plus a history of transactions for them.';
                MultiLine = true;
            }
            label(Line2)
            {
                ApplicationArea = All;
                Caption = 'Migration will take a few minutes. We''ll let you know when migration is complete.';
                MultiLine = true;
            }
            label(Line3)
            {
                ApplicationArea = All;
                Caption = 'In the meantime you can explore Dynamics 365, but do not add new customers, vendors, items, or G/L accounts.';
                MultiLine = true;
            }
            label(Line4)
            {
                ApplicationArea = All;
                Caption = 'To monitor progress, choose OK to go to the Data Migration Overview page.';
                MultiLine = true;
            }
            field(LearnMore; LearnMoreLbl)
            {
                ApplicationArea = All;
                AssistEdit = false;
                DrillDown = true;
                Editable = false;
                Lookup = false;
                ShowCaption = false;
                Style = StandardAccent;
                StyleExpr = true;

                trigger OnDrillDown()
                var
                    DataMigrationStatus: Record "Data Migration Status";
                    Url: Text;
                begin
                    DataMigrationStatus.SetFilter(Status, '%1|%2',
                      DataMigrationStatus.Status::"In Progress",
                      DataMigrationStatus.Status::Pending);
                    if DataMigrationStatus.FindFirst() then
                        DataMigrationFacade.OnGetMigrationHelpTopicUrl(DataMigrationStatus."Migration Type", Url);
                    if Url = '' then
                        HyperLink(GeneralHelpTopicUrlTxt)
                    else
                        HyperLink(Url);
                end;
            }
        }
    }

    actions
    {
    }

    var
        DataMigrationFacade: Codeunit "Data Migration Facade";

        GeneralHelpTopicUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=859445', Locked = true;
        LearnMoreLbl: Label 'Learn more';
}

